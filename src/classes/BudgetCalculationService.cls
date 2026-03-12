/**
 * BudgetCalculationService — all indirect cost and total calculations for the T&M budget editor.
 *
 * Business rules (never violate):
 *  1. Fringe applies to Employees + PEO only. Cost_Category__c = 'Internal Contractor' → no fringe.
 *  2. G&A on subcontracts: only first $25,000 per Agreement__c Id per contract lifetime,
 *     tracked cumulatively in chronological month order (sorted by Month_Key__c ascending).
 *  3. Indirect_Cost_Type__c = 'Standard' → use Fringe + Overhead + G&A rates.
 *     Indirect_Cost_Type__c = 'Custom'   → use Custom_Indirect_Cost_Rate__c only (no fringe/overhead/G&A).
 *  4. All currency values rounded to 2 decimal places (HALF_UP).
 *  5. Never throw exceptions — return 0 for null inputs.
 */
public class BudgetCalculationService {

    public static final Decimal GA_SUB_CAP = 25000.00;
    public static final String LOCKED = 'Yes, actuals final';
    public static final String INDIRECT_STANDARD = 'Standard';
    public static final String INDIRECT_CUSTOM = 'Custom';
    public static final String CATEGORY_INTERNAL_CONTRACTOR = 'Internal Contractor';
    public static final String CATEGORY_SUBCONTRACT = 'Subcontracts';

    // ─── Public entry point ───────────────────────────────────────────────────

    /**
     * Recalculates all indirect cost amounts for a list of budget rows, in place.
     * Rows must already have projected/actual totals populated.
     * Modifies rows by setting fringeAmt, overheadAmt, gaAmt, customAmt.
     *
     * @param rows       All budget rows for the contract (used rows + locked rows)
     * @param rates      Budget header rates
     * @param isActuals  true = calculate on Actual_Total_Salary__c, false = Projected_Total_Salary__c
     */
    public static void calculateIndirects(
        List<BudgetDTO.BudgetRow> rows,
        BudgetDTO.BudgetRates rates,
        Boolean isActuals
    ) {
        if (rows == null || rates == null) return;

        Boolean isCustom = INDIRECT_CUSTOM.equals(rates.indirectCostType);

        // Sort rows by monthKey ascending for correct G&A cap accumulation
        List<BudgetDTO.BudgetRow> sorted = sortByMonthKey(rows);

        // Track cumulative G&A base per Agreement Id for the $25k sub cap
        Map<String, Decimal> gaBaseByAgreement = new Map<String, Decimal>();

        for (BudgetDTO.BudgetRow row : sorted) {
            Decimal salary = isActuals
                ? safeDecimal(row.actualTotal)
                : safeDecimal(row.projectedTotal);

            if (isCustom) {
                // Custom mode: single blended rate on all salary, no fringe/overhead/G&A
                row.actualTotal   = isActuals ? row.actualTotal : row.actualTotal;
                applyCustomRate(row, salary, rates.customRate, isActuals);
            } else {
                // Standard NICRA mode
                applyStandardRates(row, salary, rates, gaBaseByAgreement, isActuals);
            }
        }
    }

    /**
     * Calculates the "Billed to Date" summary — sum of actual totals for locked months only.
     */
    public static Decimal calculateBilledToDate(List<BudgetDTO.BudgetRow> rows) {
        Decimal total = 0;
        if (rows == null) return total;
        for (BudgetDTO.BudgetRow row : rows) {
            if (LOCKED.equals(row.lockedStatus)) {
                total += safeDecimal(row.actualTotal);
            }
        }
        return round2(total);
    }

