@isTest
public class TimeCardTriggerControllerTest {

    @testSetup
    public static void addTestData() {
        BatchDefaultSettings__c batchSettings = BatchDefaultSettings__c.getOrgDefaults();
        insert batchSettings;

        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj;

        DContract__c parent1 = new DContract__c(Name = 'Sample Parent 1', Services_Spend__c = 400, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No', FB_Id__c = 111);
        insert parent1;

        DContract__c child1 = new DContract__c(Name = 'Sample Child 1',  Services_Spend__c = 100, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child1;

        DContract__c child2 = new DContract__c(Name = 'Sample Child 2',  Services_Spend__c = 100, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child2;

        DContract__c parent2 = new DContract__c(Name = 'Sample Parent 2', Services_Spend__c = 500, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent2;

        DContract__c child3 = new DContract__c(Name = 'Sample Child 3', Services_Spend__c = 200, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', FB_Id__c = 222, Parent_Contract__c = parent2.Id);
        insert child3;

        DContract__c child4 = new DContract__c(Name = 'Sample Child 4', Services_Spend__c = 150, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent2.Id);
        insert child4;

        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);

        insert new Project_Billing_Rate__c(Name = 'Test Daily Rate', Date__c = Date.newInstance(2018, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 10, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Test Daily Rate', Date__c = Date.newInstance(2018, 01, 20), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 20, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Test Daily Rate', Date__c = Date.newInstance(2018, 03, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
    }

    @isTest
    public static void shouldMarkContractsToRefreshAfterTimeCardDelete() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child3 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 3'];
        DContract__c child4 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 4'];
        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 1.0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 2.0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 3.0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child3.Id);
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 4.0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child4.Id);

        List<Time_Card__c> timeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3, timeCardObj4};
        insert timeCards;

        List<DContract__c> toUpdate = new List<DContract__c>();
        for (DContract__c dContract : [SELECT Id, Services_Spend__c, Require_Services_Spend_Refresh__c FROM DContract__c]) {
            dContract.Require_Services_Spend_Refresh__c = false;
            toUpdate.add(dContract);
        }
        update toUpdate;

        Test.startTest();
        delete timeCards;
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        System.assertEquals(true, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Parent 2'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        System.assertEquals(true, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Child 2'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Child 3'];
        System.assertEquals(true, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Child 4'];
        System.assertEquals(true, dcontractFromDB.Require_Services_Spend_Refresh__c);
    }

    @isTest
    public static void shouldUpdateServicesSpendAfterTimeCardDelete() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child3 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 3'];
        DContract__c child4 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 4'];
        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 1.0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 2.0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 3.0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child3.Id);
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 4.0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child4.Id);
        List<Time_Card__c> timeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3, timeCardObj4};
        insert timeCards;

        List<DContract__c> toUpdate = new List<DContract__c>();
        for (DContract__c dContract : [SELECT Id, Services_Spend__c, Require_Services_Spend_Refresh__c FROM DContract__c]) {
            dContract.Require_Services_Spend_Refresh__c = false;
            dContract.Services_Spend__c = 12345;
            toUpdate.add(dContract);
        }
        update toUpdate;

        Test.startTest();
        delete timeCards;
        Database.executeBatch(new TimeCardCalculator());
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        System.assertEquals(0, dcontractFromDB.Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 2'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        System.assertEquals(0, dcontractFromDB.Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        System.assertEquals(0, dcontractFromDB.Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        System.assertEquals(0, dcontractFromDB.Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 3'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        System.assertEquals(0, dcontractFromDB.Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 4'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        System.assertEquals(0, dcontractFromDB.Services_Spend__c);
    }


    @isTest
    public static void shouldCalcualteTimeCardCostForGivenContractIds() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child2 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 2'];

        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child2.Id);

        List<Time_Card__c> timeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3, timeCardObj4};
        insert timeCards;

        Test.startTest();
        Database.executeBatch(new TimeCardCalculator(new Set<Id> { child1.Id }), 200);
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        System.assertEquals(1724.25, dcontractFromDB.Services_Spend__c); // (30 * (1.1 * 1.1 * 1.3 * 1.52) * ((50000 / 260.0) / 8.0))
        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        System.assertEquals(1034.55, dcontractFromDB.Services_Spend__c); // (18 * (1.1 * 1.1 * 1.3 * 1.52) * ((50000 / 260.0) / 8.0))
        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];
        System.assertEquals(459.80, dcontractFromDB.Services_Spend__c); // (8 * (1.1 * 1.1 * 1.3 * 1.52) * ((50000 / 260.0) / 8.0))
    }

    @isTest
    public static void shouldUseEmployeeSnapshotForCalculations() {
        DContract__c parent1 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child2 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];

        parent1.Project_Billing_Rate__c = 'Test Daily Rate';
        child1.Project_Billing_Rate__c = 'Test Daily Rate';
        update parent1;
        update child1;
        update child2;

        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];
        SFDC_Employee_Snapshot__c emplSnp1 = new SFDC_Employee_Snapshot__c(Salary__c = 30000, Exchange_Rate__c = 2.0, Per_Week_Hours__c = 20,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 1, 31), Employee_Record__c = employeeObj.Id);
        insert emplSnp1;
        SFDC_Employee_Snapshot__c emplSnp2 = new SFDC_Employee_Snapshot__c(Salary__c = 40000, Exchange_Rate__c = 3.0, Per_Week_Hours__c = 20,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 2, 28), Employee_Record__c = employeeObj.Id);
        insert emplSnp2;
        SFDC_Employee_Snapshot__c emplSnp3 = new SFDC_Employee_Snapshot__c(Salary__c = 45000, Exchange_Rate__c = 1.0, Per_Week_Hours__c = 30,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 3, 31), Employee_Record__c = employeeObj.Id);
        insert emplSnp3;

        Test.startTest();
        // January : Salary -> (30000 / (260 / 2)) / 8 Billing Rate -> before 20 : (1.1 * 1.1 * 1.1 * 1.52) = 2.02312, from 20 (1.1 * 1.2 * 1.1 * 1.52) = 2.20704  
        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 1, 2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 1, 12),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 1, 20),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        // Febryuary : Salary -> (30000 / (260 / 2)) / 8 Billing Rate -> (1.1 * 1.2 * 1.1 * 1.52) = 2.20704
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 2, 20),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj5 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 2, 15),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj6 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 2, 2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        // March : Salary -> (40000 / (260 / 3)) / 8 Billing Rate -> (1.1 * 1.3 * 1.1 * 1.52) = 2.39096
        Time_Card__c timeCardObj7 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 3, 15),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj8 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 3, 20),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj9 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 3, 1),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        // April : Salary from Employee -> (50000 / 260) / 8 Billing Rate -> (1.1 * 1.3 * 1.1 * 1.52) = 2.39096
        Time_Card__c timeCardObj10 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 4, 15),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj11 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 4, 20),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj12 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 4, 1),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);

        List<Time_Card__c> timeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3,timeCardObj4, timeCardObj5, timeCardObj6, timeCardObj7, timeCardObj8, timeCardObj9,
                                                                    timeCardObj10, timeCardObj11, timeCardObj12};
        insert timeCards;
        Test.stopTest();

        TimeCardCalculator tcCalculator = new TimeCardCalculator();
        Database.QueryLocatorIterator iter = tcCalculator.start(null).iterator();
        List<sObject> testData = new List<sObject>();
        while (iter.hasNext()) {
            testData.add(iter.next());
        }
        tcCalculator.execute(null, testData);
        tcCalculator.finish(null);

        Decimal child1Value = (8 * (((30000 / 2.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.0231200000).setScale(8)
                            + (10 * (((30000 / 2.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.2070400000).setScale(8)
                            + (8 * (((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.2070400000).setScale(8)
                            + (10 * (((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.2070400000).setScale(8)
                            + (8 * ((45000 / (260.0 * (30.0 / 40.0))) / 8.0).setScale(8) * 2.3909600000).setScale(8)
                            + (10 * ((45000 / (260.0 * (30.0 / 40.0))) / 8.0).setScale(8) * 2.3909600000).setScale(8)
                            + (8 * ((50000 / 260.0) / 8.0).setScale(8) * 2.3909600000).setScale(8)
                            + (10 * ((50000 / 260.0) / 8.0).setScale(8) * 2.3909600000);

        Decimal parentValue = (4 * (((30000 / 2.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.0231200000).setScale(8)
                            + (4 * (((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.2070400000).setScale(8)
                            + (4 * ((45000 / (260.0 * (30.0 / 40.0))) / 8.0).setScale(8) * 2.3909600000).setScale(8)
                            + (4 * ((50000 / 260.0) / 8.0).setScale(8) * 2.3909600000).setScale(8);

        for (Time_Card__c tc : [SELECT Id, Date__c, Time_Card_Salary__c, Billing_Rate__c,  Client__r.Name FROM TIme_Card__c]) {
            System.debug('Debug tc : ' + tc.Client__r.Name + ' ' + tc.Date__c + ' ' + tc.Billing_Rate__c + ' ' + tc.Time_Card_Salary__c);
        }

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        System.assertEquals((parentValue + child1Value).setScale(2), dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        System.assertEquals((child1Value).setScale(2), dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];
        System.assertEquals(0, dcontractFromDB.Services_Spend__c);
    }

    @isTest
    public static void shouldUseUpdatedEmployeeSnapshotForCalculations() {
        DContract__c parent1 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child2 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];

        parent1.Project_Billing_Rate__c = 'Test Daily Rate';
        child1.Project_Billing_Rate__c = 'Test Daily Rate';
        update parent1;
        update child1;
        update child2;

        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];
        SFDC_Employee_Snapshot__c emplSnp1 = new SFDC_Employee_Snapshot__c(Salary__c = 30000, Exchange_Rate__c = 2.0, Per_Week_Hours__c = 20,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 1, 31), Employee_Record__c = employeeObj.Id);
        insert emplSnp1;
        SFDC_Employee_Snapshot__c emplSnp2 = new SFDC_Employee_Snapshot__c(Salary__c = 40000, Exchange_Rate__c = 3.0, Per_Week_Hours__c = 20,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 2, 28), Employee_Record__c = employeeObj.Id);
        insert emplSnp2;
        SFDC_Employee_Snapshot__c emplSnp3 = new SFDC_Employee_Snapshot__c(Salary__c = 45000, Exchange_Rate__c = 1.0, Per_Week_Hours__c = 30,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 3, 31), Employee_Record__c = employeeObj.Id);
        insert emplSnp3;


        // January : Salary -> (30000 / (260 / 2)) / 8 Billing Rate -> before 20 : (1.1 * 1.1 * 1.1 * 1.52) = 2.02312, from 20 (1.1 * 1.2 * 1.1 * 1.52) = 2.20704
        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 1, 2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 1, 12),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 1, 20),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);

        List<Time_Card__c> timeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3};
        insert timeCards;

        Test.startTest();
        emplSnp1.Per_Week_Hours__c = 40;
        emplSnp1.Salary__c = 77000;
        update emplSnp1;

        Test.stopTest();

        Time_Card__c tc1 = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj1.Id];
        System.assertEquals((((77000 / 2.0) / 260.0) / 8.0).setScale(8), tc1.Time_Card_Salary__c);
        Time_Card__c tc2 = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj2.Id];
        System.assertEquals((((77000 / 2.0) / 260.0) / 8.0).setScale(8), tc2.Time_Card_Salary__c);
        Time_Card__c tc3 = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj3.Id];
        System.assertEquals((((77000 / 2.0) / 260.0) / 8.0).setScale(8), tc2.Time_Card_Salary__c);
    }

    @isTest
    public static void shouldUpdateRatesAndTCFieldsAfterFetchingUpdatedCases() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child2 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 2'];
        DContract__c child3 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 3'];
        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 1, 2),
                                                        Employee__c = employeeObj.Id, Client__c = child2.Id, Case__c = '22222: WrongTitle');
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 1, 12),
                                                        Employee__c = employeeObj.Id, Client__c = child2.Id, Case__c = '22222: WrongTitle');
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 1, 20),
                                                        Employee__c = employeeObj.Id, Client__c = child2.Id, Case__c = '11111: WrongTitle');
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 1, 2),
                                                        Employee__c = employeeObj.Id, Client__c = child2.Id, Case__c = '11111: WrongTitle');

        List<Time_Card__c> timeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3, timeCardObj4};
        insert timeCards;

        List<DContract__c> toUpdate = new List<DContract__c>();
        for (DContract__c dContract : [SELECT Id, Services_Spend__c, Require_Services_Spend_Refresh__c FROM DContract__c]) {
            dContract.Require_Services_Spend_Refresh__c = false;
            toUpdate.add(dContract);
        }
        update toUpdate;

        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();
        Database.executeBatch(new TimeCardCaseUpdateBatch(), 200);
        Test.stopTest();

        Time_Card__c tc1DB = [SELECT Area__c, Case__c, Project__c, Client__c, Billing_Rate__c FROM Time_Card__c WHERE Id =: timeCardObj1.Id];
        System.assertEquals('area 2', tc1DB.Area__c);
        System.assertEquals('22222: Title 2', tc1DB.Case__c);
        System.assertEquals('Test 2', tc1DB.Project__c);
        System.assertEquals(child3.Id, tc1DB.Client__c);
        System.assertEquals(2.39096, tc1DB.Billing_Rate__c);

        Time_Card__c tc2DB = [SELECT Area__c, Case__c, Project__c, Client__c, Billing_Rate__c FROM Time_Card__c WHERE Id =: timeCardObj2.Id];
        System.assertEquals('area 2', tc2DB.Area__c);
        System.assertEquals('22222: Title 2', tc2DB.Case__c);
        System.assertEquals('Test 2', tc2DB.Project__c);
        System.assertEquals(child3.Id, tc2DB.Client__c);
        System.assertEquals(2.39096, tc2DB.Billing_Rate__c);

        Time_Card__c tc3DB = [SELECT Area__c, Case__c, Project__c, Client__c, Billing_Rate__c FROM Time_Card__c WHERE Id =: timeCardObj3.Id];
        System.assertEquals('area 1', tc3DB.Area__c);
        System.assertEquals('11111: Title 1', tc3DB.Case__c);
        System.assertEquals('Test 1', tc3DB.Project__c);
        System.assertEquals(parent1.Id, tc3DB.Client__c);
        System.assertEquals(2.39096, tc3DB.Billing_Rate__c);

        Time_Card__c tc4DB = [SELECT Area__c, Case__c, Project__c, Client__c, Billing_Rate__c FROM Time_Card__c WHERE Id =: timeCardObj4.Id];
        System.assertEquals('area 1', tc4DB.Area__c);
        System.assertEquals('11111: Title 1', tc4DB.Case__c);
        System.assertEquals('Test 1', tc4DB.Project__c);
        System.assertEquals(parent1.Id, tc4DB.Client__c);
        System.assertEquals(2.39096, tc4DB.Billing_Rate__c);

        System.assertEquals(3, [SELECT Id FROM DContract__c WHERE Require_Services_Spend_Refresh__c = true].size());
    }

    @isTest
    public static void shouldUpdateTimeCardSalaryAfterEmployeeSnapshotUpsert() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        SFDC_Employee_Snapshot__c emplSnp1 = new SFDC_Employee_Snapshot__c(Salary__c = 40000, Exchange_Rate__c = 3.0, Per_Week_Hours__c = 20,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 1, 31), Employee_Record__c = employeeObj.Id);
        insert emplSnp1;

        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 1, 2),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id, Case__c = '22222: WrongTitle');
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 1, 12),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id, Case__c = '22222: WrongTitle');
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 2, 20),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id, Case__c = '11111: WrongTitle');
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 2, 2),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id, Case__c = '11111: WrongTitle');

        List<Time_Card__c> timeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3, timeCardObj4};
        insert timeCards;

        Test.startTest();
        List<SFDC_Employee_Snapshot__c> emplSnpList = new List<SFDC_Employee_Snapshot__c>();
        emplSnp1.Salary__c = 80000;
        emplSnpList.add(emplSnp1);
        SFDC_Employee_Snapshot__c emplSnp2 = new SFDC_Employee_Snapshot__c(Salary__c = 45000, Exchange_Rate__c = 1.0, Per_Week_Hours__c = 30,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 2, 28), Employee_Record__c = employeeObj.Id);
        emplSnpList.add(emplSnp2);
        upsert emplSnpList;
        Test.stopTest();

        DContract__c pContract = [SELECT Id, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Id =: parent1.Id];
        System.assertEquals(true, pContract.Require_Services_Spend_Refresh__c);


        Decimal salary1 = (((80000 / 3.0) / (260 * (20.0 / 40.0))) / 8.0).setScale(8);
        Time_Card__c tc1DB = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj1.Id];
        System.assertEquals(salary1, tc1DB.Time_Card_Salary__c);

        Time_Card__c tc2DB = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj2.Id];
        System.assertEquals(salary1, tc2DB.Time_Card_Salary__c);

        Decimal salary2 = (((45000 / 1.0) / (260 * (30.0 / 40.0))) / 8.0).setScale(8);
        Time_Card__c tc3DB = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj3.Id];
        System.assertEquals(salary2, tc3DB.Time_Card_Salary__c);

        Time_Card__c tc4DB = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj4.Id];
        System.assertEquals(salary2, tc4DB.Time_Card_Salary__c);
    }

    @isTest
    public static void shouldUpdateServicesSpend() {
        Test.startTest();
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Old Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj;

        DContract__c dcontract = new DContract__c(Name = 'Sample Test Name', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert dcontract;

        Time_Card__c timeCardObj = new Time_Card__c(Total__c = 4, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = dcontract.Id);
        insert timeCardObj;
        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: dcontract.Id];
        System.assertEquals(229.90, dcontractFromDB.Services_Spend__c);
    }

    @isTest
    static void shouldUpdateParentServicesSpend() {
        Test.startTest();
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Old Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj;

        DContract__c parent = new DContract__c(Name = 'Old Sample Parent', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent;
        DContract__c child1 = new DContract__c(Name = 'Old Sample Child 1', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent.Id);
        insert child1;
        DContract__c child2 = new DContract__c(Name = 'Old Sample Child 2', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent.Id);
        insert child2;

        Time_Card__c timeCardObj1 = new Time_Card__c(Total__c = 4, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child2.Id);

        List<Time_Card__c> newTimeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2};
        insert newTimeCards;

        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

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
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Old Test Employee', Salary__c = 50000, Exchange_Rate__c = 1,  Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj;

        DContract__c parent1 = new DContract__c(Name = 'Old Sample Parent', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent1;
        DContract__c child1 = new DContract__c(Name = 'Old Sample Child 1', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child1;
        DContract__c child2 = new DContract__c(Name = 'Old Sample Child 2', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child2;
        DContract__c parent2 = new DContract__c(Name = 'Old Sample Parent', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent2;
        DContract__c child3 = new DContract__c(Name = 'Old Sample Child 1', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent2.Id);
        insert child3;
        DContract__c child4 = new DContract__c(Name = 'Old Sample Child 2', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent2.Id);
        insert child4;

        Time_Card__c timeCardObj1 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Total__c = 4, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj3 = new Time_Card__c(Total__c = 10, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child3.Id);
        Time_Card__c timeCardObj4 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child4.Id);

        List<Time_Card__c> newTimeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3, timeCardObj4};
        insert newTimeCards;

        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent1.Id];
        System.assertEquals(689.70, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child1.Id];
        System.assertEquals(459.80, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child2.Id];
        System.assertEquals(0, dcontractFromDB.Services_Spend__c);

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
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate Old', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 22, Custom_2__c = 0, Custom_3__c = 0, Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Old Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj;

        DContract__c parent = new DContract__c(Name = 'Old Sample Parent', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent;

        DContract__c child1 = new DContract__c(Name = 'Old Sample Child 1', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent.Id);
        insert child1;

        DContract__c child2 = new DContract__c(Name = 'Old Sample Child 2', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent.Id);
        insert child2;

        Time_Card__c timeCardObj1 = new Time_Card__c(Total__c = 4, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child2.Id);

        List<Time_Card__c> newTimeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2};
        insert newTimeCards;

        DContract__c toUpdate = [SELECT Id, Project_Billing_Rate__c FROM DContract__c WHERE Id =: child1.Id];
        toUpdate.Project_Billing_Rate__c = 'Loaded Daily Rate Old';
        update toUpdate;

        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent.Id];
        System.assertEquals(740.28, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child1.Id];
        System.assertEquals(280.48, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child2.Id];
        System.assertEquals(459.80, dcontractFromDB.Services_Spend__c);
    }

    @isTest
    public static void testManyTimeCardsAndEmployees() {
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate', Date__c = Date.newInstance(2018, 03, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 12, Fringe__c = 30, G_A__c = 15, Overhead__c = 52);

        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child2 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 2'];
        DContract__c parent2 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 2'];
        DContract__c child3 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 3'];
        DContract__c child4 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 4'];

        SFDC_Employee__c employeeObj2 = new SFDC_Employee__c(Name = 'Sample Employee 2', Salary__c = 70000, Exchange_Rate__c = 1.5, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj2;
        SFDC_Employee__c employeeObj1 = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        SFDC_Employee_Snapshot__c emplSnp1 = new SFDC_Employee_Snapshot__c(Salary__c = 50000, Exchange_Rate__c = 2.0, Per_Week_Hours__c = 30,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 1, 31), Employee_Record__c = employeeObj2.Id);
        insert emplSnp1;
        SFDC_Employee_Snapshot__c emplSnp2 = new SFDC_Employee_Snapshot__c(Salary__c = 50000, Exchange_Rate__c = 1.0, Per_Week_Hours__c = 30,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 2, 28), Employee_Record__c = employeeObj2.Id);
        insert emplSnp2;
        SFDC_Employee_Snapshot__c emplSnp3 = new SFDC_Employee_Snapshot__c(Salary__c = 65000, Exchange_Rate__c = 1.0, Per_Week_Hours__c = 40,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 3, 31), Employee_Record__c = employeeObj2.Id);
        insert emplSnp3;

        SFDC_Employee_Snapshot__c emplSnp4 = new SFDC_Employee_Snapshot__c(Salary__c = 30000, Exchange_Rate__c = 2.0, Per_Week_Hours__c = 20,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 1, 31), Employee_Record__c = employeeObj1.Id);
        insert emplSnp4;
        SFDC_Employee_Snapshot__c emplSnp5 = new SFDC_Employee_Snapshot__c(Salary__c = 40000, Exchange_Rate__c = 1.5, Per_Week_Hours__c = 30,
                                                                              Snapshot_Date__c = Date.newInstance(2018, 2, 28), Employee_Record__c = employeeObj1.Id);
        insert emplSnp5;

        Test.startTest();
        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 1, 5), Employee__c = employeeObj2.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(2018, 1, 6), Employee__c = employeeObj2.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(2018, 1, 7), Employee__c = employeeObj2.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(2018, 1, 31), Employee__c = employeeObj2.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2018, 1, 15), Employee__c = employeeObj2.Id, Client__c = parent1.Id));

        timeCards.add(new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(2018, 2, 15), Employee__c = employeeObj2.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(2018, 2, 4), Employee__c = employeeObj2.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2018, 2, 14), Employee__c = employeeObj2.Id, Client__c = child1.Id));
        timeCards.add(new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(2018, 2, 27), Employee__c = employeeObj2.Id, Client__c = child1.Id));
        timeCards.add(new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(2018, 2, 25), Employee__c = employeeObj2.Id, Client__c = child1.Id));

        timeCards.add(new Time_Card__c(Total__c = 9, Date__c = Date.newInstance(2018, 3, 15), Employee__c = employeeObj2.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2018, 3, 11), Employee__c = employeeObj2.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(2018, 3, 12), Employee__c = employeeObj2.Id, Client__c = child1.Id));
        timeCards.add(new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(2018, 3, 13), Employee__c = employeeObj2.Id, Client__c = child1.Id));
        timeCards.add(new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(2018, 3, 1), Employee__c = employeeObj2.Id, Client__c = child1.Id));

        timeCards.add(new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2018, 4, 15), Employee__c = employeeObj2.Id, Client__c = child2.Id));
        timeCards.add(new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(2018, 4, 17), Employee__c = employeeObj2.Id, Client__c = child2.Id));
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 4, 18), Employee__c = employeeObj2.Id, Client__c = child2.Id));
        timeCards.add(new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(2018, 4, 19), Employee__c = employeeObj2.Id, Client__c = child2.Id));
        timeCards.add(new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2018, 4, 21), Employee__c = employeeObj2.Id, Client__c = child2.Id));
        timeCards.add(new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(2018, 4, 20), Employee__c = employeeObj2.Id, Client__c = child2.Id));

        // Employee 1
        timeCards.add(new Time_Card__c(Total__c = 9, Date__c = Date.newInstance(2018, 1, 7), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2018, 1, 8), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 1, 9), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 1, 4), Employee__c = employeeObj1.Id, Client__c = parent1.Id));
        timeCards.add(new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(2018, 1, 5), Employee__c = employeeObj1.Id, Client__c = parent1.Id));

        timeCards.add(new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2018, 2, 5), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 2, 4), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2018, 2, 3), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 2, 2), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2018, 2, 1), Employee__c = employeeObj1.Id, Client__c = child3.Id));

        timeCards.add(new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(2018, 3, 21), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 3, 22), Employee__c = employeeObj1.Id, Client__c = child3.Id));
        timeCards.add(new Time_Card__c(Total__c = 9, Date__c = Date.newInstance(2018, 3, 23), Employee__c = employeeObj1.Id, Client__c = child2.Id));
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 3, 25), Employee__c = employeeObj1.Id, Client__c = child2.Id));
        timeCards.add(new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2018, 3, 24), Employee__c = employeeObj1.Id, Client__c = child2.Id));

        timeCards.add(new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2018, 4, 16), Employee__c = employeeObj1.Id, Client__c = child4.Id));
        timeCards.add(new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2018, 4, 15), Employee__c = employeeObj1.Id, Client__c = child4.Id));
        timeCards.add(new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(2018, 4, 14), Employee__c = employeeObj1.Id, Client__c = child4.Id));
        timeCards.add(new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2018, 4, 13), Employee__c = employeeObj1.Id, Client__c = child4.Id));
        timeCards.add(new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(2018, 4, 12), Employee__c = employeeObj1.Id, Client__c = child4.Id));
        timeCards.add(new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(2018, 4, 11), Employee__c = employeeObj1.Id, Client__c = child4.Id));
        insert timeCards;

        Database.executeBatch(new TimeCardCalculator(new Set<Id> {child1.Id, parent2.Id}), 200);
        Test.stopTest();

        for (Time_Card__c tc : [SELECT Id, Time_Card_Salary__c, Billing_Rate__c, Date__c FROM Time_Card__c WHERE Client__c =: parent2.Id OR Client__c =: child3.Id OR Client__c =: child4.Id  ORDER BY Date__c]) {
            System.debug('Time Card value ' + tc.Date__c + '  : ' + tc.Time_Card_Salary__c + '   ' + tc.Billing_Rate__c);
        }

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent1.Id];
        System.assertEquals(7426.28, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child1.Id];
        System.assertEquals(1947.74, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child2.Id];
        System.assertEquals(2463.51, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: parent2.Id];
        System.assertEquals(2907.37, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child3.Id];
        System.assertEquals(1806.13, dcontractFromDB.Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Id =: child4.Id];
        System.assertEquals(1101.24, dcontractFromDB.Services_Spend__c);
    }

    @isTest
    public static void futureMethodShouldRecalculateTimeCardCostAndBillingRate() {
        Test.startTest();
        SFDC_Employee__c employeeObj1 = new SFDC_Employee__c(Name = 'Old Test Employee', Salary__c = 50000, Exchange_Rate__c = 1,  Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                                    Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj1;

        SFDC_Employee__c employeeObj2 = new SFDC_Employee__c(Name = 'Old Test Employee', Salary__c = 80000, Exchange_Rate__c = 1,  Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                                    Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj2;

        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate Updated', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 25);

        DContract__c parent1 = new DContract__c(Name = 'Old Sample Parent', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent1;
        DContract__c child1 = new DContract__c(Name = 'Old Sample Child 1', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child1;

        Time_Card__c timeCardObj1 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj1.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj2 = new Time_Card__c(Total__c = 4, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj1.Id, Client__c = parent1.Id);
        Time_Card__c timeCardObj3 = new Time_Card__c(Total__c = 10, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj1.Id, Client__c = child1.Id);
        Time_Card__c timeCardObj4 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj1.Id, Client__c = child1.Id);

        List<Time_Card__c> newTimeCards = new List<Time_Card__c> {timeCardObj1, timeCardObj2, timeCardObj3, timeCardObj4};
        insert newTimeCards;

        timeCardObj1.Employee__c = employeeObj2.Id;
        timeCardObj2.Employee__c = employeeObj2.Id;
        child1.Project_Billing_Rate__c = 'Loaded Daily Rate Updated';
        update new List<Time_Card__c> {timeCardObj1, timeCardObj2};
        update child1;

        TimeCardCalculatorUtils.calculateTimeCardSalaryAndBillingRate(new Set<Id> {timeCardObj1.Id, timeCardObj2.Id, timeCardObj3.Id, timeCardObj4.Id});
        Test.stopTest();

        DContract__c testContract = [SELECT Id, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Id =: parent1.Id];
        System.assertEquals(true, testContract.Require_Services_Spend_Refresh__c);

        testContract = [SELECT Id, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Id =: child1.Id];
        System.assertEquals(true, testContract.Require_Services_Spend_Refresh__c);

        Decimal salary1 = (((50000 / 1.0) / (260 * (40.0 / 40.0))) / 8.0).setScale(8);
        Decimal salary2 = (((80000 / 1.0) / (260 * (40.0 / 40.0))) / 8.0).setScale(8);

        Time_Card__c tc1DB = [SELECT Id, Billing_Rate__c, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj1.Id];
        System.assertEquals(salary2, tc1DB.Time_Card_Salary__c);
        System.assertEquals(2.39096, tc1DB.Billing_Rate__c);

        Time_Card__c tc2DB = [SELECT Id, Billing_Rate__c, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj2.Id];
        System.assertEquals(salary2, tc2DB.Time_Card_Salary__c);
        System.assertEquals(2.39096, tc2DB.Billing_Rate__c);

        Time_Card__c tc3DB = [SELECT Id, Billing_Rate__c, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj3.Id];
        System.assertEquals(salary1, tc3DB.Time_Card_Salary__c);
        System.assertEquals(1.96625, tc3DB.Billing_Rate__c);

        Time_Card__c tc4DB = [SELECT Id, Billing_Rate__c, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj4.Id];
        System.assertEquals(salary1, tc4DB.Time_Card_Salary__c);
        System.assertEquals(1.96625, tc4DB.Billing_Rate__c);
    }

    /**
     * Test for Billing Rates
     */

    @isTest
    public static void shouldSortBillingRate() {
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate Order', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate Order', Date__c = Date.newInstance(2015, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 15, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate Order', Date__c = Date.newInstance(2014, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 20, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate Order', Date__c = Date.newInstance(2017, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 25, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);

        TimeCardCalculatorHelper tcHelper = new TimeCardCalculatorHelper();

        List<SalaryHistoryRecord> billingRates = tcHelper.loadBillingRatesHistory('Loaded Daily Rate Order');
        System.assertEquals(2.39096, billingRates.get(0).getValue());
        System.assertEquals(2.60832, billingRates.get(1).getValue());
        System.assertEquals(2.49964, billingRates.get(2).getValue());
        System.assertEquals(2.717, billingRates.get(3).getValue());
    }

    @isTest
    public static void billingRateManagerShouldAddNewRate() {
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 1', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        PageReference pageRef = Page.Billing_Rates_List;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BillingRateController brc = new BillingRateController();
        brc.initManageRates();
        System.assertEquals(3, brc.billingRates.size()); // we have 2 rates from setUp method

        brc.newBillingRate.Name = 'Simple new rate';
        brc.newBillingRate.Fee__c = 30;
        brc.newBillingRate.Fringe__c = 15;
        brc.newBillingRate.G_A__c = 10;
        brc.newBillingRate.Overhead__c = 5;
        brc.newBillingRate.Custom_1__c = 11;
        brc.newBillingRate.Custom_2__c = 12;
        brc.newBillingRate.Custom_3__c = 13;
        brc.saveNewRate();
        Test.stopTest();

        System.assertEquals(4, brc.billingRates.size());
        Project_Billing_Rate__c newRate = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c FROM Project_Billing_Rate__c WHERE Name = 'Simple new rate'];
        System.assertEquals(11, newRate.Custom_1__c);
        System.assertEquals(12, newRate.Custom_2__c);
        System.assertEquals(13, newRate.Custom_3__c);
        System.assertEquals(15, newRate.Fringe__c);
        System.assertEquals(30, newRate.Fee__c);
        System.assertEquals(10, newRate.G_A__c);
        System.assertEquals(5, newRate.Overhead__c);
        System.assertEquals(Date.newInstance(2000, 1, 1), newRate.Date__c);
    }

    @isTest
    public static void billingRateManagerShouldntAddNewRateWithSameName() {
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 3', Date__c = Date.newInstance(2017, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 25, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        PageReference pageRef = Page.Billing_Rates_List;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BillingRateController brc = new BillingRateController();
        brc.initManageRates();
        System.assertEquals(3, brc.billingRates.size());

        brc.newBillingRate.Name = 'Loaded Daily Rate 3';
        brc.newBillingRate.Fee__c = 30;
        brc.newBillingRate.Fringe__c = 15;
        brc.saveNewRate();
        Test.stopTest();

        System.assertEquals(3, brc.billingRates.size());
    }

    @isTest
    public static void billingRateManagerShouldInsertNewRateRow() {
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 1', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 1', Date__c = Date.newInstance(2015, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 15, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 2', Date__c = Date.newInstance(2014, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 20, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 3', Date__c = Date.newInstance(2017, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 25, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        PageReference pageRef = Page.Billing_Rate_Manager;
        pageRef.getParameters().put('billingRateName', EncodingUtil.urlDecode('Loaded Daily Rate 1', 'UTF-8'));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BillingRateController brc = new BillingRateController();
        brc.initManageRate();
        System.assertEquals(2, brc.rateHistoryList.size());
        System.assertEquals('Loaded Daily Rate 1', brc.newBillingRate.Name);

        brc.newBillingRate.Fee__c = 30;
        brc.newBillingRate.Fringe__c = 15;
        brc.newBillingRate.G_A__c = 10;
        brc.newBillingRate.Overhead__c = 5;
        brc.newBillingRate.Custom_1__c = 11;
        brc.newBillingRate.Custom_2__c = 12;
        brc.newBillingRate.Custom_3__c = 13;
        brc.saveNewRateHistory();
        Test.stopTest();

        System.assertEquals(3, brc.rateHistoryList.size());
        Project_Billing_Rate__c newRate = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c FROM Project_Billing_Rate__c WHERE Name = 'Loaded Daily Rate 1'
                                                AND Date__c =: Date.today()];
        System.assertEquals(11, newRate.Custom_1__c);
        System.assertEquals(12, newRate.Custom_2__c);
        System.assertEquals(13, newRate.Custom_3__c);
        System.assertEquals(15, newRate.Fringe__c);
        System.assertEquals(30, newRate.Fee__c);
        System.assertEquals(10, newRate.G_A__c);
        System.assertEquals(5, newRate.Overhead__c);
        System.assertEquals(Date.today(), newRate.Date__c);
    }

    @isTest
    public static void billingRateManagerShouldUpdateRateHistory1() {
        Project_Billing_Rate__c br1 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 1', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        Project_Billing_Rate__c br2 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 1', Date__c = Date.newInstance(2015, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 15, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert br1;
        insert br2;

        PageReference pageRef = Page.Billing_Rate_Manager;
        pageRef.getParameters().put('billingRateName', EncodingUtil.urlDecode('Loaded Daily Rate 1', 'UTF-8'));
        pageRef.getParameters().put('billingRateId', br2.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BillingRateController brc = new BillingRateController();
        brc.initUpdateRate();
        brc.newBillingRate.Fee__c = 30;
        brc.newBillingRate.Fringe__c = 15;
        brc.newBillingRate.G_A__c = 10;
        brc.newBillingRate.Overhead__c = 5;
        brc.newBillingRate.Custom_1__c = 11;
        brc.newBillingRate.Custom_2__c = 12;
        brc.newBillingRate.Custom_3__c = 13;
        brc.updateRateHistory();
        Test.stopTest();

        brc.initManageRate();
        System.assertEquals(2, brc.rateHistoryList.size());
        Project_Billing_Rate__c newRate = [SELECT Id, Name, Date__c, Custom_1__c, Overhead__c, G_A__c, Fringe__c, Fee__c, Custom_2__c, Custom_3__c FROM Project_Billing_Rate__c WHERE Id =: br2.Id];
        System.assertEquals(11, newRate.Custom_1__c);
        System.assertEquals(12, newRate.Custom_2__c);
        System.assertEquals(13, newRate.Custom_3__c);
        System.assertEquals(15, newRate.Fringe__c);
        System.assertEquals(30, newRate.Fee__c);
        System.assertEquals(10, newRate.G_A__c);
        System.assertEquals(5, newRate.Overhead__c);
        System.assertEquals(Date.newInstance(2015, 01, 01), newRate.Date__c);
    }

    @isTest
    public static void billingRateManagerShouldUpdateRateHistory2() {
        Project_Billing_Rate__c br1 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 1', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        Project_Billing_Rate__c br2 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 1', Date__c = Date.newInstance(2015, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 15, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert br1;
        insert br2;

        PageReference pageRef = Page.Billing_Rate_Manager;
        pageRef.getParameters().put('billingRateName', EncodingUtil.urlDecode('Loaded Daily Rate 1', 'UTF-8'));
        pageRef.getParameters().put('billingRateId', br2.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BillingRateController brc = new BillingRateController();
        brc.initUpdateRate();
        brc.deleteRateRow();
        Test.stopTest();

        brc.initManageRate();
        System.assertEquals(1, brc.rateHistoryList.size());
        System.assertEquals(1, [SELECT Id FROM Project_Billing_Rate__c WHERE Name = 'Loaded Daily Rate 1'].size());
        List<Project_Billing_Rate_Update__c> upData = [SELECT From_Range__c, To_Range__c FROM Project_Billing_Rate_Update__c WHERE Name = 'Loaded Daily Rate 1'];
        System.assertEquals(1, upData.size());
        System.assertEquals(Date.newInstance(2015, 01, 01), upData.get(0).From_Range__c);
        System.assertEquals(Date.today(), upData.get(0).To_Range__c);
    }

    @isTest
    static void billingRateManagerShouldRunRecalculationBatch1() {
        Project_Billing_Rate__c rate1_1 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 2', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        Project_Billing_Rate__c rate1_2 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 2', Date__c = Date.newInstance(2011, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 15, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        Project_Billing_Rate__c rate1_3 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate 2', Date__c = Date.newInstance(2012, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert rate1_1;
        insert rate1_2;
        insert rate1_3;

        SFDC_Employee__c employee_1 = new SFDC_Employee__c(Name = 'emp_6', Salary__c = 60000, Exchange_Rate__c = 2,
                                                          Effective_Salary_Date__c = Date.newInstance(2011, 11, 1),
                                                          Effective_Exchange_Rate_Date__c = Date.newInstance(2013, 1, 1));
        insert employee_1;

        DContract__c parent_1 = new DContract__c(Name = 'Sample Parent', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No', Project_Billing_Rate__c = 'Loaded Daily Rate 2');
        insert parent_1;
        Time_Card__c tc_1_employee_1 = new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2010, 12, 30), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        Time_Card__c tc_2_employee_1 = new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2010, 11, 1), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        Time_Card__c tc_3_employee_1 = new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(2011, 1, 1), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        Time_Card__c tc_4_employee_1 = new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(2011, 5, 22), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        Time_Card__c tc_5_employee_1 = new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2016, 3, 3), Employee__c = employee_1.Id, Client__c = parent_1.Id);

        List<Time_Card__c> newTimeCards = new List<Time_Card__c> {tc_1_employee_1, tc_2_employee_1, tc_3_employee_1, tc_4_employee_1, tc_5_employee_1};
        insert newTimeCards;

        PageReference pageRef = Page.Billing_Rate_Manager;
        pageRef.getParameters().put('billingRateName', EncodingUtil.urlDecode('Loaded Daily Rate 2', 'UTF-8'));
        pageRef.getParameters().put('billingRateId', rate1_2.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BillingRateController brc = new BillingRateController();
        brc.initUpdateRate();
        brc.newBillingRate.Fee__c = 30;
        brc.newBillingRate.Fringe__c = 15;
        brc.newBillingRate.G_A__c = 10;
        brc.newBillingRate.Overhead__c = 5;
        brc.newBillingRate.Custom_1__c = 11;
        brc.newBillingRate.Custom_2__c = 12;
        brc.newBillingRate.Custom_3__c = 13;
        brc.updateRateHistory();
        brc.runRecalculationBatchJob();
        Test.stopTest();

        Time_Card__c tcDB_1 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_1_employee_1.Id];
        System.assertEquals(2.39096, tcDB_1.Billing_Rate__c);
        Time_Card__c tcDB_2 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_2_employee_1.Id];
        System.assertEquals(2.39096, tcDB_2.Billing_Rate__c);
        Time_Card__c tcDB_3 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_3_employee_1.Id];
        System.assertEquals(2.4257309076, tcDB_3.Billing_Rate__c);
        Time_Card__c tcDB_4 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_4_employee_1.Id];
        System.assertEquals(2.4257309076, tcDB_4.Billing_Rate__c);
        Time_Card__c tcDB_5 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_5_employee_1.Id];
        System.assertEquals(2.39096, tcDB_5.Billing_Rate__c);
    }

    @isTest
    public static void billingRateManagerShouldRunRecalculationBatch2() {
        Project_Billing_Rate__c rate1_1 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        Project_Billing_Rate__c rate1_2 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate', Date__c = Date.newInstance(2011, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 15, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        Project_Billing_Rate__c rate1_3 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate', Date__c = Date.newInstance(2012, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert rate1_1;
        insert rate1_2;
        insert rate1_3;

        SFDC_Employee__c employee_1 = new SFDC_Employee__c(Name = 'emp_6', Salary__c = 60000, Exchange_Rate__c = 2,
                                                          Effective_Salary_Date__c = Date.newInstance(2011, 11, 1),
                                                          Effective_Exchange_Rate_Date__c = Date.newInstance(2013, 1, 1));
        insert employee_1;
        DContract__c parent_1 = new DContract__c(Name = 'Sample Parent', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No', Project_Billing_Rate__c = 'Loaded Daily Rate');
        insert parent_1;
        Time_Card__c tc_1_employee_1 = new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(2010, 12, 30), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        Time_Card__c tc_2_employee_1 = new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(2010, 11, 1), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        Time_Card__c tc_3_employee_1 = new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(2011, 1, 1), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        Time_Card__c tc_4_employee_1 = new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(2011, 5, 22), Employee__c = employee_1.Id, Client__c = parent_1.Id);
        Time_Card__c tc_5_employee_1 = new Time_Card__c(Total__c = 8, Date__c = Date.newInstance(2016, 3, 3), Employee__c = employee_1.Id, Client__c = parent_1.Id);

        List<Time_Card__c> newTimeCards = new List<Time_Card__c> {tc_1_employee_1, tc_2_employee_1, tc_3_employee_1, tc_4_employee_1, tc_5_employee_1};
        insert newTimeCards;

        PageReference pageRef = Page.Billing_Rate_Manager;
        pageRef.getParameters().put('billingRateName', EncodingUtil.urlDecode('Loaded Daily Rate', 'UTF-8'));
        pageRef.getParameters().put('billingRateId', rate1_2.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BillingRateController brc = new BillingRateController();
        brc.initUpdateRate();
        brc.newBillingRate.Fee__c = 30;
        brc.newBillingRate.Fringe__c = 15;
        brc.newBillingRate.G_A__c = 10;
        brc.newBillingRate.Overhead__c = 5;
        brc.newBillingRate.Custom_1__c = 11;
        brc.newBillingRate.Custom_2__c = 12;
        brc.newBillingRate.Custom_3__c = 13;
        brc.updateRateHistory();
        brc.initManageRate();
        brc.newBillingRate.Fee__c = 30;
        brc.newBillingRate.Fringe__c = 15;
        brc.newBillingRate.G_A__c = 10;
        brc.newBillingRate.Overhead__c = 5;
        brc.newBillingRate.Custom_1__c = 50;
        brc.newBillingRate.Custom_2__c = 12;
        brc.newBillingRate.Custom_3__c = 50;
        brc.newBillingRate.Date__c = Date.newInstance(2016, 3, 3);
        brc.saveNewRateHistory();
        brc.runRecalculationBatchJob();
        Test.stopTest();

        Time_Card__c tcDB_1 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_1_employee_1.Id];
        System.assertEquals(2.39096, tcDB_1.Billing_Rate__c);
        Time_Card__c tcDB_2 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_2_employee_1.Id];
        System.assertEquals(2.39096, tcDB_2.Billing_Rate__c);
        Time_Card__c tcDB_3 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_3_employee_1.Id];
        System.assertEquals(2.4257309076, tcDB_3.Billing_Rate__c);
        Time_Card__c tcDB_4 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_4_employee_1.Id];
        System.assertEquals(2.4257309076, tcDB_4.Billing_Rate__c);
        Time_Card__c tcDB_5 = [SELECT Id, Billing_Rate__c FROM Time_Card__c WHERE Id =: tc_5_employee_1.Id];
        System.assertEquals(4.351347, tcDB_5.Billing_Rate__c);
    }

    @isTest
    public static void billingRateCtrlShouldReturnPageReference() {
        Project_Billing_Rate__c rate1_1 = new Project_Billing_Rate__c(Name = 'Loaded Daily Rate', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                                                      Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
        insert rate1_1;

        PageReference pageRef = Page.Billing_Rate_Manager;
        pageRef.getParameters().put('billingRateName', EncodingUtil.urlDecode('Loaded Daily Rate', 'UTF-8'));
        pageRef.getParameters().put('billingRateId', rate1_1.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        BillingRateController brc = new BillingRateController();
        brc.initManageRate();

        brc.billingRateId = rate1_1.Id;
        PageReference pageRef1 = brc.goToRateUpdateView();
        System.assertNotEquals(null, pageRef1);
        System.assertEquals(true, pageRef1.getRedirect());
        System.assertEquals(2, pageRef1.getParameters().size());
        System.assertEquals('Loaded+Daily+Rate', pageRef1.getParameters().get('billingRateName'));
        System.assertEquals(rate1_1.Id, pageRef1.getParameters().get('billingRateId'));

        PageReference pageRef2 = brc.goToRateListView();
        System.assertNotEquals(null, pageRef2);
        System.assertEquals(true, pageRef2.getRedirect());
        Test.stopTest();
    }
}