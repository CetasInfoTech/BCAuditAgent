/// <summary>Risk Trends — alert counts grouped by domain and severity (query-backed).</summary>
page 50120 "RIA Risk Trends"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Risk Alert";
    Caption = 'Risk Trends';
    Editable = false;
    SourceTableView = sorting(Domain, Severity);

    layout
    {
        area(Content)
        {
            repeater(Trends)
            {
                field(Domain; Rec.Domain) { }
                field(Severity; Rec.Severity) { }
                field("Detected DateTime"; Rec."Detected DateTime") { }
                field(Title; Rec.Title) { }
                field("Risk Score"; Rec."Risk Score") { }
                field(Status; Rec.Status) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowChart)
            {
                Caption = 'Open Analysis View';
                Image = PieChart;
                ToolTip = 'Open the Business Central analysis mode to pivot alerts by domain, severity, and time.';
                trigger OnAction()
                var
                    AnalysisHintLbl: Label 'Use the Analyze (Edit in Excel / Analysis Mode) toggle on this list to pivot by Domain, Severity, and Detected date.';
                begin
                    Message(AnalysisHintLbl);
                end;
            }
        }
    }
}
