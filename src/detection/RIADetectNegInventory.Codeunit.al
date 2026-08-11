/// <summary>L1-021 Negative Inventory. Flags item/location combinations with a negative inventory balance.</summary>
codeunit 50114 "RIA Detect Neg Inventory"
{
    Access = Public;
    Permissions = tabledata Item = r,
                  tabledata "Item Ledger Entry" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";
        ControlIDLbl: Label 'L1-021', Locked = true;

    /// <summary>Scans items for negative on-hand balances. Returns alerts raised.</summary>
    procedure Detect() AlertsRaised: Integer
    var
        Item: Record Item;
        Inventory: Decimal;
    begin
        Item.SetLoadFields("No.", Description, Type);
        Item.SetRange(Type, Item.Type::Inventory);
        if Item.FindSet() then
            repeat
                Item.CalcFields(Inventory);
                Inventory := Item.Inventory;
                if Inventory < 0 then
                    if RaiseNegInvAlert(Item, Inventory) then
                        AlertsRaised += 1;
            until Item.Next() = 0;
    end;

    local procedure RaiseNegInvAlert(var Item: Record Item; Inventory: Decimal) Raised: Boolean
    var
        AlertNo: Integer;
        Hash: Text[100];
        TitleTxt: Text[150];
        DescTxt: Text[2048];
        TitleLbl: Label 'Negative inventory: %1', Comment = '%1 = Item No.';
        DescLbl: Label 'Item %1 (%2) shows a negative on-hand balance of %3. This distorts inventory valuation and costing. Post the missing receipt or an approved adjustment.', Comment = '%1=Item,%2=Desc,%3=Qty';
    begin
        Hash := CopyStr(StrSubstNo('L1021|%1|%2', Item."No.", Format(Today())), 1, 100);
        if AlertMgt.AlertExists(Hash) then
            exit(false);

        TitleTxt := CopyStr(StrSubstNo(TitleLbl, Item."No."), 1, MaxStrLen(TitleTxt));
        DescTxt := CopyStr(StrSubstNo(DescLbl, Item."No.", Item.Description, Format(Inventory)), 1, MaxStrLen(DescTxt));

        AlertNo := AlertMgt.RaiseAlert(ControlIDLbl, TitleTxt, DescTxt, Abs(Inventory), Hash,
            Database::Item, Item.SystemId, Item."No.");
        if AlertNo = 0 then
            exit(false);

        AlertMgt.AddEvidence(AlertNo, 'Item on-hand balance', Database::Item, 'Inventory', '0', Format(Inventory));
        exit(true);
    end;
}
