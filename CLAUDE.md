# Salesforce Project — Dimagi

## Project Overview
Salesforce org for Dimagi. Uses the **MDAPI format** (not SFDX DX format) — all source lives under `src/`.

Main branch: `develop`. Feature branches follow the pattern `SAL###-Description`.

---

## Key Architecture

### Visualforce + Apex (primary pattern for internal tools)
- Pages live in `src/pages/`, controllers in `src/classes/`
- The main internal tools page is `src/pages/DimagiSFTools.page`, controlled by `DimagiToolsController.cls`
- Visualforce components live in `src/components/` with `ApexComponent` controllers

### Controller patterns
- **Use `@RemoteAction`** for Visualforce pages and components. Example: `TravelComponentController.cls`, `BudgetController.cls`
- **Do NOT use `@AuraEnabled` / LWC** for these pages — Lightning Out / LWC is not compatible with this org's Salesforce Sites context
- **Do NOT use Screen Flows** for data logic — all logic must be in Apex

### Travel Portal
- UI: `src/components/TravelComponent.component` (Visualforce, jQuery UI dialogs)
- Controller: `src/classes/TravelComponentController.cls` (@RemoteAction)
- Embedded in `DimagiSFTools.page` at line ~215
- Data object: `Trip__c`

---

## T&M Budget Tool (SAL-495) — Active Development

### Architecture
- UI: `src/pages/TmBudgetEditor.page` (full-page Visualforce + AG Grid Community)
- Controller: `src/classes/BudgetController.cls` (@RemoteAction)
- Access: "Edit T&M Budget" button on DContract__c → `/apex/TmBudgetEditor?contractId={!Id}`
- Users: Finance team with full SF accounts (~5-10 people)
- NOT embedded in DimagiSFTools — standalone page within Lightning app

### Key classes
- `BudgetDTO.cls` — all request/response data shapes
- `BudgetCalculationService.cls` — G&A, fringe, overhead, $25k sub cap logic
- `BudgetController.cls` — @RemoteAction load/save
- `BudgetLineItemTriggerHandler.cls` — lock enforcement
- `BudgetLineItemTrigger.trigger` — thin trigger, all logic in handler

### Object API Names
**UPDATE THIS SECTION after pulling metadata from QASandbox:**
- Budget object: `Budget__c` — confirm lookup field to DContract__c
- Budget Line Item: `Budget_Line_Item__c` — confirm Month_Key__c vs date-range model
- Contract: `DContract__c` — confirm start/end date field names
- Employee: `SFDC_Employee__c` — confirm rate field (Loaded vs Unloaded) and type picklist values
- Agreement/Subcontract: `Agreement__c` — confirm

### Business Rules (never violate)
1. Fringe applies to Employees + PEO only — never to Internal Contractors
2. G&A on subcontractors: only first $25,000 per sub per contract lifetime, tracked cumulatively in month order
3. Once a month is locked (Actuals), no field on any line item in that month can be edited — enforced by trigger
4. New line items added to a budget where some months are locked must inherit locked state
5. Rates are non-dynamic: pulling a new employee's rate does not retroactively change locked periods

### Do Not
- Do not put formula logic in Screen Flows or LWC JS
- Do not use `lightning-datatable` for the budget grid (use AG Grid in VF page)
- Do not use `@AuraEnabled` for the budget editor (use `@RemoteAction`)
- Do not modify locked line items without checking `Bypass_Budget_Lock` custom permission

---

## Deployment
- **Metadata format**: MDAPI (`src/package.xml`). `ApexClass` and `ApexComponent` use `<members>*</members>` wildcards.
- Sandbox may be behind the repo — be careful about committing metadata refreshes from an outdated sandbox.
- Large numbers of modified layout/object/workflow files in git status usually indicate an org metadata refresh — investigate before committing.

## What NOT to commit
- `.sfdx/`, `.vscode/`, `.claude/`, `src/main/` — tooling directories (in .gitignore)
- Binary static resources (`*.bin`, `*.gif`, `*.zip` in `src/staticresources/`) — in .gitignore
- `src/customMetadata/` — in .gitignore
- Unreviewed metadata refreshes from an outdated sandbox
