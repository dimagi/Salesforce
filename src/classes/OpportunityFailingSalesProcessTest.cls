@isTest
public class OpportunityFailingSalesProcessTest {

    @testSetup
    public static void setUpData() {
        insert new Opportunity(Name = 'Test Opportunity 1', StageName = 'Stage 5 - Submitted', Channel_Response__c = 'Inside Sales',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        insert new Opportunity(Name = 'Test Opportunity 2', StageName = 'Stage 5 - Submitted', Channel_Response__c = 'Inside Sales',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        insert new Opportunity(Name = 'Test Opportunity 3', StageName = 'Stage 5 - Submitted', Channel_Response__c = 'Inside Sales',
                                                 CloseDate = date.today().addMonths(5), Probability = 30, Latest_day_Opp_failed_sales_process__c = Date.today().addDays(-15),
                                                 Nb_times_Opp_failed_sales_process__c = 15,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
    }

    @isTest
    public static void shouldSetDateAndIncrementCounter() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];
        Opportunity opp3 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 3' LIMIT 1];

        Account theAccount = new Account(Name = 'Test Account');
        insert theAccount;

        Contact contact1 = new Contact(LastName = 'Test Contact 1', AccountId = theAccount.Id, Follow_up_Date__c = null, Hubspot_Next_Activity_Date__c = null); // true
        insert contact1;
        Contact contact2 = new Contact(LastName = 'Test Contact 2', AccountId = theAccount.Id, Follow_up_Date__c = Date.today().addDays(-2), Hubspot_Next_Activity_Date__c = null); // true
        insert contact2;
        Contact contact3 = new Contact(LastName = 'Test Contact 3', AccountId = theAccount.Id, Follow_up_Date__c = null, Hubspot_Next_Activity_Date__c = Date.today().addDays(-1)); // true
        insert contact3;
        Contact contact4 = new Contact(LastName = 'Test Contact 4', AccountId = theAccount.Id, Follow_up_Date__c = Date.today().addDays(-15), Hubspot_Next_Activity_Date__c = Date.today().addDays(-31)); // true
        insert contact4;
        Contact contact5 = new Contact(LastName = 'Test Contact 5', AccountId = theAccount.Id, Follow_up_Date__c = Date.today(), Hubspot_Next_Activity_Date__c = null); // false
        insert contact5;
        Contact contact6 = new Contact(LastName = 'Test Contact 6', AccountId = theAccount.Id, Follow_up_Date__c = null, Hubspot_Next_Activity_Date__c = Date.today().addDays(1)); // false
        insert contact6;

        insert new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = contact1.Id);
        insert new OpportunityContactRole(OpportunityId = opp2.Id, ContactId = contact2.Id);
        insert new OpportunityContactRole(OpportunityId = opp2.Id, ContactId = contact6.Id);
        insert new OpportunityContactRole(OpportunityId = opp3.Id, ContactId = contact2.Id);
        insert new OpportunityContactRole(OpportunityId = opp3.Id, ContactId = contact3.Id);
        insert new OpportunityContactRole(OpportunityId = opp3.Id, ContactId = contact4.Id);
        insert new OpportunityContactRole(OpportunityId = opp3.Id, ContactId = contact2.Id); // duplicated for test
        insert new OpportunityContactRole(OpportunityId = opp3.Id, ContactId = contact2.Id); // duplicated for test

        Test.startTest();
        Database.executeBatch(new OpportunityFailingSalesProcessBatch());
        Test.stopTest();

        Opportunity oppFromDB = [SELECT Id, Latest_day_Opp_failed_sales_process__c, Nb_times_Opp_failed_sales_process__c FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];
        System.assertEquals(Date.today(), oppFromDB.Latest_day_Opp_failed_sales_process__c);
        System.assertEquals(1, oppFromDB.Nb_times_Opp_failed_sales_process__c);
        oppFromDB = [SELECT Id, Latest_day_Opp_failed_sales_process__c, Nb_times_Opp_failed_sales_process__c FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];
        System.assertEquals(null, oppFromDB.Latest_day_Opp_failed_sales_process__c);
        System.assertEquals(null, oppFromDB.Nb_times_Opp_failed_sales_process__c);
        oppFromDB = [SELECT Id, Latest_day_Opp_failed_sales_process__c, Nb_times_Opp_failed_sales_process__c FROM Opportunity WHERE Name = 'Test Opportunity 3' LIMIT 1];
        System.assertEquals(Date.today(), oppFromDB.Latest_day_Opp_failed_sales_process__c);
        System.assertEquals(16, oppFromDB.Nb_times_Opp_failed_sales_process__c);
    }

