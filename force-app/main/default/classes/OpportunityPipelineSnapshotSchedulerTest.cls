@isTest
public class OpportunityPipelineSnapshotSchedulerTest {
@isTest
    static void testSchedulerExecute() {
        OpportunityPipelineSnapshotScheduler scheduler = new OpportunityPipelineSnapshotScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        
    }
}