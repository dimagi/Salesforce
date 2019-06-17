@isTest
public class EmployeeTriggerTests {

    @testsetup
    static void setup() {
        Id p = [SELECT Id FROM Profile WHERE name='System Administrator'].Id;

        User user = new User(alias = 'test1234', email = 'test1234@no1email.com',
                emailencodingkey = 'UTF-8', lastname='Testing', languagelocalekey = 'en_US',
                localesidkey = 'en_US', profileid = p, country = 'United States',IsActive = true,
                timezonesidkey = 'America/Los_Angeles', username = 'tester1234@no1email.com');

        insert user;

        List<Business_Unit__c> businessUnits = new List<Business_Unit__c>();
        businessUnits.add(new Business_Unit__c(Name = 'Test Business Unit 1'));
        businessUnits.add(new Business_Unit__c(Name = 'Test Business Unit 2'));
        insert businessUnits;
    }

    @isTest
    static void testBusinessUnitNameInsert() {
        List<Business_Unit__c> businessUnits = [SELECT Id, Name FROM Business_Unit__c];

        Test.startTest();
        SFDC_Employee__c emp = new SFDC_Employee__c(
            Name = 'test employee', 
            Email_Address__c = 'tester1234@no1email.com', 
            Business_Unit__c = businessUnits[0].Id,
            Salary__c = 5000,
            Exchange_Rate__c = 10,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24)
        );
        insert emp;
        Test.stopTest();

        emp = [SELECT Id, SF_User__c, Email_Address__c, Business_Unit__c, Business_Unit__r.Name FROM SFDC_Employee__c WHERE Id =: emp.Id];
        User user = [SELECT Id, Business_Unit_Name__c FROM User WHERE Username =: emp.Email_Address__c];
        System.assertEquals(emp.SF_User__c, user.Id);
        System.assertEquals(emp.Business_Unit__r.Name, user.Business_Unit_Name__c);
    }

    @isTest static void testBusinessUnitNameUpdate() {
        List<Business_Unit__c> businessUnits = [Select Id, Name From Business_Unit__c];

        SFDC_Employee__c emp = new SFDC_Employee__c(
            Name = 'test employee',
            Email_Address__c = 'tester1234@no1email.com',
            Business_Unit__c = businessUnits[0].Id,
            Salary__c = 5000,
            Exchange_Rate__c = 10,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24)
        );
        insert emp;

        Test.startTest();
        emp.Business_Unit__c = businessUnits[1].Id;
        emp.SF_User__c = null;
        update emp;
        Test.stopTest();

        emp = [SELECT Id, SF_User__c, Email_Address__c, Business_Unit__c, Business_Unit__r.Name FROM SFDC_Employee__c WHERE Id =: emp.Id];
        User user = [SELECT Id, Business_Unit_Name__c FROM User WHERE Username =: emp.Email_Address__c];
        System.assertEquals(emp.SF_User__c, user.Id);
        System.assertEquals(emp.Business_Unit__r.Name, user.Business_Unit_Name__c);
    }
}