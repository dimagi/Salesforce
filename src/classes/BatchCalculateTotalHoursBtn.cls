/**
 * TODO delete
 */
public class BatchCalculateTotalHoursBtn {

    public static void executeBatch(String contractId) { 
        Database.executeBatch(new TimeCardCalculator(new Set<Id> { (Id) contractId }));
    }
}