/// <summary>Compliance Monitoring — control effectiveness view (open vs total alerts per control).</summary>
page 50118 "RIA Compliance Monitoring"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "RIA Control Catalogue";
    Caption = 'Compliance Monitoring';
    Editable = false;
    SourceTableView = sorting(Layer, Domain);

    layout
    {
        area(Content)
        {
            repeater(Controls)
            {
                field("Control ID"; Rec."Control ID") { }
                field(Name; Rec.Name) { }
                field(Layer; Rec.Layer) { }
                field(Domain; Rec.Domain) { }
                field(Enabled; Rec.Enabled) { StyleExpr = EnabledStyle; }
                field("Open Alert Count"; Rec."Open Alert Count") { StyleExpr = OpenStyle; }
                field("Total Alert Count"; Rec."Total Alert Count") { }
                field(Effectiveness; EffectivenessTxt) { Caption = 'Status'; StyleExpr = OpenStyle; }
            }
        }
    }

    var
        EnabledStyle: Text;
        OpenStyle: Text;
        EffectivenessTxt: Text;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Open Alert Count");
        if Rec.Enabled then
            EnabledStyle := 'Favorable'
        else
            EnabledStyle := 'Subordinate';
        if Rec."Open Alert Count" > 0 then begin
            OpenStyle := 'Unfavorable';
            EffectivenessTxt := 'Action Required';
        end else begin
            OpenStyle := 'Favorable';
            EffectivenessTxt := 'Effective';
        end;
    end;
}
