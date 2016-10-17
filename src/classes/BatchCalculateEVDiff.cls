public class BatchCalculateEVDiff implements Database.Batchable<Pipeline_Snapshot__c>, Database.Stateful {

    private Date currentDate;
    private Boolean forTrigger;
    private Boolean emptyList;

    public BatchCalculateEVDiff (Date currentDate, Boolean forTrigger) {
        this.currentDate = currentDate;
        this.forTrigger = forTrigger;
        this.emptyList = false;
    }

    public List<Pipeline_Snapshot__c> start(Database.BatchableContext BC) {
        Date firstDate = this.currentDate.toStartOfMonth();
        Date lastDate = firstDate.addDays(Date.daysInMonth(this.currentDate.year() , this.currentDate.month())).addDays(-1);

        List<Pipeline_Snapshot__c> records = [SELECT Id, Name, Opportunity__c, Opportunity__r.StageName, Opportunity__r.Name,
                            Opportunity__r.Expected_Monthly_Recurring_Revenue_MRR__c,
                            Opportunity__r.Monthly_Recurring_Revenue_MRR__c, Month_Date__c,
                            Amount_Minus_Expense_Income__c,
                            X12_Month_Cash_Minus_Expense_Income_EV__c ,
                            X18_Month_Cash_Minus_Expenses_Income_EV__c,
                            X24_Month_Cash_Minus_Expense_Income_EV__c,
                            Opportunity_Amount_Minus_Expense_Income__c,
                            Expected_Value_Minus_Expense__c,
                            Stage__c
                            FROM Pipeline_Snapshot__c
                            WHERE Month_Date__c >=: firstDate
                            AND Month_Date__c <=: lastDate
                            AND Source_Type__c = 'Opportunity'
                            AND Stage__c != 'Total'];

        if (!forTrigger && records.size() == 0) {
            this.emptyList = true;
            records.add(new Pipeline_Snapshot__c());
        }

        return records;
    }

    public void execute(Database.BatchableContext BC, List<Pipeline_Snapshot__c> scope) {
        NetEVDifferenceTriggerGateway helper = new NetEVDifferenceTriggerGateway();
    if (!forTrigger) {
            helper.processPriorMonthSnapshotsWithClosedStatus(this.emptyList == true ? new List<Pipeline_Snapshot__c>() : scope, currentDate);
        } else {
            helper.processLastMonthSnapshots(scope);
        }
    }

    public void finish(Database.BatchableContext BC) {
    }
}