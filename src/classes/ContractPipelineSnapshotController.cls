public class ContractPipelineSnapshotController extends PipelineSnapshotController {

    public ContractPipelineSnapshotController() {
        this.jobName = 'ContractPipelineSnapshotBatch';
    }

    public override List<Pipeline_Snapshot__c> getSnpList() {
        List<Pipeline_Snapshot__c> snplist = [SELECT Id, Name, Month_Date__c, Stage__c, Amount__c, Three_Month_EV__c, Twelve_Month_Cash_EV__c, X18_Month_Cash_EV__c, X24_Month_Cash_EV__c,
                            Probability__c, CloseDate__c, Expected_Value__c, Duration_months__c, Contract__c
                            FROM Pipeline_Snapshot__c WHERE Month_Date__c =: this.lastMonthSnapshotDate AND Source_Type__c = 'Contract'
                            ORDER BY Name LIMIT : this.pagination.pageSize OFFSET : this.pagination.getOffsetValue()];
        loadTotal();
        return snplist;
    }

    public override void runPipelineSnapshotJob() {
        ApexClass batchClass = [SELECT Id FROM ApexClass WHERE Name =: this.jobName LIMIT 1];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID =: batchClass.Id
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];
        if (batchClassJobList != null && batchClassJobList.size() == 0) {
            Database.executeBatch(new ContractPipelineSnapshotBatch(this.lastMonthSnapshotDate), 5);
        }
        loadJobStatus();
    }

    public override void loadTotal() {
        this.currentPSCount = [SELECT count() FROM Pipeline_Snapshot__c WHERE Month_Date__c =: this.lastMonthSnapshotDate AND Source_Type__c = 'Contract'];
        this.pagination.handleResulSize(this.currentPSCount);
    }
}