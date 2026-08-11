/// <summary>Investigation Workspace — full case detail with linked alerts.</summary>
page 50113 "RIA Investigation Case Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "RIA Investigation Case";
    Caption = 'Investigation Case';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.") { }
                field(Title; Rec.Title) { }
                field(Status; Rec.Status) { }
                field(Severity; Rec.Severity) { }
                field("Assigned To"; Rec."Assigned To") { }
                field("Entity Type"; Rec."Entity Type") { }
                field("Entity No."; Rec."Entity No.") { }
            }
            group(Detail)
            {
                Caption = 'Detail';
                field(Description; Rec.Description) { MultiLine = true; }
                field(Findings; Rec.Findings) { MultiLine = true; }
            }
            group(Closure)
            {
                Caption = 'Closure';
                field("Opened By"; Rec."Opened By") { }
                field("Opened Date"; Rec."Opened Date") { }
                field("Closed By"; Rec."Closed By") { }
                field("Closed Date"; Rec."Closed Date") { }
                field("Total Exposure (LCY)"; Rec."Total Exposure (LCY)") { }
            }
            part(LinkedAlerts; "RIA Case Alerts Sub")
            {
                ApplicationArea = All;
                Caption = 'Linked Alerts';
                SubPageLink = "Case No." = field("No.");
            }
        }
    }
}
