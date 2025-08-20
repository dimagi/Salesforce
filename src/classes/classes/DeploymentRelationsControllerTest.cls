@isTest
public class DeploymentRelationsControllerTest {

    @testSetup
    public static void setUp() {
        Account account = new Account(Name = 'Test');
        insert account;

        DContract__c contract = new DContract__c(Name = 'Test', Account__c = account.Id, Implementing_Account__c = account.Id,
                                                 Area__c = 'Test Area', Sub_Area__c = 'Test Sub Area');
        insert contract;

        Product2 product = new Product2(Name = 'Test Product');
        insert product;

        Project__c deployment = new Project__c(Name = 'Test Deployment', Implementing_Account__c = account.Id);
        insert deployment;

        Country__c country = new Country__c(Name = 'Test Country');
        insert country; 

        Location__c location = new Location__c(Name = 'Test Location', Country__c = country.Id);
        insert location;
    }

    @isTest
    public static void testContractRelation() {
        DContract__c contract = [SELECT Id, Name FROM DContract__c WHERE Name = 'Test' LIMIT 1];
        Project__c deployment = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Deployment' LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.standardController(new Contract_Project__c());
        PageReference pageRef = Page.DeploymentContractPage;
        pageRef.getParameters().put('deploymentId', deployment.Id);
        Test.setCurrentPage(pageRef);

        System.assertEquals(0, [SELECT Id FROM Contract_Project__c].size());

        Test.startTest();
        DeploymentRelationsController ctrl = new DeploymentRelationsController(sc);
        PageReference backPage = ctrl.goBack();
        Contract_Project__c rec = (Contract_Project__c) ctrl.currentRecord;
        rec.Contract__c = contract.Id;
        PageReference savePage = ctrl.saveNewRelation();
        Test.stopTest();

        System.assertNotEquals(null, backPage);
        System.assertNotEquals(null, savePage);

        System.assertEquals(1, [SELECT Id FROM Contract_Project__c].size());
        Contract_Project__c testRecord = [SELECT Id, Contract__c, Project__c FROM Contract_Project__c LIMIT 1];
        System.assertEquals(deployment.Id, testRecord.Project__c);
        System.assertEquals(contract.Id, testRecord.Contract__c);
    }

    @isTest
    public static void testLocarionRelation() {
        Location__c location = [SELECT Id, Name FROM Location__c WHERE Name = 'Test Location' LIMIT 1];
        Project__c deployment = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Deployment' LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.standardController(new Project_Location__c());
        PageReference pageRef = Page.DeploymentLocationPage;
        pageRef.getParameters().put('deploymentId', deployment.Id);
        Test.setCurrentPage(pageRef);

        System.assertEquals(0, [SELECT Id FROM Project_Location__c].size());

        Test.startTest();
        DeploymentRelationsController ctrl = new DeploymentRelationsController(sc);
        PageReference backPage = ctrl.goBack();
        Project_Location__c rec = (Project_Location__c) ctrl.currentRecord;
        rec.Location__c = location.Id;
        PageReference savePage = ctrl.saveNewRelation();
        Test.stopTest();

        System.assertNotEquals(null, backPage);
        System.assertNotEquals(null, savePage);

        System.assertEquals(1, [SELECT Id FROM Project_Location__c].size());
        Project_Location__c testRecord = [SELECT Id, Location__c, Project__c FROM Project_Location__c LIMIT 1];
        System.assertEquals(deployment.Id, testRecord.Project__c);
        System.assertEquals(location.Id, testRecord.Location__c);
    }

    @isTest
    public static void testProductRelation() {
        Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Project__c deployment = [SELECT Id, Name FROM Project__c WHERE Name = 'Test Deployment' LIMIT 1];

        ApexPages.StandardController sc = new ApexPages.standardController(new Project_Product__c());
        PageReference pageRef = Page.DeploymentProductPage;
        pageRef.getParameters().put('deploymentId', deployment.Id);
        Test.setCurrentPage(pageRef);

        System.assertEquals(0, [SELECT Id FROM Project_Product__c].size());

        Test.startTest();
        DeploymentRelationsController ctrl = new DeploymentRelationsController(sc);
        PageReference backPage = ctrl.goBack();
        Project_Product__c rec = (Project_Product__c) ctrl.currentRecord;
        rec.Product__c = product.Id;
        PageReference savePage = ctrl.saveNewRelation();
        Test.stopTest();

        System.assertNotEquals(null, backPage);
        System.assertNotEquals(null, savePage);

        System.assertEquals(1, [SELECT Id FROM Project_Product__c].size());
        Project_Product__c testRecord = [SELECT Id, Product__c, Project__c FROM Project_Product__c LIMIT 1];
        System.assertEquals(deployment.Id, testRecord.Project__c);
        System.assertEquals(product.Id, testRecord.Product__c);
    }
}