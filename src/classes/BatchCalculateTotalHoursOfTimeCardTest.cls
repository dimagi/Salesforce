@isTest
public class BatchCalculateTotalHoursOfTimeCardTest {

    @testSetup
    static void setup() {
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0, Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 2', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 22, Custom_2__c = 0, Custom_3__c = 0, Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
    }

    @isTest
    public static void shouldUpdateServicesSpend() {
        Test.startTest();

        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Sample Employee',
            Salary__c = 50000,
            Exchange_Rate__c = 1,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24),
            Per_Week_Hours__c = 40
        );
        insert employeeObj;

        DContract__c dcontract = new DContract__c(
            Name = 'Sample Test Name',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'No'
        );
        insert dcontract;

        Time_Card__c timeCardObj = new Time_Card__c(
            Total__c = 4,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = dcontract.Id
        );
        insert timeCardObj;
        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        BatchCalculateTotalHoursOfTimeCard batch1 = new BatchCalculateTotalHoursOfTimeCard(new Set<Id> {dcontract.Id}, true);
        Database.QueryLocatorIterator iter = batch1.start(null).iterator();
        List<sObject> testData = new List<sObject>();
        while (iter.hasNext()) {
            testData.add(iter.next());
        }

        batch1.execute(null, testData);
        BatchUpdateContractServicesSpend batch2 = new BatchUpdateContractServicesSpend(batch1.getServicesSpendMap());
        batch2.execute(null, batch2.start(null));

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: dcontract.Id];
        System.assertEquals(229.90, dcontractFromDB.Services_Spend__c);
    }

    @isTest
    static void shouldUpdateParentServicesSpend() {
        Test.startTest();
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Sample Employee',
            Salary__c = 50000,
            Exchange_Rate__c = 1,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24),
            Per_Week_Hours__c = 40
        );
        insert employeeObj;

        DContract__c parent = new DContract__c(
            Name = 'Sample Parent',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'No'
        );
        insert parent;

        DContract__c child1 = new DContract__c(
            Name = 'Sample Child 1',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'Yes',
            Parent_Contract__c = parent.Id
        );
        insert child1;

        DContract__c child2 = new DContract__c(
            Name = 'Sample Child 2',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'Yes',
            Parent_Contract__c = parent.Id
        );
        insert child2;

        Time_Card__c timeCardObj1 = new Time_Card__c(
            Total__c = 4,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = child1.Id
        );
        insert timeCardObj1;

        Time_Card__c timeCardObj2 = new Time_Card__c(
            Total__c = 8,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = child2.Id
        );
        insert timeCardObj2;
        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        BatchCalculateTotalHoursOfTimeCard batch1 = new BatchCalculateTotalHoursOfTimeCard();
        Database.QueryLocatorIterator iter = batch1.start(null).iterator();
        List<sObject> testData = new List<sObject>();
        while (iter.hasNext()) {
            testData.add(iter.next());
        }

        System.debug('testData ' + testData);
        batch1.execute(null, testData);
        BatchUpdateContractServicesSpend batch2 = new BatchUpdateContractServicesSpend(batch1.getServicesSpendMap());
        batch2.execute(null, batch2.start(null));

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent.Id];
        System.assertEquals(689.70, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child1.Id];
        System.assertEquals(229.90, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child2.Id];
        System.assertEquals(459.80, dcontractFromDB.Services_Spend__c);
    }

    @isTest
    static void shouldUpdateServicesSpendInManyContracts() {
        Test.startTest();
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Sample Employee',
            Salary__c = 50000,
            Exchange_Rate__c = 1,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24),
            Per_Week_Hours__c = 40
        );
        insert employeeObj;

        DContract__c parent1 = new DContract__c(
            Name = 'Sample Parent',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'No'
        );
        insert parent1;

        DContract__c child1 = new DContract__c(
            Name = 'Sample Child 1',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'Yes',
            Parent_Contract__c = parent1.Id
        );
        insert child1;

        DContract__c child2 = new DContract__c(
            Name = 'Sample Child 2',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'Yes',
            Parent_Contract__c = parent1.Id
        );
        insert child2;

        DContract__c parent2 = new DContract__c(
            Name = 'Sample Parent',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'No'
        );
        insert parent2;

        DContract__c child3 = new DContract__c(
            Name = 'Sample Child 1',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'Yes',
            Parent_Contract__c = parent2.Id
        );
        insert child3;

        DContract__c child4 = new DContract__c(
            Name = 'Sample Child 2',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'Yes',
            Parent_Contract__c = parent2.Id
        );
        insert child4;

        Time_Card__c timeCardObj1 = new Time_Card__c(
            Total__c = 8,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = child1.Id
        );
        insert timeCardObj1;

        Time_Card__c timeCardObj2 = new Time_Card__c(
            Total__c = 4,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = parent1.Id
        );
        insert timeCardObj2;

        Time_Card__c timeCardObj3 = new Time_Card__c(
            Total__c = 10,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = child3.Id
        );
        insert timeCardObj3;

        Time_Card__c timeCardObj4 = new Time_Card__c(
            Total__c = 8,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = child4.Id
        );
        insert timeCardObj4;
        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        Set<Id> ids = new Set<Id>();
        ids.add(child4.Id);
        ids.add(parent1.Id);

        BatchCalculateTotalHoursOfTimeCard batch1 = new BatchCalculateTotalHoursOfTimeCard();
        Database.QueryLocatorIterator iter = batch1.start(null).iterator();
        List<sObject> testData = new List<sObject>();
        while (iter.hasNext()) {
            testData.add(iter.next());
        }

        batch1.execute(null, testData);
        BatchUpdateContractServicesSpend batch2 = new BatchUpdateContractServicesSpend(batch1.getServicesSpendMap());
        batch2.execute(null, batch2.start(null));

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent1.Id];
        System.assertEquals(689.70, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child1.Id];
        System.assertEquals(459.80, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child2.Id];
        System.assertEquals(null, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent2.Id];
        System.assertEquals(1034.55, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child3.Id];
        System.assertEquals(574.75, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child4.Id];
        System.assertEquals(459.80, dcontractFromDB.Services_Spend__c);
    }

    @isTest
    public static void triggerShouldUpdateRates() {
        Test.startTest();
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Sample Employee',
            Salary__c = 50000,
            Exchange_Rate__c = 1,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24),
            Per_Week_Hours__c = 40
        );
        insert employeeObj;

        DContract__c parent = new DContract__c(
            Name = 'Sample Parent',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'No'
        );
        insert parent;

        DContract__c child1 = new DContract__c(
            Name = 'Sample Child 1',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'Yes',
            Parent_Contract__c = parent.Id
        );
        insert child1;

        DContract__c child2 = new DContract__c(
            Name = 'Sample Child 2',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'Yes',
            Parent_Contract__c = parent.Id
        );
        insert child2;

        Time_Card__c timeCardObj1 = new Time_Card__c(
            Total__c = 4,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = child1.Id
        );
        insert timeCardObj1;

        Time_Card__c timeCardObj2 = new Time_Card__c(
            Total__c = 8,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = child2.Id
        );
        insert timeCardObj2;

        DContract__c toUpdate = [SELECT Id, Project_Billing_Rate__c FROM DContract__c WHERE Id =: child1.Id];
        toUpdate.Project_Billing_Rate__c = 'Loaded Daily Rate 2';
        update toUpdate;
        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        // we must manually run Batch job from finish method, not sure why this is not working in tests
        BatchCalculateTotalHoursOfTimeCard batch1 = new BatchCalculateTotalHoursOfTimeCard(new Set<Id> {toUpdate.Id});
        Database.QueryLocatorIterator iter = batch1.start(null).iterator();
        List<sObject> testData = new List<sObject>();
        while (iter.hasNext()) {
            testData.add(iter.next());
        }

        System.debug('testData ' + testData);
        batch1.execute(null, testData);
        BatchUpdateContractServicesSpend batch2 = new BatchUpdateContractServicesSpend(batch1.getServicesSpendMap());
        batch2.execute(null, batch2.start(null));

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent.Id];
        System.assertEquals(740.28, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child1.Id];
        System.assertEquals(280.48, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child2.Id];
        System.assertEquals(459.80, dcontractFromDB.Services_Spend__c);
    }

    @isTest
    public static void shouldRemoveOnlyDuplicatedTimeCards() {
        SFDC_Employee__c employeeObj1 = new SFDC_Employee__c(
            name = 'Sample Employee',
            Salary__c = 50000,
            Exchange_Rate__c = 1,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24),
            Per_Week_Hours__c = 40
        );
        insert employeeObj1;
        DContract__c dcontract1 = new DContract__c(
            Name = 'Sample Test Name',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'No'
        );
        insert dcontract1;
        SFDC_Employee__c employeeObj2 = new SFDC_Employee__c(
            name = 'Sample Employee',
            Salary__c = 50000,
            Exchange_Rate__c = 1,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24)
        );
        insert employeeObj2;
        DContract__c dcontract2 = new DContract__c(
            Name = 'Sample Test Name',
            Status__c = 'Active',
            Requires_Report_Out__c = 'No',
            Intracompany_Sub_contract__c = 'No'
        );
        insert dcontract2;

        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,1), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 1'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,1), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 1'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 1'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 3'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 3'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj1.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 3'); // remove

        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,1), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 1'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,1), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 1'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 1'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj2.Id, Client__c = dcontract1.Id, Case__c = 'Test Case 2'); // remove

        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,1), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 4'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,1), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 5'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 6'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 6'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 6'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 4'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,2), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 4'); // remove
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 4'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 5'); // ok
        insert new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2017, 3 ,3), Employee__c = employeeObj1.Id, Client__c = dcontract2.Id, Case__c = 'Test Case 5'); // remove

        Test.startTest();

        RemoveDuplicatedTimeCardsBatch obj = new RemoveDuplicatedTimeCardsBatch(Date.newInstance(2017, 3, 1), Date.newInstance(2017, 3, 31));
        Database.executeBatch(obj, 50);

        Test.stopTest();

        List<Time_Card__c> allTimeCards = [SELECT Id FROM Time_Card__c];
        System.assertEquals(16, allTimeCards.size());
        List<Time_Card__c> timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 1) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 1'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 1) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 2'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 2) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 1'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 2) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 2'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 3) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 3'];
        System.assertEquals(1, timeCards.size());

        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 1) AND Employee__c =: employeeObj2.Id AND Case__c = 'Test Case 1'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 1) AND Employee__c =: employeeObj2.Id AND Case__c = 'Test Case 2'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 2) AND Employee__c =: employeeObj2.Id AND Case__c = 'Test Case 1'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 2) AND Employee__c =: employeeObj2.Id AND Case__c = 'Test Case 2'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 3) AND Employee__c =: employeeObj2.Id AND Case__c = 'Test Case 2'];
        System.assertEquals(1, timeCards.size());

        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 1) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 4'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 1) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 5'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 2) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 6'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 2) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 4'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 3) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 4'];
        System.assertEquals(1, timeCards.size());
        timeCards = [SELECT Id FROM Time_Card__c WHERE Date__c =: Date.newInstance(2017, 3, 3) AND Employee__c =: employeeObj1.Id AND Case__c = 'Test Case 5'];
        System.assertEquals(1, timeCards.size());
    }
}