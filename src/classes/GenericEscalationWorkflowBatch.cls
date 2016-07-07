/**
 * Job for Generic Escalation Workflow logic.
 */
global class GenericEscalationWorkflowBatch implements Database.Batchable<Generic_Escalation_Workflow__c>, Database.Stateful {

    private OrgWideEmailAddress orgWideAddress;
    private Date referenceDate;
    private List<String> triggerErrors;
    private List<String> emailErrors;

    global List<Generic_Escalation_Workflow__c> start(Database.BatchableContext context) {
        this.orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE
                               Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];
        this.referenceDate = Date.today();
        this.triggerErrors = new List<String>();
        this.emailErrors =  new List<String>();
        return getGenericEscalationWorkflow();
    }

    public void setReferenceDate(Date refD) {
        this.referenceDate = refD;
    }

    global void execute(Database.BatchableContext context, List<Generic_Escalation_Workflow__c> scope) {
        // For each trigger we must check all reminders
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (Generic_Escalation_Workflow__c genericTrigger : scope) {
            System.debug('Processing generic trigger : ' + genericTrigger.Name + ' ' + genericTrigger.Id);

            try {
                List<Generic_Reminder__c> reminders = getReminders(genericTrigger);
                String triggerQuery = buildTriggerQuery(genericTrigger, reminders);

                // Retrieve all objects for report
                List<sObject> sobjList = Database.query(triggerQuery);
                System.debug('sobjList Found : ' + sobjList.size());

                for (Generic_Reminder__c reminder : reminders) {
                    if (GenericEscalationWorkflowHelper.checkReminderDate(reminder, this.referenceDate)) {
                        List<sObject> objectsForReminders = GenericEscalationWorkflowHelper.filterObjects(sobjList, genericTrigger, reminder, referenceDate);
                        System.debug('Found : ' + objectsForReminders.size());
                        messages.addAll(processWorkflowEmails(objectsForReminders, reminder, this.orgWideAddress));
                    }
                }

            } catch (Exception e) {
                System.debug('Cannot process Generic Trigger with Id : ' + genericTrigger.Id + ' with Name : ' + genericTrigger.Name);
                System.debug('Error at Line : '+ e.getLineNumber() + ' Message : ' + e.getMessage() + ' Type : ' + e.getTypeName() + ' Stack Trace : ' + e.getStackTraceString());
                triggerErrors.add(getBodyFromException('Cannot process trigger : ' + genericTrigger.Name, e));
            }
        }
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] emailResult = Messaging.sendEmail(messages, false);
            for (Messaging.SendEmailResult emailRes : emailResult) {
                if (!emailRes.isSuccess()) {
                    String errorMessage = 'Cannot send email :<br />';
                    for (Messaging.SendEmailError emailError : emailRes.getErrors()) {
                        errorMessage += 'Message: ' + emailError.getMessage() + '<br />Fields: ' + emailError.getFields() + '<br />Code: ' + emailError.getStatusCode() + '<br />Target Id: ' + emailError.getTargetObjectId();
                    }

                    emailErrors.add(errorMessage);
                }
            }
        }
    }

    global void finish(Database.BatchableContext context) {
        Generic_Workflow_Settings__c settings = Generic_Workflow_Settings__c.getOrgDefaults();
        String emails = settings.Error_Email__c;

        if (!String.isEmpty(emails)) {

            if (emailErrors.size() > 0 || triggerErrors.size() > 0) {
                String[] addressList = emails.split(',');
                String emailBody = 'Trigger Exceptions :<br />';
                for (String row : triggerErrors) {
                    emailBody += '<br />';
                    emailBody += row;
                }

                emailBody += '<br /><br />Email Exceptions :<br />';
                for (String row : emailErrors) {
                    emailBody += '<br />';
                    emailBody += row;
                }

                EmailHelper.sendEmail(addressList, 'Generic Escalation Workflow Errors', emailBody);
            }
        }
    }

    public static String buildTriggerQuery(Generic_Escalation_Workflow__c genericTrigger, List<Generic_Reminder__c> reminders) {
        Map<String, Boolean> isFieldAddedMap = new Map<String, Boolean>();
        isFieldAddedMap.put('Id', true);
        isFieldAddedMap.put('Name', true);
        isFieldAddedMap.put('CreatedDate', true);

        String triggerQuery = 'SELECT Id, Name, CreatedDate';
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

    public List<Messaging.SingleEmailMessage> processWorkflowEmails(List<sObject> records, Generic_Reminder__c reminder, OrgWideEmailAddress orgWideAddress) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (sObject record : records) {
            if (!String.isEmpty(reminder.Recipients__c)) {
                String[] contacts = reminder.Recipients__c.split(',');
                for (String contactField : contacts) {
                    Id contactId = (Id) record.get(contactField);
                    System.debug('contactId ' + contactId);
                    if (!String.isEmpty(contactId)) {
                        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                        msg.setTemplateId(reminder.Email_Template__c);
                        msg.setTargetObjectId(contactId);
                        msg.setWhatId((Id) record.get('Id'));
                        msg.setSaveAsActivity(false);
                        msg.setOrgWideEmailAddressId(orgWideAddress.id);
                        messages.add(msg);
                    }
                }
            }
        }

        return messages;
    }

    private String getBodyFromException(String head, Exception ex) {
        return head + '<br />' +
                'Line: ' + ex.getLineNumber() + '<br />' +
                'Type: ' + ex.getTypeName() + '<br />' +
                'Message: ' + ex.getMessage() + '<br />' +
                'Stack Trace: ' + ex.getStackTraceString() + '<br />' +
                'Cause by: ' + ex.getCause() + '<br />';
    }

    private List<Generic_Escalation_Workflow__c> getGenericEscalationWorkflow() {
        List<Generic_Escalation_Workflow__c> triggers = [SELECT Id, Name, Custom_Object__c, Requires_Report_Field__c
                                                         FROM Generic_Escalation_Workflow__c
                                                         WHERE Enabled__c = true AND Start_date__c <=: this.referenceDate AND End_date__c >=: this.referenceDate];
        return triggers;
    }

    private List<Generic_Reminder__c> getReminders(Generic_Escalation_Workflow__c genericTrigger) {
         List<Generic_Reminder__c> reminders = [SELECT Id, Name, Email_Template__c, Reminder_Index__c, Recipients__c, Frequency_type__c, Week_days__c, Monthly_type__c, Numeral_monthly__c,
                                                Day_of_the_month__c, Day_of_the_week__c, (SELECT Id, Field_Name__c, Operator__c, Value__c, Data_Type__c, Number_Value__c, Checkbox_Value__c,
                                                                                          Date_Value__c FROM Generic_Reminder_Filters__r)
                                                FROM Generic_Reminder__c
                                                WHERE Generic_Escalation_Workflow__c =: genericTrigger.Id ORDER BY Reminder_Index__c];
        System.debug('Size" ' + reminders.size());
        return reminders;
    }
}