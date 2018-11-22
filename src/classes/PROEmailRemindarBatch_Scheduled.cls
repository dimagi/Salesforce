public class PROEmailRemindarBatch_Scheduled implements Schedulable {
   public void execute(SchedulableContext sc) {
      PROEmailRemindarBatch b = new PROEmailRemindarBatch(); 
      database.executebatch(b, 20);
   }
}