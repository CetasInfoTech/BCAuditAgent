/// <summary>Audit-grade evidence and comment trail attached to an alert.</summary>
table 50103 "RIA Alert Evidence"
{
    Caption = 'RIA Alert Evidence';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Alert Entry No."; Integer)
        {
            Caption = 'Alert Entry No.';
            TableRelation = "RIA Risk Alert"."Entry No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionMembers = Evidence,Comment,"System Note";
            OptionCaption = 'Evidence,Comment,System Note';
        }
        field(4; "Created DateTime"; DateTime)
        {
            Caption = 'Created';
            Editable = false;
        }
        field(5; "Created By"; Code[50])
        {
            Caption = 'Created By';
            Editable = false;
        }
        field(6; "Description"; Text[250])
        {
            Caption = 'Description';
        }
        field(7; "Detail"; Blob)
        {
            Caption = 'Detail';
        }
        field(8; "Source Table No."; Integer)
        {
            Caption = 'Source Table No.';
        }
        field(9; "Source Field Caption"; Text[100])
        {
            Caption = 'Source Field';
        }
        field(10; "Old Value"; Text[250])
        {
            Caption = 'Old Value';
        }
        field(11; "New Value"; Text[250])
        {
            Caption = 'New Value';
        }
    }

    keys
    {
        key(PK; "Alert Entry No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if "Created DateTime" = 0DT then
            "Created DateTime" := CurrentDateTime();
        if "Created By" = '' then
            "Created By" := CopyStr(UserId(), 1, MaxStrLen("Created By"));
    end;
}
