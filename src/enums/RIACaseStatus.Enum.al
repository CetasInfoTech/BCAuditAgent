/// <summary>Investigation case lifecycle.</summary>
enum 50105 "RIA Case Status"
{
    Extensible = true;
    Caption = 'RIA Case Status';

    value(0; Open) { Caption = 'Open'; }
    value(1; "In Progress") { Caption = 'In Progress'; }
    value(2; "Pending Review") { Caption = 'Pending Review'; }
    value(3; Closed) { Caption = 'Closed'; }
}
