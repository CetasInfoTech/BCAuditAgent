/// <summary>Aggregated open-alert counts by domain and severity, used by analytics and external reporting.</summary>
query 50100 "RIA Alerts by Severity"
{
    Caption = 'RIA Alerts by Severity';
    QueryType = Normal;

    elements
    {
        dataitem(RiskAlert; "RIA Risk Alert")
        {
            column(Domain; Domain) { }
            column(Severity; Severity) { }
            column(Status; Status) { }
            // column(AlertCount; "Entry No.")
            // {
            //     Method = Count;
            // }
            column(TotalAmountLCY; "Amount (LCY)")
            {
                Method = Sum;
            }
        }
    }
}
