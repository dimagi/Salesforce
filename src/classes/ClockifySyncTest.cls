@isTest
public class ClockifySyncTest {
    @TestSetup
    static void createData(){
        Time_Card__c tcard = new Time_Card__c();
        SFDC_Employee__c emp = new SFDC_Employee__c();
        emp.Name = 'Employee 1';
        emp.Email_Address__c = 'employee@dimagi.com';
        emp.Exchange_Rate__c = 1;
        emp.Employee_Status__c = 'Active';
        emp.Employee_Type__c = 'Employee';
        emp.Hire_Date__c = System.today() - 180;
        insert emp;
        
        DContract__c client = new DContract__c();
        client.Name = 'Overhead';
        insert client;
        tcard.Time_Entry_ID__c = '600d7f09843909186990142g';
        tcard.Date__c = System.today();
        tcard.Employee__c = emp.Id;
        insert tcard;
        
        Clockify_Settings__c clockifySetting = new Clockify_Settings__c();
        clockifySetting.Name__c = 'Clockify';
        clockifySetting.Page_Size__c = 5;
        clockifySetting.XApikey__c = 'APIKEY';
        clockifySetting.URL__c = 'Clockify/test.org/timeEntries';
        insert clockifySetting;
       	System.debug('client: '+client);
    }
    @isTest
    public static void ClockifyManualCalloutController(){
        //visual force page controller
        List<Time_Card__c> timeCard = [SELECT Id from Time_Card__c where Employee__r.Name = 'Employee 1' LIMIT 1];
        PageReference pageRef = Page.ClockifyManualCallout;
        Test.setCurrentPage(pageRef);
        Test.startTest();
        pageRef.getParameters().put('Id', String.valueOf(timeCard[0].Id));
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(timeCard);
        ClockifyManualCallout clockifyManualCalloutCtrl =  new ClockifyManualCallout(sc);
        clockifyManualCalloutCtrl.runRecalculation();
        System.assert(ApexPages.hasMessages(ApexPages.SEVERITY.CONFIRM));
        Test.stopTest();
        
    }
    @isTest
    public static void testBackPage(){
        List<Time_Card__c> timeCard = [SELECT Id from Time_Card__c where Employee__r.Name = 'Employee 1' LIMIT 1];
        PageReference pageRef = Page.ClockifyManualCallout;
        Test.setCurrentPage(pageRef);
        Test.startTest();
        pageRef.getParameters().put('Id', String.valueOf(timeCard[0].Id));
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(timeCard);
        ClockifyManualCallout clockifyManualCalloutCtrl =  new ClockifyManualCallout(sc);
        clockifyManualCalloutCtrl.goBack();
        Test.stopTest();
        
        System.assertEquals(false, pageRef.getRedirect());
    }
    @isTest
    public static void testClockifySyncBatch(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ClockifyAPIMockCallout());
        Database.executeBatch(new ClockifySyncBatch(), 1);
        Test.stopTest();
        Time_Card__c timeCard = [SELECT Id,Time_Entry_ID__c,Employee__r.Name from Time_Card__c WHERE Employee__r.Name = 'Employee 1' LIMIT 1];
        System.debug('Employee : ' +timeCard.Employee__r.Name);
        System.assertEquals('Employee 1', timeCard.Employee__r.Name);
    }
    @isTest
    public static void exceptionNonUser(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ClockifyNonUserMock());
        Database.executeBatch(new ClockifySyncBatch(), 1);
        Test.stopTest();
        List<Status_log__c> errorLogs = [SELECT Id,message__c from Status_log__c WHERE Createddate = today];
        System.debug('errorLogs : ' +errorLogs.size());
        System.assert(errorLogs.size()>0) ;
    }
    @isTest
    public static void testClockifySyncScheduler(){
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new ClockifyAPIMockCallout());
        ClockifySyncScheduler sh1 = new ClockifySyncScheduler();
        
        String sch = '0 0 10 ? * WED'; 
        System.schedule('Clockify Sync', sch, sh1); 
        Test.stopTest(); 
    }
}