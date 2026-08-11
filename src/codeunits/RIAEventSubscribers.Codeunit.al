/// <summary>Real-time event subscribers for sub-5-minute detection of the highest-severity controls.</summary>
codeunit 50104 "RIA Event Subscribers"
{
    Access = Internal;
    Permissions = tabledata "RIA Risk Setup" = r;

    /// <summary>Fires immediately when a vendor bank account is modified (L1-013 real-time path).</summary>
    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyVendorBankAccount(var Rec: Record "Vendor Bank Account"; var xRec: Record "Vendor Bank Account"; RunTrigger: Boolean)
    var
        Setup: Record "RIA Risk Setup";
        Vendor: Record Vendor;
        AlertMgt: Codeunit "RIA Alert Mgt";
        NotificationMgt: Codeunit "RIA Notification Mgt";
        AlertNo: Integer;
        Hash: Text[100];
        BankChanged: Boolean;
        TitleTxt: Text[150];
        DescTxt: Text[2048];
        TitleLbl: Label 'Vendor bank account modified: %1', Comment = '%1 = Vendor No.';
        DescLbl: Label 'Bank details for vendor %1 were just modified by %2. A 5-business-day payment hold and out-of-band verification are recommended before any payment (possible BEC fraud).', Comment = '%1=Vendor,%2=User';
    begin
        if Rec.IsTemporary() then
            exit;
        if not Setup.Get() then
            exit;
        if not Setup."Monitoring Enabled" then
            exit;

        BankChanged := (Rec."Bank Account No." <> xRec."Bank Account No.") or
                       (Rec.IBAN <> xRec.IBAN) or
                       (Rec."SWIFT Code" <> xRec."SWIFT Code");
        if not BankChanged then
            exit;

        Hash := CopyStr(StrSubstNo('L1013RT|%1|%2|%3', Rec."Vendor No.", Rec.Code,
            Format(CurrentDateTime(), 0, 9)), 1, 100);

        TitleTxt := CopyStr(StrSubstNo(TitleLbl, Rec."Vendor No."), 1, MaxStrLen(TitleTxt));
        DescTxt := CopyStr(StrSubstNo(DescLbl, Rec."Vendor No.", UserId()), 1, MaxStrLen(DescTxt));

        AlertNo := AlertMgt.RaiseAlert('L1-013', TitleTxt, DescTxt, 0, Hash,
            Database::"Vendor Bank Account", Rec.SystemId, Rec."Vendor No.");
        if AlertNo = 0 then
            exit;

        if Vendor.Get(Rec."Vendor No.") then
            AlertMgt.SetEntity(AlertNo, "RIA Profile Type"::Vendor, Vendor."No.", Vendor.Name);
        AlertMgt.AddEvidence(AlertNo, 'Bank account no. (real-time)', Database::"Vendor Bank Account",
            'Bank Account No.', xRec."Bank Account No.", Rec."Bank Account No.");
        AlertMgt.AddEvidence(AlertNo, 'IBAN (real-time)', Database::"Vendor Bank Account",
            'IBAN', xRec.IBAN, Rec.IBAN);
        NotificationMgt.NotifyNewAlert(AlertNo);
    end;
}
