/// <summary>Master-Data-domain L1 detection (L1-MD01 to MD04).</summary>
codeunit 50122 "RIA Detect Master Data"
{
    Access = Public;
    Permissions = tabledata Vendor = r, tabledata Customer = r,
                  tabledata "Vendor Bank Account" = r, tabledata "Change Log Entry" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L1-MD01 Duplicate Vendors: vendors sharing a VAT registration no. or normalized name.</summary>
    procedure DetectDuplicateVendors() Raised: Integer
    var
        Vendor: Record Vendor;
        Cmp: Record Vendor;
        TitleLbl: Label 'Possible duplicate vendor: %1', Comment = '%1=vendor';
        DescLbl: Label 'Vendor %1 (%2) appears to duplicate vendor %3 (same %4). Duplicate master records enable double payment and split spend — merge or block.', Comment = 'positional';
    begin
        Vendor.SetLoadFields("No.", Name, "VAT Registration No.");
        if Vendor.FindSet() then
            repeat
                // Match on VAT Registration No.
                if Vendor."VAT Registration No." <> '' then begin
                    Cmp.SetFilter("No.", '<>%1', Vendor."No.");
                    Cmp.SetRange("VAT Registration No.", Vendor."VAT Registration No.");
                    if Cmp.FindFirst() then
                        if RaiseDup('L1-MD01', Vendor."No.", Vendor.Name, Cmp."No.", 'VAT reg. no.', Vendor.SystemId, Database::Vendor, "RIA Profile Type"::Vendor, TitleLbl, DescLbl) then
                            Raised += 1;
                end;
            until Vendor.Next() = 0;
    end;

    /// <summary>L1-MD02 Duplicate Customers: customers sharing a VAT registration no.</summary>
    procedure DetectDuplicateCustomers() Raised: Integer
    var
        Customer: Record Customer;
        Cmp: Record Customer;
        TitleLbl: Label 'Possible duplicate customer: %1', Comment = '%1=customer';
        DescLbl: Label 'Customer %1 (%2) appears to duplicate customer %3 (same %4). Duplicates fragment credit exposure and reporting — merge or block.', Comment = 'positional';
    begin
        Customer.SetLoadFields("No.", Name, "VAT Registration No.");
        if Customer.FindSet() then
            repeat
                if Customer."VAT Registration No." <> '' then begin
                    Cmp.SetFilter("No.", '<>%1', Customer."No.");
                    Cmp.SetRange("VAT Registration No.", Customer."VAT Registration No.");
                    if Cmp.FindFirst() then
                        if RaiseDup('L1-MD02', Customer."No.", Customer.Name, Cmp."No.", 'VAT reg. no.', Customer.SystemId, Database::Customer, "RIA Profile Type"::Customer, TitleLbl, DescLbl) then
                            Raised += 1;
                end;
            until Customer.Next() = 0;
    end;

    /// <summary>L1-MD03 Missing Data Governance: master records missing key governance fields.</summary>
    procedure DetectMissingGovernance() Raised: Integer
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        AlertNo: Integer;
        Hash: Text[100];
        VTitleLbl: Label 'Vendor master data gap: %1', Comment = '%1=vendor';
        VDescLbl: Label 'Vendor %1 (%2) is missing key fields (payment terms and/or VAT registration). Incomplete master data weakens controls and reporting.', Comment = 'positional';
        CTitleLbl: Label 'Customer master data gap: %1', Comment = '%1=customer';
        CDescLbl: Label 'Customer %1 (%2) is missing key fields (payment terms and/or VAT registration). Complete the record.', Comment = 'positional';
    begin
        Vendor.SetLoadFields("No.", Name, "Payment Terms Code", "VAT Registration No.", Blocked);
        if Vendor.FindSet() then
            repeat
                if (Vendor.Blocked = Vendor.Blocked::" ") and ((Vendor."Payment Terms Code" = '') or (Vendor."VAT Registration No." = '')) then begin
                    Hash := CopyStr(StrSubstNo('L1MD03V|%1', Vendor."No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseEntityAlert('L1-MD03',
                            CopyStr(StrSubstNo(VTitleLbl, Vendor."No."), 1, 150),
                            CopyStr(StrSubstNo(VDescLbl, Vendor."No.", Vendor.Name), 1, 2048),
                            0, Hash, Database::Vendor, Vendor.SystemId, Vendor."No.",
                            "RIA Profile Type"::Vendor, Vendor."No.", Vendor.Name);
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until Vendor.Next() = 0;

        Customer.SetLoadFields("No.", Name, "Payment Terms Code", "VAT Registration No.");
        if Customer.FindSet() then
            repeat
                if (Customer."Payment Terms Code" = '') or (Customer."VAT Registration No." = '') then begin
                    Hash := CopyStr(StrSubstNo('L1MD03C|%1', Customer."No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseEntityAlert('L1-MD03',
                            CopyStr(StrSubstNo(CTitleLbl, Customer."No."), 1, 150),
                            CopyStr(StrSubstNo(CDescLbl, Customer."No.", Customer.Name), 1, 2048),
                            0, Hash, Database::Customer, Customer.SystemId, Customer."No.",
                            "RIA Profile Type"::Customer, Customer."No.", Customer.Name);
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until Customer.Next() = 0;
    end;

    /// <summary>L1-MD04 Master Data Config Violations: posting-group / posting-setup changes from the Change Log.</summary>
    procedure DetectConfigViolations() Raised: Integer
    var
        ChangeLogEntry: Record "Change Log Entry";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Posting setup change on table %1', Comment = '%1=table';
        DescLbl: Label 'Field "%1" on a posting-setup record (table %2) was changed by %3 on %4 from "%5" to "%6". One posting-group change can misroute thousands of transactions — verify authorisation.', Comment = 'positional';
    begin
        ChangeLogEntry.SetCurrentKey("Date and Time");
        ChangeLogEntry.SetFilter("Table No.", '%1|%2|%3|%4|%5|%6',
            Database::"General Posting Setup", Database::"VAT Posting Setup", Database::"Customer Posting Group",
            Database::"Vendor Posting Group", Database::"Gen. Business Posting Group", Database::"Gen. Product Posting Group");
        ChangeLogEntry.SetRange("Type of Change", ChangeLogEntry."Type of Change"::Modification);
        ChangeLogEntry.SetFilter("Date and Time", '>=%1', CreateDateTime(CalcDate('<-30D>', Today()), 0T));
        ChangeLogEntry.SetLoadFields("Table No.", "Field Caption", "User ID", "Date and Time", "Old Value", "New Value", "Primary Key");
        if ChangeLogEntry.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1MD04|%1|%2|%3', ChangeLogEntry."Table No.", ChangeLogEntry."Primary Key", Format(ChangeLogEntry."Date and Time")), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L1-MD04',
                        CopyStr(StrSubstNo(TitleLbl, ChangeLogEntry."Table No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, ChangeLogEntry."Field Caption", Format(ChangeLogEntry."Table No."), ChangeLogEntry."User ID", Format(DT2Date(ChangeLogEntry."Date and Time")), ChangeLogEntry."Old Value", ChangeLogEntry."New Value"), 1, 2048),
                        0, Hash, ChangeLogEntry."Table No.", ChangeLogEntry.SystemId, '');
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until ChangeLogEntry.Next() = 0;
    end;

    local procedure RaiseDup(ControlID: Code[20]; No1: Code[20]; Name1: Text[100]; No2: Code[20]; MatchField: Text; SysId: Guid; TableNo: Integer; EntityType: Enum "RIA Profile Type"; TitleLbl: Text; DescLbl: Text): Boolean
    var
        Hash: Text[100];
        AlertNo: Integer;
    begin
        Hash := CopyStr(StrSubstNo('%1|%2|%3', ControlID, No1, No2), 1, 100);
        if AlertMgt.AlertExists(Hash) then
            exit(false);
        // Suppress the mirror-image duplicate (B->A when A->B already exists)
        if AlertMgt.AlertExists(CopyStr(StrSubstNo('%1|%2|%3', ControlID, No2, No1), 1, 100)) then
            exit(false);
        AlertNo := AlertMgt.RaiseEntityAlert(ControlID,
            CopyStr(StrSubstNo(TitleLbl, No1), 1, 150),
            CopyStr(StrSubstNo(DescLbl, No1, Name1, No2, MatchField), 1, 2048),
            0, Hash, TableNo, SysId, No1, EntityType, No1, Name1);
        exit(AlertNo <> 0);
    end;
}
