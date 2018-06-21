/**
 * OpportunityPipelineSnapshotBatch for generating new Pipeline Snapshots.
 */
public class OpportunityPipelineSnapshotBatch implements Database.Batchable<Opportunity>, Database.Stateful {

    private Date runDate;

    public OpportunityPipelineSnapshotBatch() {
        this(Date.today());
    }

    public OpportunityPipelineSnapshotBatch(Date runDate) {
        this.runDate = runDate;
    }

    public List<Opportunity> start(Database.BatchableContext BC) {
        List<Pipeline_Snapshot_EV_DIff__c> evToRemove = [SELECT Id FROM Pipeline_Snapshot_EV_DIff__c WHERE Month_Date__c =: this.runDate];
        List<Pipeline_Snapshot__c> psTORemove = [SELECT Id FROM Pipeline_Snapshot__c WHERE Month_Date__c =: this.runDate AND Source_Type__c = 'Opportunity'];
        if (evToRemove.size() > 0) {
            delete evToRemove;
        }
        if (psTORemove.size() > 0) {
            delete psTORemove;
        }

        return [SELECT Id, Name, AccountId, Amount, Amount_Minus_Expense_Income__c, Country_Text__c, Duration_months__c, Expected_Buffer__c,
                    Funder_Account__c, Expense_Income__c, Opportunity_Owning_Entity__c, Probability, Product_Text__c,
                    Channel_Response__c, StageName, CloseDate, OwnerId
                    FROM Opportunity
                    WHERE StageName = 'Stage 4 - Proposal Development'
                    OR StageName = 'Stage 5 - Submitted'
                    OR StageName = 'Stage 6 - In Negotiations'
                    OR StageName = 'Cash on Hand'
                    OR StageName = 'Predicted pipeline'
                    OR StageName = 'Core run rate'];
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<Pipeline_Snapshot__c> newSnapshots = new List<Pipeline_Snapshot__c>();
        for (Opportunity opp : scope) {
            Pipeline_Snapshot__c lastMonthSnapshot = getOldSnapshots(opp.Id, this.runDate);

            Pipeline_Snapshot__c newPs = new Pipeline_Snapshot__c(
                    Name = opp.Name + ' - ' + this.runDate.month() + '/' + this.runDate.year(),
                    Month_Date__c = this.runDate,
                    Opportunity__c = opp.Id,
                    Account__c = opp.AccountId,
                    Amount__c = opp.Amount,
                    Amount_Minus_Expense_Income__c = opp.Amount_Minus_Expense_Income__c,
                    Country__c = opp.Country_Text__c,
                    Duration_months__c = opp.Duration_months__c,
                    Expected_Buffer__c = opp.Expected_Buffer__c,
                    Funder_Account__c = opp.Funder_Account__c,
                    Opportunity_Amount__c = opp.Amount,
                    Opportunity_Amount_Minus_Expense_Income__c = opp.Amount_Minus_Expense_Income__c,
                    CloseDate__c = opp.CloseDate,
                    Opportunity_Duration__c = opp.Duration_months__c,
                    Opportunity_Expense_Income__c = opp.Expense_Income__c,
                    OwnerId = opp.OwnerId,
                    Owning_Entity__c = opp.Opportunity_Owning_Entity__c,
                    Probability__c = opp.Probability,
                    Products__c = opp.Product_Text__c,
                    RFP_Response__c = opp.Channel_Response__c,
                    Source_Type__c = 'Opportunity',
                    Stage__c = opp.StageName
                );

            newPs.recalculateFormulas();
            newPs.Buffer_EV_for_Period__c = (newPs.Buffer_EV__c != null ? newPs.Buffer_EV__c : 0) - (lastMonthSnapshot.Buffer_EV__c != null ? lastMonthSnapshot.Buffer_EV__c : 0);
            newSnapshots.add(newPs);
        }

        if (newSnapshots.size() > 0) {
            insert newSnapshots;
        }

        NetEVDifferenceTriggerGateway evDiffHelper = new NetEVDifferenceTriggerGateway();
        evDiffHelper.processLastMonthSnapshots(newSnapshots);
    }

    public void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            NetEVDifferenceTriggerGateway.processPriorMonthSnapshotsWithClosedStatus(this.runDate);
            EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Opportunity Pipeline Snapshots', 'Job finished : ' + Date.today() + ' created for : ' + this.runDate);
        }
    }

    private Pipeline_Snapshot__c getOldSnapshots(Id oppId, Date monthDate) {
        List<Pipeline_Snapshot__c> oldSnapshots;
        oldSnapshots = [SELECT Id, Opportunity__c, Buffer_EV__c FROM Pipeline_Snapshot__c
                            WHERE Opportunity__c =: oppId AND Month_Date__c < :monthDate AND Month_Date__c > :monthDate.addMonths(-6)
                            AND Stage__c != 'Total' ORDER BY Month_Date__c DESC];

        if (oldSnapshots.size() > 0) {
            return oldSnapshots.get(0);
        }
        return new Pipeline_Snapshot__c();
    }
}