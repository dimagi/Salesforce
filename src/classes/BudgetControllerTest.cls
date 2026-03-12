/**
 * BudgetControllerTest — covers loadBudget, saveBudget, and addEmployees @RemoteAction methods.
 *
 * All tests use real DML (no mocks) against the test database.
 * Formula fields (Projected_Total_Salary__c, Actual_Total_Salary__c, etc.) are read-only —
 * tests only assert on writable fields and response structure.
 */
@IsTest
private class BudgetControllerTest {

    // ─── Test data setup ──────────────────────────────────────────────────────

    private static DContract__c createContract() {
        DContract__c c = new DContract__c(
            Name                   = 'Test Contract',
            Contract_Start_Date__c = Date.newInstance(2024, 1, 1),
            Contract_End_Date__c   = Date.newInstance(2024, 3, 31)
        );
        insert c;
        return c;
    }

    private static Budget__c createBudget(Id contractId) {
        Budget__c b = new Budget__c(
            Contract__c                = contractId,
            Budget_Period_Start_Date__c = Date.newInstance(2024, 1, 1),
            Budget_Period_End_date__c   = Date.newInstance(2024, 3, 31),
            Fringe_Benefit_Rate__c      = 30,
            Overhead_Rate__c            = 20,
            G_A_Rate__c                 = 10,
            Indirect_Cost_Type__c       = 'Standard',
            Fee_Percentage__c           = 0
        );
        insert b;
        return b;
    }

    private static Budget_Line_Item__c createLineItem(
        Id budgetId, String monthKey, String locked
    ) {
        Budget_Line_Item__c li = new Budget_Line_Item__c(
            Budget__c            = budgetId,
            Month_Key__c         = monthKey,
            Cost_Category__c     = 'Employee',
            Actuals_Locked__c    = locked,
            Projected_Units__c   = 5,
            Actual_Units__c      = 5,
            Actual_Daily_Rate__c = 400
        );
        insert li;
        return li;
    }

    // ─── loadBudget: no budget exists yet ────────────────────────────────────

    @IsTest
    static void testLoadBudget_NoBudget() {
        DContract__c contract = createContract();

        Test.startTest();
        String result = BudgetController.loadBudget(contract.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Response JSON should not be null');
        // Should return a LoadResponse with no rows
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(response.containsKey('header'), 'Response has header');
        System.assert(response.containsKey('months'), 'Response has months');
        System.assert(response.containsKey('rows'), 'Response has rows');
    }

    // ─── loadBudget: existing budget with line items ──────────────────────────

    @IsTest
    static void testLoadBudget_WithBudgetAndRows() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);
        createLineItem(budget.Id, '2024_01', 'No, still projected');
        createLineItem(budget.Id, '2024_02', 'Yes, actuals final');

        Test.startTest();
        String result = BudgetController.loadBudget(contract.Id, budget.Id);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        List<Object> rows = (List<Object>) response.get('rows');
        System.assertEquals(2, rows.size(), 'Two line items returned');

        // Month columns: Jan, Feb, Mar (from budget period)
        List<Object> months = (List<Object>) response.get('months');
        System.assertEquals(3, months.size(), 'Three months in budget period');

