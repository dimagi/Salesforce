/**
 * Calculates Services Spend field value for each contracts, runs BatchUpdateContractServicesSpend job.
 */
global without sharing class BatchCalculateTotalHoursOfTimeCard implements Database.Batchable<sObject>, Database.Stateful {

    private List<String> contractIds;
    private Map<Id, Decimal> servicesSpendMap;
    private String lastEmployee;
    private List<SalaryHistoryRecord> employeeSalaryHistory;
    private SalaryHistoryHelper salaryHistoryHelper;
    private Boolean testMode;

    global BatchCalculateTotalHoursOfTimeCard(){
        this.contractIds = new List<String>();
        this.testMode = false;
        this.servicesSpendMap = new Map<Id, Decimal>();
    }

    global BatchCalculateTotalHoursOfTimeCard(String contractId){
        this(new List<String> {contractId});
    }

    global BatchCalculateTotalHoursOfTimeCard(List<String> contractIds){
        this.testMode = false;
        this.contractIds = contractIds;
        this.servicesSpendMap = new Map<Id, Decimal>();
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();
        this.employeeSalaryHistory = new List<SalaryHistoryRecord>();

        String query;
        if (contractIds.size() == 0) {
            query = 'SELECT Client__c, Time_Card_Rate_Cost__c, Employee__c, Date__c FROM Time_Card__c WHERE Employee__c != \'\' ORDER BY Employee__c';
        } else {
            query = 'SELECT Client__c, Time_Card_Rate_Cost__c, Employee__c, Date__c FROM Time_Card__c WHERE Client__c IN: contractIds ORDER BY Employee__c';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        for (sObject obj : scope) {
            Time_Card__c tc = (Time_Card__c) obj;

            if (tc.Time_Card_Rate_Cost__c != null) {
                if (servicesSpendMap.containsKey(tc.Client__c)) {
                    servicesSpendMap.put(tc.Client__c, servicesSpendMap.get(tc.Client__c) + tc.Time_Card_Rate_Cost__c);
                } else {
                    servicesSpendMap.put(tc.Client__c, tc.Time_Card_Rate_Cost__c);
                }
            }
        }
    }

    global void finish(Database.BatchableContext context){
        // We must replace values in contracts
        if (!Test.isRunningTest()) {
            BatchUpdateContractServicesSpend obj = new BatchUpdateContractServicesSpend(servicesSpendMap);
            Database.executeBatch(obj, 50);
        }
    }

    public Map<Id, Decimal> getServicesSpendMap() {
        return this.servicesSpendMap;
    }
}