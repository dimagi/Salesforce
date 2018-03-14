/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<Domain__c>, Database.Stateful {

    /**
     * Script code for moving data to second sied of the relation before deleting field in domain custom object
     */
    public ScriptBatchJob() {
    }

    public List<Domain__c> start(Database.BatchableContext context) {
        return [SELECT Id, Opportunity__c FROM Domain__c WHERE Opportunity__c != ''];
    }

    public void execute(Database.BatchableContext context, List<Domain__c> scope) {
        Set<Id> oppsSet = new Set<Id>();
        for (Domain__c hqDomain : scope) {
            oppsSet.add(hqDomain.Opportunity__c);
        }
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity> ([SELECT Id, Domain_Name__c FROM Opportunity WHERE Id IN: oppsSet]);

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Domain__c hqDomain : scope) {
            if (oppsMap.containsKey(hqDomain.Opportunity__c)) {
                Opportunity opp = oppsMap.get(hqDomain.Opportunity__c);
                opp.Domain_Name__c = hqDomain.Id;
                oppsToUpdate.add(opp);
            }
        }

        if (oppsToUpdate.size() > 0) {
            update oppsToUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
    }
}