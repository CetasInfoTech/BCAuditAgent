/// <summary>Full detail card for a single risk alert: every business question on one screen.</summary>
page 50105 "RIA Risk Alert Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "RIA Risk Alert";
    Caption = 'Risk Alert';
    Editable = false;

    layout
    {
        area(Content)
        {
            group(Overview)
            {
                Caption = 'Overview';
                field(Title; Rec.Title) { Style = Strong; }
                field("Control ID"; Rec."Control ID") { }
                field("Control Name"; Rec."Control Name") { }
                field(Layer; Rec.Layer) { }
                field(Domain; Rec.Domain) { }
                field(Severity; Rec.Severity) { StyleExpr = SeverityStyle; }
                field("Risk Score"; Rec."Risk Score") { StyleExpr = SeverityStyle; }
                field(Status; Rec.Status) { }
                field("Detected DateTime"; Rec."Detected DateTime") { }
            }
            group(WhatHappened)
            {
                Caption = 'What Happened';
                field(Description; Rec.Description) { MultiLine = true; }
                field("Recommended Action"; Rec."Recommended Action") { MultiLine = true; }
                field("Amount (LCY)"; Rec."Amount (LCY)") { }
            }
            group(EntityGroup)
            {
                Caption = 'Entity';
                field("Entity Type"; Rec."Entity Type") { }
                field("Entity No."; Rec."Entity No.") { }
                field("Entity Name"; Rec."Entity Name") { }
            }
            group(Source)
            {
                Caption = 'Source';
                field("Source Document No."; Rec."Source Document No.") { }
                field("Source Table No."; Rec."Source Table No.") { }
            }
            group(Lifecycle)
            {
                Caption = 'Lifecycle';
                field("Assigned To"; Rec."Assigned To") { Editable = true; }
                field("SLA Due DateTime"; Rec."SLA Due DateTime") { }
                field("SLA Breached"; Rec."SLA Breached") { }
                field("Acknowledged By"; Rec."Acknowledged By") { }
                field("Acknowledged DateTime"; Rec."Acknowledged DateTime") { }
                field("Resolved By"; Rec."Resolved By") { }
                field("Resolved DateTime"; Rec."Resolved DateTime") { }
                field("Resolution Notes"; Rec."Resolution Notes") { MultiLine = true; }
                field("Case No."; Rec."Case No.") { }
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
            action(Acknowledge)
            {
                Caption = 'Acknowledge';
                Image = Approve;
                ToolTip = 'Acknowledge this alert.';

                trigger OnAction()
                var
                    AlertMgt: Codeunit "RIA Alert Mgt";
                begin
                    AlertMgt.Acknowledge(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenSource)
            {
                Caption = 'Open Source Record';
                Image = ViewDetails;
                ToolTip = 'Drill through to the originating BC record.';

                trigger OnAction()
                var
                    DrillDown: Codeunit "RIA Drilldown Mgt";
                begin
                    DrillDown.OpenSource(Rec);
                end;
            }
            action(CreateCase)
            {
                Caption = 'Create Investigation Case';
                Image = New;
                ToolTip = 'Open a new investigation case from this alert.';

                trigger OnAction()
                var
                    CaseMgt: Codeunit "RIA Case Mgt";
                begin
                    CaseMgt.CreateCaseFromAlert(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Ack_P; Acknowledge) { }
                actionref(Source_P; OpenSource) { }
                actionref(Case_P; CreateCase) { }
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
