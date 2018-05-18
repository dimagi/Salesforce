/**
 * Calculates Services Spend field value for each contracts, runs BatchUpdateContractServicesSpend job for update values in contracts.
 */
public without sharing class BatchCalculateTotalHoursOfTimeCard implements Database.Batchable<sObject>, Database.Stateful {

    private Set<Id> contractIds;
    private Map<Id, Decimal> servicesSpendMap;
    private String lastEmployee;
    private List<SalaryHistoryRecord> employeeSalaryHistory;
    private SalaryHistoryHelper salaryHistoryHelper;
    private Boolean updatedContracts;

    public BatchCalculateTotalHoursOfTimeCard(){
        this(new Set<Id>());
    }

    public BatchCalculateTotalHoursOfTimeCard(Boolean updatedContracts){
        this(new Set<Id>(), true);
    }

    public BatchCalculateTotalHoursOfTimeCard(Id contractId){
        this(new Set<Id> {contractId});
    }

    public BatchCalculateTotalHoursOfTimeCard(Set<Id> contractIds){
        this(contractIds, false);
    }

    public BatchCalculateTotalHoursOfTimeCard(Set<Id> contractIds, Boolean updatedContracts) {
        this.updatedContracts = updatedContracts;
        this.contractIds = contractIds;
        this.servicesSpendMap = new Map<Id, Decimal>();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();
        this.employeeSalaryHistory = new List<SalaryHistoryRecord>();
        Set<Id> parentAndChildContracts = new Set<Id>();

        if (this.contractIds.size() > 0) {
            for (String conId : this.contractIds) {
                parentAndChildContracts.add(conId);
                this.servicesSpendMap.put(conId, 0);
            }
        }

        if (this.updatedContracts == true) {
            for (DContract__c con : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Require_Services_Spend_Refresh__c = true AND Id NOT IN: parentAndChildContracts ]) {
                parentAndChildContracts.add(con.Id);
                this.servicesSpendMap.put(con.Id, 0);
            }
        }

        for (DContract__c con : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Id IN: parentAndChildContracts AND Parent_Contract__c != '']) {
            parentAndChildContracts.add(con.Parent_Contract__c);
            this.servicesSpendMap.put(con.Parent_Contract__c, 0); // Load all parents
        }
        for (DContract__c con : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Parent_Contract__c IN: parentAndChildContracts]) {
            parentAndChildContracts.add(con.Id);
            this.servicesSpendMap.put(con.Id, 0);// Add childs
        }

        String query;
        if (this.updatedContracts == true && contractIds.size() > 0) { // Require_Services_Spend_Refresh__c this field is set to true when time card client was updated, we must remove cost from old contract
            query = 'SELECT Client__c, Total__c, Time_Card_Salary__c, Billing_Rate__c, Employee__c, Date__c FROM Time_Card__c WHERE Client__c IN: parentAndChildContracts OR Client__r.Require_Services_Spend_Refresh__c = true ORDER BY Employee__c';
        } else if (this.updatedContracts == true) { // only with updated time cards
            query = 'SELECT Client__c, Total__c, Time_Card_Salary__c, Billing_Rate__c, Employee__c, Date__c FROM Time_Card__c WHERE Client__r.Require_Services_Spend_Refresh__c = true ORDER BY Employee__c';
        } else if (contractIds.size() > 0) {
            query = 'SELECT Client__c, Total__c, Time_Card_Salary__c, Billing_Rate__c, Employee__c, Date__c FROM Time_Card__c WHERE Client__c IN: parentAndChildContracts ORDER BY Employee__c';
        } else {
            query = 'SELECT Client__c, Total__c, Time_Card_Salary__c, Billing_Rate__c, Employee__c, Date__c FROM Time_Card__c WHERE Employee__c != \'\' ORDER BY Employee__c';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        for (sObject obj : scope) {
            Time_Card__c tc = (Time_Card__c) obj;

            Decimal value = (tc.Total__c * (tc.Time_Card_Salary__c != null ? tc.Time_Card_Salary__c : 0.0) * (tc.Billing_Rate__c != null ? tc.Billing_Rate__c : 0.0)).setScale(8);
            if (servicesSpendMap.containsKey(tc.Client__c)) {
                servicesSpendMap.put(tc.Client__c, servicesSpendMap.get(tc.Client__c) + value);
            } else {
                servicesSpendMap.put(tc.Client__c, value);
            }
        }
    }

    public void finish(Database.BatchableContext context){
        if (this.contractIds.size() == 0 && this.updatedContracts == false) {
            for (DContract__c dContract : [SELECT Id FROM DContract__c WHERE Id NOT IN: this.servicesSpendMap.keySet()]) {
                this.servicesSpendMap.put(dContract.Id, 0);
            }
        }

        // We must replace values in contracts
        if (!Test.isRunningTest()) {
            BatchUpdateContractServicesSpend obj = new BatchUpdateContractServicesSpend(this.servicesSpendMap);
            Database.executeBatch(obj, 50);
        }
    }

    public Map<Id, Decimal> getServicesSpendMap() {
        return this.servicesSpendMap;
    }
}