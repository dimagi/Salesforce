/**
 * BudgetController — @RemoteAction controller for TmBudgetEditor.page.
 *
 * Three entry points:
 *   loadBudget(contractId, budgetId)  — returns serialized LoadResponse JSON
 *   saveBudget(payloadJson)           — upserts Budget__c + Budget_Line_Item__c, savepoint rollback on error
 *   addEmployees(budgetId, json)      — bulk-inserts employee rows across all budget months
 *
 * All methods return JSON strings (not typed objects) so the VF RemoteAction callback
 * receives a plain string that JS can JSON.parse() — avoids SF double-serialization quirks.
 *
 * Note: Employee_Status__c picklist value 'Active' should be verified against org metadata.
 */
public class BudgetController {

    // ─── loadBudget ───────────────────────────────────────────────────────────

    @RemoteAction
    public static String loadBudget(String contractId, String budgetId) {
        try {
            if (String.isBlank(contractId)) {
                return errorJson('contractId is required');
            }

            DContract__c contract = [
                SELECT Id, Name, Contract_Start_Date__c, Contract_End_Date__c,
                       Total_Amount_of_Contract__c
                FROM DContract__c
                WHERE Id = :contractId
                LIMIT 1
            ];

            // Find existing budget (by explicit Id or most recent for contract)
            Budget__c budget = findBudget(contractId, budgetId);

            BudgetDTO.LoadResponse response = new BudgetDTO.LoadResponse();

            // Build header
            BudgetDTO.BudgetHeader header = new BudgetDTO.BudgetHeader();
            header.contractId    = contract.Id;
            header.contractName  = contract.Name;
            header.contractTotal = contract.Total_Amount_of_Contract__c;
            header.contractStart = contract.Contract_Start_Date__c;
            header.contractEnd   = contract.Contract_End_Date__c;

            Date periodStart = contract.Contract_Start_Date__c;
            Date periodEnd   = contract.Contract_End_Date__c;

            if (budget != null) {
                header.budgetId        = budget.Id;
                header.budgetStart     = budget.Budget_Period_Start_Date__c;
                header.budgetEnd       = budget.Budget_Period_End_date__c;
                header.fringeRate      = budget.Fringe_Benefit_Rate__c;
                header.overheadRate    = budget.Overhead_Rate__c;
                header.gaRate          = budget.G_A_Rate__c;
                header.customRate      = budget.Custom_Indirect_Cost_Rate__c;
                header.indirectCostType = budget.Indirect_Cost_Type__c;
                header.feePercentage   = budget.Fee_Percentage__c;
                if (budget.Budget_Period_Start_Date__c != null) periodStart = budget.Budget_Period_Start_Date__c;
                if (budget.Budget_Period_End_date__c   != null) periodEnd   = budget.Budget_Period_End_date__c;
            }
            response.header = header;

            // Load line items (only Month_Key__c-based records — old date-range records excluded)
            List<Budget_Line_Item__c> lineItems = new List<Budget_Line_Item__c>();
            if (budget != null) {
                lineItems = [
                    SELECT Id, Employee__c, Agreement__c, Cost_Category__c,
                           Month_Key__c, Actuals_Locked__c,
                           Projected_Units__c, Projected_Total_Salary__c,
                           Actual_Units__c, Actual_Daily_Rate__c, Actual_Total_Salary__c,
                           Amount_to_Include_in_G_A__c
                    FROM Budget_Line_Item__c
                    WHERE Budget__c = :budget.Id
                      AND Month_Key__c != null
                    ORDER BY Month_Key__c ASC, Cost_Category__c ASC
                ];
            }

            response.months   = buildMonthColumns(periodStart, periodEnd, lineItems);
            response.rows     = buildRows(lineItems);
            response.summary  = buildSummary(response.rows, contract.Total_Amount_of_Contract__c);
            response.employees = loadEmployees();

            return JSON.serialize(response);

        } catch (Exception e) {
            return errorJson(e.getMessage());
        }
    }

    // ─── saveBudget ───────────────────────────────────────────────────────────

