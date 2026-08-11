/// <summary>Remediation Tracker — track remediation actions to closure.</summary>
page 50119 "RIA Remediation Tracker"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Remediation Action";
    Caption = 'Remediation Tracker';
    SourceTableView = sorting(Status, "Due Date");

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."No.") { }
                field(Description; Rec.Description) { }
                field("Control ID"; Rec."Control ID") { }
                field(Severity; Rec.Severity) { }
                field(Status; Rec.Status) { StyleExpr = StatusStyle; }
                field(Owner; Rec.Owner) { }
                field("Due Date"; Rec."Due Date") { }
                field("Days Overdue"; Rec."Days Overdue") { StyleExpr = OverdueStyle; }
                field("Case No."; Rec."Case No.") { }
                field("Completed Date"; Rec."Completed Date") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(MarkComplete)
            {
                Caption = 'Mark Complete';
                Image = Completed;
                ToolTip = 'Mark this remediation action as completed.';
                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::Completed;
                    Rec."Completed Date" := Today();
                    Rec."Days Overdue" := 0;
                    Rec.Modify(true);
                end;
            }
        }
    }

    var
        StatusStyle: Text;
        OverdueStyle: Text;

    trigger OnAfterGetRecord()
    var
        IsOverdue: Boolean;
    begin
        IsOverdue := (Rec.Status <> Rec.Status::Completed) and (Rec."Due Date" <> 0D) and (Rec."Due Date" < Today());
        case true of
            Rec.Status = Rec.Status::Completed:
                StatusStyle := 'Favorable';
            (Rec.Status = Rec.Status::Overdue) or IsOverdue:
                StatusStyle := 'Unfavorable';
            else
                StatusStyle := 'Standard';
        end;
        if IsOverdue or (Rec."Days Overdue" > 0) then
            OverdueStyle := 'Unfavorable'
        else
            OverdueStyle := 'Standard';
    end;
}
