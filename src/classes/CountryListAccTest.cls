/**
 *  Tests for Global Account View
 */
@isTest
public class CountryListAccTest {

    @testSetup
    static void setup() {
        // Account
        Account acc1 = new Account(Name = 'Acc 1', Status__c = 'Active');
        insert acc1;
        Account acc2 = new Account(Name = 'Acc 2 Test', Status__c = 'Active');
        insert acc2;
        Account acc3 = new Account(Name = 'Acc 3 NY', Status__c = 'Active');
        insert acc3;
        Account acc4 = new Account(Name = 'Child 4', Status__c = 'Active', ParentId = acc1.Id);
        insert acc4;

        // Contact
        Contact cont1 = new Contact(Email = 'test1@dimagi.com', FirstName = 'Contact', LastName = '1', AccountId = acc1.Id);
        insert cont1;
        Contact cont2 = new Contact(Email = 'test2@dimagi.com', FirstName = 'Contact', LastName = '2', AccountId = acc1.Id);
        insert cont2;
        Contact cont3 = new Contact(Email = 'test3@dimagi.com', FirstName = 'Contact', LastName = '3', AccountId = acc2.Id);
        insert cont3;
        Contact cont4 = new Contact(Email = 'test4@dimagi.com', FirstName = 'Contact', LastName = '4', AccountId = acc3.Id);
        insert cont4;
        Contact cont5 = new Contact(Email = 'test5@dimagi.com', FirstName = 'Contact', LastName = '5', AccountId = acc3.Id);
        insert cont5;
        Contact cont6 = new Contact(Email = 'test6@dimagi.com', FirstName = 'Contact', LastName = '6', AccountId = acc4.Id);
        insert cont6;

        // Contract
        DContract__c dcontract1 = new DContract__c(Name = 'Contract 1', Account__c = acc1.Id, Contract_Start_Date__c = Date.today().addMonths(-6),
                                                    Contract_End_Date__c = Date.today().addMonths(6), Status__c = 'Active', Short_Description__c = 'Desc 1');
        insert dcontract1;
        DContract__c dcontract2 = new DContract__c(Name = 'Contract 2', Account__c = acc2.Id, Contract_Start_Date__c = Date.today().addMonths(-6),
                                                    Contract_End_Date__c = Date.today().addMonths(6), Status__c = 'Active', Short_Description__c = 'Desc 2');
        insert dcontract2;
        DContract__c dcontract3 = new DContract__c(Name = 'Contract 3', Account__c = acc3.Id, Contract_Start_Date__c = Date.today().addMonths(-6),
                                                    Contract_End_Date__c = Date.today().addMonths(6), Status__c = 'Active', Short_Description__c = 'Desc 3');
        insert dcontract3;
        DContract__c dcontract4 = new DContract__c(Name = 'Contract 4', Account__c = acc4.Id, Contract_Start_Date__c = Date.today().addMonths(-6),
                                                    Contract_End_Date__c = Date.today().addMonths(-1), Status__c = 'Complete', Short_Description__c = 'Desc 4');
        insert dcontract4;
        DContract__c dcontract5 = new DContract__c(Name = 'Contract 5', Account__c = acc1.Id, Contract_Start_Date__c = Date.today().addMonths(-6),
                                                    Contract_End_Date__c = Date.today().addMonths(-1), Status__c = 'Complete', Short_Description__c = 'Desc 5');
        insert dcontract5;

        // Opportunity
        Opportunity opp1 = new Opportunity(Name = 'Opp 1', StageName = 'Stage 2 - Talking', AccountId = acc1.Id, CloseDate = Date.today().addMonths(6));
        insert opp1;
        Opportunity opp2 = new Opportunity(Name = 'Opp 1', StageName = 'Stage 2 - Talking', AccountId = acc2.Id, CloseDate = Date.today().addMonths(6));
        insert opp2;
        Opportunity opp3 = new Opportunity(Name = 'Opp 1', StageName = 'Stage 2 - Talking', AccountId = acc3.Id, CloseDate = Date.today().addMonths(6));
        insert opp3;
        Opportunity opp4 = new Opportunity(Name = 'Opp 1', StageName = 'Closed - Won', AccountId = acc4.Id, CloseDate = Date.today().addMonths(-1));
        insert opp4;
        Opportunity opp5 = new Opportunity(Name = 'Opp 1', StageName = 'Closed - Lost', AccountId = acc1.Id, CloseDate = Date.today().addMonths(-1));
        insert opp5;

        // Domains & Subscriptions
        Accounting_SoftwareProductRate__c productRate1 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 150, Server_Name__c = 'CommCare HQ');
        Accounting_SoftwareProductRate__c productRate2 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 75, Server_Name__c = 'CommCare HQ');
        Accounting_SoftwareProductRate__c productRate3 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 25, Server_Name__c = 'CommCare HQ');

        insert productRate1;
        insert productRate2;
        insert productRate3;

        Accounting_Softwareplan__c softwarePlan1 = new Accounting_Softwareplan__c(Name = 'softwarePlan1', edition__c = 'Community', Server_Name__c = 'CommCare HQ');
        Accounting_Softwareplan__c softwarePlan2 = new Accounting_Softwareplan__c(Name = 'softwarePlan2', edition__c = 'Standard', Server_Name__c = 'CommCare HQ');
        Accounting_Softwareplan__c softwarePlan3 = new Accounting_Softwareplan__c(Name = 'softwarePlan3', edition__c = 'Pro', Server_Name__c = 'CommCare HQ');

        insert softwarePlan1;
        insert softwarePlan2;
        insert softwarePlan3;

        Accounting_SoftwarePlanVersion__c planVersion1 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate1.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan1.Id, Server_Name__c = 'CommCare HQ');
        Accounting_SoftwarePlanVersion__c planVersion2 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate2.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan2.Id, Server_Name__c = 'CommCare HQ');
        Accounting_SoftwarePlanVersion__c planVersion3 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate3.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan3.Id, Server_Name__c = 'CommCare HQ');

        insert planVersion1;
        insert planVersion2;
        insert planVersion3;

        Domain__c domain1 = new Domain__c(Name = 'domain_1', Server_Name__c = 'CommCare HQ', is_test__c = 'false', cpIsActive__c = true,
                                          Wam__c = 15, cpActiveMobileUsers__c = 20, cpAllForms__c = 325, Account__c = acc1.Id);
        insert domain1;
        Domain__c domain2 = new Domain__c(Name = 'domain_2', Server_Name__c = 'CommCare HQ', is_test__c = 'false', cpIsActive__c = true,
                                          Wam__c = 30, cpActiveMobileUsers__c = 35, cpAllForms__c = 340, Account__c = acc2.Id);
        insert domain2;
        Domain__c domain3 = new Domain__c(Name = 'domain_3', Server_Name__c = 'CommCare HQ', is_test__c = 'false', cpIsActive__c = true,
                                          Wam__c = 45, cpActiveMobileUsers__c = 50, cpAllForms__c = 355, Account__c = acc3.Id);
        insert domain3;
        Domain__c domain4 = new Domain__c(Name = 'domain_4', Server_Name__c = 'CommCare HQ', is_test__c = 'false', cpIsActive__c = true,
                                          Wam__c = 60, cpActiveMobileUsers__c = 65, cpAllForms__c = 370, Account__c = acc4.Id);
        insert domain4;
        Domain__c domain5 = new Domain__c(Name = 'domain_5', Server_Name__c = 'CommCare HQ', is_test__c = 'false', cpIsActive__c = true,
                                          Wam__c = 75, cpActiveMobileUsers__c = 80, cpAllForms__c = 385, Account__c = acc2.Id);
        insert domain5;

        Accounting_Subscription__c subscription1 = new Accounting_Subscription__c(Created_By__c = 'Sample 1', date_start__c = Date.today().addMonths(-6), date_end__c = Date.today().addMonths(6), is_active__c = true,
                                                          Accounting_subscriber_domain__c = domain1.Id, plan_version__c = planVersion1.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Self_service');
        insert subscription1;
        Accounting_Subscription__c subscription2 = new Accounting_Subscription__c(Created_By__c = 'Sample 2', date_start__c = Date.today().addMonths(-6), date_end__c = Date.today().addMonths(6), is_active__c = true,
                                                          Accounting_subscriber_domain__c = domain2.Id, plan_version__c = planVersion2.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Product');
        insert subscription2;
        Accounting_Subscription__c subscription3 = new Accounting_Subscription__c(Created_By__c = 'Sample 3', date_start__c = Date.today().addMonths(-6), date_end__c = Date.today().addMonths(6), is_active__c = true,
                                                          Accounting_subscriber_domain__c = domain3.Id, plan_version__c = planVersion3.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Self_service');
        insert subscription3;
        Accounting_Subscription__c subscription4 = new Accounting_Subscription__c(Created_By__c = 'Sample 4', date_start__c = Date.today().addMonths(-6), date_end__c = Date.today().addMonths(6), is_active__c = true,
                                                          Accounting_subscriber_domain__c = domain4.Id, plan_version__c = planVersion1.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Self_service');
        insert subscription4;
        Accounting_Subscription__c subscription5 = new Accounting_Subscription__c(Created_By__c = 'Sample 5', date_start__c = Date.today().addMonths(-6), date_end__c = Date.today().addMonths(6), is_active__c = true,
                                                          Accounting_subscriber_domain__c = domain5.Id, plan_version__c = planVersion2.Id, Server_Name__c = 'CommCare HQ',
                                                          is_trial__c = false, service_type__c = 'Product');
        insert subscription5;
    }

    @isTest
    public static void shouldLoadAllAccountsByName() {
        Test.startTest();
        CountryListAcc globalAccountViewController = new CountryListAcc();

        globalAccountViewController.searchString = 'Acc'; // 4 results
        globalAccountViewController.search();

        System.assertEquals(4, globalAccountViewController.wrapperList.size());

        globalAccountViewController.searchString = 'Acc 1'; // 2 results
        globalAccountViewController.search();

        System.assertEquals(2, globalAccountViewController.wrapperList.size());

        globalAccountViewController.searchString = 'NY'; // 1 results
        globalAccountViewController.search();

        System.assertEquals(1, globalAccountViewController.wrapperList.size());
        Test.stopTest();
    }

    @isTest
    public static void shouldLoadRecordsConnectedWithChoosenAccount() {
        Test.startTest();
        CountryListAcc globalAccountViewController = new CountryListAcc();

        globalAccountViewController.searchString = 'Acc 1'; // 2 results
        globalAccountViewController.search();
        globalAccountViewController.selectedAccountId = [SELECT Id FROM Account WHERE Name = 'Acc 1' LIMIT 1].Id;
        globalAccountViewController.searchByAccount();

        System.assertEquals(2, globalAccountViewController.wrapperList.size());
        System.assertEquals(3, globalAccountViewController.lstCon.size());
        System.assertEquals(1, globalAccountViewController.lstContr.size());
        System.assertEquals(2, globalAccountViewController.lstContrclosed.size());
        System.assertEquals(1, globalAccountViewController.lstoppty.size());
        System.assertEquals(2, globalAccountViewController.lstopptyClosed.size());
        System.assertEquals(2, globalAccountViewController.lstDomains.size());
        System.assertEquals(2, globalAccountViewController.lstSubscriptions.size());
        Test.stopTest();
    }

    @isTest
    public static void shouldLoadParams() {
        Test.startTest();
        PageReference pageRef = Page.CountryList;
        pageRef.getParameters().put('id', [SELECT Id FROM Account WHERE Name = 'Acc 1' LIMIT 1].Id);
        pageRef.getParameters().put('q', 'Acc 1');
        Test.setCurrentPage(pageRef);
        CountryListAcc globalAccountViewController = new CountryListAcc();

        System.assertEquals(2, globalAccountViewController.wrapperList.size());
        System.assertEquals(3, globalAccountViewController.lstCon.size());
        System.assertEquals(1, globalAccountViewController.lstContr.size());
        System.assertEquals(2, globalAccountViewController.lstContrclosed.size());
        System.assertEquals(1, globalAccountViewController.lstoppty.size());
        System.assertEquals(2, globalAccountViewController.lstopptyClosed.size());
        System.assertEquals(2, globalAccountViewController.lstDomains.size());
        System.assertEquals(2, globalAccountViewController.lstSubscriptions.size());

        Test.stopTest();
    }
}