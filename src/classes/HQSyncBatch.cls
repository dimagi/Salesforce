/**
 * Batch job for fetching and processing data from HQ. It works with all HQ API Types, for example Domain, Invoice or Malt tables.
 */
public virtual class HQSyncBatch implements Database.Batchable<Integer>, Database.AllowsCallouts, Database.Stateful {

    protected HQSyncAPI hqAPI;
    protected CommcareToSalesforceSettings__c serverSettings;

    protected Map<String, String> parameters;
    protected Integer addedRecords;
    protected String serverName;
    protected List<Integer> offsets;
    protected List<String> servers;
    protected Integer size;

    public HQSyncBatch(String serverName, List<Integer> offsets, List<String> servers, String suffix) {
        this.serverName = serverName;
        this.offsets = offsets;
        this.servers = servers;
        this.serverSettings = CommcareToSalesforceSettings__c.getInstance(this.serverName);
        this.addedRecords = 0;
        this.parameters = new Map<String, String>();

        if (this.serverSettings == null) {
            this.handleError();
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Cannot find settings for server with given code : ' + this.serverName);
            throw ex;
        }
        this.size = this.serverSettings.API_Limit_Parameter__c != null ? Integer.valueOf(this.serverSettings.API_Limit_Parameter__c) : 10;
        this.hqAPI = new HQSyncAPI(this.serverSettings, suffix);

        if (this.servers.contains(this.serverName)) {
            this.servers.remove(this.servers.indexOf(this.serverName));
        }
    }

    public virtual Iterable<Integer> start(Database.BatchableContext BC) {
        if (this.offsets != null) {
            return this.offsets;
        }

        Integer totalCount = this.hqAPI.getTotalCount(this.parameters);
        this.parameters.put(HQSyncUtils.LIMIT_PARAM, String.valueOf(this.size));

        return HQSyncUtils.buildsOffsetList(totalCount, this.size);
    }

    public virtual void execute(Database.BatchableContext info, List<Integer> offsetList) {
        for (Integer offset : offsetList) {
            Boolean success = false;
            Integer requests = 0;
            Exception e;
            HttpResponse response = null;

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
                // TODO LOG
            }
        }
    }

    public virtual void finish(Database.BatchableContext info) {
    }

    protected virtual Integer processJSON(String jsonString) {
        return 0;
    }

    protected virtual void handleError() {
    }
}