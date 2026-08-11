/// <summary>Purchasing-domain L1 detection (L1-010, 011, 012, 014, 015).</summary>
codeunit 50116 "RIA Detect Purchasing"
{
    Access = Public;
    Permissions = tabledata "Purchase Header" = r, tabledata "Purchase Line" = r,
                  tabledata Vendor = r, tabledata Item = r, tabledata "Approval Entry" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L1-010 Split Purchase Orders: same vendor + purchaser within 3 days, each below limit but combined above.</summary>
    procedure DetectSplitPOs() Raised: Integer
    var
        PH: Record "Purchase Header";
        Grp: Record "Purchase Header";
        Vendor: Record Vendor;
        Limit: Decimal;
        GroupSum: Decimal;
        ThisAmt: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Possible split PO: vendor %1', Comment = '%1=vendor';
        DescLbl: Label 'Vendor %1 has multiple orders by purchaser %2 within 3 days totalling %3, each below the %4 approval limit. This pattern can bypass approval thresholds.', Comment = '%1=vendor,%2=purchaser,%3=sum,%4=limit';
    begin
        Limit := ApprovalLimit();
        PH.SetRange("Document Type", PH."Document Type"::Order);
        PH.SetRange("Order Date", CalcDate('<-30D>', Today()), Today());
        PH.SetLoadFields("No.", "Buy-from Vendor No.", "Purchaser Code", "Order Date");
        if PH.FindSet() then
            repeat
                PH.CalcFields(Amount);
                ThisAmt := PH.Amount;
                if (ThisAmt > 0) and (ThisAmt < Limit) then begin
                    GroupSum := 0;
                    Grp.SetRange("Document Type", Grp."Document Type"::Order);
                    Grp.SetRange("Buy-from Vendor No.", PH."Buy-from Vendor No.");
                    Grp.SetRange("Purchaser Code", PH."Purchaser Code");
                    Grp.SetRange("Order Date", CalcDate('<-3D>', PH."Order Date"), CalcDate('<+3D>', PH."Order Date"));
                    if Grp.FindSet() then
                        repeat
                            Grp.CalcFields(Amount);
                            GroupSum += Grp.Amount;
                        until Grp.Next() = 0;
                    if GroupSum > Limit then begin
                        Hash := CopyStr(StrSubstNo('L1010|%1|%2|%3', PH."Buy-from Vendor No.", PH."Purchaser Code", Format(PH."Order Date")), 1, 100);
                        if not AlertMgt.AlertExists(Hash) then begin
                            if not Vendor.Get(PH."Buy-from Vendor No.") then
                                Clear(Vendor);
                            AlertNo := AlertMgt.RaiseEntityAlert('L1-010',
                                CopyStr(StrSubstNo(TitleLbl, PH."Buy-from Vendor No."), 1, 150),
                                CopyStr(StrSubstNo(DescLbl, PH."Buy-from Vendor No.", PH."Purchaser Code", Format(GroupSum), Format(Limit)), 1, 2048),
                                GroupSum, Hash, Database::"Purchase Header", PH.SystemId, PH."No.",
                                "RIA Profile Type"::Vendor, PH."Buy-from Vendor No.", Vendor.Name);
                            if AlertNo <> 0 then
                                Raised += 1;
                        end;
                    end;
                end;
            until PH.Next() = 0;
    end;

    /// <summary>L1-011 Vendor Price Deviations: purchase line cost materially above the item's last direct cost.</summary>
    procedure DetectPriceDeviations() Raised: Integer
    var
        PL: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        Tol: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Vendor price deviation: item %1', Comment = '%1=item';
        DescLbl: Label 'Purchase line on doc %1 prices item %2 at %3 vs last direct cost %4 (>%5%% higher). Verify the price increase.', Comment = '%1=doc,%2=item,%3=price,%4=last,%5=tol';
    begin
        Tol := 15;
        PL.SetRange(Type, PL.Type::Item);
        PL.SetFilter("Direct Unit Cost", '>0');
        PL.SetLoadFields("Document No.", "No.", "Direct Unit Cost", "Buy-from Vendor No.", "Line No.");
        if PL.FindSet() then
            repeat
                if Item.Get(PL."No.") then
                    if (Item."Last Direct Cost" > 0) and (PL."Direct Unit Cost" > Item."Last Direct Cost" * (1 + Tol / 100)) then begin
                        Hash := CopyStr(StrSubstNo('L1011|%1|%2', PL."Document No.", PL."Line No."), 1, 100);
                        if not AlertMgt.AlertExists(Hash) then begin
                            if not Vendor.Get(PL."Buy-from Vendor No.") then
                                Clear(Vendor);
                            AlertNo := AlertMgt.RaiseEntityAlert('L1-011',
                                CopyStr(StrSubstNo(TitleLbl, PL."No."), 1, 150),
                                CopyStr(StrSubstNo(DescLbl, PL."Document No.", PL."No.", Format(PL."Direct Unit Cost"), Format(Item."Last Direct Cost"), Format(Tol)), 1, 2048),
                                PL."Direct Unit Cost", Hash, Database::"Purchase Line", PL.SystemId, PL."Document No.",
                                "RIA Profile Type"::Vendor, PL."Buy-from Vendor No.", Vendor.Name);
                            if AlertNo <> 0 then
                                Raised += 1;
                        end;
                    end;
            until PL.Next() = 0;
    end;

    /// <summary>L1-012 Unauthorized Vendors: open purchase documents for a blocked vendor.</summary>
    procedure DetectUnauthorizedVendors() Raised: Integer
    var
        PH: Record "Purchase Header";
        Vendor: Record Vendor;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Purchase to blocked vendor %1', Comment = '%1=vendor';
        DescLbl: Label 'Document %1 exists for vendor %2 which is Blocked (%3). Purchases to blocked vendors should not proceed without authorisation.', Comment = '%1=doc,%2=vendor,%3=block';
    begin
        PH.SetFilter("Document Type", '%1|%2', PH."Document Type"::Order, PH."Document Type"::Invoice);
        PH.SetLoadFields("No.", "Buy-from Vendor No.", "Document Type");
        if PH.FindSet() then
            repeat
                if Vendor.Get(PH."Buy-from Vendor No.") then
                    if Vendor.Blocked <> Vendor.Blocked::" " then begin
                        Hash := CopyStr(StrSubstNo('L1012|%1|%2', PH."Document Type", PH."No."), 1, 100);
                        if not AlertMgt.AlertExists(Hash) then begin
                            AlertNo := AlertMgt.RaiseEntityAlert('L1-012',
                                CopyStr(StrSubstNo(TitleLbl, PH."Buy-from Vendor No."), 1, 150),
                                CopyStr(StrSubstNo(DescLbl, PH."No.", PH."Buy-from Vendor No.", Format(Vendor.Blocked)), 1, 2048),
                                0, Hash, Database::"Purchase Header", PH.SystemId, PH."No.",
                                "RIA Profile Type"::Vendor, Vendor."No.", Vendor.Name);
                            if AlertNo <> 0 then
                                Raised += 1;
                        end;
                    end;
            until PH.Next() = 0;
    end;

    /// <summary>L1-014 Purchases Outside Contracts: order line for an item that has a blanket order with this vendor, but not linked to it.</summary>
    procedure DetectOffContract() Raised: Integer
    var
        PL: Record "Purchase Line";
        Blanket: Record "Purchase Line";
        Vendor: Record Vendor;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Off-contract purchase: item %1', Comment = '%1=item';
        DescLbl: Label 'Order %1 buys item %2 from vendor %3 outside the existing blanket contract. Confirm contract pricing/terms were applied.', Comment = '%1=doc,%2=item,%3=vendor';
    begin
        PL.SetRange("Document Type", PL."Document Type"::Order);
        PL.SetRange(Type, PL.Type::Item);
        PL.SetRange("Blanket Order No.", '');
        PL.SetLoadFields("Document No.", "No.", "Buy-from Vendor No.", "Line No.");
        if PL.FindSet() then
            repeat
                Blanket.SetRange("Document Type", Blanket."Document Type"::"Blanket Order");
                Blanket.SetRange(Type, Blanket.Type::Item);
                Blanket.SetRange("No.", PL."No.");
                Blanket.SetRange("Buy-from Vendor No.", PL."Buy-from Vendor No.");
                if not Blanket.IsEmpty() then begin
                    Hash := CopyStr(StrSubstNo('L1014|%1|%2', PL."Document No.", PL."Line No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        if not Vendor.Get(PL."Buy-from Vendor No.") then
                            Clear(Vendor);
                        AlertNo := AlertMgt.RaiseEntityAlert('L1-014',
                            CopyStr(StrSubstNo(TitleLbl, PL."No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, PL."Document No.", PL."No.", PL."Buy-from Vendor No."), 1, 2048),
                            0, Hash, Database::"Purchase Line", PL.SystemId, PL."Document No.",
                            "RIA Profile Type"::Vendor, PL."Buy-from Vendor No.", Vendor.Name);
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until PL.Next() = 0;
    end;

    /// <summary>L1-015 Approval Violations: released orders above the approval limit with no approved Approval Entry.</summary>
    procedure DetectApprovalViolations() Raised: Integer
    var
        PH: Record "Purchase Header";
        ApprovalEntry: Record "Approval Entry";
        Vendor: Record Vendor;
        Limit: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Approval gap: order %1', Comment = '%1=doc';
        DescLbl: Label 'Order %1 for vendor %2 (%3) is released above the %4 approval limit but has no approved approval entry. Confirm it was properly authorised.', Comment = '%1=doc,%2=vendor,%3=amt,%4=limit';
    begin
        Limit := ApprovalLimit();
        PH.SetRange("Document Type", PH."Document Type"::Order);
        PH.SetRange(Status, PH.Status::Released);
        PH.SetLoadFields("No.", "Buy-from Vendor No.");
        if PH.FindSet() then
            repeat
                PH.CalcFields(Amount);
                if PH.Amount >= Limit then begin
                    ApprovalEntry.SetRange("Table ID", Database::"Purchase Header");
                    ApprovalEntry.SetRange("Document Type", ApprovalEntry."Document Type"::Order);
                    ApprovalEntry.SetRange("Document No.", PH."No.");
                    ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
                    if ApprovalEntry.IsEmpty() then begin
                        Hash := CopyStr(StrSubstNo('L1015|%1', PH."No."), 1, 100);
                        if not AlertMgt.AlertExists(Hash) then begin
                            if not Vendor.Get(PH."Buy-from Vendor No.") then
                                Clear(Vendor);
                            AlertNo := AlertMgt.RaiseEntityAlert('L1-015',
                                CopyStr(StrSubstNo(TitleLbl, PH."No."), 1, 150),
                                CopyStr(StrSubstNo(DescLbl, PH."No.", PH."Buy-from Vendor No.", Format(PH.Amount), Format(Limit)), 1, 2048),
                                PH.Amount, Hash, Database::"Purchase Header", PH.SystemId, PH."No.",
                                "RIA Profile Type"::Vendor, PH."Buy-from Vendor No.", Vendor.Name);
                            if AlertNo <> 0 then
                                Raised += 1;
                        end;
                    end;
                end;
            until PH.Next() = 0;
    end;

    local procedure ApprovalLimit(): Decimal
    var
        Setup: Record "RIA Risk Setup";
    begin
        Setup.GetSetup();
        if Setup."Materiality Floor (LCY)" <= 0 then
            exit(10000);
        exit(Setup."Materiality Floor (LCY)" * 10);
    end;
}
