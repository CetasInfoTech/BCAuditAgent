/// <summary>Aggregated risk profile/score per customer or vendor.</summary>
table 50104 "RIA Risk Profile"
{
    Caption = 'RIA Risk Profile';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Profile Type"; Enum "RIA Profile Type")
        {
            Caption = 'Profile Type';
        }
        field(2; "Entity No."; Code[20])
        {
            Caption = 'Entity No.';
        }
        field(3; "Entity Name"; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Risk Score"; Decimal)
        {
            Caption = 'Risk Score';
            DecimalPlaces = 1 : 1;
            MinValue = 0;
            MaxValue = 10;
            Editable = false;
        }
        field(5; Severity; Enum "RIA Severity")
        {
            Caption = 'Severity Band';
            Editable = false;
        }
        field(6; "Last Calculated"; DateTime)
        {
            Caption = 'Last Calculated';
            Editable = false;
        }
        field(7; "Balance (LCY)"; Decimal)
        {
            Caption = 'Balance (LCY)';
            AutoFormatType = 1;
            Editable = false;
        }
        field(8; "Overdue (LCY)"; Decimal)
        {
            Caption = 'Overdue (LCY)';
            AutoFormatType = 1;
            Editable = false;
        }
        field(9; "Credit Limit (LCY)"; Decimal)
        {
            Caption = 'Credit Limit (LCY)';
            AutoFormatType = 1;
            Editable = false;
        }
        field(10; "Credit Utilization %"; Decimal)
        {
            Caption = 'Credit Utilization %';
            DecimalPlaces = 0 : 1;
            Editable = false;
        }
        field(11; "Watch List"; Boolean)
        {
            Caption = 'Watch List';
        }
        field(20; "Open Alert Count"; Integer)
        {
            Caption = 'Open Alerts';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where("Entity Type" = field("Profile Type"),
                                                        "Entity No." = field("Entity No."),
                                                        Status = filter(New | Acknowledged | "Under Review" | Escalated)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Profile Type", "Entity No.") { Clustered = true; }
        key(Score; "Risk Score") { }
        key(Watch; "Watch List", "Risk Score") { }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Entity No.", "Entity Name", "Risk Score", Severity) { }
    }
}
