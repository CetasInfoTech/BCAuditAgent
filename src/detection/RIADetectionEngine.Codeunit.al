/// <summary>Orchestrates all detection routines across L1-L5. Invoked by the Job Queue and manual actions.
/// Dispatches each Control ID to the relevant domain/layer detection codeunit, honouring enable flags and license tier.</summary>
codeunit 50110 "RIA Detection Engine"
{
    Access = Public;
    TableNo = "RIA Risk Setup";

    trigger OnRun()
    begin
        RunAllDetections();
    end;

    /// <summary>Runs every enabled control that has an implemented routine. Returns alerts raised.</summary>
    procedure RunAllDetections() AlertsRaised: Integer
    var
        Control: Record "RIA Control Catalogue";
        Setup: Record "RIA Risk Setup";
    begin
        Setup.GetSetup();
        if not Setup."Monitoring Enabled" then
            exit(0);

        Control.SetRange(Enabled, true);
        Control.SetRange("Detection Available", true);
        if Control.FindSet() then
            repeat
                if TierAllows(Control."Min License Tier", Setup."License Tier") then
                    AlertsRaised += RunControl(Control."Control ID");
            until Control.Next() = 0;

        OnAfterRunAllDetections(AlertsRaised);
    end;

    /// <summary>Runs the detection routine for a single control. Central dispatcher.</summary>
    procedure RunControl(ControlID: Code[20]) AlertsRaised: Integer
    var
        DupPayment: Codeunit "RIA Detect Dup Payment";
        BankChange: Codeunit "RIA Detect Bank Change";
        CreditLimit: Codeunit "RIA Detect Credit Limit";
        NegInventory: Codeunit "RIA Detect Neg Inventory";
        Finance: Codeunit "RIA Detect Finance";
        Purchasing: Codeunit "RIA Detect Purchasing";
        Sales: Codeunit "RIA Detect Sales";
        Inventory: Codeunit "RIA Detect Inventory";
        Manufacturing: Codeunit "RIA Detect Manufacturing";
        Projects: Codeunit "RIA Detect Projects";
        FixedAssets: Codeunit "RIA Detect Fixed Assets";
        MasterData: Codeunit "RIA Detect Master Data";
        Process: Codeunit "RIA Detect Process";
        Config: Codeunit "RIA Detect Config";
        Predict: Codeunit "RIA Predict";
        Handled: Boolean;
    begin
        case ControlID of
            // Finance L1
            'L1-001':
                AlertsRaised := DupPayment.Detect();
            'L1-002':
                AlertsRaised := Finance.DetectDuplicateInvoices();
            'L1-003':
                AlertsRaised := Finance.DetectSuspiciousJournals();
            'L1-004':
                AlertsRaised := Finance.DetectBackdated();
            'L1-005':
                AlertsRaised := Finance.DetectRevenueRecognition();
            'L1-006':
                AlertsRaised := CreditLimit.Detect();
            'L1-007':
                AlertsRaised := Finance.DetectCashFlowAnomalies();
            'L1-008':
                AlertsRaised := Finance.DetectTaxExceptions();
            'L1-009':
                AlertsRaised := Finance.DetectPostingIrregularities();
            // Purchasing L1
            'L1-010':
                AlertsRaised := Purchasing.DetectSplitPOs();
            'L1-011':
                AlertsRaised := Purchasing.DetectPriceDeviations();
            'L1-012':
                AlertsRaised := Purchasing.DetectUnauthorizedVendors();
            'L1-013':
                AlertsRaised := BankChange.Detect();
            'L1-014':
                AlertsRaised := Purchasing.DetectOffContract();
            'L1-015':
                AlertsRaised := Purchasing.DetectApprovalViolations();
            // Sales L1
            'L1-016':
                AlertsRaised := Sales.DetectMarginErosion();
            'L1-017':
                AlertsRaised := Sales.DetectPricingDeviations();
            'L1-018':
                AlertsRaised := Sales.DetectRevenueLeakage();
            'L1-019':
                AlertsRaised := Sales.DetectSuspiciousReturns();
            'L1-020':
                AlertsRaised := Sales.DetectCustomerCreditRisk();
            // Inventory L1
            'L1-021':
                AlertsRaised := NegInventory.Detect();
            'L1-022':
                AlertsRaised := Inventory.DetectShrinkage();
            'L1-023':
                AlertsRaised := Inventory.DetectExcessiveAdjustments();
            'L1-024':
                AlertsRaised := Inventory.DetectSlowMoving();
            'L1-025':
                AlertsRaised := Inventory.DetectDeadStock();
            'L1-026':
                AlertsRaised := Inventory.DetectLotRisks();
            // Manufacturing L1
            'L1-M001':
                AlertsRaised := Manufacturing.DetectScrap();
            'L1-M002':
                AlertsRaised := Manufacturing.DetectBOMDeviations();
            'L1-M003':
                AlertsRaised := Manufacturing.DetectProductionVariances();
            'L1-M004':
                AlertsRaised := Manufacturing.DetectRoutingDeviations();
            'L1-M005':
                AlertsRaised := Manufacturing.DetectCapacityRisks();
            'L1-M006':
                AlertsRaised := Manufacturing.DetectCostOverruns();
            // Projects L1
            'L1-P001':
                AlertsRaised := Projects.DetectBudgetOverruns();
            'L1-P002':
                AlertsRaised := Projects.DetectResourceUtilization();
            'L1-P003':
                AlertsRaised := Projects.DetectRevenueConcerns();
            'L1-P004':
                AlertsRaised := Projects.DetectTimesheetAnomalies();
            // Fixed Assets L1
            'L1-FA01':
                AlertsRaised := FixedAssets.DetectGhostAssets();
            'L1-FA02':
                AlertsRaised := FixedAssets.DetectDepreciationExceptions();
            'L1-FA03':
                AlertsRaised := FixedAssets.DetectCapitalizationViolations();
            'L1-FA04':
                AlertsRaised := FixedAssets.DetectDisposalRisks();
            // Master Data L1
            'L1-MD01':
                AlertsRaised := MasterData.DetectDuplicateVendors();
            'L1-MD02':
                AlertsRaised := MasterData.DetectDuplicateCustomers();
            'L1-MD03':
                AlertsRaised := MasterData.DetectMissingGovernance();
            'L1-MD04':
                AlertsRaised := MasterData.DetectConfigViolations();
            // Process L2
            'L2-P2P-01':
                AlertsRaised := Process.DetectThreeWayMatch();
            'L2-Q2C-01':
                AlertsRaised := Process.DetectFulfillment();
            'L2-R2R-01':
                AlertsRaised := Process.DetectPeriodEndClose();
            'L2-PTP-01':
                AlertsRaised := Process.DetectPlanToProduce();
            'L2-IC-01':
                AlertsRaised := Process.DetectIntercompany();
            'L2-PTC-01':
                AlertsRaised := Process.DetectProjectToCash();
            // Config L3
            'L3-001':
                AlertsRaised := Config.DetectPostingSetupGovernance();
            'L3-002':
                AlertsRaised := Config.DetectApprovalWorkflow();
            'L3-003':
                AlertsRaised := Config.DetectSoD();
            'L3-004':
                AlertsRaised := Config.DetectNumberSeries();
            'L3-005':
                AlertsRaised := Config.DetectChangeLogIntegrity();
            // Predictive L5 (deterministic projections)
            'L5-001':
                AlertsRaised := Predict.CashFlowRisk();
            'L5-002':
                AlertsRaised := Predict.CustomerDefaultRisk();
            'L5-003':
                AlertsRaised := Predict.InventoryShortageRisk();
            'L5-004':
                AlertsRaised := Predict.MarginErosionRisk();
            else
                OnRunCustomControl(ControlID, AlertsRaised, Handled);
        end;
    end;

    /// <summary>Returns true if the control's minimum tier is at or below the licensed tier.</summary>
    procedure TierAllows(ControlTier: Enum "RIA License Tier"; LicensedTier: Enum "RIA License Tier"): Boolean
    begin
        exit(ControlTier.AsInteger() <= LicensedTier.AsInteger());
    end;

    /// <summary>Extensibility point: partners can register their own control detection routines.</summary>
    [IntegrationEvent(false, false)]
    local procedure OnRunCustomControl(ControlID: Code[20]; var AlertsRaised: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunAllDetections(AlertsRaised: Integer)
    begin
    end;
}
