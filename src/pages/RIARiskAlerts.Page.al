/// <summary>Master list of risk alerts with triage actions and an evidence FactBox.</summary>
page 50103 "RIA Risk Alerts"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Risk Alert";
    Caption = 'Risk Alerts';
    CardPageId = "RIA Risk Alert Card";
    Editable = false;
    SourceTableView = sorting(Status, Severity, "Detected DateTime") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Alerts)
            {
                field("Entry No."; Rec."Entry No.") { Visible = false; }
                field(Severity; Rec.Severity)
                {
                    StyleExpr = SeverityStyle;
                }
                field(Title; Rec.Title) { }
                field("Control ID"; Rec."Control ID") { }
                field(Domain; Rec.Domain) { }
                field("Risk Score"; Rec."Risk Score")
                {
                    StyleExpr = SeverityStyle;
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field("Entity No."; Rec."Entity No.") { }
                field("Entity Name"; Rec."Entity Name") { }
                field("Amount (LCY)"; Rec."Amount (LCY)") { }
                field("Detected DateTime"; Rec."Detected DateTime") { }
                field("SLA Due DateTime"; Rec."SLA Due DateTime") { }
                field("SLA Breached"; Rec."SLA Breached")
                {
                    StyleExpr = 'Unfavorable';
                }
                field("Assigned To"; Rec."Assigned To") { }
                field("Case No."; Rec."Case No.") { }
            }
        }
        area(FactBoxes)
        {
            part(Evidence; "RIA Alert Evidence FactBox")
            {
                SubPageLink = "Alert Entry No." = field("Entry No.");
            }
            systempart(Links; Links) { }
            systempart(Notes; Notes) { }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Triage)
            {
                Caption = 'Triage';
                Image = Action;

                action(Acknowledge)
                {
                    Caption = 'Acknowledge';
                    Image = Approve;
                    ToolTip = 'Confirm you have seen this alert and start the SLA clock.';

                    trigger OnAction()
                    var
                        AlertMgt: Codeunit "RIA Alert Mgt";
                    begin
                        AlertMgt.Acknowledge(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(StartReview)
                {
                    Caption = 'Start Review';
                    Image = Start;
                    ToolTip = 'Begin investigating this alert.';

                    trigger OnAction()
                    var
                        AlertMgt: Codeunit "RIA Alert Mgt";
                    begin
                        AlertMgt.StartReview(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Resolve)
                {
                    Caption = 'Resolve';
                    Image = Completed;
                    ToolTip = 'Mark this alert as resolved with notes.';

                    trigger OnAction()
                    var
                        AlertMgt: Codeunit "RIA Alert Mgt";
                        Notes: Text[2048];
                    begin
                        if PromptNotes(Notes) then begin
                            AlertMgt.Resolve(Rec, Notes, false);
                            CurrPage.Update(false);
                        end;
                    end;
                }
                action(FalsePositive)
                {
                    Caption = 'False Positive';
                    Image = Cancel;
                    ToolTip = 'Mark this alert as a false positive (feeds ML calibration).';

                    trigger OnAction()
                    var
                        AlertMgt: Codeunit "RIA Alert Mgt";
                        Notes: Text[2048];
                    begin
                        if PromptNotes(Notes) then begin
                            AlertMgt.MarkFalsePositive(Rec, Notes);
                            CurrPage.Update(false);
                        end;
                    end;
                }
            }
            group(Investigate)
            {
                Caption = 'Investigate';
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
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Triage';
                actionref(Ack_Promoted; Acknowledge) { }
                actionref(Review_Promoted; StartReview) { }
                actionref(Resolve_Promoted; Resolve) { }
                actionref(Case_Promoted; CreateCase) { }
                actionref(Source_Promoted; OpenSource) { }
            }
        }
    }

    var
        SeverityStyle: Text;
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        SeverityStyle := SeverityToStyle(Rec.Severity);
        StatusStyle := StatusToStyle(Rec.Status);
    end;

    local procedure SeverityToStyle(Severity: Enum "RIA Severity"): Text
    begin
        case Severity of
            Severity::Critical:
                exit('Unfavorable');
            Severity::High:
                exit('Ambiguous');
            Severity::"Medium-High":
                exit('Ambiguous');
            else
                exit('Standard');
        end;
    end;

    local procedure StatusToStyle(Status: Enum "RIA Alert Status"): Text
    begin
        case Status of
            Status::Resolved:
                exit('Favorable');
            Status::"False Positive":
                exit('Subordinate');
            Status::Escalated:
                exit('Unfavorable');
            else
                exit('Standard');
        end;
    end;

    local procedure PromptNotes(var Notes: Text[2048]): Boolean
    var
        ResolveNotesPage: Page "RIA Resolution Dialog";
    begin
        ResolveNotesPage.LookupMode(true);
        if ResolveNotesPage.RunModal() = Action::LookupOK then begin
            Notes := ResolveNotesPage.GetNotes();
            exit(true);
        end;
        exit(false);
    end;
}
