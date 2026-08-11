/// <summary>An investigation case grouping one or more alerts for forensic review.</summary>
table 50102 "RIA Investigation Case"
{
    Caption = 'RIA Investigation Case';
    DataClassification = CustomerContent;
    LookupPageId = "RIA Open Cases";
    DrillDownPageId = "RIA Open Cases";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; "Title"; Text[150])
        {
            Caption = 'Title';
        }
        field(3; Status; Enum "RIA Case Status")
        {
            Caption = 'Status';
        }
        field(4; Severity; Enum "RIA Severity")
        {
            Caption = 'Severity';
        }
        field(5; "Opened By"; Code[50])
        {
            Caption = 'Opened By';
            Editable = false;
        }
        field(6; "Opened Date"; Date)
        {
            Caption = 'Opened Date';
            Editable = false;
        }
        field(7; "Assigned To"; Code[50])
        {
            Caption = 'Assigned To';
            TableRelation = "User Setup"."User ID";
            ValidateTableRelation = false;
        }
        field(8; "Description"; Text[2048])
        {
            Caption = 'Description';
        }
        field(9; "Findings"; Text[2048])
        {
            Caption = 'Findings';
        }
        field(10; "Closed Date"; Date)
        {
            Caption = 'Closed Date';
            Editable = false;
        }
        field(11; "Closed By"; Code[50])
        {
            Caption = 'Closed By';
            Editable = false;
        }
        field(12; "Entity Type"; Enum "RIA Profile Type")
        {
            Caption = 'Entity Type';
        }
        field(13; "Entity No."; Code[20])
        {
            Caption = 'Entity No.';
        }
        field(20; "Linked Alert Count"; Integer)
        {
            Caption = 'Linked Alerts';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where("Case No." = field("No.")));
            Editable = false;
        }
        field(21; "Total Exposure (LCY)"; Decimal)
        {
            Caption = 'Total Exposure (LCY)';
            FieldClass = FlowField;
            CalcFormula = sum("RIA Risk Alert"."Amount (LCY)" where("Case No." = field("No.")));
            AutoFormatType = 1;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Status; Status, Severity) { }
        key(Assigned; "Assigned To", Status) { }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", Title, Status, Severity) { }
    }

    trigger OnInsert()
    begin
        if "Opened Date" = 0D then
            "Opened Date" := Today();
        if "Opened By" = '' then
            "Opened By" := CopyStr(UserId(), 1, MaxStrLen("Opened By"));
    end;
}
