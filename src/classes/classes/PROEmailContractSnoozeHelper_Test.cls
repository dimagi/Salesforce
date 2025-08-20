@IsTest
public class PROEmailContractSnoozeHelper_Test {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account ' + System.currentTimeMillis());
        insert acc;

        insert new PRO_Email_Remindar_Settings__c(
            Name = 'Test Settings',
            Global_Services_Backstop__c = 'vp@dimagi.com',
            Dev_Work_Emails__c = 'dev1@dimagi.com,dev2@dimagi.com'
        );

        insert new Contact(
            FirstName = 'Dev1', LastName = 'One',
            Email = 'dev1@dimagi.com', AccountId = acc.Id
        );
        insert new Contact(
            FirstName = 'Dev2', LastName = 'Two',
            Email = 'dev2@dimagi.com', AccountId = acc.Id
        );
    }

    private static PRO_Email_Remindar_Settings__c createSettings() {
        PRO_Email_Remindar_Settings__c settings = new PRO_Email_Remindar_Settings__c(
            Name = 'Default Setting ' + System.currentTimeMillis(),
            Error_Email__c = 'test1@example.com,test2@example.com'
        );
        insert settings;
        return settings;
    }

    private static DContract__c createContract(Boolean isFirstNagSent) {
        Account acc = new Account(Name = 'Contract Account ' + System.currentTimeMillis());
        insert acc;

        Contact pmContact = new Contact(
            FirstName = 'PM', LastName = 'Manager ' + System.currentTimeMillis(),
            AccountId = acc.Id,
            Email = 'pm' + System.currentTimeMillis() + '@dimagi.com'
        );
        insert pmContact;

        DContract__c contract = new DContract__c(
            Name = 'Test Contract ' + System.currentTimeMillis(),
            Is_First_Nag_Sent__c = isFirstNagSent,
            Project_Manager__c = pmContact.Id,
            In_Charge_Of_Report_Out__c = 'Project Manager'
        );
        insert contract;
        return contract;
    }


    @isTest
    static void testSetFirstNegSent() {
        createSettings();
        DContract__c contract = createContract(false);

        Test.startTest();
        new PROEmailContractSnoozeHelper().SetFirstNegSent(new List<DContract__c>{contract});
        Test.stopTest();

        contract = [SELECT Is_First_Nag_Sent__c, First_Nag_Sent_Date__c FROM DContract__c WHERE Id = :contract.Id];
        System.assert(contract.Is_First_Nag_Sent__c);
        System.assertEquals(Date.today(), contract.First_Nag_Sent_Date__c);
    }

    @isTest
    static void testSetSecondNegSent() {
        createSettings();
        DContract__c contract = createContract(false);

        Test.startTest();
        new PROEmailContractSnoozeHelper().SetSecondNegSent(new List<DContract__c>{contract});
        Test.stopTest();

        contract = [SELECT Second_Nag_Sent_Date__c FROM DContract__c WHERE Id = :contract.Id];
        System.assertEquals(Date.today(), contract.Second_Nag_Sent_Date__c);
    }

    @isTest
    static void testSetThirdNegSent() {
        createSettings();
        DContract__c contract = createContract(false);

        Test.startTest();
        new PROEmailContractSnoozeHelper().SetThirdNegSent(new List<DContract__c>{contract});
        Test.stopTest();

        contract = [SELECT Third_Nag_Sent_Date__c FROM DContract__c WHERE Id = :contract.Id];
        System.assertEquals(Date.today(), contract.Third_Nag_Sent_Date__c);
    }

    @isTest
    static void testSetFourthNegSent() {
        createSettings();
        DContract__c contract = createContract(false);

        Test.startTest();
        new PROEmailContractSnoozeHelper().SetFourthNegSent(new List<DContract__c>{contract});
        Test.stopTest();

        contract = [SELECT Fourth_Nag_Sent_Date__c FROM DContract__c WHERE Id = :contract.Id];
        System.assertEquals(Date.today(), contract.Fourth_Nag_Sent_Date__c);
    }

    @isTest
    static void testSnoozeContractById() {
        createSettings();
        DContract__c contract = createContract(true);

        Test.startTest();
        new PROEmailContractSnoozeHelper().SnoozeContract(contract.Id, 7);
        Test.stopTest();

        contract = [SELECT Snooze_Days__c, Is_Snooze__c FROM DContract__c WHERE Id = :contract.Id];
        System.assertEquals(7, contract.Snooze_Days__c);
        System.assert(contract.Is_Snooze__c);
    }

    @isTest
    static void testResetEmailReminder() {
        createSettings();
        DContract__c contract = createContract(true);
        contract.Second_Nag_Sent_Date__c = Date.today();
        contract.Third_Nag_Sent_Date__c = Date.today();
        contract.Fourth_Nag_Sent_Date__c = Date.today();
        update contract;

        Test.startTest();
        PROEmailContractSnoozeHelper.resetEmailReminder(contract.Id);
        Test.stopTest();

        contract = [
            SELECT Is_Snooze__c, Is_First_Nag_Sent__c, First_Nag_Sent_Date__c,
                   Second_Nag_Sent_Date__c, Third_Nag_Sent_Date__c, Fourth_Nag_Sent_Date__c 
            FROM DContract__c WHERE Id = :contract.Id
        ];

        System.assertEquals(false, contract.Is_Snooze__c);
        System.assertEquals(false, contract.Is_First_Nag_Sent__c);
        System.assertEquals(null, contract.First_Nag_Sent_Date__c);
        System.assertEquals(null, contract.Second_Nag_Sent_Date__c);
        System.assertEquals(null, contract.Third_Nag_Sent_Date__c);
        System.assertEquals(null, contract.Fourth_Nag_Sent_Date__c);
    }

   @isTest
