/**
 * setup_tmtracker_test_data.apex
 *
 * Run in tmtracker Developer Console:
 *   Setup → Developer Console → Debug → Open Execute Anonymous Window → paste → Execute
 *
 * After running, look for the "OPEN PAGE:" line in the debug log output
 * (filter by "USER_DEBUG" in the log view).
 *
 * Reference scenario (matches SPEC.md manual verification):
 *   Employee A: 10 days × $500/day = $5,000 salary
 *   Fringe 30%:   $1,500
 *   Overhead 20%: $1,300  (on $5,000 + $1,500)
 *   G&A 10%:      $650    (on $5,000 + $1,500)
 *   Grand Total:  $8,450
 */

// ── 1. Find or create an active employee ─────────────────────────────────────

SFDC_Employee__c emp;
List<SFDC_Employee__c> existingEmps = [
    SELECT Id, Name, Employee_Type__c, Loaded_Daily_Rate__c
    FROM SFDC_Employee__c
    WHERE Employee_Status__c = 'Active'
    ORDER BY Name ASC
    LIMIT 1
];

if (!existingEmps.isEmpty()) {
    emp = existingEmps[0];
    System.debug('Using existing employee: ' + emp.Name + ' (Id: ' + emp.Id + ')');
} else {
    // Fall back to creating a placeholder employee
    emp = new SFDC_Employee__c(
        Name             = 'Test Employee (Budget Setup)',
        Employee_Status__c = 'Active',
        Exchange_Rate__c = 1,
        Employee_Type__c = 'Employee'
    );
    insert emp;
    System.debug('Created placeholder employee: ' + emp.Id);
}

// ── 2. Create contract ────────────────────────────────────────────────────────

DContract__c contract = new DContract__c(
    Name                    = 'TEST — T&M Budget Reference Scenario',
    Contract_Start_Date__c  = Date.newInstance(2024, 1, 1),
    Contract_End_Date__c    = Date.newInstance(2024, 12, 31),
    Total_Amount_of_Contract__c = 100000
);
insert contract;
System.debug('Created contract: ' + contract.Id);

// ── 3. Create budget with reference scenario rates ────────────────────────────

Budget__c budget = new Budget__c(
    Contract__c                 = contract.Id,
    Budget_Period_Start_Date__c = Date.newInstance(2024, 1, 1),
    Budget_Period_End_date__c   = Date.newInstance(2024, 3, 31),  // Jan–Mar for demo
    Fringe_Benefit_Rate__c      = 30,   // 30%
    Overhead_Rate__c            = 20,   // 20%
    G_A_Rate__c                 = 10,   // 10%
    Custom_Indirect_Cost_Rate__c = 0,
    Indirect_Cost_Type__c       = 'Standard',
    Fee_Percentage__c           = 0
);
insert budget;
System.debug('Created budget: ' + budget.Id);

// ── 4. Create line items — reference scenario employee across Jan–Mar ─────────
//    Jan: 10 days × $500/day  →  actual total $5,000 → expected grand total $8,450
//    Feb: 8 days × $500/day   →  unlocked
//    Mar: 5 days × $500/day   →  unlocked

List<Budget_Line_Item__c> items = new List<Budget_Line_Item__c>();

// January — locked (to test "Billed to Date" calculation)
items.add(new Budget_Line_Item__c(
    Budget__c            = budget.Id,
    Employee__c          = emp.Id,
    Cost_Category__c     = 'Employee',
    Month_Key__c         = '2024_01',
    Actuals_Locked__c    = 'Yes, actuals final',
    Projected_Units__c   = 10,
    Actual_Units__c      = 10,
    Actual_Daily_Rate__c = 500,
    Amount_to_Include_in_G_A__c = 0  // n/a for employees — formula uses salary+fringe
));

// February — unlocked projected
items.add(new Budget_Line_Item__c(
    Budget__c            = budget.Id,
    Employee__c          = emp.Id,
    Cost_Category__c     = 'Employee',
    Month_Key__c         = '2024_02',
    Actuals_Locked__c    = 'No, still projected',
    Projected_Units__c   = 8,
    Actual_Units__c      = 0,
    Actual_Daily_Rate__c = 500,
    Amount_to_Include_in_G_A__c = 0
));

// March — unlocked projected
items.add(new Budget_Line_Item__c(
    Budget__c            = budget.Id,
    Employee__c          = emp.Id,
    Cost_Category__c     = 'Employee',
    Month_Key__c         = '2024_03',
    Actuals_Locked__c    = 'No, still projected',
    Projected_Units__c   = 5,
    Actual_Units__c      = 0,
    Actual_Daily_Rate__c = 500,
    Amount_to_Include_in_G_A__c = 0
));

insert items;
System.debug('Created ' + items.size() + ' line items');

// ── 5. Print the page URL ─────────────────────────────────────────────────────

String pageUrl = '/apex/TmBudgetEditor?contractId=' + contract.Id
    + '&budgetId=' + budget.Id;

System.debug('OPEN PAGE: https://dimagi--tmtracker.sandbox.lightning.force.com' + pageUrl);
System.debug('Contract Id: ' + contract.Id);
System.debug('Budget Id:   ' + budget.Id);
System.debug('Employee:    ' + emp.Name + ' (' + emp.Id + ')');
System.debug('');
System.debug('Expected Jan totals (reference scenario):');
System.debug('  Salary:   $5,000  (10 days x $500)');
System.debug('  Fringe:   $1,500  (30% of $5,000)');
System.debug('  Overhead: $1,300  (20% of $6,500)');
System.debug('  G&A:      $650    (10% of $6,500)');
System.debug('  Total:    $8,450');
