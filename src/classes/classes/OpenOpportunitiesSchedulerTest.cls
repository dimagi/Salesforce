@isTest
public class OpenOpportunitiesSchedulerTest {
@isTest
    static void testSchedulerExecute() {
        OpenOpportunitiesScheduler scheduler = new OpenOpportunitiesScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        
    }
}