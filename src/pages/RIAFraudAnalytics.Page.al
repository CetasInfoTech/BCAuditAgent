/// <summary>Fraud Analytics — Critical-severity alerts from fraud-oriented controls.</summary>
page 50122 "RIA Fraud Analytics"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Risk Alert";
    Caption = 'Fraud Analytics';
    CardPageId = "RIA Risk Alert Card";
    Editable = false;
    SourceTableView = sorting("Detected DateTime") order(descending) where(Severity = const(Critical));

    layout
    {
        area(Content)
        {
            repeater(Fraud)
            {
                field(Title; Rec.Title) { }
                field("Control ID"; Rec."Control ID") { }
                field(Domain; Rec.Domain) { }
                field("Entity No."; Rec."Entity No.") { }
                field("Entity Name"; Rec."Entity Name") { }
                field("Amount (LCY)"; Rec."Amount (LCY)") { }
                field("Risk Score"; Rec."Risk Score") { }
                field(Status; Rec.Status) { }
                field("Detected DateTime"; Rec."Detected DateTime") { }
            }
        }
    }
}
