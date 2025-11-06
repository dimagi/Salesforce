@IsTest
private class ScriptBatchJobTest {
    
    @TestSetup
    static void setupTestData() {
        List<SFDC_Employee__c> employees = new List<SFDC_Employee__c>{
            new SFDC_Employee__c(Name = 'Contractor Employee',Exchange_Rate__c = 10),
            new SFDC_Employee__c(Name = 'Regular Employee',Exchange_Rate__c = 15)
        };
        insert employees;
        
        
        
        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        Date testDate = Date.newInstance(2018, 1, 1); // After threshold
        
        timeCards.add(new Time_Card__c(
            Employee__c = employees[0].Id,
            Date__c = testDate,
            Time_Card_Salary__c = 100.00,
            Billing_Rate__c = null
        ));
        
        timeCards.add(new Time_Card__c(
            Employee__c = employees[1].Id,
            Date__c = testDate,
            Time_Card_Salary__c = 100.00,
            Billing_Rate__c = null
        ));
        
        timeCards.add(new Time_Card__c(
            Employee__c = employees[0].Id,
            Date__c = Date.newInstance(2016, 1, 1), 
            Time_Card_Salary__c = 100.00,
            Billing_Rate__c = null
        ));
        
        insert timeCards;
    }
    
    @IsTest
    static void testConstructorWithDefaultDate() {
        Test.startTest();
        ScriptBatchJob batch = new ScriptBatchJob();
        Test.stopTest();
        
        System.assertEquals(Date.today(), batch.helperDate, 'Helper date should be set to today');
    }
    
    @IsTest
    static void testConstructorWithCustomDate() {
        Date testDate = Date.newInstance(2020, 1, 1);
        
        Test.startTest();
        ScriptBatchJob batch = new ScriptBatchJob(testDate);
        Test.stopTest();
        
        System.assertEquals(testDate, batch.helperDate, 'Helper date should be set to provided date');
    }
    
    @IsTest
    static void testStartMethod() {
        ScriptBatchJob batch = new ScriptBatchJob();
        
        Test.startTest();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
        
        String queryString = ql.getQuery();
        System.assert(queryString.contains('SELECT Id, Client__c, Client__r.Project_Billing_Rate__c, Employee__c, Time_Card_Salary__c, Billing_Rate__c, Date__c'), 'Query should select required fields');
        System.assert(queryString.contains('FROM Time_Card__c'), 'Query should be on Time_Card__c');
        System.assert(queryString.contains('Date__c >=: dateThreshold'), 'Query should filter by date threshold');
        System.assert(queryString.contains('ORDER BY Employee__c, Date__c'), 'Query should have correct ordering');
    }
    
  
    
    @IsTest
    static void testFinishMethod() {
        ScriptBatchJob batch = new ScriptBatchJob();
        
        Test.startTest();
        batch.finish(null);
        Test.stopTest();
        
        System.assert(true, 'Finish method should execute without errors');
    }
    
    @IsTest
    static void testBatchExecution() {
        ScriptBatchJob batch = new ScriptBatchJob();
        
        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();
        
        AsyncApexJob job = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors 
                           FROM AsyncApexJob 
                           WHERE Id = :batchId];
        
        System.assertEquals('Completed', job.Status, 'Batch job should complete successfully');
        System.assertEquals(0, job.NumberOfErrors, 'Batch job should complete without errors');
    }
}