        // Feb should be marked locked
        Map<String, Object> feb = (Map<String, Object>) months.get(1);
        System.assertEquals('2024_02', feb.get('monthKey'), 'Feb is second column');
        System.assertEquals(true, feb.get('isLocked'), 'Feb is locked');
    }

    // ─── loadBudget: finds budget automatically by contractId ─────────────────

    @IsTest
    static void testLoadBudget_AutoFindsByContractId() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        Test.startTest();
        // Pass null budgetId — should find the budget by contractId
        String result = BudgetController.loadBudget(contract.Id, null);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        Map<String, Object> header = (Map<String, Object>) response.get('header');
        System.assertEquals(budget.Id, header.get('budgetId'), 'Found budget by contractId');
    }

    // ─── loadBudget: missing contractId returns error ─────────────────────────

    @IsTest
    static void testLoadBudget_MissingContractId() {
        Test.startTest();
        String result = BudgetController.loadBudget(null, null);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, response.get('success'), 'Error on missing contractId');
    }

    // ─── saveBudget: creates new budget and line items ────────────────────────

    @IsTest
    static void testSaveBudget_CreateNew() {
        DContract__c contract = createContract();

        BudgetDTO.SavePayload payload = new BudgetDTO.SavePayload();
        payload.contractId = contract.Id;
        payload.budgetId   = null;

        BudgetDTO.BudgetRates rates = new BudgetDTO.BudgetRates();
        rates.budgetStart      = Date.newInstance(2024, 1, 1);
        rates.budgetEnd        = Date.newInstance(2024, 3, 31);
        rates.fringeRate       = 30;
        rates.overheadRate     = 20;
        rates.gaRate           = 10;
        rates.customRate       = 0;
        rates.indirectCostType = 'Standard';
        rates.feePercentage    = 0;
        payload.rates = rates;

        BudgetDTO.BudgetRow row = new BudgetDTO.BudgetRow();
        row.monthKey       = '2024_01';
        row.costCategory   = 'Employee';
        row.lockedStatus   = 'No, still projected';
        row.projectedUnits = 10;
        row.actualUnits    = 10;
        row.actualRate     = 500;
        payload.rows = new List<BudgetDTO.BudgetRow>{ row };

        Test.startTest();
        String result = BudgetController.saveBudget(JSON.serialize(payload));
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, response.get('success'), 'Save succeeded');
        System.assertNotEquals(null, response.get('budgetId'), 'Budget Id returned');

        String newBudgetId = (String) response.get('budgetId');
        System.assertEquals(1, [SELECT COUNT() FROM Budget_Line_Item__c WHERE Budget__c = :newBudgetId]);
    }

    // ─── saveBudget: updates existing budget ─────────────────────────────────

    @IsTest
    static void testSaveBudget_UpdateExisting() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);
        Budget_Line_Item__c existing = createLineItem(budget.Id, '2024_01', 'No, still projected');

        BudgetDTO.SavePayload payload = new BudgetDTO.SavePayload();
        payload.contractId = contract.Id;
        payload.budgetId   = budget.Id;

        BudgetDTO.BudgetRates rates = new BudgetDTO.BudgetRates();
        rates.budgetStart      = budget.Budget_Period_Start_Date__c;
        rates.budgetEnd        = budget.Budget_Period_End_date__c;
        rates.fringeRate       = 30;
        rates.overheadRate     = 20;
        rates.gaRate           = 10;
        rates.customRate       = 0;
        rates.indirectCostType = 'Standard';
        rates.feePercentage    = 0;
        payload.rates = rates;

        // Update the existing line item (different units)
        BudgetDTO.BudgetRow row = new BudgetDTO.BudgetRow();
        row.lineItemId     = existing.Id;
        row.monthKey       = '2024_01';
        row.costCategory   = 'Employee';
        row.lockedStatus   = 'No, still projected';
        row.projectedUnits = 8;
        row.actualUnits    = 8;
        row.actualRate     = 400;
        payload.rows = new List<BudgetDTO.BudgetRow>{ row };

        Test.startTest();
        String result = BudgetController.saveBudget(JSON.serialize(payload));
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, response.get('success'), 'Update succeeded');

        Budget_Line_Item__c updated = [
            SELECT Projected_Units__c FROM Budget_Line_Item__c WHERE Id = :existing.Id
        ];
        System.assertEquals(8, updated.Projected_Units__c, 'Units updated to 8');
    }

    // ─── saveBudget: G&A cap tracked correctly across two rows ────────────────

    @IsTest
    static void testSaveBudget_GaCapApplied() {
        DContract__c contract = createContract();

        BudgetDTO.SavePayload payload = new BudgetDTO.SavePayload();
        payload.contractId = contract.Id;

        BudgetDTO.BudgetRates rates = new BudgetDTO.BudgetRates();
        rates.budgetStart      = Date.newInstance(2024, 1, 1);
        rates.budgetEnd        = Date.newInstance(2024, 3, 31);
        rates.fringeRate       = 0;
        rates.overheadRate     = 0;
        rates.gaRate           = 10;
        rates.customRate       = 0;
        rates.indirectCostType = 'Standard';
        rates.feePercentage    = 0;
        payload.rates = rates;

        // Create a real Agreement__c record so the lookup field can be set
        Agreement__c agree = new Agreement__c(Name = 'Test Agreement', P_O__c = 'PO-TEST-001');
        insert agree;

        // Two sub rows for the same agreement, $20k each — second should be capped
        BudgetDTO.BudgetRow sub1 = new BudgetDTO.BudgetRow();
        sub1.monthKey       = '2024_01';
        sub1.costCategory   = 'Subcontracts';
        sub1.agreementId    = agree.Id;
        sub1.lockedStatus   = 'No, still projected';
        sub1.projectedTotal = 20000;
        sub1.actualTotal    = 20000;

        BudgetDTO.BudgetRow sub2 = new BudgetDTO.BudgetRow();
        sub2.monthKey       = '2024_02';
        sub2.costCategory   = 'Subcontracts';
        sub2.agreementId    = agree.Id;
        sub2.lockedStatus   = 'No, still projected';
        sub2.projectedTotal = 15000;
        sub2.actualTotal    = 15000;

        payload.rows = new List<BudgetDTO.BudgetRow>{ sub2, sub1 }; // intentionally unsorted

        Test.startTest();
        String result = BudgetController.saveBudget(JSON.serialize(payload));
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, response.get('success'), 'Save succeeded');

        String budgetId = (String) response.get('budgetId');
        List<Budget_Line_Item__c> items = [
            SELECT Month_Key__c, Amount_to_Include_in_G_A__c
            FROM Budget_Line_Item__c
            WHERE Budget__c = :budgetId
            ORDER BY Month_Key__c ASC
        ];

        System.assertEquals(2, items.size(), 'Two sub rows saved');
        System.assertEquals(20000, items[0].Amount_to_Include_in_G_A__c, 'Jan: full $20k in G&A base');
        System.assertEquals(5000,  items[1].Amount_to_Include_in_G_A__c, 'Feb: only $5k remaining under cap');
    }

    // ─── saveBudget: invalid payload returns error ────────────────────────────

    @IsTest
    static void testSaveBudget_InvalidPayload() {
        Test.startTest();
        String result = BudgetController.saveBudget('{"contractId": null}');
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, response.get('success'), 'Error on missing contractId');
    }

    // ─── addEmployees: inserts rows for each month ────────────────────────────

    @IsTest
    static void testAddEmployees_InsertsOneRowPerMonth() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id); // Jan–Mar 2024 = 3 months

        // Create a minimal SFDC_Employee__c for the test
        SFDC_Employee__c emp = new SFDC_Employee__c(
            Name             = 'Test Employee',
            Exchange_Rate__c = 1
        );
        insert emp;

        Test.startTest();
        String result = BudgetController.addEmployees(
            budget.Id,
            JSON.serialize(new List<String>{ emp.Id })
        );
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, response.get('success'), 'addEmployees succeeded');

        List<Budget_Line_Item__c> inserted = [
            SELECT Month_Key__c, Actuals_Locked__c
            FROM Budget_Line_Item__c
            WHERE Budget__c = :budget.Id
            ORDER BY Month_Key__c ASC
        ];
        System.assertEquals(3, inserted.size(), 'One row per month (Jan, Feb, Mar)');
        System.assertEquals('2024_01', inserted[0].Month_Key__c);
        System.assertEquals('2024_02', inserted[1].Month_Key__c);
        System.assertEquals('2024_03', inserted[2].Month_Key__c);
        System.assertEquals('No, still projected', inserted[0].Actuals_Locked__c);
    }

    // ─── addEmployees: new rows inherit locked status from existing siblings ───

    @IsTest
    static void testAddEmployees_InheritsLockedMonths() {
        DContract__c contract = createContract();
        Budget__c budget = createBudget(contract.Id);

        // Lock January by creating an existing locked row
        createLineItem(budget.Id, '2024_01', 'Yes, actuals final');

        SFDC_Employee__c emp = new SFDC_Employee__c(Name = 'Test Employee 2', Exchange_Rate__c = 1);
        insert emp;

        Test.startTest();
        BudgetController.addEmployees(budget.Id, JSON.serialize(new List<String>{ emp.Id }));
        Test.stopTest();

        // The new employee's Jan row should inherit locked status
        List<Budget_Line_Item__c> empRows = [
            SELECT Month_Key__c, Actuals_Locked__c
            FROM Budget_Line_Item__c
            WHERE Budget__c = :budget.Id AND Employee__c = :emp.Id
            ORDER BY Month_Key__c ASC
        ];
        System.assertEquals('Yes, actuals final', empRows[0].Actuals_Locked__c,
            'Jan row inherits locked status');
        System.assertEquals('No, still projected', empRows[1].Actuals_Locked__c,
            'Feb row is unlocked');
    }

    // ─── addEmployees: missing budgetId returns error ─────────────────────────

    @IsTest
    static void testAddEmployees_MissingBudgetId() {
        Test.startTest();
        String result = BudgetController.addEmployees(null, '["someId"]');
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, response.get('success'), 'Error on missing budgetId');
    }

    // ─── generateMonthKeys: correct range ────────────────────────────────────

    @IsTest
    static void testLoadBudget_MonthColumnsMatchBudgetPeriod() {
        DContract__c contract = createContract(); // Jan–Mar 2024
        Budget__c budget = createBudget(contract.Id);

        Test.startTest();
        String result = BudgetController.loadBudget(contract.Id, budget.Id);
        Test.stopTest();

        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(result);
        List<Object> months = (List<Object>) response.get('months');

        System.assertEquals(3, months.size(), 'Jan–Mar = 3 months');
        System.assertEquals('2024_01', ((Map<String, Object>) months.get(0)).get('monthKey'));
        System.assertEquals('Jan 2024', ((Map<String, Object>) months.get(0)).get('label'));
        System.assertEquals('2024_03', ((Map<String, Object>) months.get(2)).get('monthKey'));
        System.assertEquals('Mar 2024', ((Map<String, Object>) months.get(2)).get('label'));
    }
}
