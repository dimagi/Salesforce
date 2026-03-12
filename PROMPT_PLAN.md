# PROMPT_PLAN.md — T&M Budget Tool Implementation

> **How to use this file with Claude Code:**
> Work through each prompt in order. Mark each step `[x]` when complete and committed.
> Start a fresh Claude Code session for each major section.
>
> **Before starting Section 1:** Complete the metadata pull and update SPEC.md field names.

---

## Section 1: Foundation

- [ ] **Step 1.1 — BudgetDTO**
  ```
  Read SPEC.md section 3 (Data Model).
  Create src/classes/BudgetDTO.cls and its meta.xml.
  All inner classes are pure data structures — no logic.
  Deploy and confirm it compiles before proceeding.
  ```

- [ ] **Step 1.2 — BudgetCalculationService + Tests**
  ```
  Read SPEC.md sections 4 and 5.
  Create BudgetCalculationService.cls implementing calculate() and buildMonthColumns().
  Critical rules:
  - G&A subcontractor $25k cap tracked cumulatively in chronological month order
  - Fringe excludes InternalContractor employee type
  - All currency: setScale(2, RoundingMode.HALF_UP)
  Create BudgetCalculationServiceTest.cls covering all 8 scenarios in SPEC.md section 9.
  Run all tests. Do not move on until all pass.
  ```

- [ ] **Step 1.3 — Trigger + Handler**
  ```
  Read SPEC.md section 7.
  Create BudgetLineItemTriggerHandler.cls and BudgetLineItemTrigger.trigger.
  Before insert: auto-lock new line items added to already-locked months.
  Create BudgetLineItemTriggerHandlerTest.cls covering all 5 scenarios in SPEC.md section 9.
  Run all tests. Do not move on until all pass.
  Commit: git commit -m "SAL-495 BudgetCalculationService, trigger, and tests"
  ```

---

## Section 2: Controller

- [ ] **Step 2.1 — BudgetController skeleton + loadBudget()**
  ```
  Read SPEC.md section 6. Read BudgetDTO.cls.
  Create BudgetController.cls with the three @RemoteAction method signatures.
  Implement loadBudget() fully:
  1. Query DContract__c for contract info
  2. Query or return a default Budget__c (do not insert yet if new)
  3. Build month columns using BudgetCalculationService.buildMonthColumns()
  4. Query and map all Budget_Line_Item__c records
  5. Load available employees (excluding those already on budget)
  6. Call BudgetCalculationService.calculate() and return totals
  Return errors as ResponseWrapper(false, e.getMessage(), null).
  Deploy and confirm it compiles.
  ```

- [ ] **Step 2.2 — BudgetController saveBudget()**
  ```
  Implement saveBudget() in BudgetController.cls. Requirements from SPEC.md section 6:
  - Open Database.setSavepoint() at top
  - Validate locked line items not being modified (throw if violated)
  - Single upsert for all Budget_Line_Item__c records
  - Single delete for removed items (never delete locked)
  - Apply lock/unlock changes
  - Recalculate and return updated totals
  - Rollback savepoint on ANY exception
  Deploy and confirm it compiles.
  ```

- [ ] **Step 2.3 — Controller tests**
  ```
  Create BudgetControllerTest.cls covering all 6 scenarios in SPEC.md section 9.
  Use @TestSetup for shared test data.
  Include a test that causes a save failure and verifies full rollback.
  Run all tests. Target 90%+ coverage on BudgetController.
  Commit: git commit -m "SAL-495 BudgetController with @RemoteAction load/save"
  ```

---

## Section 3: Visualforce UI

- [ ] **Step 3.1 — Page shell and layout**
  ```
  Read SPEC.md section 8.
  Create src/pages/TmBudgetEditor.page as a full-viewport Visualforce page.
  Include AG Grid Community CDN script and stylesheet.
  Build topbar, summary strip, toolbar, rates bar, and status bar as static HTML.
  Grid div fills all remaining height.
  Deploy and open: sf org open --path /apex/TmBudgetEditor?contractId=TEST --target-org tmtracker
  Verify layout renders before adding data.
  ```

- [ ] **Step 3.2 — Grid initialization and data load**
  ```
  Add JavaScript to TmBudgetEditor.page:
  1. On load, call BudgetController.loadBudget() via Visualforce.remoting
  2. Build AG Grid column definitions — pinned left columns + dynamic month columns
     Each month = 3 sub-columns (Units, Rate, Total) with correct editable flags
     Locked months: gray header, editable=false
  3. Build row data — section headers, employee rows, calc rows, grand total pinned bottom
  4. Initialize grid with agGrid.createGrid()
  5. Populate summary strip and rates bar
  Deploy and test with a real contractId from tmtracker.
  ```

- [ ] **Step 3.3 — Inline editing and client-side recalc**
  ```
  Add onCellValueChanged handler:
  - Personnel rows: recompute Total = Units × Rate immediately
  - Direct cost rows: update amount directly
  Client-side recalculate function mirrors BudgetCalculationService formulas.
  Runs after every edit, updates summary strip and calc rows.
  Dirty state flag — warn on navigation away.
  ```

- [ ] **Step 3.4 — Modals and save**
  ```
  1. Employee picker modal — search, checkboxes, Add/Cancel
     Calls BudgetController.addEmployees() on confirm
  2. Save button: serialize grid state → call saveBudget() → show result
  3. Lock/Unlock: update month headers, rebuild columns
  4. Export CSV: grid.exportDataAsCsv()
  5. Back button: warn if dirty, navigate to contract record
  Deploy and run end-to-end test.
  Commit: git commit -m "SAL-495 TmBudgetEditor VF page with AG Grid"
  ```

---

## Section 4: Polish + Deploy

- [ ] **Step 4.1 — Custom Metadata**
  ```
  Confirm TM_Budget_Defaults__mdt exists or create it.
  Verify BudgetController.loadBudget() returns correct default rates.
  ```

- [ ] **Step 4.2 — Permissions and button**
  ```
  1. Verify Bypass_Budget_Lock custom permission exists (create if not)
  2. Add TmBudgetEditor VF page to Finance Administrator profile
  3. Create "Edit T&M Budget" button on DContract__c → /apex/TmBudgetEditor?contractId={!Id}
  4. Add button to DContract__c page layout
  ```

- [ ] **Step 4.3 — Scenario testing**
  ```
  Test against tmtracker scenario contracts:
  1. Standard Budget No Sub and No Fee
  2. Standard Budget w/ Sub and No Fee
  3. Standard Budget w/ Sub and w/ Fee
  4. Non Standard Indirects No Sub
  5. Non Standard Indirects w/ Sub
  6. No Indirects No Sub
  7. No Indirects w/ Sub
  ```

- [ ] **Step 4.4 — Final coverage check**
  ```
  sf apex run test --class-names BudgetCalculationServiceTest,BudgetControllerTest,BudgetLineItemTriggerHandlerTest --target-org tmtracker
  All classes must be ≥85% coverage.
  Final commit: git commit -m "SAL-495 T&M Budget Tool — complete implementation"
  ```
