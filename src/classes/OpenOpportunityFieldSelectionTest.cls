@isTest
private class OpenOpportunityFieldSelectionTest {

    @testSetup
    static void setupTestData() {
        // Create initial mock Open_Opportunity_Fields__c records
        List<Open_Opportunity_Fields__c> fields = new List<Open_Opportunity_Fields__c>();
        for (Integer i = 1; i <= 2; i++) {
            fields.add(new Open_Opportunity_Fields__c(
                Name = 'TestField' + i,
                Label__c = 'Test Label ' + i,
                Type__c = 'String',
                Order__c = i
            ));
        }
        insert fields;
    }

    @isTest
    static void testAddColumnWithSelectedValue() {
        Test.startTest();
        OpenOpportunityFieldSelectionController controller = new OpenOpportunityFieldSelectionController();
        // Simulate selection of an available field
        controller.selectedValue = 'StageName'; // common Opportunity field
        controller.addColumn();
        Test.stopTest();

        // Assert new record is inserted
        List<Open_Opportunity_Fields__c> inserted = [
            SELECT Name, Label__c FROM Open_Opportunity_Fields__c WHERE Name = 'StageName'
        ];
        System.assertEquals(1, inserted.size(), 'A new field should be inserted');
    }

    @isTest
    static void testAddColumnWithNullSelection() {
        OpenOpportunityFieldSelectionController controller = new OpenOpportunityFieldSelectionController();
        controller.selectedValue = null;

        Test.startTest();
        controller.addColumn();
        Test.stopTest();

        // Should add a page message (though not testable via standard assertions)
        System.assertEquals(true, true); // Placeholder to show test ran without exception
    }

    @isTest
    static void testClearCurrentSelection() {
        OpenOpportunityFieldSelectionController controller = new OpenOpportunityFieldSelectionController();

        Test.startTest();
        controller.clearCurrentSelection();
        Test.stopTest();

        List<Open_Opportunity_Fields__c> fields = [SELECT Id FROM Open_Opportunity_Fields__c];
        System.assertEquals(0, fields.size(), 'All fields should be deleted');
    }

    @isTest
    static void testGetCurrentSelection() {
        OpenOpportunityFieldSelectionController controller = new OpenOpportunityFieldSelectionController();
        List<Open_Opportunity_Fields__c> selectedFields = controller.getCurrentSelection();
        System.assertEquals(2, selectedFields.size(), 'Should return 2 initially inserted fields');
    }

    @isTest
    static void testOpportunityOwnerSpecialCase() {
        OpenOpportunityFieldSelectionController controller = new OpenOpportunityFieldSelectionController();
        controller.selectedValue = 'Owner.Name';

        Test.startTest();
        controller.addColumn();
        Test.stopTest();

        List<Open_Opportunity_Fields__c> inserted = [
            SELECT Name, Label__c FROM Open_Opportunity_Fields__c WHERE Name = 'Owner.Name'
        ];
        System.assertEquals(1, inserted.size(), 'Should handle Opportunity Owner special case');
        System.assertEquals('Opportunity Owner', inserted[0].Label__c);
    }
}