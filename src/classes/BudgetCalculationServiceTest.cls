/**
 * BudgetCalculationServiceTest — covers all 8 T&M budget scenarios.
 *
 * Reference scenario (used for manual browser verification):
 *   Employee A:  10 units × $500/day = $5,000 salary
 *   Fringe:      30% → $1,500
 *   Overhead:    20% on ($5,000 + $1,500) = $1,300
 *   G&A:         10% on ($5,000 + $1,500) = $650
 *   Grand Total: $5,000 + $1,500 + $1,300 + $650 = $8,450
 *
 * All 8 scenarios from SPEC.md:
 *   1. Standard rates, no sub, no fee
 *   2. Standard rates, with sub (under $25k), no fee
 *   3. Standard rates, with sub (under $25k), with fee
 *   4. Custom indirect, no sub
 *   5. Custom indirect, with sub
 *   6. No indirects (all rates 0), no sub
 *   7. No indirects, with sub
 *   8. Sub that exceeds $25k cap (two months)
 */
@IsTest
private class BudgetCalculationServiceTest {

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private static BudgetDTO.BudgetRates standardRates(
        Decimal fringe, Decimal overhead, Decimal ga, Decimal fee
    ) {
        BudgetDTO.BudgetRates r = new BudgetDTO.BudgetRates();
        r.indirectCostType = BudgetCalculationService.INDIRECT_STANDARD;
        r.fringeRate    = fringe;
        r.overheadRate  = overhead;
        r.gaRate        = ga;
        r.feePercentage = fee;
        r.customRate    = 0;
        return r;
    }

    private static BudgetDTO.BudgetRates customRates(Decimal customRate) {
        BudgetDTO.BudgetRates r = new BudgetDTO.BudgetRates();
        r.indirectCostType = BudgetCalculationService.INDIRECT_CUSTOM;
        r.customRate    = customRate;
        r.fringeRate    = 0;
        r.overheadRate  = 0;
        r.gaRate        = 0;
        r.feePercentage = 0;
        return r;
    }

    private static BudgetDTO.BudgetRow employeeRow(
        String monthKey, Decimal units, Decimal rate
    ) {
        BudgetDTO.BudgetRow row = new BudgetDTO.BudgetRow();
        row.costCategory    = 'Employee';
        row.monthKey        = monthKey;
        row.projectedUnits  = units;
        row.projectedRate   = rate;
        row.projectedTotal  = units * rate;
        row.actualTotal     = units * rate;
        row.lockedStatus    = 'No, still projected';
        return row;
    }

    private static BudgetDTO.BudgetRow subRow(
        String monthKey, String agreementId, Decimal amount
    ) {
        BudgetDTO.BudgetRow row = new BudgetDTO.BudgetRow();
        row.costCategory   = BudgetCalculationService.CATEGORY_SUBCONTRACT;
        row.agreementId    = agreementId;
        row.monthKey       = monthKey;
        row.projectedTotal = amount;
        row.actualTotal    = amount;
        row.lockedStatus   = 'No, still projected';
        return row;
    }

    private static BudgetDTO.BudgetRow contractorRow(String monthKey, Decimal amount) {
        BudgetDTO.BudgetRow row = new BudgetDTO.BudgetRow();
        row.costCategory   = BudgetCalculationService.CATEGORY_INTERNAL_CONTRACTOR;
        row.monthKey       = monthKey;
        row.projectedTotal = amount;
        row.actualTotal    = amount;
        row.lockedStatus   = 'No, still projected';
        return row;
    }

    // ─── Scenario 1: Standard rates, no sub, no fee ───────────────────────────

