/// <summary>Inventory Intelligence Center — risk alerts filtered to the Inventory domain.</summary>
page 50109 "RIA Inventory Intelligence"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Risk Alert";
    Caption = 'Inventory Intelligence Center';
    CardPageId = "RIA Risk Alert Card";
    Editable = false;
    SourceTableView = sorting("Detected DateTime") order(descending) where(Domain = const(Inventory));

    layout
    {
        area(Content)
        {
            repeater(Alerts)
            {
                field(Severity; Rec.Severity) { StyleExpr = SeverityStyle; }
                field(Title; Rec.Title) { }
                field("Control ID"; Rec."Control ID") { }
                field("Risk Score"; Rec."Risk Score") { }
                field(Status; Rec.Status) { }
                field("Entity No."; Rec."Entity No.") { }
                field("Entity Name"; Rec."Entity Name") { }
                field("Amount (LCY)"; Rec."Amount (LCY)") { }
                field("Detected DateTime"; Rec."Detected DateTime") { }
                field("SLA Breached"; Rec."SLA Breached") { StyleExpr = 'Unfavorable'; }
            }
        }
        area(FactBoxes)
        {
            part(Evidence; "RIA Alert Evidence FactBox")
            {
                SubPageLink = "Alert Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenCard)
            {
                Caption = 'Open';
                Image = ViewDetails;
                ToolTip = 'Open the full alert card.';
                trigger OnAction()
                begin
                    Page.Run(Page::"RIA Risk Alert Card", Rec);
                end;
            }
        }
    }

    var
        SeverityStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Severity of
            Rec.Severity::Critical:
                SeverityStyle := 'Unfavorable';
            Rec.Severity::High, Rec.Severity::"Medium-High":
                SeverityStyle := 'Ambiguous';
            else
                SeverityStyle := 'Standard';
        end;
    end;
}
