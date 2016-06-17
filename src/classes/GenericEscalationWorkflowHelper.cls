/**
 * Helper class for filtering sObjects for Generic Escalation Workflow. It also sends workflow emails.
 */
public class GenericEscalationWorkflowHelper {

    public static List<sObject> filterObjects(List<sObject> sourceList, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder) {
        List<sObject> filteredList = new List<sObject>();

        DateTime lastDueDate = getLastDueDate(genericTrigger, Date.today());
        for (sObject record : sourceList) {
            if (checkFilter(record, genericTrigger, genericReminder)) {
                filteredList.add(record);
            }
        }

        return filteredList;
    }

    public static void processWorkflowEmails() {
        //TODO
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

    private static Boolean checkFilter(sObject record, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder) {
        Object dateVal = record.get(genericTrigger.Last_Report_Date_Field__c);
        DateTime lastReportDate = null;

        if (dateVal != null) {
            lastReportDate = (DateTime) dateVal;
        }

        if (genericReminder.Reminder_Index__c == 1) {
            return processFirstReminader();
        } else {
            return processOtherReminaders();
        }
    }

    private static Boolean processFirstReminader() {
        //TODO
        return true;
    }

    private static Boolean processOtherReminaders() {
        // TODO
        return true;
    }

}