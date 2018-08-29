public class HQSyncGIRBatch extends HQSyncBatch {

    private Date monthDate;
    private Boolean forErrors;

    public HQSyncGIRBatch(Date monthDate, String serverCode, List<String> nextServers, Boolean forErrors) {
        super(serverCode, null, nextServers, HQSyncUtils.GIR_SUFFIX, StatusLoggerUtils.GIR_SYNC_LOGGER, 'GIR');
        this.monthDate = monthDate;
        this.forErrors = forErrors;
        this.size = 100;

        Date tmpDate = monthDate;
        String startDate = tmpDate.year() + '-' + tmpDate.month() + '-' + tmpDate.day();
        tmpDate.addDays(1);
        String endDate = tmpDate.year() + '-' + tmpDate.month() + '-' + tmpDate.day();

        this.parameters.put('month__gte' , startDate); // todo
        this.parameters.put('month__lte' , endDate);
    }

    public override void finish(Database.BatchableContext info) {
        StatusLoggerUtils.logInfo(StatusLoggerUtils.GIR_SYNC_LOGGER, this.jobName + ' - ' + this.serverName, this.addedRecords, 'Finished GIR synchronization for server - ' + this.serverName);


        if (nextServers.size() > 0) {
            String nextServer = this.nextServers.get(0);
            this.nextServers.remove(0);
            Database.executeBatch(new HQSyncMaltTablesBatch(this.monthDate, nextServer, this.nextServers), 1);
        } else {
            StatusLoggerUtils.sendLog(StatusLoggerUtils.GIR_SYNC_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        }
    }

    protected override Integer processJSON(String jsonString) {
        JSONParser parser = HQSyncUtils.createParser(res.getBody());
        Integer size = 0;
        HQSyncModels.GIRModel objModel;
        SObject sObj = null;

        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                objModel = (HQSyncModels.GIRModel) parser.readValueAs(HQSyncModels.GIRModel.class);

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

        insert sObj;
        return size;
    }

    protected override void handleError(Exception e, Integer offset) {
        StatusLoggerUtils.logError(StatusLoggerUtils.GIR_SYNC_LOGGER, this.jobName + ' - ' + this.serverName, offset, e.getMessage());
        // insert new sobj for error offset
    }
}