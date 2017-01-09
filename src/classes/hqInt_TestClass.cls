@isTest
private class hqInt_TestClass {
/**
    @testSetup
    static void setupCustomSetting() {
        CommcareToSalesforceSettings__c[] customSettings = new list <CommcareToSalesforceSettings__c>();

        CommcareToSalesforceSettings__c testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'ApiLimitParameter';
        testCustomSetting.value__c = '10';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'BatchFailureReportRecepeint';
        testCustomSetting.value__c = 'BatchFailureReportRecepeint@gmail.com;';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'CommCarePassword';
        testCustomSetting.value__c = 'CommCarePassword';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'CommCareUserName';
        testCustomSetting.value__c = 'CommCareUserName@gmail.com';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'LastRunDate';
        testCustomSetting.value__c = '2015-01-01';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'JOBSTARTDATE';
        testCustomSetting.value__c = '2015-01-01';
        customSettings.add(testCustomSetting);

        insert customSettings;
    }

    @isTest
    static void hqInt_TestMethod() {
        Test.startTest();

        //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext     bc;
        hqInt_MainClassBatch bClass = new hqInt_MainClassBatch();

        // we execute the start() and prepare results for execute()
        // in my use case, start() does the callout;
        // thus the testmethod mocks the results of the callout (assumed here to be accounts)
        // setup of custom Iterable and Iterator not shown
        Integer[]  itrbl = (Integer[])bclass.start(bc);  //start() returns an iterable, in my case, a custom iterable.
        //Note the casting
        //iterator  itrator = (Iterable<Integer>) itrbl.iterator();  // continue simulation of start() by constructing the iterator//
        Integer[] aScopeList = new Integer[]{};

        //create scope for execute() by iterating against the result of the mocked callout

        aScopeList.add(0);
        //while (itrator.hasNext())
        //{
        //aScopeList.add(itrator.next());

        // Now invoke execute() w/ Account list built via mocked callout invoked by start()
        system.debug('---bc--'+bc);
        bClass.execute(bc,aScopeList);

        // Finally, invoke finish()
        bClass.finish(bc);
        Test.stopTest();
    }

    @isTest
    static void hqInt_TestMethodPhase2_SoftPlan() {
        Test.startTest();

        //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext     bc;
        hqInt_BatchFetchObjectSoftwarePlan bClass = new hqInt_BatchFetchObjectSoftwarePlan(1);

        Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable.

        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
        bClass.execute(bc,aScopeList);

        // Finally, invoke finish()
        bClass.finish(bc);
        Test.stopTest();
    }

    @isTest
    static void hqInt_TestMethodPhase2_Subscriber() {
        Test.startTest();

        //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext     bc;
        hqInt_BatchFetchObjectSubscriber bClass = new hqInt_BatchFetchObjectSubscriber(1);

        Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable.

        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
        bClass.execute(bc,aScopeList);

            // Finally, invoke finish()
            bClass.finish(bc);
            Test.stopTest();
    }

    @isTest 
    static void hqInt_TestMethodPhase2_Invoice() {
        Test.startTest();

        //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext     bc;
        hqInt_BatchFetchObjectAcctingInvoice bClass = new hqInt_BatchFetchObjectAcctingInvoice(1);

        Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable.

        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
        bClass.execute(bc,aScopeList);

        // Finally, invoke finish()
        bClass.finish(bc);
        Test.stopTest();
    }

    @isTest
    static void hqInt_TestMethodManualRunController() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        hqInt_ManualRunController obj = new hqInt_ManualRunController();
        obj.runBatchJob();
        Test.StopTest();
    }

    @isTest
    static void hqInt_TestMethodErrorLogger() {
        hqInt_BatchErrorLogger.logError('abc','test error details','Actual Error Message','LIne no error in class');
    }

/**
    @isTest
    static void hqInt_TestMethodManualRunController2()
    {
    
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        hqInt_ManualRunController obj = new hqInt_ManualRunController();
        obj.runBatchJobPhase2();
        Test.StopTest();
    
    }
    **/
/**
    @isTest
    static void hqInt_TestSubsAdjTrigger() {
        Accounting_SubscriptionAdjustment__c obj = new Accounting_SubscriptionAdjustment__c();
        insert obj;
    }




    @isTest
    static void hqIntTestSubscription() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext     bc;
        hqInt_BatchFetchObjectSubscription bClass = new hqInt_BatchFetchObjectSubscription(1);

        Integer[]  itrbl = (Integer[])bClass.start(bc);

        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
        bClass.execute(bc,aScopeList);

        List<Accounting_Subscription__c> subscriptions = [SELECT id__c FROM Accounting_Subscription__c];
        System.assertEquals(4, subscriptions.size());

        Accounting_Subscription__c subscription = [SELECT id__c, service_type__c, pro_bono_status__c, funding_source__c FROM Accounting_Subscription__c WHERE id__c = '1'];
        System.assertEquals('NOT_SET', subscription.service_type__c);
        System.assertEquals('NOT_SET', subscription.pro_bono_status__c);
        System.assertEquals('CLIENT', subscription.funding_source__c);

        subscription = [SELECT id__c, service_type__c, pro_bono_status__c, funding_source__c  FROM Accounting_Subscription__c
                            WHERE id__c = '2'];
        System.assertEquals('NOT_SET', subscription.service_type__c);
        System.assertEquals('NOT_SET', subscription.pro_bono_status__c);
        System.assertEquals('CLIENT', subscription.funding_source__c);

        subscription = [SELECT id__c, service_type__c, pro_bono_status__c, funding_source__c  FROM Accounting_Subscription__c
                            WHERE id__c = '3'];
        System.assertEquals('TRIAL', subscription.service_type__c);
        System.assertEquals('NOT_SET', subscription.pro_bono_status__c);
        System.assertEquals('CLIENT', subscription.funding_source__c);

        subscription = [SELECT id__c, service_type__c, pro_bono_status__c, funding_source__c  FROM Accounting_Subscription__c
                            WHERE id__c = '4'];
        System.assertEquals('PRODUCT', subscription.service_type__c);
        System.assertEquals('FULL_PRICE', subscription.pro_bono_status__c);
        System.assertEquals('CLIENT', subscription.funding_source__c);

        bClass.finish(bc);
        Test.stopTest();
    }

    @isTest
    static void hqIntTestBillingAccount() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext bc;
        hqInt_BatchFetchObjectBillingAccount bClass = new hqInt_BatchFetchObjectBillingAccount(1);

        Integer[]  itrbl = (Integer[])bClass.start(bc);
        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
        bClass.execute(bc,aScopeList);

        List<Accounting_BillingAccount__c> billings = [SELECT id__c FROM Accounting_BillingAccount__c];
        System.assertEquals(3, billings.size());

        Accounting_BillingAccount__c billing = [SELECT id__c, last_payment_method__c, pre_or_post_pay__c FROM Accounting_BillingAccount__c WHERE id__c = '1'];
        System.assertEquals('CC_ONE_TIME', billing.last_payment_method__c);
        System.assertEquals('PREPAY', billing.pre_or_post_pay__c);

        billing = [SELECT id__c, last_payment_method__c, pre_or_post_pay__c FROM Accounting_BillingAccount__c WHERE id__c = '2'];
        System.assertEquals('CC_AUTO', billing.last_payment_method__c);
        System.assertEquals('NOT_SET', billing.pre_or_post_pay__c);

        billing = [SELECT id__c, last_payment_method__c, pre_or_post_pay__c FROM Accounting_BillingAccount__c WHERE id__c = '3'];
        System.assertEquals('NONE', billing.last_payment_method__c);
        System.assertEquals('POSTPAY', billing.pre_or_post_pay__c);

        bClass.finish(bc);
        Test.stopTest();
    }

    @isTest
    static void hqIntTestBillingContact() {

        hqInt_ModelClass.Accounting_BillingContactInfo newContact = new hqInt_ModelClass.Accounting_BillingContactInfo();
        newContact.account = '1';
        newContact.emails = 'emails@old.com';

        insert newContact.createDbObject();

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext bc;
        hqInt_BatchFetchObjectBillingContactInfo billingContactInfoBatch = new hqInt_BatchFetchObjectBillingContactInfo(1);

        Integer[]  itrbl = (Integer[]) billingContactInfoBatch.start(bc);
        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
        billingContactInfoBatch.execute(bc, aScopeList);

        List<Accounting_BillingContactInfo__c> billingContacts = [SELECT accountid__c FROM Accounting_BillingContactInfo__c];
        System.assertEquals(4, billingContacts.size());

        Accounting_BillingContactInfo__c contact = [SELECT accountid__c, city__c, company_name__c, country__c, emails__c, first_line__c, first_name__c,
                                                        last_name__c , phone_number__c, postal_code__c, second_line__c, state_province_region__c
                                                        FROM Accounting_BillingContactInfo__c WHERE accountid__c = '1'];
        System.assertEquals('1', contact.accountid__c);
        System.assertEquals('City_1', contact.city__c);
        System.assertEquals('Company_1', contact.company_name__c);
        System.assertEquals('US', contact.country__c);
        System.assertEquals('email_updated@gmail.com', contact.emails__c);
        System.assertEquals('first_line_1', contact.first_line__c);
        System.assertEquals('Name_1', contact.first_name__c);
        System.assertEquals('Last_name_1', contact.last_name__c);
        System.assertEquals('+48123123', contact.phone_number__c);
        System.assertEquals('123123', contact.postal_code__c);
        System.assertEquals('Second_1', contact.second_line__c);
        System.assertEquals('XD', contact.state_province_region__c);

        contact = [SELECT accountid__c, city__c, company_name__c, country__c, emails__c, first_line__c, first_name__c, last_name__c , phone_number__c,
                    postal_code__c, second_line__c, state_province_region__c FROM Accounting_BillingContactInfo__c WHERE accountid__c = '2'];
        System.assertEquals('2', contact.accountid__c);
        System.assertEquals('empty data', contact.city__c);
        System.assertEquals(null, contact.company_name__c);
        System.assertEquals(null, contact.country__c);
        System.assertEquals(null, contact.emails__c);
        System.assertEquals(null, contact.first_line__c);
        System.assertEquals(null, contact.first_name__c);
        System.assertEquals(null, contact.last_name__c);
        System.assertEquals(null, contact.phone_number__c);
        System.assertEquals('11', contact.postal_code__c);
        System.assertEquals(null, contact.second_line__c);
        System.assertEquals(null, contact.state_province_region__c);

        contact = [SELECT accountid__c, city__c, company_name__c, country__c, emails__c, first_line__c, first_name__c, last_name__c , phone_number__c,
                    postal_code__c, second_line__c, state_province_region__c FROM Accounting_BillingContactInfo__c WHERE accountid__c = '3'];
        System.assertEquals('3', contact.accountid__c);
        System.assertEquals('City_3', contact.city__c);
        System.assertEquals('Company_3', contact.company_name__c);
        System.assertEquals('US', contact.country__c);
        System.assertEquals('em31@gmail.com,em32@gmail.com', contact.emails__c);
        System.assertEquals('first_line_3', contact.first_line__c);
        System.assertEquals('Name_3', contact.first_name__c);
        System.assertEquals('Last_name_3', contact.last_name__c);
        System.assertEquals('+483123123', contact.phone_number__c);
        System.assertEquals('113', contact.postal_code__c);
        System.assertEquals('Second_3', contact.second_line__c);
        System.assertEquals('T_3', contact.state_province_region__c);

        contact = [SELECT accountid__c, city__c, company_name__c, country__c, emails__c, first_line__c, first_name__c, last_name__c , phone_number__c,
                    postal_code__c, second_line__c, state_province_region__c FROM Accounting_BillingContactInfo__c WHERE accountid__c = '4'];
        System.assertEquals('4', contact.accountid__c);
        System.assertEquals('City_4', contact.city__c);
        System.assertEquals('Company_4', contact.company_name__c);
        System.assertEquals('US', contact.country__c);
        System.assertEquals('qwe1@gmail.com', contact.emails__c);
        System.assertEquals('first_line_4', contact.first_line__c);
        System.assertEquals('Name_4', contact.first_name__c);
        System.assertEquals('Last_name_4', contact.last_name__c);
        System.assertEquals('+483444123', contact.phone_number__c);
        System.assertEquals('11443', contact.postal_code__c);
        System.assertEquals('Second_4', contact.second_line__c);
        System.assertEquals('T_4', contact.state_province_region__c);

        billingContactInfoBatch.finish(bc);
        Test.stopTest();
    }

    @isTest
    static void hqIntTestMethodPhase2SoftPlanVer() {
        createSoftwarePlan('1');
        createSoftwarePlan('3');
        createSoftwarePlan('4');
        createSoftwarePlan('5');
        createSoftwarePlan('7');
        createProductRate('9');
        createProductRate('11');
        createProductRate('12');
        createProductRate('13');
        createProductRate('15');

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext bc;
        hqInt_BatchFetchObjectSoftwarePlanVer softwarePlanBatch = new hqInt_BatchFetchObjectSoftwarePlanVer(1);

        Integer[]  itrbl = (Integer[]) softwarePlanBatch.start(bc);
        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
        softwarePlanBatch.execute(bc, aScopeList);

        List<Accounting_SoftwarePlanVersion__c> softwarePlans = [SELECT id__c FROM Accounting_SoftwarePlanVersion__c];
        System.debug('--softwarePlans--' + softwarePlans);
        System.assertEquals(5, softwarePlans.size());

        Accounting_SoftwarePlanVersion__c planVersion = [SELECT id__c, Software_Product_Rate__r.id__c, Accounting_SoftwarePlan__r.id__c, is_active__c, FeatureRates__c
                                                            FROM Accounting_SoftwarePlanVersion__c WHERE id__c = '25'];
        System.assertEquals(false, planVersion.is_active__c);
        System.assertEquals('17,18', planVersion.FeatureRates__c);
        System.assertEquals('9', planVersion.Software_Product_Rate__r.id__c);
        System.assertEquals('1', planVersion.Accounting_SoftwarePlan__r.id__c);

        planVersion = [SELECT id__c, Software_Product_Rate__r.id__c, Accounting_SoftwarePlan__r.id__c, is_active__c, FeatureRates__c
                        FROM Accounting_SoftwarePlanVersion__c WHERE id__c = '27'];
        System.assertEquals(true, planVersion.is_active__c);
        System.assertEquals('22,21', planVersion.FeatureRates__c);
        System.assertEquals('11', planVersion.Software_Product_Rate__r.id__c);
        System.assertEquals('3', planVersion.Accounting_SoftwarePlan__r.id__c);

        planVersion = [SELECT id__c, Software_Product_Rate__r.id__c, Accounting_SoftwarePlan__r.id__c, is_active__c, FeatureRates__c
                            FROM Accounting_SoftwarePlanVersion__c WHERE id__c = '28'];
        System.assertEquals(true, planVersion.is_active__c);
        System.assertEquals('24,23', planVersion.FeatureRates__c);
        System.assertEquals('12', planVersion.Software_Product_Rate__r.id__c);
        System.assertEquals('4', planVersion.Accounting_SoftwarePlan__r.id__c);

        planVersion = [SELECT id__c, Software_Product_Rate__r.id__c, Accounting_SoftwarePlan__r.id__c, is_active__c, FeatureRates__c
                            FROM Accounting_SoftwarePlanVersion__c WHERE id__c = '29'];
        System.assertEquals(true, planVersion.is_active__c);
        System.assertEquals('25,26', planVersion.FeatureRates__c);
        System.assertEquals('13', planVersion.Software_Product_Rate__r.id__c);
        System.assertEquals('5', planVersion.Accounting_SoftwarePlan__r.id__c);

        planVersion = [SELECT id__c, Software_Product_Rate__r.id__c, Accounting_SoftwarePlan__r.id__c, is_active__c, FeatureRates__c
                            FROM Accounting_SoftwarePlanVersion__c WHERE id__c = '31'];
        System.assertEquals(true, planVersion.is_active__c);
        System.assertEquals('29,30', planVersion.FeatureRates__c);
        System.assertEquals('15', planVersion.Software_Product_Rate__r.id__c);
        System.assertEquals('7', planVersion.Accounting_SoftwarePlan__r.id__c);
        softwarePlanBatch.finish(bc);

        Test.stopTest();
    }

    @isTest
    static void hqintTestSoftwareProductRateBatch() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext bc;
        hqInt_BatchFetchObjectProductRate productRateBatch = new hqInt_BatchFetchObjectProductRate(1);

        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);

        productRateBatch.execute(bc, aScopeList);

        List<Accounting_SoftwareProductRate__c> productsRates = [SELECT id__c, monthly_fee__c FROM Accounting_SoftwareProductRate__c];
        System.assertEquals(5, productsRates.size());

        Accounting_SoftwareProductRate__c productRate = [SELECT id__c, monthly_fee__c FROM Accounting_SoftwareProductRate__c WHERE id__c = '9'];
        System.assertEquals(0.00, productRate.monthly_fee__c);
        productRate = [SELECT id__c, monthly_fee__c FROM Accounting_SoftwareProductRate__c WHERE id__c = '10'];
        System.assertEquals(100.00, productRate.monthly_fee__c);
        productRate = [SELECT id__c, monthly_fee__c FROM Accounting_SoftwareProductRate__c WHERE id__c = '11'];
        System.assertEquals(500.00, productRate.monthly_fee__c);
        productRate = [SELECT id__c, monthly_fee__c FROM Accounting_SoftwareProductRate__c WHERE id__c = '12'];
        System.assertEquals(1000.00, productRate.monthly_fee__c);
        productRate = [SELECT id__c, monthly_fee__c FROM Accounting_SoftwareProductRate__c WHERE id__c = '13'];
        System.assertEquals(0.00, productRate.monthly_fee__c);

        productRateBatch.finish(bc);

        Test.stopTest();
    }

    @isTest
    static void hqIntShouldUpdateMissingRelationsInSubscriberCustomObject() {
        Test.startTest();

        Domain__c d1 = buildDomain(1);
        Domain__c d2 = buildDomain(2);
        Domain__c d3 = buildDomain(3);
        buildSubscriber(1, null);
        buildSubscriber(2, null);
        buildSubscriber(3, d3.Id);   

        List<Accounting_Subscriber__c> subscribers = [SELECT id__c, domain__c, domain_lookup__c FROM Accounting_Subscriber__c];
        System.assertEquals(3, subscribers.size());

        hqInt_BatchFetchObjectSubscriber batchSubscriber = new hqInt_BatchFetchObjectSubscriber(1);
        batchSubscriber.finish(null);

        Accounting_Subscriber__c subscriber = [SELECT id__c, domain__c, domain_lookup__c FROM Accounting_Subscriber__c WHERE id__c = 'external_id_1'];
        System.assertEquals(d1.Id, subscriber.domain_lookup__c);
        subscriber = [SELECT id__c, domain__c, domain_lookup__c FROM Accounting_Subscriber__c WHERE id__c = 'external_id_2'];
        System.assertEquals(d2.Id, subscriber.domain_lookup__c);
        subscriber = [SELECT id__c, domain__c, domain_lookup__c FROM Accounting_Subscriber__c WHERE id__c = 'external_id_3'];
        System.assertEquals(d3.Id, subscriber.domain_lookup__c);
        Test.stopTest();
    }

    @isTest
    static void hqIntShouldUpdateMissingRelationsInAccountingCustomObject() {
        Test.startTest();

        Domain__c d1 = buildDomain(1);
        Domain__c d2 = buildDomain(2);
        Domain__c d3 = buildDomain(3);
        Accounting_Subscriber__c s1 = buildSubscriber(1, null);
        Accounting_Subscriber__c s2 = buildSubscriber(2, null);
        Accounting_Subscriber__c s3 = buildSubscriber(3, d3.Id);
        Accounting_Subscription__c sub1 = buildSubscription(1, s1.Id);
        Accounting_Subscription__c sub2 = buildSubscription(2, s2.Id);
        Accounting_Subscription__c sub3 = buildSubscription(3, s3.Id);
        buildInvoice(1, sub1.Id, null);
        buildInvoice(2, sub2.Id, null);
        buildInvoice(3, sub3.Id, d3.Id);

        List<Accounting_Invoice__c> invoiceList = [SELECT id__c, Project_Space__c FROM Accounting_Invoice__c];
        System.assertEquals(3, invoiceList.size());

        hqInt_BatchFetchObjectAcctingInvoice batchInvoice = new hqInt_BatchFetchObjectAcctingInvoice(1);
        batchInvoice.finish(null);

        Accounting_Invoice__c invoice = [SELECT id__c, Project_Space__c FROM Accounting_Invoice__c WHERE id__c = 'external_id_1'];
        System.assertEquals(d1.Id, invoice.Project_Space__c);
        invoice = [SELECT id__c, Project_Space__c FROM Accounting_Invoice__c WHERE id__c = 'external_id_2'];
        System.assertEquals(d2.Id, invoice.Project_Space__c);
        invoice = [SELECT id__c, Project_Space__c FROM Accounting_Invoice__c WHERE id__c = 'external_id_3'];
        System.assertEquals(d3.Id, invoice.Project_Space__c);
        Test.stopTest();
    }

    @isTest
    static void hqIntTestLifetimeMRRCalculation() {
        Test.startTest();

        Accounting_SoftwareProductRate__c productRate1 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 150);
        Accounting_SoftwareProductRate__c productRate2 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 75);
        Accounting_SoftwareProductRate__c productRate3 = new Accounting_SoftwareProductRate__c(is_active__c = true,  monthly_fee__c = 25);

        insert productRate1;
        insert productRate2;
        insert productRate3;

        Accounting_Softwareplan__c softwarePlan1 = new Accounting_Softwareplan__c(Name = 'softwarePlan1');
        Accounting_Softwareplan__c softwarePlan2 = new Accounting_Softwareplan__c(Name = 'softwarePlan2');
        Accounting_Softwareplan__c softwarePlan3 = new Accounting_Softwareplan__c(Name = 'softwarePlan3');

        insert softwarePlan1;
        insert softwarePlan2;
        insert softwarePlan3;

        Accounting_SoftwarePlanVersion__c planVersion1 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate1.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan1.Id);
        Accounting_SoftwarePlanVersion__c planVersion2 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate2.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan2.Id);
        Accounting_SoftwarePlanVersion__c planVersion3 = new Accounting_SoftwarePlanVersion__c(is_active__c = true, Software_Product_Rate__c = productRate3.Id,
                                                                                               Accounting_SoftwarePlan__c = softwarePlan3.Id);

        insert planVersion1;
        insert planVersion2;
        insert planVersion3;

        Domain__c domain1 = new Domain__c(Name = 'Sample 1');
        Domain__c domain2 = new Domain__c(Name = 'Sample 2');
        Domain__c domain3 = new Domain__c(Name = 'Sample 3');

        insert domain1;
        insert domain2;
        insert domain3;

        Accounting_Subscription__c subscription1 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2015, 11, 2), date_end__c = Date.newInstance(2016, 2 ,1),
                                                                                  Accounting_subscriber_domain__c = domain1.Id, plan_version__c = planVersion1.Id);
        insert subscription1;
        Accounting_Subscription__c subscription2 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2016, 1, 1), date_end__c = Date.newInstance(2016, 2 ,1),
                                                                                  Accounting_subscriber_domain__c = domain1.Id, plan_version__c = planVersion2.Id);
        insert subscription2;
        Accounting_Subscription__c subscription3 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2014, 1, 1), date_end__c = Date.newInstance(2014, 3 ,4),
                                                                                  Accounting_subscriber_domain__c = domain1.Id, plan_version__c = planVersion3.Id);
        insert subscription3;
        Accounting_Subscription__c subscription4 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2016, 1, 1), date_end__c = Date.newInstance(2016, 2 ,1),
                                                                                  Accounting_subscriber_domain__c = domain2.Id, plan_version__c = planVersion1.Id);
        insert subscription4;
        Accounting_Subscription__c subscription5 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2016, 1, 1), date_end__c = Date.newInstance(2016, 2 ,1),
                                                                                  Accounting_subscriber_domain__c = domain2.Id, plan_version__c = planVersion2.Id);
        insert subscription5;
        Accounting_Subscription__c subscription6 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2013, 6, 6), date_end__c = Date.newInstance(2014, 5 ,5),
                                                                                  Accounting_subscriber_domain__c = domain2.Id, plan_version__c = planVersion3.Id);
        insert subscription6;
        Accounting_Subscription__c subscription7 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2016, 1, 1), date_end__c = Date.newInstance(2016, 2 ,1),
                                                                                  Accounting_subscriber_domain__c = domain2.Id, plan_version__c = planVersion1.Id);
        insert subscription7;
        Accounting_Subscription__c subscription8 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2016, 2, 1), date_end__c = Date.newInstance(2016, 4, 4),
                                                                                  Accounting_subscriber_domain__c = domain3.Id, plan_version__c = planVersion2.Id);
        insert subscription8;
        Accounting_Subscription__c subscription9 = new Accounting_Subscription__c(date_start__c = Date.newInstance(2016, 1, 14), date_end__c = Date.newInstance(2016, 2 ,10),
                                                                                  Accounting_subscriber_domain__c = domain3.Id, plan_version__c = planVersion3.Id);
        insert subscription9;

        Database.executeBatch(new CalculateDomainsLifeTimeMRRBatch(), 200);

        Test.stopTest();

        Domain__c domainFromDB1 = [SELECT Lifetime_MRR__c FROM Domain__c WHERE Name = 'Sample 1' LIMIT 1];
        System.assertEquals(calculateMRRForDomain(domain1.Id, 3), domainFromDB1.Lifetime_MRR__c);
        Domain__c domainFromDB2 = [SELECT Lifetime_MRR__c FROM Domain__c WHERE Name = 'Sample 2' LIMIT 1];
        System.assertEquals(calculateMRRForDomain(domain2.Id, 4), domainFromDB2.Lifetime_MRR__c);
        Domain__c domainFromDB3 = [SELECT Lifetime_MRR__c FROM Domain__c WHERE Name = 'Sample 3' LIMIT 1];
        System.assertEquals(calculateMRRForDomain(domain3.Id, 2), domainFromDB3.Lifetime_MRR__c);
        System.debug(domainFromDB1);
        System.debug(domainFromDB2);
        System.debug(domainFromDB3);
    }


    */
}