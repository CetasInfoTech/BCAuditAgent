/// <summary>Audit Evidence Report — a Word-layout report producing an audit-ready evidence pack for an alert.</summary>
report 50100 "RIA Audit Evidence Report"
{
    Caption = 'RIA Audit Evidence Report';
    UsageCategory = Documents;
    ApplicationArea = All;
    DefaultRenderingLayout = WordLayout;
    WordMergeDataItem = Alert;

    dataset
    {
        dataitem(Alert; "RIA Risk Alert")
        {
            RequestFilterFields = "Entry No.", "Control ID", Severity, Status;
            column(EntryNo; "Entry No.") { }
            column(ControlID; "Control ID") { }
            column(ControlName; "Control Name") { }
            column(Severity; Severity) { }
            column(RiskScore; "Risk Score") { }
            column(Status; Status) { }
            column(Title; Title) { }
            column(Description; Description) { }
            column(RecommendedAction; "Recommended Action") { }
            column(AmountLCY; "Amount (LCY)") { }
            column(EntityNo; "Entity No.") { }
            column(EntityName; "Entity Name") { }
            column(DetectedDateTime; "Detected DateTime") { }
            column(ResolvedBy; "Resolved By") { }
            column(ResolutionNotes; "Resolution Notes") { }
            column(CompanyName; CompanyName) { }
            column(PrintedBy; PrintedBy) { }
            column(PrintedOn; PrintedOn) { }

            dataitem(Evidence; "RIA Alert Evidence")
            {
                DataItemLink = "Alert Entry No." = field("Entry No.");
                DataItemTableView = sorting("Alert Entry No.", "Line No.");
                column(Ev_Type; Format("Entry Type")) { }
                column(Ev_Description; Description) { }
                column(Ev_Field; "Source Field Caption") { }
                column(Ev_OldValue; "Old Value") { }
                column(Ev_NewValue; "New Value") { }
                column(Ev_CreatedBy; "Created By") { }
                column(Ev_CreatedDateTime; "Created DateTime") { }
            }

            trigger OnAfterGetRecord()
            begin
                CompanyName := CompanyProperty.DisplayName();
            end;
        }
    }

    rendering
    {
        layout(WordLayout)
        {
            Type = RDLC;
            LayoutFile = './src/reports/RIAAuditEvidenceReport.rdl';
        }
    }

    trigger OnInitReport()
    begin
        PrintedBy := CopyStr(UserId(), 1, MaxStrLen(PrintedBy));
        PrintedOn := CurrentDateTime();
    end;

    var
        CompanyName: Text;
        PrintedBy: Code[50];
        PrintedOn: DateTime;
}
