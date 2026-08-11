/// <summary>Exposure Analytics — financial exposure of open alerts by entity.</summary>
page 50121 "RIA Exposure Analytics"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Risk Profile";
    Caption = 'Exposure Analytics';
    Editable = false;
    SourceTableView = sorting("Risk Score") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Exposure)
            {
                field("Profile Type"; Rec."Profile Type") { }
                field("Entity No."; Rec."Entity No.") { }
                field("Entity Name"; Rec."Entity Name") { }
                field("Risk Score"; Rec."Risk Score") { }
                field("Open Alert Count"; Rec."Open Alert Count") { }
                field("Balance (LCY)"; Rec."Balance (LCY)") { }
                field("Overdue (LCY)"; Rec."Overdue (LCY)") { }
                field("Credit Utilization %"; Rec."Credit Utilization %") { }
            }
        }
    }
}
