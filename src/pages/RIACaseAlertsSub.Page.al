/// <summary>Listpart showing alerts linked to an investigation case.</summary>
page 50114 "RIA Case Alerts Sub"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "RIA Risk Alert";
    Caption = 'Linked Alerts';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Alerts)
            {
                field(Severity; Rec.Severity) { }
                field(Title; Rec.Title) { }
                field("Risk Score"; Rec."Risk Score") { }
                field(Status; Rec.Status) { }
                field("Amount (LCY)"; Rec."Amount (LCY)") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Open)
            {
                Caption = 'Open Alert';
                Image = ViewDetails;
                ToolTip = 'Open the alert card.';
                trigger OnAction()
                begin
                    Page.Run(Page::"RIA Risk Alert Card", Rec);
                end;
            }
        }
    }
}
