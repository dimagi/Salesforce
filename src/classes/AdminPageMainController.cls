public class AdminPageMainController {

    public AdminPageMainController() {
        this.icdsPagination = new Pagination();

        this.batchPagination = new Pagination();
        this.batchPagination.pageSize = 50;

        this.upsertMode = false;
    }

    /**
     * Global Metrics tab
     */

    public void refreshDimagiToolsPage() {
        CorporateDashboardHelper.refreshAllGraphsFuture();
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Dimagi Tools Global Metrics tab refresh was scheduled'));
    }

    public void refreshSalesforcePage() {
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setMethod('PUT');
        req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v36.0/analytics/dashboards/01Zb0000000gCws'); // TODO move link to settings
        Http http = new Http();
        HttpResponse res = http.send(req);
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Salesforce Global Metrics refresh was scheduled'));
    }

    /**
     * Batch data tab
     */

    public Pagination batchPagination { get; set; }

    public List<AsyncApexJob> getBatchData() {
        List<AsyncApexJob> result = [SELECT Id, ApexClassID, JobType, MethodName, JobItemsProcessed, TotalJobItems, Status, ExtendedStatus, NumberOfErrors, CompletedDate, CreatedDate FROM AsyncApexJob
                                   WHERE (Status IN ('Aborted', 'Failed') OR (Status = 'Completed' AND ExtendedStatus != null AND ExtendedStatus != ''))
                                   ORDER BY CreatedDate DESC LIMIT : this.batchPagination.pageSize OFFSET : this.batchPagination.getOffsetValue()];
        this.batchPagination.handleResulSize([SELECT Count() FROM AsyncApexJob WHERE (Status IN ('Aborted', 'Failed') OR (Status = 'Completed' AND ExtendedStatus != null AND ExtendedStatus != ''))]);
        return result;
    }

    /**
     * ICDS snapshot data tab
     */

    public Pagination icdsPagination { get; set; }
    public ICDS_Domain_Snapshot__c icdsRecord { get; set; }
    public Id helperId { get ; set; }
    public Boolean upsertMode { get; set; }

    public List<ICDS_Domain_Snapshot__c> getIcdsData() {
        List<ICDS_Domain_Snapshot__c> result = [SELECT Id, Date__c, Active_Users__c, Forms__c, WAMs__c FROM ICDS_Domain_Snapshot__c
                                                ORDER BY Date__c DESC LIMIT : this.icdsPagination.pageSize OFFSET : this.icdsPagination.getOffsetValue()];
        this.icdsPagination.handleResulSize([SELECT Count() FROM ICDS_Domain_Snapshot__c]);
        return result;
    }

    public void switchToAddRecord() {
        this.upsertMode = true;
        Date helperDate = Date.today().addMonths(-1);
        Date snapshotDate = Date.newInstance(helperDate.year(), helperDate.month(), Date.daysInMonth(helperDate.year(), helperDate.month()));
        this.icdsRecord = new ICDS_Domain_Snapshot__c(Date__c = snapshotDate);
        this.helperId = null;
    }

    public void switchToUpdateRecord() {
        this.upsertMode = true;
        this.icdsRecord = [SELECT Id, Date__c, Active_Users__c, Forms__c, WAMs__c FROM ICDS_Domain_Snapshot__c WHERE Id =: this.helperId];
        this.helperId = null;
    }

    public void saveIcdsRecord() {
        if (this.icdsRecord.Id != null) {
            update this.icdsRecord;
        } else {
            insert this.icdsRecord;
        }
        openICDSList();
    }

    public void deleteIcdsRecord() {
        if (this.icdsRecord.Id != null) {
            delete [SELECT Id FROM ICDS_Domain_Snapshot__c WHERE Id =: this.icdsRecord.Id];
        }
        openICDSList();
    }

    public void openICDSList() {
        this.helperId = null;
        this.upsertMode = false;
    }

    /**
     * Malt tables data tab
     */

    /**
     * GIR data tab
     */

}