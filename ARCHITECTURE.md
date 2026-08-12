# Risk Intelligence Agent (RIA) — Solution Architecture & Build Report

**Publisher:** Cetas  **Target:** Microsoft Dynamics 365 Business Central 26.x (SaaS)
**App ID:** a3f1c8e2-7b94-4d61-9e02-1f7a6c5d8b40  **Object range:** 50100–50299

---

## 1. Requirement Understanding

**Executive summary.** RIA is a continuous audit and compliance intelligence agent embedded inside Business Central. Rather than running periodic, after-the-fact audits, it watches transactions, master data, and configuration changes as they happen, scores the risk of each finding, and routes prioritized, actionable alerts to a Risk Command Center. The product is organized as five intelligence layers (L1 Transaction, L2 Process, L3 Configuration, L4 External, L5 Predictive) and a catalogue of 44 L1 controls across eight domains.

**Business objectives.** Detect fraud and control failures in near real time; cut the cost and duration of internal/external audits by generating evidence automatically; give finance, procurement, and audit leaders a single screen that answers "what needs my attention and why"; remain upgrade-safe and AppSource-certifiable.

**Challenges.** Volume (millions of ledger entries), false-positive fatigue, multi-company/multi-country deployments, and the need to stay loosely coupled to standard BC so upgrades never break.

**Risks.** Over-alerting erodes trust; under-tuned thresholds miss real risk; heavy detection queries could affect transactional performance. These are mitigated by a configurable materiality floor, shadow mode for calibration, deduplication, per-control thresholds, and background (Job Queue) execution.

**Assumptions.** Change Log is enabled for the tables RIA monitors (required for L1-013 batch detection); the customer assigns a Microsoft-registered object range before AppSource submission; an Azure OpenAI resource is supplied if the AI Copilot is enabled.

---

## 2. Gap Analysis Matrix

| Requirement | Standard BC | Configuration | Customization | Integration | Recommendation |
|---|---|---|---|---|---|
| Capture who changed vendor bank details | Change Log | Enable logging on Vendor Bank Account | Event subscriber + batch reader | — | Use standard Change Log; RIA reads it (no custom logging) |
| Duplicate payment detection | Partial (vendor ledger) | — | Detection codeunit over Vendor Ledger Entry | — | Custom detection; no standard equivalent |
| Credit limit enforcement | Posting checks exist | Credit limit on customer | Continuous monitor for breaches | — | Extend with monitoring; keep standard posting checks |
| Alert routing / notifications | Notifications, My Notifications | Per-user severity routing | Notification Mgt codeunit | — | Standard Notification API + config table |
| Background detection | Job Queue | Recurring entries | Job Queue Mgt helper | — | Standard Job Queue; RIA provisions entries |
| Investigation workflow | — | — | Case tables/pages | — | Custom; no standard case object |
| Audit evidence pack | Report engine | — | Report 50100 + evidence table | — | Custom Word-layout report |
| External GRC / Power BI feed | API framework | — | API page | OData v4 | Standard API page |
| Natural-language risk Q&A | Copilot framework | AI endpoint config | Copilot Mgt codeunit | Azure OpenAI | Data-grounded stub now; AOAI-ready |

**Avoid:** re-implementing change tracking, posting validations, or number series — all reused from standard BC.

---

## 3. Final Product Architecture

**Workspaces (navigation):** Risk Command Center (Home) → Monitoring (Risk Alerts, Financial Controls, Procurement Risk, Revenue Assurance, Inventory Intelligence) → Risk Profiles (Customer, Vendor) → Investigations (Open Cases, Investigation Workspace, Audit Evidence) → Compliance (Control Catalogue, Compliance Monitoring, Remediation Tracker) → Intelligence (Risk Trends, Exposure Analytics, Fraud Analytics, Copilot) → Setup (Risk Configuration, Threshold Setup, Notification Setup, AI Configuration).

**Personas / security model:** RIA Administrator (full), RIA User / risk analyst (triage + cases, read-only setup), RIA Auditor (read + evidence export), RIA Read Only (executive/dashboard). Each is an assignable permission set.

**Modules:** detection engine + per-control routines; alert lifecycle service; risk scoring; case management; notification routing; SLA monitor; Copilot; install/seed; Job Queue provisioning.

---

## 4. UX Architecture (highlights)

Every KPI tile on the Role Center drills to a filtered list, which opens a card, which drills to the source BC record — no dead ends. The Risk Alerts list carries triage actions (Acknowledge, Start Review, Resolve, False Positive, Create Case, Open Source) and an Evidence FactBox showing the full audit trail. Severity drives conditional row styling (Unfavorable/Ambiguous/Favorable). The four domain centers reuse the alert model filtered by domain so users live in their business context. Headline cues surface the single most important number on sign-in.

---

## 5. Data Architecture

Core tables (50100–50109): Control Catalogue, Risk Alert (central transactional table, eight keys for triage/entity/dedup/SLA access paths), Investigation Case, Alert Evidence, Risk Profile, Remediation Action, Risk Setup (singleton), Threshold Setup, Notification Setup, Cue. Relationships are by Control ID, Entity Type+No., Case No., and Alert Entry No. FlowFields provide open-alert counts and exposure sums without denormalization. Data classification: CustomerContent for transactional data, SystemMetadata for catalogue/cues.

---

## 6. Technical Architecture

Event-driven and loosely coupled: a real-time `OnAfterModify` subscriber on Vendor Bank Account gives sub-5-minute BEC-fraud detection, while the Job Queue runs the batch Detection Engine on an interval. The engine dispatches to per-control codeunits and exposes `OnRunCustomControl` so partners can register controls without modifying RIA. APIs (OData v4) and queries feed Power BI / external GRC. No standard objects are modified — only extended via events and reads.

---

## 7. Performance Architecture

SetLoadFields on every detection scan; keyed filtered reads instead of nested loops; FlowFields for counts/sums; dedup hashing to prevent alert storms; materiality floor and per-control thresholds to suppress noise; background sessions via Job Queue; APIs are read-only with ODataKeyFields on SystemId. The Risk Alert table is indexed for each access pattern the UI and engine use (status, control, entity, dedup, assignment, domain).

---

## 8. Security Architecture

Four assignable permission sets enforce least privilege. Setup tables are read-only for analysts; evidence export is available to auditors without triage rights; the Read Only set powers executive dashboards. The real-time subscriber is `Access = Internal`. Segregation of duties is itself a seeded control (L3-003).

---

## 9–12. Source, Testing, Deployment, Validation

All AL source is in `/src` (see Deployment Structure below). Tests ship as a **separate** app (`ria-app-tests`) depending on the Microsoft test framework, as required for AppSource (test libraries must never be a dependency of the production app). Build validation results are in `BUILD_NOTES.md`.
