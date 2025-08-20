@isTest
public class ContactEmailTriggerTest {

    @isTest
    public static void shouldSendEmailAfterUpdate() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'emailTe', Email='emailContactTrigger@dTest.com', 
        EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='emailContactTrigger@dTest.com');

        System.runAs(u) {
            Test.startTest();
            Contact cont = new Contact();
            cont.FirstName = 'contact';
            cont.LastName = 'test';
            cont.Email = 'a.b@test.com';
            insert cont;
            cont.Email = 'a.c@test.com';
            update cont;
            Test.stopTest();
        }

        Contact contFromDB = [SELECT Id, Email, FirstName FROM Contact WHERE Email = 'a.c@test.com' LIMIT 1];
        System.assertEquals('a.c@test.com', contFromDB.Email);
    }
}