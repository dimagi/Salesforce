/**
 * Helper class for filtering sObjects for Generic Escalation Workflow. It also sends workflow emails.
 */
public class GenericEscalationWorkflowHelper {

    public static List<sObject> filterObjects(List<sObject> sourceList, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder) {
        List<sObject> filteredList = new List<sObject>();

        DateTime lastDueDate = getLastDueDate(genericTrigger, Date.today());
        for (sObject record : sourceList) {
            if (checkFilter(record, genericTrigger, genericReminder, Date.today())) {
                filteredList.add(record);
            }
        }

        return filteredList;
    }

    public static List<Messaging.SingleEmailMessage> processWorkflowEmails(List<sObject> records, Generic_Reminder__c reminder, OrgWideEmailAddress orgWideAddress) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (sObject record : records) {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTemplateId(reminder.Email_Template__c);
            // TODO load contacts
            //msg.setTargetObjectId(contactList[0].Id);
            msg.setToAddresses(new String[] {'tstalka@soldevelo.com'});
            msg.setWhatId((Id) record.get('Id'));
            msg.setSaveAsActivity(false);
            msg.setOrgWideEmailAddressId(orgWideAddress.id);
            messages.add(msg);
        }

        return messages;
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

    public static Boolean checkFilter(sObject record, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder, Date referenceDate) {
        if (genericReminder.Reminder_Index__c == 1) {
            return processFirstReminader(record, genericTrigger, genericReminder, referenceDate);
        } else {
            return processOtherReminaders(record, genericTrigger, genericReminder, referenceDate);
        }
    }

    private static Boolean processFirstReminader(sObject record, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder, Date referenceDate) {
        Object dateVal = record.get(genericTrigger.Last_Report_Date_Field__c);
        Date lastReportDate = null;

        if (dateVal != null) {
            lastReportDate = (Date) dateVal;
        }

        Date latestDueDate = getLastDueDate(genericTrigger, referenceDate);
        Date lastAllowedDate = latestDueDate.addDays(Integer.valueOf(genericReminder.Days__c));

        if (referenceDate >= lastAllowedDate &&
            ((lastReportDate != null && lastReportDate < latestDueDate) || (lastReportDate == null && ((Date) record.get('CreatedDate')) < latestDueDate))
            ) {
            return true;
        }
        return false;
    }

    private static Boolean processOtherReminaders(sObject record, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder, Date referenceDate) {
        Object dateVal = record.get(genericTrigger.First_Reminder_Date_Field__c);
        Date firstSentDate = null;

        if (dateVal != null) {
            firstSentDate = (Date) dateVal;
        }

        Date latestDueDate = getLastDueDate(genericTrigger, referenceDate);
        Date lastAllowedDate = latestDueDate.addDays(Integer.valueOf(genericReminder.Days__c));

        if (firstSentDate != null && firstSentDate.addDays(Integer.valueOf(genericReminder.Days__c)) == referenceDate) {
            return true;
        }
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