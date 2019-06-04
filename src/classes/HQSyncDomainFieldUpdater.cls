public interface HQSyncDomainFieldUpdater {

    /**
     * Update domain field with data from HQ server.
     */
    void updateSyncField(Domain__c domain);

    /**
     * Update snapshot field with data from HQ server.
     */
    void updateSyncField(Domain__c domain, Domain_Monthly_Snapshot__c snapshot);

    /**
     * Update snapshot field with given data.
     */
    void updateSyncField(Decimal value, Domain_Monthly_Snapshot__c snapshot);

    /**
     * Fetch correct value from domain object.
     */
    Integer getSyncFieldValue(Domain__c domain);

    /**
     * Returns field which is updated by implementation.
     */
    String getSyncFieldName();
}