    @IsTest
    static void testScenario1_StandardNoSubNoFee() {
        BudgetDTO.BudgetRates rates = standardRates(30, 20, 10, 0);
        // Employee: 10 days × $500 = $5,000
        BudgetDTO.BudgetRow emp = employeeRow('2024_01', 10, 500);
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        BudgetCalculationService.LineItemCalc calc =
            BudgetCalculationService.calcRow(emp, rates, gaUsed, false);

        System.assertEquals(5000.00, calc.salary,      'Salary');
        System.assertEquals(1500.00, calc.fringeAmt,   'Fringe 30%');
        System.assertEquals(1300.00, calc.overheadAmt, 'Overhead 20% on 6500');
        System.assertEquals(650.00,  calc.gaAmt,       'G&A 10% on 6500');
        System.assertEquals(6500.00, calc.gaBaseIncluded, 'G&A base = salary + fringe');
        System.assertEquals(0,       calc.customAmt,   'No custom rate');
    }

    // ─── Scenario 2: Standard rates, sub under $25k, no fee ──────────────────

    @IsTest
    static void testScenario2_StandardSubUnderCapNoFee() {
        BudgetDTO.BudgetRates rates = standardRates(30, 20, 10, 0);
        String agreeId = 'AGR001';
        // Subcontract $10,000 — under $25k cap
        BudgetDTO.BudgetRow sub = subRow('2024_01', agreeId, 10000);
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        BudgetCalculationService.LineItemCalc calc =
            BudgetCalculationService.calcRow(sub, rates, gaUsed, false);

        System.assertEquals(10000.00, calc.salary,       'Sub salary');
        System.assertEquals(0,        calc.fringeAmt,    'No fringe on sub');
        System.assertEquals(0,        calc.overheadAmt,  'No overhead on sub');
        System.assertEquals(1000.00,  calc.gaAmt,        'G&A 10% on $10k');
        System.assertEquals(10000.00, calc.gaBaseIncluded, '$10k under cap');
        System.assertEquals(10000.00, gaUsed.get(agreeId), 'Cap tracker updated');
    }

    // ─── Scenario 3: Standard rates, sub under $25k, with fee ────────────────

    @IsTest
    static void testScenario3_StandardSubUnderCapWithFee() {
        // Fee is applied at the BudgetController level on the grand total,
        // not in the per-row calculation. Verify calcRow is unaffected by fee setting.
        BudgetDTO.BudgetRates rates = standardRates(30, 20, 10, 5);
        String agreeId = 'AGR002';
        BudgetDTO.BudgetRow sub = subRow('2024_01', agreeId, 8000);
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        BudgetCalculationService.LineItemCalc calc =
            BudgetCalculationService.calcRow(sub, rates, gaUsed, false);

        System.assertEquals(800.00, calc.gaAmt, 'G&A 10% on $8k');
        System.assertEquals(8000.00, calc.gaBaseIncluded, '$8k under cap');
    }

    // ─── Scenario 4: Custom indirect, no sub ─────────────────────────────────

    @IsTest
    static void testScenario4_CustomNoSub() {
        BudgetDTO.BudgetRates rates = customRates(25);
        BudgetDTO.BudgetRow emp = employeeRow('2024_01', 5, 400); // $2,000
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        BudgetCalculationService.LineItemCalc calc =
            BudgetCalculationService.calcRow(emp, rates, gaUsed, false);

        System.assertEquals(2000.00, calc.salary,     'Salary');
        System.assertEquals(500.00,  calc.customAmt,  'Custom 25% on $2k');
        System.assertEquals(0,       calc.fringeAmt,  'No fringe in custom mode');
        System.assertEquals(0,       calc.overheadAmt,'No overhead in custom mode');
        System.assertEquals(0,       calc.gaAmt,      'No G&A in custom mode');
    }

    // ─── Scenario 5: Custom indirect, with sub ───────────────────────────────

