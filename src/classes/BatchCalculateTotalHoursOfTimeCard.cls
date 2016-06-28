/**
 * Calculates Services Spend field value for each contracts, runs BatchUpdateContractServicesSpend job.
 */
global class BatchCalculateTotalHoursOfTimeCard implements Database.Batchable<Time_Card__c> {

    private String contractId;
    private Map<Id, Integer> servicesSpendMap;

    global BatchCalculateTotalHoursOfTimeCard(){
        this.servicesSpendMap = new Map<Id, Integer>();
    }

    global BatchCalculateTotalHoursOfTimeCard(String contractId){
        this.contractId = contractId;
        this.servicesSpendMap = new Map<Id, Integer>();
    }

    global List<Time_Card__c> start(Database.BatchableContext context) {
        if (String.isEmpty(contractId)) {
            return [SELECT Client__c, labor_cost__c FROM Time_Card__c WHERE Client__c != ''];
        }
        return [SELECT Client__c, labor_cost__c FROM Time_Card__c WHERE Client__c =: contractId];
    }

    global void execute(Database.BatchableContext BC, List<Time_Card__c> scope){
        for (Time_Card__c tc : scope) {
            if (tc.labor_cost__c != null) {
                if (servicesSpendMap.containsKey(tc.Client__c)) {
                    servicesSpendMap.put(tc.Client__c, servicesSpendMap.get(tc.Client__c) + tc.labor_cost__c.intValue());
                } else {
                    servicesSpendMap.put(tc.Client__c, tc.labor_cost__c.intValue());
                }
            }
        }

    }

    global void finish(Database.BatchableContext context){
        // We must update values in contracts
        if (!Test.isRunningTest()) {
            BatchUpdateContractServicesSpend obj = new BatchUpdateContractServicesSpend(servicesSpendMap);
            Database.executeBatch(obj, 50);
        }
    }

    public Map<Id, Integer> getServicesSpendMap() {
        return this.servicesSpendMap;
    }
}