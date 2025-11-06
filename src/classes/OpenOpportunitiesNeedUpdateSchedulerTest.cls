@isTest
public class OpenOpportunitiesNeedUpdateSchedulerTest {
@isTest
    static void testSchedulerExecute() {
        OpenOpportunitiesNeedUpdateScheduler scheduler = new OpenOpportunitiesNeedUpdateScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        
    }
}