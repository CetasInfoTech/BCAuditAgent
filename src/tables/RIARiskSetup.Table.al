/// <summary>Single-instance configuration table for the RIA solution.</summary>
table 50106 "RIA Risk Setup"
{
    Caption = 'RIA Risk Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Monitoring Enabled"; Boolean)
        {
            Caption = 'Monitoring Enabled';
            InitValue = true;
        }
        field(11; "Detection Interval (Min)"; Integer)
        {
            Caption = 'Detection Interval (Minutes)';
            InitValue = 15;
            MinValue = 5;
        }
        field(12; "Shadow Mode"; Boolean)
        {
            Caption = 'Shadow Mode';
            ToolTip = 'When enabled, alerts are recorded but notifications are suppressed (30-day calibration period).';
        }
        field(20; "SLA Critical (Hours)"; Integer)
        {
            Caption = 'SLA Critical (Hours)';
            InitValue = 4;
        }
        field(21; "SLA High (Hours)"; Integer)
        {
            Caption = 'SLA High (Hours)';
            InitValue = 24;
        }
        field(22; "SLA Medium (Hours)"; Integer)
        {
            Caption = 'SLA Medium (Hours)';
            InitValue = 120;
        }
        field(30; "Materiality Floor (LCY)"; Decimal)
        {
            Caption = 'Materiality Floor (LCY)';
            InitValue = 1000;
            AutoFormatType = 1;
        }
        field(31; "Case No. Series"; Code[20])
        {
            Caption = 'Case Nos.';
            TableRelation = "No. Series";
        }
        field(32; "Remediation No. Series"; Code[20])
        {
            Caption = 'Remediation Nos.';
            TableRelation = "No. Series";
        }
        field(40; "Notify Critical Email"; Boolean)
        {
            Caption = 'Email on Critical';
            InitValue = true;
        }
        field(41; "Default Risk Manager"; Code[50])
        {
            Caption = 'Default Risk Manager';
            TableRelation = "User Setup"."User ID";
            ValidateTableRelation = false;
        }
        field(50; "AI Copilot Enabled"; Boolean)
        {
            Caption = 'AI Copilot Enabled';
        }
        field(51; "AI Endpoint"; Text[250])
        {
            Caption = 'AI Endpoint';
            ExtendedDatatype = URL;
        }
        field(52; "AI Deployment"; Text[100])
        {
            Caption = 'AI Deployment Name';
        }
        field(53; "AI API Key Key"; Guid)
        {
            Caption = 'AI API Key Reference';
            ToolTip = 'Reference to the Azure OpenAI API key stored in Isolated Storage (the key value itself is never shown).';
        }
        field(55; "License Tier"; Enum "RIA License Tier")
        {
            Caption = 'License Tier';
            ToolTip = 'Controls above this tier are suppressed.';
        }
        field(56; "Enable Email Digest"; Boolean)
        {
            Caption = 'Enable Email Digest';
        }
        field(57; "Digest Recipient"; Text[250])
        {
            Caption = 'Digest Recipient';
            ExtendedDatatype = EMail;
        }
        field(58; "Teams Webhook URL"; Text[2048])
        {
            Caption = 'Teams Webhook URL';
            ExtendedDatatype = URL;
        }
        field(59; "Alert Webhook URL"; Text[2048])
        {
            Caption = 'Alert Webhook URL';
            ExtendedDatatype = URL;
        }
        field(60; "Setup Completed"; Boolean)
        {
            Caption = 'Setup Completed';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    /// <summary>Returns the singleton setup record, creating it if missing.</summary>
    procedure GetSetup()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(true);
        end;
    end;
}
