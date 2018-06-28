/**
 * Controller for scheduling services spend recalculation.
 */
public class DContractRecalculationController {

    private PageReference backPage = null;
    private DContract__c dContract;
    private Id contractId;

    public DContractRecalculationController(ApexPages.StandardController sc) {
        this.backPage = sc.cancel();
        this.contractId = sc.getId();
    }

    public void runRecalculation() {
        ApexClass[] batchClass = [SELECT Id FROM ApexClass WHERE Name='TimeCardCalculator' OR Name = 'BatchCalculateTotalHoursOfTimeCard' OR Name = 'BatchUpdateContractServicesSpend'
                                                                OR Name = 'BatchRecalculateTimeCardCost' OR Name = 'TimeCardCaseUpdateBatch'];
        AsyncApexJob[] batchClassJobList = [SELECT Id, JobItemsProcessed, TotalJobItems, createdDate FROM AsyncApexJob WHERE ApexClassID IN: batchClass
                                            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing') ORDER BY createdDate DESC LIMIT 1];

        if(batchClassJobList != null && batchClassJobList.size() > 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Time Card Calculator is running right now, cannot schedule two jobs at the same time. Please try again after few minutes.'));
            return;
        }

        Database.executeBatch(new TimeCardCalculator(new Set<Id> { this.contractId }), 200);
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Services Spend recalculation was scheduled, it should be updated in a few minutes for contract and for it parent/childs'));
    }

    public PageReference goBack() {
        return backPage;
    }
}