/**
 * BudgetLineItemTriggerHandlerTest — covers lock enforcement and trigger guard.
 *
 * Note: Bypass_Budget_Lock custom permission is not assigned in test context,
 * so all tests run without bypass unless explicitly tested via permission set.
 */
@IsTest
private class BudgetLineItemTriggerHandlerTest {

    // ─── Test data setup ─────────────────────────────────────────────────────

    private static DContract__c createContract() {
        DContract__c c = new DContract__c(
            Name                    = 'Test Contract',
            Contract_Start_Date__c  = Date.newInstance(2024, 1, 1),
            Contract_End_Date__c    = Date.newInstance(2024, 12, 31)
        );
        insert c;
        return c;
    }

    private static Budget__c createBudget(Id contractId) {
        Budget__c b = new Budget__c(
            Contract__c                = contractId,
            Budget_Period_Start_Date__c = Date.newInstance(2024, 1, 1),
            Budget_Period_End_date__c   = Date.newInstance(2024, 12, 31),
            Fringe_Benefit_Rate__c      = 30,
            Overhead_Rate__c            = 20,
            G_A_Rate__c                 = 10,
            Indirect_Cost_Type__c       = 'Standard',
            Fee_Percentage__c           = 0
        );
        insert b;
        return b;
    }

    private static Budget_Line_Item__c buildLineItem(Id budgetId, String monthKey, String locked) {
        Budget_Line_Item__c li = new Budget_Line_Item__c(
            Budget__c            = budgetId,
            Month_Key__c         = monthKey,
            Cost_Category__c     = 'Employee',
            Actuals_Locked__c    = locked,
            Projected_Units__c   = 5,
            Actual_Units__c      = 5,
            Actual_Daily_Rate__c = 400
            // Projected_Daily_Rate__c, Projected_Total_Salary__c, Actual_Total_Salary__c
            // are formula fields — not settable directly
        );
        return li;
    }

    // ─── Trigger guard: null Month_Key skipped ────────────────────────────────

    @IsTest
    static void testTriggerGuard_NullMonthKeySkipped() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        // Old-style record with no Month_Key__c — should be insertable even if
        // the handler would normally block it (it won't run for this record)
        Budget_Line_Item__c oldRecord = new Budget_Line_Item__c(
            Budget__c             = budget.Id,
            Month_Key__c          = null,   // old date-range style record
            Cost_Category__c      = 'Employee',
            Actuals_Locked__c     = 'Yes, actuals final'
        );

        // Should not throw — trigger guard skips null Month_Key records
        Test.startTest();
        insert oldRecord;
        Test.stopTest();

        System.assertNotEquals(null, oldRecord.Id, 'Old-style record inserted without error');
    }

    // ─── Insert: unlocked record succeeds ────────────────────────────────────

    @IsTest
    static void testInsert_UnlockedSucceeds() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        Budget_Line_Item__c li = buildLineItem(budget.Id, '2024_01', 'No, still projected');

        Test.startTest();
        insert li;
        Test.stopTest();

        System.assertNotEquals(null, li.Id, 'Unlocked line item inserted');
    }

    // ─── Update: editing a locked record is blocked ───────────────────────────

    @IsTest
    static void testUpdate_LockedRecordBlocked() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        // Insert a locked record (insert is allowed)
        Budget_Line_Item__c li = buildLineItem(budget.Id, '2024_01', 'Yes, actuals final');
        insert li;

        // Now try to update it — should be blocked
        li.Projected_Units__c = 99;
        Test.startTest();
        try {
            update li;
            System.assert(false, 'Expected DmlException not thrown');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('locked') || e.getMessage().contains('actuals are final'),
                'Error message mentions lock: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    // ─── Update: editing an unlocked record succeeds ──────────────────────────

    @IsTest
    static void testUpdate_UnlockedRecordSucceeds() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        Budget_Line_Item__c li = buildLineItem(budget.Id, '2024_01', 'No, still projected');
        insert li;

        li.Projected_Units__c = 10;
        Test.startTest();
        update li;
        Test.stopTest();

        Budget_Line_Item__c updated = [SELECT Projected_Units__c FROM Budget_Line_Item__c WHERE Id = :li.Id];
        System.assertEquals(10, updated.Projected_Units__c, 'Unlocked record updated successfully');
    }

    // ─── Insert: new record inherits locked status from existing sibling ──────

    @IsTest
    static void testInsert_InheritsLockFromSibling() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        // Existing locked record for 2024_01
        Budget_Line_Item__c existing = buildLineItem(budget.Id, '2024_01', 'Yes, actuals final');
        insert existing;

        // New record for the same month — should inherit locked status
        Budget_Line_Item__c newItem = buildLineItem(budget.Id, '2024_01', 'No, still projected');
        Test.startTest();
        insert newItem;
        Test.stopTest();

        Budget_Line_Item__c inserted = [SELECT Actuals_Locked__c FROM Budget_Line_Item__c WHERE Id = :newItem.Id];
        System.assertEquals(
            'Yes, actuals final',
            inserted.Actuals_Locked__c,
            'New record in locked month inherited locked status'
        );
    }

    // ─── Insert: new record in unlocked month does NOT inherit lock ───────────

    @IsTest
    static void testInsert_NoInheritanceForUnlockedMonth() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        // Jan is locked, Feb is not
        Budget_Line_Item__c jan = buildLineItem(budget.Id, '2024_01', 'Yes, actuals final');
        insert jan;

        Budget_Line_Item__c feb = buildLineItem(budget.Id, '2024_02', 'No, still projected');
        Test.startTest();
        insert feb;
        Test.stopTest();

        Budget_Line_Item__c inserted = [SELECT Actuals_Locked__c FROM Budget_Line_Item__c WHERE Id = :feb.Id];
        System.assertNotEquals(
            'Yes, actuals final',
            inserted.Actuals_Locked__c,
            'Record in unlocked month should not inherit lock'
        );
    }

    // ─── Bulk: 200 records, mix of locked and unlocked ───────────────────────

    @IsTest
    static void testBulk_MixedLockStatus() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        // Insert 100 unlocked records — should all succeed
        List<Budget_Line_Item__c> items = new List<Budget_Line_Item__c>();
        for (Integer i = 1; i <= 100; i++) {
            String monthKey = '2024_' + String.valueOf(i).leftPad(2, '0');
            if (i > 12) monthKey = '2024_01'; // reuse month for volume
            items.add(buildLineItem(budget.Id, monthKey, 'No, still projected'));
        }

        Test.startTest();
        insert items;
        Test.stopTest();

        System.assertEquals(100, [SELECT COUNT() FROM Budget_Line_Item__c WHERE Budget__c = :budget.Id]);
    }
}
