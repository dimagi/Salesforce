/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;

    public ScriptBatchJob() {
        this.helperDate = Date.today();
    }

    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Software_Edition__c, Software_Plan_Edition__c FROM Domain_Monthly_Snapshot__c');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        for (SObject objRec : scope) {
            Domain_Monthly_Snapshot__c domain = (Domain_Monthly_Snapshot__c) objRec;
            domain.Software_Edition__c = domain.Software_Plan_Edition__c;
        }

        if (scope.size() > 0) {
            update scope;
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}