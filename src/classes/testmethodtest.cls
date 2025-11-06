@isTest
public class testmethodtest {
        @isTest
public static  void unitTest() {
        Country__c cntry = new Country__c(Name = 'Test');
        insert cntry;
        Account acct = new Account(Name = 'Test Account', country__c = cntry.Id, office_type__c = 'HQ');
        insert acct;

        Project__c p = new Project__c();
        p.Name = 'Test';
        p.Project_Space_Name__c = 'Test';
        p.Status__c = 'Test';
        p.Implementing_Account__c = acct.Id;
        insert p;
    }
}