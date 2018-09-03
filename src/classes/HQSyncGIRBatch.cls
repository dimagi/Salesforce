public class HQSyncGIRBatch extends HQSyncBatch {

    private Date monthDate;
    private Boolean forErrors;

    public HQSyncGIRBatch(Date monthDate, String serverCode, List<String> nextServers, Boolean forErrors) {
        super(serverCode, null, nextServers, HQSyncUtils.GIR_SUFFIX, StatusLoggerUtils.GIR_SYNC_LOGGER, 'GIR');
        this.monthDate = monthDate;
        this.forErrors = forErrors;
        this.size = 60;

        Date tmpDate = monthDate;
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
        StatusLoggerUtils.logInfo(StatusLoggerUtils.GIR_SYNC_LOGGER, this.jobName + ' - ' + this.serverName, this.addedRecords, 'Finished GIR synchronization for server - '
                                                                            + this.serverName + ' for errors : ' + this.forErrors);

        if (this.servers.size() > 0) {
            String nextServer = this.servers.get(0);
            this.servers.remove(0);
            Database.executeBatch(new HQSyncMaltTablesBatch(this.monthDate, nextServer, this.servers, this.forErrors), 1);
        } else {
            if (!Test.isRunningTest()) {
                StatusLoggerUtils.sendLog(StatusLoggerUtils.GIR_SYNC_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
                if ([SELECT Count() FROM HQ_Sync_Error__c WHERE (Object_Type__c = 'Malt Tables' OR Object_Type__c = 'GIR') AND Date__c =: this.monthDate] > 0) {
                   Database.executeBatch(new HQSyncUpdateDomainFieldsBatch(true));
                }
            }
        }
    }

    protected override Integer processJSON(String jsonString) {
        JSONParser parser = HQSyncUtils.createParser(jsonString);
        Integer size = 0;
        HQSyncModels.GIRModel objModel;
        Map<String, Decimal> domainsWam = new Map<String, Decimal>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                objModel = (HQSyncModels.GIRModel) parser.readValueAs(HQSyncModels.GIRModel.class);

                if (objModel.domain_name != null) {
                    if (objModel.domain_name.length() > 80) {
                        objModel.domain_name = objModel.domain_name.subString(0, 80);
                    }

                    if (objModel.wams_current == null || objModel.wams_current == 0) {
                        continue; // we skip this object if forms is equal to 0 or null we don't need add anything
                    }

                    if (domainsWam.containsKey(objModel.domain_name)) {
                        domainsWam.put(objModel.domain_name, domainsWam.get(objModel.domain_name) + objModel.wams_current);
                    } else {
                        domainsWam.put(objModel.domain_name, objModel.wams_current);
                    }
                    size++;
                }
                parser.skipChildren();
            }
        }

        List<Domain__c> domainsToUpdate = new List<Domain__c>();
        for (Domain__c domain : [SELECT Id, Name, Wam_TMP__c FROM Domain__c WHERE Name IN: domainsWam.keySet()]) {
            if (domainsWam.containsKey(domain.Name)) { // we update Forms_for_Period_TMP__c because we have Forms_for_Period__c history and we don't want a lot of history updateds for example 15 for 1 object sync no sense
                domain.Wam_TMP__c = (domain.Wam_TMP__c != null ? domain.Wam_TMP__c : 0) + domainsWam.get(domain.Name);
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

        return size;
    }

    protected override void handleError(Exception e, String message, Integer offset) {
        StatusLoggerUtils.logError(StatusLoggerUtils.GIR_SYNC_LOGGER, this.jobName, offset, this.serverName + ' - ' + message + ' - ' +  e.getMessage());
        insert new HQ_Sync_Error__c(Server_Name__c = this.serverName, Offset__c = offset, Object_Type__c = 'GIR', Date__c = this.monthDate);
    }
}