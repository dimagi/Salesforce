public class UpdateMaltTablesStatisticsBatch implements Database.Batchable<Domain__c>, Database.Stateful{

    private Map<String, Decimal> domainsWam;
    private String serverCode;

    public UpdateMaltTablesStatisticsBatch(String serverCode, Map<String, Decimal> domainsWam) {
        this.domainsWam = domainsWam;
        this.serverCode = serverCode;
    }

    public List<Domain__c> start(Database.BatchableContext BC) {
        return [SELECT Id, Name, Wam__c FROM Domain__c WHERE Name IN: this.domainsWam.keySet() AND Server_Name__c =: this.serverCode];
    }

    public void execute(Database.BatchableContext info, List<Domain__c> scope) {
        List<Domain__c> toUpdate = new List<Domain__c>();
        for (Domain__c dm : scope) {
            if (this.domainsWam.containsKey(dm.Name)) {
                dm.Wam__c = this.domainsWam.get(dm.Name);
                toUpdate.add(dm);
            }
        }
        if (toUpdate.size() > 0) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext info) {

    }
}