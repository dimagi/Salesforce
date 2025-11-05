@IsTest
private class RenewalSubscriptionsSchedulerTest {

    // Helper method to add all products and pricebooks
    private static void addTestPricebooks() {
        Id standardPBId = Test.getStandardPricebookId();

        // Create Products
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Hosting: Advanced', ProductCode = 'Advanced', Family = 'Hosting'));
        products.add(new Product2(Name = 'Hosting: Community', ProductCode = 'Community', Family = 'Hosting'));
        products.add(new Product2(Name = 'Hosting: Enterprise', ProductCode = 'Enterprise', Family = 'Hosting'));
        products.add(new Product2(Name = 'Hosting: Pro', ProductCode = 'Pro', Family = 'Hosting'));
        products.add(new Product2(Name = 'Hosting: Standard', ProductCode = 'Standard', Family = 'Hosting'));
        products.add(new Product2(Name = 'Managed Hosting', ProductCode = 'Managed Hosting', Family = 'Hosting'));
        products.add(new Product2(Name = 'Reseller', ProductCode = 'Reseller', Family = 'Hosting'));
        products.add(new Product2(Name = 'CommCare', ProductCode = 'CommCare', Family = 'Product'));
        insert products;

        // Standard PriceBookEntries
        List<PricebookEntry> standardEntries = new List<PricebookEntry>();
        for (Product2 p : products) {
            Decimal price = (p.ProductCode == 'CommCare') ? 650000 : 1000;
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = standardPBId,
                Product2Id = p.Id,
                UnitPrice = price,
                IsActive = true
            ));
        }
        insert standardEntries;

        // Create Dimagi PriceBook
        Pricebook2 dimagiPB = new Pricebook2(Name = 'Dimagi', IsActive = true);
        insert dimagiPB;

        // Dimagi PriceBookEntries
        List<PricebookEntry> dimagiEntries = new List<PricebookEntry>();
        for (Product2 p : products) {
            Decimal price = (p.ProductCode == 'CommCare') ? 650000 : 1000;
            dimagiEntries.add(new PricebookEntry(
                Pricebook2Id = dimagiPB.Id,
                Product2Id = p.Id,
                UnitPrice = price,
                IsActive = true
            ));
        }
        insert dimagiEntries;
    }

    @IsTest
    static void testSchedulerExecution() {

        // --- Add Products and PriceBooks ---
        addTestPricebooks();

        // --- Create Business Unit ---
        Business_Unit__c bu = new Business_Unit__c(Name = 'Default BU');
        insert bu;

        // --- Create Users ---
        Profile prof = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User implEnterprise = new User(
            FirstName='Impl', LastName='Enterprise', Alias='ieuser',
            Email='impl.enterprise@test.com',
            Username='impl.enterprise'+DateTime.now().getTime()+'@test.com',
            ProfileId=prof.Id, EmailEncodingKey='UTF-8', TimeZoneSidKey='GMT',
            LocaleSidKey='en_US', LanguageLocaleKey='en_US'
        );
        insert implEnterprise;

        User implNonEnterprise = new User(
            FirstName='Impl', LastName='NonEnterprise', Alias='ineuser',
            Email='impl.nonenterprise@test.com',
            Username='impl.nonenterprise'+DateTime.now().getTime()+'@test.com',
            ProfileId=prof.Id, EmailEncodingKey='UTF-8', TimeZoneSidKey='GMT',
            LocaleSidKey='en_US', LanguageLocaleKey='en_US'
        );
        insert implNonEnterprise;

        User prodEnterprise = new User(
            FirstName='Prod', LastName='Enterprise', Alias='peuser',
            Email='prod.enterprise@test.com',
            Username='prod.enterprise'+DateTime.now().getTime()+'@test.com',
            ProfileId=prof.Id, EmailEncodingKey='UTF-8', TimeZoneSidKey='GMT',
            LocaleSidKey='en_US', LanguageLocaleKey='en_US'
        );
        insert prodEnterprise;

        User prodNonEnterprise = new User(
            FirstName='Prod', LastName='NonEnterprise', Alias='pneuser',
            Email='prod.nonenterprise@test.com',
            Username='prod.nonenterprise'+DateTime.now().getTime()+'@test.com',
            ProfileId=prof.Id, EmailEncodingKey='UTF-8', TimeZoneSidKey='GMT',
            LocaleSidKey='en_US', LanguageLocaleKey='en_US'
        );
        insert prodNonEnterprise;

        // --- Create Subscription Renewal Settings ---
        Subscription_Renewal_Settings__c settings = new Subscription_Renewal_Settings__c(
            Default_Business_Unit__c = 'Default BU',
            Implementation_Enterprise_Owner__c = implEnterprise.FirstName + ' ' + implEnterprise.LastName,
            Implementation_non_Enterprise_Owner__c = implNonEnterprise.FirstName + ' ' + implNonEnterprise.LastName,
            Product_Enterprise_Owner__c = prodEnterprise.FirstName + ' ' + prodEnterprise.LastName,
            Product_non_Enterprise_Owner__c = prodNonEnterprise.FirstName + ' ' + prodNonEnterprise.LastName,
            Error_Emails__c = 'test@example.com'
        );
        insert settings;

        // --- Start Test Context ---
        Test.startTest();

        // Schedule the RenewalSubscriptionsScheduler
        String cronExp = '0 ' + (Datetime.now().minute() + 1) + ' ' + Datetime.now().hour() + ' * * ?';
        System.schedule('Test Renewal Subscriptions Scheduler', cronExp, new RenewalSubscriptionsScheduler());

        Test.stopTest();

        // --- Assert Scheduled Job Exists ---
        List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name, State 
                                  FROM CronTrigger 
                                  WHERE CronJobDetail.Name='Test Renewal Subscriptions Scheduler'];
        System.assertEquals(1, jobs.size(), 'Scheduled job should exist');
        System.assertEquals('WAITING', jobs[0].State, 'Scheduled job should be WAITING');
    }
}