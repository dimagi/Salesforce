/**
 * Calculates Services Spend field value for each contracts, runs BatchUpdateContractServicesSpend job for update values in contracts.
 */
public without sharing class BatchCalculateTotalHoursOfTimeCard implements Database.Batchable<sObject>, Database.Stateful {

    private List<String> contractIds;
    private Map<Id, Decimal> servicesSpendMap;
    private String lastEmployee;
    private List<SalaryHistoryRecord> employeeSalaryHistory;
    private SalaryHistoryHelper salaryHistoryHelper;
    private Boolean updatedContracts;

    public BatchCalculateTotalHoursOfTimeCard(){
        this(new List<String>());
    }

    public BatchCalculateTotalHoursOfTimeCard(Boolean updatedContracts){
        this(new List<String>(), true);
    }

    public BatchCalculateTotalHoursOfTimeCard(String contractId){
        this(new List<String> {contractId});
    }

    public BatchCalculateTotalHoursOfTimeCard(List<String> contractIds){
        this(contractIds, false);
    }

    public BatchCalculateTotalHoursOfTimeCard(List<String> contractIds, Boolean updatedContracts) {
        this.updatedContracts = updatedContracts;
        this.contractIds = contractIds;
        this.servicesSpendMap = new Map<Id, Decimal>();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();
        this.employeeSalaryHistory = new List<SalaryHistoryRecord>();
        Set<Id> parentAndChildContracts = new Set<Id>();

        String query;
        if (this.updatedContracts == true) { // only with updated time cards
            query = 'SELECT Client__c, Time_Card_Rate_Cost__c, Employee__c, Date__c FROM Time_Card__c WHERE Client__r.Require_Services_Spend_Refresh__c = true ORDER BY Employee__c';
        } else if (contractIds.size() == 0) {
            query = 'SELECT Client__c, Time_Card_Rate_Cost__c, Employee__c, Date__c FROM Time_Card__c WHERE Employee__c != \'\' ORDER BY Employee__c';
        } else {
            for (String conId : contractIds) {
                parentAndChildContracts.add(conId);
            }
            for (DContract__c con : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Id IN: parentAndChildContracts AND Parent_Contract__c != '']) {
                parentAndChildContracts.add(con.Parent_Contract__c); // Load all parents
            }
            for (DContract__c con : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Parent_Contract__c IN: parentAndChildContracts]) {
                parentAndChildContracts.add(con.Id); // Add childs
            }

            for (Id elId : contractIds) {
                parentAndChildContracts.add(elId);
            }

            query = 'SELECT Client__c, Time_Card_Rate_Cost__c, Employee__c, Date__c FROM Time_Card__c WHERE Client__c IN: parentAndChildContracts ORDER BY Employee__c';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
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

    public void finish(Database.BatchableContext context){
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