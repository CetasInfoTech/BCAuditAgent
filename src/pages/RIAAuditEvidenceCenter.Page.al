/// <summary>Audit Evidence Center — all evidence collected across alerts, exportable for auditors.</summary>
page 50115 "RIA Audit Evidence Center"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Alert Evidence";
    Caption = 'Audit Evidence Center';
    Editable = false;
    SourceTableView = sorting("Alert Entry No.", "Line No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Evidence)
            {
                field("Alert Entry No."; Rec."Alert Entry No.") { }
                field("Entry Type"; Rec."Entry Type") { }
                field(Description; Rec.Description) { }
                field("Source Field Caption"; Rec."Source Field Caption") { }
                field("Old Value"; Rec."Old Value") { }
                field("New Value"; Rec."New Value") { }
                field("Created By"; Rec."Created By") { }
                field("Created DateTime"; Rec."Created DateTime") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenAlert)
            {
                Caption = 'Open Alert';
                Image = ViewDetails;
                ToolTip = 'Open the related alert.';
                trigger OnAction()
                var
                    RiskAlert: Record "RIA Risk Alert";
                begin
                    if RiskAlert.Get(Rec."Alert Entry No.") then
                        Page.Run(Page::"RIA Risk Alert Card", RiskAlert);
                end;
            }
            action(ExportEvidence)
            {
                Caption = 'Export Evidence Pack';
                Image = Export;
                ToolTip = 'Generate an audit-ready evidence report.';
                trigger OnAction()
                var
                    RiskAlert: Record "RIA Risk Alert";
                begin
                    if RiskAlert.Get(Rec."Alert Entry No.") then begin
                        RiskAlert.SetRecFilter();
                        Report.Run(Report::"RIA Audit Evidence Report", true, false, RiskAlert);
                    end;
                end;
            }
        }
    }
}