    @RemoteAction
    public static String saveBudget(String payloadJson) {
        Savepoint sp = Database.setSavepoint();
        try {
            BudgetDTO.SavePayload payload = (BudgetDTO.SavePayload)
                JSON.deserialize(payloadJson, BudgetDTO.SavePayload.class);

            if (String.isBlank(payload.contractId)) {
                return errorJson('contractId is required');
            }

            // Upsert Budget__c header
            Budget__c budget = new Budget__c();
            Boolean isBudgetNew = String.isBlank(payload.budgetId);
            if (!isBudgetNew) {
                budget.Id = payload.budgetId;
            } else {
                // Contract__c is MasterDetail — only settable on insert
                budget.Contract__c = payload.contractId;
            }

            BudgetDTO.BudgetRates rates = payload.rates != null
                ? payload.rates
                : new BudgetDTO.BudgetRates();

            if (payload.rates != null) {
                budget.Budget_Period_Start_Date__c  = rates.budgetStart;
                budget.Budget_Period_End_date__c    = rates.budgetEnd;
                budget.Fringe_Benefit_Rate__c       = rates.fringeRate;
                budget.Overhead_Rate__c             = rates.overheadRate;
                budget.G_A_Rate__c                  = rates.gaRate;
                budget.Custom_Indirect_Cost_Rate__c = rates.customRate;
                budget.Indirect_Cost_Type__c        = rates.indirectCostType;
                budget.Fee_Percentage__c            = rates.feePercentage;
            }
            upsert budget;

            // Process line items sorted by monthKey for correct G&A cap accumulation
            if (payload.rows != null && !payload.rows.isEmpty()) {
                List<BudgetDTO.BudgetRow> sortedRows = sortRowsByMonthKey(payload.rows);
                Map<String, Decimal> gaUsed = new Map<String, Decimal>();
                List<Budget_Line_Item__c> toUpsert = new List<Budget_Line_Item__c>();

                for (BudgetDTO.BudgetRow row : sortedRows) {
                    BudgetCalculationService.LineItemCalc calc =
                        BudgetCalculationService.calcRow(row, rates, gaUsed, false);

                    Budget_Line_Item__c li = new Budget_Line_Item__c();
                    Boolean isNew = String.isBlank(row.lineItemId);
                    if (!isNew) li.Id = row.lineItemId;
                    // Only set master-detail Budget__c on insert — cannot reparent on update
                    if (isNew) li.Budget__c = budget.Id;
                    li.Month_Key__c      = row.monthKey;
                    li.Cost_Category__c  = row.costCategory;
                    li.Actuals_Locked__c = row.lockedStatus;
                    if (String.isNotBlank(row.employeeId))  li.Employee__c  = row.employeeId;
                    if (String.isNotBlank(row.agreementId)) li.Agreement__c = row.agreementId;

                    // Writable fields only — formula fields (Projected_Daily_Rate__c,
                    // Projected_Total_Salary__c, Actual_Total_Salary__c) auto-compute
                    li.Projected_Units__c          = row.projectedUnits;
                    li.Actual_Units__c             = row.actualUnits;
                    li.Actual_Daily_Rate__c        = row.actualRate;
                    li.Amount_to_Include_in_G_A__c = calc.gaBaseIncluded;

                    toUpsert.add(li);
                }
                upsert toUpsert;
            }

            BudgetDTO.ResponseWrapper result =
                new BudgetDTO.ResponseWrapper(true, 'Saved successfully');
            result.budgetId = budget.Id;
            return JSON.serialize(result);

        } catch (Exception e) {
            Database.rollback(sp);
            return errorJson(e.getMessage());
        }
    }

    // ─── addEmployees ─────────────────────────────────────────────────────────

