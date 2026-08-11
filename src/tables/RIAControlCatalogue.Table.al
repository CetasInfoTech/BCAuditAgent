/// <summary>Master catalogue of all RIA risk controls (L1-L5). Seeded on install.</summary>
table 50100 "RIA Control Catalogue"
{
    Caption = 'RIA Control Catalogue';
    DataClassification = SystemMetadata;
    LookupPageId = "RIA Control Catalogue";
    DrillDownPageId = "RIA Control Catalogue";

    fields
    {
        field(1; "Control ID"; Code[20])
        {
            Caption = 'Control ID';
            NotBlank = true;
        }
        field(2; "Name"; Text[100])
        {
            Caption = 'Name';
        }
        field(3; Layer; Enum "RIA Layer")
        {
            Caption = 'Layer';
        }
        field(4; Domain; Enum "RIA Domain")
        {
            Caption = 'Domain';
        }
        field(5; Priority; Enum "RIA Control Priority")
        {
            Caption = 'Priority';
        }
        field(6; "Default Severity"; Enum "RIA Severity")
        {
            Caption = 'Default Severity';
        }
        field(7; "Default Risk Score"; Decimal)
        {
            Caption = 'Default Risk Score';
            DecimalPlaces = 1 : 1;
            MinValue = 0;
            MaxValue = 10;
        }
        field(8; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(9; "Risk Description"; Text[250])
        {
            Caption = 'Risk Description';
        }
        field(10; "Business Impact"; Text[250])
        {
            Caption = 'Business Impact';
        }
        field(11; "Detection Available"; Boolean)
        {
            Caption = 'Detection Available';
            ToolTip = 'Indicates an automated detection routine is implemented for this control.';
        }
        field(12; "Threshold Amount"; Decimal)
        {
            Caption = 'Threshold Amount';
            AutoFormatType = 1;
        }
        field(13; "Threshold Days"; Integer)
        {
            Caption = 'Threshold Days';
        }
        field(14; "Threshold Percent"; Decimal)
        {
            Caption = 'Threshold Percent';
            DecimalPlaces = 0 : 2;
        }
        field(15; "Min License Tier"; Enum "RIA License Tier")
        {
            Caption = 'Minimum License Tier';
            ToolTip = 'Lowest license tier at which this control is available.';
        }
        field(20; "Open Alert Count"; Integer)
        {
            Caption = 'Open Alerts';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where("Control ID" = field("Control ID"),
                                                        Status = filter(New | Acknowledged | "Under Review" | Escalated)));
            Editable = false;
        }
        field(21; "Total Alert Count"; Integer)
        {
            Caption = 'Total Alerts';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where("Control ID" = field("Control ID")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Control ID") { Clustered = true; }
        key(Layer; Layer, Domain) { }
        key(Severity; "Default Severity") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Control ID", Name, Layer, Domain) { }
        fieldgroup(Brick; "Control ID", Name, "Default Severity", "Open Alert Count") { }
    }
}
