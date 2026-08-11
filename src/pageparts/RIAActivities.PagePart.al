/// <summary>Risk Command Center activity tiles. Each tile drills to a filtered alert/case list.</summary>
page 50101 "RIA Activities"
{
    PageType = CardPart;
    SourceTable = "RIA Cue";
    Caption = 'Risk Activities';
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            cuegroup(Priority)
            {
                Caption = 'Priority';

                field("Critical Open"; Rec."Critical Open")
                {
                    ApplicationArea = All;
                    ToolTip = 'Open Critical-severity alerts requiring immediate attention.';
                    Style = Unfavorable;
                    StyleExpr = true;

                    trigger OnDrillDown()
                    begin
                        OpenAlerts("RIA Severity"::Critical);
                    end;
                }
                field("High Open"; Rec."High Open")
                {
                    ApplicationArea = All;
                    ToolTip = 'Open High-severity alerts.';
                    Style = Ambiguous;
                    StyleExpr = true;

                    trigger OnDrillDown()
                    begin
                        OpenAlerts("RIA Severity"::High);
                    end;
                }
                field("SLA Breached"; Rec."SLA Breached")
                {
                    ApplicationArea = All;
                    ToolTip = 'Open alerts that have passed their SLA due date/time.';
                    Style = Unfavorable;
                    StyleExpr = true;

                    trigger OnDrillDown()
                    var
                        RiskAlert: Record "RIA Risk Alert";
                    begin
                        RiskAlert.SetRange("SLA Breached", true);
                        RiskAlert.SetFilter(Status, '%1|%2|%3',
                            RiskAlert.Status::New, RiskAlert.Status::Acknowledged, RiskAlert.Status::"Under Review");
                        Page.Run(Page::"RIA Risk Alerts", RiskAlert);
                    end;
                }
            }
            cuegroup(Workload)
            {
                Caption = 'Workload';

                field("New Alerts"; Rec."New Alerts")
                {
                    ApplicationArea = All;
                    ToolTip = 'Alerts not yet acknowledged.';

                    trigger OnDrillDown()
                    var
                        RiskAlert: Record "RIA Risk Alert";
                    begin
                        RiskAlert.SetRange(Status, RiskAlert.Status::New);
                        Page.Run(Page::"RIA Risk Alerts", RiskAlert);
                    end;
                }
                field("Open Cases"; Rec."Open Cases")
                {
                    ApplicationArea = All;
                    ToolTip = 'Active investigation cases.';
                    DrillDownPageId = "RIA Open Cases";
                }
                field("Overdue Remediations"; Rec."Overdue Remediations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Remediation actions past their due date.';
                    Style = Unfavorable;
                    StyleExpr = true;
                    DrillDownPageId = "RIA Remediation Tracker";
                }
            }
            cuegroup(Exposure)
            {
                Caption = 'Exposure';

                field("Watchlist Entities"; Rec."Watchlist Entities")
                {
                    ApplicationArea = All;
                    ToolTip = 'Customers and vendors flagged on the risk watch list.';
                }
                field("Total Exposure (LCY)"; Rec."Total Exposure (LCY)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Sum of amounts attached to open alerts.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetCue();
    end;

    local procedure OpenAlerts(Severity: Enum "RIA Severity")
    var
        RiskAlert: Record "RIA Risk Alert";
    begin
        RiskAlert.SetRange(Severity, Severity);
        RiskAlert.SetFilter(Status, '%1|%2|%3|%4',
            RiskAlert.Status::New, RiskAlert.Status::Acknowledged,
            RiskAlert.Status::"Under Review", RiskAlert.Status::Escalated);
        Page.Run(Page::"RIA Risk Alerts", RiskAlert);
    end;
}
