/// <summary>Risk Configuration — core RIA setup card.</summary>
page 50124 "RIA Risk Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "RIA Risk Setup";
    Caption = 'Risk Configuration';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Monitoring)
            {
                Caption = 'Monitoring';
                field("Monitoring Enabled"; Rec."Monitoring Enabled") { }
                field("Detection Interval (Min)"; Rec."Detection Interval (Min)") { }
                field("Shadow Mode"; Rec."Shadow Mode") { }
                field("Materiality Floor (LCY)"; Rec."Materiality Floor (LCY)") { }
                field("License Tier"; Rec."License Tier") { }
            }
            group(Delivery)
            {
                Caption = 'Delivery';
                field("Enable Email Digest"; Rec."Enable Email Digest") { }
                field("Digest Recipient"; Rec."Digest Recipient") { }
                field("Teams Webhook URL"; Rec."Teams Webhook URL") { }
                field("Alert Webhook URL"; Rec."Alert Webhook URL") { }
            }
            group(SLA)
            {
                Caption = 'SLA (Hours)';
                field("SLA Critical (Hours)"; Rec."SLA Critical (Hours)") { }
                field("SLA High (Hours)"; Rec."SLA High (Hours)") { }
                field("SLA Medium (Hours)"; Rec."SLA Medium (Hours)") { }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Case No. Series"; Rec."Case No. Series") { }
                field("Remediation No. Series"; Rec."Remediation No. Series") { }
            }
            group(Routing)
            {
                Caption = 'Notifications';
                field("Notify Critical Email"; Rec."Notify Critical Email") { }
                field("Default Risk Manager"; Rec."Default Risk Manager") { }
            }
            group(AI)
            {
                Caption = 'AI Configuration';
                field("AI Copilot Enabled"; Rec."AI Copilot Enabled") { }
                field("AI Endpoint"; Rec."AI Endpoint") { }
                field("AI Deployment"; Rec."AI Deployment") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetAIKey)
            {
                Caption = 'Set AI API Key';
                Image = EncryptionKeys;
                ToolTip = 'Store the Azure OpenAI API key securely in Isolated Storage.';
                trigger OnAction()
                var
                    Copilot: Codeunit "RIA Copilot Mgt";
                    KeyValue: Text;
                    Dlg: Page "RIA Resolution Dialog";
                    SavedLbl: Label 'AI API key saved securely.';
                begin
                    Dlg.LookupMode(true);
                    if Dlg.RunModal() = Action::LookupOK then begin
                        KeyValue := Dlg.GetNotes();
                        if KeyValue <> '' then begin
                            Copilot.SetApiKey(KeyValue);
                            Message(SavedLbl);
                        end;
                    end;
                end;
            }
            action(SendDigest)
            {
                Caption = 'Send Digest Now';
                Image = SendTo;
                ToolTip = 'Send the risk digest email immediately.';
                trigger OnAction()
                var
                    DeliveryMgt: Codeunit "RIA Delivery Mgt";
                    DoneLbl: Label 'Digest sent (if enabled and recipient set).';
                begin
                    DeliveryMgt.SendDailyDigest();
                    Message(DoneLbl);
                end;
            }
            action(ScheduleJobs)
            {
                Caption = 'Schedule Background Jobs';
                Image = Job;
                ToolTip = 'Create recurring Job Queue entries for detection and SLA monitoring.';
                trigger OnAction()
                var
                    JobQueueMgt: Codeunit "RIA Job Queue Mgt";
                    DoneLbl: Label 'Background jobs scheduled.';
                begin
                    JobQueueMgt.EnsureJobQueueEntries();
                    Message(DoneLbl);
                end;
            }
            action(SeedCatalogue)
            {
                Caption = 'Reseed Control Catalogue';
                Image = Recalculate;
                ToolTip = 'Re-create any missing control catalogue entries.';
                trigger OnAction()
                var
                    Install: Codeunit "RIA Install";
                    DoneLbl: Label 'Control catalogue reseeded.';
                begin
                    Install.SeedControlCatalogue();
                    Message(DoneLbl);
                end;
            }
            action(RunDetection)
            {
                ApplicationArea = All;
                Caption = 'Run Detection Now';
                Image = Refresh;
                ToolTip = 'Run all enabled detection routines immediately.';

                trigger OnAction()
                var
                    DetectionEngine: Codeunit "RIA Detection Engine";
                    Raised: Integer;
                    DoneLbl: Label 'Detection complete. %1 alert(s) raised.', Comment = '%1 = count';
                begin
                    Raised := DetectionEngine.RunAllDetections();
                    Message(DoneLbl, Raised);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
