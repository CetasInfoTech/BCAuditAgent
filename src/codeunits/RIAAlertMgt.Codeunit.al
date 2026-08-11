/// <summary>Central service for raising, deduplicating, and transitioning alerts through their lifecycle.</summary>
codeunit 50101 "RIA Alert Mgt"
{
    Access = Public;
    Permissions = tabledata "RIA Risk Alert" = rimd,
                  tabledata "RIA Alert Evidence" = rim,
                  tabledata "RIA Control Catalogue" = r,
                  tabledata "RIA Risk Setup" = r;

    var
        RiskScoreMgt: Codeunit "RIA Risk Score Mgt";

    /// <summary>Raises an alert if no open alert with the same dedup hash already exists. Returns the entry no. (0 if suppressed).</summary>
    procedure RaiseAlert(ControlID: Code[20]; Title: Text[150]; Description: Text[2048]; AmountLCY: Decimal; DedupHash: Text[100]; SourceTableNo: Integer; SourceSystemID: Guid; SourceDocNo: Code[20]): Integer
    var
        RiskAlert: Record "RIA Risk Alert";
        Control: Record "RIA Control Catalogue";
        Setup: Record "RIA Risk Setup";
        Severity: Enum "RIA Severity";
        Score: Decimal;
    begin
        if not Control.Get(ControlID) then
            exit(0);
        if not Control.Enabled then
            exit(0);

        if AlertExists(DedupHash) then
            exit(0);

        Setup.GetSetup();

        Score := RiskScoreMgt.ComputeScore(
            Control."Default Risk Score", AmountLCY, Setup."Materiality Floor (LCY)",
            CountRecentForControl(ControlID, SourceDocNo), IsFraudControl(Control), IsPeriodEnd());
        Severity := RiskScoreMgt.ScoreToSeverity(Score);

        RiskAlert.Init();
        RiskAlert."Control ID" := ControlID;
        RiskAlert."Control Name" := Control.Name;
        RiskAlert.Layer := Control.Layer;
        RiskAlert.Domain := Control.Domain;
        RiskAlert.Severity := Severity;
        RiskAlert."Risk Score" := Score;
        RiskAlert.Status := RiskAlert.Status::New;
        RiskAlert."Detected DateTime" := CurrentDateTime();
        RiskAlert.Title := Title;
        RiskAlert.Description := Description;
        RiskAlert."Recommended Action" := CopyStr(Control."Business Impact", 1, MaxStrLen(RiskAlert."Recommended Action"));
        RiskAlert."Amount (LCY)" := AmountLCY;
        RiskAlert."Source Table No." := SourceTableNo;
        RiskAlert."Source System ID" := SourceSystemID;
        RiskAlert."Source Document No." := SourceDocNo;
        RiskAlert."Dedup Hash" := DedupHash;
        RiskAlert."SLA Due DateTime" := CalcSLADue(Severity, Setup);
        RiskAlert.Insert(true);

        NotifyAndDeliver(RiskAlert, Setup);
        exit(RiskAlert."Entry No.");
    end;

    /// <summary>Sets entity attribution on an alert and recalculates the entity risk score.</summary>
    procedure SetEntity(AlertEntryNo: Integer; EntityType: Enum "RIA Profile Type"; EntityNo: Code[20]; EntityName: Text[100])
    var
        RiskAlert: Record "RIA Risk Alert";
    begin
        if not RiskAlert.Get(AlertEntryNo) then
            exit;
        RiskAlert."Entity Type" := EntityType;
        RiskAlert."Entity No." := EntityNo;
        RiskAlert."Entity Name" := EntityName;
        RiskAlert.Modify();
        RiskScoreMgt.RecalculateEntityScore(EntityType, EntityNo);
    end;

    /// <summary>Convenience: raises an alert and attributes it to an entity in one call. Returns entry no. (0 if suppressed).</summary>
    procedure RaiseEntityAlert(ControlID: Code[20]; Title: Text[150]; Description: Text[2048]; AmountLCY: Decimal; DedupHash: Text[100]; SourceTableNo: Integer; SourceSystemID: Guid; SourceDocNo: Code[20]; EntityType: Enum "RIA Profile Type"; EntityNo: Code[20]; EntityName: Text[100]) AlertNo: Integer
    begin
        AlertNo := RaiseAlert(ControlID, Title, Description, AmountLCY, DedupHash, SourceTableNo, SourceSystemID, SourceDocNo);
        if (AlertNo <> 0) and (EntityNo <> '') then
            SetEntity(AlertNo, EntityType, EntityNo, EntityName);
    end;

    procedure Acknowledge(var RiskAlert: Record "RIA Risk Alert")
    begin
        if RiskAlert.Status <> RiskAlert.Status::New then
            exit;
        RiskAlert.Status := RiskAlert.Status::Acknowledged;
        RiskAlert."Acknowledged By" := CopyStr(UserId(), 1, MaxStrLen(RiskAlert."Acknowledged By"));
        RiskAlert."Acknowledged DateTime" := CurrentDateTime();
        RiskAlert.Modify(true);
        AddSystemNote(RiskAlert."Entry No.", 'Alert acknowledged.');
    end;

    procedure StartReview(var RiskAlert: Record "RIA Risk Alert")
    begin
        RiskAlert.Status := RiskAlert.Status::"Under Review";
        RiskAlert.Modify(true);
        AddSystemNote(RiskAlert."Entry No.", 'Investigation started.');
    end;

    procedure Resolve(var RiskAlert: Record "RIA Risk Alert"; Notes: Text[2048]; Exception: Boolean)
    begin
        if Exception then
            RiskAlert.Status := RiskAlert.Status::"Resolved - Exception"
        else
            RiskAlert.Status := RiskAlert.Status::Resolved;
        RiskAlert."Resolved By" := CopyStr(UserId(), 1, MaxStrLen(RiskAlert."Resolved By"));
        RiskAlert."Resolved DateTime" := CurrentDateTime();
        RiskAlert."Resolution Notes" := Notes;
        RiskAlert.Modify(true);
        AddSystemNote(RiskAlert."Entry No.", 'Alert resolved.');
        if RiskAlert."Entity No." <> '' then
            RiskScoreMgt.RecalculateEntityScore(RiskAlert."Entity Type", RiskAlert."Entity No.");
    end;

    procedure MarkFalsePositive(var RiskAlert: Record "RIA Risk Alert"; Notes: Text[2048])
    begin
        RiskAlert.Status := RiskAlert.Status::"False Positive";
        RiskAlert."Resolved By" := CopyStr(UserId(), 1, MaxStrLen(RiskAlert."Resolved By"));
        RiskAlert."Resolved DateTime" := CurrentDateTime();
        RiskAlert."Resolution Notes" := Notes;
        RiskAlert.Modify(true);
        AddSystemNote(RiskAlert."Entry No.", 'Marked as false positive (feedback captured for ML calibration).');
        if RiskAlert."Entity No." <> '' then
            RiskScoreMgt.RecalculateEntityScore(RiskAlert."Entity Type", RiskAlert."Entity No.");
    end;

    procedure Escalate(var RiskAlert: Record "RIA Risk Alert")
    begin
        RiskAlert.Status := RiskAlert.Status::Escalated;
        RiskAlert.Modify(true);
        AddSystemNote(RiskAlert."Entry No.", 'Alert escalated.');
    end;

    procedure AddComment(AlertEntryNo: Integer; CommentText: Text[250])
    var
        Evidence: Record "RIA Alert Evidence";
    begin
        Evidence.Init();
        Evidence."Alert Entry No." := AlertEntryNo;
        Evidence."Line No." := NextEvidenceLineNo(AlertEntryNo);
        Evidence."Entry Type" := Evidence."Entry Type"::Comment;
        Evidence.Description := CommentText;
        Evidence.Insert(true);
    end;

    procedure AddEvidence(AlertEntryNo: Integer; Descr: Text[250]; SourceTableNo: Integer; FieldCaption: Text[100]; OldVal: Text[250]; NewVal: Text[250])
    var
        Evidence: Record "RIA Alert Evidence";
    begin
        Evidence.Init();
        Evidence."Alert Entry No." := AlertEntryNo;
        Evidence."Line No." := NextEvidenceLineNo(AlertEntryNo);
        Evidence."Entry Type" := Evidence."Entry Type"::Evidence;
        Evidence.Description := Descr;
        Evidence."Source Table No." := SourceTableNo;
        Evidence."Source Field Caption" := FieldCaption;
        Evidence."Old Value" := OldVal;
        Evidence."New Value" := NewVal;
        Evidence.Insert(true);
    end;

    local procedure AddSystemNote(AlertEntryNo: Integer; NoteText: Text[250])
    var
        Evidence: Record "RIA Alert Evidence";
    begin
        Evidence.Init();
        Evidence."Alert Entry No." := AlertEntryNo;
        Evidence."Line No." := NextEvidenceLineNo(AlertEntryNo);
        Evidence."Entry Type" := Evidence."Entry Type"::"System Note";
        Evidence.Description := NoteText;
        Evidence.Insert(true);
    end;

    local procedure NextEvidenceLineNo(AlertEntryNo: Integer): Integer
    var
        Evidence: Record "RIA Alert Evidence";
    begin
        Evidence.SetRange("Alert Entry No.", AlertEntryNo);
        if Evidence.FindLast() then
            exit(Evidence."Line No." + 10000);
        exit(10000);
    end;

    local procedure NotifyAndDeliver(var RiskAlert: Record "RIA Risk Alert"; Setup: Record "RIA Risk Setup")
    var
        NotificationMgt: Codeunit "RIA Notification Mgt";
        DeliveryMgt: Codeunit "RIA Delivery Mgt";
    begin
        if Setup."Shadow Mode" then
            exit;
        if RiskAlert.Severity.AsInteger() >= RiskAlert.Severity::High.AsInteger() then
            NotificationMgt.NotifyNewAlert(RiskAlert."Entry No.");
        if RiskAlert.Severity = RiskAlert.Severity::Critical then
            DeliveryMgt.SendCriticalAlert(RiskAlert."Entry No.");
    end;

    procedure AlertExists(DedupHash: Text[100]): Boolean
    var
        RiskAlert: Record "RIA Risk Alert";
    begin
        if DedupHash = '' then
            exit(false);
        RiskAlert.SetCurrentKey("Dedup Hash");
        RiskAlert.SetRange("Dedup Hash", DedupHash);
        RiskAlert.SetFilter(Status, '<>%1&<>%2&<>%3',
            RiskAlert.Status::Resolved, RiskAlert.Status::"Resolved - Exception", RiskAlert.Status::"False Positive");
        exit(not RiskAlert.IsEmpty());
    end;

    local procedure CountRecentForControl(ControlID: Code[20]; DocNo: Code[20]): Integer
    var
        RiskAlert: Record "RIA Risk Alert";
    begin
        RiskAlert.SetCurrentKey("Control ID", Status);
        RiskAlert.SetRange("Control ID", ControlID);
        RiskAlert.SetRange("Source Document No.", DocNo);
        RiskAlert.SetFilter("Detected DateTime", '>=%1', CreateDateTime(CalcDate('<-90D>', Today()), 0T));
        exit(RiskAlert.Count());
    end;

    local procedure CalcSLADue(Severity: Enum "RIA Severity"; Setup: Record "RIA Risk Setup"): DateTime
    var
        Hours: Integer;
    begin
        case Severity of
            Severity::Critical:
                Hours := Setup."SLA Critical (Hours)";
            Severity::High:
                Hours := Setup."SLA High (Hours)";
            else
                Hours := Setup."SLA Medium (Hours)";
        end;
        if Hours = 0 then
            Hours := 24;
        exit(CurrentDateTime() + (Hours * 60 * 60 * 1000));
    end;

    local procedure IsFraudControl(Control: Record "RIA Control Catalogue"): Boolean
    begin
        exit(Control."Default Severity" = Control."Default Severity"::Critical);
    end;

    local procedure IsPeriodEnd(): Boolean
    var
        LastDayOfMonth: Date;
    begin
        LastDayOfMonth := CalcDate('<CM>', Today());
        exit((LastDayOfMonth - Today()) <= 2);
    end;
}
