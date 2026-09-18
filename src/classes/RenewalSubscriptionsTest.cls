@isTest
public class RenewalSubscriptionsTest {

    private static void addTestData() {
        Business_Unit__c bu = new Business_Unit__c(Name = 'Inc');
        insert bu;
		system.debug('Business_Unit__c : '+bu);
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@dimagi.com',
            EmailEncodingKey='UTF-8', FirstName = 'FirstName', LastName='LastName', LanguageLocaleKey='en_US',
            TimeZoneSidKey='America/Panama', LocaleSidKey='en_US', ProfileId = p.Id, UserName='standarduser@dimagi.com');
        insert u;

        Subscription_Renewal_Settings__c settings = Subscription_Renewal_Settings__c.getOrgDefaults();
        settings.Default_Business_Unit__c = 'Inc';
        settings.Implementation_non_Enterprise_Owner__c = 'FirstName LastName';
        settings.Implementation_Enterprise_Owner__c = 'FirstName LastName';
        settings.Product_non_Enterprise_Owner__c = 'FirstName LastName';
        settings.Product_Enterprise_Owner__c = 'FirstName LastName';

        settings.Error_Emails__c = 'dimagiErrors@dimagi.com';
        insert settings;
    }

    public static testMethod void shouldCreateOpps() {
        addTestData();
        addTestPricebooks();

        List<PricebookEntry> entries = [SELECT Id, Name, ProductCode, UseStandardPrice, UnitPrice, Pricebook2Id FROM PricebookEntry];
        System.debug('Entries ; ' + entries);

        Accounting_BillingAccount__c billingAccount1 = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Pro', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_1', dimagi_contact__c = 'contact_1@dimagi.com');
        insert billingAccount1;
        Accounting_BillingAccount__c billingAccount2 = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Conventional 1', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_2', dimagi_contact__c = 'contact_1@dimagi.com');
        insert billingAccount2;
        Accounting_BillingAccount__c billingAccount3 = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Conventional 2', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_2', dimagi_contact__c = 'contact_1@dimagi.com');
        insert billingAccount3;
        Accounting_BillingAccount__c billingAccount4 = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Conventional 3', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_2', dimagi_contact__c = 'contact_1@dimagi.com');
        insert billingAccount4;
        Accounting_BillingAccount__c billingAccount5 = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Free', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_3', dimagi_contact__c = 'contact_1@dimagi.com');
        insert billingAccount5;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Domain__c domain1 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_1', cpAllWebUsers__c = 30, Account__c = testAccount.Id);
        insert domain1;
        Domain__c domain2 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_2', cpAllWebUsers__c = 22);
        insert domain2;
        Domain__c domain3 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_3', cpAllWebUsers__c = 11);
        insert domain3;
        Domain__c domain4 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_4', cpAllWebUsers__c = 111);
        insert domain4;

        Business_Unit__c bizUnit = new Business_Unit__c(Name = 'Test Business Unit 1');
        Opportunity opp = new Opportunity(Name = 'AAA Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted',Expense_Income__c = 0,
                                                 CloseDate = date.today().addMonths(5), Probability = 30, Domain_Name__c = domain4.Id,
                                                 Opportunity_Owner_Division__c = 'Global Solutions', Opportunity_Owner_Sub_Division__c = 'USS Delivery',Country__c = 'a00b0000001AOufAAG',Proposal_Dropbox_Location__c = 'https://example.com/proposal.pdf');
        insert opp;


        Accounting_Softwareplan__c softwarePlan1 = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Pro');
        insert softwarePlan1;
        Accounting_Softwareplan__c softwarePlan2 = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Community');
        insert softwarePlan2;
        Accounting_Softwareplan__c softwarePlan3 = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Standard');
        insert softwarePlan3;

        // SAL-515: rate drives the subscription's current monthly fee (formula); planVersion1 -> $778.
        Accounting_SoftwareProductRate__c proRate = new Accounting_SoftwareProductRate__c(Server_Name__c = 'CommCareHQ', monthly_fee__c = 778);
        insert proRate;

        Accounting_SoftwarePlanVersion__c planVersion1 = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlan1.Id, Software_Product_Rate__c = proRate.Id);
        insert planVersion1;
        Accounting_SoftwarePlanVersion__c planVersion2 = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlan2.Id);
        insert planVersion2;
        Accounting_SoftwarePlanVersion__c planVersion3 = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlan3.Id);
        insert planVersion3;

        Accounting_Subscription__c subscription1 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 6, 14), service_type__c = 'Product', is_active__c = true,
                                                                                  account__c = billingAccount1.Id, Accounting_subscriber_domain__c = domain1.Id, plan_version__c = planVersion1.Id);
        insert subscription1; // should create

        Accounting_Subscription__c subscription2 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 5, 2), service_type__c = 'Implementation', is_active__c = false,
                                                                                  account__c = billingAccount2.Id, Accounting_subscriber_domain__c = domain2.Id, plan_version__c = planVersion2.Id);
        insert subscription2;
        Accounting_Subscription__c subscription3 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 6, 1), date_end__c = Date.newInstance(2023, 6, 13), service_type__c = 'Implementation', is_active__c = true,
                                                                                  account__c = billingAccount3.Id, Accounting_subscriber_domain__c = domain2.Id, plan_version__c = planVersion2.Id);
        insert subscription3;
        Accounting_Subscription__c subscription4 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 6, 13), date_end__c = Date.newInstance(2024, 8, 1), service_type__c = 'Product', is_active__c = true,
                                                                                  account__c = billingAccount4.Id, Accounting_subscriber_domain__c = domain2.Id, plan_version__c = planVersion2.Id);
        insert subscription4; // has future subscription no create

        Accounting_Subscription__c subscription5 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2024, 6, 19), service_type__c = 'Implementation', is_active__c = true,
                                                                                  account__c = billingAccount5.Id, Accounting_subscriber_domain__c = domain3.Id, plan_version__c = planVersion3.Id);
        insert subscription5; // no create no 60 days

        Accounting_Subscription__c subscription6 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 6, 1), date_end__c = Date.newInstance(2024, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                  account__c = billingAccount5.Id, Accounting_subscriber_domain__c = domain4.Id, plan_version__c = planVersion3.Id);
        insert subscription6;
        Accounting_Subscription__c subscription7 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 6, 15), service_type__c = 'Product', is_active__c = true,
                                                                                  account__c = billingAccount5.Id, Accounting_subscriber_domain__c = domain4.Id, plan_version__c = planVersion3.Id);
        insert subscription7;// should created for the second one

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        List<Accounting_Subscription__c> futureList = batchJob.getFutureSubscriptions();
        System.assertEquals(1, futureList.size());
        List<Accounting_Subscription__c> renewalList = batchJob.getSubscriptionsForRenewal(new Set<String> { 'domain_2' });
        System.assertEquals(2, renewalList.size());
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Name, Prior_Dimagi_contact__c, Subscriptions_web_users__c, Duration_months__c,
                                  Expected_Buffer__c, of_Execution_budget_for_GS__c, CloseDate, Domain_Name__c, Product_Text__c,
                                  StageName, Implementation_Type__c, Opportunity_Owning_Entity__c, Contract_Owner_BU__c,
                                  Implementing_Business_Unit__c, Opportunity_Source__c, Owner.Name FROM Opportunity ORDER BY Name DESC];
        System.assertEquals(3, opps.size());
        for(Opportunity op : opps){
            system.debug(op.name + 'Opportunity_Owning_Entity__c : '+op.Opportunity_Owning_Entity__c);
        }
        Opportunity opp1 = opps.get(0);
		system.debug('oppsssss :' + opps.get(0).name);
        
        System.assertEquals('contact_1@dimagi.com', opp1.Prior_Dimagi_contact__c);
        System.assertEquals('Test Account-Pro Renewal 06112023', opp1.Name);
        System.assertEquals(30, opp1.Subscriptions_web_users__c);
        System.assertEquals(12, opp1.Duration_months__c);
        System.assertEquals(100, opp1.Expected_Buffer__c);
        System.assertEquals(0, opp1.of_Execution_budget_for_GS__c);
        System.assertEquals(Date.newInstance(2023, 6, 14), opp1.CloseDate);
        System.assertEquals(domain1.Id, opp1.Domain_Name__c);
        System.assertEquals('Stage 3 - Prospect', opp1.StageName);
        System.assertEquals('Self Service', opp1.Implementation_Type__c);

        Business_Unit__c bu = [SELECT Id,name FROM Business_Unit__c WHERE Name = 'Inc'];
        list<Business_Unit__c> buList = [SELECT Id,name FROM Business_Unit__c];
        		system.debug('oppsssss111 :' + opp1.Opportunity_Owning_Entity__c);
				system.debug('bu.Id :' + buList);

        
        System.debug([SELECT Id FROM OpportunityLineItem]);
        List<OpportunityLineItem> opp1Products = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =: opp1.Id];
        System.assertEquals(1, opp1Products.size());

        opp1Products = [SELECT Id, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId =: opp1.Id and ProductCode = 'Pro'];
        System.assertEquals(1, opp1Products.size());
        System.assertEquals(12, opp1Products.get(0).Quantity);
        // SAL-515: priced from the subscription's current monthly fee ($778), not the custom setting.
        System.assertEquals(778, opp1Products.get(0).UnitPrice);

        Opportunity opp2 = opps.get(1);

        System.assertEquals('contact_1@dimagi.com', opp2.Prior_Dimagi_contact__c);
        System.assertEquals('domain_4-Standard Renewal 06112023', opp2.Name);
        System.assertEquals(111, opp2.Subscriptions_web_users__c);
        System.assertEquals(12, opp2.Duration_months__c);
        System.assertEquals(100, opp2.Expected_Buffer__c);
        System.assertEquals(0, opp2.of_Execution_budget_for_GS__c);
        System.assertEquals(Date.newInstance(2023, 6, 15), opp2.CloseDate);
        System.assertEquals(domain4.Id, opp2.Domain_Name__c);
        System.assertEquals('Stage 3 - Prospect', opp2.StageName);
        System.assertEquals('Self Service', opp2.Implementation_Type__c);
		
        List<OpportunityLineItem> opp2Products = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =: opp2.Id];
        System.assertEquals(1, opp2Products.size());

        opp2Products = [SELECT Id, Quantity, UnitPrice FROM OpportunityLineItem WHERE OpportunityId =: opp2.Id and ProductCode = 'Standard'];
        System.assertEquals(1, opp2Products.size());
        System.assertEquals(12, opp2Products.get(0).Quantity);
        // SAL-515: subscription has no rate, so it falls back to the Dimagi Pricebook list price ($500).
        System.assertEquals(500, opp2Products.get(0).UnitPrice);

        futureList = batchJob.getFutureSubscriptions();
        System.assertEquals(1, futureList.size());
        // start() now does grouping/representative selection itself - domain1 and domain4
        // already carry an open Opportunity from the run above, so no representatives
        // should come back for them at all.
        List<Accounting_Subscription__c> representatives = batchJob.start(null);
        System.assertEquals(0, representatives.size(), 'Domains already carrying an open renewal Opportunity should produce no representatives');
        batchJob.execute(null, representatives);
        batchJob.finish(null);

        opps = [SELECT Id, Name, Prior_Dimagi_contact__c, Subscriptions_web_users__c, Duration_months__c,
                                  Expected_Buffer__c, of_Execution_budget_for_GS__c, CloseDate, Domain_Name__c, Product_Text__c,
                                  StageName, Implementation_Type__c, Opportunity_Owning_Entity__c, Contract_Owner_BU__c,
                                  Implementing_Business_Unit__c, Opportunity_Source__c, Owner.Name FROM Opportunity ORDER BY Name DESC];
        System.assertEquals(3, opps.size(), 'Domains already carrying an open renewal Opportunity should be skipped, not duplicated');
    }

    public static testMethod void shouldCreateNewOppWhenRenewalOppHaveClosedDateFromThePast() {
        addTestData();
        addTestPricebooks();

        Accounting_BillingAccount__c billingAccount1 = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Pro', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_1', dimagi_contact__c = 'contact_1@dimagi.com');
        insert billingAccount1;
        Accounting_BillingAccount__c billingAccount2 = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Conventional 1', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_2', dimagi_contact__c = 'contact_1@dimagi.com');
        insert billingAccount2;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Domain__c domain1 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_1', cpAllWebUsers__c = 30, Account__c = testAccount.Id);
        insert domain1;

        Business_Unit__c bizUnit = new Business_Unit__c(Name = 'Test Business Unit 1');
        Opportunity opp = new Opportunity(Name = 'Old Renewal Opportunity', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Closed',Expense_Income__c = 0,
                                                 CloseDate = date.today().addDays(-1), Probability = 30, Domain_Name__c = domain1.Id,
                                                 Opportunity_Owner_Division__c = 'Global Solutions', Opportunity_Owner_Sub_Division__c = 'USS Delivery',Country__c = 'a00b0000001AOufAAG');
        insert opp;
        Test.setCreatedDate(opp.Id, DateTime.now().addDays(-200));
        update new Domain__c(Id = domain1.Id, Opportunity__c = opp.Id);

        Accounting_Softwareplan__c softwarePlan1 = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Pro');
        insert softwarePlan1;
        Accounting_Softwareplan__c softwarePlan2 = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Community');
        insert softwarePlan2;
        Accounting_Softwareplan__c softwarePlan3 = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Standard');
        insert softwarePlan3;

        Accounting_SoftwarePlanVersion__c planVersion1 = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlan1.Id);
        insert planVersion1;
        Accounting_SoftwarePlanVersion__c planVersion2 = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlan2.Id);
        insert planVersion2;
        Accounting_SoftwarePlanVersion__c planVersion3 = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlan3.Id);
        insert planVersion3;

        Accounting_Subscription__c subscription1 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.today().addDays(-47), date_end__c = Date.today().addDays(-45), service_type__c = 'Product', is_active__c = false,
                                                                                  account__c = billingAccount1.Id, Accounting_subscriber_domain__c = domain1.Id, plan_version__c = planVersion1.Id);
        insert subscription1;
        Accounting_Subscription__c subscription2 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.today().addDays(-45), date_end__c = Date.today().addDays(7), service_type__c = 'Product', is_active__c = true,
                                                                                  account__c = billingAccount2.Id, Accounting_subscriber_domain__c = domain1.Id, plan_version__c = planVersion2.Id);
        insert subscription2;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch();
        List<Accounting_Subscription__c> futureList = batchJob.getFutureSubscriptions();
        System.assertEquals(0, futureList.size());
        List<Accounting_Subscription__c> renewalList = batchJob.getSubscriptionsForRenewal(new Set<String>());
        System.assertEquals(1, renewalList.size());
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Name, Prior_Dimagi_contact__c, Subscriptions_web_users__c, Duration_months__c,
                                  Expected_Buffer__c, of_Execution_budget_for_GS__c, CloseDate, Domain_Name__c, Product_Text__c,
                                  StageName, Implementation_Type__c, Opportunity_Owning_Entity__c, Contract_Owner_BU__c,
                                  Implementing_Business_Unit__c, Opportunity_Source__c, Owner.Name FROM Opportunity ORDER BY Name DESC];
        System.assertEquals(2, opps.size());
        Opportunity opp1 = opps.get(0);
        System.assertEquals('Test Account-Community Renewal ' + ((Date.today().month() < 10 ? '0' + Date.today().month() : '' + Date.today().month())
                                                                    + (Date.today().day() < 10 ? '0' + Date.today().day() : '' + Date.today().day())
                                                                    + ('' + Date.today().year())), opp1.Name);
        Opportunity opp2 = opps.get(1);
        System.assertEquals('Old Renewal Opportunity', opp2.Name);
        Domain__c domainFromDB = [SELECT Id, Name, Opportunity__c FROM Domain__c WHERE Id =: domain1.Id];
        System.assertEquals(opp1.Id, domainFromDB.Opportunity__c);
    }

    public static testMethod void shouldCreateOneOppForGroupedBillingAccount() {
        addTestData();
        addTestPricebooks();

        // One billing account grouping three project-space domains - the "grouped subscription" case.
        Accounting_BillingAccount__c groupBillingAccount = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Grouped', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_group_1', dimagi_contact__c = 'contact_2@dimagi.com');
        insert groupBillingAccount;

        Account groupAccount = new Account(Name = 'Grouped Test Account');
        insert groupAccount;
        Domain__c domainG1 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_group_1', cpAllWebUsers__c = 5, Account__c = groupAccount.Id);
        insert domainG1;
        Domain__c domainG2 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_group_2', cpAllWebUsers__c = 8, Account__c = groupAccount.Id);
        insert domainG2;
        Domain__c domainG3 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_group_3', cpAllWebUsers__c = 13, Account__c = groupAccount.Id);
        insert domainG3;

        Accounting_Softwareplan__c softwarePlanAdvanced = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Advanced');
        insert softwarePlanAdvanced;
        Accounting_SoftwarePlanVersion__c planVersionAdvanced = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanAdvanced.Id);
        insert planVersionAdvanced;

        // Two non-billing domains (Do Not Invoice) and one billing domain (domainG3), all in the same group, all ending on the same date.
        Accounting_Subscription__c subscriptionG1 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainG1.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = true);
        insert subscriptionG1;
        Accounting_Subscription__c subscriptionG2 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainG2.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = true);
        insert subscriptionG2;
        Accounting_Subscription__c subscriptionG3 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainG3.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false);
        insert subscriptionG3;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        List<Accounting_Subscription__c> renewalList = batchJob.getSubscriptionsForRenewal(new Set<String>());
        System.assertEquals(3, renewalList.size());
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Name, Domain_Name__c FROM Opportunity WHERE AccountId =: groupAccount.Id];
        System.assertEquals(1, opps.size(), 'One grouped billing account should produce exactly one renewal Opportunity, not one per domain');
        Opportunity groupOpp = opps.get(0);
        System.assertEquals(domainG3.Id, groupOpp.Domain_Name__c, 'The billed (non Do-Not-Invoice) domain should represent the group');

        List<OpportunityLineItem> lineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId =: groupOpp.Id];
        System.assertEquals(1, lineItems.size());

        Map<Id, Domain__c> domainsAfter = new Map<Id, Domain__c>([SELECT Id, Opportunity__c FROM Domain__c WHERE Id IN (:domainG1.Id, :domainG2.Id, :domainG3.Id)]);
        System.assertEquals(groupOpp.Id, domainsAfter.get(domainG1.Id).Opportunity__c, 'Every domain in the group should be stamped with the shared Opportunity');
        System.assertEquals(groupOpp.Id, domainsAfter.get(domainG2.Id).Opportunity__c, 'Every domain in the group should be stamped with the shared Opportunity');
        System.assertEquals(groupOpp.Id, domainsAfter.get(domainG3.Id).Opportunity__c, 'Every domain in the group should be stamped with the shared Opportunity');
    }

    /**
     * RenewalSubscriptionsScheduler runs this batch with a scope of 10, and a grouped
     * billing account can have more members than that (see the TECHOPS-211 analysis).
     * Grouping and representative selection happen entirely in start() - the only place
     * that ever sees every candidate for a run at once - specifically so a group's DML work
     * can never be split across execute() chunks: start() returns one already-validated
     * representative per group, and execute() only ever receives representatives, never raw
     * per-domain candidates. This drives start()/execute()/finish() directly (matching how
     * Database.executeBatch would call them) and confirms that even though execute() here
     * only sees the ONE representative record for the group, it still stamps every domain in
     * it via the domainIdsByGroup state built in start().
     */
    public static testMethod void shouldStampEveryGroupDomainWhenExecuteOnlySeesTheRepresentative() {
        addTestData();
        addTestPricebooks();

        Accounting_BillingAccount__c groupBillingAccount = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Grouped', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_chunk_1', dimagi_contact__c = 'contact_3@dimagi.com');
        insert groupBillingAccount;

        Account groupAccount = new Account(Name = 'Grouped Chunked Account');
        insert groupAccount;
        Domain__c domainC1 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_chunk_1', cpAllWebUsers__c = 5, Account__c = groupAccount.Id);
        insert domainC1;
        Domain__c domainC2 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_chunk_2', cpAllWebUsers__c = 8, Account__c = groupAccount.Id);
        insert domainC2;
        Domain__c domainC3 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_chunk_3', cpAllWebUsers__c = 13, Account__c = groupAccount.Id);
        insert domainC3;

        Accounting_Softwareplan__c softwarePlanAdvanced = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Advanced');
        insert softwarePlanAdvanced;
        Accounting_SoftwarePlanVersion__c planVersionAdvanced = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanAdvanced.Id);
        insert planVersionAdvanced;

        Accounting_Subscription__c subscriptionC1 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainC1.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = true);
        insert subscriptionC1;
        Accounting_Subscription__c subscriptionC2 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainC2.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = true);
        insert subscriptionC2;
        Accounting_Subscription__c subscriptionC3 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainC3.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false);
        insert subscriptionC3;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        List<Accounting_Subscription__c> representatives = batchJob.start(null);
        System.assertEquals(1, representatives.size(), 'start() should already have reduced the 3-domain group to one representative');
        System.assertEquals(domainC3.Id, representatives.get(0).Accounting_subscriber_domain__c, 'The billed (non Do-Not-Invoice) domain should represent the group');
        batchJob.execute(null, representatives);
        batchJob.finish(null);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Domain_Name__c FROM Opportunity WHERE AccountId =: groupAccount.Id];
        System.assertEquals(1, opps.size(), 'The group should produce exactly one Opportunity');
        System.assertEquals(domainC3.Id, opps.get(0).Domain_Name__c);

        Map<Id, Domain__c> domainsAfter = new Map<Id, Domain__c>([SELECT Id, Opportunity__c FROM Domain__c WHERE Id IN (:domainC1.Id, :domainC2.Id, :domainC3.Id)]);
        System.assertEquals(opps.get(0).Id, domainsAfter.get(domainC1.Id).Opportunity__c, 'domainC1 should be stamped even though execute() never saw its subscription directly');
        System.assertEquals(opps.get(0).Id, domainsAfter.get(domainC2.Id).Opportunity__c, 'domainC2 should be stamped even though execute() never saw its subscription directly');
        System.assertEquals(opps.get(0).Id, domainsAfter.get(domainC3.Id).Opportunity__c);
    }

    /**
     * If one domain in a group already carries its own Opportunity (e.g. left over from
     * before this fix shipped), the rest of the group shouldn't be blocked from getting a
     * shared renewal Opportunity of their own.
     */
    public static testMethod void shouldCreateSharedOppForRemainingDomainsWhenOneDomainAlreadyHasOpp() {
        addTestData();
        addTestPricebooks();

        Accounting_BillingAccount__c groupBillingAccount = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Grouped', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_mixed_1', dimagi_contact__c = 'contact_4@dimagi.com');
        insert groupBillingAccount;

        Account groupAccount = new Account(Name = 'Grouped Mixed Account');
        insert groupAccount;
        Domain__c domainM1 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_mixed_1', cpAllWebUsers__c = 5, Account__c = groupAccount.Id);
        insert domainM1;
        Domain__c domainM2 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_mixed_2', cpAllWebUsers__c = 8, Account__c = groupAccount.Id);
        insert domainM2;
        Domain__c domainM3 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_mixed_3', cpAllWebUsers__c = 13, Account__c = groupAccount.Id);
        insert domainM3;

        // domainM1 already has its own open renewal Opportunity, e.g. left over from before
        // this grouping logic existed.
        Business_Unit__c bizUnitMixed = new Business_Unit__c(Name = 'Test Business Unit Mixed');
        Opportunity existingOpp = new Opportunity(Name = 'Existing Domain Opp', Business_Unit_Owner__c = bizUnitMixed.Id, StageName = 'Stage 5 - Submitted', Expense_Income__c = 0,
                                                 CloseDate = Date.newInstance(2023, 7, 1), Probability = 30, Domain_Name__c = domainM1.Id,
                                                 Opportunity_Owner_Division__c = 'Global Solutions', Opportunity_Owner_Sub_Division__c = 'USS Delivery', Country__c = 'a00b0000001AOufAAG');
        insert existingOpp;
        update new Domain__c(Id = domainM1.Id, Opportunity__c = existingOpp.Id);

        Accounting_Softwareplan__c softwarePlanAdvanced = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Advanced');
        insert softwarePlanAdvanced;
        Accounting_SoftwarePlanVersion__c planVersionAdvanced = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanAdvanced.Id);
        insert planVersionAdvanced;

        Accounting_Subscription__c subscriptionM1 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainM1.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = true);
        insert subscriptionM1;
        Accounting_Subscription__c subscriptionM2 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainM2.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = true);
        insert subscriptionM2;
        Accounting_Subscription__c subscriptionM3 = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                    account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domainM3.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false);
        insert subscriptionM3;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> newOpps = [SELECT Id, Domain_Name__c FROM Opportunity WHERE AccountId =: groupAccount.Id AND Id !=: existingOpp.Id];
        System.assertEquals(1, newOpps.size(), 'domainM2 and domainM3 should still get one shared new Opportunity even though domainM1 already has its own');
        System.assertEquals(domainM3.Id, newOpps.get(0).Domain_Name__c, 'The billed domain should represent the new shared Opportunity');

        Map<Id, Domain__c> domainsAfter = new Map<Id, Domain__c>([SELECT Id, Opportunity__c FROM Domain__c WHERE Id IN (:domainM1.Id, :domainM2.Id, :domainM3.Id)]);
        System.assertEquals(existingOpp.Id, domainsAfter.get(domainM1.Id).Opportunity__c, 'domainM1 should keep pointing at its existing Opportunity, untouched');
        System.assertEquals(newOpps.get(0).Id, domainsAfter.get(domainM2.Id).Opportunity__c, 'domainM2 should be stamped with the new shared Opportunity');
        System.assertEquals(newOpps.get(0).Id, domainsAfter.get(domainM3.Id).Opportunity__c, 'domainM3 should be stamped with the new shared Opportunity');
    }

    /**
     * A domain can have more than one eligible candidate subscription. If the
     * higher-priority one (preferred by do_not_invoice__c/date_end__c) turns out not to be
     * renewable (unrecognized service type, here), the batch should fall back to the next
     * candidate instead of giving up on the domain entirely.
     */
    public static testMethod void shouldFallBackToNextCandidateWhenBestCandidateFailsValidation() {
        addTestData();
        addTestPricebooks();

        Account testAccount = new Account(Name = 'Fallback Test Account');
        insert testAccount;
        Domain__c domainF1 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_fallback_1', cpAllWebUsers__c = 9, Account__c = testAccount.Id);
        insert domainF1;

        Accounting_Softwareplan__c softwarePlanAdvanced = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Advanced');
        insert softwarePlanAdvanced;
        Accounting_SoftwarePlanVersion__c planVersionAdvanced = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanAdvanced.Id);
        insert planVersionAdvanced;

        // Preferred by the representative comparator (do_not_invoice__c = false), but has a
        // service type the batch doesn't know how to renew - should be passed over...
        Accounting_Subscription__c subscriptionBad = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'UNRECOGNIZED_TYPE', is_active__c = true,
                                                                                     Accounting_subscriber_domain__c = domainF1.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false);
        insert subscriptionBad;
        // ...in favor of this one, which is lower priority (do_not_invoice__c = true) but is actually renewable.
        Accounting_Subscription__c subscriptionGood = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                      Accounting_subscriber_domain__c = domainF1.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = true);
        insert subscriptionGood;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Domain_Name__c FROM Opportunity WHERE AccountId =: testAccount.Id];
        System.assertEquals(1, opps.size(), 'Should fall back to the valid candidate instead of giving up because the preferred one is unrenewable');
        System.assertEquals(domainF1.Id, opps.get(0).Domain_Name__c);
    }

    /**
     * When every candidate in a group fails to resolve (unrecognized service type here,
     * with no fallback available), the group should be skipped silently as far as
     * Opportunity creation goes, but it must still show up in the error log - otherwise
     * finish()'s error email has nothing to surface it in, which was the whole point of
     * logging in the first place.
     */
    public static testMethod void shouldLogErrorWhenNoCandidateInGroupResolves() {
        addTestData();
        addTestPricebooks();

        Account testAccount = new Account(Name = 'Unresolvable Test Account');
        insert testAccount;
        Domain__c domainU1 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_unresolvable_1', cpAllWebUsers__c = 6, Account__c = testAccount.Id);
        insert domainU1;

        Accounting_Softwareplan__c softwarePlanAdvanced = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Advanced');
        insert softwarePlanAdvanced;
        Accounting_SoftwarePlanVersion__c planVersionAdvanced = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanAdvanced.Id);
        insert planVersionAdvanced;

        // Only candidate for this domain, and it isn't renewable - no fallback exists.
        Accounting_Subscription__c subscriptionUnresolvable = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'UNRECOGNIZED_TYPE', is_active__c = true,
                                                                                               Accounting_subscriber_domain__c = domainU1.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false);
        insert subscriptionUnresolvable;
        // Name is assigned by a trigger, not a native autonumber field, so it isn't
        // reflected back onto this variable until re-queried.
        subscriptionUnresolvable = [SELECT Id, Name FROM Accounting_Subscription__c WHERE Id =: subscriptionUnresolvable.Id];

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId =: testAccount.Id];
        System.assertEquals(0, opps.size(), 'No Opportunity should be created when nothing in the group resolves');
        List<Status_Log__c> errorLogs = [SELECT Title__c, Message__c FROM Status_Log__c WHERE Name =: StatusLoggerUtils.RENEWAL_LOGGER AND Status__c =: StatusLoggerUtils.ERROR_LOG];
        System.assertEquals(1, errorLogs.size(), 'The unresolvable group should show up exactly once in the error log for the run\'s email');
        System.assert(errorLogs.get(0).Title__c.contains(subscriptionUnresolvable.Name), 'Error log title should identify the subscription that was tried: ' + errorLogs.get(0).Title__c);
        System.assert(errorLogs.get(0).Message__c.contains('could be turned into a renewal Opportunity'), 'Error log message should explain why: ' + errorLogs.get(0).Message__c);
    }

    /**
     * A missing/deactivated Pricebook entry for a shared edition can fail every domain in a
     * large group at once - Status_Log__c.Title__c is a 255-char field, so a group large
     * enough that every candidate's name wouldn't fit must not throw STRING_TOO_LONG out of
     * start() (which would abort the whole run) when logging the failure.
     */
    public static testMethod void shouldLogBoundedTitleWhenManyCandidatesInGroupFail() {
        addTestData();
        addTestPricebooks();

        Accounting_BillingAccount__c groupBillingAccount = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Grouped', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_manyfail_0', dimagi_contact__c = 'contact_5@dimagi.com');
        insert groupBillingAccount;

        Account groupAccount = new Account(Name = 'Many Failing Candidates Account');
        insert groupAccount;

        Accounting_Softwareplan__c softwarePlanAdvanced = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Advanced');
        insert softwarePlanAdvanced;
        Accounting_SoftwarePlanVersion__c planVersionAdvanced = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanAdvanced.Id);
        insert planVersionAdvanced;

        List<Accounting_Subscription__c> subscriptions = new List<Accounting_Subscription__c>();
        for (Integer i = 0; i < 12; i++) {
            Domain__c domain = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_manyfail_' + i, cpAllWebUsers__c = 1, Account__c = groupAccount.Id);
            insert domain;
            subscriptions.add(new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'UNRECOGNIZED_TYPE', is_active__c = true,
                                                              account__c = groupBillingAccount.Id, Accounting_subscriber_domain__c = domain.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false));
        }
        insert subscriptions;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId =: groupAccount.Id];
        System.assertEquals(0, opps.size(), 'No Opportunity should be created when nothing in the 12-candidate group resolves');
        List<Status_Log__c> errorLogs = [SELECT Title__c FROM Status_Log__c WHERE Name =: StatusLoggerUtils.RENEWAL_LOGGER AND Status__c =: StatusLoggerUtils.ERROR_LOG];
        System.assertEquals(1, errorLogs.size(), 'The 12-candidate group should show up exactly once in the error log');
        System.assert(errorLogs.get(0).Title__c.length() <= 255, 'Title__c must stay within its field limit: ' + errorLogs.get(0).Title__c.length() + ' chars');
        System.assert(errorLogs.get(0).Title__c.contains('more'), 'Title should indicate there were more candidates than shown: ' + errorLogs.get(0).Title__c);
    }

    /**
     * A domain's subscriptions can end up split across two different billing-account groups
     * (e.g. its Account__c was changed on one subscription but not a sibling one for the same
     * domain, or one has an Account__c and another doesn't). Grouping by billing account must
     * not lose the guarantee the old per-domain domainsToSkip gave: at most one Opportunity,
     * and one Domain__c.Opportunity__c stamp, per domain - regardless of which group(s) its
     * subscriptions land in. The two candidates here deliberately differ (edition and
     * date_end__c), not just their billing account, so this also proves the correct
     * (later-ending) one wins the domain - not whichever group's Id happens to sort first.
     */
    public static testMethod void shouldNotDuplicateOpportunityWhenDomainSpansTwoBillingAccounts() {
        addTestData();
        addTestPricebooks();

        Accounting_BillingAccount__c billingAccountA = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'A', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_split', dimagi_contact__c = 'contact_6@dimagi.com');
        insert billingAccountA;
        Accounting_BillingAccount__c billingAccountB = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'B', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_split', dimagi_contact__c = 'contact_6@dimagi.com');
        insert billingAccountB;

        Account testAccount = new Account(Name = 'Split Domain Test Account');
        insert testAccount;
        Domain__c domainSplit = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_split', cpAllWebUsers__c = 3, Account__c = testAccount.Id);
        insert domainSplit;

        Accounting_Softwareplan__c softwarePlanCommunity = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Community');
        insert softwarePlanCommunity;
        Accounting_SoftwarePlanVersion__c planVersionCommunity = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanCommunity.Id);
        insert planVersionCommunity;
        Accounting_Softwareplan__c softwarePlanStandard = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Standard');
        insert softwarePlanStandard;
        Accounting_SoftwarePlanVersion__c planVersionStandard = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanStandard.Id);
        insert planVersionStandard;

        // Two fully valid, independently renewable subscriptions for the SAME domain, under
        // two DIFFERENT billing accounts - each would form its own group - but with different
        // editions and end dates, so only the later one (Standard, Aug 1) should win.
        Accounting_Subscription__c subscriptionViaA = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 6, 15), service_type__c = 'Product', is_active__c = true,
                                                                                      account__c = billingAccountA.Id, Accounting_subscriber_domain__c = domainSplit.Id, plan_version__c = planVersionCommunity.Id, do_not_invoice__c = false);
        insert subscriptionViaA;
        Accounting_Subscription__c subscriptionViaB = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 8, 1), service_type__c = 'Product', is_active__c = true,
                                                                                      account__c = billingAccountB.Id, Accounting_subscriber_domain__c = domainSplit.Id, plan_version__c = planVersionStandard.Id, do_not_invoice__c = false);
        insert subscriptionViaB;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, CloseDate FROM Opportunity WHERE Domain_Name__c =: domainSplit.Id];
        System.assertEquals(1, opps.size(), 'A domain split across two billing-account groups should still produce exactly one Opportunity');
        System.assertEquals(Date.newInstance(2023, 8, 1), opps.get(0).CloseDate, 'The later-ending subscription (Standard, Aug 1) should win the domain, not whichever billing account happened to sort first');

        List<OpportunityLineItem> lineItems = [SELECT ProductCode FROM OpportunityLineItem WHERE OpportunityId =: opps.get(0).Id];
        System.assertEquals(1, lineItems.size());
        System.assertEquals('Standard', lineItems.get(0).ProductCode, 'The winning Opportunity should reflect the later subscription\'s edition (Standard), not the earlier one\'s (Community)');

        Domain__c domainAfter = [SELECT Id, Opportunity__c FROM Domain__c WHERE Id =: domainSplit.Id];
        System.assertEquals(opps.get(0).Id, domainAfter.Opportunity__c, 'The domain should be stamped with the one Opportunity that won, not overwritten by a second one');
    }

    /**
     * A domain spanning two billing accounts, where the higher-priority candidate (later
     * date_end__c) isn't actually renewable, must still fall back to the lower-priority but
     * renewable candidate under the OTHER billing account - not lose its Opportunity entirely
     * just because the priority winner turned out unrenewable.
     */
    public static testMethod void shouldFallBackAcrossBillingAccountsWhenPreferredCandidateIsUnrenewable() {
        addTestData();
        addTestPricebooks();

        Accounting_BillingAccount__c billingAccountA = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'A', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_split_fallback', dimagi_contact__c = 'contact_8@dimagi.com');
        insert billingAccountA;
        Accounting_BillingAccount__c billingAccountB = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'B', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_split_fallback', dimagi_contact__c = 'contact_8@dimagi.com');
        insert billingAccountB;

        Account testAccount = new Account(Name = 'Split Domain Fallback Test Account');
        insert testAccount;
        Domain__c domainSplitFallback = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_split_fallback', cpAllWebUsers__c = 2, Account__c = testAccount.Id);
        insert domainSplitFallback;

        Accounting_Softwareplan__c softwarePlanAdvanced = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Advanced');
        insert softwarePlanAdvanced;
        Accounting_SoftwarePlanVersion__c planVersionAdvanced = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanAdvanced.Id);
        insert planVersionAdvanced;

        // Higher priority (later end date) but NOT renewable, under billingAccountA.
        Accounting_Subscription__c subscriptionViaA = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 8, 1), service_type__c = 'UNRECOGNIZED_TYPE', is_active__c = true,
                                                                                      account__c = billingAccountA.Id, Accounting_subscriber_domain__c = domainSplitFallback.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false);
        insert subscriptionViaA;
        // Lower priority (earlier end date) but fully renewable, under billingAccountB.
        Accounting_Subscription__c subscriptionViaB = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 6, 15), service_type__c = 'Product', is_active__c = true,
                                                                                      account__c = billingAccountB.Id, Accounting_subscriber_domain__c = domainSplitFallback.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false);
        insert subscriptionViaB;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, CloseDate FROM Opportunity WHERE Domain_Name__c =: domainSplitFallback.Id];
        System.assertEquals(1, opps.size(), 'The domain should still get an Opportunity from the renewable candidate under the other billing account, even though the higher-priority one is unrenewable');
        System.assertEquals(Date.newInstance(2023, 6, 15), opps.get(0).CloseDate, 'The Opportunity should reflect the valid (lower-priority) subscription, not the invalid (higher-priority) one');
    }

    /**
     * A missing/deactivated Pricebook entry can make many groups unresolvable in the same
     * run. Error logs for those groups must not be inserted one DML statement at a time
     * inside start()'s single transaction - that would share the 150-DML-statement budget
     * with every group in the run, valid or not, and could abort the whole batch before
     * execute() ever creates a single Opportunity. Asserts the actual DML count directly
     * (not just the outcome) - an outcome-only assertion here would still pass against the
     * old one-insert-per-group implementation at this small a scale.
     */
    public static testMethod void shouldBulkInsertErrorLogsWithoutBlockingAValidGroup() {
        addTestData();
        addTestPricebooks();

        Accounting_Softwareplan__c softwarePlanAdvanced = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Advanced');
        insert softwarePlanAdvanced;
        Accounting_SoftwarePlanVersion__c planVersionAdvanced = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanAdvanced.Id);
        insert planVersionAdvanced;

        // Several distinct, unrelated groups (different billing accounts / domains), each with
        // a single unrenewable candidate.
        List<Accounting_Subscription__c> failingSubscriptions = new List<Accounting_Subscription__c>();
        for (Integer i = 0; i < 5; i++) {
            Accounting_BillingAccount__c failingAccount = new Accounting_BillingAccount__c(Server_Name__c = 'CommCareHQ', account_type__c = 'Failing', is_active__c = true, created_by__c = 'test@dimagi.com', created_by_domain__c = 'domain_bulk_fail_' + i, dimagi_contact__c = 'contact_7@dimagi.com');
            insert failingAccount;
            Domain__c failingDomain = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_bulk_fail_' + i, cpAllWebUsers__c = 1);
            insert failingDomain;
            failingSubscriptions.add(new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'UNRECOGNIZED_TYPE', is_active__c = true,
                                                                     account__c = failingAccount.Id, Accounting_subscriber_domain__c = failingDomain.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false));
        }
        insert failingSubscriptions;

        // One separate, fully valid group that must still succeed.
        Account validAccount = new Account(Name = 'Valid Alongside Failures Account');
        insert validAccount;
        Domain__c validDomain = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_bulk_valid', cpAllWebUsers__c = 1, Account__c = validAccount.Id);
        insert validDomain;
        Accounting_Subscription__c validSubscription = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 7, 1), service_type__c = 'Product', is_active__c = true,
                                                                                       Accounting_subscriber_domain__c = validDomain.Id, plan_version__c = planVersionAdvanced.Id, do_not_invoice__c = false);
        insert validSubscription;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 11));
        // start() runs synchronously in the calling transaction when invoked directly (unlike
        // via Database.executeBatch, which hands it its own async governor-limit context), so
        // Limits.getDmlStatements() here actually reflects what start() itself consumed.
        Integer dmlBeforeStart = Limits.getDmlStatements();
        List<Accounting_Subscription__c> representatives = batchJob.start(null);
        Integer dmlUsedByStart = Limits.getDmlStatements() - dmlBeforeStart;
        System.assertEquals(1, dmlUsedByStart, 'start() should insert all failing-group error logs in a single bulk DML statement, not one per failing group');
        batchJob.execute(null, representatives);
        batchJob.finish(null);
        Test.stopTest();

        List<Opportunity> validOpps = [SELECT Id FROM Opportunity WHERE AccountId =: validAccount.Id];
        System.assertEquals(1, validOpps.size(), 'The valid group must still get its Opportunity - start() must not abort due to error-log DML from the failing groups');

        List<Status_Log__c> errorLogs = [SELECT Id FROM Status_Log__c WHERE Name =: StatusLoggerUtils.RENEWAL_LOGGER AND Status__c =: StatusLoggerUtils.ERROR_LOG];
        System.assertEquals(5, errorLogs.size(), 'Every failing group should still be logged, just bundled into one bulk insert');
    }

    /**
     * When a domain has more than one otherwise-valid candidate subscription, the one
     * ending LATEST should win ("we must create Opp only for the latest subscription which
     * will end") - not the one ending soonest. Both candidates here are equally billed
     * (do_not_invoice__c = false) and both fully valid, so date_end__c is the only thing
     * that can decide it.
     */
    public static testMethod void shouldPreferLatestEndingCandidateOverEarlierOne() {
        addTestData();
        addTestPricebooks();

        Account testAccount = new Account(Name = 'Latest Wins Test Account');
        insert testAccount;
        Domain__c domainL1 = new Domain__c(Server_Name__c = 'CommCareHQ', Name = 'domain_latest_1', cpAllWebUsers__c = 4, Account__c = testAccount.Id);
        insert domainL1;

        Accounting_Softwareplan__c softwarePlanCommunity = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Community');
        insert softwarePlanCommunity;
        Accounting_SoftwarePlanVersion__c planVersionCommunity = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanCommunity.Id);
        insert planVersionCommunity;
        Accounting_Softwareplan__c softwarePlanStandard = new Accounting_Softwareplan__c(Server_Name__c = 'CommCareHQ', edition__c = 'Standard');
        insert softwarePlanStandard;
        Accounting_SoftwarePlanVersion__c planVersionStandard = new Accounting_SoftwarePlanVersion__c(Server_Name__c = 'CommCareHQ', Accounting_SoftwarePlan__c = softwarePlanStandard.Id);
        insert planVersionStandard;

        Accounting_Subscription__c subscriptionEarlier = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 6, 15), service_type__c = 'Product', is_active__c = true,
                                                                                         Accounting_subscriber_domain__c = domainL1.Id, plan_version__c = planVersionCommunity.Id, do_not_invoice__c = false);
        insert subscriptionEarlier;
        Accounting_Subscription__c subscriptionLater = new Accounting_Subscription__c(Server_Name__c = 'CommCareHQ', is_trial__c = false, date_start__c = Date.newInstance(2023, 1, 1), date_end__c = Date.newInstance(2023, 8, 1), service_type__c = 'Product', is_active__c = true,
                                                                                       Accounting_subscriber_domain__c = domainL1.Id, plan_version__c = planVersionStandard.Id, do_not_invoice__c = false);
        insert subscriptionLater;

        Test.startTest();
        RenewalSubscriptionsBatch batchJob = new RenewalSubscriptionsBatch(Date.newInstance(2023, 6, 1));
        Database.executeBatch(batchJob, 50);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, CloseDate FROM Opportunity WHERE AccountId =: testAccount.Id];
        System.assertEquals(1, opps.size());
        System.assertEquals(Date.newInstance(2023, 8, 1), opps.get(0).CloseDate, 'The later-ending subscription should win, not the earlier one');

        List<OpportunityLineItem> lineItems = [SELECT ProductCode FROM OpportunityLineItem WHERE OpportunityId =: opps.get(0).Id];
        System.assertEquals(1, lineItems.size());
        System.assertEquals('Standard', lineItems.get(0).ProductCode, 'The later subscription (Standard) should represent the Opportunity, not the earlier one (Community)');
    }

    private static void addTestPricebooks() {
        Id pricebookId = Test.getStandardPricebookId();

        Product2 productAdvanced = new Product2(Name = 'Hosting: Advanced', ProductCode = 'Advanced', Family = 'Hosting');
        insert productAdvanced;
        Product2 productCommunity = new Product2(Name = 'Hosting: Community', ProductCode = 'Community', Family = 'Hosting');
        insert productCommunity;
        Product2 productEnterprise = new Product2(Name = 'Hosting: Enterprise', ProductCode = 'Enterprise', Family = 'Hosting');
        insert productEnterprise;
        Product2 productPro = new Product2(Name = 'Hosting: Pro', ProductCode = 'Pro', Family = 'Hosting');
        insert productPro;
        Product2 producStandard = new Product2(Name = 'Hosting: Standard', ProductCode = 'Standard', Family = 'Hosting');
        insert producStandard;
        Product2 hosting = new Product2(Name = 'Managed Hosting', ProductCode = 'Managed Hosting', Family = 'Hosting');
        insert hosting;
        Product2 reseller = new Product2(Name = 'Reseller', ProductCode = 'Reseller', Family = 'Hosting');
        insert reseller;
        Product2 commCare = new Product2(Name = 'CommCare', ProductCode = 'CommCare', Family = 'Product');
        insert commCare;

        PricebookEntry productAdvancedPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productAdvanced.Id, UnitPrice = 1000, IsActive = true);
        insert productAdvancedPrice;
        PricebookEntry productCommunityPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productCommunity.Id, UnitPrice = 0, IsActive = true);
        insert productCommunityPrice;
        PricebookEntry productEnterprisePrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productEnterprise.Id, UnitPrice = 2000, IsActive = true);
        insert productEnterprisePrice;
        PricebookEntry productProPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productPro.Id, UnitPrice = 3000, IsActive = true);
        insert productProPrice;
        PricebookEntry producStandardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = producStandard.Id, UnitPrice = 500, IsActive = true);
        insert producStandardPrice;
        PricebookEntry producCommCarePrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = commCare.Id, UnitPrice = 650000, IsActive = true);
        insert producCommCarePrice;
        PricebookEntry hostingPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = hosting.Id, UnitPrice = 2000, IsActive = true);
        insert hostingPrice;
        PricebookEntry resellerPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = reseller.Id, UnitPrice = 2000, IsActive = true);
        insert resellerPrice;

        Pricebook2 dimagiPB = new Pricebook2(Name = 'Dimagi', isActive = true);
        insert dimagiPB;

        PricebookEntry productAdvancedPrice2 = new PricebookEntry(Pricebook2Id = dimagiPB.Id, Product2Id = productAdvanced.Id, UnitPrice = 1000, IsActive = true);
        insert productAdvancedPrice2;
        PricebookEntry productCommunityPrice2 = new PricebookEntry(Pricebook2Id = dimagiPB.Id, Product2Id = productCommunity.Id, UnitPrice = 0, IsActive = true);
        insert productCommunityPrice2;
        PricebookEntry productEnterprisePrice2 = new PricebookEntry(Pricebook2Id = dimagiPB.Id, Product2Id = productEnterprise.Id, UnitPrice = 2000, IsActive = true);
        insert productEnterprisePrice2;
        PricebookEntry productProPrice2 = new PricebookEntry(Pricebook2Id = dimagiPB.Id, Product2Id = productPro.Id, UnitPrice = 3000, IsActive = true);
        insert productProPrice2;
        PricebookEntry producStandardPrice2 = new PricebookEntry(Pricebook2Id = dimagiPB.Id, Product2Id = producStandard.Id, UnitPrice = 500, IsActive = true);
        insert producStandardPrice2;
        PricebookEntry producCommCarePrice2 = new PricebookEntry(Pricebook2Id = dimagiPB.Id, Product2Id = commCare.Id, UnitPrice = 650000, IsActive = true);
        insert producCommCarePrice2;
        PricebookEntry hostingPrice2 = new PricebookEntry(Pricebook2Id = dimagiPB.Id, Product2Id = hosting.Id, UnitPrice = 2000, IsActive = true);
        insert hostingPrice2;
        PricebookEntry resellerPrice2 = new PricebookEntry(Pricebook2Id = dimagiPB.Id, Product2Id = reseller.Id, UnitPrice = 2000, IsActive = true);
        insert resellerPrice2;
    }
}