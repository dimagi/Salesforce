/**
 * Helper class for filtering sObjects for Generic Escalation Workflow. It also sends workflow emails.
 */
public class GenericEscalationWorkflowHelper {

    public static List<sObject> filterObjects(List<sObject> sourceList, Generic_Escalation_Workflow__c genericTrigger, Generic_Reminder__c genericReminder, Date referenceDate) {
        List<sObject> filteredList = new List<sObject>();

        for (sObject record : sourceList) {
            if (checkFilters(record, genericReminder.Generic_Reminder_Filters__r)) {
                filteredList.add(record);
            }
        }

        return filteredList;
    }

    public static Boolean checkReminderDate(Generic_Reminder__c reminder, Date referenceDate) {
        if (reminder.Frequency_type__c == 'Weekly') {
            return processWeeklyReminderDate(reminder, referenceDate);
        } else {
            return processMonthlyReminderDate(reminder, referenceDate);
        }
    }

    public static Boolean processWeeklyReminderDate(Generic_Reminder__c reminder, Date referenceDate) {
        String daysList = reminder.Week_days__c;
        if (!String.isEmpty(daysList)) {
            String[] days = daysList.split(';');
            String currentDay = DateTime.newInstance(referenceDate, Time.newInstance(0, 0, 0, 0)).format('E');
            for (String day : days) {
                if (day.startsWith(currentDay)) {
                    return true;
                }
            }
        }

        return false;
    }

    public static Boolean processMonthlyReminderDate(Generic_Reminder__c reminder, Date referenceDate) {
        if (reminder.Monthly_type__c == 'On day') {
            if (reminder.Day_of_the_month__c == 'Last day') {
                Integer lastDay = Date.daysInMonth(referenceDate.year(), referenceDate.month());
                if (lastDay == referenceDate.day()) {
                    return true;
                }
            } else {
                if (referenceDate.day() == Integer.valueOf(reminder.Day_of_the_month__c)) {
                    return true;
                }
            }
        } else {
            Date propDate = getProperDate(reminder.Day_of_the_week__c, reminder.Numeral_monthly__c, referenceDate);
            if (propDate == referenceDate) {
                return true;
            }
        }

        return false;
    }

    public static Date getProperDate(String dayOfWeek, String num, Date referenceDate) {
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

    public static Boolean checkFilters(sObject record, List<Generic_Reminder_Filter__c> filters) {
        for (Generic_Reminder_Filter__c filter : filters) {

            if (filter.Data_Type__c == 'STRING' || filter.Data_Type__c == 'PICKLIST' || filter.Data_Type__c == 'EMAIL' || filter.Data_Type__c == 'ID') {
                System.debug('String filter');
                if (!invokeStringFilter(record, filter)) {
                    return false;
                }
            } else if (filter.Data_Type__c == 'DATE') {
                System.debug('DATE filter');
                if (!invokeDateFilter(record, filter)) {
                    return false;
                }
            } else if (filter.Data_Type__c == 'DOUBLE') {
                System.debug('DOUBLE filter');
                if (!invokeDoubleFilter(record, filter)) {
                    return false;
                }
            } else if (filter.Data_Type__c == 'BOOLEAN') {
                System.debug('BOOLEAN filter');
                if (!invokeBooleanFilter(record, filter)) {
                    return false;
                }
            }
        }
        return true;
    }

    private static Boolean invokeDateFilter(sObject record, Generic_Reminder_Filter__c filter) {
        System.debug('Operator ' + filter.Operator__c);
        System.debug('Field_Name__c ' + filter.Field_Name__c);
        System.debug('Date_Value__c ' + filter.Date_Value__c);
        System.debug('RECIRD Date_Value__c ' + record.get(filter.Field_Name__c));
        if (filter.Operator__c == '=') {
            if (filter.Date_Value__c == (Date) record.get(filter.Field_Name__c)) {
                return true;
            }
        } else if (filter.Operator__c == '!=') {
            if (filter.Date_Value__c != (Date) record.get(filter.Field_Name__c)) {
                return true;
            }
        } else if (filter.Operator__c == '<') {
            if ((Date) record.get(filter.Field_Name__c) < filter.Date_Value__c) {
                return true;
            }
        } else if (filter.Operator__c == '>') {
            if ((Date) record.get(filter.Field_Name__c) > filter.Date_Value__c) {
                return true;
            }
        } else if (filter.Operator__c == '>=') {
            if ((Date) record.get(filter.Field_Name__c) >= filter.Date_Value__c) {
                return true;
            }
        } else if (filter.Operator__c == '<=') {
            if ((Date) record.get(filter.Field_Name__c) <= filter.Date_Value__c) {
                return true;
            }
        }
        System.debug('Date  false');
        return false;
    }

    private static Boolean invokeDoubleFilter(sObject record, Generic_Reminder_Filter__c filter) {
        if (filter.Operator__c == '=') {
            if (filter.Number_Value__c == (Double) record.get(filter.Field_Name__c)) {
                return true;
            }
        } else if (filter.Operator__c == '!=') {
            if (filter.Number_Value__c != (Double) record.get(filter.Field_Name__c)) {
                return true;
            }
        } else if (filter.Operator__c == '<') {
            if ((Double) record.get(filter.Field_Name__c) < filter.Number_Value__c) {
                return true;
            }
        } else if (filter.Operator__c == '>') {
            if ((Double) record.get(filter.Field_Name__c) > filter.Number_Value__c) {
                return true;
            }
        } else if (filter.Operator__c == '>=') {
            if ((Double) record.get(filter.Field_Name__c) >= filter.Number_Value__c) {
                return true;
            }
        } else if (filter.Operator__c == '<=') {
            if ((Double) record.get(filter.Field_Name__c) <= filter.Number_Value__c) {
                return true;
            }
        }
        return false;
    }

    private static Boolean invokeBooleanFilter(sObject record, Generic_Reminder_Filter__c filter) {
        if (filter.Operator__c == '=') {
            if (filter.Checkbox_Value__c == (Boolean) record.get(filter.Field_Name__c)) {
                return true;
            }
        } else if (filter.Operator__c == '!=') {
            if (filter.Checkbox_Value__c != (Boolean) record.get(filter.Field_Name__c)) {
                return true;
            }
        }
        return false;
    }

    private static Boolean invokeStringFilter(sObject record, Generic_Reminder_Filter__c filter) {
        if (filter.Operator__c == '=') {
            if (filter.Value__c == (String) record.get(filter.Field_Name__c)) {
                return true;
            }
        } else if (filter.Operator__c == '!=') {
            if (filter.Value__c != (String) record.get(filter.Field_Name__c)) {
                return true;
            }
        }
        return false;
    }
}