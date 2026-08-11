/// <summary>L3 Configuration-intelligence detection: governance of the settings that control everything else.</summary>
codeunit 50124 "RIA Detect Config"
{
    Access = Public;
    Permissions = tabledata "General Ledger Setup" = r, tabledata "User Setup" = r,
                  tabledata "Change Log Entry" = r, tabledata "Change Log Setup" = r,
                  tabledata Workflow = r, tabledata "Access Control" = r,
                  tabledata "No. Series Line" = r, tabledata "No. Series" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L3-001 Posting Setup Governance: open posting windows + logged changes to the posting window.</summary>
    procedure DetectPostingSetupGovernance() Raised: Integer
    var
        GLSetup: Record "General Ledger Setup";
        ChangeLogEntry: Record "Change Log Entry";
        Hash: Text[100];
        AlertNo: Integer;
        OpenTitleLbl: Label 'Posting window is wide open';
        OpenDescLbl: Label 'General Ledger Setup allows posting up to %1. An open or far-future posting window permits back/future-dated entries — tighten Allow Posting From/To at period close.', Comment = '%1=allowto';
        ChgTitleLbl: Label 'Posting window changed';
        ChgDescLbl: Label 'The posting window ("%1") was changed by %2 on %3 from "%4" to "%5". Loosening the window enables backdating — verify authorisation.', Comment = 'positional';
    begin
        // Current-state: window open or far in the future.
        if GLSetup.Get() then
            if (GLSetup."Allow Posting To" = 0D) or (GLSetup."Allow Posting To" > CalcDate('<+CM+1M>', Today())) then begin
                Hash := CopyStr(StrSubstNo('L3001OPEN|%1', Format(GLSetup."Allow Posting To")), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L3-001', CopyStr(OpenTitleLbl, 1, 150),
                        CopyStr(StrSubstNo(OpenDescLbl, Format(GLSetup."Allow Posting To")), 1, 2048),
                        0, Hash, Database::"General Ledger Setup", GLSetup.SystemId, '');
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            end;

        // Change Log: modifications to the posting window on GL Setup / User Setup.
        ChangeLogEntry.SetCurrentKey("Date and Time");
        ChangeLogEntry.SetFilter("Table No.", '%1|%2', Database::"General Ledger Setup", Database::"User Setup");
        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Modification);
        ChangeLogEntry.SetFilter("Field Caption", '@*allow posting*');
        ChangeLogEntry.SetFilter("Date and Time", '>=%1', CreateDateTime(CalcDate('<-30D>', Today()), 0T));
        ChangeLogEntry.SetLoadFields("Field Caption", "User ID", "Date and Time", "Old Value", "New Value", "Primary Key");
        if ChangeLogEntry.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L3001CHG|%1|%2', ChangeLogEntry."Primary Key", Format(ChangeLogEntry."Date and Time")), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L3-001', CopyStr(ChgTitleLbl, 1, 150),
                        CopyStr(StrSubstNo(ChgDescLbl, ChangeLogEntry."Field Caption", ChangeLogEntry."User ID", Format(DT2Date(ChangeLogEntry."Date and Time")), ChangeLogEntry."Old Value", ChangeLogEntry."New Value"), 1, 2048),
                        0, Hash, Database::"General Ledger Setup", ChangeLogEntry.SystemId, '');
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until ChangeLogEntry.Next() = 0;
    end;

    /// <summary>L3-002 Approval Workflow Governance: no enabled approval workflow present.</summary>
    procedure DetectApprovalWorkflow() Raised: Integer
    var
        Workflow: Record Workflow;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'No approval workflows enabled';
        DescLbl: Label 'No enabled workflows were found. Without approval workflows, high-value documents can post without authorisation. Enable purchase/payment approval workflows.';
    begin
        Workflow.SetRange(Enabled, true);
        if Workflow.IsEmpty() then begin
            Hash := CopyStr(StrSubstNo('L3002|%1', Format(Today())), 1, 100);
            if not AlertMgt.AlertExists(Hash) then begin
                AlertNo := AlertMgt.RaiseAlert('L3-002', CopyStr(TitleLbl, 1, 150),
                    CopyStr(DescLbl, 1, 2048), 0, Hash, Database::Workflow, CreateGuid(), '');
                if AlertNo <> 0 then
                    Raised += 1;
            end;
        end;
    end;

    /// <summary>L3-003 Segregation of Duties: excessive SUPER assignments (broad privilege concentration).</summary>
    procedure DetectSoD() Raised: Integer
    var
        AccessControl: Record "Access Control";
        SuperUsers: Integer;
        MaxSuper: Integer;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Excessive SUPER access';
        DescLbl: Label '%1 users hold the SUPER permission set (threshold %2). Broad privilege concentration undermines segregation of duties — review and restrict.', Comment = 'positional';
    begin
        MaxSuper := 3;
        AccessControl.SetRange("Role ID", 'SUPER');
        SuperUsers := AccessControl.Count();
        if SuperUsers > MaxSuper then begin
            Hash := CopyStr(StrSubstNo('L3003|%1|%2', SuperUsers, Format(Today())), 1, 100);
            if not AlertMgt.AlertExists(Hash) then begin
                AlertNo := AlertMgt.RaiseAlert('L3-003', CopyStr(TitleLbl, 1, 150),
                    CopyStr(StrSubstNo(DescLbl, SuperUsers, MaxSuper), 1, 2048),
                    0, Hash, Database::"Access Control", CreateGuid(), '');
                if AlertNo <> 0 then
                    Raised += 1;
            end;
        end;
    end;

    /// <summary>L3-004 Number Series Integrity: financial series that allow gaps (audit-trail weakness).</summary>
    procedure DetectNumberSeries() Raised: Integer
    var
        NoSeriesLine: Record "No. Series Line";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Number series allows gaps: %1', Comment = '%1=series';
        DescLbl: Label 'Number series %1 has "Allow Gaps in Nos." enabled. Gaps in financial document numbering weaken the audit trail — disable for posting series.', Comment = '%1=series';
    begin
        NoSeriesLine.SetRange(Implementation, NoSeriesLine.Implementation::Sequence);
        NoSeriesLine.SetLoadFields("Series Code", "Line No.");
        if NoSeriesLine.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L3004|%1', NoSeriesLine."Series Code"), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L3-004', CopyStr(StrSubstNo(TitleLbl, NoSeriesLine."Series Code"), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, NoSeriesLine."Series Code"), 1, 2048),
                        0, Hash, Database::"No. Series Line", NoSeriesLine.SystemId, NoSeriesLine."Series Code");
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until NoSeriesLine.Next() = 0;
    end;

    /// <summary>L3-005 Change Log Integrity: change log not activated (blinds other controls).</summary>
    procedure DetectChangeLogIntegrity() Raised: Integer
    var
        ChangeLogSetup: Record "Change Log Setup";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Change Log is not active';
        DescLbl: Label 'Change Log is not activated. Vendor bank-change and posting-setup controls depend on it — activate Change Log and log the critical tables.';
    begin
        if ChangeLogSetup.Get() then
            if not ChangeLogSetup."Change Log Activated" then begin
                Hash := CopyStr(StrSubstNo('L3005|%1', Format(Today())), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L3-005', CopyStr(TitleLbl, 1, 150),
                        CopyStr(DescLbl, 1, 2048), 0, Hash, Database::"Change Log Setup", ChangeLogSetup.SystemId, '');
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            end;
    end;
}
