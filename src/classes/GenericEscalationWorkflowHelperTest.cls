@isTest
public class GenericEscalationWorkflowHelperTest {

    @isTest
    public static void shouldReturnProperDueDates() {
        Date referenceDate1 = Date.newInstance(2016, 6, 17);
        Date dueDate = GenericEscalationWorkflowHelper.getLastDueDate(
            new Generic_Escalation_Workflow__c(From_Day_of_Week__c = 'Friday', From_Numeral__c = 'First',
            To_Day_of_Week__c = 'Friday', To_Numeral__c = 'Second'),
            referenceDate1);
        System.assertEquals(Date.newInstance(2016, 6, 10), dueDate);

        Date referenceDate2 = Date.newInstance(2016, 6, 9);
        dueDate = GenericEscalationWorkflowHelper.getLastDueDate(
            new Generic_Escalation_Workflow__c(From_Day_of_Week__c = 'Friday', From_Numeral__c = 'First',
            To_Day_of_Week__c = 'Friday', To_Numeral__c = 'Second'),
            referenceDate2);
        System.assertEquals(Date.newInstance(2016, 6, 3), dueDate);

        Date referenceDate3 = Date.newInstance(2016, 6, 9);
        dueDate = GenericEscalationWorkflowHelper.getLastDueDate(
            new Generic_Escalation_Workflow__c(From_Day_of_Week__c = 'Friday', From_Numeral__c = 'Second',
            To_Day_of_Week__c = 'Friday', To_Numeral__c = 'Third'),
            referenceDate3);
        System.assertEquals(Date.newInstance(2016, 5, 20), dueDate);
    }
}