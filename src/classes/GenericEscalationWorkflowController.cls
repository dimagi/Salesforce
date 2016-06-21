/**
 * Controller for creating/updating/deleting triggers for generic escalation workflow.
 */
public class GenericEscalationWorkflowController {

    private String genericTriggerId;
    private List<Generic_Escalation_Workflow__c> genericTriggers;
    private Generic_Escalation_Workflow__c genericTrigger;

    private List<SelectOption> emailTemplates;

    private Map<String, Schema.SObjectType> sObjectTypes;
    private List<SelectOption> customObjects;
    private Map<String, Schema.SObjectField> customObjectFieldsMap;
    private List<SelectOption> customObjectFields;

    private Integer reminderIndex;
    private List<Generic_Reminder__c> triggerReminders;
    private List<Generic_Reminder__c> remindersToDelete;

    private Integer selectedFilterIndex;
    private Map<Decimal, List<Generic_Reminder_Filter__c>> reminderFiltersMap;
    private List<Generic_Reminder_Filter__c> filtersToDelete;

    private List<SelectOption> operators = new List<SelectOption> { new SelectOption('=', '='), new SelectOption('>=', '>='), new SelectOption('<=', '<='), new SelectOption('>', '>'), new SelectOption('<', '<'), new SelectOption('!=', '!=')};
    private List<SelectOption> textOperators = new List<SelectOption> { new SelectOption('=', '='), new SelectOption('!=', '!=') };

    public GenericEscalationWorkflowController() {
        this.genericTrigger = new Generic_Escalation_Workflow__c(Global_Start_Date__c = Date.today());
        this.triggerReminders = new List<Generic_Reminder__c>();
        this.remindersToDelete = new List<Generic_Reminder__c>();
        this.reminderFiltersMap = new Map<Decimal, List<Generic_Reminder_Filter__c>>();
        this.filtersToDelete = new List<Generic_Reminder_Filter__c>();
        this.reminderIndex = -1;
        loadGenericTriggers();
        loadTemplatesAndObjects();
        this.genericTrigger.Custom_Object__c = customObjects.get(0).getValue();
        loadCustomObjectFields();
    }

    public PageReference chooseGenericTrigger() {
        for (Generic_Escalation_Workflow__c gew : genericTriggers) {
            if (gew.Id == this.genericTriggerId) {
                this.genericTrigger = gew;
                loadTriggerReminders();
                loadCustomObjectFields();
                loadReminderFilters();
                return null;
            }
        }
        return null;
    }

    public PageReference clearGenericTrigger() {
        this.genericTrigger = new Generic_Escalation_Workflow__c(Global_Start_Date__c = Date.today());
        this.triggerReminders = new List<Generic_Reminder__c>();
        this.remindersToDelete = new List<Generic_Reminder__c>();
        this.reminderFiltersMap = new Map<Decimal, List<Generic_Reminder_Filter__c>>();
        this.filtersToDelete = new List<Generic_Reminder_Filter__c>();
        this.genericTriggerId = '';
        this.reminderIndex = -1;
        this.genericTrigger.Custom_Object__c = customObjects.get(0).getValue();
        loadCustomObjectFields();
        return null;
    }

    public PageReference saveGenericTrigger() {
        upsert this.genericTrigger;
        delete this.filtersToDelete;
        delete this.remindersToDelete;

        Id upsertedTriggerId = this.genericTrigger.Id;
        for (Generic_Reminder__c triggerRem : triggerReminders) {
            if (String.isEmpty(triggerRem.Id)) {
                triggerRem.Generic_Escalation_Workflow__c = upsertedTriggerId;
            }
        }
        upsert triggerReminders;

        for (Generic_Reminder__c triggerRem : triggerReminders) {
            List<Generic_Reminder_Filter__c>  filtersToUpsert = this.reminderFiltersMap.get(triggerRem.Reminder_Index__c);
            for (Generic_Reminder_Filter__c remFilter : filtersToUpsert) {
                if (String.isEmpty(remFilter.Id)) {
                    remFilter.Generic_Reminder__c = triggerRem.Id;
                }
            }
            upsert filtersToUpsert;
        }

        clearGenericTrigger();
        loadGenericTriggers();
        return null;
    }

    public PageReference removeGenericTrigger() {
        if (String.isEmpty(this.genericTrigger.Id)) {
            return clearGenericTrigger();
        }
        delete this.genericTrigger;
        clearGenericTrigger();
        loadGenericTriggers();
        return null;
    }

    public PageReference addNewTriggerReminder() {
        if (this.triggerReminders == null) {
            this.triggerReminders = new List<Generic_Reminder__c>();
        }

        Integer newIndex = this.triggerReminders.size() + 1;
        Generic_Reminder__c newReminder = new Generic_Reminder__c(Reminder_Index__c = newIndex, Days__c = 5);
        this.triggerReminders.add(newReminder);
        this.reminderFiltersMap.put(newIndex, new List<Generic_Reminder_Filter__c>());
        return null;
    }

