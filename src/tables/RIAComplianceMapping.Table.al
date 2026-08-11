/// <summary>Maps RIA controls to compliance framework requirements for audit evidence packaging.</summary>
table 50110 "RIA Compliance Mapping"
{
    Caption = 'RIA Compliance Mapping';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Framework"; Enum "RIA Compliance Framework")
        {
            Caption = 'Framework';
        }
        field(2; "Control ID"; Code[20])
        {
            Caption = 'Control ID';
            TableRelation = "RIA Control Catalogue"."Control ID";
        }
        field(3; "Requirement Ref"; Text[50])
        {
            Caption = 'Requirement Reference';
            ToolTip = 'The clause or section of the framework this control satisfies (e.g. SOX 404).';
        }
        field(4; "Control Name"; Text[100])
        {
            Caption = 'Control Name';
            FieldClass = FlowField;
            CalcFormula = lookup("RIA Control Catalogue".Name where("Control ID" = field("Control ID")));
            Editable = false;
        }
        field(5; "Control Enabled"; Boolean)
        {
            Caption = 'Control Enabled';
            FieldClass = FlowField;
            CalcFormula = lookup("RIA Control Catalogue".Enabled where("Control ID" = field("Control ID")));
            Editable = false;
        }
        field(6; "Open Alerts"; Integer)
        {
            Caption = 'Open Alerts';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where("Control ID" = field("Control ID"),
                Status = filter(New | Acknowledged | "Under Review" | Escalated)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Framework", "Control ID") { Clustered = true; }
        key(Control; "Control ID") { }
    }
}
