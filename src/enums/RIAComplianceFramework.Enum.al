/// <summary>Compliance frameworks that RIA controls can be mapped to for audit evidence.</summary>
enum 50109 "RIA Compliance Framework"
{
    Extensible = true;
    Caption = 'RIA Compliance Framework';

    value(0; "SOX") { Caption = 'SOX'; }
    value(1; "ISO 9001") { Caption = 'ISO 9001'; }
    value(2; "GDPR") { Caption = 'GDPR'; }
    value(3; "IFRS") { Caption = 'IFRS / GAAP'; }
    value(4; "Internal Controls") { Caption = 'Internal Controls'; }
}
