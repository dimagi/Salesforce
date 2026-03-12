# SPEC: T&M Budget Tool — Salesforce Implementation

> **Status:** Ready for implementation
> **Sandbox:** `dimagi--tmtracker.sandbox.lightning.force.com`
> **Audience:** Claude Code — use this file as the primary implementation reference

---

## 1. What We Are Building

A full-page Visualforce budget editor that replaces the current Screen Flow + LWC implementation. Finance users navigate to a Contract record, click "Edit T&M Budget," and land on a spreadsheet-style page where they can:

- View and edit a month-by-month budget across an obligation period
- Add/remove employees, contractors, direct costs, and subcontracts
- Lock months as "Actuals" (preventing further edits)
- See live-calculated totals for fringe, overhead, G&A, and grand total
- Export the grid to CSV

The current implementation has critical reliability bugs (intermittent save failures, locking not persisting, G&A calculation errors) caused by too much logic in Screen Flows. The new implementation moves all logic to Apex.

---

## 2. Files to Create

```
src/
├── classes/
│   ├── BudgetDTO.cls                      # Data transfer objects
│   ├── BudgetDTO.cls-meta.xml
│   ├── BudgetCalculationService.cls        # All formula logic
│   ├── BudgetCalculationService.cls-meta.xml
│   ├── BudgetCalculationServiceTest.cls    # Unit tests
│   ├── BudgetCalculationServiceTest.cls-meta.xml
│   ├── BudgetController.cls               # VF @RemoteAction controller
│   ├── BudgetController.cls-meta.xml
│   ├── BudgetControllerTest.cls
│   ├── BudgetControllerTest.cls-meta.xml
│   ├── BudgetLineItemTriggerHandler.cls    # Lock enforcement
│   ├── BudgetLineItemTriggerHandler.cls-meta.xml
│   ├── BudgetLineItemTriggerHandlerTest.cls
│   └── BudgetLineItemTriggerHandlerTest.cls-meta.xml
├── triggers/
│   ├── BudgetLineItemTrigger.trigger
│   └── BudgetLineItemTrigger.trigger-meta.xml
└── pages/
    ├── TmBudgetEditor.page                # Full-page VF + AG Grid
    └── TmBudgetEditor.page-meta.xml
```

NOTE: File paths use `src/` (MDAPI format), not `force-app/main/default/`.

---

## 3. Data Model

**Field names confirmed against QASandbox metadata pull.**

### Budget__c
Master-detail child of `DContract__c`. One budget per obligation period.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Contract | `Contract__c` | MasterDetail(DContract__c) | |
| Budget Period Start | `Budget_Period_Start_Date__c` | Date | Defines month columns |
| Budget Period End | `Budget_Period_End_date__c` | Date | Note lowercase 'd' |
| Fringe Rate | `Fringe_Benefit_Rate__c` | Percent | Default from CMT |
| Overhead Rate | `Overhead_Rate__c` | Percent | |
| G&A Rate | `G_A_Rate__c` | Percent | |
| Custom Indirect Rate | `Custom_Indirect_Cost_Rate__c` | Percent | Used when NICRA=false |
| Indirect Cost Type | `Indirect_Cost_Type__c` | Picklist | Controls NICRA vs custom — confirm picklist values |
| Fee | `Fee_Percentage__c` | Percent | Fee is stored as a percentage, not flat amount |
| Budgeted Grand Total | `Budgeted_Grand_Total__c` | Currency | Read-only rollup |

### Budget_Line_Item__c
Master-detail child of `Budget__c`. New implementation creates **one record per person/category per month** using `Month_Key__c`.

