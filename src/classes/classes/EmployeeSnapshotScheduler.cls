public without sharing class EmployeeSnapshotScheduler implements Schedulable {

    public EmployeeSnapshotScheduler () {}

    public void execute(SchedulableContext sc) {
       Database.executeBatch(new EmployeeSnapshotBatch(), 1);
    }
}