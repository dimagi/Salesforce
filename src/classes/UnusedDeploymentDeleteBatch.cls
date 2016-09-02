/**
 * Batch job for deleting unused Deployment custom object.
 */
public class UnusedDeploymentDeleteBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, (SELECT Id FROM Domain__r) FROM Deployment__c');
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Deployment__c> unusedDepList = new List<Deployment__c>();
        for (sObject obj : scope) {
            Deployment__c dep = (Deployment__c) obj;
            if (dep.Domain__r == null || dep.Domain__r.size() == 0) {
                unusedDepList.add(dep);
            }
        }

        if (unusedDepList.size() > 0) {
            delete unusedDepList;
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}