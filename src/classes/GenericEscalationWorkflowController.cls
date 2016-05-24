/**
 * Controller for creating/updating/deleting reminders for generic escalation workflow.
 */
public class GenericEscalationWorkflowController {

    private String genericReminderId;
    private List<Generic_Escalation_Workflow__c> genericReminders;
    private Generic_Escalation_Workflow__c genericReminder;

    private List<SelectOption> emailTemplates;
    private String selectedTemplate;

    private Map<String, Schema.SObjectType> sObjectTypes;
    private List<SelectOption> customObjects;
    private String selectedCustomObject;

    public GenericEscalationWorkflowController() {
        this.genericReminders = [SELECT Id, Name, Custom_Object__c, Email_Template__c FROM Generic_Escalation_Workflow__c];
        this.genericReminder = new Generic_Escalation_Workflow__c();
        loadTemplatesAndObjects();
    }

    public PageReference chooseGenericReminder() {
        for (Generic_Escalation_Workflow__c gew : genericReminders) {
            if (gew.Id == this.genericReminderId) {
                this.genericReminder = gew;
            }
        }
        return null;
    }

    public PageReference clearGenericTrigger() {
        this.genericReminder = new Generic_Escalation_Workflow__c();
        return null;
    }

    public PageReference saveGenericTrigger() {
        clearGenericTrigger();
        return null;
    }

    private void loadTemplatesAndObjects() {
        customObjects = new List<SelectOption>(); 
        emailTemplates = new List<SelectOption>();

        List<Folder> emailFolder = [SELECT Id, Name, Type FROM Folder WHERE Type = 'Email' AND Name = 'Generic Escalation Workflow'];
        if (emailFolder != null && emailFolder.size() > 0) {
            List<EmailTemplate> templates = [SELECT Id, Name FROM EmailTemplate WHERE FolderId =: emailFolder.get(0).Id];   
            for (EmailTemplate t : templates) {
                emailTemplates.add(new SelectOption(t.Id, t.Name));
            }

            emailTemplates.add(new SelectOption('Test value 1', 'Templ Test 1'));
            emailTemplates.add(new SelectOption('Test value 2', 'Templ Test 2'));
        }

        sObjectTypes = new Map<String, Schema.SObjectType>();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (Schema.SObjectType objectType : globalDescribe.values()) {
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            if (objectDescribe.isCustom() && !objectDescribe.isCustomSetting()) {
                customObjects.add(new SelectOption(objectDescribe.getName(), objectDescribe.getLabel()));
                sObjectTypes.put(objectDescribe.getName(), objectType);
            }
        }
    }

    public List<Generic_Escalation_Workflow__c> getGenericReminders() {
        return this.genericReminders;
    }

    public Generic_Escalation_Workflow__c getGenericReminder() {
        return this.genericReminder;
    }    
    
    public String getGenericReminderId() {
        return this.genericReminderId;
    }

    public void setGenericReminderId(String newId) {
        this.genericReminderId = newId;
    }
    
    public List<SelectOption> getEmailTemplates() {
        return this.emailTemplates;
    }

    public String getSelectedTemplate(){
        return this.selectedTemplate;
    }

    public void setSelectedTemplate(String so){
        this.selectedTemplate = so;
    }
    
        
    public List<SelectOption> getCustomObjects() {
        return this.customObjects;
    }

    public String getSelectedCustomObject(){
        return this.selectedCustomObject;
    }

    public void setSelectedCustomObject(String sco){
        this.selectedCustomObject = sco;
    }  
}