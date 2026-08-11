/// <summary>Fixed-Assets-domain L1 detection (L1-FA01 to FA04).</summary>
codeunit 50121 "RIA Detect Fixed Assets"
{
    Access = Public;
    Permissions = tabledata "Fixed Asset" = r, tabledata "FA Ledger Entry" = r,
                  tabledata "FA Depreciation Book" = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L1-FA01 Ghost Assets: active assets with book value but no ledger movement in 365 days.</summary>
    procedure DetectGhostAssets() Raised: Integer
    var
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Possible ghost asset: %1', Comment = '%1=fa';
        DescLbl: Label 'Fixed asset %1 (%2) is active but has had no ledger activity in 365 days. Confirm it physically exists (ghost/missing asset risk).', Comment = 'positional';
    begin
        FA.SetRange(Blocked, false);
        FA.SetRange(Inactive, false);
        FA.SetLoadFields("No.", Description);
        if FA.FindSet() then
            repeat
                FALedgEntry.SetCurrentKey("FA No.", "FA Posting Date");
                FALedgEntry.SetRange("FA No.", FA."No.");
                FALedgEntry.SetRange("FA Posting Date", CalcDate('<-365D>', Today()), Today());
                if FALedgEntry.IsEmpty() then begin
                    Hash := CopyStr(StrSubstNo('L1FA01|%1|%2', FA."No.", Format(Today())), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L1-FA01',
                            CopyStr(StrSubstNo(TitleLbl, FA."No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, FA."No.", FA.Description), 1, 2048),
                            0, Hash, Database::"Fixed Asset", FA.SystemId, FA."No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until FA.Next() = 0;
    end;

    /// <summary>L1-FA02 Depreciation Exceptions: depreciable books with positive book value not depreciated in 90 days.</summary>
    procedure DetectDepreciationExceptions() Raised: Integer
    var
        FADeprBook: Record "FA Depreciation Book";
        FA: Record "Fixed Asset";
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Depreciation gap: asset %1', Comment = '%1=fa';
        DescLbl: Label 'Asset %1 (book %2) has book value %3 but was last depreciated on %4. Missed depreciation overstates assets and understates expense.', Comment = 'positional';
    begin
        FADeprBook.SetLoadFields("FA No.", "Depreciation Book Code", "Last Depreciation Date");
        if FADeprBook.FindSet() then
            repeat
                FADeprBook.CalcFields("Book Value");
                if (FADeprBook."Book Value" > 0) and
                   ((FADeprBook."Last Depreciation Date" = 0D) or (FADeprBook."Last Depreciation Date" < CalcDate('<-90D>', Today()))) then begin
                    Hash := CopyStr(StrSubstNo('L1FA02|%1|%2', FADeprBook."FA No.", FADeprBook."Depreciation Book Code"), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        if not FA.Get(FADeprBook."FA No.") then
                            Clear(FA);
                        AlertNo := AlertMgt.RaiseAlert('L1-FA02',
                            CopyStr(StrSubstNo(TitleLbl, FADeprBook."FA No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, FADeprBook."FA No.", FADeprBook."Depreciation Book Code", Format(FADeprBook."Book Value"), Format(FADeprBook."Last Depreciation Date")), 1, 2048),
                            FADeprBook."Book Value", Hash, Database::"FA Depreciation Book", FADeprBook.SystemId, FADeprBook."FA No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until FADeprBook.Next() = 0;
    end;

    /// <summary>L1-FA03 Capitalization Violations: low-value acquisitions that likely should have been expensed.</summary>
    procedure DetectCapitalizationViolations() Raised: Integer
    var
        FALedgEntry: Record "FA Ledger Entry";
        FloorAmt: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Capitalization review: asset %1', Comment = '%1=fa';
        DescLbl: Label 'Asset %1 was capitalised at %2, below the %3 capitalisation floor. Confirm it should be a fixed asset rather than an expense.', Comment = 'positional';
    begin
        FloorAmt := CapitalizationFloor();
        FALedgEntry.SetCurrentKey("FA No.", "FA Posting Date");
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
        FALedgEntry.SetRange("FA Posting Date", CalcDate('<-180D>', Today()), Today());
        FALedgEntry.SetFilter(Amount, '>0&<%1', FloorAmt);
        FALedgEntry.SetLoadFields("FA No.", Amount, "Entry No.");
        if FALedgEntry.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1FA03|%1', FALedgEntry."Entry No."), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L1-FA03',
                        CopyStr(StrSubstNo(TitleLbl, FALedgEntry."FA No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, FALedgEntry."FA No.", Format(FALedgEntry.Amount), Format(FloorAmt)), 1, 2048),
                        FALedgEntry.Amount, Hash, Database::"FA Ledger Entry", FALedgEntry.SystemId, FALedgEntry."FA No.");
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until FALedgEntry.Next() = 0;
    end;

    /// <summary>L1-FA04 Disposal Risks: disposals posted at a material loss (below net book value).</summary>
    procedure DetectDisposalRisks() Raised: Integer
    var
        FALedgEntry: Record "FA Ledger Entry";
        LossThreshold: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Disposal loss: asset %1', Comment = '%1=fa';
        DescLbl: Label 'Asset %1 was disposed with a loss of %2 on %3. Disposals below net book value warrant approval and review for asset stripping.', Comment = 'positional';
    begin
        LossThreshold := MaterialityX(1);
        FALedgEntry.SetCurrentKey("FA No.", "FA Posting Date");
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Proceeds on Disposal");
        FALedgEntry.SetRange("FA Posting Date", CalcDate('<-365D>', Today()), Today());
        FALedgEntry.SetLoadFields("FA No.", Amount, "Result on Disposal", "FA Posting Date", "Entry No.");
        if FALedgEntry.FindSet() then
            repeat
                if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Loss then begin
                    Hash := CopyStr(StrSubstNo('L1FA04|%1', FALedgEntry."Entry No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L1-FA04',
                            CopyStr(StrSubstNo(TitleLbl, FALedgEntry."FA No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, FALedgEntry."FA No.", Format(Abs(FALedgEntry.Amount)), Format(FALedgEntry."FA Posting Date")), 1, 2048),
                            Abs(FALedgEntry.Amount), Hash, Database::"FA Ledger Entry", FALedgEntry.SystemId, FALedgEntry."FA No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until FALedgEntry.Next() = 0;
    end;

    local procedure CapitalizationFloor(): Decimal
    var
        Setup: Record "RIA Risk Setup";
    begin
        Setup.GetSetup();
        if Setup."Materiality Floor (LCY)" <= 0 then
            exit(500);
        exit(Setup."Materiality Floor (LCY)" / 2);
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
