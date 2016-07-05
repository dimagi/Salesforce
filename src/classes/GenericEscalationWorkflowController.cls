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
    private List<SelectOption> customObjectFieldsText;
    private List<SelectOption> customObjectFieldsReference;

    private Integer reminderIndex;
    private List<Generic_Reminder__c> triggerReminders;
    private List<Generic_Reminder__c> remindersToDelete;

    private Integer selectedFilterIndex;
    private Map<Decimal, List<Generic_Reminder_Filter__c>> reminderFiltersMap;
    private List<Generic_Reminder_Filter__c> filtersToDelete;

    private Integer selectedRecipientIndex;
    private Map<Decimal, List<StringWrapper>> recipientsMap;

    private Map<String, String> fieldTypes;
    private List<SelectOption> operators = new List<SelectOption> { new SelectOption('=', '='), new SelectOption('>=', '>='), new SelectOption('<=', '<='),
                                                                    new SelectOption('>', '>'), new SelectOption('<', '<'), new SelectOption('!=', '!=')};
    private List<SelectOption> textOperators = new List<SelectOption> { new SelectOption('=', '='), new SelectOption('!=', '!=') };
    private List<SelectOption> frequencyTypes = new List<SelectOption> { new SelectOption('Monthly', 'Monthly'), new SelectOption('Weekly', 'Weekly') };
    private List<SelectOption> monthlyTypes = new List<SelectOption> { new SelectOption('On day', 'Choose date'), new SelectOption('On', 'Choose week day') };
    private List<SelectOption> dayOfMonth;
    private List<SelectOption> daysOfWeek = new List<SelectOption> { new SelectOption('Monday', 'Monday'), new SelectOption('Tuesday', 'Tuesday'),
                                                                     new SelectOption('Wednesday', 'Wednesday'), new SelectOption('Thursday', 'Thursday'),
                                                                     new SelectOption('Friday', 'Friday'), new SelectOption('Saturday', 'Saturday'),
                                                                     new SelectOption('Sunday', 'Sunday') };
    private List<SelectOption> daysNumeric = new List<SelectOption> { new SelectOption('First', 'First'), new SelectOption('Second', 'Second'),
                                                                      new SelectOption('Third', 'Third'), new SelectOption('Fourth', 'Fourth') };

    public GenericEscalationWorkflowController() {
        this.dayOfMonth = new List<SelectOption>();
        Integer i;
        for (i = 1; i < 32; i++) {
            dayOfMonth.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
        }

        dayOfMonth.add(new SelectOption('Last day', 'Last day'));
        this.referenceDate = new DateWrapper();
        this.genericTrigger = new Generic_Escalation_Workflow__c(Start_date__c = Date.today(), End_date__c = Date.today());
        this.triggerReminders = new List<Generic_Reminder__c>();
        this.remindersToDelete = new List<Generic_Reminder__c>();
        this.reminderFiltersMap = new Map<Decimal, List<Generic_Reminder_Filter__c>>();
        this.recipientsMap = new Map<Decimal, List<StringWrapper>>();
        this.filtersToDelete = new List<Generic_Reminder_Filter__c>();
        this.reminderIndex = -1;
        loadGenericTriggers();
        loadTemplatesAndObjects();
        this.genericTrigger.Custom_Object__c = customObjects.get(0).getValue();
        loadCustomObjectFields();
    }

    ///////////////////////////////////////////// TODO REMOVE AFTER TESTING

    private DateWrapper referenceDate;

    public DateWrapper getReferenceDate() {
        return this.referenceDate;
    }

    public void setreferenceDate(DateWrapper val) {
        this.referenceDate = val;
    }

    public PageReference runJob() {
        GenericEscalationWorkflowBatch bJob = new GenericEscalationWorkflowBatch();
        List<Generic_Escalation_Workflow__c> scope = bJob.start(null);
        bJob.setReferenceDate(this.referenceDate.getValue());
        bJob.execute(null, scope);
        return null;
    }

    public class DateWrapper {

        private Date value;

        public DateWrapper() {
            this.value = Date.today();
        }

        public DateWrapper(Date v) {
            this.value = v;
        }

        public Date getValue() {
            return this.value;
        }

        public void setValue(Date v) {
            this.value = v;
        }
    }
    /////////////////////////////////////////////

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
        this.genericTrigger = new Generic_Escalation_Workflow__c(Start_date__c = Date.today(), End_date__c = Date.today());
        this.triggerReminders = new List<Generic_Reminder__c>();
        this.remindersToDelete = new List<Generic_Reminder__c>();
        this.reminderFiltersMap = new Map<Decimal, List<Generic_Reminder_Filter__c>>();
        this.recipientsMap = new Map<Decimal, List<StringWrapper>>();
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
            String recipients = '';
            Boolean first = true;
            for (StringWrapper r : this.recipientsMap.get(triggerRem.Reminder_Index__c)) {
                if (first) {
                    first = false;
                    recipients += r.getValue();
                } else {
                    recipients += ',';
                    recipients += r.getValue();
                }
            }
            triggerRem.Recipients__c = recipients;
            if (String.isEmpty(triggerRem.Id)) {
                triggerRem.Generic_Escalation_Workflow__c = upsertedTriggerId;
            }
        }
        upsert triggerReminders;

        for (Generic_Reminder__c triggerRem : triggerReminders) {
            List<Generic_Reminder_Filter__c>  filtersToUpsert = this.reminderFiltersMap.get(triggerRem.Reminder_Index__c);
            for (Generic_Reminder_Filter__c remFilter : filtersToUpsert) {
                Schema.DisplayType fieldType = customObjectFieldsMap.get(remFilter.Field_Name__c).getDescribe().getType();
                remFilter.Data_Type__c = fieldType.name();
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
        Generic_Reminder__c newReminder = new Generic_Reminder__c(Reminder_Index__c = newIndex, Frequency_type__c = 'Monthly', Monthly_type__c = 'On day');
        this.triggerReminders.add(newReminder);
        this.reminderFiltersMap.put(newIndex, new List<Generic_Reminder_Filter__c>());
        this.recipientsMap.put(newIndex, new List<StringWrapper>());
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
                this.filtersToDelete.add(grf);
            }
        }

        this.reminderFiltersMap.remove(this.reminderIndex);
        for (Integer i = this.reminderIndex + 1; i <= this.reminderFiltersMap.size() + 1; i++) {
            this.reminderFiltersMap.put(i - 1, this.reminderFiltersMap.get(i));
            this.reminderFiltersMap.remove(i);
        }

        this.recipientsMap.remove(this.reminderIndex);
        for (Integer i = this.reminderIndex + 1; i <= this.recipientsMap.size() + 1; i++) {
            this.recipientsMap.put(i - 1, this.recipientsMap.get(i));
            this.recipientsMap.remove(i);
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
            Generic_Reminder_Filter__c filter = this.reminderFiltersMap.get(this.reminderIndex).get(this.selectedFilterIndex);
            if (!String.isEmpty(filter.Id)) {
                this.filtersToDelete.add(filter);
            }
            this.reminderFiltersMap.get(this.reminderIndex).remove(this.selectedFilterIndex);
        }

        return null;
    }

    public PageReference addRecipient() {
        if (this.customObjectFields != null && this.customObjectFields.size() > 0) {
            String fieldName = this.customObjectFields.get(0).getValue();
            String fieldLabel = this.customObjectFields.get(0).getLabel();
            if (!String.isBlank(fieldName)) {
                this.recipientsMap.get(reminderIndex).add(new StringWrapper(fieldName));
            }
        }

        return null;
    }

    public PageReference removeRecipient() {
        if (this.selectedRecipientIndex != null && this.selectedRecipientIndex < this.recipientsMap.get(this.reminderIndex).size()) {
            this.recipientsMap.get(this.reminderIndex).remove(this.selectedRecipientIndex);
        }

        return null;
    }

    public void loadCustomObjectFields() {
        this.customObjectFields = new List<SelectOption>();
        this.customObjectFieldsReference = new List<SelectOption>();
        this.customObjectFieldsText = new List<SelectOption>();
        Schema.SObjectType selectedCustomObj = sObjectTypes.get(this.genericTrigger.Custom_Object__c);
        this.customObjectFieldsMap = new Map<String, Schema.SObjectField>();
        this.fieldTypes = new Map<String, String>();
        if (selectedCustomObj == null) {
            return;
        }

        Schema.DescribeSObjectResult descResultType = selectedCustomObj.getDescribe();
        this.customObjectFieldsMap = descResultType.fields.getMap();

        for (String key : customObjectFieldsMap.keySet()) {
            Schema.DescribeFieldResult objField = customObjectFieldsMap.get(key).getDescribe();
            String fType = objField.getType().name();
            if (fType == 'STRING' || fType == 'PICKLIST') {
                this.customObjectFieldsText.add(new SelectOption(objField.getName(), objField.getLabel()));
            }
            if (fType == 'STRING' || fType == 'PICKLIST' || fType == 'DATE' || fType == 'ID' || fType == 'BOOLEAN' || fType == 'EMAIL' || fType == 'DOUBLE' || fType == 'INTEGER') {
                this.customObjectFields.add(new SelectOption(objField.getName(), objField.getLabel()));
                this.fieldTypes.put(objField.getName(), objField.getType().name());
            }
            if (fType == 'REFERENCE') {
                customObjectFieldsReference.add(new SelectOption(objField.getName(), objField.getLabel()));
            }
        }
        //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'You changed custom object, all recipients and fillters was cleared.'));

        //for (Generic_Reminder__c rem : this.triggerReminders) {
        //    this.recipientsMap.get(rem.Reminder_Index__c).clear();
        //    for (Generic_Reminder_Filter__c filter : this.reminderFiltersMap.get(rem.Reminder_Index__c)) {
        //      if (!String.isEmpty(filter.Id)) {
        //          this.filtersToDelete.add(filter);
        //      }
        //    }
        //    this.reminderFiltersMap.get(rem.Reminder_Index__c).clear();
        //}
    }

    public Boolean getFieldType(String fieldName) {
        return true;
    }

    private void loadReminderFilters() {
        for (Generic_Reminder__c rem : this.triggerReminders) {
            this.reminderFiltersMap.put(rem.Reminder_Index__c, [SELECT Id, Field_Name__c, Operator__c, Value__c, Data_Type__c, Number_Value__c, Checkbox_Value__c, Date_Value__c
                                                                FROM Generic_Reminder_Filter__c WHERE Generic_Reminder__c =: rem.Id]);

            List<StringWrapper> values = new List<StringWrapper>();
            if (!String.isEmpty(rem.Recipients__c)) {
                String [] recipientsData = rem.Recipients__c.split(',');
                for (String r : recipientsData) {
                    values.add(new StringWrapper(r));
                }
            }
            this.recipientsMap.put(rem.Reminder_Index__c, values);
        }
    }

    private void loadTriggerReminders() {
        this.triggerReminders = [SELECT Id, Name, Email_Template__c, Reminder_Index__c, Recipients__c, Frequency_type__c, Week_days__c, Monthly_type__c, Numeral_monthly__c, Day_of_the_month__c, Day_of_the_week__c
                                 FROM Generic_Reminder__c WHERE Generic_Escalation_Workflow__c =: genericTriggerId ORDER BY Reminder_Index__c];
    }

    private void loadGenericTriggers() {
        this.genericTriggers = [SELECT Id, Name, Custom_Object__c, Enabled__c, Requires_Report_Field__c, Start_date__c, End_date__c
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

    public List<SelectOption> getCustomObjectFieldsText() {
        return this.customObjectFieldsText;
    }

    public List<SelectOption> getCustomObjectFieldsReference() {
        return this.customObjectFieldsReference;
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

    public Integer getSelectedRecipientIndex() {
        return this.selectedRecipientIndex;
    }

    public void setSelectedRecipientIndex(Integer val) {
        this.selectedRecipientIndex = val;
    }

    public Map<Decimal, List<StringWrapper>> getRecipientsMap() {
        return this.recipientsMap;
    }

    public void setRecipientsMap(Map<Decimal, List<StringWrapper>> rm) {
        this.recipientsMap = rm;
    }

    public List<SelectOption> getTextOperators() {
        return this.textOperators;
    }

    public List<SelectOption> getOperators() {
        return this.operators;
    }

    public List<SelectOption> getFrequencyTypes() {
        return this.frequencyTypes;
    }

    public List<SelectOption> getMonthlyTypes() {
        return this.monthlyTypes;
    }

    public List<SelectOption> getDaysNumeric() {
        return this.daysNumeric;
    }

    public List<SelectOption> getDaysOfWeek() {
        return this.daysOfWeek;
    }

    public List<SelectOption> getDayOfMonth() {
        return this.dayOfMonth;
    }

    public Map<String, String> getFieldTypes() {
        return this.fieldTypes;
    }

    public class StringWrapper {

        private String value;

        public StringWrapper() {
            this.value = '';
        }

        public StringWrapper(String v) {
            this.value = v;
        }

        public String getValue() {
            return this.value;
        }

        public void setValue(String v) {
            this.value = v;
        }
    }
}