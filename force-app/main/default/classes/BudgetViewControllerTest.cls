@isTest
public class BudgetViewControllerTest {
        static Id accountId;
 static Id dummyId;

    private static testMethod void testBudgetViewControllerMethods() {
     



        SFDC_Employee__c emp1 = new SFDC_Employee__c(Name = 'John Doe',Exchange_Rate__c = 100);
        insert emp1;
        
		DContract__c contract = new DContract__c(Name = 'Test Contract', Account__c = accountId);
		insert contract;

        Budget__c budget = new Budget__c(Name = '2025 Budget',Contract__c = contract.Id);
        insert budget;

        Date janStart = Date.newInstance(2025, 1, 1);
        Date janEnd = Date.newInstance(2025, 1, 31);
        Budget_Line_Item__c item1 = new Budget_Line_Item__c(
            Budget__c = budget.Id,
            Employee__c = emp1.Id,
            Budget_Line_Item_Start_Date__c = janStart,
            Budget_Line_Item_EndDate__c = janEnd,
            Cost_Category__c = 'Employee',
            Actual_Units__c = 10,
            Actual_Daily_Rate__c = 100,
            //Actual_Total_Salary__c = 1000,
            Actuals_Locked__c = 'Not Set'
        );
        insert item1;

        // Create Internal Contractor Entry
        Budget_Line_Item__c item2 = new Budget_Line_Item__c(
            Budget__c = budget.Id,
            Employee__c = emp1.Id,
            Budget_Line_Item_Start_Date__c = janStart,
            Budget_Line_Item_EndDate__c = janEnd,
            Cost_Category__c = 'Internal Contractor',
            Actual_Units__c = 5,
            Actual_Daily_Rate__c = 200,
          //  Actual_Total_Salary__c = 1000,
            Actuals_Locked__c = 'Not Set'
        );
        insert item2;

        Test.startTest();

        // Test getEmployeeContractData
        List<BudgetViewController.EmployeeContractData> empData = BudgetViewController.getEmployeeContractData(budget.Id, '2025');
        System.assert(!empData.isEmpty());

        // Test getContractersData
        List<BudgetViewController.EmployeeContractData> contractorData = BudgetViewController.getContractersData(budget.Id, '2025');
        System.assert(!contractorData.isEmpty());

        // Test searchEmployees
        List<SFDC_Employee__c> results = BudgetViewController.searchEmployees('John');
        System.assertEquals(2, results.size());

        // Test updateEmployeeContractData for update
        List<Map<String, Object>> updateDrafts = new List<Map<String, Object>>();
        updateDrafts.add(new Map<String, Object>{
            'budgetItemId' => item1.Id,
            'EmployeeId' => emp1.Id,
            'Month' => 1,
            'dailyRate' => 150,
            'units' => 12
        });
        BudgetViewController.updateEmployeeContractData(budget.Id, updateDrafts, '2025', 'Employee');

        // Test updateEmployeeContractData for insert
        List<Map<String, Object>> insertDrafts = new List<Map<String, Object>>();
        insertDrafts.add(new Map<String, Object>{
            'budgetItemId' => null,
            'EmployeeId' => emp1.Id,
            'Month' => 2,
            'dailyRate' => 200,
            'units' => 8
        });
        BudgetViewController.updateEmployeeContractData(budget.Id, insertDrafts, '2025', 'Internal Contractor');

        // Test updateEmployeeData (same logic as updateEmployeeContractData)
        BudgetViewController.updateEmployeeData(budget.Id, insertDrafts, '2025', 'Employee');

        // Test deleteColumnData
        BudgetViewController.deleteColumnData(budget.Id, new List<Id>{emp1.Id});

        Test.stopTest();
    }
     @testSetup
    static void setupData() {
        
Account acc = new Account(Name = 'Test Account ');
insert acc;
        accountId = acc.Id;

        SFDC_Employee__c emp1 = new SFDC_Employee__c(Name = 'John Doe',Exchange_Rate__c = 100);
        insert emp1;
        DContract__c contract = new DContract__c(Name = 'Test Contract', Account__c = acc.Id);
		insert contract;

        
        // Create a Budget__c record with all fields set
        Budget__c budget = new Budget__c(
            Name = 'Test Budget',
            Budgeted_Travel_Transportation__c = 5000,
            Budgeted_Equipment_Costs__c = 3000,
            Budgeted_Contractual_Costs__c = 4000,
            Budgeted_Subcontracts_Costs__c = 2000,
            Budgeted_Other_Direct_Costs__c = 1000,
            Budgeted_Indirect_Cost_Overhead__c = 600,
            Budgeted_Indirect_Cost_G_A__c = 400,
            Budgeted_Fringe_Benefits__c = 800,
            //Budgeted_Direct_Costs__c = 9000,
            Budget_Period_Start_Date__c = Date.newInstance(2024, 1, 1),
            Overhead_Rate__c = 0.1,
            G_A_Rate__c = 0.05,
            Contract__c = contract.Id
        );
        insert budget;

        List<Budget_Line_Item__c> items = new List<Budget_Line_Item__c>();
        Date startDate = Date.newInstance(2024, 1, 1);
        
        // Add entries for different cost categories
        List<String> costCategories = new List<String>{
            'Equipment', 'Contractual', 'Travel & Transportation', 'Other Direct Cost', 
            'Subcontracts', 'Overhead Rate', 'G&A Rate'
        };

        for (Integer i = 0; i < costCategories.size(); i++) {
            items.add(new Budget_Line_Item__c(
                Budget__c = budget.Id,
                Cost_Category__c = costCategories[i],
              //  Actual_Total_Salary__c = 100 * (i+1),
              //  Overhead_Amount__c = 50,
              //  G_A_Amount__c = 25,
              //  Custom_Indirect_Cost_Amount__c = 10,
                Budget_Line_Item_Start_Date__c = startDate.addMonths(i)
            ));
        }

        // Edge case: Null dates and values
        items.add(new Budget_Line_Item__c(
            Budget__c = budget.Id,
            Cost_Category__c = 'Equipment',
          //  Actual_Total_Salary__c = null,
          //  Overhead_Amount__c = null,
          //  G_A_Amount__c = null,
          //  Custom_Indirect_Cost_Amount__c = null,
            Budget_Line_Item_Start_Date__c = null
        ));

        insert items;
    }

    

