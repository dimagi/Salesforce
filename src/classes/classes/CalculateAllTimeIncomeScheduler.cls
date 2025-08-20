/**
* Monthly scheduled class for updating “ID Subcontract 1 Spend” and “ID Subcontract 2 Spend” of the Contracts
**/

public class CalculateAllTimeIncomeScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new CalculateAllTimeIncomeBatch(), 100);
    }
}