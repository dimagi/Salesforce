@isTest
private class ProjectTriggerSyncTest {

    @isTest
    static void testProjectTriggerSyncFlow() {
        Country__c cntry = new Country__c(Name = 'Test');
        insert cntry;

        Account acct = new Account(Name='Test Account', Country__c = cntry.Id, Office_Type__c = 'HQ');
        insert acct;

        Project__c p = new Project__c(
            Name = 'Test',
            Project_Space_Name__c = 'Test',
            Status__c = 'Test',
            Implementing_Account__c = acct.Id
        );
        insert p;

        Country__c c = new Country__c(Name = 'United States');
        insert c; 

        Location__c l = new Location__c(Country__c = c.Id, Name = 'Los Angeles');
        insert l;

        Project_Location__c pl = new Project_Location__c(Project__c = p.Id, Location__c = l.Id);
        insert pl;

        Project_Location__c pl2 = new Project_Location__c(Project__c = p.Id, Location__c = l.Id);
        insert pl2;

        delete pl;

        p.Status__c = 'Complete';
        update p;
    }
}