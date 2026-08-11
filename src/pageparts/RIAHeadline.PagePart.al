/// <summary>Role Center headline RSS-style insights.</summary>
page 50102 "RIA Headline"
{
    PageType = HeadLinePart;
    SourceTable = "RIA Cue";
    Caption = 'Risk Headlines';

    layout
    {
        area(Content)
        {
            field(Headline1; Headline1Txt)
            {
                ApplicationArea = All;
                Caption = ' ';
                ToolTip = 'Critical alert headline.';
            }
            field(Headline2; Headline2Txt)
            {
                ApplicationArea = All;
                Caption = ' ';
                ToolTip = 'Workload headline.';
            }
        }
    }

    var
        Headline1Txt: Text;
        Headline2Txt: Text;

    trigger OnOpenPage()
    begin
        Rec.GetCue();
        Rec.CalcFields("Critical Open", "New Alerts");
        if Rec."Critical Open" > 0 then
            Headline1Txt := StrSubstNo(CriticalLbl, Rec."Critical Open")
        else
            Headline1Txt := AllClearLbl;
        Headline2Txt := StrSubstNo(NewLbl, Rec."New Alerts");
    end;

    var
        CriticalLbl: Label 'You have %1 critical risk alert(s) needing attention', Comment = '%1 = count';
        AllClearLbl: Label 'No critical alerts right now — risk posture is stable';
        NewLbl: Label '%1 new alert(s) awaiting triage', Comment = '%1 = count';
}
