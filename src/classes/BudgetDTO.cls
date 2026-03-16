/**
 * BudgetDTO — all request/response data shapes for the T&M Budget Editor.
 * No logic here — pure data containers passed between BudgetController and the VF page.
 */
public class BudgetDTO {

    // ─── Inbound (JS → Apex) ──────────────────────────────────────────────────

    /**
     * Full payload sent by saveBudget(). Designed to accept a complete grid state
     * so that a future bulk-upload path can call the same endpoint.
     */
    public class SavePayload {
        public String budgetId;       // existing Budget__c Id, null if creating new
        public String contractId;     // DContract__c Id — required
        public BudgetRates rates;     // indirect rates and dates
        public List<BudgetRow> rows;  // all line item rows
    }

    /**
     * Indirect cost rates and budget period — mirrors Budget__c header fields.
     */
    public class BudgetRates {
        public Date   budgetStart;        // Budget_Period_Start_Date__c
        public Date   budgetEnd;          // Budget_Period_End_date__c  (lowercase 'd')
        public Decimal fringeRate;        // Fringe_Benefit_Rate__c (0–100, percent)
        public Decimal overheadRate;      // Overhead_Rate__c
        public Decimal gaRate;            // G_A_Rate__c
        public Decimal customRate;        // Custom_Indirect_Cost_Rate__c
        public String  indirectCostType;  // Indirect_Cost_Type__c: 'Standard' | 'Custom'
        public Decimal feePercentage;     // Fee_Percentage__c
    }

    /**
     * One row in the budget grid — one person/category per month.
     */
    public class BudgetRow {
        public String  lineItemId;       // Budget_Line_Item__c Id (null for new rows)
        public String  employeeId;       // Employee__c lookup Id
        public String  agreementId;      // Agreement__c lookup Id (subcontracts only)
        public String  costCategory;     // Cost_Category__c picklist value
        public String  monthKey;         // Month_Key__c "YYYY_MM"
        public String  lockedStatus;     // Actuals_Locked__c picklist value
        public Decimal projectedUnits;   // Projected_Units__c
        public Decimal projectedRate;    // Projected_Daily_Rate__c  (formula, read-only)
        public Decimal projectedTotal;   // Projected_Total_Salary__c (formula, read-only)
        public Decimal actualUnits;      // Actual_Units__c
        public Decimal actualRate;       // Actual_Daily_Rate__c
        public Decimal actualTotal;      // Actual_Total_Salary__c    (formula, read-only)
        // Calculated indirect cost amounts (formula fields — populated on load, used for P&L display)
        public Decimal fringeAmount;     // Fringe_Amount__c
        public Decimal overheadAmount;   // Overhead_Amount__c
        public Decimal gaAmount;         // G_A_Amount__c
    }

    // ─── Outbound (Apex → JS) ─────────────────────────────────────────────────

    /**
     * Top-level response from loadBudget().
     */
    public class LoadResponse {
        public BudgetHeader    header;
        public List<MonthColumn> months;   // ordered list of month columns
        public List<BudgetRow>   rows;     // all line items
        public BudgetSummary   summary;
        public List<EmployeeOption>  employees;  // active employees for the picker
        public List<AgreementOption> agreements; // agreements linked to the contract
    }

    /**
     * Budget__c header data returned to the page.
     */
    public class BudgetHeader {
        public String  budgetId;
        public String  contractId;
        public String  contractName;
        public Decimal contractTotal;     // Total_Amount_of_Contract__c
        public Date    contractStart;     // Contract_Start_Date__c
        public Date    contractEnd;       // Contract_End_Date__c
        public Date    budgetStart;       // Budget_Period_Start_Date__c
        public Date    budgetEnd;         // Budget_Period_End_date__c
        public Decimal fringeRate;
        public Decimal overheadRate;
        public Decimal gaRate;
        public Decimal customRate;
        public String  indirectCostType;
        public Decimal feePercentage;
    }

    /**
     * One month column in the grid.
     */
    public class MonthColumn {
        public String  monthKey;   // "YYYY_MM"
        public String  label;      // "Jan 2024"
        public Boolean isLocked;   // drives AG Grid editable flag
    }

    /**
     * Summary strip values shown above the grid.
     */
    public class BudgetSummary {
        public Decimal totalBudgeted;      // sum of all projected grand totals
        public Decimal billedToDate;       // sum of locked months only
        public Decimal remaining;          // totalBudgeted - billedToDate
        public Decimal contractTotal;      // Total_Amount_of_Contract__c
    }

    /**
     * One employee option in the Add Employee picker modal.
     */
    public class EmployeeOption {
        public String  employeeId;
        public String  name;
        public String  employeeType;   // Employee_Type__c
        public Decimal dailyRate;      // Loaded_Daily_Rate__c
    }

    /**
     * One agreement option in the Add Subcontract picker modal.
     */
    public class AgreementOption {
        public String  agreementId;
        public String  name;
        public Decimal contractBudget; // Contract_Budget__c
    }

    /**
     * Generic response wrapper for save/error cases.
     */
    public class ResponseWrapper {
        public Boolean success;
        public String  message;
        public String  budgetId;   // returned after a successful create

        public ResponseWrapper(Boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }
}