    @IsTest
    static void testScenario5_CustomWithSub() {
        BudgetDTO.BudgetRates rates = customRates(25);
        String agreeId = 'AGR003';
        BudgetDTO.BudgetRow sub = subRow('2024_01', agreeId, 12000);
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        BudgetCalculationService.LineItemCalc calc =
            BudgetCalculationService.calcRow(sub, rates, gaUsed, false);

        System.assertEquals(12000.00, calc.salary,    'Sub salary');
        System.assertEquals(3000.00,  calc.customAmt, 'Custom 25% on $12k');
        System.assertEquals(0,        calc.gaAmt,     'No G&A in custom mode');
        // G&A cap tracker should NOT be updated in custom mode
        System.assertEquals(null, gaUsed.get(agreeId), 'Cap not tracked in custom mode');
    }

    // ─── Scenario 6: No indirects (zero rates), no sub ───────────────────────

    @IsTest
    static void testScenario6_NoIndirectsNoSub() {
        BudgetDTO.BudgetRates rates = standardRates(0, 0, 0, 0);
        BudgetDTO.BudgetRow emp = employeeRow('2024_01', 8, 300); // $2,400
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        BudgetCalculationService.LineItemCalc calc =
            BudgetCalculationService.calcRow(emp, rates, gaUsed, false);

        System.assertEquals(2400.00, calc.salary,      'Salary');
        System.assertEquals(0,       calc.fringeAmt,   'No fringe');
        System.assertEquals(0,       calc.overheadAmt, 'No overhead');
        System.assertEquals(0,       calc.gaAmt,       'No G&A');
    }

    // ─── Scenario 7: No indirects, with sub ──────────────────────────────────

    @IsTest
    static void testScenario7_NoIndirectsWithSub() {
        BudgetDTO.BudgetRates rates = standardRates(0, 0, 0, 0);
        String agreeId = 'AGR004';
        BudgetDTO.BudgetRow sub = subRow('2024_01', agreeId, 30000); // over cap but rates are 0
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        BudgetCalculationService.LineItemCalc calc =
            BudgetCalculationService.calcRow(sub, rates, gaUsed, false);

        System.assertEquals(30000.00, calc.salary,  'Sub salary');
        System.assertEquals(0,        calc.gaAmt,   'G&A = 0 because rate is 0%');
        System.assertEquals(25000.00, calc.gaBaseIncluded, 'Base capped at $25k');
        System.assertEquals(25000.00, gaUsed.get(agreeId), 'Cap tracker at $25k');
    }

    // ─── Scenario 8: Sub exceeding $25k cap across two months ────────────────

    @IsTest
    static void testScenario8_SubExceedsCapAcrossMonths() {
        BudgetDTO.BudgetRates rates = standardRates(30, 20, 10, 0);
        String agreeId = 'AGREE_CAP_TEST';
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        // Month 1: $20,000 (under cap — all $20k included)
        BudgetDTO.BudgetRow sub1 = subRow('2024_01', agreeId, 20000);
        BudgetCalculationService.LineItemCalc calc1 =
            BudgetCalculationService.calcRow(sub1, rates, gaUsed, false);

        System.assertEquals(20000.00, calc1.gaBaseIncluded, 'Month 1: full $20k included');
        System.assertEquals(2000.00,  calc1.gaAmt,          'Month 1 G&A: 10% of $20k');
        System.assertEquals(20000.00, gaUsed.get(agreeId),  'Cap tracker after month 1');

        // Month 2: $15,000 (only $5k remaining under cap)
        BudgetDTO.BudgetRow sub2 = subRow('2024_02', agreeId, 15000);
        BudgetCalculationService.LineItemCalc calc2 =
            BudgetCalculationService.calcRow(sub2, rates, gaUsed, false);

        System.assertEquals(5000.00,  calc2.gaBaseIncluded, 'Month 2: only $5k remaining');
        System.assertEquals(500.00,   calc2.gaAmt,          'Month 2 G&A: 10% of $5k');
        System.assertEquals(25000.00, gaUsed.get(agreeId),  'Cap maxed out after month 2');

        // Month 3: $10,000 (cap exhausted — $0 included)
        BudgetDTO.BudgetRow sub3 = subRow('2024_03', agreeId, 10000);
        BudgetCalculationService.LineItemCalc calc3 =
            BudgetCalculationService.calcRow(sub3, rates, gaUsed, false);

        System.assertEquals(0,        calc3.gaBaseIncluded, 'Month 3: cap exhausted');
        System.assertEquals(0,        calc3.gaAmt,          'Month 3 G&A: $0');
        System.assertEquals(25000.00, gaUsed.get(agreeId),  'Cap unchanged after exhaustion');
    }

