/**
 * Calculates Services Spend field value for each contracts, runs BatchUpdateContractServicesSpend job.
 */
global class BatchCalculateTotalHoursOfTimeCard implements Database.Batchable<sObject>, Database.Stateful {

    private String contractId;
    private Map<Id, Integer> servicesSpendMap;

    global BatchCalculateTotalHoursOfTimeCard(){
        this.servicesSpendMap = new Map<Id, Integer>();
    }

    global BatchCalculateTotalHoursOfTimeCard(String contractId){
        this.contractId = contractId;
        this.servicesSpendMap = new Map<Id, Integer>();
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        String query;
        if (String.isEmpty(contractId)) {
            query = 'SELECT Client__c, labor_cost__c FROM Time_Card__c';
        } else {
            query = 'SELECT Client__c, labor_cost__c FROM Time_Card__c WHERE Client__c =: contractId';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        for (sObject obj : scope) {
            Time_Card__c tc = (Time_Card__c) obj;
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