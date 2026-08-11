/// <summary>Finance-domain L1 detection routines (L1-002, 003, 004, 005, 007, 008, 009).</summary>
codeunit 50115 "RIA Detect Finance"
{
    Access = Public;
    Permissions = tabledata "Vendor Ledger Entry" = r, tabledata "G/L Entry" = r,
                  tabledata "Bank Account Ledger Entry" = r, tabledata "VAT Entry" = r,
                  tabledata "Sales Invoice Line" = r, tabledata Vendor = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    /// <summary>L1-002 Duplicate Invoices: same vendor + amount + vendor invoice no. within window.</summary>
    procedure DetectDuplicateInvoices() Raised: Integer
    var
        VLE: Record "Vendor Ledger Entry";
        Cmp: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Possible duplicate invoice: %1', Comment = '%1=Vendor';
        DescLbl: Label 'Invoice %1 for %2 from vendor %3 (vendor invoice %4) matches another invoice with the same amount and vendor invoice number. Verify before payment.', Comment = '%1=doc,%2=amt,%3=vendor,%4=extdoc';
    begin
        VLE.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
        VLE.SetRange("Document Type", VLE."Document Type"::Invoice);
        VLE.SetRange("Posting Date", CalcDate('<-180D>', Today()), Today());
        VLE.SetFilter("External Document No.", '<>%1', '');
        VLE.SetLoadFields("Vendor No.", "External Document No.", "Amount (LCY)", "Document No.", "Entry No.");
        if VLE.FindSet() then
            repeat
                Cmp.SetCurrentKey("Document Type", "Vendor No.", "Posting Date");
                Cmp.SetRange("Document Type", Cmp."Document Type"::Invoice);
                Cmp.SetRange("Vendor No.", VLE."Vendor No.");
                Cmp.SetRange("External Document No.", VLE."External Document No.");
                Cmp.SetRange("Amount (LCY)", VLE."Amount (LCY)");
                Cmp.SetFilter("Entry No.", '<>%1', VLE."Entry No.");
                if not Cmp.IsEmpty() then begin
                    Hash := CopyStr(StrSubstNo('L1002|%1|%2|%3', VLE."Vendor No.", VLE."External Document No.", Format(VLE."Amount (LCY)")), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        if not Vendor.Get(VLE."Vendor No.") then
                            Clear(Vendor);
                        AlertNo := AlertMgt.RaiseEntityAlert('L1-002',
                            CopyStr(StrSubstNo(TitleLbl, VLE."Vendor No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, VLE."Document No.", Format(Abs(VLE."Amount (LCY)")), VLE."Vendor No.", VLE."External Document No."), 1, 2048),
                            Abs(VLE."Amount (LCY)"), Hash, Database::"Vendor Ledger Entry", VLE.SystemId, VLE."Document No.",
                            "RIA Profile Type"::Vendor, VLE."Vendor No.", Vendor.Name);
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until VLE.Next() = 0;
    end;

    /// <summary>L1-003 Suspicious Journals: large round-number G/L entries posted outside business hours or on weekends.</summary>
    procedure DetectSuspiciousJournals() Raised: Integer
    var
        GLE: Record "G/L Entry";
        Threshold: Decimal;
        CreatedTime: Time;
        IsWeekend: Boolean;
        OffHours: Boolean;
        RoundNumber: Boolean;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Suspicious journal entry %1', Comment = '%1=entry no';
        DescLbl: Label 'G/L entry %1 of %2 to account %3 was created %4. Round-number, out-of-hours, or weekend manual postings warrant review for manipulation.', Comment = '%1=entry,%2=amt,%3=acct,%4=context';
        CtxLbl: Label 'outside business hours / weekend';
    begin
        Threshold := MaterialityX(10);
        GLE.SetCurrentKey("Posting Date");
        GLE.SetRange("Posting Date", CalcDate('<-60D>', Today()), Today());
        GLE.SetFilter(Amount, '>=%1|<=%2', Threshold, -Threshold);
        GLE.SetLoadFields(Amount, "G/L Account No.", "Posting Date", "Entry No.", SystemCreatedAt);
        if GLE.FindSet() then
            repeat
                CreatedTime := DT2Time(GLE.SystemCreatedAt);
                OffHours := (CreatedTime < 060000T) or (CreatedTime >= 200000T);
                IsWeekend := Date2DWY(GLE."Posting Date", 1) in [6, 7];
                RoundNumber := (Abs(GLE.Amount) >= Threshold) and ((Abs(GLE.Amount) mod 1000) = 0);
                if (OffHours or IsWeekend) and RoundNumber then begin
                    Hash := CopyStr(StrSubstNo('L1003|%1', GLE."Entry No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L1-003',
                            CopyStr(StrSubstNo(TitleLbl, GLE."Entry No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, GLE."Entry No.", Format(GLE.Amount), GLE."G/L Account No.", CtxLbl), 1, 2048),
                            Abs(GLE.Amount), Hash, Database::"G/L Entry", GLE.SystemId, '');
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until GLE.Next() = 0;
    end;

    /// <summary>L1-004 Backdated / future-dated transactions: gap between system creation date and posting date.</summary>
    procedure DetectBackdated() Raised: Integer
    var
        GLE: Record "G/L Entry";
        BackDays: Integer;
        FwdDays: Integer;
        GapDays: Integer;
        CreatedDate: Date;
        Hash: Text[100];
        AlertNo: Integer;
        IsBack: Boolean;
        IsFwd: Boolean;
        TitleLbl: Label 'Date-shifted posting: entry %1', Comment = '%1=entry';
        BackLbl: Label 'G/L entry %1 (account %2, %3) was created on %4 but posted %5 days earlier (%6). Backdating into a prior/closed period distorts period results — verify approval.', Comment = '%1=entry,%2=acct,%3=amt,%4=created,%5=days,%6=postingdate';
        FwdLbl: Label 'G/L entry %1 (account %2, %3) was created on %4 but posted %5 days in the FUTURE (%6). Unrealistic future-dating warrants review.', Comment = 'same';
    begin
        BackDays := 30;
        FwdDays := 30;
        GLE.SetCurrentKey("Posting Date");
        GLE.SetRange("Posting Date", CalcDate('<-2Y>', Today()), CalcDate('<+2Y>', Today()));
        GLE.SetLoadFields("Posting Date", "Entry No.", "G/L Account No.", Amount, SystemCreatedAt);
        if GLE.FindSet() then
            repeat
                CreatedDate := DT2Date(GLE.SystemCreatedAt);
                GapDays := CreatedDate - GLE."Posting Date";
                IsBack := GapDays > BackDays;
                IsFwd := (GLE."Posting Date" - CreatedDate) > FwdDays;
                if IsBack or IsFwd then begin
                    Hash := CopyStr(StrSubstNo('L1004|%1', GLE."Entry No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        if IsBack then
                            AlertNo := AlertMgt.RaiseAlert('L1-004',
                                CopyStr(StrSubstNo(TitleLbl, GLE."Entry No."), 1, 150),
                                CopyStr(StrSubstNo(BackLbl, GLE."Entry No.", GLE."G/L Account No.", Format(GLE.Amount), Format(CreatedDate), Format(GapDays), Format(GLE."Posting Date")), 1, 2048),
                                Abs(GLE.Amount), Hash, Database::"G/L Entry", GLE.SystemId, '')
                        else
                            AlertNo := AlertMgt.RaiseAlert('L1-004',
                                CopyStr(StrSubstNo(TitleLbl, GLE."Entry No."), 1, 150),
                                CopyStr(StrSubstNo(FwdLbl, GLE."Entry No.", GLE."G/L Account No.", Format(GLE.Amount), Format(CreatedDate), Format(GLE."Posting Date" - CreatedDate), Format(GLE."Posting Date")), 1, 2048),
                                Abs(GLE.Amount), Hash, Database::"G/L Entry", GLE.SystemId, '');
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until GLE.Next() = 0;
    end;

    /// <summary>L1-005 Revenue Recognition Risks: material service (Resource) lines that may require deferral.</summary>
    procedure DetectRevenueRecognition() Raised: Integer
    var
        SIL: Record "Sales Invoice Line";
        Threshold: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Revenue recognition review: invoice %1', Comment = '%1=doc';
        DescLbl: Label 'Invoice %1 contains a service/resource line of %2 (%3). Confirm whether revenue should be deferred over the service period per IFRS 15 / ASC 606.', Comment = '%1=doc,%2=amt,%3=desc';
    begin
        Threshold := MaterialityX(5);
        SIL.SetRange(Type, SIL.Type::Resource);
        SIL.SetFilter("Line Amount", '>=%1', Threshold);
        SIL.SetLoadFields("Document No.", "Line Amount", Description, "Sell-to Customer No.");
        if SIL.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1005|%1|%2', SIL."Document No.", SIL."Line No."), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseEntityAlert('L1-005',
                        CopyStr(StrSubstNo(TitleLbl, SIL."Document No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, SIL."Document No.", Format(SIL."Line Amount"), SIL.Description), 1, 2048),
                        SIL."Line Amount", Hash, Database::"Sales Invoice Line", SIL.SystemId, SIL."Document No.",
                        "RIA Profile Type"::Customer, SIL."Sell-to Customer No.", '');
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until SIL.Next() = 0;
    end;

    /// <summary>L1-007 Cash Flow Anomalies: unusually large bank movements.</summary>
    procedure DetectCashFlowAnomalies() Raised: Integer
    var
        BALE: Record "Bank Account Ledger Entry";
        Threshold: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Large cash movement on %1', Comment = '%1=bank';
        DescLbl: Label 'Bank account %1 had a movement of %2 on %3 (document %4), well above the normal range. Confirm it is expected and authorised.', Comment = '%1=bank,%2=amt,%3=date,%4=doc';
    begin
        Threshold := MaterialityX(20);
        BALE.SetCurrentKey("Bank Account No.", "Posting Date");
        BALE.SetRange("Posting Date", CalcDate('<-90D>', Today()), Today());
        BALE.SetFilter("Amount (LCY)", '>=%1|<=%2', Threshold, -Threshold);
        BALE.SetLoadFields("Bank Account No.", "Amount (LCY)", "Posting Date", "Document No.", "Entry No.");
        if BALE.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1007|%1', BALE."Entry No."), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L1-007',
                        CopyStr(StrSubstNo(TitleLbl, BALE."Bank Account No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, BALE."Bank Account No.", Format(BALE."Amount (LCY)"), Format(BALE."Posting Date"), BALE."Document No."), 1, 2048),
                        Abs(BALE."Amount (LCY)"), Hash, Database::"Bank Account Ledger Entry", BALE.SystemId, BALE."Document No.");
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until BALE.Next() = 0;
    end;

    /// <summary>L1-008 Tax Exceptions: material taxable base posted with zero VAT.</summary>
    procedure DetectTaxExceptions() Raised: Integer
    var
        VATEntry: Record "VAT Entry";
        Threshold: Decimal;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Possible tax exception: entry %1', Comment = '%1=entry';
        DescLbl: Label 'VAT entry %1 has a taxable base of %2 but zero VAT amount (document %3, %4). Confirm the zero-rating or exemption is correct.', Comment = '%1=entry,%2=base,%3=doc,%4=date';
    begin
        Threshold := MaterialityX(5);
        VATEntry.SetCurrentKey("Posting Date");
        VATEntry.SetRange("Posting Date", CalcDate('<-90D>', Today()), Today());
        VATEntry.SetFilter(Base, '>=%1|<=%2', Threshold, -Threshold);
        VATEntry.SetRange(Amount, 0);
        VATEntry.SetLoadFields(Base, Amount, "Document No.", "Posting Date", "Entry No.");
        if VATEntry.FindSet() then
            repeat
                Hash := CopyStr(StrSubstNo('L1008|%1', VATEntry."Entry No."), 1, 100);
                if not AlertMgt.AlertExists(Hash) then begin
                    AlertNo := AlertMgt.RaiseAlert('L1-008',
                        CopyStr(StrSubstNo(TitleLbl, VATEntry."Entry No."), 1, 150),
                        CopyStr(StrSubstNo(DescLbl, VATEntry."Entry No.", Format(VATEntry.Base), VATEntry."Document No.", Format(VATEntry."Posting Date")), 1, 2048),
                        Abs(VATEntry.Base), Hash, Database::"VAT Entry", VATEntry.SystemId, VATEntry."Document No.");
                    if AlertNo <> 0 then
                        Raised += 1;
                end;
            until VATEntry.Next() = 0;
    end;

    /// <summary>L1-009 Posting Irregularities: same user posting many manual entries to one account on one day (round-trip risk).</summary>
    procedure DetectPostingIrregularities() Raised: Integer
    var
        GLE: Record "G/L Entry";
        EntryCount: Integer;
        SumAmount: Decimal;
        CurrentAcct: Code[20];
        CurrentUser: Code[50];
        CurrentDate: Date;
        Hash: Text[100];
        AlertNo: Integer;
        TitleLbl: Label 'Posting cluster: account %1', Comment = '%1=acct';
        DescLbl: Label 'User %1 posted %2 entries to account %3 on %4 (net %5). High-frequency same-account postings can indicate round-tripping — review.', Comment = '%1=user,%2=count,%3=acct,%4=date,%5=net';
    begin
        GLE.SetCurrentKey("G/L Account No.", "Posting Date");
        GLE.SetRange("Posting Date", CalcDate('<-60D>', Today()), Today());
        GLE.SetLoadFields("G/L Account No.", "Posting Date", "User ID", Amount, "Entry No.");
        if GLE.FindSet() then begin
            CurrentAcct := GLE."G/L Account No.";
            CurrentDate := GLE."Posting Date";
            CurrentUser := GLE."User ID";
            repeat
                if (GLE."G/L Account No." = CurrentAcct) and (GLE."Posting Date" = CurrentDate) and (GLE."User ID" = CurrentUser) then begin
                    EntryCount += 1;
                    SumAmount += GLE.Amount;
                end else begin
                    if EntryCount >= 4 then
                        if RaisePostingCluster(CurrentAcct, CurrentUser, CurrentDate, EntryCount, SumAmount, GLE.SystemId, TitleLbl, DescLbl) then
                            Raised += 1;
                    CurrentAcct := GLE."G/L Account No.";
                    CurrentDate := GLE."Posting Date";
                    CurrentUser := GLE."User ID";
                    EntryCount := 1;
                    SumAmount := GLE.Amount;
                end;
            until GLE.Next() = 0;
            if EntryCount >= 4 then
                if RaisePostingCluster(CurrentAcct, CurrentUser, CurrentDate, EntryCount, SumAmount, GLE.SystemId, TitleLbl, DescLbl) then
                    Raised += 1;
        end;
    end;

    local procedure RaisePostingCluster(Acct: Code[20]; User: Code[50]; PostDate: Date; Cnt: Integer; Net: Decimal; SysId: Guid; TitleLbl: Text; DescLbl: Text): Boolean
    var
        Hash: Text[100];
        AlertNo: Integer;
    begin
        Hash := CopyStr(StrSubstNo('L1009|%1|%2|%3', Acct, User, Format(PostDate)), 1, 100);
        if AlertMgt.AlertExists(Hash) then
            exit(false);
        AlertNo := AlertMgt.RaiseAlert('L1-009',
            CopyStr(StrSubstNo(TitleLbl, Acct), 1, 150),
            CopyStr(StrSubstNo(DescLbl, User, Cnt, Acct, Format(PostDate), Format(Net)), 1, 2048),
            Abs(Net), Hash, Database::"G/L Entry", SysId, '');
        exit(AlertNo <> 0);
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
