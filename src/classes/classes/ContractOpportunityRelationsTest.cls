@isTest
public class ContractOpportunityRelationsTest {

    @testSetup
    public static void setUp() {
        Account account = new Account(Name = 'Test');
        insert account;
        contact cntName = new contact(FirstName='singh', LastName = 'Singh', email='abcd@dimagi.com');
        insert cntName;
        
        contact cntName2 = new contact(FirstName='singh', LastName = 'Bharat', email='abcdf@dimagi.com');
        insert cntName2;
        
        DContract__c contract = new DContract__c(Name = 'Test', Account__c = account.Id, Implementing_Account__c = account.Id,
                                                 Area__c = 'Test Area', Sub_Area__c = 'Test Sub Area', Project_Manager__c = cntName2.id, 
                                                 Backstop__c = cntName2.id, Field_Manager__c = cntName2.id );
        insert contract;

        Product2 product = new Product2(Name = 'Test Product');
        insert product;

        Opportunity opportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Stage 2 - Talking', AccountId = account.Id, CloseDate = Date.today().addMonths(6), 
                                                    Opportunity_Owner_Division__c = 'Solutions',Opportunity_Owner_Sub_Division__c='USH - Delivery'); //, Opportunity_Owner_Sub_Division__c='USH - Delivery'
        insert opportunity;
        Business_Unit__c bu = new Business_Unit__c(Name = 'Inc');
        insert bu;
        
        SFDC_Employee__c employee = new SFDC_Employee__c(Exchange_Rate__c = 1 , Business_Unit__c = bu.id, Employee_Status__c = 'Active', Email_Address__c = 'abcd@dimagi.com', Name = 'Singh',Title__c = 'Country Director');
        Insert employee;
        PRO_Email_Remindar_Settings__c resettings= new PRO_Email_Remindar_Settings__c (Name = 'test', Dev_Work_Emails__c = 'abcd@dimagi.com');
        insert resettings;
        Contract_Contact__c cont =  new Contract_Contact__c(Contract__c = contract.id, contact__C = cntName.id );
        insert cont;
        
    }
    
    @isTest
     public static void testContractTrigger() {
        Business_Unit__c bu = [select id, name from Business_Unit__c where name =: 'Inc' LIMIT 1];
        SFDC_Employee__c emp = [SELECT Id, Email_Address__c, Business_Unit__c, Contact__c FROM SFDC_Employee__c 
                                      where Name =: 'Singh' LIMIT 1];
          contact cntNames =  [select id, firstname, email from contact where firstName = 'singh' LIMIT 1];
          DContract__c contract = [SELECT Id, Name FROM DContract__c WHERE Name = 'Test' LIMIT 1];
          contract.Project_Manager__c = cntNames.id;
          contract.Requires_Developer_Work__c = true;
          update contract;
         
         
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