    @isTest
    public static void shouldntUpdateFields() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];
        Opportunity opp3 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 3' LIMIT 1];

        Account theAccount = new Account(Name = 'Test Account');
        insert theAccount;

        Contact contact1 = new Contact(LastName = 'Test Contact 1', AccountId = theAccount.Id, Follow_up_Date__c = null, Hubspot_Next_Activity_Date__c = null); // true
        insert contact1;
        Contact contact2 = new Contact(LastName = 'Test Contact 2', AccountId = theAccount.Id, Follow_up_Date__c = Date.today().addDays(-1), Hubspot_Next_Activity_Date__c = null); // true
        insert contact2;
        Contact contact3 = new Contact(LastName = 'Test Contact 3', AccountId = theAccount.Id, Follow_up_Date__c = null, Hubspot_Next_Activity_Date__c = Date.today().addDays(-1)); // true
        insert contact3;
        Contact contact4 = new Contact(LastName = 'Test Contact 4', AccountId = theAccount.Id, Follow_up_Date__c = Date.today().addDays(-15), Hubspot_Next_Activity_Date__c = Date.today().addDays(-31)); // true
        insert contact4;
        Contact contact5 = new Contact(LastName = 'Test Contact 5', AccountId = theAccount.Id, Follow_up_Date__c = Date.today(), Hubspot_Next_Activity_Date__c = null); // false
        insert contact5;
        Contact contact6 = new Contact(LastName = 'Test Contact 6', AccountId = theAccount.Id, Follow_up_Date__c = null, Hubspot_Next_Activity_Date__c = Date.today().addDays(1)); // false
        insert contact6;

        insert new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = contact5.Id);
        insert new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = contact6.Id);
        insert new OpportunityContactRole(OpportunityId = opp2.Id, ContactId = contact2.Id);
        insert new OpportunityContactRole(OpportunityId = opp2.Id, ContactId = contact6.Id);

        Test.startTest();
        Database.executeBatch(new OpportunityFailingSalesProcessBatch());
        Test.stopTest();

        Opportunity oppFromDB = [SELECT Id, Latest_day_Opp_failed_sales_process__c, Nb_times_Opp_failed_sales_process__c FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];
        System.assertEquals(null, oppFromDB.Latest_day_Opp_failed_sales_process__c);
        System.assertEquals(null, oppFromDB.Nb_times_Opp_failed_sales_process__c);
        oppFromDB = [SELECT Id, Latest_day_Opp_failed_sales_process__c, Nb_times_Opp_failed_sales_process__c FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];
        System.assertEquals(null, oppFromDB.Latest_day_Opp_failed_sales_process__c);
        System.assertEquals(null, oppFromDB.Nb_times_Opp_failed_sales_process__c);
        oppFromDB = [SELECT Id, Latest_day_Opp_failed_sales_process__c, Nb_times_Opp_failed_sales_process__c FROM Opportunity WHERE Name = 'Test Opportunity 3' LIMIT 1];
        System.assertEquals(Date.today().addDays(-15), oppFromDB.Latest_day_Opp_failed_sales_process__c);
        System.assertEquals(15, oppFromDB.Nb_times_Opp_failed_sales_process__c);
    }
}