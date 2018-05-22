/**
 * Schedules BatchCalculateTotalHoursOfTimeCard job for calculating Services Spend value.
 */
global without sharing class BatchCalculateTotalHoursScheduler implements Schedulable {

    public BatchCalculateTotalHoursScheduler () {}

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchRecalculateTimeCardCost(null)); // Recalculate new time cards from the past (2017-12-1), this job then runs new TimeCardCalculator job
        Database.executeBatch(new FTEUpdateTagsBatch(false)); // Move removed FTE tags
    }
}