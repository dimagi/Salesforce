/**
 * Calculates NetDiff for Closed opps in last month (Pipeline Snapshot wasn't created).
 */
public class BatchCalculateEVDiffSch implements Schedulable {

    public BatchCalculateEVDiffSch() {}

    public void execute(SchedulableContext sc) {
        List<Pipeline_Snapshot__c> yesterdaySnapshots = [SELECT Id, Month_Date__c FROM Pipeline_Snapshot__c
            WHERE Source_Type__c = 'Opportunity' AND CreatedDate = YESTERDAY LIMIT 1];
        if (yesterdaySnapshots.size() > 0) {
            NetEVDifferenceTriggerGateway.processPriorMonthSnapshotsWithClosedStatusHistory(yesterdaySnapshots.get(0).Month_Date__c);
        }
        Database.executeBatch(new BatchCalculateEVDiff());
    }
}