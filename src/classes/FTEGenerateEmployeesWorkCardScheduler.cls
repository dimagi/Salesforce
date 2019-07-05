/**
 * Schedules FTEUpdateTagsBatch job, then FTETimeAllocator and FTEGenerateEmployeesWorkCardBatch. First job checks situation in which FTE Tag was deleted by FB sync,
 * Second job is allocationg FTE Time by using uploaded CSV templates, the last job is calculationg work cards used by FTE Tracker Ui to increase performance.
 */
public without sharing class FTEGenerateEmployeesWorkCardScheduler implements Schedulable {

    public FTEGenerateEmployeesWorkCardScheduler() {}

    public void execute(SchedulableContext sc) {
       Database.executeBatch(new FTEUpdateTagsBatch());
    }
}