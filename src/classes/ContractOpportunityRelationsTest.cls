@isTest
public class ContractOpportunityRelationsTest {

    @testSetup
    public static void setUp() {
        Account account = new Account(Name = 'Test');
        insert account;

        DContract__c contract = new DContract__c(Name = 'Test', Account__c = account.Id, Implementing_Account__c = account.Id,
                                                 Area__c = 'Test Area', Sub_Area__c = 'Test Sub Area');
        insert contract;

        Product2 product = new Product2(Name = 'Test Product');
        insert product;

        Opportunity opportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Stage 2 - Talking', AccountId = account.Id, CloseDate = Date.today().addMonths(6));
        insert opportunity;
    }

    @isTest
    public static void testOpportunityContractRelation() {
        Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        DContract__c contract = [SELECT Id, Name FROM DContract__c WHERE Name = 'Test' LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.standardController(new Contract_Opportunity__c());
        PageReference pageRef = Page.ContractOpportunityPage;
        pageRef.getParameters().put('opportunityId', opportunity.Id);
        Test.setCurrentPage(pageRef);

        System.assertEquals(0, [SELECT Id FROM Contract_Opportunity__c].size());

        Test.startTest();
        ContractOpportunityController ctrl = new ContractOpportunityController(sc);
        PageReference backPage = ctrl.goBack();
        Contract_Opportunity__c rec = ctrl.coRelation;
        rec.Contract__c = contract.Id;
        PageReference savePage = ctrl.saveNewRelation();
        Test.stopTest();

        System.assertNotEquals(null, backPage);
        System.assertNotEquals(null, savePage);

        System.assertEquals(1, [SELECT Id FROM Contract_Opportunity__c].size());
        Contract_Opportunity__c testRecord = [SELECT Id, Opportunity__c, Contract__c FROM Contract_Opportunity__c LIMIT 1];
        System.assertEquals(opportunity.Id, testRecord.Opportunity__c);
        System.assertEquals(contract.Id, testRecord.Contract__c);
    }

    @isTest
    public static void testContractOpportunityRelation() {
        Opportunity opportunity = [SELECT Id, Name FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        DContract__c contract = [SELECT Id, Name FROM DContract__c WHERE Name = 'Test' LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.standardController(new Contract_Opportunity__c());
        PageReference pageRef = Page.ContractOpportunityPage;
        pageRef.getParameters().put('contractId', contract.Id);
        Test.setCurrentPage(pageRef);

        System.assertEquals(0, [SELECT Id FROM Contract_Opportunity__c].size());

        Test.startTest();
        ContractOpportunityController ctrl = new ContractOpportunityController(sc);
        PageReference backPage = ctrl.goBack();
        Contract_Opportunity__c rec = ctrl.coRelation;
        rec.Opportunity__c = opportunity.Id;
        PageReference savePage = ctrl.saveNewRelation();
        Test.stopTest();

        System.assertNotEquals(null, backPage);
        System.assertNotEquals(null, savePage);

        System.assertEquals(1, [SELECT Id FROM Contract_Opportunity__c].size());
        Contract_Opportunity__c testRecord = [SELECT Id, Opportunity__c, Contract__c FROM Contract_Opportunity__c LIMIT 1];
        System.assertEquals(opportunity.Id, testRecord.Opportunity__c);
        System.assertEquals(contract.Id, testRecord.Contract__c);
    }

    @isTest
    public static void testContractProductRelation() {
        DContract__c contract = [SELECT Id, Name FROM DContract__c WHERE Name = 'Test' LIMIT 1];
        Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = 'Test Product' LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.standardController(new Contract_Product__c());
        PageReference pageRef = Page.ContractProductPage;
        pageRef.getParameters().put('contractId', contract.Id);
        Test.setCurrentPage(pageRef);

        System.assertEquals(0, [SELECT Id FROM Contract_Product__c].size());

        Test.startTest();
        ContractProductController ctrl = new ContractProductController(sc);
        PageReference backPage = ctrl.goBack();
        Contract_Product__c rec = ctrl.currentRecord;
        rec.Product__c = product.Id;
        PageReference savePage = ctrl.saveNewRelation();
        Test.stopTest();

        System.assertNotEquals(null, backPage);
        System.assertNotEquals(null, savePage);

        System.assertEquals(1, [SELECT Id FROM Contract_Product__c].size());
        Contract_Product__c testRecord = [SELECT Id, Contract__c, Product__c FROM Contract_Product__c LIMIT 1];
        System.assertEquals(product.Id, testRecord.Product__c);
        System.assertEquals(contract.Id, testRecord.Contract__c);
    }
}