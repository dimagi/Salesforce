public without sharing class RedFormReminderBatch implements Database.Batchable<SFDC_Employee__c>, Database.Stateful {

    private Id orgwideId;
    private Boolean quarterMode;

    private List<SFDC_Employee__c> firstEmail;
    private List<SFDC_Employee__c> secondEmail;
    private List<SFDC_Employee__c> globalEmail;
    private List<SFDC_Employee__c> quarterEmail;

    private Red_Form_Settings__c redFormSettings;

    public RedFormReminderBatch() {
        this(false);
    }

    public RedFormReminderBatch(Boolean quarterMode) {
        this.quarterMode = quarterMode;
        this.redFormSettings = Red_Form_Settings__c.getOrgDefaults();
    }

    public List<SFDC_Employee__c> start(Database.BatchableContext context) {
        this.firstEmail = new List<SFDC_Employee__c>();
        this.secondEmail = new List<SFDC_Employee__c>();
        this.globalEmail = new List<SFDC_Employee__c>();
        this.quarterEmail = new List<SFDC_Employee__c>();
        OrgWideEmailAddress orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE
                                                        Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];
        this.orgWideId = orgWideAddress.Id;

        if (!this.quarterMode) { // we want send first email or reminders
            return [SELECT Id, Name, Hire_Date__c, Email_Address__c FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active'
                                               AND (Employee_Type__c = 'Contractor' OR Employee_Type__c = 'Employee')
                                               AND Hire_Date__c <=: Date.today() AND Red_Form_Filled_Date__c = null AND Email_Address__c != null];
        }

        // We want send quarter email only to employees who filled first time Red Form
        return [SELECT Id, Name, Email_Address__c FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' AND Red_Form_Filled_Date__c != null AND Email_Address__c != null
                                                        AND (Employee_Type__c = 'Contractor' OR Employee_Type__c = 'Employee')];
    }

    public void execute(Database.BatchableContext context, List<SFDC_Employee__c> scope) {
        if (this.quarterMode) {
            this.quarterEmail.addAll(scope);
        } else {
            for (SFDC_Employee__c employee : scope) {
                Integer daysDiff = employee.Hire_Date__c.daysBetween(Date.today());
                if (employee.Hire_Date__c == Date.today()) {
                    this.firstEmail.add(employee);
                } else {
                    if (Math.mod(daysDiff, 7) == 0 && daysDiff > 1) {
                        this.globalEmail.add(employee);
                    }
                    if (Math.mod(daysDiff, 2) == 0 && daysDiff > 1) {
                        this.secondEmail.add(employee);
                    }
                }
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for (SFDC_Employee__c employee : this.quarterEmail) {
            emailsToSend.add(buildEmailMessage('Important: Update to Employee Forms and Information', getQuarterReminderEmailTemplate(employee.Name, null), employee.Email_Address__c));
        }
        for (SFDC_Employee__c employee : this.firstEmail) {
            emailsToSend.add(buildEmailMessage('Important: Dimagi Employee Forms and Information', getFirstEmailTemplate(employee.Name, null), employee.Email_Address__c));
        }
        for (SFDC_Employee__c employee : this.secondEmail) {
            emailsToSend.add(buildEmailMessage('Reminder: Dimagi Employee Forms and Information', getReminderEmailTemplate(employee.Name, null), employee.Email_Address__c));
        }
        for (SFDC_Employee__c employee : this.globalEmail) {
            emailsToSend.add(buildEmailMessage('Notification of Missing Employee Forms and Information', getOpsReminderEmailTemplate(employee.Name, null), redFormSettings.Global_Email_Address__c));
        }
        if (!Test.isRunningTest() && emailsToSend.size() > 0) {
            Messaging.sendEmail(emailsToSend);
        }

        Date currentDate = Date.today();
        Date quarter1 = Date.newInstance(currentDate.year(), 1, 1);
        Date quarter2 = Date.newInstance(currentDate.year(), 4, 1);
        Date quarter3 = Date.newInstance(currentDate.year(), 7, 1);
        Date quarter4 = Date.newInstance(currentDate.year(), 10, 1);
        if (!Test.isRunningTest() && (currentDate.isSameDay(quarter1) || currentDate.isSameDay(quarter2)
                || currentDate.isSameDay(quarter3) || currentDate.isSameDay(quarter4))) { // If new quarter we want send quarter reminder to each employee who filled RED Form
             Database.executeBatch(new RedFormReminderBatch(true));
        }
    }

    public  Messaging.SingleEmailMessage buildEmailMessage(String subject, String body, String email) {
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        emailMsg.setHtmlBody(body);
        emailMsg.subject = subject;
        emailMsg.setOrgWideEmailAddressId(this.orgwideId);
        emailMsg.setSaveAsActivity(false);
        emailMsg.setToAddresses(new String[] {email});
        return emailMsg;
    }

    public String getQuarterReminderEmailTemplate(String employeeName, String pageUrl) {
        String emailContent = 'Hi '+ employeeName + ',' + '<br/><br/>';
        emailContent += redFormSettings.Quarter_Email_Part_1__c;
        emailContent += ' ' + redFormSettings.Quarter_Email_Part_2__c;
        emailContent += '<br/><br/>';
        emailContent += 'Best,<br/>People Ops';

        return emailContent;
    }

    public String getOpsReminderEmailTemplate(String employeeName, String pageUrl) {
        String emailContent = redFormSettings.Global_Email_Part_1__c;
        emailContent += ' ' + employeeName + ' ';
        emailContent += redFormSettings.Global_Email_Part_2__c;

        return emailContent;
    }

    public String getReminderEmailTemplate(String employeeName, String pageUrl) {
        String emailContent = 'Hi '+ employeeName + ',' + '<br/><br/>';
        emailContent += redFormSettings.Remainder_Email_Part_1__c;
        emailContent += ' ' + redFormSettings.Remainder_Email_Part_2__c;
        emailContent += '<br/><br/>';
        emailContent += 'Best,<br/>Dimagi';

        return emailContent;
    }

    public String getFirstEmailTemplate(String employeeName, String pageUrl) {
        String emailContent = 'Hi '+ employeeName + ',' + '<br/><br/>';
        emailContent += redFormSettings.First_Email_Part_1__c;
        emailContent += ' ' + redFormSettings.First_Email_Part_2__c;
        emailContent += ' ' + redFormSettings.First_Email_Part_3__c;
        emailContent += '<br/><br/>';
        emailContent += 'Record of Emergency data form - https://dimagi.secure.force.com/sftools';
        emailContent += '<br/><br/>';
        emailContent += 'Looking forward to working with you!';
        emailContent += '<br/><br/>';
        emailContent += 'Best,<br/>Dimagi';

        return emailContent;
    }
}