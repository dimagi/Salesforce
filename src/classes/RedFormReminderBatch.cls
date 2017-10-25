public without sharing class RedFormReminderBatch implements Database.Batchable<SFDC_Employee__c>, Database.Stateful {

    private List<Messaging.SingleEmailMessage> emailsToSend;
    private Id orgwideId;
    private Boolean quarterMode;

    public RedFormReminderBatch() {
        this(false);
    }

    public RedFormReminderBatch(Boolean quarterMode) {
        this.quarterMode = quarterMode;
    }

    public List<SFDC_Employee__c> start(Database.BatchableContext context) {
        this.emailsToSend = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE
                                                        Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];
        this.orgWideId = orgWideAddress.Id;

        if (this.quarterMode) { // we want send first email or reminders
            return [SELECT Id, Name, Hire_Date__c FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active'
                                               AND Hire_Date__c <=: Date.today() AND Red_Form_Filled_Date__c = null];
        }

        // We want send quarter email only to employees who filled first time Red Form
        return [SELECT Id, Name FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' AND Red_Form_Filled_Date__c != null];
    }

    public void execute(Database.BatchableContext context, List<SFDC_Employee__c> scope) {
        if (this.quarterMode) {
            for (SFDC_Employee__c employee : scope) {
                emailsToSend.add(buildEmailMessage(employee.Name, getQuarterReminderEmailTemplate(employee.Name, null)));
            }
        } else {
            for (SFDC_Employee__c employee : scope) {
                Integer daysDiff = Date.today().daysBetween(employee.Hire_Date__c);
                if (employee.Hire_Date__c == Date.today()) {
                    emailsToSend.add(buildEmailMessage(employee.Name, getFirstEmailTemplate(employee.Name, null)));
                } else {
                    if (daysDiff == 7) {
                        emailsToSend.add(buildEmailMessage(employee.Name, getOpsReminderEmailTemplate(employee.Name, null)));
                    }
                    if (Math.mod(daysDiff, 2) == 0 && daysDiff > 1) {
                        emailsToSend.add(buildEmailMessage(employee.Name, getReminderEmailTemplate(employee.Name, null)));
                    }
                }
            }
        }
        // choose method for creeate email and ready
    }

    public void finish(Database.BatchableContext context) {
        if (emailsToSend.size() > 0) {
            Messaging.sendEmail(emailsToSend);
        }
    }

    public  Messaging.SingleEmailMessage buildEmailMessage(String subject, String body) {
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        emailMsg.setHtmlBody(body);
        emailMsg.subject = subject;
        emailMsg.setOrgWideEmailAddressId(this.orgwideId);
        emailMsg.setSaveAsActivity(false);
        return emailMsg;
    }

    public String getQuarterReminderEmailTemplate(String employeeName, String pageUrl) {
       String emailContent = 'Hi '+ employeeName + ',' + '<br/><br/>';
       emailContent += '1';
       return emailContent;
    }

    public String getOpsReminderEmailTemplate(String employeeName, String pageUrl) {
       String emailContent = 'Hi '+ employeeName + ',' + '<br/><br/>';
       emailContent += '2';
       return emailContent;
    }

    public String getReminderEmailTemplate(String employeeName, String pageUrl) {
       String emailContent = 'Hi '+ employeeName + ',' + '<br/><br/>';
       emailContent += '3';
       return emailContent;
    }

    public String getFirstEmailTemplate(String employeeName, String pageUrl) {
       String emailContent = 'Hi '+ employeeName + ',' + '<br/><br/>';
       emailContent += '4';
       return emailContent;
    }
}