@isTest
public class OpportunityPipelineSnapshotTest {

    @testSetup
    public static void setUpOppData() {
        Account snapShotAccount = new Account(Name = 'Test Account');
        insert snapShotAccount;
        Opportunity opp1 = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Stage 5 - Submitted', Channel_Response__c = 'Inside Sales', Amount = 50000,
                                                Expense_Income__c = 15000, Expected_Buffer__c = 50, Duration_months__c = 18, Country_Text__c = 'Sample text 1 test',
                                                Product_Text__c = 'Product test 1', CloseDate = date.today().addMonths(5), Probability = 30, AccountId = snapShotAccount.Id,
                                                Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        Opportunity opp2 = new Opportunity(Name = 'Test Opportunity 2', StageName = 'Stage 5 - Submitted', Channel_Response__c = 'Inside Sales', Amount = 70000,
                                                Expense_Income__c = 23000, Expected_Buffer__c = 40, Duration_months__c = 24, Country_Text__c = 'Sample text 2 test',
                                                Product_Text__c = 'Product test 2', CloseDate = date.today().addMonths(6), Probability = 40, AccountId = snapShotAccount.Id,
                                                Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        insert opp1;
        insert opp2;
    }

    @isTest
    public static void testPipelineSnapshotCtrl() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1'];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2'];
        Account snapShotAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Opportunity opp3 = new Opportunity(Name = 'Test Opportunity 3', StageName = 'Stage 5 - Submitted', Channel_Response__c = 'Inside Sales', Amount = 50000,
                                                Expense_Income__c = 15000, Expected_Buffer__c = 50, Duration_months__c = 18, Country_Text__c = 'Sample text 1 test',
                                                Product_Text__c = 'Product test 1', CloseDate = date.today().addMonths(5), Probability = 30, AccountId = snapShotAccount.Id,
                                                Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        Opportunity opp4 = new Opportunity(Name = 'Test Opportunity 4', StageName = 'Stage 5 - Submitted', Channel_Response__c = 'Inside Sales', Amount = 50000,
                                                Expense_Income__c = 15000, Expected_Buffer__c = 50, Duration_months__c = 18, Country_Text__c = 'Sample text 1 test',
                                                Product_Text__c = 'Product test 1', CloseDate = date.today().addMonths(5), Probability = 30, AccountId = snapShotAccount.Id,
                                                Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        insert opp3;
        insert opp4;

        Date currentDate = Date.today().addMonths(-1);
        Integer numberOfDays = Date.daysInMonth(currentDate.year(), currentDate.month());
        Date testDate = Date.newInstance(currentDate.year(), currentDate.month(), numberOfDays);

        Pipeline_Snapshot__c snapShot1 = new Pipeline_Snapshot__c(Opportunity__c = opp1.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = testDate, Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + testDate);
        insert snapShot1;
        Pipeline_Snapshot__c snapShot2 = new Pipeline_Snapshot__c(Opportunity__c = opp2.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = testDate, Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + testDate);
        insert snapShot2;
        Pipeline_Snapshot__c snapShot3 = new Pipeline_Snapshot__c(Opportunity__c = opp3.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = testDate, Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + testDate);
        insert snapShot3;
        Pipeline_Snapshot__c snapShot4 = new Pipeline_Snapshot__c(Opportunity__c = opp4.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = testDate, Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + testDate); // TO DELETE
        insert snapShot4;

        Test.startTest();
        OpportunityPipelineSnapshotController ctrl = new OpportunityPipelineSnapshotController();
        ctrl.initPipelineSnapshot();
        System.assertEquals(4, ctrl.currentPSCount);
        System.assertEquals(testDate, ctrl.lastMonthSnapshotDate);

        List<Pipeline_Snapshot__c> testResult = ctrl.getSnpList();
        System.assertEquals(4, testResult.size());
        System.assertEquals(4, ctrl.pagination.resultSize);
        System.assertEquals(10, ctrl.pagination.pageSize);
        System.assertEquals(1, ctrl.pagination.pageNumber);
        System.assertEquals(false, ctrl.pagination.hasNext);
        System.assertEquals(false, ctrl.pagination.hasPrevious);
        ctrl.runPipelineSnapshotJob();
        Test.stopTest();
        ctrl = new OpportunityPipelineSnapshotController();
        ctrl.initPipelineSnapshot();
        System.assertEquals(4, ctrl.currentPSCount);
    }

    @isTest
    public static void shouldCreatePipelineSnapshots() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1'];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2'];
        Account snapShotAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Opportunity opp3 = new Opportunity(Name = 'Test Opportunity 3', StageName = 'Stage 3 - Prospect', Channel_Response__c = 'Inside Sales', Amount = 40000,
                                                Expense_Income__c = 23000, Expected_Buffer__c = 40, Duration_months__c = 24, Country_Text__c = 'Sample text 3 test',
                                                Product_Text__c = 'Product test 3', CloseDate = date.today().addMonths(6), Probability = 35, AccountId = snapShotAccount.Id);
        insert opp3;