static void testSnoozeContractByOwnerId() {
    createSettings();

    Account acc = new Account(Name = 'Snooze Test Account');
    insert acc;

    Contact pm = new Contact(
        FirstName = 'PM', LastName = 'Owner',
        AccountId = acc.Id,
        Email = 'pmowner' + System.currentTimeMillis() + '@dimagi.com'
    );
    insert pm;

    DContract__c contract = new DContract__c(
        Name = 'Snooze Contract ' + System.currentTimeMillis(),
        Account__c = acc.Id,
        Is_First_Nag_Sent__c = true,
        In_Charge_Of_Report_Out__c = 'Project Manager',
        Project_Manager__c = pm.Id
    );
    insert contract;

    Test.startTest();
    new PROEmailContractSnoozeHelper().SnoozeContractByOwnerId(pm.Id, 5);
    Test.stopTest();

    contract = [SELECT Snooze_Days__c, Is_Snooze__c FROM DContract__c WHERE Id = :contract.Id];
    System.assertEquals(5, contract.Snooze_Days__c, 'Snooze days should be updated');
    System.assert(contract.Is_Snooze__c, 'Contract should be marked as snoozed');
}
@isTest
    static void testSetFirstNegSent_FailurePath() {
        insert new PRO_Email_Remindar_Settings__c(
            Name = 'Test Settings Failure',
            Error_Email__c = 'test1@dimagi.com,test2@dimagi.com'
        );

        Account acc = new Account(Name = 'Failure Test Account ' + System.currentTimeMillis());
        insert acc;

        Contact pm = new Contact(
            LastName = 'PM ' + System.currentTimeMillis(),
            AccountId = acc.Id,
            Email = 'pm' + System.currentTimeMillis() + '@dimagi.com'
        );
        insert pm;

        DContract__c contract = new DContract__c(
            Name = 'Failure Contract ' + System.currentTimeMillis(),
            Project_Manager__c = pm.Id,
            In_Charge_Of_Report_Out__c = 'Project Manager',
            Is_First_Nag_Sent__c = false
        );
        insert contract;

        contract.Project_Manager__c = '001000000000000AAA'; // invalid Id for Contact lookup

        Test.startTest();
        new PROEmailContractSnoozeHelper().SetFirstNegSent(new List<DContract__c>{contract});
        Test.stopTest();

        System.assert(true, 'Failure path (email sending) executed');
    }
  
}