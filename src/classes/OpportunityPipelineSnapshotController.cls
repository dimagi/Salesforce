public class OpportunityPipelineSnapshotController {

    public String monthYearText { get; set;}
    public JobWrapper oppSnapshotJobWrapper { get; set;}

    public Integer currentPSCount {get; set;}
    public Date lastMonthSnapshotDate {get; set;}

    public Integer resultSize { get; set;}
    public Integer pageSize { get; set;}
    public Integer pageNumber { get; set;}
    public Boolean hasPrevious { get; set;}
    public Boolean hasNext { get; set;}

    public void initOpportunityPipelineSnapshot() {
        loadOpportunityPipelineSnapshotBatchJobStatus();
        Date currentDate = Date.today().addMonths(-1);
        Integer numberOfDays = Date.daysInMonth(currentDate.year(), currentDate.month());
        this.lastMonthSnapshotDate = Date.newInstance(currentDate.year(), currentDate.month(), numberOfDays);
        this.monthYearText = DateTime.newInstance(this.lastMonthSnapshotDate.year(), this.lastMonthSnapshotDate.month(), this.lastMonthSnapshotDate.day()).format('MMMM yyyy');
        this.currentPSCount = [SELECT count() FROM Pipeline_Snapshot__c WHERE Month_Date__c =: this.lastMonthSnapshotDate AND Source_Type__c = 'Opportunity'];
    }

    public List<Pipeline_Snapshot__c> getSnpList() {
        initPagination();

        this.hasPrevious = true;
        this.hasNext = true;
        Integer offsetValue = ((this.pageNumber - 1) * this.pageSize);

        String soqlQuery = 'SELECT Id, Name, Month_Date__c, Stage__c, Amount__c, Three_Month_EV__c, Twelve_Month_Cash_EV__c, X18_Month_Cash_EV__c, X24_Month_Cash_EV__c,'
                                + ' Probability__c, CloseDate__c, Expected_Value__c, Duration_months__c, Opportunity__c'
                                + ' FROM Pipeline_Snapshot__c WHERE Month_Date__c =: lastMonthSnapshotDate AND Source_Type__c = \'Opportunity\''
                                + ' ORDER BY Name LIMIT : pageSize OFFSET : offsetValue';
        List<Pipeline_Snapshot__c> snplist = Database.query(soqlQuery);

        this.resultSize = Database.countQuery('SELECT count() FROM Pipeline_Snapshot__c WHERE Month_Date__c =: lastMonthSnapshotDate AND Source_Type__c = \'Opportunity\'');

        if (this.resultSize == 0) {
            this.pageNumber = 0;
        }
        if (this.pageNumber == 1) {
            this.HasPrevious = false;
        }
        if (offsetValue + this.pageSize >= this.resultSize) {
            this.HasNext = false;
        }

        return snplist;
    }

    public void runOpportunityPipelineSnapshotBatchJob() {
        ApexClass batchClass = [SELECT Id FROM ApexClass WHERE Name='OpportunityPipelineSnapshotBatch' LIMIT 1];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID = :batchClass.Id
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];
        if (batchClassJobList != null && batchClassJobList.size() == 0) {
            Database.executeBatch(new OpportunityPipelineSnapshotBatch(this.lastMonthSnapshotDate), 5);
        }
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
                    if (lastJobInfo.Status == 'Completed' && (lastJobInfo.ExtendedStatus == null || lastJobInfo.ExtendedStatus == '')) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Pipeline snapshots job complete.'));
                    } else {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Pipeline snapshots job complete with status ' + lastJobInfo.Status
                                                                        + ' ' + lastJobInfo.ExtendedStatus));
                    }
                    this.currentPSCount = [SELECT count() FROM Pipeline_Snapshot__c WHERE Month_Date__c =: this.lastMonthSnapshotDate AND Source_Type__c = 'Opportunity'] ;
                    initPagination();
                }
            }
        }
    }

    public void previousPage() {
        this.pageNumber--;
    }

    public void nextPage() {
        this.pageNumber++;
    }

    public void updatePageNumber() {
        this.pageNumber = 1;
    }

    private void initPagination() {
        if (this.pageNumber == null || this.pageNumber == 0) {
            this.pageNumber = 1;
            this.resultSize = 0;
            this.pageSize = 10;
            this.hasPrevious = true;
            this.hasNext = true;
        }
    }
}