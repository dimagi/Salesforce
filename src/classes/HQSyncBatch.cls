/**
 * Batch job for fetching and processing data from HQ. It works with all HQ API Types, for example Domain, Invoice or Malt tables.
 */
public virtual class HQSyncBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {


    protected CommcareToSalesforceSettings__c serverSettings;
    protected HQSyncAPI hqAPI;
    protected Map<String, String> parameters;
    protected String serverName;
    protected List<String> servers;

    protected Integer size;
    protected Integer addedRecords;
    protected List<Integer> offsets;
    protected String loggerName;
    protected String jobName;
    protected Integer currentOffset;
    protected Integer currentTotalSize;

    public HQSyncBatch(String serverName, List<Integer> offsets, List<String> servers, String suffix, String loggerName, String jobName) {
        this.serverName = serverName;
        this.offsets = offsets;
        this.servers = servers;
        this.loggerName = loggerName;
        this.jobName = jobName;
        this.serverSettings = CommcareToSalesforceSettings__c.getInstance(this.serverName);
        this.addedRecords = 0;
        this.currentTotalSize = 0;
        this.parameters = new Map<String, String>();

        if (this.serverSettings == null) {
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Cannot find settings for server with given code : ' + this.serverName);
            throw ex;
        }
        this.size = this.serverSettings.API_Limit_Parameter__c != null ? Integer.valueOf(this.serverSettings.API_Limit_Parameter__c) : 10;
        this.hqAPI = new HQSyncAPI(this.serverSettings, suffix);

        if (this.servers.contains(this.serverName)) {
            this.servers.remove(this.servers.indexOf(this.serverName));
        }
        this.parameters.put(HQSyncUtils.FORMAT_PARAM, HQSyncUtils.JSON_PARAM);
        this.parameters.put(HQSyncUtils.OFFSET_PARAM, '0');
        this.parameters.put(HQSyncUtils.LIMIT_PARAM, String.valueOf(this.size));
    }

    public virtual Iterable<Integer> start(Database.BatchableContext BC) {
        if (this.offsets != null) {
            System.debug('Offset elements : ' + this.offsets.get(0));
            return this.offsets;
        }

        this.currentTotalSize = 0;
        try {
            this.currentTotalSize = this.hqAPI.getTotalCount(this.parameters);
        } catch (Exception e) {
            handleError(e, 'Cannot fetch total count.', -1);
        }
        this.parameters.put(HQSyncUtils.LIMIT_PARAM, String.valueOf(this.size));

        if (this.currentTotalSize == 0) {
            return new List<Integer>();
        }

        return HQSyncUtils.buildsOffsetList(this.currentTotalSize, this.size);
    }

    public virtual void execute(Database.BatchableContext info, List<Integer> offsetList) {
        for (Integer offset : offsetList) {
            Boolean success = false;
            Integer requests = 0;
            Exception e;
            HttpResponse response = null;
            this.currentOffset = offset;
            this.parameters.put(HQSyncUtils.OFFSET_PARAM, String.valueOf(offset));

            while (!success && requests < 3) { // we want try 3 times to fetch data if we faced any errors
                try {
                    response = this.hqAPI.httpGet(this.parameters);
                    this.addedRecords += this.processJSON(HQSyncUtils.replaceReservedWords(response.getBody()));
                    success = true;
                } catch (Exception ex) {
                    e = ex;
                    requests++;
                }
            }

            if (success == false && e != null) {
                handleError(e, '', offset);
            }
        }
    }

    public virtual void finish(Database.BatchableContext info) {
    }

    protected virtual Integer processJSON(String jsonString) {
        return 0;
    }

    protected virtual void handleError(Exception e, String message, Integer offset) {
    }
}