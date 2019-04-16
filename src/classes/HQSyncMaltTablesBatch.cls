public class HQSyncMaltTablesBatch extends HQSyncBatch {

    private Date monthDate;
    private Boolean forErrors;

    public HQSyncMaltTablesBatch(Date monthDate, String serverCode, List<String> nextServers, Boolean forErrors) {
        super(serverCode, null, nextServers, HQSyncUtils.MALT_SUFFIX, StatusLoggerUtils.MALT_SYNC_LOGGER, HQSyncUtils.MALT_TABLES);
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
            this.offsets = HQSyncUtils.getErrorOffsetList('Malt Tables', this.serverName, this.monthDate);
        }
    }

    public override void finish(Database.BatchableContext info) {
        StatusLoggerUtils.logInfo(StatusLoggerUtils.MALT_SYNC_LOGGER, this.jobName, this.addedRecords, 'Finished malt tables synchronization for server - '
                                                                            + this.serverName + ' for errors : ' + this.forErrors);

        if (this.servers.size() > 0) {
            String nextServer = this.servers.get(0);
            this.servers.remove(0);
            Database.executeBatch(new HQSyncMaltTablesBatch(this.monthDate, nextServer, this.servers, this.forErrors), 1);
        } else {
            if (!Test.isRunningTest()) {
                StatusLoggerUtils.sendLog(StatusLoggerUtils.MALT_SYNC_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
                if ([SELECT Count() FROM HQ_Sync_Error__c WHERE Object_Type__c = 'Malt Tables' AND Date__c =: this.monthDate] == 0) {
                    Database.executeBatch(new HQSyncUpdateDomainFieldsBatch(true, new HQSyncFormsForPeriodUpdate()));
                }
            }
        }
    }

    protected override Integer processJSON(String jsonString) {
        JSONParser parser = HQSyncUtils.createParser(jsonString);
        Integer size = 0;
        HQSyncModels.MaltTablesModel objModel;
        Map<String, Decimal> domainsWam = new Map<String, Decimal>();

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                objModel = (HQSyncModels.MaltTablesModel) parser.readValueAs(HQSyncModels.MaltTablesModel.class);

                if (objModel.domain_name != null) {
                    if (objModel.domain_name.length() > 80) {
                        objModel.domain_name = objModel.domain_name.subString(0, 80);
                    }

                    if (objModel.num_of_forms == null && objModel.num_of_forms == 0) {
                        continue; // we skip this object if forms is equal to 0 or null we don't need add anything
                    }

                    if (domainsWam.containsKey(objModel.domain_name)) {
                        domainsWam.put(objModel.domain_name, domainsWam.get(objModel.domain_name) + objModel.num_of_forms);
                    } else {
                        domainsWam.put(objModel.domain_name, (objModel.num_of_forms != null ? objModel.num_of_forms : 0));
                    }
                    size++;
                }
                parser.skipChildren();
            }
        }

        List<Domain__c> domainsToUpdate = new List<Domain__c>();
        for (Domain__c domain : [SELECT Id, Name, Forms_for_Period_TMP__c FROM Domain__c WHERE Name IN: domainsWam.keySet() AND Server_Name__c =: this.serverName]) {
            if (domainsWam.containsKey(domain.Name)) { // we update Forms_for_Period_TMP__c because we have Forms_for_Period__c history and we don't want a lot of history updateds for example 15 for 1 object sync no sense
                domain.Forms_for_Period_TMP__c = (domain.Forms_for_Period_TMP__c != null ? domain.Forms_for_Period_TMP__c : 0) + domainsWam.get(domain.Name);
                domainsToUpdate.add(domain);
            }
        }

        List<HQ_Sync_Error__c> oldRunsErrors = [SELECT Id FROM HQ_Sync_Error__c WHERE Object_Type__c = 'Malt Tables' AND Server_Name__c =: this.serverName AND Date__c =: this.monthDate AND Offset__c =: this.currentOffset];
        if (oldRunsErrors.size() > 0) { // if there was an error before we must delete it to avoid duplicated sum
            delete oldRunsErrors;
        }

        if (domainsToUpdate.size() > 0) {
            update domainsToUpdate;
        }
        return size;
    }

    protected override void handleError(Exception e, String message, Integer offset) {
        StatusLoggerUtils.logError(StatusLoggerUtils.MALT_SYNC_LOGGER, this.jobName, offset, this.serverName + ' - ' + message + ' - ' + e.getMessage());
        insert new HQ_Sync_Error__c(Server_Name__c = this.serverName, Offset__c = offset, Object_Type__c = 'Malt Tables', Date__c = this.monthDate);
    }
}