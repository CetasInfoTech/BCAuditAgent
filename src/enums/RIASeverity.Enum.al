/// <summary>Risk severity classification aligned to the RIA risk scoring model.</summary>
enum 50100 "RIA Severity"
{
    Extensible = true;
    Caption = 'RIA Severity';

    value(0; "None") { Caption = 'None'; }
    value(1; Low) { Caption = 'Low'; }
    value(2; Medium) { Caption = 'Medium'; }
    value(3; "Medium-High") { Caption = 'Medium-High'; }
    value(4; High) { Caption = 'High'; }
    value(5; Critical) { Caption = 'Critical'; }
}
