/// <summary>L1-006 Credit Limit Violations. Flags customers whose balance + outstanding exceeds their credit limit.</summary>
codeunit 50113 "RIA Detect Credit Limit"
{
    Access = Public;
    Permissions = tabledata Customer = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";
        ControlIDLbl: Label 'L1-006', Locked = true;

    /// <summary>Scans customers for credit limit breaches. Returns alerts raised.</summary>
    procedure Detect() AlertsRaised: Integer
    var
        Customer: Record Customer;
        Exposure: Decimal;
    begin
        Customer.SetLoadFields("No.", Name, "Credit Limit (LCY)");
        if Customer.FindSet() then
            repeat
                if Customer."Credit Limit (LCY)" > 0 then begin
                    Customer.CalcFields("Balance (LCY)", "Outstanding Orders (LCY)", "Shipped Not Invoiced (LCY)");
                    Exposure := Customer."Balance (LCY)" + Customer."Outstanding Orders (LCY)" + Customer."Shipped Not Invoiced (LCY)";
                    if Exposure > Customer."Credit Limit (LCY)" then
                        if RaiseCreditAlert(Customer, Exposure) then
                            AlertsRaised += 1;
                end;
            until Customer.Next() = 0;
    end;

    local procedure RaiseCreditAlert(var Customer: Record Customer; Exposure: Decimal) Raised: Boolean
    var
        AlertNo: Integer;
        Hash: Text[100];
        Overage: Decimal;
        TitleTxt: Text[150];
        DescTxt: Text[2048];
        TitleLbl: Label 'Credit limit exceeded: %1', Comment = '%1 = Customer No.';
        DescLbl: Label 'Customer %1 has total exposure of %2 against a credit limit of %3 (over by %4). Review before processing further orders.', Comment = '%1=Cust,%2=Exposure,%3=Limit,%4=Overage';
    begin
        Overage := Exposure - Customer."Credit Limit (LCY)";
        Hash := CopyStr(StrSubstNo('L1006|%1|%2', Customer."No.", Format(Today())), 1, 100);
        if AlertMgt.AlertExists(Hash) then
            exit(false);

        TitleTxt := CopyStr(StrSubstNo(TitleLbl, Customer."No."), 1, MaxStrLen(TitleTxt));
        DescTxt := CopyStr(StrSubstNo(DescLbl, Customer."No.", Format(Exposure),
            Format(Customer."Credit Limit (LCY)"), Format(Overage)), 1, MaxStrLen(DescTxt));

        AlertNo := AlertMgt.RaiseAlert(ControlIDLbl, TitleTxt, DescTxt, Overage, Hash,
            Database::Customer, Customer.SystemId, Customer."No.");
        if AlertNo = 0 then
            exit(false);

        AlertMgt.SetEntity(AlertNo, "RIA Profile Type"::Customer, Customer."No.", Customer.Name);
        AlertMgt.AddEvidence(AlertNo, 'Credit limit vs exposure', Database::Customer,
            'Credit Limit (LCY)', Format(Customer."Credit Limit (LCY)"), Format(Exposure));
        exit(true);
    end;
}
