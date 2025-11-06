@isTest
public class PROEmailTest {

    @testSetup
    public static void setUp() {
        PRO_Email_Remindar_Settings__c settings = PRO_Email_Remindar_Settings__c.getOrgDefaults();
        settings.Name = 'Test_Settings';
        settings.Dev_Work_Emails__c = 'sample@sample.com';
        settings.First_Nag_Days__c = 4;
        settings.Second_Nag_Days__c = 1;
        settings.Third_Nag_Days__c = 3;
        settings.Fourth_Nag_Days__c = 7;
        insert settings;
        
    }

    @isTest
    public static void PROSnoozeTestContract(){
        DContract__C contract = new DContract__C(Name = 'C Test 1', Is_First_Nag_Sent__c = true, Is_Snooze__c = false);
        insert contract;

        PageReference pageRef = Page.SnoozePRO;
        pageRef.getParameters().put('id', contract.Id);
        pageRef.getParameters().put('NoOfDays', '5');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        SnoozePROController snoozeCtrl = new SnoozePROController();
        snoozeCtrl.SnoozePRO();
        Test.stopTest();

        DContract__C contractFromDB = [SELECT Id, Is_Snooze__c, Snooze_Date__c, Snooze_Days__c, Is_First_Nag_Sent__c, First_Nag_Sent_Date__c, Second_Nag_Sent_Date__c,
                                       Third_Nag_Sent_Date__c, Fourth_Nag_Sent_Date__c FROM DContract__c WHERE Id =: contract.Id LIMIT 1];
        System.assertEquals(true, contractFromDB.Is_Snooze__c);
        System.assertEquals(Date.today(), contractFromDB.Snooze_Date__c);
        System.assertEquals(5, contractFromDB.Snooze_Days__c);
        System.assertEquals(false, contractFromDB.Is_First_Nag_Sent__c);
        System.assertEquals(null, contractFromDB.First_Nag_Sent_Date__c);
        System.assertEquals(null, contractFromDB.Second_Nag_Sent_Date__c);
        System.assertEquals(null, contractFromDB.Third_Nag_Sent_Date__c);
        System.assertEquals(null, contractFromDB.Fourth_Nag_Sent_Date__c);
    }

    @isTest
    public static void PROSnoozeTestOwner(){
        Account acc = new Account(Name = 'Acc 1', Status__c = 'Active');
        insert acc;
        Contact simpleTestContact = new Contact(Email = 'test1@dimagi.com', FirstName = 'Contact', LastName = '1', AccountId = acc.Id);
        insert simpleTestContact;
        DContract__C contract = new DContract__C(Name = 'C Test 1', Is_First_Nag_Sent__c = true, Is_Snooze__c = false,
                                                 In_Charge_Of_Report_Out__c = 'Project Manager', Project_Manager__C = simpleTestContact.Id);
        insert contract;

        PageReference pageRef = Page.SnoozePRO;
        pageRef.getParameters().put('NoOfDays', '15');
        pageRef.getParameters().put('OwnerId', simpleTestContact.Id);
        Test.setCurrentPage(pageRef);

        Test.startTest();
        SnoozePROController snoozeCtrl = new SnoozePROController();
        snoozeCtrl.SnoozePRO();
        Test.stopTest();

        DContract__C contractFromDB = [SELECT Id, Is_Snooze__c, Snooze_Date__c, Snooze_Days__c, Is_First_Nag_Sent__c, First_Nag_Sent_Date__c, Second_Nag_Sent_Date__c,
                                       Third_Nag_Sent_Date__c, Fourth_Nag_Sent_Date__c FROM DContract__c WHERE Id =: contract.Id LIMIT 1];
        System.assertEquals(true, contractFromDB.Is_Snooze__c);
        System.assertEquals(Date.today(), contractFromDB.Snooze_Date__c);
        System.assertEquals(15, contractFromDB.Snooze_Days__c);
        System.assertEquals(false, contractFromDB.Is_First_Nag_Sent__c);
        System.assertEquals(null, contractFromDB.First_Nag_Sent_Date__c);
        System.assertEquals(null, contractFromDB.Second_Nag_Sent_Date__c);
        System.assertEquals(null, contractFromDB.Third_Nag_Sent_Date__c);
        System.assertEquals(null, contractFromDB.Fourth_Nag_Sent_Date__c);
    }

