/**
 * Schedules FTEUpdateTagsBatch job, then FTERemoveNegativeHoursBatch, FTEGenerateEmployeesWorkCardBatch.
 */
public without sharing class FTEGenerateEmployeesWorkCardScheduler implements Schedulable {

    public FTEGenerateEmployeesWorkCardScheduler() {}

    public void execute(SchedulableContext sc) {
       Database.executeBatch(new FTEUpdateTagsBatch(true));
    }
}