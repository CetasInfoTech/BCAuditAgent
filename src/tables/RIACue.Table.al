/// <summary>Backing table for Role Center activity cues (single record).</summary>
table 50109 "RIA Cue"
{
    Caption = 'RIA Cue';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10]) { Caption = 'Primary Key'; }
        field(10; "Critical Open"; Integer)
        {
            Caption = 'Critical Open';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where(Severity = const(Critical),
                Status = filter(New | Acknowledged | "Under Review" | Escalated)));
            Editable = false;
        }
        field(11; "High Open"; Integer)
        {
            Caption = 'High Open';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where(Severity = const(High),
                Status = filter(New | Acknowledged | "Under Review" | Escalated)));
            Editable = false;
        }
        field(12; "New Alerts"; Integer)
        {
            Caption = 'New Alerts';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where(Status = const(New)));
            Editable = false;
        }
        field(13; "SLA Breached"; Integer)
        {
            Caption = 'SLA Breached';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Alert" where("SLA Breached" = const(true),
                Status = filter(New | Acknowledged | "Under Review")));
            Editable = false;
        }
        field(14; "Open Cases"; Integer)
        {
            Caption = 'Open Cases';
            FieldClass = FlowField;
            CalcFormula = count("RIA Investigation Case" where(Status = filter(Open | "In Progress" | "Pending Review")));
            Editable = false;
        }
        field(15; "Overdue Remediations"; Integer)
        {
            Caption = 'Overdue Remediations';
            FieldClass = FlowField;
            CalcFormula = count("RIA Remediation Action" where(Status = const(Overdue)));
            Editable = false;
        }
        field(16; "Watchlist Entities"; Integer)
        {
            Caption = 'Watchlist Entities';
            FieldClass = FlowField;
            CalcFormula = count("RIA Risk Profile" where("Watch List" = const(true)));
            Editable = false;
        }
        field(17; "Total Exposure (LCY)"; Decimal)
        {
            Caption = 'Total Exposure (LCY)';
            FieldClass = FlowField;
            CalcFormula = sum("RIA Risk Alert"."Amount (LCY)" where(
                Status = filter(New | Acknowledged | "Under Review" | Escalated)));
            AutoFormatType = 1;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }

    procedure GetCue()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
