public class ContractPipelineSnapshotScheduler implements Schedulable {

    public ContractPipelineSnapshotScheduler() {}

    public void execute(SchedulableContext sc) {
        Date currentDate = Date.today().addMonths(-1);
        Integer numberOfDays = Date.daysInMonth(currentDate.year(), currentDate.month());
        Date lastMonthSnapshotDate = Date.newInstance(currentDate.year(), currentDate.month(), numberOfDays);

        Database.executeBatch(new ContractPipelineSnapshotBatch(lastMonthSnapshotDate), 5);
    }
}