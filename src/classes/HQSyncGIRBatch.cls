public class HQSyncGIRBatch extends HQSyncBatch {

    private Date monthDate;
    private Boolean forErrors;
    private Boolean manualRun;
    private Boolean syncError;
    private String userEmail;
    private Map<String, Decimal> domainsWam;
    private String errorMessage;

    public HQSyncGIRBatch(Date monthDate, String serverCode, List<String> nextServers, Boolean forErrors) {
        this(monthDate, serverCode, nextServers, forErrors, false, '');
    }

    public HQSyncGIRBatch(Date monthDate, String serverCode, List<String> nextServers, Boolean forErrors, Boolean manualRun, String userEmail) {
        super(serverCode, null, nextServers, HQSyncUtils.GIR_SUFFIX, StatusLoggerUtils.GIR_SYNC_LOGGER, HQSyncUtils.GIR);
        this.monthDate = monthDate;
        this.forErrors = forErrors;
        this.manualRun = manualRun;
        this.userEmail = userEmail;
        this.syncError = false;
        this.domainsWam = new Map<String, Decimal>();
        this.size = 60;

        Date tmpDate = this.monthDate;
        String startDate = tmpDate.year() + '-' + tmpDate.month() + '-' + tmpDate.day();
        tmpDate.addDays(1);
        String endDate = tmpDate.year() + '-' + tmpDate.month() + '-' + tmpDate.day();

        this.parameters.put('month__gte' , startDate);
        this.parameters.put('month__lte' , endDate);

        if (this.forErrors == true) {
            this.offsets = HQSyncUtils.getErrorOffsetList('GIR', this.serverName, this.monthDate);
        }
    }

    public override void finish(Database.BatchableContext info) {
        StatusLoggerUtils.logInfo(StatusLoggerUtils.GIR_SYNC_LOGGER, this.jobName, this.addedRecords, 'Finished GIR synchronization for server - '
                                                                            + this.serverName + ' for errors : ' + this.forErrors);

        if (this.manualRun == false) {
            if (this.servers.size() > 0) {
                String nextServer = this.servers.get(0);
                this.servers.remove(0);
                Database.executeBatch(new HQSyncGIRBatch(this.monthDate, nextServer, this.servers, this.forErrors), 1);
            } else {
                if (!Test.isRunningTest()) {
                    StatusLoggerUtils.sendLog(StatusLoggerUtils.GIR_SYNC_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
                    if ([SELECT Count() FROM HQ_Sync_Error__c WHERE Object_Type__c = 'GIR' AND Date__c =: this.monthDate] == 0) {
                        Database.executeBatch(new HQSyncUpdateDomainFieldsBatch(new HQSyncWamUpdate()));
                    }
                }
            }
        } else {  // for manual run we want sync only one server
            String emailSubject;
            String emailBody;
            if (this.syncError == false) {
                Database.executeBatch(new HQSyncUpdateDomainFieldsBatch(new HQSyncWamUpdate(), this.monthDate, this.serverName, this.domainsWam));
                emailSubject = 'GIR sync for - ' + this.serverName + ' ' + this.monthDate.month() + '/' + this.monthDate.year() + ' Status : Success';
                emailBody = 'GIR synchronization end. Data was saved in Domain Snapshots for : ' + this.serverName + ' ' + this.monthDate.month() + '/' + this.monthDate.year();
            } else {
                emailSubject = 'GIR sync for - ' + this.serverName + ' ' + this.monthDate.month() + '/' + this.monthDate.year() + ' Status : Error';
                emailBody = 'Cannot save GIR data for : ' + this.serverName + ' ' + this.monthDate.month() + '/' + this.monthDate.year()
                            + ' Errors : ' + this.errorMessage;
            }
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmail(this.userEmail, emailSubject, emailBody);
            }
        }
    }

    protected override Integer processJSON(String jsonString) {
        JSONParser parser = HQSyncUtils.createParser(jsonString);
        HQSyncModels.GIRModel objModel;
        if (manualRun == false) { // for manual we store data in domain snapshot only
            this.domainsWam = new Map<String, Decimal>();
        }

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                objModel = (HQSyncModels.GIRModel) parser.readValueAs(HQSyncModels.GIRModel.class);

                if (objModel.domain_name != null) {
                    if (objModel.domain_name.length() > 80) {
                        objModel.domain_name = objModel.domain_name.subString(0, 80);
                    }

                    if (objModel.wams_current != null && objModel.wams_current > 0) {
                        if (this.domainsWam.containsKey(objModel.domain_name)) {
                            this.domainsWam.put(objModel.domain_name, this.domainsWam.get(objModel.domain_name) + objModel.wams_current);
                        } else {
                            this.domainsWam.put(objModel.domain_name, objModel.wams_current);
                        }
                    }
                }
                parser.skipChildren();
            }
        }

        if (manualRun == false) { // for manual run we want sync all data into map and save result to the Domain snapshots

            List<Domain__c> domainsToUpdate = new List<Domain__c>();
            for (Domain__c domain : [SELECT Id, Name, Wam_TMP__c FROM Domain__c WHERE Name IN: this.domainsWam.keySet() AND Server_Name__c =: this.serverName]) {
                if (this.domainsWam.containsKey(domain.Name)) { // we update Wam_TMP__c because we have Wam__c history and we don't want a lot of history updateds for example 15 for 1 object sync no sense
                    domain.Wam_TMP__c = (domain.Wam_TMP__c != null ? domain.Wam_TMP__c : 0) + this.domainsWam.get(domain.Name);
                    domainsToUpdate.add(domain);
                }
            }

            List<HQ_Sync_Error__c> oldRunsErrors = [SELECT Id FROM HQ_Sync_Error__c WHERE Object_Type__c = 'GIR' AND Server_Name__c =: this.serverName AND Date__c =: this.monthDate AND Offset__c =: this.currentOffset];
            if (oldRunsErrors.size() > 0) { // if there was an error before we must delete it to avoid duplicated sum
                delete oldRunsErrors;
            }

            if (domainsToUpdate.size() > 0) {
                update domainsToUpdate;
            }

        }

        return this.domainsWam.size();
    }

    protected override void handleError(Exception e, String message, Integer offset) {
        if (manualRun == true) {
            if (this.syncError == false) { // we need store only first error
                this.syncError = true;
                this.errorMessage = e.getMessage();
            }
            return;
        }
        StatusLoggerUtils.logError(StatusLoggerUtils.GIR_SYNC_LOGGER, this.jobName, offset, this.serverName + ' - ' + message + ' - ' +  e.getMessage());

        List<HQ_Sync_Error__c> oldRunsErrors = [SELECT Id FROM HQ_Sync_Error__c WHERE Object_Type__c = 'GIR' AND Server_Name__c =: this.serverName AND Date__c =: this.monthDate AND Offset__c =: offset];
        if (oldRunsErrors.size() == 0) { // we don't want duplicated offset error
            insert new HQ_Sync_Error__c(Server_Name__c = this.serverName, Offset__c = offset, Object_Type__c = 'GIR', Date__c = this.monthDate);
        }
    }
}