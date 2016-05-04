@isTest
public class BatchCalculateEVDiffTest {
    
    @isTest
    public static void TestWithSingleRecordForNewOpp()
    {
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = new Opportunity(Name='Test Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted', CloseDate = date.today().addMonths(5), Probability = 30);
        insert currentOpp;
        
        Pipeline_Snapshot__c snapShotForCurrentMonth = new Pipeline_Snapshot__c();
        snapShotForCurrentMonth.Opportunity__c = currentOpp.Id;
        snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 2000;
        snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 2000;
        snapShotForCurrentMonth.Probability__c = 30;
        snapShotForCurrentMonth.Opportunity_Amount__c = 2000;
        snapShotForCurrentMonth.Amount__c = 2000;
        snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
        snapShotForCurrentMonth.Country__c = 'Test Country';
        snapShotForCurrentMonth.Duration_months__c = 4;
        snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
        snapShotForCurrentMonth.Month_Date__c = date.today();
        snapShotForCurrentMonth.Name = 'Test PS for date  ' + snapShotForCurrentMonth.Month_Date__c;
        
        Pipeline_Snapshot__c snapShotForPriorMonth = new Pipeline_Snapshot__c();
        snapShotForPriorMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorMonth.Probability__c = 30;
        snapShotForPriorMonth.Opportunity_Amount__c = 2000;
        snapShotForPriorMonth.Amount__c = 2000;
        snapShotForPriorMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorMonth.Country__c = 'Test Country';
        snapShotForPriorMonth.Duration_months__c = 4;
        snapShotForPriorMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorMonth.Month_Date__c = date.today().addMonths(-1);
        snapShotForPriorMonth.Name = 'Test PS for date  ' + snapShotForPriorMonth.Month_Date__c;
        
        Test.startTest();
        insert snapShotForPriorMonth;
        insert snapShotForCurrentMonth;
        ExecuteForCurrentMonth(system.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 1);
        
        //test case New Opp EV
        Pipeline_Snapshot_EV_DIff__c snapShotEVDiff = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'New Opp EV' limit 1];
        System.assert(snapShotEVDiff != null);
    }
    
    @isTest
    public static void TestWithSingleRecordForIncreasedEV()
    {
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = new Opportunity(Name='Test Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted', CloseDate = date.today().addMonths(5), Probability = 30);
        insert currentOpp;
        
        //List<Pipeline_Snapshot__c> pipelineSnapShots = new List<Pipeline_Snapshot__c>();
        Pipeline_Snapshot__c snapShotForCurrentMonth = new Pipeline_Snapshot__c();
        snapShotForCurrentMonth.Opportunity__c = currentOpp.Id;
        snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 2000;
        snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 2000;
        snapShotForCurrentMonth.Probability__c = 90;
        snapShotForCurrentMonth.Opportunity_Amount__c = 2000;
        snapShotForCurrentMonth.Amount__c = 2000;
        snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
        snapShotForCurrentMonth.Country__c = 'Test Country';
        snapShotForCurrentMonth.Duration_months__c = 4;
        snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
        snapShotForCurrentMonth.Month_Date__c = date.today();
        snapShotForCurrentMonth.Name = 'Test PS for date  ' + snapShotForCurrentMonth.Month_Date__c;
        
        Pipeline_Snapshot__c snapShotForPriorMonth = new Pipeline_Snapshot__c();
        snapShotForPriorMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorMonth.Probability__c = 2;
        snapShotForPriorMonth.Opportunity_Amount__c = 200;
        snapShotForPriorMonth.Amount__c = 200;
        snapShotForPriorMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorMonth.Country__c = 'Test Country';
        snapShotForPriorMonth.Duration_months__c = 4;
        snapShotForPriorMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorMonth.Month_Date__c = date.today().addMonths(-1);
        snapShotForPriorMonth.Name = 'Test PS for date  ' + snapShotForPriorMonth.Month_Date__c;
        
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
        snapShotForPriorToLastMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Probability__c = 30;
        snapShotForPriorToLastMonth.Opportunity_Amount__c = 2000;
        snapShotForPriorToLastMonth.Amount__c = 2000;
        snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorToLastMonth.Country__c = 'Test Country';
        snapShotForPriorToLastMonth.Duration_months__c = 4;
        snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
        snapShotForPriorToLastMonth.Name = 'Test PS for date  ' + snapShotForPriorToLastMonth.Month_Date__c;
        
        Date dateVal = date.today();
        Test.startTest();
        insert snapShotForPriorMonth;
        insert snapShotForPriorToLastMonth;
        insert snapShotForCurrentMonth;
        ExecuteForCurrentMonth(system.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 1);
        
        //test case Increased EV
        Pipeline_Snapshot_EV_DIff__c snapShotEVDiff = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'Increased EV' limit 1];
        System.assert(snapShotEVDiff != null);
    }
    
    @isTest
    public static void TestWithSingleRecordForDecreasedEV()
    {
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = new Opportunity(Name='Test Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted', CloseDate = date.today().addMonths(5), Probability = 30);
        insert currentOpp;
        
        //List<Pipeline_Snapshot__c> pipelineSnapShots = new List<Pipeline_Snapshot__c>();
        Pipeline_Snapshot__c snapShotForCurrentMonth = new Pipeline_Snapshot__c();
        snapShotForCurrentMonth.Opportunity__c = currentOpp.Id;
        snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForCurrentMonth.Probability__c = 30;
        snapShotForCurrentMonth.Opportunity_Amount__c = 200;
        snapShotForCurrentMonth.Amount__c = 2000;
        snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
        snapShotForCurrentMonth.Country__c = 'Test Country';
        snapShotForCurrentMonth.Duration_months__c = 4;
        snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
        snapShotForCurrentMonth.Month_Date__c = date.today();
        snapShotForCurrentMonth.Name = 'Test PS for date  ' + snapShotForCurrentMonth.Month_Date__c;
        
        Pipeline_Snapshot__c snapShotForPriorMonth = new Pipeline_Snapshot__c();
        snapShotForPriorMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorMonth.Opportunity_Amount_Minus_Expense_Income__c = 2000;
        snapShotForPriorMonth.Amount_Minus_Expense_Income__c = 2000;
        snapShotForPriorMonth.Probability__c = 90;
        snapShotForPriorMonth.Opportunity_Amount__c = 2000;
        snapShotForPriorMonth.Amount__c = 200;
        snapShotForPriorMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorMonth.Country__c = 'Test Country';
        snapShotForPriorMonth.Duration_months__c = 4;
        snapShotForPriorMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorMonth.Month_Date__c = date.today().addMonths(-1);
        snapShotForPriorMonth.Name = 'Test PS for date  ' + snapShotForPriorMonth.Month_Date__c;
        
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
        snapShotForPriorToLastMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Probability__c = 30;
        snapShotForPriorToLastMonth.Opportunity_Amount__c = 2000;
        snapShotForPriorToLastMonth.Amount__c = 2000;
        snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorToLastMonth.Country__c = 'Test Country';
        snapShotForPriorToLastMonth.Duration_months__c = 4;
        snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
        snapShotForPriorToLastMonth.Name = 'Test PS for date  ' + snapShotForPriorToLastMonth.Month_Date__c;
        
        //pipelineSnapShots.add(snapShot);
        Test.startTest();
        insert snapShotForPriorMonth;
        insert snapShotForPriorToLastMonth;
        insert snapShotForCurrentMonth;
        ExecuteForCurrentMonth(date.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 1);
        
        //test case Decreased EV
        Pipeline_Snapshot_EV_DIff__c snapShotEVDiff = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'Decreased EV' limit 1];
        System.assert(snapShotEVDiff != null);
    }
    
    @isTest
    public static void TestWithSingleRecordForNoChange()
    {
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = new Opportunity(Name='Test Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted', CloseDate = date.today().addMonths(5), Probability = 30);
        insert currentOpp;
        
        //List<Pipeline_Snapshot__c> pipelineSnapShots = new List<Pipeline_Snapshot__c>();
        Pipeline_Snapshot__c snapShotForCurrentMonth = new Pipeline_Snapshot__c();
        snapShotForCurrentMonth.Opportunity__c = currentOpp.Id;
        snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForCurrentMonth.Probability__c = 30;
        snapShotForCurrentMonth.Opportunity_Amount__c = 200;
        snapShotForCurrentMonth.Amount__c = 2000;
        snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
        snapShotForCurrentMonth.Country__c = 'Test Country';
        snapShotForCurrentMonth.Duration_months__c = 4;
        snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
        snapShotForCurrentMonth.Month_Date__c = date.today();
        snapShotForCurrentMonth.Name = 'Test PS for date  ' + snapShotForCurrentMonth.Month_Date__c;
        
        Pipeline_Snapshot__c snapShotForPriorMonth = new Pipeline_Snapshot__c();
        snapShotForPriorMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorMonth.Probability__c = 30;
        snapShotForPriorMonth.Opportunity_Amount__c = 200;
        snapShotForPriorMonth.Amount__c = 200;
        snapShotForPriorMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorMonth.Country__c = 'Test Country';
        snapShotForPriorMonth.Duration_months__c = 4;
        snapShotForPriorMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorMonth.Month_Date__c = date.today().addMonths(-1);
        snapShotForPriorMonth.Name = 'Test PS for date  ' + snapShotForPriorMonth.Month_Date__c;
        
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
        snapShotForPriorToLastMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Probability__c = 30;
        snapShotForPriorToLastMonth.Opportunity_Amount__c = 200;
        snapShotForPriorToLastMonth.Amount__c = 2000;
        snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorToLastMonth.Country__c = 'Test Country';
        snapShotForPriorToLastMonth.Duration_months__c = 4;
        snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
        snapShotForPriorToLastMonth.Name = 'Test PS for date  ' + snapShotForPriorToLastMonth.Month_Date__c;

        
        //pipelineSnapShots.add(snapShot);
        Test.startTest();
        insert snapShotForPriorMonth;
        insert snapShotForPriorToLastMonth;
        insert snapShotForCurrentMonth;
        ExecuteForCurrentMonth(date.today());
        Test.stopTest();
        
        //test case No Change
        Pipeline_Snapshot_EV_DIff__c snapShotEVDiff = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'No Change' limit 1];
        System.assert(snapShotEVDiff != null);
    }
    
    @isTest
    public static void TestWithSingleRecordForClosedOppLost()
    {        
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;        

        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = new Opportunity(Name='Test Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Closed - Lost', CloseDate = date.today().addMonths(5), Probability = 30);
        insert currentOpp;
        
        //List<Pipeline_Snapshot__c> pipelineSnapShots = new List<Pipeline_Snapshot__c>();

        Pipeline_Snapshot__c snapShotForCurrentMonth = new Pipeline_Snapshot__c();
        snapShotForCurrentMonth.Opportunity__c = currentOpp.Id;
        snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForCurrentMonth.Probability__c = 30;
        snapShotForCurrentMonth.Opportunity_Amount__c = 200;
        snapShotForCurrentMonth.Amount__c = 2000;
        snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
        snapShotForCurrentMonth.Country__c = 'Test Country';
        snapShotForCurrentMonth.Duration_months__c = 4;
        snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
        snapShotForCurrentMonth.Month_Date__c = date.today();
        snapShotForCurrentMonth.Name = 'Test PS for date  ' + snapShotForCurrentMonth.Month_Date__c;
                
        
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
        snapShotForPriorToLastMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Probability__c = 30;
        snapShotForPriorToLastMonth.Opportunity_Amount__c = 200;
        snapShotForPriorToLastMonth.Amount__c = 2000;
        snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorToLastMonth.Country__c = 'Test Country';
        snapShotForPriorToLastMonth.Duration_months__c = 4;
        snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
        snapShotForPriorToLastMonth.Name = 'Test PS for date  ' + snapShotForPriorToLastMonth.Month_Date__c;
       
       
        //pipelineSnapShots.add(snapShot);
        Test.startTest();
        insert snapShotForPriorToLastMonth;
        insert snapShotForCurrentMonth;
        ExecuteForCurrentMonth(date.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 1);
        
        //test case Closed Opp - Lost / No Go
        Pipeline_Snapshot_EV_DIff__c snapShotEVDiff = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'Closed Opp - Lost / No Go' limit 1];
        System.assert(snapShotEVDiff != null); 
    }
    
    @isTest
    public static void TestWithSingleRecordForClosedOppWon()
    {        
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;        

        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = new Opportunity(Name='Test Opportunity 1', Business_Unit_Owner__c = bizUnit.Id, StageName = 'Closed - Won', CloseDate = date.today().addMonths(5), Probability = 30);
        insert currentOpp;
        
        //List<Pipeline_Snapshot__c> pipelineSnapShots = new List<Pipeline_Snapshot__c>();

        Pipeline_Snapshot__c snapShotForCurrentMonth = new Pipeline_Snapshot__c();
        snapShotForCurrentMonth.Opportunity__c = currentOpp.Id;
        snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForCurrentMonth.Probability__c = 30;
        snapShotForCurrentMonth.Opportunity_Amount__c = 200;
        snapShotForCurrentMonth.Amount__c = 2000;
        snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
        snapShotForCurrentMonth.Country__c = 'Test Country';
        snapShotForCurrentMonth.Duration_months__c = 4;
        snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
        snapShotForCurrentMonth.Month_Date__c = date.today();
        snapShotForCurrentMonth.Name = 'Test PS for date  ' + snapShotForCurrentMonth.Month_Date__c;
                
        
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
        snapShotForPriorToLastMonth.Opportunity__c = currentOpp.Id;
        snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200;
        snapShotForPriorToLastMonth.Probability__c = 30;
        snapShotForPriorToLastMonth.Opportunity_Amount__c = 200;
        snapShotForPriorToLastMonth.Amount__c = 2000;
        snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
        snapShotForPriorToLastMonth.Country__c = 'Test Country';
        snapShotForPriorToLastMonth.Duration_months__c = 4;
        snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
        snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
        snapShotForPriorToLastMonth.Name = 'Test PS for date  ' + snapShotForPriorToLastMonth.Month_Date__c;
        
       
        //pipelineSnapShots.add(snapShot);
        Test.startTest();
        insert snapShotForPriorToLastMonth;
        insert snapShotForCurrentMonth;
        ExecuteForCurrentMonth(date.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 1);
        
        //test case Closed Opp - Won
        Pipeline_Snapshot_EV_DIff__c snapShotEVDiff = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'Closed Opp - Won' limit 1];
        System.assert(snapShotEVDiff != null);
    }
    
    @isTest
    public static void TestWithMultipleRecordsForNewOpp()
    {
       
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = null;
        Pipeline_Snapshot__c snapShotForCurrentMonth = null;
        
        List<Pipeline_Snapshot__c> snapShotForCurrentMonthLst = new List<Pipeline_Snapshot__c>();
        List<Opportunity> currentOppLst = new List<Opportunity>();
        
        for(integer i = 0; i < 20; i++)
        {
            currentOpp = new Opportunity(Name='Test Opportunity ' + i + ' for date  ' + date.today(), Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted', CloseDate = date.today().addMonths(5).addDays(i), Probability = 30);
            currentOppLst.add(currentOpp);
        }
        
        insert currentOppLst;        
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForCurrentMonth = new Pipeline_Snapshot__c();
            snapShotForCurrentMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 2000 + i;
            snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 2000 + i;
            snapShotForCurrentMonth.Probability__c = 30 + i;
            snapShotForCurrentMonth.Opportunity_Amount__c = 2000 + i;
            snapShotForCurrentMonth.Amount__c = 2000 + i;
            snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
            snapShotForCurrentMonth.Country__c = 'Test Country';
            snapShotForCurrentMonth.Duration_months__c = 4 + i;
            snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
            snapShotForCurrentMonth.Month_Date__c = date.today();
            snapShotForCurrentMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForCurrentMonth.Month_Date__c;
            
            snapShotForCurrentMonthLst.add(snapShotForCurrentMonth);
        }
        
        List<Pipeline_Snapshot__c> snapShotForPriorMonthLst = new List<Pipeline_Snapshot__c>();
                
        Pipeline_Snapshot__c snapShotForPriorMonth = null;
        for(integer i = 0; i < 20; i++)
        {
            snapShotForPriorMonth = new Pipeline_Snapshot__c();
            snapShotForPriorMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForPriorMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorMonth.Probability__c = 30 + i;
            snapShotForPriorMonth.Opportunity_Amount__c = 2000 + i;
            snapShotForPriorMonth.Amount__c = 2000 + i;
            snapShotForPriorMonth.Account__c = snapShotAccount.Id;
            snapShotForPriorMonth.Country__c = 'Test Country';
            snapShotForPriorMonth.Duration_months__c = 4;
            snapShotForPriorMonth.Funder_Account__c = funderAccount.Id;
            snapShotForPriorMonth.Month_Date__c = date.today().addMonths(-1);
            snapShotForPriorMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForPriorMonth.Month_Date__c;
            
            snapShotForPriorMonthLst.add(snapShotForPriorMonth);
        }
        
        Test.startTest();
        insert snapShotForPriorMonthLst;
        insert snapShotForCurrentMonthLst;
        ExecuteForCurrentMonth(date.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 20);
        
        //test case New Opp EV
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffNewOpp = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'New Opp EV'];
        System.assert(snapShotsEVDiffNewOpp.size() == 20);
     }
    
    @isTest
    public static void TestWithMultipleRecordsForIncreasedEV()
    {
       
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = null;
        Pipeline_Snapshot__c snapShotForCurrentMonth = null;
        
        List<Pipeline_Snapshot__c> snapShotForCurrentMonthLst = new List<Pipeline_Snapshot__c>();
        List<Opportunity> currentOppLst = new List<Opportunity>();
        
        for(integer i = 0; i < 20; i++)
        {
            currentOpp = new Opportunity(Name='Test Opportunity ' + i + ' for date  ' + date.today(), Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted', CloseDate = date.today().addMonths(5).addDays(i), Probability = 30);
            currentOppLst.add(currentOpp);
        }
        
        insert currentOppLst;        
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForCurrentMonth = new Pipeline_Snapshot__c();
            snapShotForCurrentMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 2000 + i;
            snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 2000 + i;
            snapShotForCurrentMonth.Probability__c = 30 + i;
            snapShotForCurrentMonth.Opportunity_Amount__c = 2000 + i;
            snapShotForCurrentMonth.Amount__c = 2000 + i;
            snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
            snapShotForCurrentMonth.Country__c = 'Test Country';
            snapShotForCurrentMonth.Duration_months__c = 4 + i;
            snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
            snapShotForCurrentMonth.Month_Date__c = date.today();
            snapShotForCurrentMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForCurrentMonth.Month_Date__c;
            
            snapShotForCurrentMonthLst.add(snapShotForCurrentMonth);
        }
        
        List<Pipeline_Snapshot__c> snapShotForPriorMonthLst = new List<Pipeline_Snapshot__c>();
                
        Pipeline_Snapshot__c snapShotForPriorMonth = null;
        for(integer i = 0; i < 20; i++)
        {
            snapShotForPriorMonth = new Pipeline_Snapshot__c();
            snapShotForPriorMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForPriorMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorMonth.Probability__c = 30 + i;
            snapShotForPriorMonth.Opportunity_Amount__c = 2000 + i;
            snapShotForPriorMonth.Amount__c = 2000 + i;
            snapShotForPriorMonth.Account__c = snapShotAccount.Id;
            snapShotForPriorMonth.Country__c = 'Test Country';
            snapShotForPriorMonth.Duration_months__c = 4;
            snapShotForPriorMonth.Funder_Account__c = funderAccount.Id;
            snapShotForPriorMonth.Month_Date__c = date.today().addMonths(-1);
            snapShotForPriorMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForPriorMonth.Month_Date__c;
            
            snapShotForPriorMonthLst.add(snapShotForPriorMonth);
        }
        
        List<Pipeline_Snapshot__c> snapShotForPriorToLastMonthLst = new List<Pipeline_Snapshot__c>();
                
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = null;
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
            snapShotForPriorToLastMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorToLastMonth.Probability__c = 30 + i;
            snapShotForPriorToLastMonth.Opportunity_Amount__c = 2000 + i;
            snapShotForPriorToLastMonth.Amount__c = 2000 + i;
            snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
            snapShotForPriorToLastMonth.Country__c = 'Test Country';
            snapShotForPriorToLastMonth.Duration_months__c = 4;
            snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
            snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
            snapShotForPriorToLastMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForPriorToLastMonth.Month_Date__c;
            
            snapShotForPriorToLastMonthLst.add(snapShotForPriorToLastMonth);
        }
        
        Test.startTest();
        insert snapShotForPriorMonthLst;
        insert snapShotForPriorToLastMonthLst;
        insert snapShotForCurrentMonthLst;
        ExecuteForCurrentMonth(date.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 20);
        
        //test case New Opp EV
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffIncreasedEV = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'Increased EV'];
        System.assert(snapShotsEVDiffIncreasedEV.size() == 20);
     }
    
    @isTest
    public static void TestWithMultipleRecordsForNoChange()
    {
       
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = null;
        Pipeline_Snapshot__c snapShotForCurrentMonth = null;
        
        List<Pipeline_Snapshot__c> snapShotForCurrentMonthLst = new List<Pipeline_Snapshot__c>();
        List<Opportunity> currentOppLst = new List<Opportunity>();
        
        for(integer i = 0; i < 20; i++)
        {
            currentOpp = new Opportunity(Name='Test Opportunity ' + i + ' for date  ' + date.today(), Business_Unit_Owner__c = bizUnit.Id, StageName = 'Stage 5 - Submitted', CloseDate = date.today().addMonths(5).addDays(i), Probability = 30);
            currentOppLst.add(currentOpp);
        }
        
        insert currentOppLst;        
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForCurrentMonth = new Pipeline_Snapshot__c();
            snapShotForCurrentMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForCurrentMonth.Probability__c = 30 + i;
            snapShotForCurrentMonth.Opportunity_Amount__c = 200 + i;
            snapShotForCurrentMonth.Amount__c = 200 + i;
            snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
            snapShotForCurrentMonth.Country__c = 'Test Country';
            snapShotForCurrentMonth.Duration_months__c = 4 + i;
            snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
            snapShotForCurrentMonth.Month_Date__c = date.today();
            snapShotForCurrentMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForCurrentMonth.Month_Date__c;
            
            snapShotForCurrentMonthLst.add(snapShotForCurrentMonth);
        }
        
        List<Pipeline_Snapshot__c> snapShotForPriorMonthLst = new List<Pipeline_Snapshot__c>();
                
        Pipeline_Snapshot__c snapShotForPriorMonth = null;
        for(integer i = 0; i < 20; i++)
        {
            snapShotForPriorMonth = new Pipeline_Snapshot__c();
            snapShotForPriorMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForPriorMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorMonth.Probability__c = 30 + i;
            snapShotForPriorMonth.Opportunity_Amount__c = 200 + i;
            snapShotForPriorMonth.Amount__c = 200 + i;
            snapShotForPriorMonth.Account__c = snapShotAccount.Id;
            snapShotForPriorMonth.Country__c = 'Test Country';
            snapShotForPriorMonth.Duration_months__c = 4;
            snapShotForPriorMonth.Funder_Account__c = funderAccount.Id;
            snapShotForPriorMonth.Month_Date__c = date.today().addMonths(-1);
            snapShotForPriorMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForPriorMonth.Month_Date__c;
            
            snapShotForPriorMonthLst.add(snapShotForPriorMonth);
        }
        
        List<Pipeline_Snapshot__c> snapShotForPriorToLastMonthLst = new List<Pipeline_Snapshot__c>();
                
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = null;
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
            snapShotForPriorToLastMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorToLastMonth.Probability__c = 30 + i;
            snapShotForPriorToLastMonth.Opportunity_Amount__c = 200 + i;
            snapShotForPriorToLastMonth.Amount__c = 200 + i;
            snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
            snapShotForPriorToLastMonth.Country__c = 'Test Country';
            snapShotForPriorToLastMonth.Duration_months__c = 4;
            snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
            snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
            snapShotForPriorToLastMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForPriorToLastMonth.Month_Date__c;
            
            snapShotForPriorToLastMonthLst.add(snapShotForPriorToLastMonth);
        }
        
        Test.startTest();
        insert snapShotForPriorMonthLst;
        insert snapShotForPriorToLastMonthLst;
        insert snapShotForCurrentMonthLst;
        ExecuteForCurrentMonth(date.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 20);
        
        //test case New Opp EV
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffNoChange = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'No Change'];
        System.assert(snapShotsEVDiffNoChange.size() == 20);
     }
    
    @isTest
    public static void TestWithMultipleRecordsForClosedLost()
    {
       
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = null;
        Pipeline_Snapshot__c snapShotForCurrentMonth = null;
        
        List<Pipeline_Snapshot__c> snapShotForCurrentMonthLst = new List<Pipeline_Snapshot__c>();
        List<Opportunity> currentOppLst = new List<Opportunity>();
        
        for(integer i = 0; i < 20; i++)
        {
            currentOpp = new Opportunity(Name='Test Opportunity ' + i + ' for date  ' + date.today(), Business_Unit_Owner__c = bizUnit.Id, StageName = 'Closed - Lost', CloseDate = date.today().addMonths(5).addDays(i), Probability = 30);
            currentOppLst.add(currentOpp);
        }
        
        insert currentOppLst;        
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForCurrentMonth = new Pipeline_Snapshot__c();
            snapShotForCurrentMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForCurrentMonth.Probability__c = 30 + i;
            snapShotForCurrentMonth.Opportunity_Amount__c = 200 + i;
            snapShotForCurrentMonth.Amount__c = 200 + i;
            snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
            snapShotForCurrentMonth.Country__c = 'Test Country';
            snapShotForCurrentMonth.Duration_months__c = 4 + i;
            snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
            snapShotForCurrentMonth.Month_Date__c = date.today();
            snapShotForCurrentMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForCurrentMonth.Month_Date__c;
            
            snapShotForCurrentMonthLst.add(snapShotForCurrentMonth);
        }
        
        List<Pipeline_Snapshot__c> snapShotForPriorToLastMonthLst = new List<Pipeline_Snapshot__c>();
                
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = null;
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
            snapShotForPriorToLastMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorToLastMonth.Probability__c = 30 + i;
            snapShotForPriorToLastMonth.Opportunity_Amount__c = 200 + i;
            snapShotForPriorToLastMonth.Amount__c = 200 + i;
            snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
            snapShotForPriorToLastMonth.Country__c = 'Test Country';
            snapShotForPriorToLastMonth.Duration_months__c = 4;
            snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
            snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
            snapShotForPriorToLastMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForPriorToLastMonth.Month_Date__c;
            
            snapShotForPriorToLastMonthLst.add(snapShotForPriorToLastMonth);
        }
        
        Test.startTest();
        insert snapShotForPriorToLastMonthLst;
        insert snapShotForCurrentMonthLst;
        ExecuteForCurrentMonth(date.today());
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 20);
        
        //test case New Opp EV
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffClosedLost = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'Closed Opp - Lost / No Go'];
        System.assert(snapShotsEVDiffClosedLost.size() == 20);
     }
    
    @isTest
    public static void TestWithMultipleRecordsForClosedWon()
    {
       
        Account snapShotAccount = new Account(Name='Test Account');
        insert snapShotAccount;
        Account funderAccount = new Account(Name='Test Funder Account');
        insert funderAccount;
        
        Business_Unit__c bizUnit = new Business_Unit__c(Name='Test Business Unit 1');
        
        Opportunity currentOpp = null;
        Pipeline_Snapshot__c snapShotForCurrentMonth = null;
        
        List<Pipeline_Snapshot__c> snapShotForCurrentMonthLst = new List<Pipeline_Snapshot__c>();
        List<Opportunity> currentOppLst = new List<Opportunity>();
        
        for(integer i = 0; i < 20; i++)
        {
            currentOpp = new Opportunity(Name='Test Opportunity ' + i + ' for date  ' + date.today(), Business_Unit_Owner__c = bizUnit.Id, StageName = 'Closed - Won', CloseDate = date.today().addMonths(5).addDays(i), Probability = 30);
            currentOppLst.add(currentOpp);
        }
        
        insert currentOppLst;        
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForCurrentMonth = new Pipeline_Snapshot__c();
            snapShotForCurrentMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForCurrentMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForCurrentMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForCurrentMonth.Probability__c = 30 + i;
            snapShotForCurrentMonth.Opportunity_Amount__c = 200 + i;
            snapShotForCurrentMonth.Amount__c = 200 + i;
            snapShotForCurrentMonth.Account__c = snapShotAccount.Id;
            snapShotForCurrentMonth.Country__c = 'Test Country';
            snapShotForCurrentMonth.Duration_months__c = 4 + i;
            snapShotForCurrentMonth.Funder_Account__c = funderAccount.Id;
            snapShotForCurrentMonth.Month_Date__c = date.today();
            snapShotForCurrentMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForCurrentMonth.Month_Date__c;
            
            snapShotForCurrentMonthLst.add(snapShotForCurrentMonth);
        }
        
        List<Pipeline_Snapshot__c> snapShotForPriorToLastMonthLst = new List<Pipeline_Snapshot__c>();
                
        Pipeline_Snapshot__c snapShotForPriorToLastMonth = null;
        
        for(integer i = 0; i < 20; i++)
        {
            snapShotForPriorToLastMonth = new Pipeline_Snapshot__c();
            snapShotForPriorToLastMonth.Opportunity__c = currentOppLst[i].Id;
            snapShotForPriorToLastMonth.Opportunity_Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorToLastMonth.Amount_Minus_Expense_Income__c = 200 + i;
            snapShotForPriorToLastMonth.Probability__c = 30 + i;
            snapShotForPriorToLastMonth.Opportunity_Amount__c = 200 + i;
            snapShotForPriorToLastMonth.Amount__c = 200 + i;
            snapShotForPriorToLastMonth.Account__c = snapShotAccount.Id;
            snapShotForPriorToLastMonth.Country__c = 'Test Country';
            snapShotForPriorToLastMonth.Duration_months__c = 4;
            snapShotForPriorToLastMonth.Funder_Account__c = funderAccount.Id;
            snapShotForPriorToLastMonth.Month_Date__c = date.today().addMonths(-2);
            snapShotForPriorToLastMonth.Name = 'Test PS ' + i + ' for date  ' + snapShotForPriorToLastMonth.Month_Date__c;
            
            snapShotForPriorToLastMonthLst.add(snapShotForPriorToLastMonth);
        }
        
        Test.startTest();
        insert snapShotForPriorToLastMonthLst;
        insert snapShotForCurrentMonthLst;
		ExecuteForCurrentMonth(date.today()); 
        Test.stopTest();
        
        //test case EV diffs count
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffAll = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c];
        System.assert(snapShotsEVDiffAll.size() == 20);
        
        //test case New Opp EV
        List<Pipeline_Snapshot_EV_DIff__c> snapShotsEVDiffClosedWon = [select Delta_Type__c, DIFF_12_Month_Cash_Minus_Expense_Income__c, DIFF_18_Month_Cash_Minus_Expenses_Income__c, DIFF_24_Month_Cash_Minus_Expense_Income__c, DIFF_Amount_Minus_Expense_Income__c, DIFF_Expected_Value_Minus_Expense__c, Month_Date__c, Opportunity_Name__c from Pipeline_Snapshot_EV_DIff__c where Delta_Type__c = 'Closed Opp - Won'];
        System.assert(snapShotsEVDiffClosedWon.size() == 20);
     }
    
    private static void ExecuteForCurrentMonth(Date dateVal)
    {
        DateTime firstDate = dateVal.toStartOfMonth() + 1;
        DateTime lastDate = firstDate.addDays(date.daysInMonth(dateVal.year() , dateVal.month())  - 1);
        String query = '';
        query += 'SELECT Name, Opportunity__c, Opportunity__r.StageName, Opportunity__r.Name, Month_Date__c, ' +
        'X12_Month_Cash_Minus_Expense_Income_EV__c , ' +
        'X18_Month_Cash_Minus_Expenses_Income_EV__c, ' +
        'X24_Month_Cash_Minus_Expense_Income_EV__c, ' +
        'Opportunity_Amount_Minus_Expense_Income__c, ' +
        'Expected_Value_Minus_Expense__c ' +
        'FROM Pipeline_Snapshot__c ' +
        'WHERE Month_Date__c >= ' + firstDate.format('yyyy-MM-dd') + ' AND Month_Date__c <= ' + lastDate.format('yyyy-MM-dd');
        BatchCalculateEVDiff obj = new BatchCalculateEVDiff(query);
        ID batchprocessid = Database.executeBatch(obj);

    }

}