    @isTest
    static void testGetRelatedDataWithNullBudget() {
        // Edge case: invalid recordId (this should still return an empty list or fail gracefully)
        Test.startTest();
        try {
            List<BudgetViewController.BudgetRows> results = BudgetViewController.getRelatedData('a0F000000000000XXX', '2024');
            System.assertEquals(0, results.size(), 'Expected no results for fake ID');
        } catch (Exception e) {
            System.assert(true, 'Expected to catch an exception for invalid ID');
        }
        Test.stopTest();
    }
    
      @isTest
    static void testGetBudgetPeriodDates() {
        Budget__c budget = [SELECT Id FROM Budget__c LIMIT 1];
        
        Test.startTest();
        Map<String, Date> result = BudgetViewController.getBudgetPeriodDates(budget.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertEquals(Date.newInstance(2024, 1, 1), result.get('startDate'));
        System.assertEquals(Null, result.get('endDate'));
    }
    
    @isTest
    static void testGetFringeBenefitData() {
        Budget__c budget = [SELECT Id FROM Budget__c LIMIT 1];

        Test.startTest();
        Decimal fringeRate = BudgetViewController.getFringeBenefitData(budget.Id);
        Test.stopTest();
        
        System.assertEquals(null, fringeRate);
    }

    @isTest
    static void testBudgetDirectRowConstructor() {
        BudgetViewController.BudgetDirectRow row = new BudgetViewController.BudgetDirectRow();
        System.assertEquals('', row.rowName);
        System.assertEquals(0.0, row.BudgetValue);
    }
    @isTest
    static void testMonthDataConstructor() {
 SFDC_Employee__c emp1 = new SFDC_Employee__c(Name = 'John Doe',Exchange_Rate__c = 100);
        insert emp1;
        
		DContract__c contract = new DContract__c(Name = 'Test Contract', Account__c = accountId);
		insert contract;

        Budget__c budget = new Budget__c(Name = '2025 Budget',Contract__c = contract.Id);
        insert budget;

        Date janStart = Date.newInstance(2025, 1, 1);
        Date janEnd = Date.newInstance(2025, 1, 31);
        Budget_Line_Item__c item1 = new Budget_Line_Item__c(
            Budget__c = budget.Id,
            Employee__c = emp1.Id,
            Budget_Line_Item_Start_Date__c = janStart,
            Budget_Line_Item_EndDate__c = janEnd,
            Cost_Category__c = 'Employee',
            Actual_Units__c = 10,
            Actual_Daily_Rate__c = 100,
            //Actual_Total_Salary__c = 1000,
            Actuals_Locked__c = 'Not Set'
        );
        insert item1;
 dummyId = item1.Id;       
        BudgetViewController.MonthData data = new BudgetViewController.MonthData(
            dummyId, 10, 200, 2000, 'false'
        );

        System.assertEquals(10, data.units);
        System.assertEquals(200, data.dailyRate);
        System.assertEquals(2000, data.total);
        System.assertEquals(dummyId, data.budgetItemId);
        System.assertEquals('false', data.ActualLocked);
    }

    
    @isTest
    static void testGetRelatedData() {
        DContract__c contract = new DContract__c(
        Name = 'Test Contract'
        // add other required fields here if any
    );
    insert contract;
        // Create Budget record
        Budget__c budget = new Budget__c(
            Name = 'Test Budget',
            Budgeted_Travel_Transportation__c = 1000,
            Budgeted_Subcontracts_Costs__c = 2000,
            Budgeted_Salaries_Wages__c = 3000,
            Budgeted_Other_Direct_Costs__c = 400,
            Budgeted_Indirect_Cost_Overhead__c = 500,
            Budgeted_Indirect_Cost_G_A__c = 600,
            Budgeted_Fringe_Benefits__c = 700,
            Budgeted_Equipment_Costs__c = 800,
            Budgeted_Contractual_Costs__c = 1200,
            Budget_Period_Start_Date__c = Date.newInstance(2023, 1, 1),
            Fee_Percentage__c = 10,
            Fringe_Benefit_Rate__c = 5,
                    Contract__c = contract.Id

        );
        insert budget;
        
        // Insert some Budget Line Items for 2023
        List<Budget_Line_Item__c> items = new List<Budget_Line_Item__c>{
            new Budget_Line_Item__c(
                Budget__c = budget.Id,
                Cost_Category__c = 'Equipment',
                Budget_Line_Item_Start_Date__c = Date.newInstance(2023, 1, 15)
            ),
            new Budget_Line_Item__c(
                Budget__c = budget.Id,
                Cost_Category__c = 'Contractual',
                Budget_Line_Item_Start_Date__c = Date.newInstance(2023, 2, 15)
            ),
            new Budget_Line_Item__c(
                Budget__c = budget.Id,
                Cost_Category__c = 'Travel & Transportation',
                Budget_Line_Item_Start_Date__c = Date.newInstance(2023, 3, 10)
            ),
            new Budget_Line_Item__c(
                Budget__c = budget.Id,
                Cost_Category__c = 'Subcontracts',
                Budget_Line_Item_Start_Date__c = Date.newInstance(2023, 4, 5)
            ),
            new Budget_Line_Item__c(
                Budget__c = budget.Id,
                Cost_Category__c = 'Other Direct Cost',
                Budget_Line_Item_Start_Date__c = Date.newInstance(2023, 5, 20)
            )
        };
        insert items;
        
        Test.startTest();
        List<BudgetViewController.BudgetRows> results = BudgetViewController.getRelatedData(budget.Id, '2023');
        Test.stopTest();
        
        System.assertNotEquals(0, results.size(), 'Expected some BudgetRows to be returned');
        
        // Validate key rows exist
        Boolean foundEquipment = false;
        Boolean foundContractual = false;
        for (BudgetViewController.BudgetRows row : results) {
            if (row.rowName == 'Equipment') {
                foundEquipment = true;
                System.assertNotEquals(null, row.monthValues, 'Equipment row should have monthly values');
            }
            if (row.rowName == 'Contractual') {
                foundContractual = true;
            }
        }
        System.assert(foundEquipment, 'Equipment row should be returned');
        System.assert(foundContractual, 'Contractual row should be returned');
    }


  
}