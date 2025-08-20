public class PROEmailRemindarClearDataBatch_Scheduled implements Schedulable {
   public void execute(SchedulableContext sc) {
      PROEmailRemindarClearDataBatch b = new PROEmailRemindarClearDataBatch(); 
      Database.executeBatch(b,50);
   }
}