    @isTest
    public static void testThursdayUtils() {
        List<Date> decList = PROHelper.getAllThursdayOfMonth(2018, 12);
        List<Date> janList = PROHelper.getAllThursdayOfMonth(2019, 1);
        List<Date> febList = PROHelper.getAllThursdayOfMonth(2019, 2);

        System.assertEquals(Date.newInstance(2018, 12, 6), decList.get(0));
        System.assertEquals(Date.newInstance(2018, 12, 13), decList.get(1));
        System.assertEquals(Date.newInstance(2018, 12, 20), decList.get(2));
        System.assertEquals(Date.newInstance(2018, 12, 27), decList.get(3));

        System.assertEquals(Date.newInstance(2019, 1, 3), janList.get(0));
        System.assertEquals(Date.newInstance(2019, 1, 10), janList.get(1));
        System.assertEquals(Date.newInstance(2019, 1, 17), janList.get(2));
        System.assertEquals(Date.newInstance(2019, 1, 24), janList.get(3));
        System.assertEquals(Date.newInstance(2019, 1, 31), janList.get(4));

        System.assertEquals(Date.newInstance(2019, 2, 7), febList.get(0));
        System.assertEquals(Date.newInstance(2019, 2, 14), febList.get(1));
        System.assertEquals(Date.newInstance(2019, 2, 21), febList.get(2));
        System.assertEquals(Date.newInstance(2019, 2, 28), febList.get(3));

        List<Date> testList = new List<Date>();
        testList.addAll(decList);
        testList.addAll(janList);
        testList.addAll(febList);
        for (Date testDate : testList) {
            System.assert(PROHelper.isThursday(testDate));
        }

        System.assertEquals(false, PROHelper.isThursday(Date.newInstance(2019 , 2, 11)));
        System.assertEquals(false, PROHelper.isThursday(Date.newInstance(2019 , 2, 12)));
        System.assertEquals(false, PROHelper.isThursday(Date.newInstance(2019 , 2, 13)));
        System.assertEquals(true, PROHelper.isThursday(Date.newInstance(2019 , 2, 14)));
        System.assertEquals(false, PROHelper.isThursday(Date.newInstance(2019 , 2, 15)));
        System.assertEquals(false, PROHelper.isThursday(Date.newInstance(2019 , 2, 16)));
        System.assertEquals(false, PROHelper.isThursday(Date.newInstance(2019 , 2, 17)));
    }

    @isTest
    public static void testContractFilterHelper(){
        List<DContract__c> contractList = addContractsWithPRO();

        Test.startTest();
        PROEmailContractFilterHelper filterHelper = new PROEmailContractFilterHelper();
        filterHelper.currentDate = Date.newInstance(2019, 9, 17); // Mocka today, it should return last thursday 12.09.2019
        List<DContract__c> firstList = filterHelper.filter(contractList, ProEmailContractFilterType.FirstNag);
        List<DContract__c> secondList = filterHelper.filter(contractList, ProEmailContractFilterType.SecondNag);
        List<DContract__c> thirdList = filterHelper.filter(contractList, ProEmailContractFilterType.ThirdNag);
        List<DContract__c> fourthtList = filterHelper.filter(contractList, ProEmailContractFilterType.FourthNag);
        Test.stopTest();

        System.assertEquals(4, firstList.size());
        System.assertEquals(5, secondList.size());
        System.assertEquals(2, thirdList.size());
        System.assertEquals(3, fourthtList.size());
    }

    @isTest
    public static void testPROEmailTemplateHelper(){
        List<DContract__c> contractList = addContractsWithPRO();

        Test.startTest();

        PROEmailTemplateHelper templateHelper = new PROEmailTemplateHelper();

        System.assertNotEquals(null, templateHelper.GetProjectInchargeEmailTemplate('Test', contractList[0].OwnerId, contractList, ProEmailContractFilterType.FirstNag));
        System.assertNotEquals(null, templateHelper.GetProjectInchargeEmailTemplate('Test', contractList[0].OwnerId, contractList, ProEmailContractFilterType.SecondNag));
        System.assertNotEquals(null, templateHelper.GetBackstopEmailTemplate('Test1', contractList));
        System.assertNotEquals(null, templateHelper.GetThirdNagEmailTemplate(contractList));
        System.assertNotEquals(null, templateHelper.GetFourthNagEmailTemplate(contractList));

        Test.stopTest();
    }

