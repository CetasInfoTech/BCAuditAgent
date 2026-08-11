/// <summary>Projects/Jobs-domain L1 detection (L1-P001 to P004).</summary>
codeunit 50120 "RIA Detect Projects"
{
    Access = Public;
    Permissions = tabledata Job = r, tabledata "Job Task" = r,
                  tabledata "Job Ledger Entry" = r, tabledata "Time Sheet Detail" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L1-P001 Budget Overruns: job tasks where usage cost exceeds scheduled (budget) cost.</summary>
    procedure DetectBudgetOverruns() Raised: Integer
    var
        JobTask: Record "Job Task";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Budget overrun: job %1', Comment = '%1=job';
        DescLbl: Label 'Job %1 task %2 has used %3 against a budget of %4. Review the overrun before further cost is committed.', Comment = 'positional';
    begin
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        if JobTask.FindSet() then
            repeat
                JobTask.CalcFields("Usage (Total Cost)", "Schedule (Total Cost)");
                if (JobTask."Schedule (Total Cost)" > 0) and (JobTask."Usage (Total Cost)" > JobTask."Schedule (Total Cost)") then begin
                    Hash := CopyStr(StrSubstNo('L1P001|%1|%2', JobTask."Job No.", JobTask."Job Task No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L1-P001',
                            CopyStr(StrSubstNo(TitleLbl, JobTask."Job No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, JobTask."Job No.", JobTask."Job Task No.", Format(JobTask."Usage (Total Cost)"), Format(JobTask."Schedule (Total Cost)")), 1, 2048),
                            JobTask."Usage (Total Cost)" - JobTask."Schedule (Total Cost)", Hash, Database::"Job Task", JobTask.SystemId, JobTask."Job No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until JobTask.Next() = 0;
    end;

    /// <summary>L1-P002 Resource Utilization Issues: open jobs with no ledger activity in 60 days (stalled).</summary>
    procedure DetectResourceUtilization() Raised: Integer
    var
        Job: Record Job;
        JLE: Record "Job Ledger Entry";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Stalled job: %1', Comment = '%1=job';
        DescLbl: Label 'Job %1 (%2) is open but has had no ledger activity in 60 days — resource utilisation or progress concern.', Comment = 'positional';
    begin
        Job.SetRange(Status, Job.Status::Open);
        Job.SetLoadFields("No.", Description);
        if Job.FindSet() then
            repeat
                JLE.SetCurrentKey("Job No.", "Posting Date");
                JLE.SetRange("Job No.", Job."No.");
                JLE.SetRange("Posting Date", CalcDate('<-60D>', Today()), Today());
                if JLE.IsEmpty() then begin
                    Hash := CopyStr(StrSubstNo('L1P002|%1|%2', Job."No.", Format(Today())), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L1-P002',
                            CopyStr(StrSubstNo(TitleLbl, Job."No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, Job."No.", Job.Description), 1, 2048),
                            0, Hash, Database::Job, Job.SystemId, Job."No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until Job.Next() = 0;
    end;

    /// <summary>L1-P003 Revenue Recognition Concerns: job tasks with material usage but little/no billing.</summary>
    procedure DetectRevenueConcerns() Raised: Integer
    var
        JobTask: Record "Job Task";
        Threshold: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Unbilled job effort: %1', Comment = '%1=job';
        DescLbl: Label 'Job %1 task %2 has incurred %3 in usage cost but invoiced only %4. Confirm WIP/revenue recognition is current.', Comment = 'positional';
    begin
        Threshold := MaterialityX(2);
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        JobTask.SetLoadFields("Job No.", "Job Task No.");
        if JobTask.FindSet() then
            repeat
                JobTask.CalcFields("Usage (Total Cost)", "Contract (Invoiced Price)");
                if (JobTask."Usage (Total Cost)" >= Threshold) and (JobTask."Contract (Invoiced Price)" < JobTask."Usage (Total Cost)" / 2) then begin
                    Hash := CopyStr(StrSubstNo('L1P003|%1|%2', JobTask."Job No.", JobTask."Job Task No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L1-P003',
                            CopyStr(StrSubstNo(TitleLbl, JobTask."Job No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, JobTask."Job No.", JobTask."Job Task No.", Format(JobTask."Usage (Total Cost)"), Format(JobTask."Contract (Invoiced Price)")), 1, 2048),
                            JobTask."Usage (Total Cost)", Hash, Database::"Job Task", JobTask.SystemId, JobTask."Job No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until JobTask.Next() = 0;
    end;

    /// <summary>L1-P004 Timesheet Anomalies: timesheet days with excessive hours.</summary>
    procedure DetectTimesheetAnomalies() Raised: Integer
    var
        TSD: Record "Time Sheet Detail";
        MaxHours: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Excessive timesheet hours', Locked = false;
        DescLbl: Label 'Resource %1 logged %2 hours on %3 (above %4). Verify the entry is accurate.', Comment = 'positional';
    begin
        MaxHours := 12;
        TSD.SetFilter(Quantity, '>%1', MaxHours);
        TSD.SetRange(Date, CalcDate('<-90D>', Today()), Today());
        TSD.SetLoadFields("Time Sheet No.", "Time Sheet Line No.", Quantity, Date);
        if TSD.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1P004|%1|%2|%3', TSD."Time Sheet No.", TSD."Time Sheet Line No.", Format(TSD.Date)), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L1-P004',
                        CopyStr(TitleLbl, 1, 150),
                        CopyStr(StrSubstNo(DescLbl, TSD."Time Sheet No.", Format(TSD.Quantity), Format(TSD.Date), Format(MaxHours)), 1, 2048),
                        TSD.Quantity, Hash, Database::"Time Sheet Detail", TSD.SystemId, TSD."Time Sheet No.");
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until TSD.Next() = 0;
    end;

    local procedure MaterialityX(Multiplier: Decimal): Decimal
    var
        Setup: Record "RIA Risk Setup";
    begin
        Setup.GetSetup();
        if Setup."Materiality Floor (LCY)" <= 0 then
            exit(1000 * Multiplier);
        exit(Setup."Materiality Floor (LCY)" * Multiplier);
    end;
}