        Test.startTest();
        Database.executeBatch(new OpportunityPipelineSnapshotBatch(), 50);
        Test.stopTest();

        System.assertEquals(3, [SELECT Id FROM Pipeline_Snapshot__c].size());

        Pipeline_Snapshot__c psToTest = [SELECT Id, Name, Month_Date__c, Account__c, Amount__c, Amount_Minus_Expense_Income__c, Country__c, Duration_months__c,
                                        Expected_Buffer__c, Opportunity_Amount__c, CloseDate__c, Opportunity_Expense_Income__c, Probability__c, Products__c, RFP_Response__c
                                        FROM Pipeline_Snapshot__c WHERE Stage__c != 'Total' AND Opportunity__c =: opp1.Id LIMIT 1];
        assertPipelineSnapshotValues(psToTest, 'Test Opportunity 1 - ' + Date.today().month() + '/' + Date.today().year(), snapShotAccount.Id, 50000, 35000,
                                            'Sample text 1 test', 18, 50, Date.today().addMonths(5), 15000,
                                            30, 'Product test 1', 'Inside Sales');
        psToTest = [SELECT Id, Name, Month_Date__c, Account__c, Amount__c, Amount_Minus_Expense_Income__c, Country__c, Duration_months__c,
                                        Expected_Buffer__c, Opportunity_Amount__c, CloseDate__c, Opportunity_Expense_Income__c, Probability__c, Products__c, RFP_Response__c
                                        FROM Pipeline_Snapshot__c WHERE Stage__c != 'Total' AND Opportunity__c =: opp2.Id LIMIT 1];
        assertPipelineSnapshotValues(psToTest, 'Test Opportunity 2 - ' + Date.today().month() + '/' + Date.today().year(), snapShotAccount.Id, 70000, 47000,
                                            'Sample text 2 test', 24, 40, Date.today().addMonths(6), 23000,
                                            40, 'Product test 2', 'Inside Sales');
        psToTest = [SELECT Id, Name, Month_Date__c, Account__c, Amount__c, Amount_Minus_Expense_Income__c, Country__c, Duration_months__c,
                                        Expected_Buffer__c, Opportunity_Amount__c, CloseDate__c, Opportunity_Expense_Income__c, Probability__c, Products__c, RFP_Response__c
                                        FROM Pipeline_Snapshot__c WHERE Stage__c != 'Total' AND Opportunity__c =: opp3.Id LIMIT 1];
        assertPipelineSnapshotValues(psToTest, 'Test Opportunity 3 - ' + Date.today().month() + '/' + Date.today().year(), snapShotAccount.Id, 40000, 17000,
                                            'Sample text 3 test', 24, 40, Date.today().addMonths(6), 23000,
                                            35, 'Product test 3', 'Inside Sales');
    }

    @isTest
    public static void shouldRemoveOnlyThisMonthPipelineSnapshotsAndEVDiffs() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1'];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2'];
        Account snapShotAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];

        // Opp 1
        Pipeline_Snapshot__c snapShot1 = new Pipeline_Snapshot__c(Opportunity__c = opp1.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = Date.today().addMonths(-3), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 1, 12));
        insert snapShot1;
        Pipeline_Snapshot__c snapShot2 = new Pipeline_Snapshot__c(Opportunity__c = opp1.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = Date.today().addMonths(-2), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 1, 12));
        insert snapShot2;
        Pipeline_Snapshot__c snapShot3 = new Pipeline_Snapshot__c(Opportunity__c = opp1.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = Date.today().addMonths(-1), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 1, 12));
        insert snapShot3;
        Pipeline_Snapshot__c snapShot4 = new Pipeline_Snapshot__c(Opportunity__c = opp1.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = Date.today(), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 1, 12)); // TO DELETE
        insert snapShot4;

        // Opp 2
        Pipeline_Snapshot__c snapShot5 = new Pipeline_Snapshot__c(Opportunity__c = opp2.Id, Opportunity_Amount_Minus_Expense_Income__c = 2200,
                                                                                Amount_Minus_Expense_Income__c = 4000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = Date.today().addMonths(-2), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 2, 10));
        insert snapShot5;
        Pipeline_Snapshot__c snapShot6 = new Pipeline_Snapshot__c(Opportunity__c = opp2.Id, Opportunity_Amount_Minus_Expense_Income__c = 2200,
                                                                                Amount_Minus_Expense_Income__c = 4000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = Date.today().addMonths(-1), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 2, 10));
        insert snapShot6;
        Pipeline_Snapshot__c snapShot7 = new Pipeline_Snapshot__c(Opportunity__c = opp2.Id, Opportunity_Amount_Minus_Expense_Income__c = 1900,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = snapShotAccount.Id, Month_Date__c = Date.today(), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 3, 7)); // TO DELETE
        insert snapShot7;

        // we must generate EV Diffs for records to check what was deleted by batch job
        Test.startTest();
        NetEVDifferenceTriggerGateway helper = new NetEVDifferenceTriggerGateway();
        helper.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot1 });
        helper.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot2, snapShot5 });
        helper.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot3, snapShot6 });
        helper.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot4, snapShot7});

        List<Pipeline_Snapshot_EV_DIff__c> evDiffs = [SELECT Id FROM Pipeline_Snapshot_EV_DIff__c];
        System.assertEquals(7, evDiffs.size());
        Database.executeBatch(new OpportunityPipelineSnapshotBatch(), 50);
        Test.stopTest();

        System.assert([SELECT Id FROM Pipeline_Snapshot__c WHERE Id =: snapShot1.Id].size() == 1);
        System.assert([SELECT Id FROM Pipeline_Snapshot__c WHERE Id =: snapShot2.Id].size() == 1);
        System.assert([SELECT Id FROM Pipeline_Snapshot__c WHERE Id =: snapShot3.Id].size() == 1);
        System.assert([SELECT Id FROM Pipeline_Snapshot__c WHERE Id =: snapShot4.Id].size() == 0);
        System.assert([SELECT Id FROM Pipeline_Snapshot__c WHERE Id =: snapShot5.Id].size() == 1);
        System.assert([SELECT Id FROM Pipeline_Snapshot__c WHERE Id =: snapShot6.Id].size() == 1);
        System.assert([SELECT Id FROM Pipeline_Snapshot__c WHERE Id =: snapShot7.Id].size() == 0);
        System.assertEquals(7, [SELECT Id FROM Pipeline_Snapshot__c].size()); // was 7, 2 was deleted and 2 was created(2 with total stage)
        System.assertEquals(7, [SELECT Id FROM Pipeline_Snapshot_EV_DIff__c].size());
        System.assertEquals(5, [SELECT Id FROM Pipeline_Snapshot_EV_DIff__c WHERE Id IN: evDiffs].size()); // w from this list was deleted
    }

    @isTest
    public static void shouldCalculateForPeriodInPipelineSnapshotOpp() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1'];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2'];
        Account snapShotAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Pipeline_Snapshot__c ps1 = new Pipeline_Snapshot__c(Source_Type__c = 'Opportunity', Month_Date__c = Date.today().addMonths(-1), Opportunity__c = opp1.Id,
                                                            Probability__c = 20, Expected_Buffer__c = 60, Amount_Minus_Expense_Income__c = 10000);
        // Buffer EV: 60% * (10000 * 20%) = 60% * 2000 = 1200
        insert ps1;

        Test.setCreatedDate(ps1.Id, DateTime.now().addDays(-30));
        Test.startTest();
        Database.executeBatch(new OpportunityPipelineSnapshotBatch(), 50);
        Test.stopTest();

        Pipeline_Snapshot__c psFromDB = [SELECT Id, Probability__c, Expected_Buffer__c, Amount_Minus_Expense_Income__c, Buffer_EV_for_Period__c
                                         FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp1.Id AND Month_Date__c =: Date.today() AND Stage__c != 'Total' LIMIT 1];
        System.debug('Value : ' + psFromDB.Expected_Buffer__c * (psFromDB.Amount_Minus_Expense_Income__c * psFromDB.Probability__c));
        System.assertEquals(5250 - 1200, psFromDB.Buffer_EV_for_Period__c);
        psFromDB = [SELECT Id, Buffer_EV_for_Period__c FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp2.Id AND Stage__c != 'Total' LIMIT 1];
        System.assertEquals(7520, psFromDB.Buffer_EV_for_Period__c);
    }

    @isTest
    public static void testEvDiffForSingleRecord() {
        Account snapShotAccount = new Account(Name = 'Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name = 'Test Funder Account');
        insert funderAccount;
        Business_Unit__c bizUnit = new Business_Unit__c(Name = 'Test Business Unit 1');
        Opportunity currentOpp = new Opportunity(Name = 'Test Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        insert currentOpp;

        Pipeline_Snapshot__c snapShot1 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp.Id, Opportunity_Amount_Minus_Expense_Income__c = 2000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 1, 12), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 1, 12));

        insert snapShot1;
        Pipeline_Snapshot__c snapShot2 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp.Id, Opportunity_Amount_Minus_Expense_Income__c = 2200,
                                                                                Amount_Minus_Expense_Income__c = 4000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 2, 10), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 2, 10));
        insert snapShot2;
        Pipeline_Snapshot__c snapShot3 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp.Id, Opportunity_Amount_Minus_Expense_Income__c = 1900,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 3, 7), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 3, 7));
        insert snapShot3;

        currentOpp.StageName = 'Closed - Won';
        update currentOpp;

        Test.startTest();
        snapShot1.recalculateFormulas();
        snapShot2.recalculateFormulas();
        snapShot3.recalculateFormulas();
        NetEVDifferenceTriggerGateway gateway = new NetEVDifferenceTriggerGateway();
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot1 });
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot2 });
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot3 });
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot3 });

        NetEVDifferenceTriggerGateway.processPriorMonthSnapshotsWithClosedStatus(Date.newInstance(2016, 4, 14));
        Test.stopTest();

        List<Pipeline_Snapshot_EV_DIff__c> allRecords = [SELECT Opportunity_Name__c, Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c,
                                                                 DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c,
                                                                 Month_Date__c FROM Pipeline_Snapshot_EV_DIff__c ORDER BY Month_Date__c ASC];
        for (Pipeline_Snapshot_EV_DIff__c snp : allRecords) {
            System.debug('snp : ' + snp.Opportunity_Name__c + ' - ' + snp.Delta_Type__c +' date : ' + snp.Month_Date__c);
        }
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [SELECT Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c,
                                                                 DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c,
                                                                Month_Date__c, Opportunity_Name__c FROM Pipeline_Snapshot_EV_DIff__c ORDER BY Month_Date__c ASC];
        System.debug('snapShotsEVDiffAll: ' + snapShotsEVDiffAll);
        System.assert(snapShotsEVDiffAll.size() == 4);

        System.assertEquals(NetEVDifferenceTriggerGateway.NEW_OPP , snapShotsEVDiffAll.get(0).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.INCREASED , snapShotsEVDiffAll.get(1).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.DECREASED , snapShotsEVDiffAll.get(2).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.WON , snapShotsEVDiffAll.get(3).Delta_Type__c);
        System.assertEquals(Date.newInstance(2016, 4, 30) , snapShotsEVDiffAll.get(3).Month_Date__c);
    }

    @isTest
    public static void testEvDiffForMultipleRecords() {
        Account snapShotAccount = new Account(Name = 'Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name = 'Test Funder Account');
        insert funderAccount;
        Business_Unit__c bizUnit = new Business_Unit__c(Name = 'Test Business Unit 1');
        Opportunity currentOpp1 = new Opportunity(Name = 'Test Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        Opportunity currentOpp2 = new Opportunity(Name = 'Test Opportunity 2', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        Opportunity currentOpp3 = new Opportunity(Name = 'Test Opportunity 3', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        insert currentOpp1;
        insert currentOpp2;
        insert currentOpp3;

        Pipeline_Snapshot__c snapShot1_1 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp1.Id, Opportunity_Amount_Minus_Expense_Income__c = 2200,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 1, 12), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 1, 31));
        Pipeline_Snapshot__c snapShot1_2 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp2.Id, Opportunity_Amount_Minus_Expense_Income__c = 2200,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 1, 12), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 1, 22));
        Pipeline_Snapshot__c snapShot1_3 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp3.Id, Opportunity_Amount_Minus_Expense_Income__c = 2200,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 1, 12), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 1, 11));

        List<Pipeline_Snapshot__c> snapshots_1 = new List<Pipeline_Snapshot__c>();
        snapshots_1.add(snapShot1_1);
        snapshots_1.add(snapShot1_2);
        snapshots_1.add(snapShot1_3);
        insert snapshots_1;

        Pipeline_Snapshot__c snapShot2_1 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp1.Id, Opportunity_Amount_Minus_Expense_Income__c = 1000,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 45, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 2, 10), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 2, 10));
        Pipeline_Snapshot__c snapShot2_2 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp2.Id, Opportunity_Amount_Minus_Expense_Income__c = 2200,
                                                                                Amount_Minus_Expense_Income__c = 2000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 2, 10), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 2, 10));
        Pipeline_Snapshot__c snapShot2_3 = new Pipeline_Snapshot__c(Opportunity__c = currentOpp3.Id, Opportunity_Amount_Minus_Expense_Income__c = 2400,
                                                                                Amount_Minus_Expense_Income__c = 4000, Probability__c = 100, Opportunity_Amount__c = 2000,
                                                                                Amount__c = 2000, Account__c = snapShotAccount.Id, Country__c = 'Test Country', Duration_months__c = 4,
                                                                                Funder_Account__c = funderAccount.Id, Month_Date__c = Date.newInstance(2016, 2, 10), Source_Type__c = 'Opportunity',
                                                                                Name = 'Test PS for date  ' + Date.newInstance(2016, 2, 10));

        List<Pipeline_Snapshot__c> snapshots_2 = new List<Pipeline_Snapshot__c>();
        snapshots_2.add(snapShot2_1);
        snapshots_2.add(snapShot2_2);
        snapshots_2.add(snapShot2_3);
        insert snapshots_2;

        currentOpp1.StageName = 'Closed - Lost';
        update currentOpp1;
        currentOpp2.StageName = 'Closed - Won';
        update currentOpp2;
        currentOpp3.StageName = 'Closed';
        update currentOpp3;

        Test.startTest();
        snapShot1_1.recalculateFormulas();
        snapShot1_2.recalculateFormulas();
        snapShot1_3.recalculateFormulas();
        snapShot2_1.recalculateFormulas();
        snapShot2_2.recalculateFormulas();
        snapShot2_3.recalculateFormulas();
        NetEVDifferenceTriggerGateway gateway = new NetEVDifferenceTriggerGateway();
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot1_1, snapShot1_2, snapShot1_3 });
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot2_1, snapShot2_2, snapShot2_3 });
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot1_1, snapShot1_2, snapShot1_3 });
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot1_1, snapShot1_2, snapShot1_3 });
        gateway.processLastMonthSnapshots(new List<Pipeline_Snapshot__c> { snapShot2_1, snapShot2_2, snapShot2_3 });
        NetEVDifferenceTriggerGateway.processPriorMonthSnapshotsWithClosedStatus(Date.newInstance(2016, 3, 25));
        NetEVDifferenceTriggerGateway.processPriorMonthSnapshotsWithClosedStatus(Date.newInstance(2016, 3, 25));
        NetEVDifferenceTriggerGateway.processPriorMonthSnapshotsWithClosedStatus(Date.newInstance(2016, 3, 25));
        Test.stopTest();

        List<Pipeline_Snapshot_EV_DIff__c> allRecords = [SELECT Opportunity_Name__c, Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c,
                                                                 DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c,
                                                                 Month_Date__c FROM Pipeline_Snapshot_EV_DIff__c ORDER BY Month_Date__c ASC];
        for (Pipeline_Snapshot_EV_DIff__c snp : allRecords) {
            System.debug('snp : ' + snp.Opportunity_Name__c + ' - ' + snp.Delta_Type__c +' date : ' + snp.Month_Date__c);
        }
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [SELECT Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c,
                                                                 DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c,
                                                                 Month_Date__c, Opportunity_Name__c FROM Pipeline_Snapshot_EV_DIff__c
                                                                 WHERE Opportunity__c =: currentOpp1.Id ORDER BY Month_Date__c ASC];

        System.assert(snapShotsEVDiffAll.size() == 3);
        System.assertEquals(NetEVDifferenceTriggerGateway.NEW_OPP , snapShotsEVDiffAll.get(0).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.DECREASED , snapShotsEVDiffAll.get(1).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.LOST , snapShotsEVDiffAll.get(2).Delta_Type__c);
        System.assertEquals(Date.newInstance(2016, 3, 31) , snapShotsEVDiffAll.get(2).Month_Date__c);

        snapShotsEVDiffAll = [SELECT Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c,
                                                                 DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c,
                                                                 Month_Date__c, Opportunity_Name__c FROM Pipeline_Snapshot_EV_DIff__c
                                                                 WHERE Opportunity__c =: currentOpp2.Id ORDER BY Month_Date__c ASC];

        System.assert(snapShotsEVDiffAll.size() == 3);
        System.assertEquals(NetEVDifferenceTriggerGateway.NEW_OPP , snapShotsEVDiffAll.get(0).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.NO_CHANGE , snapShotsEVDiffAll.get(1).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.WON , snapShotsEVDiffAll.get(2).Delta_Type__c);
        System.assertEquals(Date.newInstance(2016, 3, 31) , snapShotsEVDiffAll.get(2).Month_Date__c);

        snapShotsEVDiffAll = [SELECT Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c,
                                                                 DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c,
                                                                 Month_Date__c, Opportunity_Name__c FROM Pipeline_Snapshot_EV_DIff__c
                                                                 WHERE Opportunity__c =: currentOpp3.Id ORDER BY Month_Date__c ASC];

        System.assert(snapShotsEVDiffAll.size() == 3);
        System.assertEquals(NetEVDifferenceTriggerGateway.NEW_OPP , snapShotsEVDiffAll.get(0).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.INCREASED , snapShotsEVDiffAll.get(1).Delta_Type__c);
        System.assertEquals(NetEVDifferenceTriggerGateway.LOST , snapShotsEVDiffAll.get(2).Delta_Type__c);
        System.assertEquals(Date.newInstance(2016, 3, 31) , snapShotsEVDiffAll.get(2).Month_Date__c);
    }

    @isTest
    public static void shouldCalculateIsSubmittedThisMonth() {
        Opportunity opp1 = new Opportunity(Name = 'Test Opportunity 1', StageName = 'Stage 5 - Submitted',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        Opportunity opp2 = new Opportunity(Name = 'Test Opportunity 2', StageName = 'Stage 5 - Submitted',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        Opportunity opp3 = new Opportunity(Name = 'Test Opportunity 3', StageName = 'Stage 5 - Submitted',
                                                 CloseDate = date.today().addMonths(5), Probability = 30,
                                                 Opportunity_Owner_Division__c = 'Solutions', Opportunity_Owner_Sub_Division__c = 'Inbound Sales');
        insert new List<Opportunity> { opp1, opp2, opp3 };

        Integer testYear = Date.today().year() - 1;
        // Opp 1
        Pipeline_Snapshot__c ps1 = new Pipeline_Snapshot__c(Stage__c = 'Stage 5 - Submitted', Opportunity__c = opp1.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 10, 31), Name = 'Test 1' + Date.newInstance(testYear, 10, 31));
        Pipeline_Snapshot__c ps2 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp1.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 11, 30), Name = 'Test 2' + Date.newInstance(testYear, 11, 30));
        Pipeline_Snapshot__c ps3 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp1.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 12, 31), Name = 'Test 3' + Date.newInstance(testYear, 12, 31));
        Pipeline_Snapshot__c ps4 = new Pipeline_Snapshot__c(Stage__c = 'Stage 5 - Submitted', Opportunity__c = opp1.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear + 1, 1, 31), Name = 'Test 4' + Date.newInstance(testYear + 1, 1, 31));
        // Opp 2
        Pipeline_Snapshot__c ps5 = new Pipeline_Snapshot__c(Stage__c = 'Stage 1 - Connect', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 3, 31), Name = 'Test 5' + Date.newInstance(testYear, 3, 31));
        Pipeline_Snapshot__c ps6 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 4, 30), Name = 'Test 6' + Date.newInstance(testYear, 4, 30));
        Pipeline_Snapshot__c ps7 = new Pipeline_Snapshot__c(Stage__c = 'Stage 5 - Submitted', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 5, 31), Name = 'Test 7' + Date.newInstance(testYear, 5, 31));
        Pipeline_Snapshot__c ps8 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 6, 30), Name = 'Test 8' + Date.newInstance(testYear, 6, 30));
        Pipeline_Snapshot__c ps9 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 7, 31), Name = 'Test 9' + Date.newInstance(testYear, 7, 31));
        // Opp 3
        Pipeline_Snapshot__c ps10 = new Pipeline_Snapshot__c(Stage__c = 'Stage 3 - Prospect', Opportunity__c = opp3.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 4, 30), Name = 'Test 10' + Date.newInstance(testYear, 4, 30));
        Pipeline_Snapshot__c ps11 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp3.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 5, 31), Name = 'Test 11' + Date.newInstance(testYear, 5, 31));
        Pipeline_Snapshot__c ps12 = new Pipeline_Snapshot__c(Stage__c = 'Stage 5 - Submitted', Opportunity__c = opp3.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 6, 30), Name = 'Test 12' + Date.newInstance(testYear, 6, 30));
        Pipeline_Snapshot__c ps13 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp3.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 7, 31), Name = 'Test 13' + Date.newInstance(testYear, 7, 31));
        Pipeline_Snapshot__c ps14 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp3.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 8, 31), Name = 'Test 14' + Date.newInstance(testYear, 8, 31));
        Pipeline_Snapshot__c ps15 = new Pipeline_Snapshot__c(Stage__c = 'Stage 5 - Submitted', Opportunity__c = opp3.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 9, 30), Name = 'Test 15' + Date.newInstance(testYear, 9, 30));
        Pipeline_Snapshot__c ps16 = new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp3.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 10, 31), Name = 'Test 16' + Date.newInstance(testYear, 10, 31));

        insert new List<Pipeline_Snapshot__c> { ps1, ps2, ps3, ps4, ps5, ps6, ps7, ps8, ps9, ps10, ps11, ps12, ps13, ps14, ps15, ps16 };

        // Opp 1
        System.assertEquals('Yes', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps1));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps2));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps3));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps4));
        // Opp 2
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps5));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps6));
        System.assertEquals('Yes', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps7));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps8));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps9));
        // Opp 3
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps10));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps11));
        System.assertEquals('Yes', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps12));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps13));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps14));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps15));
        System.assertEquals('No', OpportunityPipelineSnapshotBatch.isSubmittedThisMonth(ps16));
    }

    @isTest
    public static void shouldSetSubmittedThisMonth1() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];

        Integer testYear = Date.today().year() - 1;
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 1 - Connect', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 3, 31), Name = 'Test 5' + Date.newInstance(testYear, 3, 31));
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 4, 30), Name = 'Test 6' + Date.newInstance(testYear, 4, 30));
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 5 - Submitted', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 5, 31), Name = 'Test 7' + Date.newInstance(testYear, 5, 31));
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 6, 30), Name = 'Test 8' + Date.newInstance(testYear, 6, 30));
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 7, 31), Name = 'Test 9' + Date.newInstance(testYear, 7, 31));

        Test.startTest();
        Database.executeBatch(new OpportunityPipelineSnapshotBatch(Date.newInstance(testYear, 8, 31)));
        Test.stopTest();

        System.assertEquals(7, [SELECT count() FROM Pipeline_Snapshot__c]);
        System.assertEquals(1, [SELECT count() FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp1.Id]);
        System.assertEquals('Yes', [SELECT Submitted_this_month__c FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp1.Id LIMIT 1].Submitted_this_month__c);
        System.assertEquals(6, [SELECT count() FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp2.Id]);
        System.assertEquals('No', [SELECT Submitted_this_month__c FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp2.Id AND Month_Date__c =: Date.newInstance(testYear, 8, 31) LIMIT 1].Submitted_this_month__c);
    }

    @isTest
    public static void shouldSetSubmittedThisMonth2() {
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];

        Integer testYear = Date.today().year() - 1;
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 5 - Submitted', Opportunity__c = opp1.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 6, 30), Name = 'Test 8' + Date.newInstance(testYear, 6, 30));
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp1.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 7, 31), Name = 'Test 9' + Date.newInstance(testYear, 7, 31));

        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 4, 30), Name = 'Test 6' + Date.newInstance(testYear, 4, 30));
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 5, 31), Name = 'Test 7' + Date.newInstance(testYear, 5, 31));
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 6, 30), Name = 'Test 8' + Date.newInstance(testYear, 6, 30));
        insert new Pipeline_Snapshot__c(Stage__c = 'Stage 4 - Proposal Development', Opportunity__c = opp2.Id, Source_Type__c = 'Opportunity', Month_Date__c = Date.newInstance(testYear, 7, 31), Name = 'Test 9' + Date.newInstance(testYear, 7, 31));

        Test.startTest();
        Database.executeBatch(new OpportunityPipelineSnapshotBatch(Date.newInstance(testYear, 8, 31)));
        Test.stopTest();

        System.assertEquals(8, [SELECT count() FROM Pipeline_Snapshot__c]);
        System.assertEquals(3, [SELECT count() FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp1.Id]);
        System.assertEquals('No', [SELECT Submitted_this_month__c FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp1.Id AND Month_Date__c =: Date.newInstance(testYear, 8, 31) LIMIT 1].Submitted_this_month__c);
        System.assertEquals(5, [SELECT count() FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp2.Id]);
        System.assertEquals('Yes', [SELECT Submitted_this_month__c FROM Pipeline_Snapshot__c WHERE Opportunity__c =: opp2.Id AND Month_Date__c =: Date.newInstance(testYear, 8, 31) LIMIT 1].Submitted_this_month__c);
    }

    private static void assertPipelineSnapshotValues(Pipeline_Snapshot__c psToTest, String expectedName, Id expectedAccount, Decimal expectedAmount, Decimal expectedAmountMinus,
                                            String expectedCountry, Integer expectedDuration, Decimal expectedBuffer, Date expectedCloseDate, Decimal expectedExpense,
                                            Decimal expectedProbability, String expectedProduct, String expectedChannel) {
        System.assertEquals(expectedName, psToTest.Name);
        System.assertEquals(Date.today(), psToTest.Month_Date__c);
        System.assertEquals(expectedAccount, psToTest.Account__c);
        System.assertEquals(expectedAmount, psToTest.Amount__c);
        System.assertEquals(expectedAmountMinus, psToTest.Amount_Minus_Expense_Income__c);
        System.assertEquals(expectedCountry, psToTest.Country__c);
        System.assertEquals(expectedDuration, psToTest.Duration_months__c);
        System.assertEquals(expectedBuffer, psToTest.Expected_Buffer__c);
        System.assertEquals(expectedAmount, psToTest.Opportunity_Amount__c);
        System.assertEquals(expectedCloseDate, psToTest.CloseDate__c);
        System.assertEquals(expectedExpense, psToTest.Opportunity_Expense_Income__c);
        System.assertEquals(expectedProbability, psToTest.Probability__c);
        System.assertEquals(expectedProduct, psToTest.Products__c);
        System.assertEquals(expectedChannel, psToTest.RFP_Response__c);
    }
}