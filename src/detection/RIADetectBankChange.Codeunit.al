/// <summary>L1-013 Vendor Bank Account Changes. Correlates Change Log entries on the Vendor Bank Account table with recent payments (BEC fraud vector).</summary>
codeunit 50112 "RIA Detect Bank Change"
{
    Access = Public;
    Permissions = tabledata "Change Log Entry" = r,
                  tabledata "Vendor Ledger Entry" = r,
                  tabledata Vendor = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";
        ControlIDLbl: Label 'L1-013', Locked = true;

    /// <summary>Detects bank account changes followed by a payment within the hold window. Returns alerts raised.</summary>
    procedure Detect() AlertsRaised: Integer
    var
        ChangeLogEntry: Record "Change Log Entry";
        HoldDays: Integer;
        VendorNo: Code[20];
    begin
        HoldDays := 5;

        ChangeLogEntry.SetCurrentKey("Date and Time");
        ChangeLogEntry.SetRange("Table No.", Database::"Vendor Bank Account");
        ChangeLogEntry.SetFilter("Field No.", '%1|%2|%3',
            GetFieldNo('Bank Account No.'), GetFieldNo('IBAN'), GetFieldNo('SWIFT Code'));
        ChangeLogEntry.SetFilter("Date and Time", '>=%1', CreateDateTime(CalcDate('<-30D>', Today()), 0T));
        ChangeLogEntry.SetLoadFields("Primary Key Field 1 Value", "Date and Time", "User ID",
            "Old Value", "New Value", "Field Caption");
        if ChangeLogEntry.FindSet() then
            repeat
                VendorNo := CopyStr(ChangeLogEntry."Primary Key Field 1 Value", 1, 20);
                if PaymentAfterChange(VendorNo, DT2Date(ChangeLogEntry."Date and Time"), HoldDays) then
                    if RaiseBankChangeAlert(ChangeLogEntry, VendorNo) then
                        AlertsRaised += 1;
            until ChangeLogEntry.Next() = 0;
    end;

    local procedure PaymentAfterChange(VendorNo: Code[20]; ChangeDate: Date; HoldDays: Integer): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendorNo = '' then
            exit(false);
        VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Posting Date", ChangeDate, CalcDate('<+' + Format(HoldDays) + 'D>', ChangeDate));
        exit(not VendorLedgerEntry.IsEmpty());
    end;

    local procedure RaiseBankChangeAlert(var ChangeLogEntry: Record "Change Log Entry"; VendorNo: Code[20]) Raised: Boolean
    var
        Vendor: Record Vendor;
        AlertNo: Integer;
        Hash: Text[100];
        TitleTxt: Text[150];
        DescTxt: Text[2048];
        TitleLbl: Label 'Vendor bank account changed then paid: %1', Comment = '%1 = Vendor No.';
        DescLbl: Label 'The bank details for vendor %1 were changed by %2 on %3, and a payment was made within the hold window. Verify the change out-of-band using a pre-registered phone number before releasing further payments (possible BEC fraud).', Comment = '%1=Vendor,%2=User,%3=Date';
    begin
        Hash := CopyStr(StrSubstNo('L1013|%1|%2|%3', VendorNo,
            Format(ChangeLogEntry."Date and Time"), ChangeLogEntry."Field Caption"), 1, 100);
        if AlertMgt.AlertExists(Hash) then
            exit(false);

        TitleTxt := CopyStr(StrSubstNo(TitleLbl, VendorNo), 1, MaxStrLen(TitleTxt));
        DescTxt := CopyStr(StrSubstNo(DescLbl, VendorNo, ChangeLogEntry."User ID",
            Format(DT2Date(ChangeLogEntry."Date and Time"))), 1, MaxStrLen(DescTxt));

        AlertNo := AlertMgt.RaiseAlert(ControlIDLbl, TitleTxt, DescTxt, 0, Hash,
            Database::"Vendor Bank Account", ChangeLogEntry.SystemId, VendorNo);
        if AlertNo = 0 then
            exit(false);

        if Vendor.Get(VendorNo) then
            AlertMgt.SetEntity(AlertNo, "RIA Profile Type"::Vendor, Vendor."No.", Vendor.Name);

        AlertMgt.AddEvidence(AlertNo, 'Change Log: bank detail modified', Database::"Vendor Bank Account",
            ChangeLogEntry."Field Caption", ChangeLogEntry."Old Value", ChangeLogEntry."New Value");
        exit(true);
    end;

    local procedure GetFieldNo(FieldName: Text): Integer
    var
        VendorBankAccount: Record "Vendor Bank Account";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        i: Integer;
    begin
        RecRef.GetTable(VendorBankAccount);
        for i := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Name() = FieldName then
                exit(FieldRef.Number());
        end;
        exit(0);
    end;
}
