public class OpportunityPipelineSnapshotController {

    public String monthYearText { get; set;}
    public JobWrapper oppSnapshotJobWrapper { get; set;}

    private Date lastMonthSnapshotDate;

    public void initOpportunityPipelineSnapshot() {
        loadOpportunityPipelineSnapshotBatchJobStatus();
        Date currentDate = Date.today().addMonths(-1);
        Integer numberOfDays = Date.daysInMonth(currentDate.year(), currentDate.month());
        this.lastMonthSnapshotDate = Date.newInstance(currentDate.year(), currentDate.month(), numberOfDays);
        this.monthYearText = DateTime.newInstance(this.lastMonthSnapshotDate.year(), this.lastMonthSnapshotDate.month(), this.lastMonthSnapshotDate.day()).format('MMMM yyyy');
    }

    public void runOpportunityPipelineSnapshotBatchJob() {
        Database.executeBatch(new OpportunityPipelineSnapshotBatch(this.lastMonthSnapshotDate), 5);
        loadOpportunityPipelineSnapshotBatchJobStatus();
    }

    public void loadOpportunityPipelineSnapshotBatchJobStatus() {
        Boolean wasRunning = this.oppSnapshotJobWrapper != null ? oppSnapshotJobWrapper.isRunning : false;

        this.oppSnapshotJobWrapper = new JobWrapper(false);
        ApexClass batchClass = [SELECT Id FROM ApexClass WHERE Name='OpportunityPipelineSnapshotBatch' LIMIT 1];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];

        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            this.oppSnapshotJobWrapper.isRunning = true;
            this.oppSnapshotJobWrapper.jobItemsProcessed = batchClassJobList[0].JobItemsProcessed;
            this.oppSnapshotJobWrapper.totalJobItems = batchClassJobList[0].TotalJobItems;
        } else {
            this.oppSnapshotJobWrapper.isRunning = false;
            if (wasRunning == true) {
                batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, CreatedDate, Status, ExtendedStatus FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                            AND Status IN ('Aborted', 'Completed', 'Failed') ORDER BY createdDate DESC LIMIT 1];
                if (batchClassJobList != null && batchClassJobList.size() > 0) {
                    AsyncApexJob lastJobInfo = batchClassJobList.get(0);
                    if (lastJobInfo.Status == 'Completed') {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Pipeline snapshots job finished work.'));
                    } else {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Pipeline snapshots job finished work with status ' + lastJobInfo.Status
                                                                        + ' ' + lastJobInfo.ExtendedStatus));
                    }
                }
            }
        }
    }

}