/// <summary>OData v4 API exposing read access to risk alerts for Power BI and external GRC tools.</summary>
page 50127 "RIA Alert API"
{
    PageType = API;
    APIPublisher = 'cetas';
    APIGroup = 'risk';
    APIVersion = 'v1.0';
    EntityName = 'riskAlert';
    EntitySetName = 'riskAlerts';
    SourceTable = "RIA Risk Alert";
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    Editable = false;
    Caption = 'RIA Alert API';

    layout
    {
        area(Content)
        {
            repeater(Alerts)
            {
                field(systemId; Rec.SystemId) { }
                field(entryNo; Rec."Entry No.") { }
                field(controlId; Rec."Control ID") { }
                field(controlName; Rec."Control Name") { }
                field(domain; Rec.Domain) { }
                field(layer; Rec.Layer) { }
                field(severity; Rec.Severity) { }
                field(riskScore; Rec."Risk Score") { }
                field(status; Rec.Status) { }
                field(title; Rec.Title) { }
                field(amountLCY; Rec."Amount (LCY)") { }
                field(entityType; Rec."Entity Type") { }
                field(entityNo; Rec."Entity No.") { }
                field(entityName; Rec."Entity Name") { }
                field(detectedDateTime; Rec."Detected DateTime") { }
                field(slaDueDateTime; Rec."SLA Due DateTime") { }
                field(slaBreached; Rec."SLA Breached") { }
                field(caseNo; Rec."Case No.") { }
                field(lastModifiedDateTime; Rec.SystemModifiedAt) { }
            }
        }
    }
}
