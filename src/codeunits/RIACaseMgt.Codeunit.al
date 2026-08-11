/// <summary>Creates and manages investigation cases from alerts.</summary>
codeunit 50106 "RIA Case Mgt"
{
    Access = Public;
    Permissions = tabledata "RIA Investigation Case" = rim,
                  tabledata "RIA Risk Alert" = rm,
                  tabledata "RIA Risk Setup" = r;

    /// <summary>Creates a new investigation case seeded from an alert and links the alert to it.</summary>
    procedure CreateCaseFromAlert(var RiskAlert: Record "RIA Risk Alert"): Code[20]
    var
        InvestigationCase: Record "RIA Investigation Case";
        Setup: Record "RIA Risk Setup";
        NoSeriesCodeunit: Codeunit "No. Series";
        CaseNo: Code[20];
        TitleLbl: Label 'Investigation: %1', Comment = '%1 = alert title';
    begin
        Setup.GetSetup();
        if Setup."Case No. Series" <> '' then
            CaseNo := NoSeriesCodeunit.GetNextNo(Setup."Case No. Series", Today())
        else
            CaseNo := GenerateFallbackNo();

        InvestigationCase.Init();
        InvestigationCase."No." := CaseNo;
        InvestigationCase.Title := CopyStr(StrSubstNo(TitleLbl, RiskAlert.Title), 1, MaxStrLen(InvestigationCase.Title));
        InvestigationCase.Status := InvestigationCase.Status::Open;
        InvestigationCase.Severity := RiskAlert.Severity;
        InvestigationCase."Entity Type" := RiskAlert."Entity Type";
        InvestigationCase."Entity No." := RiskAlert."Entity No.";
        InvestigationCase.Description := CopyStr(RiskAlert.Description, 1, MaxStrLen(InvestigationCase.Description));
        InvestigationCase.Insert(true);

        RiskAlert."Case No." := CaseNo;
        if RiskAlert.Status = RiskAlert.Status::New then
            RiskAlert.Status := RiskAlert.Status::"Under Review";
        RiskAlert.Modify(true);

        exit(CaseNo);
    end;

    /// <summary>Closes a case and records the closer.</summary>
    procedure CloseCase(var InvestigationCase: Record "RIA Investigation Case")
    begin
        InvestigationCase.Status := InvestigationCase.Status::Closed;
        InvestigationCase."Closed Date" := Today();
        InvestigationCase."Closed By" := CopyStr(UserId(), 1, MaxStrLen(InvestigationCase."Closed By"));
        InvestigationCase.Modify(true);
    end;

    local procedure GenerateFallbackNo(): Code[20]
    var
        InvestigationCase: Record "RIA Investigation Case";
        NextNo: Integer;
    begin
        if InvestigationCase.FindLast() then
            Evaluate(NextNo, DelChr(InvestigationCase."No.", '=', DelChr(InvestigationCase."No.", '=', '0123456789')));
        NextNo += 1;
        exit(CopyStr('CASE' + Format(NextNo).PadLeft(6, '0'), 1, 20));
    end;
}
