/**
 * Job for Generic Escalation Workflow logic.
 */
global class GenericEscalationWorkflowBatch implements Database.Batchable<Generic_Escalation_Workflow__c>, Database.Stateful {

    private OrgWideEmailAddress orgWideAddress;
    private Map<Id, Boolean> notUpdatedRecords;

    global List<Generic_Escalation_Workflow__c> start(Database.BatchableContext context) {
        this.orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE
                               Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];
        return getGenericEscalationWorkflow();
    }

    global void execute(Database.BatchableContext context, List<Generic_Escalation_Workflow__c> scope) {
        // For each trigger we must check all reminders
        System.debug('Elements : ' + scope.size());
        for (Generic_Escalation_Workflow__c genericTrigger : scope) {
            this.notUpdatedRecords = new Map<Id, Boolean>();
            System.debug('Processing generic trigger : ' + genericTrigger.Name + ' ' + genericTrigger.Id);

            try {
                List<Generic_Reminder__c> reminders = getReminders(genericTrigger);
                String triggerQuery = buildTriggerQuery(genericTrigger, reminders);

                // Retrieve all objects for report
                List<sObject> sobjList = Database.query(triggerQuery);
                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

                for (Generic_Reminder__c reminder : reminders) {
                    List<sObject> objectsForReminders = GenericEscalationWorkflowHelper.filterObjects(sobjList, genericTrigger, reminder);
                    messages.addAll(GenericEscalationWorkflowHelper.processWorkflowEmails(objectsForReminders, reminder, this.orgWideAddress));

                    if (reminder.Reminder_Index__c == 1) {
                        for (sObject record : objectsForReminders) {
                            if (!this.notUpdatedRecords.containsKey((Id) record.get('Id'))) {
                                record.put(genericTrigger.First_Reminder_Date_Field__c, Date.today());
                            }
                        }
                    }
                }

                update objectsForReminders;
                if (!Test.isRunningTest()) {
                    Messaging.sendEmail(messages);
                }

            } catch (Exception e) {
                System.debug('Cannot process Generic Trigger with Id : ' + genericTrigger.Id + ' with Name : ' + genericTrigger.Name);
                System.debug('Error at Line : '+ e.getLineNumber() + ' Message : ' + e.getMessage() + ' Type : ' + e.getTypeName() + ' Stack Trace : ' + e.getStackTraceString());
            }
        }
    }

    global void finish(Database.BatchableContext context) {

    }

    private List<Generic_Escalation_Workflow__c> getGenericEscalationWorkflow() {
        List<Generic_Escalation_Workflow__c> triggers = [SELECT Id, Name, Custom_Object__c, Requires_Report_Field__c, Last_Report_Date_Field__c,
                                                         From_Numeral__c, From_Day_of_Week__c, To_Numeral__c, To_Day_of_Week__c
                                                         FROM Generic_Escalation_Workflow__c
                                                         WHERE Enabled__c = true];
        return triggers;
    }

    private List<Generic_Reminder__c> getReminders(Generic_Escalation_Workflow__c genericTrigger) {
         List<Generic_Reminder__c> reminders = [SELECT Id, Name, Email_Template__c, Reminder_Index__c, Days__c, Recipients__c,
                                                (SELECT Id, Field_Name__c, Operator__c, Value__c  FROM Generic_Reminder_Filters__r)
                                                FROM Generic_Reminder__c
                                                WHERE Generic_Escalation_Workflow__c =: genericTrigger.Id ORDER BY Reminder_Index__c];
        return reminders;
    }

    public static String buildTriggerQuery(Generic_Escalation_Workflow__c genericTrigger, List<Generic_Reminder__c> reminders) {
        //genericReminder.Generic_Reminder_Filters__r

        Map<String, Boolean> isFieldAddedMap = new Map<String, Boolean>();
        isFieldAddedMap.put('Id', true);
        isFieldAddedMap.put('Name', true);
        isFieldAddedMap.put('CreatedDate', true);

        String triggerQuery = 'SELECT Id, Name, CreatedDate, ';
        triggerQuery += genericTrigger.Last_Report_Date_Field__c;
        isFieldAddedMap.put(genericTrigger.Last_Report_Date_Field__c, true);
        triggerQuery += ', ';
        triggerQuery += genericTrigger.First_Reminder_Date_Field__c;
        isFieldAddedMap.put(genericTrigger.First_Reminder_Date_Field__c, true);
        for (Generic_Reminder__c rem : reminders) {
            if (!String.isEmpty(rem.Recipients__c)) {
                String[] contacts = rem.Recipients__c.split(',');
                for (String con : contacts) {
                    if (!isFieldAddedMap.containsKey(con)) {
                        triggerQuery += ', ';
                        triggerQuery += con;
                        isFieldAddedMap.put(con, true);
                    }
                }
            }

            for (Generic_Reminder_Filter__c filter : rem.Generic_Reminder_Filters__r) {
                if (!isFieldAddedMap.containsKey(filter.Field_Name__c)) {
                    triggerQuery += ', ';
                    triggerQuery += filter.Field_Name__c;
                    isFieldAddedMap.put(filter.Field_Name__c, true);
                }
            }

        }
        triggerQuery += ' FROM ';
        triggerQuery += genericTrigger.Custom_Object__c;
        triggerQuery += ' WHERE ';
        triggerQuery += genericTrigger.Requires_Report_Field__c;
        triggerQuery += ' = \'Yes\'';
        System.debug('Created Query : ' + triggerQuery);

        return triggerQuery;
    }

    public static List<Messaging.SingleEmailMessage> processWorkflowEmails(List<sObject> records, Generic_Reminder__c reminder, OrgWideEmailAddress orgWideAddress) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (sObject record : records) {
            Integer counter = 0;
            if (!String.isEmpty(reminder.Recipients__c)) {
                String[] contacts = reminder.Recipients__c.split(',');
                for (String contactField : contacts) {
                    Id contactId = (Id) record.get(contactField);
                    if (contactId != null && contactId != '') {
                        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                        msg.setTemplateId(reminder.Email_Template__c);
                        msg.setTargetObjectId(contactId);
                        msg.setWhatId((Id) record.get('Id'));
                        msg.setSaveAsActivity(false);
                        msg.setOrgWideEmailAddressId(orgWideAddress.id);
                        messages.add(msg);
                        counter++;
                    }
                }
            }

            if (counter == 0) {
                this.notUpdatedRecords.put((Id) record.get('Id'), true);
            }

        }

        return messages;
    }
}