    @isTest
    public static void PROEmailJobTest() {
        List<DContract__c> contractList = addContractsWithPRO();

        Test.startTest();

        PROEmailRemindarBatch batchJob = new PROEmailRemindarBatch();
        batchJob.contractFilterHelper.currentDate = Date.newInstance(2025, 6, 6);
        batchJob.execute(null, batchJob.start(null));
        batchJob.finish(null);

        Test.stopTest();

        System.assertEquals(4, batchJob.firstNagProcessed.size());
        System.assertEquals(0, batchJob.secondNagProcessed.size());
        System.assertEquals(0, batchJob.thirdNagProcessed.size());
        System.assertEquals(0, batchJob.fourthNagProcessed.size());
    }

    @isTest
    public static void testPROClearDataJob() {
        DContract__c contract1 = new DContract__c(Name = 'test contract', Snooze_Date__c = Date.today(), Snooze_Days__c = 11, Is_Snooze__c = true, Is_First_Nag_Sent__c = true,
                                                 First_Nag_Sent_Date__c = Date.today(), Second_Nag_Sent_Date__c = Date.today(), Third_Nag_Sent_Date__c = Date.today(),
                                                 Fourth_Nag_Sent_Date__c = Date.today(), Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes');
        insert contract1;
        DContract__c contract2 = new DContract__c(Name = 'test contract', Snooze_Date__c = Date.today(), Snooze_Days__c = 11, Is_Snooze__c = true, Is_First_Nag_Sent__c = true,
                                                 First_Nag_Sent_Date__c = Date.today(), Second_Nag_Sent_Date__c = Date.today(), Third_Nag_Sent_Date__c = Date.today(),
                                                 Fourth_Nag_Sent_Date__c = Date.today(), Workflow_Escalation_Enabled__c = true,Requires_Report_Out__c = 'Yes');
        insert contract2;
        insert new Project_Report_Out__c(Name = 'Test 1', Contract__c = contract1.Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22));
        insert new Project_Report_Out__c(Name = 'Test 2', Contract__c = contract2.Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22));

        Test.startTest();
        PROEmailRemindarClearDataBatch batchJob = new PROEmailRemindarClearDataBatch();
        batchJob.currentDate = Date.newInstance(2019, 10, 10);
        Database.executeBatch(batchJob);
        Test.stopTest();

