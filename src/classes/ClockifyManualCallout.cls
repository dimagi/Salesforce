public class ClockifyManualCallout {
    private PageReference backPage = null;

    public ClockifyManualCallout(ApexPages.StandardSetController sc) {
        this.backPage = sc.cancel();
    }  
    public void runRecalculation() {
        ApexClass[] batchClass = [SELECT Id FROM ApexClass WHERE Name = 'ClockifySyncBatch'];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID IN: batchClass
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];
        
        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Clockify Sync Batch is running right now, cannot schedule two jobs at the same time. Please try again after few minutes.'));
            return;
        }
        if(!Test.isRunningTest()){
            Database.executeBatch(new ClockifySyncBatch(),1);
        }
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Clockify Sync Batch was scheduled successfully, and all the time cards for the last 6 months from today will be updated or inserted in a few minutes.'));
    }
    
    public PageReference goBack() {
        return backPage;
    }
}