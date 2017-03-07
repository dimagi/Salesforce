/*
* Class responsible for scheduling (every 2nd & 4th Thursday) PROContractSnapshotBatch.
*/
global class PROContractSnapshotScheduled implements Schedulable {

    global void execute(SchedulableContext sc) {
        Date currentDate = Date.today();
        Integer currentYear = currentDate.year();
        Integer currentMonth = currentDate.month();
        List<Date> thursDayList = PROHelper.GetAllThursDayOfMonth(currentYear, currentMonth);

        if (PROHelper.IsThursDay(currentDate) && (thursDayList[1] == currentDate || thursDayList[3] == currentDate)) {
            PROContractSnapshotBatch proContractSnapshotBatch = new PROContractSnapshotBatch();
            database.executeBatch(proContractSnapshotBatch, 50);
        }
    }
}