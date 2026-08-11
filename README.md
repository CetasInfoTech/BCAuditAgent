# Risk Intelligence Agent (RIA) for Microsoft Dynamics 365 Business Central

Continuous audit & compliance intelligence agent by Cetas Technology.

## Repos in this package
- `ria-app/` — the production app (compile and ship this).
- `ria-app-tests/` — automated tests (separate app; depends on the Microsoft test framework).

## Quick start
1. Open `ria-app/` in VS Code with the **AL Language** extension.
2. `AL: Download Symbols` against a BC 26 sandbox.
3. `Ctrl+Shift+B` to build; press F5 to publish — the **Risk Intelligence Agent** Role Center opens.
4. Open **Risk Configuration**, then **Schedule Background Jobs** to provision detection + SLA Job Queue entries.
5. Use **Run Detection Now** on the Role Center to generate alerts immediately.

See `ria-app/ARCHITECTURE.md` for the full design and `ria-app/BUILD_NOTES.md` for validation status and the AppSource checklist.
