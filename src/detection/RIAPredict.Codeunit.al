/// <summary>L5 Predictive risk — DETERMINISTIC forward projections (not machine learning).
/// These rule-based projections approximate the FRD's ML models using live BC data.</summary>
codeunit 50125 "RIA Predict"
{
    Access = Public;
    Permissions = tabledata "Cust. Ledger Entry" = r, tabledata "Vendor Ledger Entry" = r,
                  tabledata Customer = r, tabledata Item = r, tabledata "Value Entry" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L5-001 Cash Flow Risk: projected 90-day inflows vs outflows show a shortfall.</summary>
    procedure CashFlowRisk() Raised: Integer
    var
        CLE: Record "Cust. Ledger Entry";
        VLE: Record "Vendor Ledger Entry";
        Inflow: Decimal;
        Outflow: Decimal;
        Net: Decimal;
        HorizonEnd: Date;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Projected cash shortfall (90 days)';
        DescLbl: Label 'Deterministic 90-day projection: receivables due %1 vs payables due %2 = net %3. A projected shortfall warrants a cash-management plan. (Rule-based, not ML.)', Comment = 'positional';
    begin
        HorizonEnd := CalcDate('<+90D>', Today());

        CLE.SetRange(Open, true);
        CLE.SetRange("Due Date", 0D, HorizonEnd);
        CLE.SetLoadFields("Remaining Amt. (LCY)");
        if CLE.FindSet() then
            repeat
                CLE.CalcFields("Remaining Amt. (LCY)");
                Inflow += CLE."Remaining Amt. (LCY)";
            until CLE.Next() = 0;

        VLE.SetRange(Open, true);
        VLE.SetRange("Due Date", 0D, HorizonEnd);
        VLE.SetLoadFields("Remaining Amt. (LCY)");
        if VLE.FindSet() then
            repeat
                VLE.CalcFields("Remaining Amt. (LCY)");
                Outflow += VLE."Remaining Amt. (LCY)";
            until VLE.Next() = 0;

        Net := Inflow + Outflow; // AR positive, AP negative in LCY sign convention
        if Net < 0 then begin
            Hash := CopyStr(StrSubstNo('L5001|%1', Format(Today())), 1, 100);
            if not AlertMgt.AlertExists(Hash) then begin
                AlertNo := AlertMgt.RaiseAlert('L5-001', CopyStr(TitleLbl, 1, 150),
                    CopyStr(StrSubstNo(DescLbl, Format(Inflow), Format(Abs(Outflow)), Format(Net)), 1, 2048),
                    Abs(Net), Hash, Database::"Cust. Ledger Entry", CreateGuid(), '');
                if AlertNo <> 0 then
                    Raised += 1;
            end;
        end;
    end;

    /// <summary>L5-002 Customer Default Risk: high overdue ratio on a material balance.</summary>
    procedure CustomerDefaultRisk() Raised: Integer
    var
        Customer: Record Customer;
        Threshold: Decimal;
        OverdueRatio: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Elevated default risk: %1', Comment = '%1=customer';
        DescLbl: Label 'Customer %1 has %2 overdue of a %3 balance (%4%% overdue). A high overdue ratio signals elevated default risk. (Rule-based score, not ML.)', Comment = 'positional';
    begin
        Threshold := MaterialityX(2);
        Customer.SetLoadFields("No.", Name);
        if Customer.FindSet() then
            repeat
                Customer.CalcFields("Balance (LCY)", "Balance Due (LCY)");
                if (Customer."Balance (LCY)" > 0) and (Customer."Balance Due (LCY)" >= Threshold) then begin
                    OverdueRatio := Round(Customer."Balance Due (LCY)" / Customer."Balance (LCY)" * 100, 0.1);
                    if OverdueRatio >= 50 then begin
                        Hash := CopyStr(StrSubstNo('L5002|%1|%2', Customer."No.", Format(Today())), 1, 100);
                        if not AlertMgt.AlertExists(Hash) then begin
                            AlertNo := AlertMgt.RaiseEntityAlert('L5-002', CopyStr(StrSubstNo(TitleLbl, Customer."No."), 1, 150),
                                CopyStr(StrSubstNo(DescLbl, Customer."No.", Format(Customer."Balance Due (LCY)"), Format(Customer."Balance (LCY)"), Format(OverdueRatio)), 1, 2048),
                                Customer."Balance Due (LCY)", Hash, Database::Customer, Customer.SystemId, Customer."No.",
                                "RIA Profile Type"::Customer, Customer."No.", Customer.Name);
                            if AlertNo <> 0 then
                                Raised += 1;
                        end;
                    end;
                end;
            until Customer.Next() = 0;
    end;

    /// <summary>L5-003 Inventory Shortage Risk: on-hand below reorder point.</summary>
    procedure InventoryShortageRisk() Raised: Integer
    var
        Item: Record Item;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Projected shortage: item %1', Comment = '%1=item';
        DescLbl: Label 'Item %1 on-hand %2 is below its reorder point %3. Without replenishment a stock-out is projected. (Rule-based, not ML.)', Comment = 'positional';
    begin
        Item.SetRange(Type, Item.Type::Inventory);
        Item.SetFilter("Reorder Point", '>0');
        Item.SetLoadFields("No.", Description, "Reorder Point");
        if Item.FindSet() then
            repeat
                Item.CalcFields(Inventory);
                if Item.Inventory < Item."Reorder Point" then begin
                    Hash := CopyStr(StrSubstNo('L5003|%1|%2', Item."No.", Format(Today())), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L5-003', CopyStr(StrSubstNo(TitleLbl, Item."No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, Item."No.", Format(Item.Inventory), Format(Item."Reorder Point")), 1, 2048),
                            Item."Reorder Point" - Item.Inventory, Hash, Database::Item, Item.SystemId, Item."No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until Item.Next() = 0;
    end;

    /// <summary>L5-004 Margin Erosion Risk: current-quarter sales margin below prior quarter.</summary>
    procedure MarginErosionRisk() Raised: Integer
    var
        CurrMargin: Decimal;
        PriorMargin: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Margin erosion trend detected';
        DescLbl: Label 'Company sales margin fell from %1%% (prior 90 days) to %2%% (last 90 days). A sustained decline erodes profitability. (Rule-based trend, not ML.)', Comment = 'positional';
    begin
        CurrMargin := PeriodMargin(CalcDate('<-90D>', Today()), Today());
        PriorMargin := PeriodMargin(CalcDate('<-180D>', Today()), CalcDate('<-91D>', Today()));
        if (PriorMargin <> 0) and (CurrMargin < PriorMargin - 5) then begin
            Hash := CopyStr(StrSubstNo('L5004|%1', Format(CalcDate('<CM>', Today()))), 1, 100);
            if not AlertMgt.AlertExists(Hash) then begin
                AlertNo := AlertMgt.RaiseAlert('L5-004', CopyStr(TitleLbl, 1, 150),
                    CopyStr(StrSubstNo(DescLbl, Format(PriorMargin), Format(CurrMargin)), 1, 2048),
                    0, Hash, Database::"Value Entry", CreateGuid(), '');
                if AlertNo <> 0 then
                    Raised += 1;
            end;
        end;
    end;

    local procedure PeriodMargin(FromDate: Date; ToDate: Date): Decimal
    var
        ValueEntry: Record "Value Entry";
        SalesAmt: Decimal;
        CostAmt: Decimal;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry Type", "Posting Date");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Posting Date", FromDate, ToDate);
        ValueEntry.CalcSums("Sales Amount (Actual)", "Cost Amount (Actual)");
        SalesAmt := ValueEntry."Sales Amount (Actual)";
        CostAmt := ValueEntry."Cost Amount (Actual)";
        if SalesAmt = 0 then
            exit(0);
        exit(Round((SalesAmt - CostAmt) / SalesAmt * 100, 0.1));
    end;

    local procedure MaterialityX(Multiplier: Decimal): Decimal
    var
        Setup: Record "RIA Risk Setup";
    begin
        Setup.GetSetup();
        if Setup."Materiality Floor (LCY)" <= 0 then
            exit(1000 * Multiplier);
        exit(Setup."Materiality Floor (LCY)" * Multiplier);
    end;
}
