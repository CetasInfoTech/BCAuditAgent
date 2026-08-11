/// <summary>Resolves an alert's source pointer to the correct BC page (no dead ends).</summary>
codeunit 50107 "RIA Drilldown Mgt"
{
    Access = Public;
    Permissions = tabledata Vendor = r, tabledata Customer = r, tabledata Item = r;

    /// <summary>Opens the originating BC record for an alert using its source table and system id.</summary>
    procedure OpenSource(var RiskAlert: Record "RIA Risk Alert")
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        Item: Record Item;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        NoSourceLbl: Label 'No source record is available for this alert.';
    begin
        case RiskAlert."Source Table No." of
            Database::Vendor,
            Database::"Vendor Bank Account":
                if Vendor.Get(RiskAlert."Entity No.") then
                    Page.Run(Page::"Vendor Card", Vendor);
            Database::Customer:
                if Customer.Get(RiskAlert."Entity No.") then
                    Page.Run(Page::"Customer Card", Customer);
            Database::Item:
                if Item.Get(RiskAlert."Entity No.") then
                    Page.Run(Page::"Item Card", Item);
            Database::"Vendor Ledger Entry":
                begin
                    VendorLedgerEntry.SetRange("Document No.", RiskAlert."Source Document No.");
                    if VendorLedgerEntry.FindFirst() then
                        Page.Run(Page::"Vendor Ledger Entries", VendorLedgerEntry);
                end;
            else
                Message(NoSourceLbl);
        end;
    end;
}
