/// <summary>Remediation action lifecycle.</summary>
enum 50106 "RIA Remediation Status"
{
    Extensible = true;
    Caption = 'RIA Remediation Status';

    value(0; Open) { Caption = 'Open'; }
    value(1; "In Progress") { Caption = 'In Progress'; }
    value(2; Completed) { Caption = 'Completed'; }
    value(3; Overdue) { Caption = 'Overdue'; }
}