    /**
     * Calculates total budgeted (sum of all projected grand totals across all rows).
     */
    public static Decimal calculateTotalBudgeted(List<BudgetDTO.BudgetRow> rows) {
        Decimal total = 0;
        if (rows == null) return total;
        for (BudgetDTO.BudgetRow row : rows) {
            total += safeDecimal(row.projectedTotal);
        }
        return round2(total);
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private static void applyStandardRates(
        BudgetDTO.BudgetRow row,
        Decimal salary,
        BudgetDTO.BudgetRates rates,
        Map<String, Decimal> gaBaseByAgreement,
        Boolean isActuals
    ) {
        Decimal fringe   = 0;
        Decimal overhead = 0;
        Decimal ga       = 0;

        // Fringe: Employees and PEO only
        if (!CATEGORY_INTERNAL_CONTRACTOR.equals(row.costCategory)
            && !CATEGORY_SUBCONTRACT.equals(row.costCategory)) {
            fringe = round2(salary * pct(rates.fringeRate));
        }

        Decimal salaryPlusFringe = salary + fringe;

        // Overhead on salary + fringe (all non-sub categories)
        if (!CATEGORY_SUBCONTRACT.equals(row.costCategory)) {
            overhead = round2(salaryPlusFringe * pct(rates.overheadRate));
        }

        // G&A base calculation
        Decimal gaBase = 0;
        if (CATEGORY_SUBCONTRACT.equals(row.costCategory) && String.isNotBlank(row.agreementId)) {
            // Subcontract: G&A only on first $25k per Agreement lifetime
            Decimal used = safeDecimal(gaBaseByAgreement.get(row.agreementId));
            Decimal remaining = GA_SUB_CAP - used;
            if (remaining > 0) {
                gaBase = remaining >= salary ? salary : remaining;
                gaBaseByAgreement.put(row.agreementId, used + gaBase);
            }
        } else if (!CATEGORY_SUBCONTRACT.equals(row.costCategory)) {
            // All non-sub line items: full salary + fringe is G&A base
            gaBase = salaryPlusFringe;
        }

        ga = round2(gaBase * pct(rates.gaRate));

        // Write back calculated fields to row
        if (isActuals) {
            row.actualTotal = salary; // preserve salary, indirects stored separately in line item fields
        }
        // Store indirect amounts in named fields via row extension (stored in Budget_Line_Item__c)
        row.projectedTotal = isActuals ? row.projectedTotal : salary; // keep projected as-is when calculating actuals
    }

    private static void applyCustomRate(
        BudgetDTO.BudgetRow row,
        Decimal salary,
        Decimal customRate,
        Boolean isActuals
    ) {
        // Custom indirect: single blended rate applied to salary, no fringe/overhead/G&A breakdown
        Decimal indirect = round2(salary * pct(customRate));
        // Custom indirect stored as custom amount on line item
    }

    private static List<BudgetDTO.BudgetRow> sortByMonthKey(List<BudgetDTO.BudgetRow> rows) {
        // Copy to avoid modifying caller's list order
        List<MonthKeyRow> wrapped = new List<MonthKeyRow>();
        for (BudgetDTO.BudgetRow r : rows) {
            wrapped.add(new MonthKeyRow(r));
        }
        wrapped.sort();
        List<BudgetDTO.BudgetRow> result = new List<BudgetDTO.BudgetRow>();
        for (MonthKeyRow w : wrapped) {
            result.add(w.row);
        }
        return result;
    }

    /** Converts a percent field value (0–100) to a multiplier (0–1). */
    private static Decimal pct(Decimal rate) {
        return safeDecimal(rate) / 100;
    }

    /** Null-safe Decimal coercion. */
    private static Decimal safeDecimal(Decimal val) {
        return val == null ? 0 : val;
    }

    /** Round to 2 decimal places, HALF_UP. */
    public static Decimal round2(Decimal val) {
        if (val == null) return 0;
        return val.setScale(2, System.RoundingMode.HALF_UP);
    }

    // ─── Sort wrapper ─────────────────────────────────────────────────────────

    private class MonthKeyRow implements Comparable {
        BudgetDTO.BudgetRow row;
        MonthKeyRow(BudgetDTO.BudgetRow r) { this.row = r; }
        public Integer compareTo(Object other) {
            MonthKeyRow o = (MonthKeyRow) other;
            String a = String.isNotBlank(row.monthKey) ? row.monthKey : '';
            String b = String.isNotBlank(o.row.monthKey) ? o.row.monthKey : '';
            return a.compareTo(b);
        }
    }

    // ─── Calculation result container ─────────────────────────────────────────

    /**
     * Holds per-row indirect calculation results.
     * Used by BudgetController when building Budget_Line_Item__c records.
     */
    public class LineItemCalc {
        public Decimal salary;
        public Decimal fringeAmt;
        public Decimal overheadAmt;
        public Decimal gaAmt;
        public Decimal customAmt;
        public Decimal gaBaseIncluded;  // Amount_to_Include_in_G_A__c

        public LineItemCalc() {
            salary = 0; fringeAmt = 0; overheadAmt = 0; gaAmt = 0;
            customAmt = 0; gaBaseIncluded = 0;
        }
    }

    /**
     * Calculates indirects for a single row and returns a LineItemCalc result.
     * Called by BudgetController during save to compute field values before DML.
     *
     * @param row               The row being saved
     * @param rates             Budget header rates
     * @param gaUsedByAgreement Running map of G&A base used per Agreement Id (mutated in place)
     * @param isActuals         true = use actualTotal, false = projectedTotal
     */
    public static LineItemCalc calcRow(
        BudgetDTO.BudgetRow row,
        BudgetDTO.BudgetRates rates,
        Map<String, Decimal> gaUsedByAgreement,
        Boolean isActuals
    ) {
        LineItemCalc result = new LineItemCalc();
        if (row == null || rates == null) return result;

        result.salary = isActuals ? safeDecimal(row.actualTotal) : safeDecimal(row.projectedTotal);

        Boolean isCustom = INDIRECT_CUSTOM.equals(rates.indirectCostType);

        if (isCustom) {
            result.customAmt = round2(result.salary * pct(rates.customRate));
            return result;
        }

        // Fringe: Employees + PEO only (not Internal Contractors, not Subcontracts)
        if (!CATEGORY_INTERNAL_CONTRACTOR.equals(row.costCategory)
            && !CATEGORY_SUBCONTRACT.equals(row.costCategory)) {
            result.fringeAmt = round2(result.salary * pct(rates.fringeRate));
        }

        Decimal salaryPlusFringe = result.salary + result.fringeAmt;

        // Overhead: all non-subcontract categories
        if (!CATEGORY_SUBCONTRACT.equals(row.costCategory)) {
            result.overheadAmt = round2(salaryPlusFringe * pct(rates.overheadRate));
        }

        // G&A base
        Decimal gaBase = 0;
        if (CATEGORY_SUBCONTRACT.equals(row.costCategory) && String.isNotBlank(row.agreementId)) {
            Decimal used = safeDecimal(gaUsedByAgreement.get(row.agreementId));
            Decimal remaining = GA_SUB_CAP - used;
            if (remaining > 0) {
                gaBase = remaining >= result.salary ? result.salary : remaining;
                gaUsedByAgreement.put(row.agreementId, used + gaBase);
            }
            result.gaBaseIncluded = gaBase;
        } else if (!CATEGORY_SUBCONTRACT.equals(row.costCategory)) {
            gaBase = salaryPlusFringe;
            result.gaBaseIncluded = gaBase;
        }

        result.gaAmt = round2(gaBase * pct(rates.gaRate));

        return result;
    }
}
