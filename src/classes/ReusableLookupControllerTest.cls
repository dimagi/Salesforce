@isTest
public class ReusableLookupControllerTest {

    private static SFDC_Employee__c createTestAccount(String name, integer accountNumber) {
        SFDC_Employee__c acc = new SFDC_Employee__c(
            Name = name,
            Exchange_Rate__c = accountNumber
        );
        insert acc;
        return acc;
    }

    @isTest
    static void testFetchRecords_WithSelectedRecordId() {
        SFDC_Employee__c acc = createTestAccount('Test Selected Account', 10);

        ReusableLookupController.SearchWrapper wrapper = new ReusableLookupController.SearchWrapper();
        wrapper.objectApiName = 'SFDC_Employee__c';
        wrapper.fieldApiName = 'Name';
        wrapper.otherFieldApiName = 'Division__c';
        wrapper.searchString = 'Test';
        wrapper.selectedRecordId = acc.Id;

        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(wrapper);

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals(acc.Name, result[0].mainField);
    }


    @isTest
    static void testFetchRecords_NoSelectedIdOrParent() {
        SFDC_Employee__c acc = createTestAccount('Regular Account', 123);

        ReusableLookupController.SearchWrapper wrapper = new ReusableLookupController.SearchWrapper();
        wrapper.objectApiName = 'SFDC_Employee__c';
        wrapper.fieldApiName = 'Name';
        wrapper.otherFieldApiName = 'Division__c'; 
        wrapper.searchString = 'Regular';

        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(wrapper);

        System.assertNotEquals(null, result);
        System.assertEquals(1, result.size());
        System.assertEquals(acc.Name, result[0].mainField);
    }


    @isTest
    static void testFetchRecords_EmptySearchString() {
        SFDC_Employee__c acc = createTestAccount('Empty Search Account', 456);

        ReusableLookupController.SearchWrapper wrapper = new ReusableLookupController.SearchWrapper();
        wrapper.objectApiName = 'SFDC_Employee__c';
        wrapper.fieldApiName = 'Name';
        wrapper.searchString = ''; 
        wrapper.otherFieldApiName = 'Division__c'; 

        List<ReusableLookupController.ResultWrapper> result = ReusableLookupController.fetchRecords(wrapper);

        System.assertEquals(false, result.isEmpty());
    }



}