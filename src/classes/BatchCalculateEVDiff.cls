global class BatchCalculateEVDiff implements Database.Batchable<sObject>
{
	global final String Query;
    private Map<Id, Pipeline_Snapshot__c> lastMonthSnapshotRecords;
    private Map<Id, Pipeline_Snapshot__c> priorToLastMothSnapshotRecords;
    private Map<Id, Pipeline_Snapshot__c> oldSnapshotRecords;
    private Date currentDate;
    private List<Pipeline_Snapshot_EV_DIff__c> snapShotDiffs;

    global BatchCalculateEVDiff (String q)
    {
    	Query=q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
    
   	global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        
        if(!NetEVDifferenceTriggerGateway.getInstance().IfCUrrentMonthRecordExists())
        {
            LoadCachedData(scope);
            for(Sobject s : scope)
            {
                ProcessRecord(s);
            }
            
            if(snapShotDiffs != null && snapShotDiffs.size() > 0)
            {
                try
                {
                    insert snapShotDiffs;
                    system.debug(snapShotDiffs);
                }
                catch(DmlException ex)
                {
                    System.debug('An unexpected error has occurred while inserting in snapshot difference table: ' + ex.getMessage());
                } 
            }  
        }
    }
    
    global void finish(Database.BatchableContext BC)
    {
    }
    
    private void LoadCachedData(List<Pipeline_Snapshot__c> snapShots)
    {
        currentDate = NetEVDifferenceTriggerGateway.getInstance().getCurrentDate(snapShots);  
        if(currentDate != null)
        {
            lastMonthSnapshotRecords = NetEVDifferenceTriggerGateway.getInstance().getLastMonthSnapShotRecords(currentDate);
            priorToLastMothSnapshotRecords = NetEVDifferenceTriggerGateway.getInstance().getPriorToLastMonthSnapShotRecords(currentDate);
            oldSnapshotRecords = NetEVDifferenceTriggerGateway.getInstance().getOldSnapShotRecords(currentDate);
            snapShotDiffs = new List<Pipeline_Snapshot_EV_DIff__c>();   
        }
    }
    
    private void ProcessRecord(SObject so)
	{
        system.debug('Entered after Insert Method');
        Pipeline_Snapshot__c newSnapShotObj = (Pipeline_Snapshot__c)so;
        system.debug('lastmonthsnapshotrecords --> ');
        system.debug(lastMonthSnapshotRecords);
        Pipeline_Snapshot__c lastMonthSnapShotObj = lastMonthSnapshotRecords.get(newSnapShotObj.Opportunity__c);
        system.debug('LAST MONTH SNAPSHOT RECORDS -->');
        system.debug(lastMonthSnapshotRecords);
        system.debug('NEW SNAPHOT OBJ OPP -->');
        system.debug(newSnapShotObj.Opportunity__c);
        system.debug(lastMonthSnapShotObj);
        
        Pipeline_Snapshot_EV_DIff__c snapShotsDiff = new Pipeline_Snapshot_EV_DIff__c();
        snapShotsDiff.Name = newSnapShotObj.Name;
        snapShotsDiff.Opportunity_Name__c = newSnapShotObj.Opportunity__r.Name;
        snapShotsDiff.Month_Date__c = newSnapShotObj.Month_Date__c;
        
        if(lastMonthSnapShotObj != null)
        {
            system.debug('LAST MONTH SNAP SHOT OBJ IS NOT NULL');
            snapShotsDiff.DIFF_12_Month_Cash_Minus_Expense_Income__c = (newSnapShotObj.X12_Month_Cash_Minus_Expense_Income_EV__c != null ? newSnapShotObj.X12_Month_Cash_Minus_Expense_Income_EV__c : 0) - (lastMonthSnapShotObj.X12_Month_Cash_Minus_Expense_Income_EV__c != null ? lastMonthSnapShotObj.X12_Month_Cash_Minus_Expense_Income_EV__c : 0);
            snapShotsDiff.DIFF_18_Month_Cash_Minus_Expenses_Income__c = (newSnapShotObj.X18_Month_Cash_Minus_Expenses_Income_EV__c != null ? newSnapShotObj.X18_Month_Cash_Minus_Expenses_Income_EV__c : 0) - (lastMonthSnapShotObj.X18_Month_Cash_Minus_Expenses_Income_EV__c != null ? lastMonthSnapShotObj.X18_Month_Cash_Minus_Expenses_Income_EV__c : 0);
            snapShotsDiff.DIFF_24_Month_Cash_Minus_Expense_Income__c = (newSnapShotObj.X24_Month_Cash_Minus_Expense_Income_EV__c != null ? newSnapShotObj.X24_Month_Cash_Minus_Expense_Income_EV__c : 0) - (lastMonthSnapShotObj.X24_Month_Cash_Minus_Expense_Income_EV__c != null ? lastMonthSnapShotObj.X24_Month_Cash_Minus_Expense_Income_EV__c : 0);
            snapShotsDiff.DIFF_Amount_Minus_Expense_Income__c = (newSnapShotObj.Opportunity_Amount_Minus_Expense_Income__c != null ? newSnapShotObj.Opportunity_Amount_Minus_Expense_Income__c : 0) - (lastMonthSnapShotObj.Opportunity_Amount_Minus_Expense_Income__c != null ? lastMonthSnapShotObj.Opportunity_Amount_Minus_Expense_Income__c : 0);
            snapShotsDiff.DIFF_Expected_Value_Minus_Expense__c = (newSnapShotObj.Expected_Value_Minus_Expense__c != null ? newSnapShotObj.Expected_Value_Minus_Expense__c : 0) - (lastMonthSnapShotObj.Expected_Value_Minus_Expense__c != null ? lastMonthSnapShotObj.Expected_Value_Minus_Expense__c : 0);
            
            if(snapShotsDiff.DIFF_Amount_Minus_Expense_Income__c > 0)
            {
                snapShotsDiff.Delta_Type__c = 'Increased EV';
            }
            else if(snapShotsDiff.DIFF_Amount_Minus_Expense_Income__c < 0)
            {
                snapShotsDiff.Delta_Type__c = 'Decreased EV';                
            }
            else
            {
                snapShotsDiff.Delta_Type__c = '	No Change';
            }
            
            Pipeline_Snapshot__c oldSnapShotObj = oldSnapshotRecords.get(newSnapShotObj.Opportunity__c); 
            
            if(oldSnapShotObj == null)
            {
                snapShotsDiff.Delta_Type__c = 'New Opp EV';
            }
            
            snapShotDiffs.add(snapShotsDiff);
            
        }
        else
        {
            Pipeline_Snapshot__c priorToLastMonthSnapShotObj = priorToLastMothSnapshotRecords.get(newSnapShotObj.Opportunity__c); 
            system.debug('PRIOR TO LAST MONTH SNAPSHOT RECORDS -->');
            system.debug(priorToLastMothSnapshotRecords);
            system.debug('NEW SNAPHOT OBJ OPP -->');
            system.debug(newSnapShotObj.Opportunity__c);
            if(priorToLastMonthSnapShotObj != null)
            {            
                system.debug('PRIOR TO LAST MONTH SNAP SHOT OBJ IS NOT NULL');
                snapShotsDiff.DIFF_12_Month_Cash_Minus_Expense_Income__c = 0;
                snapShotsDiff.DIFF_18_Month_Cash_Minus_Expenses_Income__c = 0;
                snapShotsDiff.DIFF_24_Month_Cash_Minus_Expense_Income__c = 0;
                snapShotsDiff.DIFF_Amount_Minus_Expense_Income__c = 0;
                snapShotsDiff.DIFF_Expected_Value_Minus_Expense__c = 0;

                if(priorToLastMonthSnapShotObj.Opportunity__r.StageName == 'Closed - Lost' || priorToLastMonthSnapShotObj.Opportunity__r.StageName == 'Closed - No Go')
                {
                    snapShotsDiff.Delta_Type__c = 'Closed Opp - Lost / No Go'; 
                }
                else if(priorToLastMonthSnapShotObj.Opportunity__r.StageName == 'Closed - Won')
                {
                    snapShotsDiff.Delta_Type__c = 'Closed Opp - Won'; 
                }
                
                snapShotDiffs.add(snapShotsDiff);
            }
        }

        system.debug('SNAP SHOT DIFFERENCE before insert--- > ');
        system.debug(snapShotDiffs);
	}
    
}