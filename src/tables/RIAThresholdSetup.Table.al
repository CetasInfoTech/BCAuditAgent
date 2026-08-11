/// <summary>Per-control threshold overrides editable by business users without development.</summary>
table 50107 "RIA Threshold Setup"
{
    Caption = 'RIA Threshold Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Control ID"; Code[20])
        {
            Caption = 'Control ID';
            TableRelation = "RIA Control Catalogue"."Control ID";
            NotBlank = true;
        }
        field(2; "Control Name"; Text[100])
        {
            Caption = 'Control Name';
            FieldClass = FlowField;
            CalcFormula = lookup("RIA Control Catalogue".Name where("Control ID" = field("Control ID")));
            Editable = false;
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(4; "Severity Override"; Enum "RIA Severity")
        {
            Caption = 'Severity Override';
        }
        field(5; "Amount Threshold"; Decimal)
        {
            Caption = 'Amount Threshold';
            AutoFormatType = 1;
        }
        field(6; "Percent Threshold"; Decimal)
        {
            Caption = 'Percent Threshold';
            DecimalPlaces = 0 : 2;
        }
        field(7; "Day Threshold"; Integer)
        {
            Caption = 'Day Threshold';
        }
        field(8; "Suppress Below Materiality"; Boolean)
        {
            Caption = 'Suppress Below Materiality';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Control ID") { Clustered = true; }
    }
}
