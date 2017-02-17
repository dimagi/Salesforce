public without sharing class GSOverallCalculationScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        GSOverallCalculationBatch overallBatch = new GSOverallCalculationBatch([SELECT Id FROM Business_Unit__c]);
        Database.executeBatch(overallBatch);
    }
}