/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<Domain__c>, Database.Stateful {

    /**
     * Script code for moving Account relation to the domain custom object
     */
    public ScriptBatchJob() {
    }

    public List<Domain__c> start(Database.BatchableContext context) {
        return [SELECT Id, Account__c, Opportunity__c, Opportunity__r.AccountId FROM Domain__c WHERE Opportunity__c != '' AND Opportunity__r.AccountId != ''];
    }

    public void execute(Database.BatchableContext context, List<Domain__c> scope) {
        List<Domain__c> toUpdate = new List<Domain__c>();
        for (Domain__c hqDomain : scope) {
            if (hqDomain.Opportunity__r.AccountId != null) {
                hqDomain.Account__c = hqDomain.Opportunity__r.AccountId;
                toUpdate.add(hqDomain);
            }
        }

        if (toUpdate.size() > 0) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
    }
}