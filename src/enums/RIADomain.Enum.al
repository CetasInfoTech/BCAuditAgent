/// <summary>Functional domain a control belongs to.</summary>
enum 50103 "RIA Domain"
{
    Extensible = true;
    Caption = 'RIA Domain';

    value(0; "None") { Caption = 'None'; }
    value(1; Finance) { Caption = 'Finance'; }
    value(2; Purchasing) { Caption = 'Purchasing'; }
    value(3; Sales) { Caption = 'Sales'; }
    value(4; Inventory) { Caption = 'Inventory'; }
    value(5; Manufacturing) { Caption = 'Manufacturing'; }
    value(6; Projects) { Caption = 'Projects'; }
    value(7; "Fixed Assets") { Caption = 'Fixed Assets'; }
    value(8; "Master Data") { Caption = 'Master Data'; }
}