    // ─── Internal contractor fringe exclusion ────────────────────────────────

    @IsTest
    static void testInternalContractorNoFringe() {
        BudgetDTO.BudgetRates rates = standardRates(30, 20, 10, 0);
        BudgetDTO.BudgetRow contractor = contractorRow('2024_01', 5000);
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        BudgetCalculationService.LineItemCalc calc =
            BudgetCalculationService.calcRow(contractor, rates, gaUsed, false);

        System.assertEquals(0, calc.fringeAmt, 'Internal contractors excluded from fringe');
        // Overhead and G&A still apply to contractors
        System.assertEquals(
            BudgetCalculationService.round2(5000 * 0.20),
            calc.overheadAmt, 'Overhead on contractor salary'
        );
    }

    // ─── Multiple subs with independent caps ─────────────────────────────────

    @IsTest
    static void testMultipleSubsIndependentCaps() {
        BudgetDTO.BudgetRates rates = standardRates(30, 20, 10, 0);
        String agree1 = 'AGREE_A';
        String agree2 = 'AGREE_B';
        Map<String, Decimal> gaUsed = new Map<String, Decimal>();

        // Sub A: $20k in Jan
        BudgetCalculationService.LineItemCalc calcA1 =
            BudgetCalculationService.calcRow(subRow('2024_01', agree1, 20000), rates, gaUsed, false);

        // Sub B: $20k in Jan — independent cap, should also include full $20k
        BudgetCalculationService.LineItemCalc calcB1 =
            BudgetCalculationService.calcRow(subRow('2024_01', agree2, 20000), rates, gaUsed, false);

        System.assertEquals(20000.00, calcA1.gaBaseIncluded, 'Sub A: $20k included');
        System.assertEquals(20000.00, calcB1.gaBaseIncluded, 'Sub B: independent $20k cap');
        System.assertEquals(20000.00, gaUsed.get(agree1), 'Sub A cap tracker');
        System.assertEquals(20000.00, gaUsed.get(agree2), 'Sub B cap tracker independent');
    }

    // ─── Null safety ─────────────────────────────────────────────────────────

    @IsTest
    static void testNullSafety() {
        // Should not throw
        BudgetCalculationService.calcRow(null, null, new Map<String, Decimal>(), false);
        BudgetCalculationService.calculateBilledToDate(null);
        BudgetCalculationService.calculateTotalBudgeted(null);
        BudgetCalculationService.round2(null);
        System.assert(true, 'No exceptions on null inputs');
    }

    // ─── Billed to date only counts locked rows ───────────────────────────────

    @IsTest
    static void testBilledToDateLockedOnly() {
        BudgetDTO.BudgetRow locked = employeeRow('2024_01', 5, 1000); // $5,000
        locked.lockedStatus  = BudgetCalculationService.LOCKED;
        locked.actualTotal   = 5000;

        BudgetDTO.BudgetRow unlocked = employeeRow('2024_02', 5, 1000); // $5,000
        unlocked.lockedStatus = 'No, still projected';
        unlocked.actualTotal  = 5000;

        List<BudgetDTO.BudgetRow> rows = new List<BudgetDTO.BudgetRow>{ locked, unlocked };
        Decimal billed = BudgetCalculationService.calculateBilledToDate(rows);

        System.assertEquals(5000.00, billed, 'Only locked month included in Billed to Date');
    }
}
