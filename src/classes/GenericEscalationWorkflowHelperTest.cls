@isTest
public class GenericEscalationWorkflowHelperTest {

    @isTest
    public static void shouldReturnProperDate() {
        Date referenceDate1 = Date.newInstance(2016, 6, 17);
        Date result = GenericEscalationWorkflowHelper.getProperDate('Monday', 'First', referenceDate1);
        System.assertEquals(Date.newInstance(2016, 6, 6), result);

        Date referenceDate2 = Date.newInstance(2016, 6, 9);
        result = GenericEscalationWorkflowHelper.getProperDate('Friday', 'Second', referenceDate2);
        System.assertEquals(Date.newInstance(2016, 6, 10), result);

        Date referenceDate3 = Date.newInstance(2016, 6, 11);
        result = GenericEscalationWorkflowHelper.getProperDate('Wednesday', 'Third', referenceDate3);
        System.assertEquals(Date.newInstance(2016, 6, 15), result);
    }

    @isTest
    public static void shouldProcessWeeklyReminderDate() {
        Generic_Reminder__c reminder = new Generic_Reminder__c(Frequency_type__c = 'Weekly', Week_days__c = 'Monday;Friday');
        Boolean result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 1));
        System.assertEquals(true, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 7));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 9));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 11));
        System.assertEquals(true, result);

        reminder = new Generic_Reminder__c(Frequency_type__c = 'Weekly', Week_days__c = 'Sunday;Thursday');
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 3));
        System.assertEquals(true, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 18));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 9));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 28));
        System.assertEquals(true, result);
    }

    @isTest
    public static void shouldProcessMonthlyReminderDate() {
        Generic_Reminder__c reminder = new Generic_Reminder__c(Frequency_type__c = 'Monthly', Monthly_type__c = 'On day', Day_of_the_month__c = '3');
        Boolean result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 3));
        System.assertEquals(true, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 6, 2));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 6, 3));
        System.assertEquals(true, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 11));
        System.assertEquals(false, result);

        reminder = new Generic_Reminder__c(Frequency_type__c = 'Monthly', Monthly_type__c = 'On day', Day_of_the_month__c = 'Last day');
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 3));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 31));
        System.assertEquals(true, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 6, 3));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 2, 29));
        System.assertEquals(true, result);

        reminder = new Generic_Reminder__c(Frequency_type__c = 'Monthly', Monthly_type__c = 'On', Day_of_the_week__c = 'Thursday', Numeral_monthly__c = 'Second');
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 13));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 14));
        System.assertEquals(true, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 6, 3));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 2, 29));
        System.assertEquals(false, result);

        reminder = new Generic_Reminder__c(Frequency_type__c = 'Monthly', Monthly_type__c = 'On', Day_of_the_week__c = 'Monday', Numeral_monthly__c = 'Third');
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 13));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 14));
        System.assertEquals(false, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 7, 18));
        System.assertEquals(true, result);
        result = GenericEscalationWorkflowHelper.checkReminderDate(reminder, Date.newInstance(2016, 8, 15));
        System.assertEquals(true, result);
    }


    @isTest
    public static void shouldFilterByStringType() {
        sObject dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 1), Country_Text__c = 'USA');
        List<Generic_Reminder_Filter__c> filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'STRING', Field_Name__c = 'Country_Text__c', Operator__c = '=', Value__c = 'USA'));
        Boolean result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 1), Country_Text__c = 'USA');
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'STRING', Field_Name__c = 'Country_Text__c', Operator__c = '!=', Value__c = 'USA'));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(false, result);
    }

    @isTest
    public static void shouldFilterByBooleanType() {
        sObject dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 1),  Exclude_from_Monthly_Upload__c = false);
        List<Generic_Reminder_Filter__c> filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'BOOLEAN', Field_Name__c = 'Exclude_from_Monthly_Upload__c', Operator__c = '=', Checkbox_Value__c = false));
        Boolean result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 1),  Exclude_from_Monthly_Upload__c = true);
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'BOOLEAN', Field_Name__c = 'Exclude_from_Monthly_Upload__c', Operator__c = '!=', Checkbox_Value__c = false));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 1),  Exclude_from_Monthly_Upload__c = true);
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'BOOLEAN', Field_Name__c = 'Exclude_from_Monthly_Upload__c', Operator__c = '=', Checkbox_Value__c = false));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(false, result);
    }

    @isTest
    public static void shouldFilterByDateType() {
        sObject dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 1), Country_Text__c = 'USA');
        List<Generic_Reminder_Filter__c> filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DATE', Field_Name__c = 'Snooze_Date__c', Operator__c = '=', Date_Value__c = Date.newInstance(2016, 6, 1)));
        Boolean result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 1), Country_Text__c = 'USA');
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DATE', Field_Name__c = 'Snooze_Date__c', Operator__c = '!=', Date_Value__c = Date.newInstance(2016, 6, 1)));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(false, result);

        dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 1), Country_Text__c = 'USA');
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DATE', Field_Name__c = 'Snooze_Date__c', Operator__c = '>', Date_Value__c = Date.newInstance(2016, 6, 1)));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(false, result);

        dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 6, 11), Country_Text__c = 'USA');
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DATE', Field_Name__c = 'Snooze_Date__c', Operator__c = '>=', Date_Value__c = Date.newInstance(2016, 6, 1)));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Snooze_Date__c = Date.newInstance(2016, 5, 1), Country_Text__c = 'USA');
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DATE', Field_Name__c = 'Snooze_Date__c', Operator__c = '<', Date_Value__c = Date.newInstance(2016, 6, 1)));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);
    }

    @isTest
    public static void shouldFilterByDoubleType() {
        sObject dimagiContract = (sObject) new DContract__c(Number_of_Users__c = 100);
        List<Generic_Reminder_Filter__c> filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DOUBLE', Field_Name__c = 'Number_of_Users__c', Operator__c = '=', Number_Value__c = 100));
        Boolean result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Number_of_Users__c = 3);
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DOUBLE', Field_Name__c = 'Number_of_Users__c', Operator__c = '!=', Number_Value__c = 4));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Number_of_Users__c = 10);
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DOUBLE', Field_Name__c = 'Number_of_Users__c', Operator__c = '>', Number_Value__c = 3));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(true, result);

        dimagiContract = (sObject) new DContract__c(Number_of_Users__c = 1);
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DOUBLE', Field_Name__c = 'Number_of_Users__c', Operator__c = '>=', Number_Value__c = 4));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(false, result);

        dimagiContract = (sObject) new DContract__c(Number_of_Users__c = 10);
        filters = new List<Generic_Reminder_Filter__c>();
        filters.add(new Generic_Reminder_Filter__c(Data_Type__c = 'DOUBLE', Field_Name__c = 'Number_of_Users__c', Operator__c = '<', Number_Value__c = 3));
        result = GenericEscalationWorkflowHelper.checkFilters(dimagiContract, filters);
        System.assertEquals(false, result);
    }
}