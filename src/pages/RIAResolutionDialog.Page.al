/// <summary>Modal dialog used to capture resolution / false-positive notes.</summary>
page 50104 "RIA Resolution Dialog"
{
    PageType = StandardDialog;
    Caption = 'Resolution Notes';
    SourceTable = "RIA Risk Setup";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            group(Notes)
            {
                Caption = 'Notes';
                field(NotesField; NotesText)
                {
                    ApplicationArea = All;
                    Caption = 'Resolution Notes';
                    MultiLine = true;
                    ShowMandatory = true;
                    ToolTip = 'Describe the corrective action taken or why this is a false positive.';
                }
            }
        }
    }

    var
        NotesText: Text[2048];

    /// <summary>Returns the captured notes text.</summary>
    procedure GetNotes(): Text[2048]
    begin
        exit(NotesText);
    end;
}