    public PageReference removeTriggerReminder() {
        if (this.triggerReminders == null) {
            this.triggerReminders = new List<Generic_Reminder__c>();
            return null;
        }

        for (Integer i = this.reminderIndex; i < this.triggerReminders.size(); i++) {
            this.triggerReminders.get(i).Reminder_Index__c = this.triggerReminders.get(i).Reminder_Index__c - 1;
        }
        Generic_Reminder__c remToDelete = this.triggerReminders.get(this.reminderIndex - 1);
        if (!String.isEmpty(remToDelete.Id)) {
            remindersToDelete.add(remToDelete);
        }
        this.triggerReminders.remove(this.reminderIndex - 1);
        
        for (Generic_Reminder_Filter__c grf : this.reminderFiltersMap.get(this.reminderIndex)) {
            if (!String.isEmpty(grf.Id)) {
                filtersToDelete.add(grf);
            }
        }
        this.reminderFiltersMap.remove(this.reminderIndex);

        for (Integer i = this.reminderIndex + 1; i <= this.reminderFiltersMap.size() + 1; i++) {
            this.reminderFiltersMap.put(i - 1, this.reminderFiltersMap.get(i));
            this.reminderFiltersMap.remove(i);
        }
        return null;
    }

    public PageReference addNewFilter() {
        if (this.customObjectFields != null && this.customObjectFields.size() > 0) {
            String fieldName = this.customObjectFields.get(0).getValue();
            if (!String.isBlank(fieldName)) {
                Generic_Reminder_Filter__c remFilter = new Generic_Reminder_Filter__c(Field_Name__c = fieldName, Operator__c = '=', Value__c = '');
                this.reminderFiltersMap.get(reminderIndex).add(remFilter);
            }
        }

        return null;
    }

    public PageReference removeReminderFilter() {
        if (this.selectedFilterIndex != null && this.selectedFilterIndex < this.reminderFiltersMap.get(this.reminderIndex).size()) {
            this.filtersToDelete.add(this.reminderFiltersMap.get(this.reminderIndex).get(this.selectedFilterIndex));
            this.reminderFiltersMap.get(this.reminderIndex).remove(this.selectedFilterIndex);
        }

        return null;
    }

    public void loadCustomObjectFields() {
        this.customObjectFields = new List<SelectOption>();
        Schema.SObjectType selectedCustomObj = sObjectTypes.get(this.genericTrigger.Custom_Object__c);
        this.customObjectFieldsMap = new Map<String, Schema.SObjectField>();
        if (selectedCustomObj == null) {
            return;
        }
        Schema.DescribeSObjectResult descResultType = selectedCustomObj.getDescribe();
        this.customObjectFieldsMap = descResultType.fields.getMap();

        for (String key : customObjectFieldsMap.keySet()) {
            Schema.DescribeFieldResult objField = customObjectFieldsMap.get(key).getDescribe();
            this.customObjectFields.add(new SelectOption(objField.getName(), objField.getLabel()));
        }
        
        //TODO delete filters!!!!!
        // TODO CHANGE Last_Report_Date_Field__c, Requires_Report_Field__c 
    }

    private void loadReminderFilters() {
        for (Generic_Reminder__c rem : this.triggerReminders) {
            this.reminderFiltersMap.put(rem.Reminder_Index__c, [SELECT Id, Field_Name__c, Operator__c, Value__c FROM Generic_Reminder_Filter__c WHERE Generic_Reminder__c =: rem.Id]);
        }
    }

    private void loadTriggerReminders() {
        this.triggerReminders = [SELECT Id, Name, Email_Template__c, Reminder_Index__c, Days__c FROM Generic_Reminder__c WHERE Generic_Escalation_Workflow__c =: genericTriggerId ORDER BY Reminder_Index__c];
    }

    private void loadGenericTriggers() {
        this.genericTriggers = [SELECT Id, Name, Custom_Object__c, Enabled__c, Global_Start_Date__c, Last_Report_Date_Field__c, Requires_Report_Field__c,
                                From_Numeral__c, From_Day_of_Week__c, To_Numeral__c, To_Day_of_Week__c, First_Reminder_Date_Field__c
                                FROM Generic_Escalation_Workflow__c];
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

    public List<Generic_Escalation_Workflow__c> getGenericTriggers() {
        return this.genericTriggers;
    }

    public Generic_Escalation_Workflow__c getGenericTrigger() {
        return this.genericTrigger;
    }    

    public String getGenericTriggerId() {
        return this.genericTriggerId;
    }

    public void setGenericTriggerId(String newId) {
        this.genericTriggerId = newId;
    }

    public List<SelectOption> getEmailTemplates() {
        return this.emailTemplates;
    }

    public List<SelectOption> getCustomObjectFields() {
        return this.customObjectFields;
    }

    public List<SelectOption> getCustomObjects() {
        return this.customObjects;
    }

    public List<Generic_Reminder__c> getTriggerReminders() {
        return this.triggerReminders;
    }
    
    public void setTriggerReminders(List<Generic_Reminder__c> gr) {
        this.triggerReminders = gr;
    }

    public Integer getReminderIndex() {
        return this.reminderIndex;
    }

    public void setReminderIndex(Integer val) {
        this.reminderIndex = val;
    }

    public Integer getSelectedFilterIndex() {
        return this.selectedFilterIndex;
    }

    public void setSelectedFilterIndex(Integer val) {
        this.selectedFilterIndex = val;
    }

    public Map<Decimal, List<Generic_Reminder_Filter__c>> getReminderFiltersMap() {
        return this.reminderFiltersMap;
    }

    public void setReminderFiltersMap(Map<Decimal, List<Generic_Reminder_Filter__c>> rfm) {
        this.reminderFiltersMap = rfm;
    }

    public List<SelectOption> getTextOperators() {
        return this.textOperators;
    }
    
    public List<SelectOption> getOperators() {
        return this.operators;
    }
}