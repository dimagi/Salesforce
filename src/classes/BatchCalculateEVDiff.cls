public class BatchCalculateEVDiff implements Database.Batchable<Pipeline_Snapshot__c>, Database.Stateful {

    private Date currentDate;
    private Boolean forClosed;

    public BatchCalculateEVDiff () {}

    public BatchCalculateEVDiff (Date currentDate) {
        this.currentDate = currentDate;
    }

    public List<Pipeline_Snapshot__c> start(Database.BatchableContext BC) {
        List<Pipeline_Snapshot__c> yesterdaySnapshots = [SELECT Id, Month_Date__c FROM Pipeline_Snapshot__c WHERE CreatedDate = YESTERDAY LIMIT 1];
        if (yesterdaySnapshots.size() > 0 || this.currentDate != null) {
            this.currentDate = this.currentDate != null ? this.currentDate : yesterdaySnapshots.get(0).Month_Date__c;
            Date firstDate = this.currentDate.toStartOfMonth();
            Date lastDate = firstDate.addDays(Date.daysInMonth(this.currentDate.year() , this.currentDate.month())).addDays(-1);

            List<Pipeline_Snapshot__c> records = [SELECT Id, Name, Opportunity__c, Opportunity__r.StageName,
                            Month_Date__c, Amount_Minus_Expense_Income__c, Opportunity_Name__c,
                            X12_Month_Cash_Minus_Expense_Income_EV__c ,
                            X18_Month_Cash_Minus_Expenses_Income_EV__c,
                            X24_Month_Cash_Minus_Expense_Income_EV__c,
                            Opportunity_Amount_Minus_Expense_Income__c,
                            Expected_Value_Minus_Expense__c,
                            Stage__c, Monthly_Recurring_Revenue_MRR__c,
                            Expected_Monthly_Recurring_Revenue_MRR__c,
                            Buffer_EV__c
                            FROM Pipeline_Snapshot__c
                            WHERE Month_Date__c >=: firstDate
                            AND Month_Date__c <=: lastDate
                            AND Source_Type__c = 'Opportunity'
                            AND Stage__c != 'Total'];
            return records;
        }
        return new List<Pipeline_Snapshot__c>();
    }

    public void execute(Database.BatchableContext BC, List<Pipeline_Snapshot__c> scope) {
        NetEVDifferenceTriggerGateway helper = new NetEVDifferenceTriggerGateway();
        helper.processLastMonthSnapshots(scope);
    }

    public void finish(Database.BatchableContext BC) {
    }
}