    @RemoteAction
    public static String addEmployees(String budgetId, String employeeIdsJson) {
        try {
            List<String> employeeIds = (List<String>)
                JSON.deserialize(employeeIdsJson, List<String>.class);

            if (String.isBlank(budgetId) || employeeIds == null || employeeIds.isEmpty()) {
                return errorJson('budgetId and at least one employeeId are required');
            }

            Budget__c budget = [
                SELECT Id, Budget_Period_Start_Date__c, Budget_Period_End_date__c
                FROM Budget__c WHERE Id = :budgetId LIMIT 1
            ];

            List<String> monthKeys = generateMonthKeys(
                budget.Budget_Period_Start_Date__c,
                budget.Budget_Period_End_date__c
            );
            Set<String> lockedMonths = getLockedMonths(budgetId);

            List<Budget_Line_Item__c> newItems = new List<Budget_Line_Item__c>();
            for (String empId : employeeIds) {
                for (String monthKey : monthKeys) {
                    Budget_Line_Item__c li = new Budget_Line_Item__c();
                    li.Budget__c         = budgetId;
                    li.Employee__c       = empId;
                    li.Cost_Category__c  = 'Employee';
                    li.Month_Key__c      = monthKey;
                    li.Actuals_Locked__c = lockedMonths.contains(monthKey)
                        ? BudgetCalculationService.LOCKED
                        : 'No, still projected';
                    newItems.add(li);
                }
            }
            insert newItems;

            BudgetDTO.ResponseWrapper result =
                new BudgetDTO.ResponseWrapper(true, 'Employees added');
            return JSON.serialize(result);

        } catch (Exception e) {
            return errorJson(e.getMessage());
        }
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private static Budget__c findBudget(String contractId, String budgetId) {
        if (String.isNotBlank(budgetId)) {
            List<Budget__c> found = [
                SELECT Id, Contract__c, Budget_Period_Start_Date__c,
                       Budget_Period_End_date__c, Fringe_Benefit_Rate__c,
                       Overhead_Rate__c, G_A_Rate__c,
                       Custom_Indirect_Cost_Rate__c, Indirect_Cost_Type__c,
                       Fee_Percentage__c
                FROM Budget__c WHERE Id = :budgetId LIMIT 1
            ];
            return found.isEmpty() ? null : found[0];
        }
        List<Budget__c> existing = [
            SELECT Id, Contract__c, Budget_Period_Start_Date__c,
                   Budget_Period_End_date__c, Fringe_Benefit_Rate__c,
                   Overhead_Rate__c, G_A_Rate__c,
                   Custom_Indirect_Cost_Rate__c, Indirect_Cost_Type__c,
                   Fee_Percentage__c
            FROM Budget__c WHERE Contract__c = :contractId
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        return existing.isEmpty() ? null : existing[0];
    }

    private static List<BudgetDTO.MonthColumn> buildMonthColumns(
        Date periodStart, Date periodEnd, List<Budget_Line_Item__c> lineItems
    ) {
        Set<String> lockedKeys = new Set<String>();
        for (Budget_Line_Item__c li : lineItems) {
            if (BudgetCalculationService.LOCKED.equals(li.Actuals_Locked__c)
                && li.Month_Key__c != null) {
                lockedKeys.add(li.Month_Key__c);
            }
        }

        List<BudgetDTO.MonthColumn> cols = new List<BudgetDTO.MonthColumn>();
        List<String> keys = generateMonthKeys(periodStart, periodEnd);
        String[] monthNames = new String[]{
            'Jan','Feb','Mar','Apr','May','Jun',
            'Jul','Aug','Sep','Oct','Nov','Dec'
        };

        for (String key : keys) {
            BudgetDTO.MonthColumn col = new BudgetDTO.MonthColumn();
            col.monthKey = key;
            Integer yr   = Integer.valueOf(key.substring(0, 4));
            Integer mo   = Integer.valueOf(key.substring(5, 7));
            col.label    = monthNames[mo - 1] + ' ' + String.valueOf(yr);
            col.isLocked = lockedKeys.contains(key);
            cols.add(col);
        }
        return cols;
    }

    private static List<String> generateMonthKeys(Date startDate, Date endDate) {
        List<String> keys = new List<String>();
        if (startDate == null || endDate == null) return keys;
        Date cursor = Date.newInstance(startDate.year(), startDate.month(), 1);
        Date last   = Date.newInstance(endDate.year(), endDate.month(), 1);
        while (cursor <= last) {
            String mo = String.valueOf(cursor.month()).leftPad(2, '0');
            keys.add(String.valueOf(cursor.year()) + '_' + mo);
            cursor = cursor.addMonths(1);
        }
        return keys;
    }

    private static List<BudgetDTO.BudgetRow> buildRows(List<Budget_Line_Item__c> lineItems) {
        List<BudgetDTO.BudgetRow> rows = new List<BudgetDTO.BudgetRow>();
        for (Budget_Line_Item__c li : lineItems) {
            BudgetDTO.BudgetRow row = new BudgetDTO.BudgetRow();
            row.lineItemId     = li.Id;
            row.employeeId     = li.Employee__c;
            row.agreementId    = li.Agreement__c;
            row.costCategory   = li.Cost_Category__c;
            row.monthKey       = li.Month_Key__c;
            row.lockedStatus   = li.Actuals_Locked__c;
            row.projectedUnits = li.Projected_Units__c;
            row.projectedTotal = li.Projected_Total_Salary__c;  // formula — read-only
            row.actualUnits    = li.Actual_Units__c;
            row.actualRate     = li.Actual_Daily_Rate__c;
            row.actualTotal    = li.Actual_Total_Salary__c;      // formula — read-only
            rows.add(row);
        }
        return rows;
    }

    private static BudgetDTO.BudgetSummary buildSummary(
        List<BudgetDTO.BudgetRow> rows, Decimal contractTotal
    ) {
        BudgetDTO.BudgetSummary s = new BudgetDTO.BudgetSummary();
        s.contractTotal = contractTotal;
        s.totalBudgeted = BudgetCalculationService.calculateTotalBudgeted(rows);
        s.billedToDate  = BudgetCalculationService.calculateBilledToDate(rows);
        s.remaining     = BudgetCalculationService.round2(s.totalBudgeted - s.billedToDate);
        return s;
    }

    private static List<BudgetDTO.EmployeeOption> loadEmployees() {
        List<BudgetDTO.EmployeeOption> options = new List<BudgetDTO.EmployeeOption>();
        // Note: verify 'Active' is the correct Employee_Status__c picklist value for this org
        for (SFDC_Employee__c emp : [
            SELECT Id, Name, Employee_Type__c, Loaded_Daily_Rate__c
            FROM SFDC_Employee__c
            WHERE Employee_Status__c = 'Active'
            ORDER BY Name ASC
            LIMIT 200
        ]) {
            BudgetDTO.EmployeeOption opt = new BudgetDTO.EmployeeOption();
            opt.employeeId   = emp.Id;
            opt.name         = emp.Name;
            opt.employeeType = emp.Employee_Type__c;
            opt.dailyRate    = emp.Loaded_Daily_Rate__c;
            options.add(opt);
        }
        return options;
    }

    private static Set<String> getLockedMonths(String budgetId) {
        Set<String> locked = new Set<String>();
        for (Budget_Line_Item__c li : [
            SELECT Month_Key__c FROM Budget_Line_Item__c
            WHERE Budget__c = :budgetId
              AND Actuals_Locked__c = :BudgetCalculationService.LOCKED
              AND Month_Key__c != null
        ]) {
            locked.add(li.Month_Key__c);
        }
        return locked;
    }

    /**
     * Sorts rows by monthKey ascending using a map keyed by monthKey.
     * monthKey format "YYYY_MM" sorts correctly as a string.
     */
    private static List<BudgetDTO.BudgetRow> sortRowsByMonthKey(List<BudgetDTO.BudgetRow> rows) {
        Map<String, List<BudgetDTO.BudgetRow>> byMonth = new Map<String, List<BudgetDTO.BudgetRow>>();
        List<String> keys = new List<String>();

        for (BudgetDTO.BudgetRow row : rows) {
            String key = String.isNotBlank(row.monthKey) ? row.monthKey : '';
            if (!byMonth.containsKey(key)) {
                byMonth.put(key, new List<BudgetDTO.BudgetRow>());
                keys.add(key);
            }
            byMonth.get(key).add(row);
        }
        keys.sort();

        List<BudgetDTO.BudgetRow> sorted = new List<BudgetDTO.BudgetRow>();
        for (String key : keys) {
            sorted.addAll(byMonth.get(key));
        }
        return sorted;
    }

    private static String errorJson(String message) {
        return JSON.serialize(new BudgetDTO.ResponseWrapper(false, message));
    }
}
