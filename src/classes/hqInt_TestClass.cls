@isTest
private class hqInt_TestClass {

    @testSetup
    static void setupCustomSetting() {
        CommcareToSalesforceSettings__c[] customSettings = new list <CommcareToSalesforceSettings__c>();

        CommcareToSalesforceSettings__c testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'ApiLimitParameter';
        testCustomSetting.value__c = '10';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'BatchFailureReportRecepeint';
        testCustomSetting.value__c = 'angadpathak@outlook.com;';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'CommCarePassword';
        testCustomSetting.value__c = 'Google@123';
        customSettings.add(testCustomSetting);

        testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.name = 'CommCareUserName';
        testCustomSetting.value__c = 'niketsoral@gmail.com';
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
    static void hqInt_TestMethodPhase2_SoftPlanVer() {
        Test.startTest();

        //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext     bc;
        hqInt_BatchFetchObjectSoftwarePlanVer bClass = new hqInt_BatchFetchObjectSoftwarePlanVer(1);

        Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable.
        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
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
    static void hqInt_TestMethodPhase2_Subscription() {
        Test.startTest();

        //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext     bc;
        hqInt_BatchFetchObjectSubscription bClass = new hqInt_BatchFetchObjectSubscription(1);

        Integer[]  itrbl = (Integer[])bClass.start(bc);  //start() returns an iterable, in my case, a custom iterable.

        Integer[] aScopeList = new Integer[]{};
        aScopeList.add(0);
        bClass.execute(bc,aScopeList);

        // Finally, invoke finish()
        bClass.finish(bc);
        Test.stopTest();
    }

    @isTest
    static void hqInt_TestMethodPhase2_BillingAccount() {

        Test.startTest();

        //Test.setMock(HttpCalloutMock.class, myMultiMockObject); // setup of multiMockObject omitted for clarity
        Test.setMock(HttpCalloutMock.class, new hqInt_HttpMock());
        Database.BatchableContext     bc;
        hqInt_BatchFetchObjectBillingAccount bClass = new hqInt_BatchFetchObjectBillingAccount(1);

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

    @isTest
    static void hqInt_TestSubsAdjTrigger() {
        Accounting_SubscriptionAdjustment__c obj = new Accounting_SubscriptionAdjustment__c();
        insert obj;
    }

    @isTest
    static void hqInt_ShouldUpdateMissingRelationsInSubscriberCustomObject() {
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
    static void hqInt_ShouldUpdateMissingRelationsInAccountingCustomObject() {
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

    static private Accounting_Invoice__c buildInvoice(Integer i, Id subsciptionId, Id domainId) {
        hqInt_ModelClass.Accounting_Invoice a = new hqInt_ModelClass.Accounting_Invoice();
        a.id = 'external_id_' + i;
        a.is_hidden = false;
        a.is_hidden_to_ops = false;
        Accounting_Invoice__c aFromDB  = a.createDbObject(subsciptionId, domainId);
        insert aFromDb;
        return aFromDb;
    }

    static private Accounting_Subscription__c buildSubscription(Integer i, Id subscriberId) {
        hqInt_ModelClass.Accounting_Subscription a = new hqInt_ModelClass.Accounting_Subscription();
        a.id = 'external_id_' + i;
        a.is_active = true;
        a.do_not_invoice = true;
        a.auto_generate_credits = false;
        a.is_trial = true;
        Accounting_Subscription__c aFromDB  = a.createDbObject(null, null, subscriberId);
        insert aFromDb;
        return aFromDb;
    }

    static private Accounting_Subscriber__c buildSubscriber(Integer i, Id domainId) {
        hqInt_ModelClass.Accounting_Subscriber a = new hqInt_ModelClass.Accounting_Subscriber();
        a.id = 'external_id_' + i;
        a.domain = 'domain_name_' + i;
        Accounting_Subscriber__c aFromDB  = a.createDbObject(domainId);
        insert aFromDb;
        return aFromDb;
    }

    static private Domain__c buildDomain(Integer i) {
        hqInt_Model_DomainClass d = new hqInt_Model_DomainClass();
        d.x_id = 'domain_' + i;
        d.Name = 'domain_name_' + i;
        d.tags = new List<String> { ' ' };
        Domain__c domainFromDb = d.createDbObject(null);
        insert domainFromDb;
        return domainFromDb;
    }
}