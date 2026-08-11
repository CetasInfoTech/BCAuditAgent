/// <summary>Notification Setup — routing of alerts to users by severity and domain.</summary>
page 50126 "RIA Notification Setup"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "RIA Notification Setup";
    Caption = 'Notification Setup';

    layout
    {
        area(Content)
        {
            repeater(Routing)
            {
                field("User ID"; Rec."User ID") { }
                field("Minimum Severity"; Rec."Minimum Severity") { }
                field("Domain Filter"; Rec."Domain Filter") { }
                field("In-App"; Rec."In-App") { }
                field(Email; Rec.Email) { }
                field("Email Address"; Rec."Email Address") { }
            }
        }
    }
}
