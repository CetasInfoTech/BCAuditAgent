/// <summary>Surfaces critical alerts as in-app notifications and routes email per Notification Setup.</summary>
codeunit 50102 "RIA Notification Mgt"
{
    Access = Public;
    Permissions = tabledata "RIA Notification Setup" = r,
                  tabledata "RIA Risk Setup" = r;

    var
        ViewAlertLbl: Label 'View Alert';
        CriticalAlertMsgLbl: Label 'Critical risk alert: %1', Comment = '%1 = Alert title';

    /// <summary>Sends an in-app notification for a newly raised alert if it meets the user's threshold and shadow mode is off.</summary>
    procedure NotifyNewAlert(AlertEntryNo: Integer)
    var
        RiskAlert: Record "RIA Risk Alert";
        Setup: Record "RIA Risk Setup";
        AlertNotification: Notification;
    begin
        if not RiskAlert.Get(AlertEntryNo) then
            exit;
        Setup.GetSetup();
        if Setup."Shadow Mode" then
            exit;
        if RiskAlert.Severity.AsInteger() < RiskAlert.Severity::High.AsInteger() then
            exit;

        AlertNotification.Id := CreateGuid();
        AlertNotification.Message(StrSubstNo(CriticalAlertMsgLbl, RiskAlert.Title));
        AlertNotification.Scope := NotificationScope::LocalScope;
        AlertNotification.SetData('EntryNo', Format(RiskAlert."Entry No."));
        AlertNotification.AddAction(ViewAlertLbl, Codeunit::"RIA Notification Mgt", 'OpenAlertFromNotification');
        AlertNotification.Send();
    end;

    /// <summary>Notification action handler that opens the alert card.</summary>
    procedure OpenAlertFromNotification(AlertNotification: Notification)
    var
        RiskAlert: Record "RIA Risk Alert";
        EntryNo: Integer;
    begin
        if Evaluate(EntryNo, AlertNotification.GetData('EntryNo')) then
            if RiskAlert.Get(EntryNo) then
                Page.Run(Page::"RIA Risk Alert Card", RiskAlert);
    end;
}
