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
        renewalList = batchJob.getSubscriptionsForRenewal(new Set<String> { 'domain_2' });
        System.assertEquals(2, renewalList.size());
        batchJob.start(null);
        batchJob.execute(null, renewalList);
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
     * RenewalSubscriptionsScheduler runs this batch with a scope of 10, so execute() only
     * ever sees a slice of the eligible subscriptions at a time - a grouped billing account
     * with more members than that (see the TECHOPS-211 analysis) spans multiple execute()
     * calls. This forces that with a scope of 1, so every subscription in the group lands in
     * its own chunk, to prove grouping still collapses to a single Opportunity.
     */
    public static testMethod void shouldCreateOneOppForGroupSpanningMultipleBatchChunks() {
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
        // Database.executeBatch always runs a List-returning start() as a single chunk in
        // test context (Salesforce won't let a test force >1 chunk that way), so multiple
        // execute() calls are driven directly here to simulate the group spanning chunks
        // the way it would in production with a scope of 10.
        List<Accounting_Subscription__c> renewalList = batchJob.start(null);
        System.assertEquals(3, renewalList.size());
        for (Accounting_Subscription__c subscription : renewalList) {
            batchJob.execute(null, new List<Accounting_Subscription__c> { subscription });
        }
        batchJob.finish(null);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Domain_Name__c FROM Opportunity WHERE AccountId =: groupAccount.Id];
        System.assertEquals(1, opps.size(), 'A group split across multiple execute() chunks should still produce exactly one Opportunity');
        System.assertEquals(domainC3.Id, opps.get(0).Domain_Name__c, 'The billed (non Do-Not-Invoice) domain should represent the group');
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