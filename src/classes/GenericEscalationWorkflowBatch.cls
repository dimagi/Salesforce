/**
 * Job for Generic Escalation Workflow logic.
 */
global class GenericEscalationWorkflowBatch implements Database.Batchable<Generic_Escalation_Workflow__c> {

    private OrgWideEmailAddress orgWideAddress;

    global List<Generic_Escalation_Workflow__c> start(Database.BatchableContext context) {
        this.orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE
                               Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];
        return getGenericEscalationWorkflow();
    }

    global void execute(Database.BatchableContext context, List<Generic_Escalation_Workflow__c> scope) {
        // For each trigger we must check all reminders
        for (Generic_Escalation_Workflow__c genericTrigger : scope) {

            List<Generic_Reminder__c> triggerReminders = [SELECT Id, Name, Email_Template__c, Reminder_Index__c, Days__c
                                                            FROM Generic_Reminder__c
                                                            WHERE Generic_Escalation_Workflow__c =: genericTrigger.Id ORDER BY Reminder_Index__c];

            System.debug('Processing generic trigger : ' + genericTrigger.Name + ' ' + genericTrigger.Id);
            String triggerQuery = buildTriggerQuery(genericTrigger);
            try {
                // Retrieve all objects for report
                List<sObject> sobjList = Database.query(triggerQuery);
                List<Generic_Reminder__c> reminders = getReminders(genericTrigger);

                for (Generic_Reminder__c reminder : reminders) {
                    List<sObject> objectsForReminders = GenericEscalationWorkflowHelper.filterObjects(sobjList, genericTrigger, null);

                    // TODO
                    Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                    msg.setTemplateId(reminder.Email_Template__c);
                    //msg.setTargetObjectId(contactList[0].Id);
                    msg.setToAddresses(new String[] {'tstalka@soldevelo.com'});
                    //msg.setWhatId(PROID);
                    msg.setSaveAsActivity(false);
                    msg.setOrgWideEmailAddressId(this.orgWideAddress.id);

                    // TODO send emails
                }
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{msg});

            } catch (Exception e) {
                // TODO
                System.debug('Cannot invoke query : ' + e);
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
         List<Generic_Reminder__c> reminders = [SELECT Id, Name, Email_Template__c, Reminder_Index__c, Days__c
                                                FROM Generic_Reminder__c
                                                WHERE Generic_Escalation_Workflow__c =: genericTriggerId ORDER BY Reminder_Index__c];
        return reminders;
    }

    private String buildTriggerQuery(Generic_Escalation_Workflow__c genericTrigger) {
        String triggerQuery = 'SELECT Id, Name, ';
        triggerQuery += genericTrigger.Last_Report_Date_Field__c;
        triggerQuery += ' FROM ';
        triggerQuery += genericTrigger.Custom_Object__c;
        triggerQuery += ' WHERE ';
        triggerQuery += Requires_Report_Field__c;
        triggerQuery += ' != \'Yes\'';
        System.debug('Created Query : ' + triggerQuery);
        return triggerQuery;
    }
}