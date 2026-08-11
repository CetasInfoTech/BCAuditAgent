/// <summary>Sales-domain L1 detection (L1-016 to L1-020).</summary>
codeunit 50117 "RIA Detect Sales"
{
    Access = Public;
    Permissions = tabledata "Sales Line" = r, tabledata "Sales Header" = r,
                  tabledata Customer = r, tabledata "Cust. Ledger Entry" = r,
                  tabledata "Sales Cr.Memo Header" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L1-016 Margin Erosion: open sales lines whose gross margin is below the minimum threshold.</summary>
    procedure DetectMarginErosion() Raised: Integer
    var
        SL: Record "Sales Line";
        Customer: Record Customer;
        MinMargin: Decimal;
        Margin: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Low margin: item %1', Comment = '%1=item';
        DescLbl: Label 'Sales doc %1 sells item %2 at margin %3%% (below %4%%). Unit price %5 vs unit cost %6. Review pricing.', Comment = '%1=doc,%2=item,%3=margin,%4=min,%5=price,%6=cost';
    begin
        MinMargin := 10;
        SL.SetRange(Type, SL.Type::Item);
        SL.SetFilter("Unit Price", '>0');
        SL.SetLoadFields("Document No.", "No.", "Unit Price", "Unit Cost (LCY)", "Sell-to Customer No.", "Line No.");
        if SL.FindSet() then
            repeat
                if SL."Unit Price" > 0 then begin
                    Margin := Round((SL."Unit Price" - SL."Unit Cost (LCY)") / SL."Unit Price" * 100, 0.1);
                    if Margin < MinMargin then begin
                        Hash := CopyStr(StrSubstNo('L1016|%1|%2', SL."Document No.", SL."Line No."), 1, 100);
                        if not AlertMgt.AlertExists(Hash) then begin
                            if not Customer.Get(SL."Sell-to Customer No.") then
                                Clear(Customer);
                            AlertNo := AlertMgt.RaiseEntityAlert('L1-016',
                                CopyStr(StrSubstNo(TitleLbl, SL."No."), 1, 150),
                                CopyStr(StrSubstNo(DescLbl, SL."Document No.", SL."No.", Format(Margin), Format(MinMargin), Format(SL."Unit Price"), Format(SL."Unit Cost (LCY)")), 1, 2048),
                                0, Hash, Database::"Sales Line", SL.SystemId, SL."Document No.",
                                "RIA Profile Type"::Customer, SL."Sell-to Customer No.", Customer.Name);
                            if AlertNo <> 0 then
                                Raised += 1;
                        end;
                    end;
                end;
            until SL.Next() = 0;
    end;

    /// <summary>L1-017 Pricing Deviations: line discount above the allowed maximum.</summary>
    procedure DetectPricingDeviations() Raised: Integer
    var
        SL: Record "Sales Line";
        Customer: Record Customer;
        MaxDisc: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'High discount: item %1', Comment = '%1=item';
        DescLbl: Label 'Sales doc %1 applies a %2%% line discount on item %3 (above the %4%% threshold). Confirm the discount was authorised.', Comment = '%1=doc,%2=disc,%3=item,%4=max';
    begin
        MaxDisc := 30;
        SL.SetRange(Type, SL.Type::Item);
        SL.SetFilter("Line Discount %", '>%1', MaxDisc);
        SL.SetLoadFields("Document No.", "No.", "Line Discount %", "Sell-to Customer No.", "Line No.");
        if SL.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1017|%1|%2', SL."Document No.", SL."Line No."), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    if not Customer.Get(SL."Sell-to Customer No.") then
                        Clear(Customer);
                    AlertNo := AlertMgt.RaiseEntityAlert('L1-017',
                        CopyStr(StrSubstNo(TitleLbl, SL."No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, SL."Document No.", Format(SL."Line Discount %"), SL."No.", Format(MaxDisc)), 1, 2048),
                        0, Hash, Database::"Sales Line", SL.SystemId, SL."Document No.",
                        "RIA Profile Type"::Customer, SL."Sell-to Customer No.", Customer.Name);
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until SL.Next() = 0;
    end;

    /// <summary>L1-018 Revenue Leakage: customers with material shipped-not-invoiced value (delivered but unbilled).</summary>
    procedure DetectRevenueLeakage() Raised: Integer
    var
        Customer: Record Customer;
        Threshold: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Unbilled shipments: %1', Comment = '%1=customer';
        DescLbl: Label 'Customer %1 has %2 shipped but not invoiced. Delivered goods that remain unbilled are revenue leakage — raise the invoices.', Comment = '%1=customer,%2=amt';
    begin
        Threshold := MaterialityX(2);
        Customer.SetLoadFields("No.", Name);
        if Customer.FindSet() then
            repeat
                Customer.CalcFields("Shipped Not Invoiced (LCY)");
                if Customer."Shipped Not Invoiced (LCY)" >= Threshold then begin
                    Hash := CopyStr(StrSubstNo('L1018|%1|%2', Customer."No.", Format(Today())), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseEntityAlert('L1-018',
                            CopyStr(StrSubstNo(TitleLbl, Customer."No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, Customer."No.", Format(Customer."Shipped Not Invoiced (LCY)")), 1, 2048),
                            Customer."Shipped Not Invoiced (LCY)", Hash, Database::Customer, Customer.SystemId, Customer."No.",
                            "RIA Profile Type"::Customer, Customer."No.", Customer.Name);
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until Customer.Next() = 0;
    end;

    /// <summary>L1-019 Suspicious Returns: material credit memos, especially clustered near period-end.</summary>
    procedure DetectSuspiciousReturns() Raised: Integer
    var
        CrMemo: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        Threshold: Decimal;
        NearPeriodEnd: Boolean;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Material credit memo: %1', Comment = '%1=customer';
        DescLbl: Label 'Credit memo %1 for customer %2 of %3 was posted on %4%5. Large or period-end returns can mask revenue manipulation — review.', Comment = '%1=doc,%2=customer,%3=amt,%4=date,%5=periodend';
        PeLbl: Label ' (near period-end)';
    begin
        Threshold := MaterialityX(3);
        CrMemo.SetRange("Posting Date", CalcDate('<-90D>', Today()), Today());
        CrMemo.SetLoadFields("No.", "Sell-to Customer No.", "Posting Date", "Amount Including VAT");
        if CrMemo.FindSet() then
            repeat
                CrMemo.CalcFields("Amount Including VAT");
                if CrMemo."Amount Including VAT" >= Threshold then begin
                    NearPeriodEnd := (CalcDate('<CM>', CrMemo."Posting Date") - CrMemo."Posting Date") <= 3;
                    Hash := CopyStr(StrSubstNo('L1019|%1', CrMemo."No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        if not Customer.Get(CrMemo."Sell-to Customer No.") then
                            Clear(Customer);
                        AlertNo := AlertMgt.RaiseEntityAlert('L1-019',
                            CopyStr(StrSubstNo(TitleLbl, CrMemo."Sell-to Customer No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, CrMemo."No.", CrMemo."Sell-to Customer No.", Format(CrMemo."Amount Including VAT"), Format(CrMemo."Posting Date"), PeriodEndText(NearPeriodEnd, PeLbl)), 1, 2048),
                            CrMemo."Amount Including VAT", Hash, Database::"Sales Cr.Memo Header", CrMemo.SystemId, CrMemo."No.",
                            "RIA Profile Type"::Customer, CrMemo."Sell-to Customer No.", Customer.Name);
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until CrMemo.Next() = 0;
    end;

    /// <summary>L1-020 Customer Credit Risks: material overdue receivables.</summary>
    procedure DetectCustomerCreditRisk() Raised: Integer
    var
        Customer: Record Customer;
        Threshold: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Overdue receivable: %1', Comment = '%1=customer';
        DescLbl: Label 'Customer %1 has %2 overdue (balance due). Rising overdue balances signal credit risk — review credit terms and collections.', Comment = '%1=customer,%2=amt';
    begin
        Threshold := MaterialityX(2);
        Customer.SetLoadFields("No.", Name);
        if Customer.FindSet() then
            repeat
                Customer.CalcFields("Balance Due (LCY)");
                if Customer."Balance Due (LCY)" >= Threshold then begin
                    Hash := CopyStr(StrSubstNo('L1020|%1|%2', Customer."No.", Format(Today())), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseEntityAlert('L1-020',
                            CopyStr(StrSubstNo(TitleLbl, Customer."No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, Customer."No.", Format(Customer."Balance Due (LCY)")), 1, 2048),
                            Customer."Balance Due (LCY)", Hash, Database::Customer, Customer.SystemId, Customer."No.",
                            "RIA Profile Type"::Customer, Customer."No.", Customer.Name);
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until Customer.Next() = 0;
    end;

    local procedure PeriodEndText(NearPeriodEnd: Boolean; PeLbl: Text): Text
    begin
        if NearPeriodEnd then
            exit(PeLbl);
        exit('');
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
