/**
 * Helper class for filtering sObjects for Generic Escalation Workflow. It also sends workflow emails.
 */
public class GenericEscalationWorkflowHelper {

    public static List<sObject> filterObjects(List<sObject> sourceList, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder, Date referenceDate) {
        List<sObject> filteredList = new List<sObject>();

        for (sObject record : sourceList) {
            if (checkFilters(record, genericTrigger, genericReminder, referenceDate, genericReminder.Generic_Reminder_Filters__r)) {
                filteredList.add(record);
            }
        }

        return filteredList;
    }

    public static Date getLastDueDate(Generic_Escalation_Workflow__c genericTrigger, Date referenceDate) {
        Date fromDate = getProperDate(genericTrigger.From_Day_of_Week__c, genericTrigger.From_Numeral__c, referenceDate);
        Date toDate = getProperDate(genericTrigger.To_Day_of_Week__c, genericTrigger.To_Numeral__c, referenceDate);

        if (referenceDate < fromDate) {
            Date previousMonthDate = referenceDate.addMonths(-1);
            return getProperDate(genericTrigger.To_Day_of_Week__c, genericTrigger.To_Numeral__c, previousMonthDate);
        } else {
            if(referenceDate < toDate) {
                return fromDate;
            }
            else {
                return toDate;
            }
        }
    }

    public static Boolean checkFilters(sObject record, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder, Date referenceDate, List<Generic_Reminder_Filter__c> filters) {
        if (genericReminder.Reminder_Index__c == 1) {
            return processFirstRemainders(record, genericTrigger, genericReminder, referenceDate, filters);
        } else {
            return processOtherRemainder(record, genericTrigger, genericReminder, referenceDate, filters);
        }
    }

    private static Boolean processFirstRemainders(sObject record, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder, Date referenceDate, List<Generic_Reminder_Filter__c> filters) {
        System.debug('Processing first reminder');
        Object dateVal = record.get(genericTrigger.Last_Report_Date_Field__c);
        Date lastReportDate = null;

        if (dateVal != null) {
            lastReportDate = (Date) dateVal;
        }

        Object dateValSent = record.get(genericTrigger.First_Reminder_Date_Field__c);
        Date firstSentDate = null;

        if (dateValSent != null) {
            firstSentDate = (Date) dateValSent;
        }

        Date latestDueDate = getLastDueDate(genericTrigger, referenceDate);
        Date lastAllowedDate = latestDueDate.addDays(Integer.valueOf(genericReminder.Days__c));
		System.debug('latestDueDate ' + latestDueDate);
        System.debug('lastAllowedDate ' + lastAllowedDate);
        System.debug('firstSentDate ' + firstSentDate);
        System.debug('referenceDate ' + referenceDate);
        System.debug('lastReportDate ' + lastReportDate);
        System.debug('CreatedDate' + (DateTime) record.get('CreatedDate'));
        if (firstSentDate == null && referenceDate >= lastAllowedDate &&
            ((lastReportDate != null && lastReportDate < latestDueDate) || (lastReportDate == null))) {//} && ((DateTime) record.get('CreatedDate')) < latestDueDate))) {
            for (Generic_Reminder_Filter__c filter : filters) {
                if (!invokeStringFilter(record, filter)) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    private static Boolean processOtherRemainder(sObject record, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder, Date referenceDate, List<Generic_Reminder_Filter__c> filters) {
        System.debug('Processing other reminder');
        Object dateVal = record.get(genericTrigger.First_Reminder_Date_Field__c);
        Date firstSentDate = null;

        if (dateVal != null) {
            firstSentDate = (Date) dateVal;
        }

        if (firstSentDate != null && firstSentDate.addDays(Integer.valueOf(genericReminder.Days__c)) == referenceDate) {
            for (Generic_Reminder_Filter__c filter : filters) {
                if (!invokeStringFilter(record, filter)) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    private static Boolean invokeStringFilter(sObject record, Generic_Reminder_Filter__c filter) {
        if (filter.Operator__c == '=') {
            if (filter.Value__c == (String) record.get(filter.Field_Name__c)) {
                System.debug('Fileter true');
                return true;
            }
        } else if (filter.Operator__c == '!=') {
            if (filter.Value__c != (String) record.get(filter.Field_Name__c)) {
                System.debug('Fileter true');
                return true;
            }
        }
        System.debug('Fileter false');
        return false;
    }

    private static Date getProperDate(String dayOfWeek, String num, Date referenceDate) {
        Integer month = referenceDate.month();
        Integer year = referenceDate.year();

        Date monthStartDate = date.newInstance(year, month, 1);
        Date resultDate = null;

        // Find first day
        for (Integer i = 0; i < 7; i++) {
            if (dayOfWeek.startsWith(DateTime.newInstance(monthStartDate.addDays(i), Time.newInstance(0, 0, 0, 0)).format('E'))) {
                resultDate = Date.newInstance(year, month, monthStartDate.addDays(i).day());
                break;
            }
        }

        if (num == 'First') {
            return resultDate;
        } else if (num == 'Second') {
            return resultDate.addDays(7);
        } else if (num == 'Third') {
            return resultDate.addDays(14);
        } else {
            return resultDate.addDays(21);
        }
    }

}