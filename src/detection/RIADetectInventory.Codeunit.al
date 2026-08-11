/// <summary>Inventory-domain L1 detection (L1-022 to L1-026).</summary>
codeunit 50118 "RIA Detect Inventory"
{
    Access = Public;
    Permissions = tabledata Item = r, tabledata "Item Ledger Entry" = r,
                  tabledata "Lot No. Information" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L1-022 Inventory Shrinkage: material negative adjustments over the window.</summary>
    procedure DetectShrinkage() Raised: Integer
    var
        ILE: Record "Item Ledger Entry";
        Item: Record Item;
        QtyThreshold: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Inventory shrinkage: item %1', Comment = '%1=item';
        DescLbl: Label 'Item %1 had a negative adjustment of %2 on %3. Recurring or large shrinkage indicates loss, theft, or process error — investigate.', Comment = '%1=item,%2=qty,%3=date';
    begin
        QtyThreshold := 0;
        ILE.SetCurrentKey("Entry Type", "Item No.", "Posting Date");
        ILE.SetRange("Entry Type", ILE."Entry Type"::"Negative Adjmt.");
        ILE.SetRange("Posting Date", CalcDate('<-90D>', Today()), Today());
        ILE.SetFilter(Quantity, '<%1', QtyThreshold);
        ILE.SetLoadFields("Item No.", Quantity, "Posting Date", "Entry No.");
        if ILE.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1022|%1', ILE."Entry No."), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    if not Item.Get(ILE."Item No.") then
                        Clear(Item);
                    AlertNo := AlertMgt.RaiseAlert('L1-022',
                        CopyStr(StrSubstNo(TitleLbl, ILE."Item No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, ILE."Item No.", Format(ILE.Quantity), Format(ILE."Posting Date")), 1, 2048),
                        Abs(ILE.Quantity), Hash, Database::"Item Ledger Entry", ILE.SystemId, '');
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until ILE.Next() = 0;
    end;

    /// <summary>L1-023 Excessive Inventory Adjustments: items with many adjustment entries in the window.</summary>
    procedure DetectExcessiveAdjustments() Raised: Integer
    var
        Item: Record Item;
        ILE: Record "Item Ledger Entry";
        AdjCount: Integer;
        MaxCount: Integer;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Frequent adjustments: item %1', Comment = '%1=item';
        DescLbl: Label 'Item %1 had %2 inventory adjustments in the last 90 days (above %3). Excessive adjustments can mask errors or manipulation.', Comment = '%1=item,%2=count,%3=max';
    begin
        MaxCount := 10;
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetLoadFields("No.", Description);
        if Item.FindSet() then
            repeat
                ILE.SetCurrentKey("Item No.", "Entry Type", "Posting Date");
                ILE.SetRange("Item No.", Item."No.");
                ILE.SetFilter("Entry Type", '%1|%2', ILE."Entry Type"::"Positive Adjmt.", ILE."Entry Type"::"Negative Adjmt.");
                ILE.SetRange("Posting Date", CalcDate('<-90D>', Today()), Today());
                AdjCount := ILE.Count();
                if AdjCount > MaxCount then begin
                    Hash := CopyStr(StrSubstNo('L1023|%1|%2', Item."No.", Format(Today())), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L1-023',
                            CopyStr(StrSubstNo(TitleLbl, Item."No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, Item."No.", AdjCount, MaxCount), 1, 2048),
                            0, Hash, Database::Item, Item.SystemId, Item."No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until Item.Next() = 0;
    end;

    /// <summary>L1-024 Slow Moving Inventory: on-hand items with no sales movement in 180 days.</summary>
    procedure DetectSlowMoving() Raised: Integer
    begin
        exit(DetectStaleStock('L1-024', 180, StrSubstNo('Slow-moving')));
    end;

    /// <summary>L1-025 Dead Stock: on-hand items with no movement in 365 days.</summary>
    procedure DetectDeadStock() Raised: Integer
    begin
        exit(DetectStaleStock('L1-025', 365, StrSubstNo('Dead stock')));
    end;

    local procedure DetectStaleStock(ControlID: Code[20]; Days: Integer; Kind: Text) Raised: Integer
    var
        Item: Record Item;
        ILE: Record "Item Ledger Entry";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label '%1: item %2', Comment = '%1=kind,%2=item';
        DescLbl: Label '%1 — item %2 holds inventory but has had no sales movement in %3 days. Tied-up capital and obsolescence/NRV write-down risk.', Comment = '%1=kind,%2=item,%3=days';
    begin
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetLoadFields("No.", Description);
        if Item.FindSet() then
            repeat
                Item.CalcFields(Inventory);
                if Item.Inventory > 0 then begin
                    ILE.SetCurrentKey("Item No.", "Entry Type", "Posting Date");
                    ILE.SetRange("Item No.", Item."No.");
                    ILE.SetRange("Entry Type", ILE."Entry Type"::Sale);
                    ILE.SetRange("Posting Date", CalcDate('<-' + Format(Days) + 'D>', Today()), Today());
                    if ILE.IsEmpty() then begin
                        Hash := CopyStr(StrSubstNo('%1|%2|%3', ControlID, Item."No.", Format(Today())), 1, 100);
                        if not AlertMgt.AlertExists(Hash) then begin
                            AlertNo := AlertMgt.RaiseAlert(ControlID,
                                CopyStr(StrSubstNo(TitleLbl, Kind, Item."No."), 1, 150),
                                CopyStr(StrSubstNo(DescLbl, Kind, Item."No.", Format(Days)), 1, 2048),
                                Item.Inventory, Hash, Database::Item, Item.SystemId, Item."No.");
                            if AlertNo <> 0 then
                                Raised += 1;
                        end;
                    end;
                end;
            until Item.Next() = 0;
    end;

    /// <summary>L1-026 Lot Tracking Risks: expired lots still showing remaining quantity.</summary>
    procedure DetectLotRisks() Raised: Integer
    var
        ILE: Record "Item Ledger Entry";
        Item: Record Item;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Expired lot in stock: item %1', Comment = '%1=item';
        DescLbl: Label 'Item %1 lot %2 has expiration date %3 (passed) but still shows remaining quantity %4. Quarantine or write off expired stock.', Comment = '%1=item,%2=lot,%3=exp,%4=qty';
    begin
        ILE.SetCurrentKey("Item No.", Open, "Expiration Date");
        ILE.SetRange(Open, true);
        ILE.SetFilter("Lot No.", '<>%1', '');
        ILE.SetFilter("Expiration Date", '<%1&<>%2', Today(), 0D);
        ILE.SetFilter("Remaining Quantity", '>0');
        ILE.SetLoadFields("Item No.", "Lot No.", "Expiration Date", "Remaining Quantity", "Entry No.");
        if ILE.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1026|%1|%2', ILE."Item No.", ILE."Lot No."), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    if not Item.Get(ILE."Item No.") then
                        Clear(Item);
                    AlertNo := AlertMgt.RaiseAlert('L1-026',
                        CopyStr(StrSubstNo(TitleLbl, ILE."Item No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, ILE."Item No.", ILE."Lot No.", Format(ILE."Expiration Date"), Format(ILE."Remaining Quantity")), 1, 2048),
                        ILE."Remaining Quantity", Hash, Database::"Item Ledger Entry", ILE.SystemId, '');
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until ILE.Next() = 0;
    end;
}