        Integer counter = 0;
        for (DContract__c testContract : [SELECT Is_Snooze__c, Snooze_Date__c, Snooze_Days__c, Is_First_Nag_Sent__c,
                                          First_Nag_Sent_Date__c, Second_Nag_Sent_Date__c, Third_Nag_Sent_Date__c, Fourth_Nag_Sent_Date__c
                                          FROM DContract__c]) {
            System.assertEquals(false, testContract.Is_Snooze__c);
            System.assertEquals(null, testContract.Snooze_Date__c);
            System.assertEquals(null, testContract.Snooze_Days__c);
            System.assertEquals(false, testContract.Is_First_Nag_Sent__c);
            System.assertEquals(null, testContract.First_Nag_Sent_Date__c);
            System.assertEquals(null, testContract.Second_Nag_Sent_Date__c);
            System.assertEquals(null, testContract.Third_Nag_Sent_Date__c);
            System.assertEquals(null, testContract.Fourth_Nag_Sent_Date__c);
            counter++;
        }
        System.assertEquals(2, counter);
    }

    @isTest
    public static void testResetEmailRemainder() {
        DContract__c contract = new DContract__c(Name = 'test contract', Snooze_Date__c = Date.today(), Snooze_Days__c = 11, Is_Snooze__c = true, Is_First_Nag_Sent__c = true,
                                                 First_Nag_Sent_Date__c = Date.today(), Second_Nag_Sent_Date__c = Date.today(), Third_Nag_Sent_Date__c = Date.today(),
                                                 Fourth_Nag_Sent_Date__c = Date.today());
        insert contract;

        Test.startTest();
        PROEmailContractSnoozeHelper.resetEmailReminder(contract.Id);
        Test.stopTest();

        DContract__c testContract = [SELECT Is_Snooze__c, Snooze_Date__c, Snooze_Days__c, Is_First_Nag_Sent__c,
                                     First_Nag_Sent_Date__c, Second_Nag_Sent_Date__c, Third_Nag_Sent_Date__c, Fourth_Nag_Sent_Date__c
                                     FROM DContract__c WHERE Id =: contract.Id LIMIT 1];

        System.assertEquals(false, testContract.Is_Snooze__c);
        System.assertEquals(null, testContract.Snooze_Date__c);
        System.assertEquals(null, testContract.Snooze_Days__c);
        System.assertEquals(false, testContract.Is_First_Nag_Sent__c);
        System.assertEquals(null, testContract.First_Nag_Sent_Date__c);
        System.assertEquals(null, testContract.Second_Nag_Sent_Date__c);
        System.assertEquals(null, testContract.Third_Nag_Sent_Date__c);
        System.assertEquals(null, testContract.Fourth_Nag_Sent_Date__c);
    }

    private static List<DContract__c> addContractsWithPRO() {
        Account acc = new Account(Name = 'Acc 1', Status__c = 'Active');
        insert acc;
        List<Contact> contacts = new List<Contact> { new Contact(Email = 'test1@dimagi.com', FirstName = 'Contact1', LastName = 'Test1', AccountId = acc.Id),
                                                     new Contact(Email = 'test2@dimagi.com', FirstName = 'Contact2', LastName = 'Test2', AccountId = acc.Id),
                                                     new Contact(Email = 'test3@dimagi.com', FirstName = 'Contact3', LastName = 'Test3', AccountId = acc.Id) };
        insert contacts;
        List<Business_Unit__c> businessUnits = new List<Business_Unit__c>();
        businessUnits.add(new Business_Unit__c(Name = 'Test Business Unit 1'));
        businessUnits.add(new Business_Unit__c(Name = 'Test Business Unit 2'));
        insert businessUnits;

        List<DContract__c> contractList = new List<DContract__c> {
                                                new DContract__c(Name = 'First 1', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Is_First_Nag_Sent__c = false,
                                                                 In_Charge_Of_Report_Out__c = 'Project Manager', Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(0).Id),
                                                new DContract__c(Name = 'First 2', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Is_First_Nag_Sent__c = false,
                                                                 In_Charge_Of_Report_Out__c = 'Field Manager', Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(0).Id),
                                                new DContract__c(Name = 'Second 1', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 16), In_Charge_Of_Report_Out__c = 'Backstop',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id, Backstop__c = contacts.get(2).Id,
                                                                 Prime_Contracting_Business_Unit__c = businessUnits.get(0).Id),
                                                new DContract__c(Name = 'Fourth 1', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 10), In_Charge_Of_Report_Out__c = 'Project Manager',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id, Backstop__c = contacts.get(2).Id,
                                                                 Prime_Contracting_Business_Unit__c = businessUnits.get(0).Id),
                                                new DContract__c(Name = 'Third 1', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 14), In_Charge_Of_Report_Out__c = 'Field Manager',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id, Backstop__c = contacts.get(2).Id,
                                                                 Prime_Contracting_Business_Unit__c = businessUnits.get(0).Id),
                                                new DContract__c(Name = 'Second 2', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 16), In_Charge_Of_Report_Out__c = 'Backstop',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id, Backstop__c = contacts.get(2).Id,
                                                                 Prime_Contracting_Business_Unit__c = businessUnits.get(0).Id),
                                                new DContract__c(Name = 'Third 2', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 14), In_Charge_Of_Report_Out__c = 'Project Manager',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(0).Id),
                                                new DContract__c(Name = 'First 3', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Is_First_Nag_Sent__c = false,
                                                                 In_Charge_Of_Report_Out__c = 'Field Manager', Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(1).Id),
                                                new DContract__c(Name = 'Second 3', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 16), In_Charge_Of_Report_Out__c = 'Backstop',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(1).Id),
                                                new DContract__c(Name = 'Second 4', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 16), In_Charge_Of_Report_Out__c = 'Project Manager',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(1).Id),
                                                new DContract__c(Name = 'Fourth 2', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 10), In_Charge_Of_Report_Out__c = 'Field Manager',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(1).Id),
                                                new DContract__c(Name = 'Fourth 3', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 10), In_Charge_Of_Report_Out__c = 'Backstop',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(1).Id),
                                                new DContract__c(Name = 'First 4', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Is_First_Nag_Sent__c = false,
                                                                 In_Charge_Of_Report_Out__c = 'Project Manager', Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(1).Id),
                                                new DContract__c(Name = 'Second 5', Workflow_Escalation_Enabled__c = true, Requires_Report_Out__c = 'Yes', Last_Report_Out_Status__c = 'Yellow',
                                                                 Is_First_Nag_Sent__c = true, First_Nag_Sent_Date__c = Date.newInstance(2019, 9, 16), In_Charge_Of_Report_Out__c = 'Field Manager',
                                                                 Project_Manager__c = contacts.get(0).Id, Field_Manager__c = contacts.get(1).Id,
                                                                 Backstop__c = contacts.get(2).Id, Prime_Contracting_Business_Unit__c = businessUnits.get(1).Id)
                                            };
        insert contractList;

        List<Project_Report_Out__c> proList = new List<Project_Report_Out__c> {
                                                    new Project_Report_Out__c(Name = 'Test 1', Contract__c = contractList.get(0).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 2', Contract__c = contractList.get(1).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 3', Contract__c = contractList.get(2).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 4', Contract__c = contractList.get(3).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 5', Contract__c = contractList.get(4).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 6', Contract__c = contractList.get(5).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 7', Contract__c = contractList.get(6).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 8', Contract__c = contractList.get(7).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 9', Contract__c = contractList.get(8).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 10', Contract__c = contractList.get(9).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 11', Contract__c = contractList.get(10).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 12', Contract__c = contractList.get(11).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 13', Contract__c = contractList.get(12).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22)),
                                                    new Project_Report_Out__c(Name = 'Test 14', Contract__c = contractList.get(13).Id, Report_Out_Date__c = Date.newInstance(2019, 8, 22))
                                                };
        insert proList;

        return [SELECT Id, Name, Last_Report_Out_Date__c, Last_Report_Out_Status__c, Is_Snooze__c, Is_First_Nag_Sent__c,
                Snooze_Days__c, Snooze_Date__c, First_Nag_Sent_Date__c , OwnerId, Owner.Name,Owner.Email,
                Backstop__c, Backstop__r.FirstName, Backstop__r.LastName, Backstop__r.Email,
                Project_Manager__c, Project_Manager__r.FirstName, Project_Manager__r.LastName, Project_Manager__r.Email,
                Prime_Contracting_Business_Unit__c, Last_Report_Out_Created_Date__c,
                In_Charge_Of_Report_Out__c, Field_Manager__c, Field_Manager__r.FirstName, Field_Manager__r.LastName, CreatedDate
                FROM DContract__c];
    }
 // Mock for HTTP Callouts
    private class GoogleAuthMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            // Simulated OAuth JSON response
            res.setBody('{"access_token":"testAccessToken","expires_in":3600}');
            return res;
        }
    }
    
    // Utility method to create test OAuth settings
    private static void createOAuthSettings() {
        PRO_OAuth_Settings__c settings = new PRO_OAuth_Settings__c(
            Name = 'Test OAuth',
            ClientID__c = 'testClientId',
            ClientSecret__c = 'testClientSecret',
            Domain_Name__c = 'gmail.com',
            Snooze_PRO_Callback_URL__c = 'https://test.callback'
        );
        insert settings;
    }
    
 
  
    @IsTest
    static void testGetUnauthorizedReqToken() {
        createOAuthSettings();
        SnoozePROController ctrl = new SnoozePROController();
        String url = ctrl.getUnauthorizedReqToken();
        System.assert(url.contains('client_id=testClientId'), 'URL should have client_id');
    }
    
    @IsTest
    static void testGetRandomNonce() {
        String nonce = SnoozePROController.getRandomNonce();
        System.assertEquals(10, nonce.length(), 'Nonce should be length 10');
    }
    
       
    @IsTest
    static void testGetFromJSON() {
        createOAuthSettings();
        SnoozePROController ctrl = new SnoozePROController();
        
        String token = ctrl.getFromJSON('{"access_token":"abc123"}', 'access_token');
        System.assertEquals('abc123', token, 'Should extract access token');
    }
    
   
    @IsTest
    static void testSnoozePROWithOwnerId() {
        createOAuthSettings();
        
Test.setCurrentPageReference(new PageReference('/apex/dummy'));
        ApexPages.currentPage().getParameters().put('OwnerId', '005xx000001SwZG');
        ApexPages.currentPage().getParameters().put('NoOfDays', '4');
        
        SnoozePROController ctrl = new SnoozePROController();
        ctrl.SnoozePRO();
        
        System.assertEquals('Your all PRO are snoozed successfully.', ctrl.PROMessage);
    }
     // Mock to simulate HTTP response
   
   private class GoogleTokenMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"access_token":"fake_token"}');
            return res;
        }
   }
  @isTest
    static void testGetAuthorizedReqToken() {
        // Insert setting BEFORE callout (avoids uncommitted work error)
        PRO_OAuth_Settings__c setting = new PRO_OAuth_Settings__c(
            Name = 'TestSetting',
            ClientID__c = 'testClientId',
            ClientSecret__c = 'testClientSecret',
            Domain_Name__c = 'gmail.com',
            Snooze_PRO_Callback_URL__c = 'https://test.callback'
        );
        insert setting;

        // Set a dummy page reference so ApexPages works
        Test.setCurrentPageReference(new PageReference('/apex/dummy'));

        // Instantiate controller
        SnoozePROController ctrl = new SnoozePROController();

        // Register mock for callout
        Test.setMock(HttpCalloutMock.class, new GoogleTokenMock());

        Test.startTest();
        String result = ctrl.getAuthorizedReqToken('test_code');
        Test.stopTest();

        // Verify the mock response is returned
        System.assertEquals('{"access_token":"fake_token"}', result);
    }
     @isTest
    static void testAuthenticateWithCode() {
        // Insert settings before the callout
        PRO_OAuth_Settings__c setting = new PRO_OAuth_Settings__c(
            Name = 'TestSetting',
            ClientID__c = 'testClientId',
            ClientSecret__c = 'testClientSecret',
            Domain_Name__c = 'gmail.com',
            Snooze_PRO_Callback_URL__c = 'https://test.callback'
        );
        insert setting;

        // Set current page with query string containing 'code'
        PageReference pageRef = new PageReference('/apex/dummy?code=test_code');
        Test.setCurrentPageReference(pageRef);

        SnoozePROController ctrl = new SnoozePROController();

        // Mock the callout for getAuthorizedReqToken
        Test.setMock(HttpCalloutMock.class, new GoogleTokenMock());

        Test.startTest();
        PageReference result = ctrl.authenticate();
        Test.stopTest();

        // With code, we expect result to be null and isAuthenticated true
        System.assertEquals(null, result, 'Should not return a PageReference when code is present');
        System.assertEquals(true, ctrl.isAuthenticated, 'isAuthenticated should be true');
        System.assertEquals('fake_token', ctrl.oauth_token, 'oauth_token should match mock');
    }

    @isTest
    static void testAuthenticateWithoutCode() {
        // Insert settings before the callout
        PRO_OAuth_Settings__c setting = new PRO_OAuth_Settings__c(
            Name = 'TestSetting',
            ClientID__c = 'testClientId',
            ClientSecret__c = 'testClientSecret',
            Domain_Name__c = 'gmail.com',
            Snooze_PRO_Callback_URL__c = 'https://test.callback'
        );
        insert setting;

        // Page params without 'code'
        PageReference pageRef = new PageReference('/apex/dummy');
        Test.setCurrentPageReference(pageRef);

        SnoozePROController ctrl = new SnoozePROController();

        Test.startTest();
        PageReference result = ctrl.authenticate();
        Test.stopTest();

        // Should return a non-null PageReference
        System.assertNotEquals(null, result, 'Expected a PageReference when code is missing');
        System.assert(result.getUrl().contains('client_id=testClientId'), 'Returned URL should contain clientId');
        System.assertEquals(false, ctrl.isAuthenticated, 'isAuthenticated should remain false');
    }
}