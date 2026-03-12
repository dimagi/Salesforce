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

### Object API Names (confirmed from QASandbox)
- Budget: `Budget__c` — MasterDetail to `DContract__c` via `Contract__c`
- Budget period: `Budget_Period_Start_Date__c` / `Budget_Period_End_date__c` (lowercase 'd')
- Fringe rate: `Fringe_Benefit_Rate__c` (not Fringe_Rate__c)
- G&A rate: `G_A_Rate__c` | Overhead: `Overhead_Rate__c` | Custom: `Custom_Indirect_Cost_Rate__c`
- Fee: `Fee_Percentage__c` (Percent, not flat Currency)
- NICRA toggle: `Indirect_Cost_Type__c` (Picklist)
- Budget Line Item: `Budget_Line_Item__c` — MasterDetail to `Budget__c`
- Line item type: `Cost_Category__c` (Picklist: 'Employee', 'Internal Contractor', 'Subcontracts', + direct cost categories)
- Lock field: `Actuals_Locked__c` (Picklist, not Checkbox)
- Per-month key: `Month_Key__c` — **NEW FIELD TO ADD** (Text 10, format "YYYY_MM")
- Projected fields: `Projected_Units__c`, `Projected_Daily_Rate__c`, `Projected_Total_Salary__c`
- Actual fields: `Actual_Units__c`, `Actual_Daily_Rate__c`, `Actual_Total_Salary__c`
- Contract dates: `Contract_Start_Date__c` / `Contract_End_Date__c` on DContract__c
- Contract total: `Total_Amount_of_Contract__c` on DContract__c
- Employee rate: `Loaded_Daily_Rate__c` on SFDC_Employee__c
- Employee type: `Employee_Type__c` | Active status: `Employee_Status__c`
- Agreement/Subcontract: `Agreement__c`

### Confirmed Picklist Values
- `Actuals_Locked__c`: **'Yes, actuals final'** = locked | 'No, still projected' | 'Not Set'
- `Indirect_Cost_Type__c`: **'Standard'** = NICRA rates | **'Custom'** = use `Custom_Indirect_Cost_Rate__c` only
- `Employee_Type__c`: 'Employee', 'PEO', 'Internal Contractor'

### Business Rules (never violate)
1. Fringe applies to Employees + PEO only — never to Internal Contractors (`Cost_Category__c != 'Internal Contractor'`)
2. G&A on subcontractors: only first $25,000 per sub per contract lifetime, tracked cumulatively in chronological month order. Each Agreement__c Id has its own independent cap.
3. Subcontract rows identified by `Cost_Category__c = 'Subcontracts'` + non-null `Agreement__c`. Cap keyed by `Agreement__c` Id.
4. Lock behavior: (1) AG Grid `editable: false` on locked month columns in UI; (2) trigger blocks any DML on locked records; (3) locked month totals ARE included in "Billed to Date" summary calculation
5. Once a month is locked (`Actuals_Locked__c = 'Yes, actuals final'`), no field on any line item in that month can be edited — enforced by trigger, bypass with `Bypass_Budget_Lock` custom permission
6. New line items added to a budget where some months are locked must inherit locked state
7. Rates are non-dynamic: pulling a new employee's rate does not retroactively change locked periods
8. Bulk upload is out of scope for this build — `saveBudget` accepts full payload to enable future CSV import without controller changes

### Sandbox Strategy
- Building in **tmtracker** Dev sandbox (alias: `tmtracker`). Created from Production — does NOT have Budget__c or Budget_Line_Item__c objects. These must be deployed first.
- QASandbox (alias: `qasandbox`) has the existing Flow + LWC implementation — do not deploy new code there.
- **Never overwrite existing files** — only create new files. Do not touch `BudgetViewController.cls`, `BudgetSummaryComponentClass.cls`, existing flows, or existing LWC components.
- The new `BudgetLineItemTrigger` must include an early-exit guard: `if (record.Month_Key__c == null) continue;` so it only affects records created by the new editor, leaving old records untouched.
- Always deploy using explicit `--metadata` or `--source-dir` flags targeting only new files. Never deploy `--source-dir src/`.

### Do Not
- Do not put formula logic in Screen Flows or LWC JS
- Do not use `lightning-datatable` for the budget grid (use AG Grid in VF page)
- Do not use `@AuraEnabled` for the budget editor (use `@RemoteAction`)
- Do not modify locked line items without checking `Bypass_Budget_Lock` custom permission
- Do not modify or overwrite any existing Apex classes, flows, or LWC components

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
