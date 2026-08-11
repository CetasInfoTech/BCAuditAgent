/// <summary>Lifecycle states for a risk alert (Section 13.3 of the FRD).</summary>
enum 50101 "RIA Alert Status"
{
    Extensible = true;
    Caption = 'RIA Alert Status';

    value(0; New) { Caption = 'New'; }
    value(1; Acknowledged) { Caption = 'Acknowledged'; }
    value(2; "Under Review") { Caption = 'Under Review'; }
    value(3; Resolved) { Caption = 'Resolved'; }
    value(4; "Resolved - Exception") { Caption = 'Resolved - Exception'; }
    value(5; Escalated) { Caption = 'Escalated'; }
    value(6; "False Positive") { Caption = 'False Positive'; }
}
