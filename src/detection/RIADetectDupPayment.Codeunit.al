/// <summary>L1-001 Duplicate Payments. Detects vendor payments with identical amount + external document within a window.</summary>
codeunit 50111 "RIA Detect Dup Payment"
{
    Access = Public;
    Permissions = tabledata "Vendor Ledger Entry" = r,
                  tabledata "Detailed Vendor Ledg. Entry" = r,
                  tabledata Vendor = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";
        ControlIDLbl: Label 'L1-001', Locked = true;

    /// <summary>Scans recent vendor payments for duplicates. Returns the number of alerts raised.</summary>
    procedure Detect() AlertsRaised: Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Threshold: Record "RIA Threshold Setup";
        WindowDays: Integer;
    begin
        WindowDays := 90;
        if Threshold.Get(ControlIDLbl) then
            if Threshold."Day Threshold" > 0 then
                WindowDays := Threshold."Day Threshold";

        VendorLedgerEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange("Posting Date", CalcDate('<-' + Format(WindowDays) + 'D>', Today()), Today());
        VendorLedgerEntry.SetLoadFields("Vendor No.", "External Document No.", Amount,
            "Amount (LCY)", "Document No.", "Posting Date", "Entry No.");
        if VendorLedgerEntry.FindSet() then
            repeat
                if IsDuplicate(VendorLedgerEntry) then
                    if RaiseDuplicateAlert(VendorLedgerEntry) then
                        AlertsRaised += 1;
            until VendorLedgerEntry.Next() = 0;
    end;

    local procedure IsDuplicate(var BaseEntry: Record "Vendor Ledger Entry"): Boolean
    var
        CompareEntry: Record "Vendor Ledger Entry";
    begin
        CompareEntry.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
        CompareEntry.SetRange("Document Type", CompareEntry."Document Type"::Payment);
        CompareEntry.SetRange("Vendor No.", BaseEntry."Vendor No.");
        CompareEntry.SetRange("Amount (LCY)", BaseEntry."Amount (LCY)");
        CompareEntry.SetFilter("Entry No.", '<>%1', BaseEntry."Entry No.");
        if BaseEntry."External Document No." <> '' then
            CompareEntry.SetRange("External Document No.", BaseEntry."External Document No.");
        CompareEntry.SetRange("Posting Date",
            CalcDate('<-90D>', BaseEntry."Posting Date"), CalcDate('<+90D>', BaseEntry."Posting Date"));
        exit(not CompareEntry.IsEmpty());
    end;

    local procedure RaiseDuplicateAlert(var VendorLedgerEntry: Record "Vendor Ledger Entry") Raised: Boolean
    var
        Vendor: Record Vendor;
        AlertNo: Integer;
        Hash: Text[100];
        TitleTxt: Text[150];
        DescTxt: Text[2048];
        TitleLbl: Label 'Possible duplicate payment to %1', Comment = '%1 = Vendor No.';
        DescLbl: Label 'Payment %1 of %2 to vendor %3 matches another payment with the same amount%4 within the detection window. Verify before the next payment run.', Comment = '%1=Doc No, %2=Amount, %3=Vendor, %4=ext doc clause';
        ExtClauseLbl: Label ' and external document %1', Comment = '%1 = External Document No.';
        ExtClause: Text;
    begin
        Hash := MakeHash(VendorLedgerEntry);
        if AlertMgt.AlertExists(Hash) then
            exit(false);

        if VendorLedgerEntry."External Document No." <> '' then
            ExtClause := StrSubstNo(ExtClauseLbl, VendorLedgerEntry."External Document No.");

        TitleTxt := CopyStr(StrSubstNo(TitleLbl, VendorLedgerEntry."Vendor No."), 1, MaxStrLen(TitleTxt));
        DescTxt := CopyStr(StrSubstNo(DescLbl, VendorLedgerEntry."Document No.",
            Format(Abs(VendorLedgerEntry."Amount (LCY)")), VendorLedgerEntry."Vendor No.", ExtClause), 1, MaxStrLen(DescTxt));

        AlertNo := AlertMgt.RaiseAlert(ControlIDLbl, TitleTxt, DescTxt, Abs(VendorLedgerEntry."Amount (LCY)"),
            Hash, Database::"Vendor Ledger Entry", VendorLedgerEntry.SystemId, VendorLedgerEntry."Document No.");
        if AlertNo = 0 then
            exit(false);

        if Vendor.Get(VendorLedgerEntry."Vendor No.") then
            AlertMgt.SetEntity(AlertNo, "RIA Profile Type"::Vendor, Vendor."No.", Vendor.Name);

        AlertMgt.AddEvidence(AlertNo, 'Vendor Ledger Entry (payment)', Database::"Vendor Ledger Entry",
            'Amount (LCY)', '', Format(VendorLedgerEntry."Amount (LCY)"));
        AlertMgt.AddEvidence(AlertNo, 'External Document No.', Database::"Vendor Ledger Entry",
            'External Document No.', '', VendorLedgerEntry."External Document No.");
        exit(true);
    end;

    local procedure MakeHash(var VendorLedgerEntry: Record "Vendor Ledger Entry"): Text[100]
    begin
        exit(CopyStr(StrSubstNo('L1001|%1|%2|%3', VendorLedgerEntry."Vendor No.",
            Format(VendorLedgerEntry."Amount (LCY)"), VendorLedgerEntry."External Document No."), 1, 100));
    end;
}
