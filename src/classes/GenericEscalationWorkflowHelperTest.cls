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

    @isTest
    public static void shouldFilter() {
        // First Reminder Test without filters
        Date referenceDate = Date.newInstance(2016, 6, 12);
        Generic_Escalation_Workflow__c testWorkflow = new Generic_Escalation_Workflow__c(Last_Report_Date_Field__c = 'Snooze_Date__c', First_Reminder_Date_Field__c = 'Third_Nag_Sent_Date__c',
                                                                                         From_Day_of_Week__c = 'Friday', From_Numeral__c = 'First',
                                                                                         To_Day_of_Week__c = 'Friday', To_Numeral__c = 'Second');
        Generic_Reminder__c reminder = new Generic_Reminder__c(Reminder_Index__c = 1, Days__c = 2);

        sObject dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = null, Snooze_Date__c = Date.newInstance(2016, 6, 1));
        Boolean result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, new List<Generic_Reminder_Filter__c>());
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = Date.newInstance(2016, 6, 9), Snooze_Date__c = Date.newInstance(2016, 6, 1));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, new List<Generic_Reminder_Filter__c>());
        System.assertEquals(false, result);

        referenceDate = Date.newInstance(2016, 6, 11);
        dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = null, Snooze_Date__c = Date.newInstance(2016, 6, 1));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, new List<Generic_Reminder_Filter__c>());
        System.assertEquals(false, result);

        // Second Reminder Test
        referenceDate = Date.newInstance(2016, 6, 11);
        testWorkflow = new Generic_Escalation_Workflow__c(Last_Report_Date_Field__c = 'Snooze_Date__c', First_Reminder_Date_Field__c = 'Third_Nag_Sent_Date__c');
        reminder = new Generic_Reminder__c(Reminder_Index__c = 2, Days__c = 2);

        dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = null, Snooze_Date__c = Date.newInstance(2016, 6, 1));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, new List<Generic_Reminder_Filter__c>());
        System.assertEquals(false, result);

        dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = Date.newInstance(2016, 6, 9), Snooze_Date__c = Date.newInstance(2016, 6, 1));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, new List<Generic_Reminder_Filter__c>());
        System.assertEquals(true, result);

        referenceDate = Date.newInstance(2016, 6, 13);
        dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = null, Snooze_Date__c = Date.newInstance(2016, 6, 1));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, new List<Generic_Reminder_Filter__c>());
        System.assertEquals(false, result);
    }

    @isTest
    public static void shouldFilterByStringType() {
        Date referenceDate = Date.newInstance(2016, 6, 12);
        Generic_Escalation_Workflow__c testWorkflow = new Generic_Escalation_Workflow__c(Last_Report_Date_Field__c = 'Snooze_Date__c', First_Reminder_Date_Field__c = 'Third_Nag_Sent_Date__c',
                                                                                         From_Day_of_Week__c = 'Friday', From_Numeral__c = 'First',
                                                                                         To_Day_of_Week__c = 'Friday', To_Numeral__c = 'Second');
        Generic_Reminder__c reminder = new Generic_Reminder__c(Reminder_Index__c = 1, Days__c = 2);

        sObject dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = null, Snooze_Date__c = Date.newInstance(2016, 6, 1), Country_Text__c = 'USA');
        List<Generic_Reminder_Filter__c> filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c( Field_Name__c = 'Country_Text__c', Operator__c = '=', Value__c = 'USA'));
        Boolean result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = null, Snooze_Date__c = Date.newInstance(2016, 6, 1), Country_Text__c = 'USA');
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c( Field_Name__c = 'Country_Text__c', Operator__c = '!=', Value__c = 'USA'));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, filters);
        System.assertEquals(false, result);

        dimagiContract = (sObject) new DContract__c(Third_Nag_Sent_Date__c = null, Snooze_Date__c = Date.newInstance(2016, 6, 1), Country_Text__c = 'USA');
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c( Field_Name__c = 'Country_Text__c', Operator__c = '!=', Value__c = 'England'));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, testWorkflow, reminder, referenceDate, filters);
        System.assertEquals(true, result);
    }

}