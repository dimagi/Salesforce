public class HQSyncMaltTablesBatch extends HQSyncBatch {

    private Date monthDate;
    private Boolean forErrors;

    public HQSyncMaltTablesBatch(Date monthDate, String serverCode, List<String> nextServers, Boolean forErrors) {
        super(serverCode, null, nextServers, HQSyncUtils.MALT_SUFFIX, StatusLoggerUtils.MALT_SYNC_LOGGER, 'Malt Tables');
        this.monthDate = monthDate;
        this.forErrors = forErrors;
        this.size = 100;

        Date tmpDate = monthDate;
        String startDate = tmpDate.year() + '-' + tmpDate.month() + '-' + tmpDate.day();
        tmpDate.addDays(1);
        String endDate = tmpDate.year() + '-' + tmpDate.month() + '-' + tmpDate.day();

        this.parameters.put('month__gte' , startDate);
        this.parameters.put('month__lte' , endDate);
    }

    public override void finish(Database.BatchableContext info) {
        StatusLoggerUtils.logInfo(StatusLoggerUtils.MALT_SYNC_LOGGER, this.jobName + ' - ' + this.serverName, this.addedRecords, 'Finished malt tables synchronization for server - ' + this.serverName);

        if (this.servers.size() > 0) {
            String nextServer = this.servers.get(0);
            this.servers.remove(0);
            Database.executeBatch(new HQSyncMaltTablesBatch(this.monthDate, nextServer, this.servers, false), 1);
        } else {
            StatusLoggerUtils.sendLog(StatusLoggerUtils.MALT_SYNC_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        }
    }

    protected override Integer processJSON(String jsonString) {
        JSONParser parser = HQSyncUtils.createParser(jsonString);
        Integer size = 0;
        HQSyncModels.MaltTablesModel objModel;
        HQ_Sync_Compressed_Data__c compressedData = new HQ_Sync_Compressed_Data__c(Server_Name__c = this.serverName, Field_Name__c = 'num_of_forms',
                                                            Offset__c = this.currentOffset, Type__c = 'Malt Tables', Status__c = 'Success');
        SObject sObj = (SObject) compressedData;

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                objModel = (HQSyncModels.MaltTablesModel) parser.readValueAs(HQSyncModels.MaltTablesModel.class);

                if (objModel.domain_name != null) {
                    if (objModel.domain_name.length() > 80) {
                        objModel.domain_name = objModel.domain_name.subString(0, 80);
                    }
                    HQSyncUtils.setSObjectFieldValue(sObj, objModel.num_of_forms != null ? objModel.num_of_forms : 0, objModel.domain_name, size + 1);
                    size++;
                }
                parser.skipChildren();
            }
        }

        compressedData = (HQ_Sync_Compressed_Data__c) sObj;
        compressedData.Size__c = size;
        insert compressedData;

        return size;
    }

    protected override void handleError(Exception e, Integer offset) {
        StatusLoggerUtils.logError(StatusLoggerUtils.MALT_SYNC_LOGGER, this.jobName + ' - ' + this.serverName, offset, e.getMessage());
        // insert new sobj for error offset
    }
}