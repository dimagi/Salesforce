@isTest
public class OpportunityFailingSalesTest {
@isTest
    static void testSchedulerExecute() {
        OpportunityFailingSalesProcessScheduler scheduler = new OpportunityFailingSalesProcessScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        
    }
}