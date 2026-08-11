/// <summary>Background job that flags SLA-breached alerts and escalates them.</summary>
codeunit 50103 "RIA SLA Monitor"
{
    Access = Public;
    TableNo = "RIA Risk Setup";
    Permissions = tabledata "RIA Risk Alert" = rm;

    trigger OnRun()
    begin
        CheckSLA();
    end;

    /// <summary>Marks open alerts past their SLA as breached and escalates Critical/High alerts.</summary>
    procedure CheckSLA() Breached: Integer
    var
        RiskAlert: Record "RIA Risk Alert";
        AlertMgt: Codeunit "RIA Alert Mgt";
    begin
        RiskAlert.SetFilter(Status, '%1|%2|%3',
            RiskAlert.Status::New, RiskAlert.Status::Acknowledged, RiskAlert.Status::"Under Review");
        RiskAlert.SetFilter("SLA Due DateTime", '<%1&<>%2', CurrentDateTime(), 0DT);
        RiskAlert.SetRange("SLA Breached", false);
        if RiskAlert.FindSet() then
            repeat
                RiskAlert."SLA Breached" := true;
                RiskAlert.Modify();
                if RiskAlert.Severity in [RiskAlert.Severity::Critical, RiskAlert.Severity::High] then
                    if RiskAlert.Status <> RiskAlert.Status::Escalated then
                        AlertMgt.Escalate(RiskAlert);
                Breached += 1;
            until RiskAlert.Next() = 0;
    end;
}
