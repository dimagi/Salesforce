@isTest
public class CalculateAllTimeTest {
    
    @TestSetup
    static void makeData(){
        BatchDefaultSettings__c batchSettings = BatchDefaultSettings__c.getOrgDefaults();
        batchSettings.Error_Emails__c = 'extra_test_1@test_test_test.test,extra_test_2@test_test_test.test';
        insert batchSettings;
        List<DContract__c> addContractList = new List<DContract__c>();
        for(Integer i = 1; i <= 3; i++){
            DContract__c contractObj = new DContract__c();
            contractObj.Name = 'Contract '+i;
            contractObj.ALL_TIME_Income__c = 500;
            addContractList.add(contractObj);
        }
        insert addContractList;
        DContract__c contract1 = [SELECT Id ,Interdivision_Child_Contract_1__c,Interdivision_Child_Contract_2__c FROM DContract__c WHERE name LIKE 'Contract 1'];
        contract1.Interdivision_Child_Contract_1__c =[SELECT Id from DContract__c WHERE name LIKE 'Contract 2'].Id;
        contract1.Interdivision_Child_Contract_2__c =[SELECT Id from DContract__c WHERE name LIKE 'Contract 3'].Id;
        update contract1;
        DContract__c noChildContract = new DContract__c(Name = 'Contract 4');
        insert noChildContract;
        DContract__c child1Contract = new DContract__c(Name = 'Contract 5', Interdivision_Child_Contract_1__c = [SELECT Id from DContract__c WHERE name LIKE 'Contract 2'].Id, ID_Support_Services_Contract__c = true );
        insert child1Contract;
        DContract__c child2Contract = new DContract__c(Name = 'Contract 6', Interdivision_Child_Contract_2__c = [SELECT Id from DContract__c WHERE name LIKE 'Contract 3'].Id ,ID_Support_Services_Contract__c = true);
        insert child2Contract;
        
    }
    @isTest
    public static void forSingleRecord(){
        Id parentContract = [SELECT Id from DContract__c where name = 'Contract 1' LIMIT 1].Id;
        System.debug('Id:'+parentContract);
        Test.startTest();
        Database.executeBatch(new CalculateAllTimeIncomeBatch(parentContract));
        Test.stopTest();
        List<DContract__c> parent = [SELECT Id , ID_Subcontract_Spend__c,ID_Subcontract_2_Spend__c FROM DContract__c WHERE Id=:parentContract];
        System.assertEquals(500, parent[0].ID_Subcontract_2_Spend__c);
    }
    @isTest
    public static void forAllContracts(){
        Test.startTest();
        Database.executeBatch(new CalculateAllTimeIncomeBatch());
        Test.stopTest();
        List<DContract__c> parent = [SELECT Id , ID_Subcontract_Spend__c,ID_Subcontract_2_Spend__c FROM DContract__c];
        System.assertEquals(500, parent[0].ID_Subcontract_2_Spend__c);
    }
    @isTest
    public static void bothNullChild(){
        Id parentContract = [SELECT Id from DContract__c where name = 'Contract 4' LIMIT 1].Id;
        System.debug('Id:'+parentContract);
        Test.startTest();
        Database.executeBatch(new CalculateAllTimeIncomeBatch(parentContract));
        Test.stopTest();
        List<DContract__c> parent = [SELECT Id , ID_Subcontract_Spend__c,ID_Subcontract_2_Spend__c FROM DContract__c WHERE Id=:parentContract];
        System.assertEquals(0, parent[0].ID_Subcontract_2_Spend__c);
    }
    @isTest
    public static void child1Null(){
        Id parentContract = [SELECT Id from DContract__c where name = 'Contract 5' LIMIT 1].Id;
        System.debug('Id:'+parentContract);
        Test.startTest();
        Database.executeBatch(new CalculateAllTimeIncomeBatch(parentContract));
        Test.stopTest();
        List<DContract__c> parent = [SELECT Id , ID_Subcontract_Spend__c,ID_Subcontract_2_Spend__c FROM DContract__c WHERE Id=:parentContract];
        System.assertEquals(0, parent[0].ID_Subcontract_2_Spend__c);
    }
    @isTest
    public static void child2Null(){
        Id parentContract = [SELECT Id from DContract__c where name = 'Contract 6' LIMIT 1].Id;
        System.debug('Id:'+parentContract);
        Test.startTest();
        Database.executeBatch(new CalculateAllTimeIncomeBatch(parentContract));
        Test.stopTest();
        List<DContract__c> parent = [SELECT Id , ID_Subcontract_Spend__c,ID_Subcontract_2_Spend__c FROM DContract__c WHERE Id=:parentContract];
        System.assertEquals(500, parent[0].ID_Subcontract_2_Spend__c);
    }
    @isTest
    public static void CalculateAllTimeController(){
        //visual force page controller
        DContract__c parentContract = [SELECT Id from DContract__c where name = 'Contract 1' LIMIT 1];
        PageReference pageRef = Page.CalculateAllTime;
        Test.setCurrentPage(pageRef);
        Test.startTest();
        pageRef.getParameters().put('Id', String.valueOf(parentContract.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(parentContract);
        CalculateAllTime calculateAllTimeCtrl =  new CalculateAllTime(sc);
        calculateAllTimeCtrl.runRecalculation();
        System.assert(ApexPages.hasMessages(ApexPages.SEVERITY.CONFIRM));
        Test.stopTest();
        
    }
    @isTest
    public static void testBackPage(){
        DContract__c parentContract = [SELECT Id from DContract__c where name = 'Contract 1' LIMIT 1];
        PageReference pageRef = Page.CalculateAllTime;
        Test.setCurrentPage(pageRef);
        Test.startTest();
        pageRef.getParameters().put('Id', String.valueOf(parentContract.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(parentContract);
        CalculateAllTime calculateAllTimeCtrl =  new CalculateAllTime(sc);
        calculateAllTimeCtrl.goBack();
        Test.stopTest();
        
        System.assertEquals(false, pageRef.getRedirect());
    }
    @isTest
    public static void forOneRecord(){
        Id parentContract = [SELECT Id from DContract__c where name = 'Contract 5' LIMIT 1].Id;
        System.debug('Id:'+parentContract);
        Test.startTest();
        Database.executeBatch(new UpdateTotalAmountRemainingBatch(parentContract));
        Test.stopTest();
        List<DContract__c> parent = [SELECT Id , ID_Sub_contract_Total_Amount_Remaining__c,Total_Amount_REMAINING__c FROM DContract__c WHERE Id=:parentContract];
        System.assertEquals(parent[0].ID_Sub_contract_Total_Amount_Remaining__c, parent[0].Total_Amount_REMAINING__c);
    }
    @isTest
    public static void forContracts(){
        Test.startTest();
        Database.executeBatch(new UpdateTotalAmountRemainingBatch());
        Test.stopTest();
        List<DContract__c> parent = [SELECT Id , ID_Sub_contract_Total_Amount_Remaining__c,Total_Amount_REMAINING__c FROM DContract__c WHERE ID_Support_Services_Contract__c = true];
        System.assertEquals(parent[0].ID_Sub_contract_Total_Amount_Remaining__c, parent[0].Total_Amount_REMAINING__c);
    }
    @isTest
    public static void testCalculateAllTimeScheduler(){
        Test.StartTest();
        CalculateAllTimeIncomeScheduler sh1 = new CalculateAllTimeIncomeScheduler();
        
        String sch = '0 0 23 * * ?'; 
        system.schedule('Calculate All Time Income', sch, sh1); 
        Test.stopTest(); 
    }
}