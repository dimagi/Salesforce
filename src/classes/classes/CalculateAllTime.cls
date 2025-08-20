public class CalculateAllTime {
    private PageReference backPage = null;
    private DContract__c dContract;
    private Id contractId;
    
    public CalculateAllTime(ApexPages.StandardController sc) {
        this.backPage = sc.cancel();
        this.contractId = sc.getId();
    }
    
    public void runRecalculation() {
        ApexClass[] batchClass = [SELECT Id FROM ApexClass WHERE Name = 'CalculateAllTimeIncomeBatch'];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID IN: batchClass
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];
        
        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'All Time Income Batch is running right now, cannot schedule two jobs at the same time. Please try again after few minutes.'));
            return;
        }
		
        Database.executeBatch(new CalculateAllTimeIncomeBatch(),100);
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'All Time Income Batch was scheduled successfully, and the "ID Subcontract 1 Spend" and "ID Subcontract 2 Spend" fields for all Contracts will be updated in a few minutes.'));
    }
    
    public PageReference goBack() {
        return backPage;
    }
}