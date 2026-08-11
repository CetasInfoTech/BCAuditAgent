/// <summary>Customer Risk Profile — aggregated risk scores and exposure for Customer entities.</summary>
page 50110 "RIA Customer Risk Profiles"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Risk Profile";
    Caption = 'Customer Risk Profile';
    Editable = false;
    SourceTableView = sorting("Risk Score") order(descending) where("Profile Type" = const(Customer));

    layout
    {
        area(Content)
        {
            repeater(Profiles)
            {
                field("Entity No."; Rec."Entity No.") { }
                field("Entity Name"; Rec."Entity Name") { }
                field("Risk Score"; Rec."Risk Score") { StyleExpr = ScoreStyle; }
                field(Severity; Rec.Severity) { StyleExpr = ScoreStyle; }
                field("Open Alert Count"; Rec."Open Alert Count") { }
                field("Balance (LCY)"; Rec."Balance (LCY)") { }
                field("Overdue (LCY)"; Rec."Overdue (LCY)") { }
                field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)") { }
                field("Credit Utilization %"; Rec."Credit Utilization %") { }
                field("Watch List"; Rec."Watch List") { Editable = true; }
                field("Last Calculated"; Rec."Last Calculated") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewAlerts)
            {
                Caption = 'View Alerts';
                Image = ViewDetails;
                ToolTip = 'Show open alerts for this entity.';
                trigger OnAction()
                var
                    RiskAlert: Record "RIA Risk Alert";
                begin
                    RiskAlert.SetRange("Entity Type", Rec."Profile Type");
                    RiskAlert.SetRange("Entity No.", Rec."Entity No.");
                    Page.Run(Page::"RIA Risk Alerts", RiskAlert);
                end;
            }
            action(ToggleWatch)
            {
                Caption = 'Toggle Watch List';
                Image = Flag;
                ToolTip = 'Add or remove this entity from the watch list.';
                trigger OnAction()
                begin
                    Rec."Watch List" := not Rec."Watch List";
                    Rec.Modify(true);
                end;
            }
        }
    }

    var
        ScoreStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Severity of
            Rec.Severity::Critical:
                ScoreStyle := 'Unfavorable';
            Rec.Severity::High, Rec.Severity::"Medium-High":
                ScoreStyle := 'Ambiguous';
            else
                ScoreStyle := 'Favorable';
        end;
    end;
}
