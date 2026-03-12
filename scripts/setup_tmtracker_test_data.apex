/**
 * setup_tmtracker_test_data.apex
 *
 * Run from terminal:
 *   sf apex run --file scripts/setup_tmtracker_test_data.apex --target-org tmtracker
 *
 * After running, the URL is printed at the end of the output.
 *
 * Reference scenario (matches SPEC.md manual verification):
 *   Employee A: 10 days × $500/day = $5,000 salary
 *   Fringe 30%:   $1,500
 *   Overhead 20%: $1,300  (on $5,000 + $1,500)
 *   G&A 10%:      $650    (on $5,000 + $1,500)
 *   Grand Total:  $8,450
 */

// ── 1. Find an active employee ────────────────────────────────────────────────

List<SFDC_Employee__c> existingEmps = [
    SELECT Id, Name, Employee_Type__c, Loaded_Daily_Rate__c
    FROM SFDC_Employee__c
    WHERE Employee_Status__c = 'Active'
    ORDER BY Name ASC
    LIMIT 1
];

if (existingEmps.isEmpty()) {
    System.debug('ERROR: No active employees found in tmtracker. ' +
        'Add at least one SFDC_Employee__c with Employee_Status__c = \'Active\' first.');
    return;
}
SFDC_Employee__c emp = existingEmps[0];
System.debug('Using employee: ' + emp.Name + ' (' + emp.Id + ')');

// ── 2. Create contract ────────────────────────────────────────────────────────

DContract__c contract = new DContract__c(
    Name                   = 'TEST — T&M Budget Reference Scenario',
    Contract_Start_Date__c = Date.newInstance(2024, 1, 1),
    Contract_End_Date__c   = Date.newInstance(2024, 12, 31)
);
insert contract;
System.debug('Created contract: ' + contract.Id);

// ── 3. Build save payload — uses BudgetController to avoid direct field refs ──
//    Jan: locked  — 10 days × $500  → expected grand total $8,450
//    Feb: unlocked — 8 days × $500
//    Mar: unlocked — 5 days × $500

BudgetDTO.BudgetRates rates = new BudgetDTO.BudgetRates();
rates.budgetStart      = Date.newInstance(2024, 1, 1);
rates.budgetEnd        = Date.newInstance(2024, 3, 31);
rates.fringeRate       = 30;
rates.overheadRate     = 20;
rates.gaRate           = 10;
rates.customRate       = 0;
rates.indirectCostType = 'Standard';
rates.feePercentage    = 0;

List<BudgetDTO.BudgetRow> rows = new List<BudgetDTO.BudgetRow>();

// January — locked actuals
BudgetDTO.BudgetRow jan = new BudgetDTO.BudgetRow();
jan.monthKey       = '2024_01';
jan.costCategory   = 'Employee';
jan.employeeId     = emp.Id;
jan.lockedStatus   = 'Yes, actuals final';
jan.projectedUnits = 10;
jan.actualUnits    = 10;
jan.actualRate     = 500;
rows.add(jan);

// February — unlocked
BudgetDTO.BudgetRow feb = new BudgetDTO.BudgetRow();
feb.monthKey       = '2024_02';
feb.costCategory   = 'Employee';
feb.employeeId     = emp.Id;
feb.lockedStatus   = 'No, still projected';
feb.projectedUnits = 8;
feb.actualUnits    = 0;
feb.actualRate     = 0;
rows.add(feb);

// March — unlocked
BudgetDTO.BudgetRow mar = new BudgetDTO.BudgetRow();
mar.monthKey       = '2024_03';
mar.costCategory   = 'Employee';
mar.employeeId     = emp.Id;
mar.lockedStatus   = 'No, still projected';
mar.projectedUnits = 5;
mar.actualUnits    = 0;
mar.actualRate     = 0;
rows.add(mar);

BudgetDTO.SavePayload payload = new BudgetDTO.SavePayload();
payload.contractId = contract.Id;
payload.rates      = rates;
payload.rows       = rows;

// ── 4. Save via controller ────────────────────────────────────────────────────

String saveResult = BudgetController.saveBudget(JSON.serialize(payload));
Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(saveResult);

if (response.get('success') != true) {
    System.debug('ERROR saving budget: ' + response.get('message'));
    return;
}

String budgetId = (String) response.get('budgetId');
System.debug('Created budget: ' + budgetId);

// ── 5. Print the URL ──────────────────────────────────────────────────────────

System.debug('');
System.debug('======================================================');
System.debug('OPEN THIS URL IN TMTRACKER:');
System.debug('https://dimagi--tmtracker.sandbox.lightning.force.com/apex/TmBudgetEditor?contractId=' + contract.Id + '&budgetId=' + budgetId);
System.debug('======================================================');
System.debug('');
System.debug('Expected Jan totals (reference scenario):');
System.debug('  Salary:   $5,000  (10 days x $500)');
System.debug('  Fringe:   $1,500  (30% of $5,000)');
System.debug('  Overhead: $1,300  (20% of $6,500)');
System.debug('  G&A:      $650    (10% of $6,500)');
System.debug('  Grand Total: $8,450');
