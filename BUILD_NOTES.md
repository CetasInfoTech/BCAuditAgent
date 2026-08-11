# Build Notes, Validation Status & Honest Scope

## What this package is
A **compilable, AppSource-shaped foundation** for the Risk Intelligence Agent: the complete data model, the full navigation as working pages, the Role Center, a data-driven Control Catalogue seeded with all 44 L1 controls (plus representative L2–L5), a working detection vertical slice with real AL logic, notifications, FactBoxes, queries, an OData API, four permission sets, an install/seed codeunit, Job Queue provisioning, an audit-evidence report, and a separate test app.

## What is fully implemented (no placeholders)
- **Data model:** 10 tables, 8 enums, all keys/FlowFields/field groups.
- **Navigation:** Role Center + 29 pages covering every node in the supplied tree.
- **Detection with real logic:** L1-001 Duplicate Payments, L1-013 Vendor Bank Account Change (batch + real-time subscriber), L1-006 Credit Limit Violations, L1-021 Negative Inventory.
- **Lifecycle:** raise → dedup → acknowledge → review → resolve / false-positive / escalate, with audit trail and SLA monitor.
- **Scoring:** amount/frequency/recency/context weighting, 0–10 normalization, severity banding.
- **Catalogue:** all 44 L1 controls seeded on install; `Detection Available` flags the four with live routines.
- **Security:** RIA Admin/User/Auditor/ReadOnly permission sets covering all objects.
- **Automation:** Job Queue entries for the engine and SLA monitor.
- **Reporting/integration:** Audit Evidence Word report, two analytical queries, OData v4 API page.
- **Tests:** scoring, dedup, lifecycle, and negative-inventory detection in a separate test app.

## What is intentionally framework-only (and clearly marked)
- **40 of 44 L1 controls** are seeded as catalogue metadata but do not yet have a bespoke detection routine; the engine's `OnRunCustomControl` event and the `RunControl` dispatcher are the extension points to add them.
- **L2–L5 layers and the 6 AI Copilots** are represented (catalogue entries + a data-grounded Copilot stub that is AOAI-ready) but not fully built out.
- **Country compliance packs** are out of scope for this foundation.
Reaching a literal zero-gap implementation of every control, copilot, and country pack is a multi-phase program; this foundation is structured so each addition is incremental and upgrade-safe.

## Validation performed in this environment
- Object-ID uniqueness verified per namespace across both apps (no duplicates).
- Brace/structure balance verified on every `.al` file.
- All internal `RIA …` object references resolve to a declaration.
- AL grammar checks: `SourceTableView` sorting/order/where ordering corrected; enum relational comparison uses `.AsInteger()`; no blank enum identifiers; no render-time record writes; no `TODO`/placeholder/pseudocode tokens remain.

## Validation NOT possible here (must be done by you)
- **The AL compiler was not run** — no `alc`/symbols in this sandbox. Compile in VS Code (AL Language extension) against a BC 26 symbol package. Treat the first compile as the authoritative check.
- **AppSourceCop / UICop / CodeCop** run only inside the AL toolchain (rulesets are pre-wired in `.vscode/settings.json`).

## Required before AppSource submission
1. Replace the 50100–50299 range with your **Microsoft-registered object ID range** (Partner Center) and update `app.json` + all object IDs.
2. Supply the real **`res/ria_logo.png`** (placeholder included).
3. Confirm the **No. Series**, **Library Assert/Tests-TestLibraries/Any** dependency versions match your target BC build.
4. Enable **Change Log** on monitored tables (Vendor Bank Account fields) for L1-013 batch detection.
5. Generate translations via the **TranslationFile** feature on first build (skeleton `.xlf` included).
6. Open the report `.docx` in Word with the BC layout add-in to bind fields (a valid starter layout is included).
