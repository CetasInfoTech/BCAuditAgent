/// <summary>FactBox listing the evidence and comment trail for an alert.</summary>
page 50129 "RIA Alert Evidence FactBox"
{
    PageType = ListPart;
    SourceTable = "RIA Alert Evidence";
    Caption = 'Evidence & Trail';
    Editable = false;
    SourceTableView = sorting("Alert Entry No.", "Line No.");

    layout
    {
        area(Content)
        {
            repeater(Trail)
            {
                field("Entry Type"; Rec."Entry Type") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Source Field Caption"; Rec."Source Field Caption") { ApplicationArea = All; }
                field("Old Value"; Rec."Old Value") { ApplicationArea = All; }
                field("New Value"; Rec."New Value") { ApplicationArea = All; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; }
                field("Created DateTime"; Rec."Created DateTime") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddComment)
            {
                ApplicationArea = All;
                Caption = 'Add Comment';
                Image = Comment;
                ToolTip = 'Add a comment to the alert trail.';

                trigger OnAction()
                var
                    AlertMgt: Codeunit "RIA Alert Mgt";
                    CommentText: Text[250];
                begin
                    if Rec."Alert Entry No." = 0 then
                        exit;
                    CommentText := CopyStr(PromptText(), 1, 250);
                    if CommentText <> '' then begin
                        AlertMgt.AddComment(Rec."Alert Entry No.", CommentText);
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    local procedure PromptText(): Text
    var
        InputDialog: Page "RIA Resolution Dialog";
    begin
        InputDialog.LookupMode(true);
        if InputDialog.RunModal() = Action::LookupOK then
            exit(InputDialog.GetNotes());
        exit('');
    end;
}
