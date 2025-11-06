@isTest
public class DContractRecalculationControllerTest {

    @testSetup
    static void setupData() {
        insert new DContract__c(Name = 'Test Contract');
    }

    @isTest
    static void testRunRecalculation_WhenJobAlreadyRunning() {
        DContract__c contract = [SELECT Id FROM DContract__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(contract);

        Test.startTest();
        Database.executeBatch(new TestBatch(), 1);
        DContractRecalculationController controller = new DContractRecalculationController(sc);
        controller.runRecalculation();
        Test.stopTest();

      

        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size());
    }

    @isTest
    static void testRunRecalculation_WhenNoJobRunning() {
        DContract__c contract = [SELECT Id FROM DContract__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(contract);

        Test.startTest();
        DContractRecalculationController controller = new DContractRecalculationController(sc);
        controller.runRecalculation();
        Test.stopTest();

        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size());
        System.assertEquals(ApexPages.Severity.CONFIRM, messages[0].getSeverity());
        System.assert(messages[0].getSummary().contains('recalculation was scheduled'));
    }

    @isTest
    static void testGoBack() {
        DContract__c contract = [SELECT Id FROM DContract__c LIMIT 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(contract);
        DContractRecalculationController controller = new DContractRecalculationController(sc);
        System.assertNotEquals(null, controller.goBack());
    }
}