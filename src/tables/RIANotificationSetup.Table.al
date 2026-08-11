/// <summary>Per-user / per-severity notification routing configuration.</summary>
table 50108 "RIA Notification Setup"
{
    Caption = 'RIA Notification Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            TableRelation = "User Setup"."User ID";
            ValidateTableRelation = false;
            NotBlank = true;
        }
        field(2; "Minimum Severity"; Enum "RIA Severity")
        {
            Caption = 'Minimum Severity';
            InitValue = High;
        }
        field(3; "In-App"; Boolean)
        {
            Caption = 'In-App';
            InitValue = true;
        }
        field(4; "Email"; Boolean)
        {
            Caption = 'Email';
        }
        field(5; "Domain Filter"; Enum "RIA Domain")
        {
            Caption = 'Domain Filter';
        }
        field(6; "Email Address"; Text[250])
        {
            Caption = 'Email Address';
            ExtendedDatatype = EMail;
        }
    }

    keys
    {
        key(PK; "User ID") { Clustered = true; }
    }
}
