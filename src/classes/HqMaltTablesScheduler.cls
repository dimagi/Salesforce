/**
 * HqMaltTablesScheduler schedules Malt tables calculations
 */
public class HqMaltTablesScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Date current = Date.today().addMonths(-1);
        HqBatchJobHelper.startMaltJob(current.toStartOfMonth());
    }
}