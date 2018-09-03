public class HQSyncDomainBatch extends HQSyncBatch {

    public HQSyncDomainBatch(String serverName, List<Integer> offsets, List<String> servers) {
        super(serverName, offsets, servers, HQSyncUtils.DOMAIN_SUFFIX, StatusLoggerUtils.HQ_SYNC_LOGGER, 'Domain');
    }

    public override void finish(Database.BatchableContext info) {
        StatusLoggerUtils.logInfo(StatusLoggerUtils.HQ_SYNC_LOGGER, this.jobName, this.addedRecords, 'Finished domains synchronization for server - ' + this.serverName);

        if (this.servers.size() > 0) {
            String nextServer = this.servers.get(0);
            Database.executeBatch(new HQSyncDomainBatch(nextServer, this.offsets, this.servers), 1);
        } else {
            HQSyncUtils.endDomainJob();
        }
    }

    protected override Integer processJSON(String jsonString) {
        Map<String, Domain__c> domainRecMap = new Map<String, Domain__c>();
        Map<String, Internal_Properties__c> internalPropsRecMap = new Map<String, Internal_Properties__c>();

        JSONParser parser = HQSyncUtils.createParser(jsonString);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                HQSyncDomainModel.DomanProjectSpaceWrapper projectSpaceMetadata = (HQSyncDomainModel.DomanProjectSpaceWrapper) parser.readValueAs(HQSyncDomainModel.DomanProjectSpaceWrapper.class);

                Domain__c domainRec = projectSpaceMetadata.domain_properties.createDbObject(serverName, projectSpaceMetadata.calculated_properties);
                domainRecMap.put(domainRec.id__c, domainRec);

                Internal_Properties__c InternalPropRec = projectSpaceMetadata.domain_properties.internal.createDbObject(serverName);
                internalPropsRecMap.put(domainRec.id__c, InternalPropRec);
           }
        }

        if (internalPropsRecMap.size() > 0) {
            upsert internalPropsRecMap.values();
        }

        Map<String, Id> externalIdMap = new Map<String, Id>();
        for (Domain__c domain : [SELECT Id, Internal_Properties__c, id__c FROM Domain__c WHERE id__c in :domainRecMap.keySet() AND Server_Name__c =: serverName]) {
            externalIdMap.put(domain.id__c, domain.Id);
        }

        for (Domain__c domain : domainRecMap.values()) {
            Internal_Properties__c internalPropObj = internalPropsRecMap.get(domain.id__c);
            domain.Internal_Properties__c = internalPropObj != null ? internalPropObj.Id : null;

            if (externalIdMap.containsKey(domain.id__c)) {
                domain.Id = externalIdMap.get(domain.id__c);
            }
        }

        if (domainRecMap.size() > 0) {
            upsert domainRecMap.values();
        }

        return domainRecMap.size();
    }

    protected override void handleError(Exception e, String message, Integer offset) {
        StatusLoggerUtils.logError(StatusLoggerUtils.HQ_SYNC_LOGGER, this.jobName, offset, this.serverName + ' - ' + message + ' - ' + e.getMessage());
    }
}