@isTest
private class GSOverallCalculationSchedulerTest {

    private class TestableScheduler extends GSOverallCalculationScheduler {
        private Date testDate;
        TestableScheduler(Date dates) {
            this.testDate = dates;
        }
        override public Date getToday() {
            return testDate;
        }
    }

    private class DummySchedulableContext implements SchedulableContext {
        public String getTriggerId() {
            return 'test';
        }
    }

    @isTest
    static void test_BeforeSecondThursday() {
        TestableScheduler scheduler = new TestableScheduler(Date.newInstance(2099, 6, 1));
        scheduler.execute(new DummySchedulableContext());
    }

    @isTest
    static void test_BetweenSecondAndFourthThursday() {
        TestableScheduler scheduler = new TestableScheduler(Date.newInstance(2099, 6, 15));
        scheduler.execute(new DummySchedulableContext());
    }

    @isTest
    static void test_AfterFourthThursday_WithBatchTrigger() {
        
        Date testDate = Date.newInstance(2099, 6, 27); 
        TestableScheduler scheduler = new TestableScheduler(testDate);

        Test.startTest();
        scheduler.execute(new DummySchedulableContext());
        Test.stopTest();
    }
}