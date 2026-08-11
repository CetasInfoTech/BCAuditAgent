/// <summary>Compliance dashboard — which RIA controls satisfy which framework requirement, and their live status.</summary>
page 50130 "RIA Compliance Mapping"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Compliance Mapping";
    Caption = 'Compliance Frameworks';
    Editable = false;
    SourceTableView = sorting(Framework, "Control ID");

    layout
    {
        area(Content)
        {
            repeater(Mappings)
            {
                field(Framework; Rec.Framework) { }
                field("Requirement Ref"; Rec."Requirement Ref") { }
                field("Control ID"; Rec."Control ID") { }
                field("Control Name"; Rec."Control Name") { }
                field("Control Enabled"; Rec."Control Enabled") { StyleExpr = EnabledStyle; }
                field("Open Alerts"; Rec."Open Alerts") { StyleExpr = AlertStyle; }
                field(Status; StatusTxt) { Caption = 'Status'; StyleExpr = AlertStyle; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewControl)
            {
                Caption = 'View Control';
                Image = ViewDetails;
                ToolTip = 'Open the control card.';
                trigger OnAction()
                var
                    Control: Record "RIA Control Catalogue";
                begin
                    if Control.Get(Rec."Control ID") then
                        Page.Run(Page::"RIA Control Card", Control);
                end;
            }
        }
    }

    var
        EnabledStyle: Text;
        AlertStyle: Text;
        StatusTxt: Text;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Control Enabled", "Open Alerts");
        if Rec."Control Enabled" then
            EnabledStyle := 'Favorable'
        else
            EnabledStyle := 'Unfavorable';
        if Rec."Open Alerts" > 0 then begin
            AlertStyle := 'Unfavorable';
            StatusTxt := 'Exceptions';
        end else begin
            AlertStyle := 'Favorable';
            StatusTxt := 'Compliant';
        end;
    end;
}
