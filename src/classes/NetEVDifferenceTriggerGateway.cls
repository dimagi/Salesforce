public with sharing class NetEVDifferenceTriggerGateway {
    
    private static NetEVDifferenceTriggerGateway Instance;
    
    public static NetEVDifferenceTriggerGateway getInstance()
    {
        if(Instance == null)
        {
            Instance = new NetEVDifferenceTriggerGateway();   
        }
        return Instance;
    }
    
    public Date getCurrentDate(List<sObject> newTrigger)
    {
        Date currentDate;
        if(newTrigger.size() > 0)
        {
            List<Pipeline_Snapshot__c> snapShots = (List<Pipeline_Snapshot__c>)newTrigger;
            if(snapShots.size() > 0)
            {
                currentDate = snapShots[0].Month_Date__c;
            }
        }
        
        return currentDate;
    }
    
    public Map<Id, Pipeline_Snapshot__c> getLastMonthSnapShotRecords(Date currentDate)
    {
        Date prevMonthDate =  currentDate.addMonths(-1);
        Date firstDate = prevMonthDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(date.daysInMonth(prevMonthDate.year() , prevMonthDate.month())  - 1);
        
        List<Pipeline_Snapshot__c> lastMonthSnapShotsList = [SELECT Name, Opportunity__c, Opportunity__r.StageName, Month_Date__c, 
                                                               X12_Month_Cash_Minus_Expense_Income_EV__c , 
                                                               X18_Month_Cash_Minus_Expenses_Income_EV__c, 
                                                               X24_Month_Cash_Minus_Expense_Income_EV__c, 
                                                               Opportunity_Amount_Minus_Expense_Income__c, 
                                                               Expected_Value_Minus_Expense__c  
                                                               FROM Pipeline_Snapshot__c
                                                               WHERE Month_Date__c >= :firstDate and Month_Date__c <= :lastDate
                                                            ];
            
        Map<Id, Pipeline_Snapshot__c> lastMonthSnapShotsMap = new Map<Id, Pipeline_Snapshot__c>();
        for(Pipeline_Snapshot__c snapshotObject : lastMonthSnapShotsList)
        {
            lastMonthSnapShotsMap.put(snapshotObject.Opportunity__c, snapshotObject);
        }
        
        return lastMonthSnapShotsMap;
    }
    
    public Map<Id, Pipeline_Snapshot__c> getPriorToLastMonthSnapShotRecords(Date currentDate)
    {
        Date prevMonthDate =  currentDate.addMonths(-2);
        Date firstDate = prevMonthDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(date.daysInMonth(prevMonthDate.year() , prevMonthDate.month())  - 1);
        
        List<Pipeline_Snapshot__c> priorToLastMonthSnapShotsList = [SELECT Name, Opportunity__c, Opportunity__r.StageName, Month_Date__c, 
                                                               X12_Month_Cash_Minus_Expense_Income_EV__c , 
                                                               X18_Month_Cash_Minus_Expenses_Income_EV__c, 
                                                               X24_Month_Cash_Minus_Expense_Income_EV__c, 
                                                               Opportunity_Amount_Minus_Expense_Income__c, 
                                                               Expected_Value_Minus_Expense__c  
                                                               FROM Pipeline_Snapshot__c
                                                               WHERE Month_Date__c >= :firstDate and Month_Date__c <= :lastDate
                                                            ];
        
        Map<Id, Pipeline_Snapshot__c> priorToLastMonthSnapShotsMap = new Map<Id, Pipeline_Snapshot__c>();
        for(Pipeline_Snapshot__c snapshotObject : priorToLastMonthSnapShotsList)
        {
            priorToLastMonthSnapShotsMap.put(snapshotObject.Opportunity__c, snapshotObject);
        }
        
        return priorToLastMonthSnapShotsMap;
    }
    
    public Map<Id, Pipeline_Snapshot__c> getOldSnapShotRecords(Date currentDate)
    {
        Date prevMonthDate =  currentDate.addMonths(-1);
        
        List<Pipeline_Snapshot__c> oldSnapShotsList = [SELECT Name, Opportunity__c, Opportunity__r.StageName, Month_Date__c, 
                                                               X12_Month_Cash_Minus_Expense_Income_EV__c , 
                                                               X18_Month_Cash_Minus_Expenses_Income_EV__c, 
                                                               X24_Month_Cash_Minus_Expense_Income_EV__c, 
                                                               Opportunity_Amount_Minus_Expense_Income__c, 
                                                               Expected_Value_Minus_Expense__c  
                                                               FROM Pipeline_Snapshot__c
                                                               WHERE Month_Date__c < :prevMonthDate
                                                            ];
        
        Map<Id, Pipeline_Snapshot__c> oldSnapShotsMap = new Map<Id, Pipeline_Snapshot__c>();
        for(Pipeline_Snapshot__c snapshotObject : oldSnapShotsList)
        {
            oldSnapShotsMap.put(snapshotObject.Opportunity__c, snapshotObject);
        }
        
        return oldSnapShotsMap;
    }
    
    public Boolean IfCUrrentMonthRecordExists()
    {
        Date todayDate = system.today();
        Date firstDate = todayDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(date.daysInMonth(todayDate.year() , todayDate.month())  - 1);
        
        Integer recordCount = [SELECT Count() FROM Pipeline_Snapshot_EV_DIff__c where Month_Date__c >= :firstDate and Month_Date__c <= :lastDate];
        
        return recordCount > 0;
        
    }

}