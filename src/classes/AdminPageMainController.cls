public class AdminPageMainController {

    public AdminPageMainController() {
        this.icdsPagination = new Pagination();

        this.batchPagination = new Pagination();
        this.batchPagination.pageSize = 50;

        this.upsertMode = false;
        initMaltTablesAndGIRTabs();
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
     * Malt tables & GIR data tabs
     */

    public Integer syncMonthMalt { get; set; }
    public Integer syncYearMalt { get; set; }
    public String syncServerMalt { get; set; }
    public Integer syncMonthWam { get; set; }
    public Integer syncYearWam { get; set; }
    public String syncServerWam { get; set; }
    public List<SelectOption> syncYears { get; set; }
    public List<SelectOption> serverCodes { get; set;}

    public void initMaltTablesAndGIRTabs() {
        List<String> values = HQSyncUtils.getCommcareServers(true);
        this.serverCodes = new List<SelectOption>();
        this.syncServerMalt = values.get(0);
        this.syncServerWam = values.get(0);
        for (String val : values) {
            this.serverCodes.add(new SelectOption(val, val));
        }

        Date lastMonth = Date.today().addMonths(-1);
        this.syncMonthMalt = lastMonth.month();
        this.syncYearMalt = lastMonth.year();
        this.syncMonthWam = lastMonth.month();
        this.syncYearWam = lastMonth.year();

        this.syncYears = new List<SelectOption>();
        this.syncYears.add(new SelectOption(String.valueOf(this.syncYearWam), String.valueOf(this.syncYearWam)));
        Integer helperYear = this.syncYearWam - 1;
        while (this.syncYearWam - 3 < helperYear && helperYear > 2018) { // we add last 3 years
            this.syncYears.add(new SelectOption(String.valueOf(helperYear), String.valueOf(helperYear)));
            helperYear--;
        }
    }

    public void scheduleMaltSync() {
        if (!String.isNotEmpty(this.syncServerMalt)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Server code cannot be empty.'));
            return;
        }
        if (isMaltOrGIRJobScheduled()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot run synchronization job. Sync running instance was found already.'));
            return;
        }
        if (isSyncDateValid(this.syncYearMalt, this.syncMonthMalt)) {
            User activeUser = [SELECT Email FROM User WHERE Username =: UserInfo.getUserName() LIMIT 1];
            String userEmail = activeUser.Email;

            Database.executeBatch(new HQSyncMaltTablesBatch(Date.newInstance(this.syncYearMalt, this.syncMonthMalt, 1),
                                                     this.syncServerMalt, new List<String>(), false,
                                                     true, userEmail), 1);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Malt tables scheduled for : ' + this.syncServerMalt + ' ' + this.syncMonthMalt + '/' + this.syncYearMalt + ' - status email will be send when synchronization will end.'));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Date is invalid : ' + this.syncMonthMalt + '/' + this.syncYearMalt
                                                            + ' - date must be greater or equal to 04/2019 and less than ' + Date.today().month() + '/' + Date.today().year()));
        }
    }

    public void scheduleWamSync() {
        if (!String.isNotEmpty(this.syncServerWam)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Server code cannot be empty.'));
            return;
        }
        if (isMaltOrGIRJobScheduled()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot run synchronization job. Sync running instance was found already.'));
            return;
        }
        if (isSyncDateValid(this.syncYearWam, this.syncMonthWam)) {
            User activeUser = [SELECT Email FROM User WHERE Username =: UserInfo.getUserName() LIMIT 1];
            String userEmail = activeUser.Email;

            Database.executeBatch(new HQSyncGIRBatch(Date.newInstance(this.syncYearWam, this.syncMonthWam, 1),
                                                     this.syncServerWam, new List<String>(), false,
                                                     true, userEmail), 1);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Malt tables scheduled for : ' + this.syncServerWam + ' ' + this.syncMonthWam + '/' + this.syncYearWam + ' - status email will be send when synchronization will end.'));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Date is invalid : ' + this.syncMonthWam + '/' + this.syncYearWam
                                                            + ' - date must be greater or equal to 04/2019 and less than ' + Date.today().month() + '/' + Date.today().year()));
        }
    }

    public Boolean isSyncDateValid(Integer year, Integer month) {
        if (year != null && month != null && Date.newInstance(year, month, 1) >= Date.newInstance(2019, 4, 1)
                         && Date.newInstance(year, month, 1) < Date.today().toStartOfMonth()) { // date when we deployed upgraded domain snapshot
            return true;
        }
        return false;
    }

    public Boolean isMaltOrGIRJobScheduled() {
        return SFUtils.isJobScheduled('HQSyncGIRBatch') || SFUtils.isJobScheduled('HQSyncMaltTablesBatch') || SFUtils.isJobScheduled('HQSyncUpdateDomainFieldsBatch');
    }
}