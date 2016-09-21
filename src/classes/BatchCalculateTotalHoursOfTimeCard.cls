/**
 * Calculates Services Spend field value for each contracts, runs BatchUpdateContractServicesSpend job.
 */
global class BatchCalculateTotalHoursOfTimeCard implements Database.Batchable<sObject>, Database.Stateful {

    private String contractId;
    private Map<Id, Decimal> servicesSpendMap;
    private String lastEmployee;
    private List<SalaryHistoryRecord> employeeSalaryHistory;
    private SalaryHistoryHelper salaryHistoryHelper;

    global BatchCalculateTotalHoursOfTimeCard(){
        this.servicesSpendMap = new Map<Id, Decimal>();
    }

    global BatchCalculateTotalHoursOfTimeCard(String contractId){
        this.contractId = contractId;
        this.servicesSpendMap = new Map<Id, Decimal>();
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();
        this.employeeSalaryHistory = new List<SalaryHistoryRecord>();
        String query;
        if (String.isEmpty(contractId)) {
            query = 'SELECT Client__c, Total__c, Employee__c, Date__c FROM Time_Card__c WHERE Employee__c != \'\' ORDER BY Employee__c';
        } else {
            query = 'SELECT Client__c, Total__c, Employee__c, Date__c FROM Time_Card__c WHERE Client__c =: contractId ORDER BY Employee__c';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){

        Date lastFromSalaryDate = Date.newInstance(1900, 1, 1);
        Date lastToSalaryDate = Date.today().addYears(1);
        Decimal lastSalary = 0;

        if (this.employeeSalaryHistory.size() > 0) {
            lastToSalaryDate = this.employeeSalaryHistory.size() > 1 ? this.employeeSalaryHistory.get(1).getValueDate() : Date.today().addYears(1);
            lastSalary = this.employeeSalaryHistory.get(0).getValue();
        }

        for (sObject obj : scope) {
            Time_Card__c tc = (Time_Card__c) obj;

            if (tc.Employee__c != this.lastEmployee) {
                this.lastEmployee = tc.Employee__c;
                this.employeeSalaryHistory = this.salaryHistoryHelper.mergeSalaryHistory([SELECT Name, Salary__c, Effective_Salary_Date__c, Exchange_Rate__c, Effective_Exchange_Rate_Date__c FROM SFDC_Employee__c WHERE Id =: tc.Employee__c]);
                System.debug('this.employeeSalaryHistory : ' + this.employeeSalaryHistory);
                lastToSalaryDate = this.employeeSalaryHistory.size() > 1 ? this.employeeSalaryHistory.get(1).getValueDate() : Date.today().addYears(1);
                lastSalary = this.employeeSalaryHistory.get(0).getValue();
                lastFromSalaryDate = Date.newInstance(1900, 1, 1);
            }

            System.debug('TC date : ' + tc.Date__c);
            System.debug('lastFromSalaryDate : ' + lastFromSalaryDate);
            System.debug('lastToSalaryDate : ' + lastToSalaryDate);
            if (tc.Date__c < lastFromSalaryDate || tc.Date__c >= lastToSalaryDate) {
                Integer index = 0;
                for (Integer i = 0; i < this.employeeSalaryHistory.size(); i++) {
                    if (tc.Date__c >= this.employeeSalaryHistory.get(i).getValueDate()) {
                        lastSalary = this.employeeSalaryHistory.get(i).getValue();
                        lastFromSalaryDate = this.employeeSalaryHistory.get(i).getValueDate();
                    } else {
                        index = i - 1;
                        break;
                    }
                }

                lastToSalaryDate = this.employeeSalaryHistory.size() > index + 1 ? this.employeeSalaryHistory.get(index + 1).getValueDate() : Date.today().addYears(1);
                System.debug('Loading new salary ' + lastFromSalaryDate + ' - ' + lastToSalaryDate);
                System.debug('loaded : ' + lastSalary);
            }

            Decimal laborCost = tc.Total__c * lastSalary;
            System.debug('TC date : ' + tc.Date__c);
            System.debug('Total__c : ' + tc.Total__c);
            System.debug('lastSalary : ' + lastSalary);
            System.debug('laborCost for ' + tc.Id + ' : ' + laborCost);
            if (laborCost != null) {
                if (servicesSpendMap.containsKey(tc.Client__c)) {
                    servicesSpendMap.put(tc.Client__c, servicesSpendMap.get(tc.Client__c) + laborCost);
                } else {
                    servicesSpendMap.put(tc.Client__c, laborCost);
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

    public Map<Id, Decimal> getServicesSpendMap() {
        return this.servicesSpendMap;
    }
}