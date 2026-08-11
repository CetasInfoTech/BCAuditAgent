/// <summary>Creates and manages the background Job Queue entries that run detection and SLA monitoring.</summary>
codeunit 50109 "RIA Job Queue Mgt"
{
    Access = Public;
    Permissions = tabledata "Job Queue Entry" = RIMD,
                  tabledata "RIA Risk Setup" = r;

    /// <summary>Ensures recurring Job Queue entries exist for the detection engine and SLA monitor.</summary>
    procedure EnsureJobQueueEntries()
    var
        Setup: Record "RIA Risk Setup";
        IntervalMinutes: Integer;
    begin
        Setup.GetSetup();
        IntervalMinutes := Setup."Detection Interval (Min)";
        if IntervalMinutes < 5 then
            IntervalMinutes := 15;

        CreateOrUpdateEntry(Codeunit::"RIA Detection Engine", IntervalMinutes, DetectionDescLbl);
        CreateOrUpdateEntry(Codeunit::"RIA SLA Monitor", 60, SLADescLbl);
        CreateOrUpdateEntry(Codeunit::"RIA Delivery Mgt", 1440, DigestDescLbl);
    end;

    local procedure CreateOrUpdateEntry(CodeunitId: Integer; IntervalMinutes: Integer; Descr: Text[250])
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CodeunitId);
        if not JobQueueEntry.FindFirst() then begin
            JobQueueEntry.Init();
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := CodeunitId;
            JobQueueEntry.Insert(true);
        end;
        JobQueueEntry.Description := Descr;
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."No. of Minutes between Runs" := IntervalMinutes;
        SetAllRunDays(JobQueueEntry);
        JobQueueEntry.Modify(true);
    end;

    local procedure SetAllRunDays(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
    end;

    var
        DetectionDescLbl: Label 'RIA - Risk Detection Engine';
        SLADescLbl: Label 'RIA - SLA Monitor';
        DigestDescLbl: Label 'RIA - Daily Risk Digest';
}
