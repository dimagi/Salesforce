/**
 * Job for Generic Escalation Workflow logic.
 */
global class GenericEscalationWorkflowBatch implements Database.Batchable<Generic_Escalation_Workflow__c> {

    global List<Generic_Escalation_Workflow__c> start(Database.BatchableContext context) {
       return getGenericEscalationWorkflow();
    }

    global void execute(Database.BatchableContext context, List<Generic_Escalation_Workflow__c> contracts) {
        
    }

    global void finish(Database.BatchableContext context) {
        
    }

    private List<Generic_Escalation_Workflow__c> getGenericEscalationWorkflow() {
        List<Generic_Escalation_Workflow__c> triggers = [SELECT Id, Name, Custom_Object__c FROM Generic_Escalation_Workflow__c WHERE Enabled__c = true];
        return triggers;
    }
}