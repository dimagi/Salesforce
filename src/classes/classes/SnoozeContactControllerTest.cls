@isTest
public class SnoozeContactControllerTest {

    @isTest
    public static void testMethod1() {
        Account theAccount = new Account(
            Name = 'Test Account'
        );
        insert theAccount;
        Contact theContact = new Contact(
            LastName = 'Test Contact',
            AccountId = theAccount.Id
        );
        insert theContact;

        ApexPages.currentPage().getParameters().put('id', theContact.Id);
        SnoozeContactController obj = new SnoozeContactController ();
        obj.autoRun();
        Task theTask = [SELECT id FROM Task WHERE WhoId =: theContact.Id];
        System.assertNotEquals(theTask,null);
    }
}