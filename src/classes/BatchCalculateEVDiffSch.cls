global class BatchCalculateEVDiffSch implements Schedulable{
    
   	public static String sched = '0 00 00 21 ? ?';  //
    
    global static String ScheduleIt()
    {
        BatchCalculateEVDiffSch SC = new BatchCalculateEVDiffSch(); 
        return System.schedule('My batch Job', sched, SC); 
    }
    
    global void execute(SchedulableContext sc)
    {
		ExecuteForCurrentMonth();
    }
    
    private static void ExecuteForCurrentMonth()
    {
        Date dateVal = system.today();
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
    
    public static void ForceExecuteForAnyMonth(Date dateVal)
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