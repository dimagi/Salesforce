@isTest
public class LeadQualifyProcessSchedulerTest {

    @isTest
    static void testSchedulerExecute() {
        LeadQualifyProcessScheduler scheduler = new LeadQualifyProcessScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        
    }
}