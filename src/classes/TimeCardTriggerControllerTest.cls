@isTest
public class TimeCardTriggerControllerTest {

    @testSetup
    public static void addTestData() {
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
                                                            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Per_Week_Hours__c = 40);
        insert employeeObj;

        DContract__c parent1 = new DContract__c(Name = 'Sample Parent 1', Services_Spend__c = 400, Calculated_Services_Spend__c = 400, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent1;

        DContract__c child1 = new DContract__c(Name = 'Sample Child 1',  Services_Spend__c = 100, Calculated_Services_Spend__c = 100, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child1;

        DContract__c child2 = new DContract__c(Name = 'Sample Child 2',  Services_Spend__c = 100, Calculated_Services_Spend__c = 100, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child2;

        DContract__c parent2 = new DContract__c(Name = 'Sample Parent 2', Services_Spend__c = 500, Calculated_Services_Spend__c = 500, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent2;

        DContract__c child3 = new DContract__c(Name = 'Sample Child 3', Services_Spend__c = 200, Calculated_Services_Spend__c = 200, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent2.Id);
        insert child3;

        DContract__c child4 = new DContract__c(Name = 'Sample Child 4', Services_Spend__c = 150, Calculated_Services_Spend__c = 150, Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent2.Id);
        insert child4;

        insert new Project_Billing_Rate__c(Name = 'Loaded Daily Rate', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);

        insert new Project_Billing_Rate__c(Name = 'Test Daily Rate', Date__c = Date.newInstance(1990, 01, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 10, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Test Daily Rate', Date__c = Date.newInstance(2018, 01, 20), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 20, G_A__c = 10, Overhead__c = 52);
        insert new Project_Billing_Rate__c(Name = 'Test Daily Rate', Date__c = Date.newInstance(2018, 03, 01), Custom_1__c = 0, Custom_2__c = 0, Custom_3__c = 0,
                                            Fee__c = 10, Fringe__c = 30, G_A__c = 10, Overhead__c = 52);
    }

    @isTest
    public static void shouldUpdateServicesSpendAfterTimeCardDelete() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child3 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 3'];
        DContract__c child4 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 4'];
        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 1.0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj1); // 16
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 2.0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj2); // 24
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 3.0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child3.Id);
        timeCards.add(timeCardObj3); // 60
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 4.0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child4.Id);
        timeCards.add(timeCardObj4); // 64
        insert timeCards;

        Test.startTest();
        delete timeCards;
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        System.assertEquals(360, dcontractFromDB.Calculated_Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 2'];
        System.assertEquals(376, dcontractFromDB.Calculated_Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        System.assertEquals(84, dcontractFromDB.Calculated_Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];
        System.assertEquals(100, dcontractFromDB.Calculated_Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 3'];
        System.assertEquals(140, dcontractFromDB.Calculated_Services_Spend__c);
        dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 4'];
        System.assertEquals(86, dcontractFromDB.Calculated_Services_Spend__c);
    }

    @isTest
    public static void shouldCalcualteTimeCardCostForGivenContractIds() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child2 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 2'];


        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj1);
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj2);
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj3);
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.today().addMonths(-2),
                                                        Employee__c = employeeObj.Id, Client__c = child2.Id);
        timeCards.add(timeCardObj4);
        insert timeCards;

        Test.startTest();
        Database.executeBatch(new TimeCardCalculator(new Set<Id> { child1.Id }, false), 200);
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        System.assertEquals(2124.25, dcontractFromDB.Services_Spend__c); // 400 + (30 * (1.1 * 1.1 * 1.3 * 1.52) * ((50000 / 260.0) / 8.0))
        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        System.assertEquals(1134.55, dcontractFromDB.Services_Spend__c); // 100 + (18 * (1.1 * 1.1 * 1.3 * 1.52) * ((50000 / 260.0) / 8.0))
        dcontractFromDB = [SELECT Id, Name, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];
        System.assertEquals(559.80, dcontractFromDB.Services_Spend__c); // 100 + (8 * (1.1 * 1.1 * 1.3 * 1.52) * ((50000 / 260.0) / 8.0))
    }

    @isTest
    public static void shouldUseEmployeeSnapshotForCalculations() {
        DContract__c parent1 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child2 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];

        parent1.Project_Billing_Rate__c = 'Test Daily Rate';
        parent1.Calculated_Services_Spend__c = 0.0;
        child1.Project_Billing_Rate__c = 'Test Daily Rate';
        child1.Calculated_Services_Spend__c = 0.0;
        child2.Calculated_Services_Spend__c = 0.0;
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

        List<Time_Card__c> timeCards = new List<Time_Card__c>();

        // January : Salary -> (30000 / (260 / 2)) / 8 Billing Rate -> before 20 : (1.1 * 1.1 * 1.1 * 1.52) = 2.02312, from 20 (1.1 * 1.2 * 1.1 * 1.52) = 2.20704
        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 1, 2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj1);
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 1, 12),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj2);
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 1, 20),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj3);
        // Febryuary : Salary -> (30000 / (260 / 2)) / 8 Billing Rate -> (1.1 * 1.2 * 1.1 * 1.52) = 2.20704
        Time_Card__c timeCardObj4 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 2, 20),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj4);
        Time_Card__c timeCardObj5 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 2, 15),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj5);
        Time_Card__c timeCardObj6 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 2, 2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj6);
        // March : Salary -> (40000 / (260 / 3)) / 8 Billing Rate -> (1.1 * 1.3 * 1.1 * 1.52) = 2.39096
        Time_Card__c timeCardObj7 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 3, 15),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj7);
        Time_Card__c timeCardObj8 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 3, 20),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj8);
        Time_Card__c timeCardObj9 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 3, 1),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj9);

        // April : Salary from Employee -> (50000 / 260) / 8 Billing Rate -> (1.1 * 1.3 * 1.1 * 1.52) = 2.39096
        Time_Card__c timeCardObj10 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 4, 15),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj10);
        Time_Card__c timeCardObj11 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 4, 20),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj11);
        Time_Card__c timeCardObj12 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 4, 1),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj12);
        insert timeCards;

        Test.startTest();
        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        Decimal child1Value = (8 * (((30000 / 2.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.0231200000).setScale(8) + (10 * (((30000 / 2.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.2070400000).setScale(8)
                                + (8 * (((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.2070400000).setScale(8) + (10 * (((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.2070400000).setScale(8)
                                + (8 * ((45000 / (260.0 * (30.0 / 40.0))) / 8.0).setScale(8) * 2.3909600000).setScale(8) + (10 * ((45000 / (260.0 * (30.0 / 40.0))) / 8.0).setScale(8) * 2.3909600000).setScale(8)
                                + (8 * ((50000 / 260.0) / 8.0).setScale(8) * 2.3909600000).setScale(8) + (10 * ((50000 / 260.0) / 8.0).setScale(8) * 2.3909600000);
        Decimal parentValue = (4 * (((30000 / 2.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.0231200000).setScale(8)
                                + (4 * (((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8) * 2.2070400000).setScale(8)
                                + (4 * ((45000 / (260.0 * (30.0 / 40.0))) / 8.0).setScale(8) * 2.3909600000).setScale(8)
                                + (4 * ((50000 / 260.0) / 8.0).setScale(8) * 2.3909600000).setScale(8);

        System.debug((((30000 / 2.0) / (260.0 / 2.0)) / 8.0).setScale(8));
        System.debug((((30000 / 2.0) / (260.0 / 2.0)) / 8.0).setScale(8));
        System.debug((((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8));
        System.debug((((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8));
        System.debug((((50000 / 260.0) / 8.0).setScale(8) * 2.3909600000).setScale(8));
        System.debug((((30000 / 2.0) / (260.0 / 2.0)) / 8.0));
        System.debug((((40000 / 3.0) / (260.0 / 2.0)) / 8.0).setScale(8));
        System.debug(((45000 / (260.0 * (30.0 / 40.0))) / 8.0).setScale(8));
        System.debug(((50000 / 260.0) / 8.0).setScale(8));

        for (Time_Card__c tc : [SELECT Id, Date__c, Time_Card_Salary__c, Billing_Rate__c,  Client__r.Name FROM TIme_Card__c]) {
            System.debug('Debug tc : ' + tc.Client__r.Name + ' ' + tc.Date__c + ' ' + tc.Billing_Rate__c + ' ' + tc.Time_Card_Salary__c);
        }

        DContract__c dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        System.assertEquals((parentValue + child1Value).setScale(8), dcontractFromDB.Calculated_Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        System.assertEquals((child1Value).setScale(8), dcontractFromDB.Calculated_Services_Spend__c);

        dcontractFromDB = [SELECT Id, Name, Calculated_Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];
        System.assertEquals(0, dcontractFromDB.Calculated_Services_Spend__c);
    }

    @isTest
    public static void shouldUseUpdatedEmployeeSnapshotForCalculations() {
        DContract__c parent1 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child2 = [SELECT Id, Project_Billing_Rate__c, Services_Spend__c FROM DContract__c WHERE Name = 'Sample Child 2'];

        parent1.Project_Billing_Rate__c = 'Test Daily Rate';
        parent1.Calculated_Services_Spend__c = 0.0;
        child1.Project_Billing_Rate__c = 'Test Daily Rate';
        child1.Calculated_Services_Spend__c = 0.0;
        child2.Calculated_Services_Spend__c = 0.0;
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

        List<Time_Card__c> timeCards = new List<Time_Card__c>();

        // January : Salary -> (30000 / (260 / 2)) / 8 Billing Rate -> before 20 : (1.1 * 1.1 * 1.1 * 1.52) = 2.02312, from 20 (1.1 * 1.2 * 1.1 * 1.52) = 2.20704
        Time_Card__c timeCardObj1 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 8, Date__c = Date.newInstance(2018 , 1, 2),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj1);
        Time_Card__c timeCardObj2 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 3.0, Total__c = 4, Date__c = Date.newInstance(2018 , 1, 12),
                                                        Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj2);
        Time_Card__c timeCardObj3 = new Time_Card__c(Time_Card_Salary__c = 0, Billing_Rate__c = 2.0, Total__c = 10, Date__c = Date.newInstance(2018 , 1, 20),
                                                        Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj3);
        insert timeCards;

        Test.startTest();
        emplSnp1.Per_Week_Hours__c = 40;
        emplSnp1.Salary__c = 77000;
        update emplSnp1;
        Database.executeBatch(new TimeCardCalculator(), 200);
        Test.stopTest();

        Time_Card__c tc1 = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj1.Id];
        System.assertEquals((((77000 / 2.0) / 260.0) / 8.0).setScale(8), tc1.Time_Card_Salary__c);
        Time_Card__c tc2 = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj2.Id];
        System.assertEquals((((77000 / 2.0) / 260.0) / 8.0).setScale(8), tc2.Time_Card_Salary__c);
        Time_Card__c tc3 = [SELECT Id, Time_Card_Salary__c FROM Time_Card__c WHERE Id =: timeCardObj3.Id];
        System.assertEquals((((77000 / 2.0) / 260.0) / 8.0).setScale(8), tc2.Time_Card_Salary__c);
    }
}