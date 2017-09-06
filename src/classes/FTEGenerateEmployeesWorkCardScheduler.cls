/**
 * Schedules FTEGenerateEmployeesWorkCardScheduler job for calculating Domains Lifetime MRR.
 */
public without sharing class FTEGenerateEmployeesWorkCardScheduler implements Schedulable {

    public FTEGenerateEmployeesWorkCardScheduler() {}

    public void execute(SchedulableContext sc) {
       Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(Date.today().year()), 1);
    }
}