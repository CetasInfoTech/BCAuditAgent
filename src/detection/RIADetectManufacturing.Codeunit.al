/// <summary>Manufacturing-domain L1 detection (L1-M001 to M006). Uses robust Prod. Order Line fields;
/// cost/BOM/routing checks are yield- and completion-based proxies (refine with site costing fields).</summary>
codeunit 50119 "RIA Detect Manufacturing"
{
    Access = Public;
    Permissions = tabledata "Prod. Order Line" = r, tabledata Item = r;

    var
        AlertMgt: Codeunit "RIA Alert Mgt";

    procedure DetectScrap() Raised: Integer
    begin
        exit(YieldCheck('L1-M001', 0.10, ScrapTitleLbl, ScrapDescLbl));
    end;

    procedure DetectBOMDeviations() Raised: Integer
    var
        POL: Record "Prod. Order Line";
        Hash: Text[100];
        AlertNo: Integer;
    begin
        // Over-production: finished quantity exceeds planned quantity (component/BOM over-consumption proxy).
        POL.SetFilter("Finished Quantity", '>0');
        POL.SetLoadFields("Prod. Order No.", "Item No.", Quantity, "Finished Quantity", "Line No.");
        if POL.FindSet() then
            repeat
                if (POL.Quantity > 0) and (POL."Finished Quantity" > POL.Quantity * 1.05) then begin
                    Hash := CopyStr(StrSubstNo('L1M002|%1|%2', POL."Prod. Order No.", POL."Line No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert('L1-M002',
                            CopyStr(StrSubstNo(BomTitleLbl, POL."Item No."), 1, 150),
                            CopyStr(StrSubstNo(BomDescLbl, POL."Prod. Order No.", POL."Item No.", Format(POL."Finished Quantity"), Format(POL.Quantity)), 1, 2048),
                            POL."Finished Quantity" - POL.Quantity, Hash, Database::"Prod. Order Line", POL.SystemId, POL."Prod. Order No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until POL.Next() = 0;
    end;

    procedure DetectProductionVariances() Raised: Integer
    begin
        // Incomplete past-due production: finished < planned after due date (schedule/variance proxy).
        exit(LateCheck('L1-M003', VarTitleLbl, VarDescLbl, true));
    end;

    procedure DetectRoutingDeviations() Raised: Integer
    begin
        // Released order with zero output past due date (routing not progressing).
        exit(LateCheck('L1-M004', RouteTitleLbl, RouteDescLbl, false));
    end;

    procedure DetectCapacityRisks() Raised: Integer
    begin
        // Released order past its due date and not finished (capacity/schedule risk).
        exit(LateCheck('L1-M005', CapTitleLbl, CapDescLbl, true));
    end;

    procedure DetectCostOverruns() Raised: Integer
    begin
        // Yield loss >20% as a cost-overrun proxy (more cost consumed per good unit produced).
        exit(YieldCheck('L1-M006', 0.20, CostTitleLbl, CostDescLbl));
    end;

    local procedure YieldCheck(ControlID: Code[20]; LossTol: Decimal; TitleLbl: Text; DescLbl: Text) Raised: Integer
    var
        POL: Record "Prod. Order Line";
        Hash: Text[100];
        AlertNo: Integer;
        LossPct: Decimal;
    begin
        POL.SetFilter(Quantity, '>0');
        POL.SetFilter("Finished Quantity", '>0');
        POL.SetLoadFields("Prod. Order No.", "Item No.", Quantity, "Finished Quantity", "Line No.");
        if POL.FindSet() then
            repeat
                if POL."Finished Quantity" < POL.Quantity then begin
                    LossPct := (POL.Quantity - POL."Finished Quantity") / POL.Quantity;
                    if LossPct >= LossTol then begin
                        Hash := CopyStr(StrSubstNo('%1|%2|%3', ControlID, POL."Prod. Order No.", POL."Line No."), 1, 100);
                        if not AlertMgt.AlertExists(Hash) then begin
                            AlertNo := AlertMgt.RaiseAlert(ControlID,
                                CopyStr(StrSubstNo(TitleLbl, POL."Item No."), 1, 150),
                                CopyStr(StrSubstNo(DescLbl, POL."Prod. Order No.", POL."Item No.", Format(Round(LossPct * 100, 0.1)), Format(POL.Quantity), Format(POL."Finished Quantity")), 1, 2048),
                                POL.Quantity - POL."Finished Quantity", Hash, Database::"Prod. Order Line", POL.SystemId, POL."Prod. Order No.");
                            if AlertNo <> 0 then
                                Raised += 1;
                        end;
                    end;
                end;
            until POL.Next() = 0;
    end;

    local procedure LateCheck(ControlID: Code[20]; TitleLbl: Text; DescLbl: Text; AllowPartial: Boolean) Raised: Integer
    var
        POL: Record "Prod. Order Line";
        Hash: Text[100];
        AlertNo: Integer;
        Trigger_L: Boolean;
    begin
        POL.SetRange(Status, POL.Status::Released);
        POL.SetFilter("Due Date", '<%1&<>%2', Today(), 0D);
        POL.SetLoadFields("Prod. Order No.", "Item No.", Quantity, "Finished Quantity", "Due Date", "Line No.");
        if POL.FindSet() then
            repeat
                if AllowPartial then
                    Trigger_L := POL."Finished Quantity" < POL.Quantity
                else
                    Trigger_L := POL."Finished Quantity" = 0;
                if Trigger_L then begin
                    Hash := CopyStr(StrSubstNo('%1|%2|%3', ControlID, POL."Prod. Order No.", POL."Line No."), 1, 100);
                    if not AlertMgt.AlertExists(Hash) then begin
                        AlertNo := AlertMgt.RaiseAlert(ControlID,
                            CopyStr(StrSubstNo(TitleLbl, POL."Item No."), 1, 150),
                            CopyStr(StrSubstNo(DescLbl, POL."Prod. Order No.", POL."Item No.", Format(POL."Due Date"), Format(POL."Finished Quantity"), Format(POL.Quantity)), 1, 2048),
                            POL.Quantity - POL."Finished Quantity", Hash, Database::"Prod. Order Line", POL.SystemId, POL."Prod. Order No.");
                        if AlertNo <> 0 then
                            Raised += 1;
                    end;
                end;
            until POL.Next() = 0;
    end;

    var
        ScrapTitleLbl: Label 'Yield loss / scrap: item %1', Comment = '%1=item';
        ScrapDescLbl: Label 'Production order %1 for item %2 lost %3%% (planned %4, finished %5). Investigate scrap/yield.', Comment = 'positional';
        BomTitleLbl: Label 'BOM over-consumption: item %1', Comment = '%1=item';
        BomDescLbl: Label 'Production order %1 finished %3 of item %2 vs planned %4 — possible BOM deviation or over-production.', Comment = 'positional';
        VarTitleLbl: Label 'Production variance: item %1', Comment = '%1=item';
        VarDescLbl: Label 'Order %1 (item %2) is past due %3 with %4 finished of %5 planned — schedule/cost variance.', Comment = 'positional';
        RouteTitleLbl: Label 'Routing stalled: item %1', Comment = '%1=item';
        RouteDescLbl: Label 'Order %1 (item %2) past due %3 has zero output (%4 of %5) — routing not progressing.', Comment = 'positional';
        CapTitleLbl: Label 'Capacity risk: item %1', Comment = '%1=item';
        CapDescLbl: Label 'Order %1 (item %2) is past due %3 and incomplete (%4 of %5) — capacity/scheduling risk.', Comment = 'positional';
        CostTitleLbl: Label 'Cost overrun (yield): item %1', Comment = '%1=item';
        CostDescLbl: Label 'Order %1 (item %2) lost %3%% yield (planned %4, finished %5), driving unit cost up.', Comment = 'positional';
}
