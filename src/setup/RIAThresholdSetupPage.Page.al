/// <summary>Threshold Setup — per-control threshold overrides for business users.</summary>
page 50125 "RIA Threshold Setup"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "RIA Threshold Setup";
    Caption = 'Threshold Setup';

    layout
    {
        area(Content)
        {
            repeater(Thresholds)
            {
                field("Control ID"; Rec."Control ID") { }
                field("Control Name"; Rec."Control Name") { }
                field(Enabled; Rec.Enabled) { }
                field("Severity Override"; Rec."Severity Override") { }
                field("Amount Threshold"; Rec."Amount Threshold") { }
                field("Percent Threshold"; Rec."Percent Threshold") { }
                field("Day Threshold"; Rec."Day Threshold") { }
                field("Suppress Below Materiality"; Rec."Suppress Below Materiality") { }
            }
        }
    }
}
