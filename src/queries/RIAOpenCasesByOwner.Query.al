/// <summary>Open investigation cases grouped by assignee.</summary>
query 50101 "RIA Open Cases by Owner"
{
    Caption = 'RIA Open Cases by Owner';
    QueryType = Normal;

    elements
    {
        dataitem(InvestigationCase; "RIA Investigation Case")
        {
            DataItemTableFilter = Status = filter(Open | "In Progress" | "Pending Review");
            column(AssignedTo; "Assigned To") { }
            column(Severity; Severity) { }
            // column(CaseCount; "No.")
            // {
            //     Method = Count;
            // }
        }
    }
}
