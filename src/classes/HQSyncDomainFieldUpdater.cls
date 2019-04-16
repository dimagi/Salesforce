public interface HQSyncDomainFieldUpdater {

    /**
     * Update domain field with data from HQ server.
     */
    void updateSyncField(Domain__c domain);

    /**
     * Fetch correct value from domain object.
     */
    Integer getSyncFieldValue(Domain__c domain);

    /**
     * Returns field which is updated by implementation.
     */
    String getSyncFieldName();
}