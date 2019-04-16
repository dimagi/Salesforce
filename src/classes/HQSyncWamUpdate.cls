public class HQSyncWamUpdate implements HQSyncDomainFieldUpdater {

    public HQSyncWamUpdate() {
    }

    public void updateSyncField(Domain__c domain) {
        domain.Wam__c = domain.Wam_TMP__c != null ? domain.Wam_TMP__c : 0;
        domain.Wam_TMP__c = 0;
    }

    public Integer getSyncFieldValue(Domain__c domain) {
        return Integer.valueOf(domain.Wam__c);
    }

    public String getSyncFieldName() {
        return 'Wam__c';
    }
}