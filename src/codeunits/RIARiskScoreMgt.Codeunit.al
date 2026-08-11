/// <summary>Computes composite risk scores and maps scores to severity bands (FRD 13.2).</summary>
codeunit 50100 "RIA Risk Score Mgt"
{
    Access = Public;

    /// <summary>Applies amount/frequency/recency/context weights to a base severity score.</summary>
    procedure ComputeScore(BaseScore: Decimal; AmountLCY: Decimal; MaterialityFloor: Decimal; RecurringCount: Integer; FraudIndicator: Boolean; PeriodEnd: Boolean): Decimal
    var
        Score: Decimal;
        AmountWeight: Decimal;
        FrequencyWeight: Decimal;
        ContextWeight: Decimal;
    begin
        AmountWeight := 1.0;
        if MaterialityFloor > 0 then
            if AmountLCY >= (MaterialityFloor * 5) then
                AmountWeight := 1.2
            else
                if AmountLCY < MaterialityFloor then
                    AmountWeight := 0.8;

        FrequencyWeight := 1.0;
        case true of
            RecurringCount > 3:
                FrequencyWeight := 1.5;
            RecurringCount >= 1:
                FrequencyWeight := 1.25;
        end;

        ContextWeight := 1.0;
        if FraudIndicator then
            ContextWeight := ContextWeight * 1.3;
        if PeriodEnd then
            ContextWeight := ContextWeight * 1.2;

        Score := BaseScore * AmountWeight * FrequencyWeight * ContextWeight;
        exit(NormalizeScore(Score));
    end;

    /// <summary>Clamps a raw score to the 0-10 range with one decimal place.</summary>
    procedure NormalizeScore(RawScore: Decimal): Decimal
    begin
        if RawScore > 10 then
            RawScore := 10;
        if RawScore < 0 then
            RawScore := 0;
        exit(Round(RawScore, 0.1));
    end;

    /// <summary>Maps a 0-10 score to a severity band.</summary>
    procedure ScoreToSeverity(Score: Decimal): Enum "RIA Severity"
    begin
        case true of
            Score >= 9.0:
                exit("RIA Severity"::Critical);
            Score >= 7.0:
                exit("RIA Severity"::High);
            Score >= 6.0:
                exit("RIA Severity"::"Medium-High");
            Score >= 5.0:
                exit("RIA Severity"::Medium);
            else
                exit("RIA Severity"::Low);
        end;
    end;

    /// <summary>Recalculates the rolling risk score for a single entity from its open alerts.</summary>
    procedure RecalculateEntityScore(ProfileType: Enum "RIA Profile Type"; EntityNo: Code[20])
    var
        RiskAlert: Record "RIA Risk Alert";
        RiskProfile: Record "RIA Risk Profile";
        TotalScore: Decimal;
        AlertCount: Integer;
        AvgScore: Decimal;
    begin
        RiskAlert.SetCurrentKey("Entity Type", "Entity No.");
        RiskAlert.SetRange("Entity Type", ProfileType);
        RiskAlert.SetRange("Entity No.", EntityNo);
        RiskAlert.SetFilter(Status, '%1|%2|%3|%4',
            RiskAlert.Status::New, RiskAlert.Status::Acknowledged,
            RiskAlert.Status::"Under Review", RiskAlert.Status::Escalated);
        RiskAlert.SetLoadFields("Risk Score");
        if RiskAlert.FindSet() then
            repeat
                TotalScore += RiskAlert."Risk Score";
                AlertCount += 1;
            until RiskAlert.Next() = 0;

        if AlertCount > 0 then
            AvgScore := NormalizeScore(TotalScore / AlertCount)
        else
            AvgScore := 0;

        if not RiskProfile.Get(ProfileType, EntityNo) then begin
            RiskProfile.Init();
            RiskProfile."Profile Type" := ProfileType;
            RiskProfile."Entity No." := EntityNo;
            RiskProfile.Insert();
        end;
        RiskProfile."Risk Score" := AvgScore;
        RiskProfile.Severity := ScoreToSeverity(AvgScore);
        RiskProfile."Last Calculated" := CurrentDateTime();
        RiskProfile.Modify();
    end;
}
