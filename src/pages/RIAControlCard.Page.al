/// <summary>Control Card — configuration and metadata for a single control.</summary>
page 50117 "RIA Control Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "RIA Control Catalogue";
    Caption = 'Control';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Control ID"; Rec."Control ID") { }
                field(Name; Rec.Name) { }
                field(Layer; Rec.Layer) { }
                field(Domain; Rec.Domain) { }
                field(Priority; Rec.Priority) { }
                field(Enabled; Rec.Enabled) { }
                field("Detection Available"; Rec."Detection Available") { }
            }
            group(Scoring)
            {
                Caption = 'Scoring';
                field("Default Severity"; Rec."Default Severity") { }
                field("Default Risk Score"; Rec."Default Risk Score") { }
            }
            group(Thresholds)
            {
                Caption = 'Thresholds';
                field("Threshold Amount"; Rec."Threshold Amount") { }
                field("Threshold Days"; Rec."Threshold Days") { }
                field("Threshold Percent"; Rec."Threshold Percent") { }
            }
            group(Narrative)
            {
                Caption = 'Risk Narrative';
                field("Risk Description"; Rec."Risk Description") { MultiLine = true; }
                field("Business Impact"; Rec."Business Impact") { MultiLine = true; }
            }
        }
    }
}
