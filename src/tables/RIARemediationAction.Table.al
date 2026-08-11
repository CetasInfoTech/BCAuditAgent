/// <summary>A remediation action tracked to closure for a control failure or audit finding.</summary>
table 50105 "RIA Remediation Action"
{
    Caption = 'RIA Remediation Action';
    DataClassification = CustomerContent;
    LookupPageId = "RIA Remediation Tracker";
    DrillDownPageId = "RIA Remediation Tracker";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; "Control ID"; Code[20])
        {
            Caption = 'Control ID';
            TableRelation = "RIA Control Catalogue"."Control ID";
        }
        field(3; "Description"; Text[250])
        {
            Caption = 'Description';
        }
        field(4; Status; Enum "RIA Remediation Status")
        {
            Caption = 'Status';
        }
        field(5; "Owner"; Code[50])
        {
            Caption = 'Owner';
            TableRelation = "User Setup"."User ID";
            ValidateTableRelation = false;
        }
        field(6; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(7; "Created Date"; Date)
        {
            Caption = 'Created Date';
            Editable = false;
        }
        field(8; "Completed Date"; Date)
        {
            Caption = 'Completed Date';
            Editable = false;
        }
        field(9; "Case No."; Code[20])
        {
            Caption = 'Case No.';
            TableRelation = "RIA Investigation Case"."No.";
        }
        field(10; Severity; Enum "RIA Severity")
        {
            Caption = 'Severity';
        }
        field(11; "Days Overdue"; Integer)
        {
            Caption = 'Days Overdue';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Status; Status, "Due Date") { }
        key(Owner; Owner, Status) { }
    }

    fieldgroups
    {
        fieldgroup(Brick; "No.", Description, Status, "Due Date") { }
    }

    trigger OnInsert()
    begin
        if "Created Date" = 0D then
            "Created Date" := Today();
    end;
}
