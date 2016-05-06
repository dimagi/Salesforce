global class BatchCalculateTotalHoursScheduler implements Schedulable {

    public BatchCalculateTotalHoursScheduler  () {}

    global void execute(SchedulableContext sc) {
       Database.executeBatch(new BatchCalculateTotalHoursOfTimeCard(), 5);
    }

}