public abstract class PipelineSnapshotController {

    public String monthYearText { get; set; }
    public JobWrapper jobWrapper { get; set; }
    public Integer currentPSCount { get; set; }
    public Date lastMonthSnapshotDate { get; set; }
    public Pagination pagination { get; set; }
    public String jobName { get; set; }

    public void initPipelineSnapshot() {
        loadJobStatus();
        this.pagination = new Pagination();
        Date currentDate = Date.today().addMonths(-1);
        Integer numberOfDays = Date.daysInMonth(currentDate.year(), currentDate.month());
        this.lastMonthSnapshotDate = Date.newInstance(currentDate.year(), currentDate.month(), numberOfDays);
        this.monthYearText = DateTime.newInstance(this.lastMonthSnapshotDate.year(), this.lastMonthSnapshotDate.month(), this.lastMonthSnapshotDate.day()).format('MMMM yyyy');
        loadTotal();
    }

    public void loadJobStatus() {
        Boolean wasRunning = this.jobWrapper != null ? jobWrapper.isRunning : false;

        this.jobWrapper = new JobWrapper(false);
        ApexClass batchClass = [SELECT Id FROM ApexClass WHERE Name =: this.jobName LIMIT 1];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];

        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            this.jobWrapper.isRunning = true;
            this.jobWrapper.jobItemsProcessed = batchClassJobList[0].JobItemsProcessed;
            this.jobWrapper.totalJobItems = batchClassJobList[0].TotalJobItems;
        } else {
            this.jobWrapper.isRunning = false;
            if (wasRunning == true) {
                batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, CreatedDate, Status, ExtendedStatus FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                            AND Status IN ('Aborted', 'Completed', 'Failed') ORDER BY createdDate DESC LIMIT 1];
                if (batchClassJobList != null && batchClassJobList.size() > 0) {
                    AsyncApexJob lastJobInfo = batchClassJobList.get(0);
                    if (lastJobInfo.Status == 'Completed' && (lastJobInfo.ExtendedStatus == null || lastJobInfo.ExtendedStatus == '')) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Pipeline snapshots job complete.'));
                    } else {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Pipeline snapshots job complete with status ' + lastJobInfo.Status
                                                                        + ' ' + lastJobInfo.ExtendedStatus));
                    }
                    this.pagination = new Pagination();
                    loadTotal();
                }
            }
        }
    }

    public abstract List<Pipeline_Snapshot__c> getSnpList();
    public abstract void runPipelineSnapshotJob();
    public abstract void loadTotal();
}