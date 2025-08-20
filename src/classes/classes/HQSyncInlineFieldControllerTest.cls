@isTest
public class HQSyncInlineFieldControllerTest {

    @isTest
    static void testControllerInitialization() {
        Internal_Properties__c internalProps = new Internal_Properties__c(
            notes__c = 'Test notes'
        );
        insert internalProps;

        Domain__c testDomain = new Domain__c(
            Name = 'Test Domain',
            Deployment_Countries__c = 'IN, US',
            Deployment_description__c = 'Test Description',
            Internal_Properties__c = internalProps.Id
        );
        insert testDomain;

        ApexPages.StandardController stdController = new ApexPages.StandardController(testDomain);

        Test.startTest();
        HQSyncInlineFieldController controller = new HQSyncInlineFieldController(stdController);
        Test.stopTest();

        System.assertNotEquals(null, controller.domain);
        System.assertEquals(testDomain.Id, controller.domain.Id);
        System.assertEquals('IN, US', controller.domain.Deployment_Countries__c);
        System.assertEquals('Test Description', controller.domain.Deployment_description__c);
        System.assertNotEquals(null, controller.domain.Internal_Properties__r);
        System.assertEquals('Test notes', controller.domain.Internal_Properties__r.notes__c);
    }
}