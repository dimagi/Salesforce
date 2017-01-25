public without sharing class GSRevenueCalculationScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GSRevenueCalculationBatch([SELECT Id FROM Business_Unit__c]));
    }
}