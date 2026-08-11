/// <summary>Control Catalogue — all risk controls across the five intelligence layers.</summary>
page 50116 "RIA Control Catalogue"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Control Catalogue";
    Caption = 'Control Catalogue';
    CardPageId = "RIA Control Card";
    Editable = false;
    SourceTableView = sorting(Layer, Domain);

    layout
    {
        area(Content)
        {
            repeater(Controls)
            {
                field("Control ID"; Rec."Control ID") { }
                field(Name; Rec.Name) { }
                field(Layer; Rec.Layer) { }
                field(Domain; Rec.Domain) { }
                field(Priority; Rec.Priority) { }
                field("Default Severity"; Rec."Default Severity") { }
                field("Default Risk Score"; Rec."Default Risk Score") { }
                field(Enabled; Rec.Enabled) { Editable = true; }
                field("Detection Available"; Rec."Detection Available") { }
                field("Open Alert Count"; Rec."Open Alert Count") { }
                field("Total Alert Count"; Rec."Total Alert Count") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunThisControl)
            {
                Caption = 'Run Detection';
                Image = Refresh;
                ToolTip = 'Run the detection routine for this control now.';
                trigger OnAction()
                var
                    DetectionEngine: Codeunit "RIA Detection Engine";
                    Raised: Integer;
                    DoneLbl: Label '%1 alert(s) raised for control %2.', Comment = '%1=count,%2=control';
                    NoDetectionLbl: Label 'No automated detection is registered for control %1 yet.', Comment = '%1=control';
                begin
                    if not Rec."Detection Available" then begin
                        Message(NoDetectionLbl, Rec."Control ID");
                        exit;
                    end;
                    Raised := DetectionEngine.RunControl(Rec."Control ID");
                    Message(DoneLbl, Raised, Rec."Control ID");
                end;
            }
            action(ViewControlAlerts)
            {
                Caption = 'View Alerts';
                Image = ViewDetails;
                ToolTip = 'Show alerts raised by this control.';
                trigger OnAction()
                var
                    RiskAlert: Record "RIA Risk Alert";
                begin
                    RiskAlert.SetRange("Control ID", Rec."Control ID");
                    Page.Run(Page::"RIA Risk Alerts", RiskAlert);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Run_P; RunThisControl) { }
                actionref(View_P; ViewControlAlerts) { }
            }
        }
    }
}
