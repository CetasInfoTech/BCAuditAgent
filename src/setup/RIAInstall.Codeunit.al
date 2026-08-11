/// <summary>Install/upgrade codeunit. Seeds the full Control Catalogue (L1-L5), license tiers,
/// and compliance-framework mappings, and creates the setup singleton. Idempotent.</summary>
codeunit 50105 "RIA Install"
{
    Subtype = Install;
    Access = Internal;
    Permissions = tabledata "RIA Control Catalogue" = rim,
                  tabledata "RIA Risk Setup" = rim,
                  tabledata "RIA Compliance Mapping" = rim;

    trigger OnInstallAppPerCompany()
    begin
        InitializeSetup();
        SeedControlCatalogue();
        SeedComplianceMappings();
    end;

    local procedure InitializeSetup()
    var
        Setup: Record "RIA Risk Setup";
    begin
        Setup.GetSetup();
    end;

    /// <summary>Seeds all controls across the five layers. All listed controls have a live detection routine.</summary>
    procedure SeedControlCatalogue()
    var
        S: Enum "RIA Severity";
        L: Enum "RIA Layer";
        D: Enum "RIA Domain";
        P: Enum "RIA Control Priority";
        T: Enum "RIA License Tier";
    begin
        // ---- L1 Finance (Standard tier) ----
        Seed('L1-001', 'Duplicate Payments', L::"L1 Transaction", D::Finance, P::Critical, S::Critical, 9.0, T::Standard);
        Seed('L1-002', 'Duplicate Invoices', L::"L1 Transaction", D::Finance, P::High, S::High, 7.0, T::Standard);
        Seed('L1-003', 'Suspicious Journals', L::"L1 Transaction", D::Finance, P::Critical, S::Critical, 9.0, T::Standard);
        Seed('L1-004', 'Backdated Transactions', L::"L1 Transaction", D::Finance, P::High, S::High, 7.0, T::Standard);
        Seed('L1-005', 'Revenue Recognition Risks', L::"L1 Transaction", D::Finance, P::High, S::High, 8.0, T::Standard);
        Seed('L1-006', 'Credit Limit Violations', L::"L1 Transaction", D::Finance, P::High, S::High, 7.0, T::Standard);
        Seed('L1-007', 'Cash Flow Anomalies', L::"L1 Transaction", D::Finance, P::Critical, S::Critical, 10.0, T::Standard);
        Seed('L1-008', 'Tax Exceptions', L::"L1 Transaction", D::Finance, P::High, S::High, 7.0, T::Standard);
        Seed('L1-009', 'Posting Irregularities', L::"L1 Transaction", D::Finance, P::Medium, S::"Medium-High", 6.0, T::Standard);
        // ---- L1 Purchasing (Standard) ----
        Seed('L1-010', 'Split Purchase Orders', L::"L1 Transaction", D::Purchasing, P::Critical, S::Critical, 9.0, T::Standard);
        Seed('L1-011', 'Vendor Price Deviations', L::"L1 Transaction", D::Purchasing, P::High, S::High, 7.0, T::Standard);
        Seed('L1-012', 'Unauthorized Vendors', L::"L1 Transaction", D::Purchasing, P::Critical, S::Critical, 9.0, T::Standard);
        Seed('L1-013', 'Vendor Bank Account Changes', L::"L1 Transaction", D::Purchasing, P::Critical, S::Critical, 10.0, T::Standard);
        Seed('L1-014', 'Purchases Outside Contracts', L::"L1 Transaction", D::Purchasing, P::Medium, S::Medium, 5.0, T::Standard);
        Seed('L1-015', 'Approval Violations', L::"L1 Transaction", D::Purchasing, P::Critical, S::Critical, 9.0, T::Standard);
        // ---- L1 Sales (Standard) ----
        Seed('L1-016', 'Margin Erosion', L::"L1 Transaction", D::Sales, P::High, S::High, 7.0, T::Standard);
        Seed('L1-017', 'Pricing Deviations', L::"L1 Transaction", D::Sales, P::Medium, S::"Medium-High", 6.0, T::Standard);
        Seed('L1-018', 'Revenue Leakage', L::"L1 Transaction", D::Sales, P::High, S::High, 7.0, T::Standard);
        Seed('L1-019', 'Suspicious Returns', L::"L1 Transaction", D::Sales, P::Medium, S::"Medium-High", 6.0, T::Standard);
        Seed('L1-020', 'Customer Credit Risks', L::"L1 Transaction", D::Sales, P::High, S::High, 8.0, T::Standard);
        // ---- L1 Inventory (Premium) ----
        Seed('L1-021', 'Negative Inventory', L::"L1 Transaction", D::Inventory, P::High, S::High, 7.0, T::Standard);
        Seed('L1-022', 'Inventory Shrinkage', L::"L1 Transaction", D::Inventory, P::High, S::High, 7.0, T::Premium);
        Seed('L1-023', 'Excessive Inventory Adjustments', L::"L1 Transaction", D::Inventory, P::Medium, S::Medium, 5.0, T::Premium);
        Seed('L1-024', 'Slow Moving Inventory', L::"L1 Transaction", D::Inventory, P::Medium, S::Medium, 5.0, T::Premium);
        Seed('L1-025', 'Dead Stock', L::"L1 Transaction", D::Inventory, P::High, S::"Medium-High", 6.0, T::Premium);
        Seed('L1-026', 'Lot Tracking Risks', L::"L1 Transaction", D::Inventory, P::High, S::Critical, 9.0, T::Premium);
        // ---- L1 Manufacturing (Premium) ----
        Seed('L1-M001', 'Scrap Analysis', L::"L1 Transaction", D::Manufacturing, P::High, S::High, 7.0, T::Premium);
        Seed('L1-M002', 'BOM Deviations', L::"L1 Transaction", D::Manufacturing, P::High, S::High, 7.0, T::Premium);
        Seed('L1-M003', 'Production Variances', L::"L1 Transaction", D::Manufacturing, P::Medium, S::"Medium-High", 6.0, T::Premium);
        Seed('L1-M004', 'Routing Deviations', L::"L1 Transaction", D::Manufacturing, P::Medium, S::Medium, 5.0, T::Premium);
        Seed('L1-M005', 'Capacity Risks', L::"L1 Transaction", D::Manufacturing, P::High, S::High, 7.0, T::Premium);
        Seed('L1-M006', 'Cost Overruns', L::"L1 Transaction", D::Manufacturing, P::High, S::High, 7.0, T::Premium);
        // ---- L1 Projects (Premium) ----
        Seed('L1-P001', 'Budget Overruns', L::"L1 Transaction", D::Projects, P::High, S::High, 7.0, T::Premium);
        Seed('L1-P002', 'Resource Utilization Issues', L::"L1 Transaction", D::Projects, P::Medium, S::Medium, 5.0, T::Premium);
        Seed('L1-P003', 'Revenue Recognition Concerns', L::"L1 Transaction", D::Projects, P::High, S::High, 8.0, T::Premium);
        Seed('L1-P004', 'Timesheet Anomalies', L::"L1 Transaction", D::Projects, P::Medium, S::Medium, 5.0, T::Premium);
        // ---- L1 Fixed Assets (Premium) ----
        Seed('L1-FA01', 'Ghost Assets', L::"L1 Transaction", D::"Fixed Assets", P::High, S::High, 7.0, T::Premium);
        Seed('L1-FA02', 'Depreciation Exceptions', L::"L1 Transaction", D::"Fixed Assets", P::High, S::High, 7.0, T::Premium);
        Seed('L1-FA03', 'Capitalization Violations', L::"L1 Transaction", D::"Fixed Assets", P::High, S::High, 7.0, T::Premium);
        Seed('L1-FA04', 'Disposal Risks', L::"L1 Transaction", D::"Fixed Assets", P::Medium, S::"Medium-High", 6.0, T::Premium);
        // ---- L1 Master Data (Standard) ----
        Seed('L1-MD01', 'Duplicate Vendors', L::"L1 Transaction", D::"Master Data", P::High, S::High, 7.0, T::Standard);
        Seed('L1-MD02', 'Duplicate Customers', L::"L1 Transaction", D::"Master Data", P::High, S::High, 7.0, T::Standard);
        Seed('L1-MD03', 'Missing Data Governance', L::"L1 Transaction", D::"Master Data", P::Medium, S::Medium, 5.0, T::Standard);
        Seed('L1-MD04', 'Master Data Config Violations', L::"L1 Transaction", D::"Master Data", P::Critical, S::Critical, 8.0, T::Standard);
        // ---- L2 Process (Premium) ----
        Seed('L2-P2P-01', 'P2P: 3-Way Match Failures', L::"L2 Process", D::Purchasing, P::High, S::High, 7.0, T::Premium);
        Seed('L2-Q2C-01', 'Q2C: Order Fulfilment Delays', L::"L2 Process", D::Sales, P::High, S::High, 7.0, T::Premium);
        Seed('L2-R2R-01', 'R2R: Period-End Close Risk', L::"L2 Process", D::Finance, P::High, S::High, 7.0, T::Premium);
        Seed('L2-PTP-01', 'Plan-to-Produce: Plan Slippage', L::"L2 Process", D::Manufacturing, P::Medium, S::"Medium-High", 6.0, T::Premium);
        Seed('L2-IC-01', 'Intercompany: Unmatched Transactions', L::"L2 Process", D::Finance, P::High, S::High, 7.0, T::Premium);
        Seed('L2-PTC-01', 'Project-to-Cash: Unbilled Work', L::"L2 Process", D::Projects, P::High, S::High, 7.0, T::Premium);
        // ---- L3 Configuration (Premium) ----
        Seed('L3-001', 'Posting Setup Governance', L::"L3 Configuration", D::Finance, P::Critical, S::Critical, 9.0, T::Premium);
        Seed('L3-002', 'Approval Workflow Governance', L::"L3 Configuration", D::Finance, P::High, S::High, 8.0, T::Premium);
        Seed('L3-003', 'Segregation of Duties', L::"L3 Configuration", D::Finance, P::Critical, S::Critical, 8.0, T::Premium);
        Seed('L3-004', 'Number Series Integrity', L::"L3 Configuration", D::Finance, P::Medium, S::"Medium-High", 6.0, T::Premium);
        Seed('L3-005', 'Change Log Integrity', L::"L3 Configuration", D::"Master Data", P::High, S::High, 7.0, T::Premium);
        // ---- L5 Predictive (Enterprise; deterministic projections) ----
        Seed('L5-001', 'Cash Flow Risk Projection', L::"L5 Predictive", D::Finance, P::Critical, S::Critical, 9.0, T::Enterprise);
        Seed('L5-002', 'Customer Default Risk', L::"L5 Predictive", D::Sales, P::High, S::High, 8.0, T::Enterprise);
        Seed('L5-003', 'Inventory Shortage Projection', L::"L5 Predictive", D::Inventory, P::High, S::High, 7.0, T::Enterprise);
        Seed('L5-004', 'Margin Erosion Projection', L::"L5 Predictive", D::Sales, P::High, S::High, 7.0, T::Enterprise);
    end;

    /// <summary>Seeds framework mappings so the compliance dashboard shows which controls satisfy which requirement.</summary>
    procedure SeedComplianceMappings()
    var
        F: Enum "RIA Compliance Framework";
    begin
        Map(F::SOX, 'L1-001', 'SOX 404 - AP');
        Map(F::SOX, 'L1-003', 'SOX 404 - JE');
        Map(F::SOX, 'L1-004', 'SOX 404 - Cutoff');
        Map(F::SOX, 'L1-015', 'SOX 404 - Authorisation');
        Map(F::SOX, 'L3-001', 'SOX 404 - ITGC');
        Map(F::SOX, 'L3-003', 'SOX 404 - SoD');
        Map(F::SOX, 'L3-005', 'SOX 404 - ITGC');
        Map(F::"Internal Controls", 'L1-006', 'Credit Control');
        Map(F::"Internal Controls", 'L1-013', 'Vendor Master');
        Map(F::"Internal Controls", 'L1-010', 'Procurement');
        Map(F::"Internal Controls", 'L2-P2P-01', '3-Way Match');
        Map(F::IFRS, 'L1-005', 'IFRS 15 Revenue');
        Map(F::IFRS, 'L1-024', 'IAS 2 NRV');
        Map(F::IFRS, 'L1-025', 'IAS 2 NRV');
        Map(F::IFRS, 'L1-FA02', 'IAS 16 Depreciation');
        Map(F::"ISO 9001", 'L1-M001', 'Process Quality');
        Map(F::"ISO 9001", 'L2-Q2C-01', 'Delivery Performance');
        Map(F::GDPR, 'L1-MD03', 'Data Quality');
        Map(F::GDPR, 'L3-005', 'Audit Trail');
    end;

    local procedure Seed(ControlID: Code[20]; Name: Text[100]; Layer: Enum "RIA Layer"; Domain: Enum "RIA Domain"; Priority: Enum "RIA Control Priority"; Severity: Enum "RIA Severity"; Score: Decimal; Tier: Enum "RIA License Tier")
    var
        Control: Record "RIA Control Catalogue";
    begin
        if Control.Get(ControlID) then begin
            Control."Detection Available" := true;
            Control."Min License Tier" := Tier;
            Control.Modify();
            exit;
        end;
        Control.Init();
        Control."Control ID" := ControlID;
        Control.Name := Name;
        Control.Layer := Layer;
        Control.Domain := Domain;
        Control.Priority := Priority;
        Control."Default Severity" := Severity;
        Control."Default Risk Score" := Score;
        Control.Enabled := true;
        Control."Detection Available" := true;
        Control."Min License Tier" := Tier;
        Control.Insert();
    end;

    local procedure Map(Framework: Enum "RIA Compliance Framework"; ControlID: Code[20]; RequirementRef: Text[50])
    var
        Mapping: Record "RIA Compliance Mapping";
    begin
        if Mapping.Get(Framework, ControlID) then
            exit;
        Mapping.Init();
        Mapping.Framework := Framework;
        Mapping."Control ID" := ControlID;
        Mapping."Requirement Ref" := RequirementRef;
        Mapping.Insert();
    end;
}
