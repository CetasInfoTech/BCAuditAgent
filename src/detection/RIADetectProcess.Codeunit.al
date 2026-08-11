/// <summary>L2 Process-intelligence detection: end-to-end flow integrity checks.</summary>
codeunit 50123 "RIA Detect Process"
{
    Access = Public;
    Permissions = tabledata "Purchase Line" = r, tabledata "Sales Line" = r,
                  tabledata "Gen. Journal Line" = r, tabledata "Prod. Order Line" = r,
                  tabledata "Job Task" = r, tabledata "IC Outbox Transaction" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L2-P2P-01 Three-way match: purchase lines invoiced beyond quantity received.</summary>
    procedure DetectThreeWayMatch() Raised: Integer
    var
        PL: Record "Purchase Line";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label '3-way match failure: doc %1', Comment = '%1=doc';
        DescLbl: Label 'Purchase order %1 item %2 is invoiced %3 but only %4 received. Invoicing beyond receipt breaks the 3-way match — hold payment.', Comment = 'positional';
    begin
        PL.SetRange("Document Type", PL."Document Type"::Order);
        PL.SetRange(Type, PL.Type::Item);
        PL.SetLoadFields("Document No.", "No.", "Quantity Invoiced", "Quantity Received", "Line No.");
        if PL.FindSet() then
            repeat
                if PL."Quantity Invoiced" > PL."Quantity Received" then begin
                    Hash := CopyStr(StrSubstNo('L2P2P|%1|%2', PL."Document No.", PL."Line No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L2-P2P-01',
                            CopyStr(StrSubstNo(TitleLbl, PL."Document No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, PL."Document No.", PL."No.", Format(PL."Quantity Invoiced"), Format(PL."Quantity Received")), 1, 2048),
                            0, Hash, Database::"Purchase Line", PL.SystemId, PL."Document No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until PL.Next() = 0;
    end;

    /// <summary>L2-Q2C-01 Order fulfilment: sales order lines past shipment date, not fully shipped.</summary>
    procedure DetectFulfillment() Raised: Integer
    var
        SL: Record "Sales Line";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Late fulfilment: doc %1', Comment = '%1=doc';
        DescLbl: Label 'Sales order %1 item %2 was due %3 but only %4 of %5 shipped. Late fulfilment risks revenue and SLA penalties.', Comment = 'positional';
    begin
        SL.SetRange("Document Type", SL."Document Type"::Order);
        SL.SetRange(Type, SL.Type::Item);
        SL.SetFilter("Shipment Date", '<%1&<>%2', Today(), 0D);
        SL.SetLoadFields("Document No.", "No.", "Shipment Date", "Quantity Shipped", Quantity, "Line No.");
        if SL.FindSet() then
            repeat
                if SL."Quantity Shipped" < SL.Quantity then begin
                    Hash := CopyStr(StrSubstNo('L2Q2C|%1|%2', SL."Document No.", SL."Line No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L2-Q2C-01',
                            CopyStr(StrSubstNo(TitleLbl, SL."Document No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, SL."Document No.", SL."No.", Format(SL."Shipment Date"), Format(SL."Quantity Shipped"), Format(SL.Quantity)), 1, 2048),
                            0, Hash, Database::"Sales Line", SL.SystemId, SL."Document No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until SL.Next() = 0;
    end;

    /// <summary>L2-R2R-01 Period-end close: unposted general journal lines lingering near period-end.</summary>
    procedure DetectPeriodEndClose() Raised: Integer
    var
        GenJnlLine: Record "Gen. Journal Line";
        UnpostedCount: Integer;
        NearClose: Boolean;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Period-end close risk';
        DescLbl: Label '%1 unposted general-journal line(s) remain with period-end approaching. Unposted entries risk an incomplete close.', Comment = '%1=count';
    begin
        NearClose := (CalcDate('<CM>', Today()) - Today()) <= 5;
        if not NearClose then
            exit(0);
        UnpostedCount := GenJnlLine.Count();
        if UnpostedCount > 0 then begin
            Hash := CopyStr(StrSubstNo('L2R2R|%1', Format(CalcDate('<CM>', Today()))), 1, 100);
            if not AlertMgt.AlertExists(Hash) then begin
                AlertNo := AlertMgt.RaiseAlert('L2-R2R-01',
                    CopyStr(TitleLbl, 1, 150),
                    CopyStr(StrSubstNo(DescLbl, UnpostedCount), 1, 2048),
                    0, Hash, Database::"Gen. Journal Line", CreateGuid(), '');
                if AlertNo <> 0 then
                    Raised += 1;
            end;
        end;
    end;

    /// <summary>L2-PTP-01 Plan-to-produce: firm-planned orders past due and not released.</summary>
    procedure DetectPlanToProduce() Raised: Integer
    var
        POL: Record "Prod. Order Line";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Planning gap: item %1', Comment = '%1=item';
        DescLbl: Label 'Firm-planned order %1 for item %2 is past its due date %3 and not yet released. Production plan is slipping.', Comment = 'positional';
    begin
        POL.SetRange(Status, POL.Status::"Firm Planned");
        POL.SetFilter("Due Date", '<%1&<>%2', Today(), 0D);
        POL.SetLoadFields("Prod. Order No.", "Item No.", "Due Date", "Line No.");
        if POL.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L2PTP|%1|%2', POL."Prod. Order No.", POL."Line No."), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L2-PTP-01',
                        CopyStr(StrSubstNo(TitleLbl, POL."Item No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, POL."Prod. Order No.", POL."Item No.", Format(POL."Due Date")), 1, 2048),
                        0, Hash, Database::"Prod. Order Line", POL.SystemId, POL."Prod. Order No.");
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until POL.Next() = 0;
    end;

    /// <summary>L2-IC-01 Intercompany: outbox transactions pending longer than 7 days.</summary>
    procedure DetectIntercompany() Raised: Integer
    var
        ICOutbox: Record "IC Outbox Transaction";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Stale intercompany transaction';
        DescLbl: Label 'Intercompany outbox transaction %1 to partner %2 has been pending since %3. Unmatched IC transactions distort consolidated results.', Comment = 'positional';
    begin
        ICOutbox.SetFilter("Document Date", '<%1', CalcDate('<-7D>', Today()));
        ICOutbox.SetLoadFields("Transaction No.", "IC Partner Code", "Document Date");
        if ICOutbox.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L2IC|%1|%2', ICOutbox."Transaction No.", ICOutbox."IC Partner Code"), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L2-IC-01',
                        CopyStr(TitleLbl, 1, 150),
                        CopyStr(StrSubstNo(DescLbl, Format(ICOutbox."Transaction No."), ICOutbox."IC Partner Code", Format(ICOutbox."Document Date")), 1, 2048),
                        0, Hash, Database::"IC Outbox Transaction", ICOutbox.SystemId, '');
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until ICOutbox.Next() = 0;
    end;

    /// <summary>L2-PTC-01 Project-to-cash: completed jobs with usage still exceeding what was invoiced.</summary>
    procedure DetectProjectToCash() Raised: Integer
    var
        JobTask: Record "Job Task";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Uninvoiced completed job: %1', Comment = '%1=job';
        DescLbl: Label 'Job %1 task %2 shows usage of %3 but only %4 invoiced. Bill the remaining work to convert project effort to cash.', Comment = 'positional';
    begin
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        if JobTask.FindSet() then
            repeat
                JobTask.CalcFields("Usage (Total Price)", "Contract (Invoiced Price)");
                if (JobTask."Usage (Total Price)" > 0) and (JobTask."Contract (Invoiced Price)" < JobTask."Usage (Total Price)") then begin
                    Hash := CopyStr(StrSubstNo('L2PTC|%1|%2', JobTask."Job No.", JobTask."Job Task No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L2-PTC-01',
                            CopyStr(StrSubstNo(TitleLbl, JobTask."Job No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, JobTask."Job No.", JobTask."Job Task No.", Format(JobTask."Usage (Total Price)"), Format(JobTask."Contract (Invoiced Price)")), 1, 2048),
                            JobTask."Usage (Total Price)" - JobTask."Contract (Invoiced Price)", Hash, Database::"Job Task", JobTask.SystemId, JobTask."Job No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until JobTask.Next() = 0;
    end;
}