| Field | API Name | Type | Notes |
|---|---|---|---|
| Budget | `Budget__c` | MasterDetail(Budget__c) | |
| Employee | `Employee__c` | Lookup(SFDC_Employee__c) | For Employee/Contractor rows |
| Agreement | `Agreement__c` | Lookup(Agreement__c) | For Subcontract rows |
| Cost Category | `Cost_Category__c` | Picklist | **'Employee', 'Internal Contractor', 'Subcontracts'**, + direct cost categories |
| Month Key | `Month_Key__c` | Text(10) | **NEW FIELD TO ADD** — format "YYYY_MM". Old data uses date ranges; new editor uses this |
| Start Date | `Budget_Line_Item_Start_Date__c` | Date | Existing date-range field (old data) |
| End Date | `Budget_Line_Item_EndDate__c` | Date | Existing date-range field (old data) |
| Projected Units | `Projected_Units__c` | Number | Days budgeted |
| Projected Daily Rate | `Projected_Daily_Rate__c` | Currency | Rate for projected |
| Projected Total | `Projected_Total_Salary__c` | Currency | Projected_Units × Projected_Daily_Rate |
| Actual Units | `Actual_Units__c` | Number | Days actuals |
| Actual Daily Rate | `Actual_Daily_Rate__c` | Currency | |
| Actual Total | `Actual_Total_Salary__c` | Currency | |
| Lock Status | `Actuals_Locked__c` | Picklist | Lock field — confirm picklist values (e.g. 'Locked') |
| G&A Amount | `Amount_to_Include_in_G_A__c` | Currency | Calculated |
| Fringe Amount | `Fringe_Amount__c` | Currency | Calculated |
| Overhead Amount | `Overhead_Amount__c` | Currency | Calculated |
| G&A Amount | `G_A_Amount__c` | Currency | Calculated |

> **Month_Key__c is a new field** that needs to be deployed to tmtracker as part of this build. Format: "2024_01". The new editor creates one record per person per month using this key. Existing date-range records from the old implementation are left untouched.

### DContract__c (read-only fields used)
- `Contract_Start_Date__c` — Date
- `Contract_End_Date__c` — Date
- `Total_Amount_of_Contract__c` — Currency

### SFDC_Employee__c (read-only fields used)
- `Loaded_Daily_Rate__c` — Currency (use this for default rate)
- `Employee_Type__c` — Picklist (confirm values — expected: Employee, PEO, Internal Contractor)
- `Employee_Status__c` — Picklist (active/inactive — confirm active value)

### TM_Budget_Defaults__mdt (Custom Metadata — confirm or create)
- `Default_Fringe_Rate__c` — Percent
- `Default_Overhead_Rate__c` — Percent
- `Default_GA_Rate__c` — Percent
- Record DeveloperName: `Standard`

---

## 4. Calculation Rules

These are the exact formulas. **Never deviate from these.**

### Fringe
```
Fringe = Sum(Employee + PEO salary for month) × fringeRate
```
Internal Contractors are EXCLUDED from fringe.

### Overhead
```
Overhead = (Employee+PEO salary + Fringe) × overheadRate
```

### G&A — The Complex One
```
G&A Base = Salary(all) + Fringe + DirectCosts(excl subs) + Overhead
         - Sum(all subcontract amounts for month)
         + Sum(min($25k cap remaining per sub, subcontract amount for month))

G&A = max(0, G&A Base) × gaRate
```

**$25k cap rule:** For each subcontractor, G&A can only be charged on the first $25,000 billed across the **entire contract lifetime** (not per year). Track cumulative billing per subcontractor in chronological month order.

Example:
- Jan: Sub A bills $10k → $10k eligible (cap used: $10k, $15k remaining)
- Feb: Sub A bills $20k → $15k eligible (cap used: $25k, $0 remaining)
- Mar+: Sub A bills anything → $0 eligible

### Fee
```
Fee = feeAmount (flat dollar, set at budget level, defaults 0)
```

### Grand Total
```
Grand Total = Salary + Fringe + DirectCosts(incl subs) + Overhead + G&A + Fee
```

### Amount Remaining
```
Amount Remaining = Grand Total Budget - Total Billed to Date
Total Billed to Date = Sum of Grand Total for all locked months
```

---

## 5. BudgetCalculationService.cls

```apex
// Main calculation — called after every save and for client preview
public static BudgetDTO.BudgetTotals calculate(
    BudgetDTO.SavePayload payload,
    List<BudgetDTO.MonthColumn> months
)

// Build month columns from obligation period
public static List<BudgetDTO.MonthColumn> buildMonthColumns(
    Date startDate,
    Date fundingEndDate,
    Set<String> lockedKeys
)
```

**Requirements:**
- Sort months chronologically before calculating G&A
- Store sub cap state in `Map<String, Decimal>` keyed by Agreement Id
- All currency rounding: `setScale(2, RoundingMode.HALF_UP)`
- Never throw exceptions — return 0 for null/missing values

---

## 6. BudgetController.cls

