/**
 * Schedules BatchCalculateTotalHoursOfTimeCard job for calculating Services Spend value.
 */
global without sharing class BatchCalculateTotalHoursScheduler implements Schedulable {

    public BatchCalculateTotalHoursScheduler () {}

    global void execute(SchedulableContext sc) {
        AggregateResult[] lastUpdatedClients = [SELECT Client__c FROM Time_Card__c WHERE LastModifiedDate >=: DateTime.now().addDays(-8) GROUP BY Client__c];
        List<Id> clientsList = new List<Id>();
        for (AggregateResult ar : lastUpdatedClients) {
            Id contractId = (Id) ar.get('Client__c');
            if (contractId != null) {
                clientsList.add(contractId);
            }
        }

        if (clientsList.size() > 0) {
            Database.executeBatch(new BatchCalculateTotalHoursOfTimeCard(clientsList), 200);
        }
    }
}