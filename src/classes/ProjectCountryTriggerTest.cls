/**
 * Tests the updates of the Country_Text__c field in Project with the names of the Project Countries
 *
 * @author  Virginia Fernández
 * @date    04/12/2013
 */
@isTest
private class ProjectCountryTriggerTest {

    static testMethod void newProjectCountryTest() {
    	Account account = new Account();
    	account.Name = 'Account';
    	insert account;
    	
        Project__c project = new Project__c();
        project.Name = 'Project';
        project.Implementing_Account__c = account.Id;
        insert project;
        
        Country__c country1 = new Country__c();
        country1.Name = 'Country1';
        insert country1;
        
        Country__c country2 = new Country__c();
        country2.Name = 'Country2';
        insert country2;
        
        Test.startTest();
        
        ProjectCountry__c projCountry1 = new ProjectCountry__c();
        projCountry1.Country__c = country1.Id;
        projCountry1.Project__c = project.Id;
        insert projCountry1;
        
        project = [select Id, Country_Text__c from Project__c where id =: project.Id];
        System.assertEquals(project.Country_Text__c, 'Country1');
        
        ProjectCountry__c projCountry2 = new ProjectCountry__c();
        projCountry2.Country__c = country2.Id;
        projCountry2.Project__c = project.Id;
        insert projCountry2;
        
        project = [select Id, Country_Text__c from Project__c where id =: project.Id];
        System.assertEquals(project.Country_Text__c, 'Country2; Country1');
        
        Test.stopTest();
        
    }
    
    static testMethod void deleteProjectCountryTest() {
        Account account = new Account();
        account.Name = 'Account';
        insert account;
        
        Project__c project = new Project__c();
        project.Name = 'Project';
        project.Implementing_Account__c = account.Id;
        insert project;
        
        Country__c country1 = new Country__c();
        country1.Name = 'Country1';
        insert country1;
        
        Country__c country2 = new Country__c();
        country2.Name = 'Country2';
        insert country2;
        
        ProjectCountry__c projCountry1 = new ProjectCountry__c();
        projCountry1.Country__c = country1.Id;
        projCountry1.Project__c = project.Id;
        insert projCountry1;
        
        ProjectCountry__c projCountry2 = new ProjectCountry__c();
        projCountry2.Country__c = country2.Id;
        projCountry2.Project__c = project.Id;
        insert projCountry2;
        
        Test.startTest();
        
        project = [select Id, Country_Text__c from Project__c where id =: project.Id];
        System.assertEquals(project.Country_Text__c, 'Country2; Country1');
        
        delete projCountry2;
        
        project = [select Id, Country_Text__c from Project__c where id =: project.Id];
        System.assertEquals(project.Country_Text__c, 'Country1');
        
        Test.stopTest();
        
    }
}