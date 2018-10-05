public without sharing class DomainMonthlySnapshotScheduler  implements Schedulable {

    public DomainMonthlySnapshotScheduler () {}

    public void execute(SchedulableContext sc) {
       Database.executeBatch(new DomainMonthlySnapshotBatch(), 1);
    }
}