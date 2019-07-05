/**
 * Daily scheduled class. It should run oru daily processes, batch jobs and future methods.
 */
public class DimagiDailyScheduler implements Schedulable {

    public DimagiDailyScheduler () {}

    public void execute(SchedulableContext sc) {
        DateTime runDate = DateTime.now().addMonths(-1);
        EmployeeArchiveManager.archiveNewHistoryData(runDate);
    }
}