@isTest
public class TimeCardTriggerControllerTest {

    @testSetup
    public static void addTestData() {
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24), Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24));
        insert employeeObj;

        DContract__c parent1 = new DContract__c(Name = 'Sample Parent 1', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent1;

        DContract__c child1 = new DContract__c(Name = 'Sample Child 1', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child1;

        DContract__c child2 = new DContract__c(Name = 'Sample Child 2', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent1.Id);
        insert child2;

        DContract__c parent2 = new DContract__c(Name = 'Sample Parent 2', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'No');
        insert parent2;

        DContract__c child3 = new DContract__c(Name = 'Sample Child 3', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent2.Id);
        insert child3;

        DContract__c child4 = new DContract__c(Name = 'Sample Child 4', Status__c = 'Active', Requires_Report_Out__c = 'No', Intracompany_Sub_contract__c = 'Yes', Parent_Contract__c = parent2.Id);
        insert child4;

        Time_Card__c timeCardObj = new Time_Card__c(Total__c = 4, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = parent2.Id);
        insert timeCardObj;
        update new DContract__c(Id = parent2.Id, Require_Services_Spend_Refresh__c = false);
    }

    @isTest
    public static void shouldMarkContractsAfterTimeCardInsert() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child3 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 3'];
        DContract__c child4 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 4'];
        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        Test.startTest();
        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        Time_Card__c timeCardObj1 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj1);
        Time_Card__c timeCardObj2 = new Time_Card__c(Total__c = 4, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj2);
        Time_Card__c timeCardObj3 = new Time_Card__c(Total__c = 10, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child3.Id);
        timeCards.add(timeCardObj3);
        Time_Card__c timeCardObj4 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child4.Id);
        timeCards.add(timeCardObj4);

        insert timeCards;
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
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
    public static void shouldMarkContractsAfterTimeCardDelete() {
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child3 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 3'];
        DContract__c child4 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 4'];
        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        Time_Card__c timeCardObj1 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child1.Id);
        timeCards.add(timeCardObj1);
        Time_Card__c timeCardObj2 = new Time_Card__c(Total__c = 4, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = parent1.Id);
        timeCards.add(timeCardObj2);
        Time_Card__c timeCardObj3 = new Time_Card__c(Total__c = 10, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child3.Id);
        timeCards.add(timeCardObj3);
        Time_Card__c timeCardObj4 = new Time_Card__c(Total__c = 8, Date__c = Date.today().addMonths(-2), Employee__c = employeeObj.Id, Client__c = child4.Id);
        timeCards.add(timeCardObj4);
        insert timeCards;

        Test.startTest();
        delete timeCards;
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
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
    public static void shouldNotMarkContractsAfterTimeCardUpdate() { // Update cannot change employee client or time field - inserted and deleted in such case
        DContract__c parent1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Parent 1'];
        DContract__c child1 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 1'];
        DContract__c child3 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 3'];
        DContract__c child4 = [SELECT Id FROM DContract__c WHERE Name = 'Sample Child 4'];
        SFDC_Employee__c employeeObj = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Sample Employee'];

        Test.startTest();
        Time_Card__c tc = [SELECT Id FROM Time_Card__c LIMIT 1];
        update tc;
        Test.stopTest();

        DContract__c dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Parent 1'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Parent 2'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Child 1'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Child 2'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Child 3'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
        dcontractFromDB = [SELECT Id, Name, Require_Services_Spend_Refresh__c FROM DContract__c WHERE Name = 'Sample Child 4'];
        System.assertEquals(false, dcontractFromDB.Require_Services_Spend_Refresh__c);
    }
}