```apex
@RemoteAction
public static String loadBudget(String contractId, String budgetId)

@RemoteAction
public static String saveBudget(String payloadJson, String contractId, String monthsJson)

@RemoteAction
public static String addEmployees(String budgetId, List<String> employeeIds)
```

**Save requirements:**
- Open `Savepoint` at start; `rollback` on any exception
- Validate no locked cells being modified before DML
- All Budget_Line_Item__c upserts in a single `upsert` statement
- Delete removed line items in one `delete` statement (never delete locked)
- Return updated totals and month columns after save

---

## 7. BudgetLineItemTriggerHandler.cls

**`before update`:** Block changes to Units, Rate, Amount on locked records. Skip if user has `Bypass_Budget_Lock` custom permission.

**`before insert`:** Auto-lock new line items added to months already locked on the parent budget.

**`before delete`:** Block deletion of locked records. Skip if `Bypass_Budget_Lock`.

---

## 8. TmBudgetEditor.page (Visualforce + AG Grid)

**Page parameters:** `contractId` (required), `budgetId` (optional)

**Access:** "Edit T&M Budget" button on DContract__c → `/apex/TmBudgetEditor?contractId={!DContract__c.Id}`

**Layout:**
```
┌─────────────────────────────────────────────────────┐
│ TOPBAR: [Contract name] ... [Save] [← Back]         │
├─────────────────────────────────────────────────────┤
│ SUMMARY: Grand Total | Billed | Remaining |         │
│          Salaries | Fringe | Overhead | G&A         │
├─────────────────────────────────────────────────────┤
│ TOOLBAR: [+Employee] [+Contractor] [+Sub] [Lock/Unlock] [Export CSV] │
├─────────────────────────────────────────────────────┤
│ RATES BAR: Fringe% | Overhead% | G&A% | Fee$ | Notes│
├─────────────────────────────────────────────────────┤
│                                                     │
│  AG GRID (fills remaining height)                   │
│  Pinned left: Label | Budget Total | Billed | Remain│
│  Scrollable: [Jan 2024 🔒][Feb 2024]...             │
│              Units | Rate | Total per month         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Grid rows:** Employees section → Contractors → Direct Costs → Subcontracts → Indirect Rates → Grand Total (pinned bottom)

**AG Grid library:**
```html
<script src="https://cdn.jsdelivr.net/npm/ag-grid-community@31.3.2/dist/ag-grid-community.min.js"/>
```

---

## 9. Test Scenarios

### BudgetCalculationServiceTest
- Standard budget, no subs
- Sub under $25k cap
- Sub over $25k cap
- Two subs both hitting cap across multiple months
- Internal contractors excluded from fringe
- Custom rates (NICRA = false)
- Zero G&A rate
- Fee added to grand total

### BudgetControllerTest
- loadBudget with existing budgetId
- loadBudget with blank budgetId (returns defaults)
- saveBudget creates all records atomically
- saveBudget rolls back on failure
- saveBudget does not overwrite locked items
- addEmployees returns correct rows

### BudgetLineItemTriggerHandlerTest
- Editing locked item throws error
- Editing unlocked item succeeds
- Deleting locked item throws error
- New item in locked month inherits lock
- Bypass_Budget_Lock permission allows edit

---

## 10. Known Bugs in Current Implementation (Do Not Repeat)

1. **Intermittent save failures** — multi-step Flow DML. Fix: single atomic Apex save.
2. **Locking not persisting** — Flow variable scoping. Fix: Apex trigger.
3. **G&A double-counting subcontracts** — Fix: single source of truth in BudgetCalculationService.
4. **Budget Summary not showing locked labor** — Fix: calculate all totals from line items directly.
5. **Employees not created on budget setup** — subflow failure not rolling back. Fix: single upsert.
6. **Fringe calculated on contractors** — Fix: explicit check in calculation service.

---

## 11. Implementation Order

1. Pull metadata from QASandbox → confirm/update all API names in this file ✓ (complete)
2. `BudgetDTO.cls` — no dependencies
3. `BudgetCalculationService.cls` + tests — pass all tests before moving on
4. `BudgetLineItemTriggerHandler.cls` + trigger + tests
5. `BudgetController.cls` + tests
6. `TmBudgetEditor.page` — test in browser against sandbox
7. Deploy to tmtracker; run scenario tests
