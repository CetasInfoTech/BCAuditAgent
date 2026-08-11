/// <summary>Risk Command Center — the RIA Role Center matching the product navigation structure.</summary>
page 50100 "RIA Risk Command Center"
{
    PageType = RoleCenter;
    Caption = 'Risk Intelligence Agent';

    layout
    {
        area(RoleCenter)
        {
            part(Headline; "RIA Headline")
            {
                ApplicationArea = All;
            }
            part(Activities; "RIA Activities")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Sections)
        {
            group(Monitoring)
            {
                Caption = 'Monitoring';
                action(RiskAlerts)
                {
                    ApplicationArea = All;
                    Caption = 'Risk Alerts';
                    RunObject = page "RIA Risk Alerts";
                    ToolTip = 'Review and triage all risk alerts.';
                }
                action(FinancialControls)
                {
                    ApplicationArea = All;
                    Caption = 'Financial Controls Center';
                    RunObject = page "RIA Financial Controls";
                    ToolTip = 'Finance-domain risk alerts and controls.';
                }
                action(ProcurementRisk)
                {
                    ApplicationArea = All;
                    Caption = 'Procurement Risk Center';
                    RunObject = page "RIA Procurement Risk";
                    ToolTip = 'Purchasing-domain risk alerts and controls.';
                }
                action(RevenueAssurance)
                {
                    ApplicationArea = All;
                    Caption = 'Revenue Assurance Center';
                    RunObject = page "RIA Revenue Assurance";
                    ToolTip = 'Sales-domain risk alerts and controls.';
                }
                action(InventoryIntelligence)
                {
                    ApplicationArea = All;
                    Caption = 'Inventory Intelligence Center';
                    RunObject = page "RIA Inventory Intelligence";
                    ToolTip = 'Inventory-domain risk alerts and controls.';
                }
            }
            group(RiskProfiles)
            {
                Caption = 'Risk Profiles';
                action(CustomerRiskProfile)
                {
                    ApplicationArea = All;
                    Caption = 'Customer Risk Profile';
                    RunObject = page "RIA Customer Risk Profiles";
                    ToolTip = 'Customer risk scores and exposure.';
                }
                action(VendorRiskProfile)
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Risk Profile';
                    RunObject = page "RIA Vendor Risk Profiles";
                    ToolTip = 'Vendor risk scores and exposure.';
                }
            }
            group(Investigations)
            {
                Caption = 'Investigations';
                action(OpenCases)
                {
                    ApplicationArea = All;
                    Caption = 'Open Cases';
                    RunObject = page "RIA Open Cases";
                    ToolTip = 'Active investigation cases.';
                }
                action(AuditEvidence)
                {
                    ApplicationArea = All;
                    Caption = 'Audit Evidence Center';
                    RunObject = page "RIA Audit Evidence Center";
                    ToolTip = 'Audit-grade evidence collected across alerts.';
                }
            }
            group(Compliance)
            {
                Caption = 'Compliance';
                action(ControlCatalogue)
                {
                    ApplicationArea = All;
                    Caption = 'Control Catalogue';
                    RunObject = page "RIA Control Catalogue";
                    ToolTip = 'All risk controls across the five intelligence layers.';
                }
                action(ComplianceMonitoring)
                {
                    ApplicationArea = All;
                    Caption = 'Compliance Monitoring';
                    RunObject = page "RIA Compliance Monitoring";
                    ToolTip = 'Control effectiveness and compliance status.';
                }
                action(RemediationTracker)
                {
                    ApplicationArea = All;
                    Caption = 'Remediation Tracker';
                    RunObject = page "RIA Remediation Tracker";
                    ToolTip = 'Track remediation actions to closure.';
                }
                action(ComplianceFrameworks)
                {
                    ApplicationArea = All;
                    Caption = 'Compliance Frameworks';
                    RunObject = page "RIA Compliance Mapping";
                    ToolTip = 'Which controls satisfy SOX / ISO / IFRS / GDPR requirements, and their live status.';
                }
            }
            group(Intelligence)
            {
                Caption = 'Intelligence';
                action(RiskTrends)
                {
                    ApplicationArea = All;
                    Caption = 'Risk Trends';
                    RunObject = page "RIA Risk Trends";
                    ToolTip = 'Alert trends over time by severity and domain.';
                }
                action(ExposureAnalytics)
                {
                    ApplicationArea = All;
                    Caption = 'Exposure Analytics';
                    RunObject = page "RIA Exposure Analytics";
                    ToolTip = 'Financial exposure by entity and domain.';
                }
                action(RiskCopilot)
                {
                    ApplicationArea = All;
                    Caption = 'Risk Intelligence Copilot';
                    RunObject = page "RIA Copilot";
                    ToolTip = 'Ask risk questions in natural language.';
                }
            }
            group(Setup)
            {
                Caption = 'Setup';
                action(RiskConfiguration)
                {
                    ApplicationArea = All;
                    Caption = 'Risk Configuration';
                    RunObject = page "RIA Risk Setup";
                    ToolTip = 'Core RIA configuration.';
                }
                action(ThresholdSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Threshold Setup';
                    RunObject = page "RIA Threshold Setup";
                    ToolTip = 'Per-control thresholds.';
                }
                action(NotificationSetup)
                {
                    ApplicationArea = All;
                    Caption = 'Notification Setup';
                    RunObject = page "RIA Notification Setup";
                    ToolTip = 'Notification routing by user and severity.';
                }
            }
        }
        area(Embedding)
        {
            action(EmbedAlerts)
            {
                ApplicationArea = All;
                Caption = 'Risk Alerts';
                RunObject = page "RIA Risk Alerts";
                ToolTip = 'Review and triage all risk alerts.';
            }
            action(EmbedCases)
            {
                ApplicationArea = All;
                Caption = 'Investigations';
                RunObject = page "RIA Open Cases";
                ToolTip = 'Active investigation cases.';
            }
            action(EmbedCatalogue)
            {
                ApplicationArea = All;
                Caption = 'Control Catalogue';
                RunObject = page "RIA Control Catalogue";
                ToolTip = 'All risk controls.';
            }
        }
        area(Processing)
        {

        }
    }
}
