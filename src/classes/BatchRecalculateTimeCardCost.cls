/**
 * Calculates cost of time cards. TODO: Remove in future. We need it until no old time cards will be added to SF from FB.
 */
public without sharing class BatchRecalculateTimeCardCost implements Database.Batchable<sObject>, Database.Stateful {

    private Date oldCalculations;
    private DateTime lastUpdatedDateTime;
    private Set<Id> timeCardsIds;
    private SalaryHistoryHelper salaryHistoryHelper;
    private List<SalaryHistoryRecord> employeeSalaryHistory;
    private String lastEmployee;

    private Boolean copyContracts;
    private Set<Id> copiedContracts;
    private List<Id> contractIds;
    private Set<Id> contractsToRefresh;

    public BatchRecalculateTimeCardCost(Set<Id> timeCards) {
        this(timeCards, new List<Id>(), false);
    }

    public BatchRecalculateTimeCardCost(List<Id> contractIds, Boolean onlyRate) {
        this(new Set<Id>(), contractIds, onlyRate);
    }

    public BatchRecalculateTimeCardCost(Set<Id> timeCards, List<Id> contractIds, Boolean onlyRate) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();
        this.timeCardsIds = timeCards;
        this.contractIds = contractIds;
        this.employeeSalaryHistory = new List<SalaryHistoryRecord>();
        this.lastUpdatedDateTime = DateTime.now().addDays(-1);
        this.oldCalculations = Date.newInstance(2017, 12, 1);
        this.contractsToRefresh = new Set<Id>();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();

        String query;
        if (this.timeCardsIds != null && this.timeCardsIds.size() > 0) {
            query = 'SELECT Billing_Rate__c, Time_Card_Salary__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Id IN: timeCardsIds AND Employee__c != \'\' ORDER BY Employee__c';
        } else if (this.contractIds != null && this.contractIds.size() > 0) {
            query = 'SELECT Billing_Rate__c, Time_Card_Salary__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Client__c IN: contractIds AND Employee__c != \'\' ORDER BY Employee__c';
        } else { // daily calculate added old time cards (with Date__c before 2017-12-01)
            query = 'SELECT Billing_Rate__c, Time_Card_Salary__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE CreatedDate>=:lastUpdatedDateTime AND Date__c<:oldCalculations AND Employee__c != \'\' ORDER BY Employee__c';
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Time_Card__c> toUpdate = new List<Time_Card__c>();
        Date lastFromSalaryDate = Date.newInstance(1900, 1, 1);
        Date lastToSalaryDate = Date.today().addYears(1);
        Decimal lastSalary = 0;

        if (this.employeeSalaryHistory.size() > 0) {
            lastToSalaryDate = this.employeeSalaryHistory.size() > 1 ? this.employeeSalaryHistory.get(1).getValueDate() : Date.today().addYears(1);
            lastSalary = this.employeeSalaryHistory.get(0).getValue();
        }

        for (sObject obj : scope) {
            Time_Card__c tc = (Time_Card__c) obj;

            /**************************************************/
            /*** Find salary entry for given time card date ***/
            /**************************************************/

            if (tc.Employee__c != this.lastEmployee) {
                this.lastEmployee = tc.Employee__c;
                this.employeeSalaryHistory = this.salaryHistoryHelper.mergeSalaryHistory([SELECT Name, Hire_Date__c, Expected_Termination_Date__c, Salary__c, Effective_Salary_Date__c,
                                                                                          Exchange_Rate__c, Effective_Exchange_Rate_Date__c, Working_Days__c FROM SFDC_Employee__c WHERE Id =: tc.Employee__c]);
                lastToSalaryDate = this.employeeSalaryHistory.size() > 1 ? this.employeeSalaryHistory.get(1).getValueDate() : Date.today().addYears(1);
                lastSalary = this.employeeSalaryHistory.get(0).getValue().setScale(8);
                lastFromSalaryDate = Date.newInstance(1900, 1, 1);
            }

            if (tc.Date__c < lastFromSalaryDate || tc.Date__c >= lastToSalaryDate) {
                Integer index = 0;
                for (Integer i = 0; i < this.employeeSalaryHistory.size(); i++) {
                    index = i;
                    if (tc.Date__c >= this.employeeSalaryHistory.get(i).getValueDate()) {
                        lastSalary = this.employeeSalaryHistory.get(i).getValue().setScale(8);
                        lastFromSalaryDate = this.employeeSalaryHistory.get(i).getValueDate();
                    } else {
                        index = i - 1;
                        break;
                    }
                }
                lastToSalaryDate = this.employeeSalaryHistory.size() > index + 1 ? this.employeeSalaryHistory.get(index + 1).getValueDate() : Date.today().addYears(1);
            }
            /****************************************/
            /*** Update time card salary and rate ***/
            /****************************************/
            if (tc.Time_Card_Salary__c != lastSalary) {
                if (tc.Date__c < Date.newInstance(2017, 12, 1)) {
                    tc.Time_Card_Salary__c = lastSalary.setScale(8);
                    toUpdate.add(tc);
                    this.contractsToRefresh.add(tc.Client__c);
                }
            }
        }

        if (toUpdate.size() > 0) {
            update toUpdate;
        }
        if (this.contractsToRefresh.size() > 0) {
             TimeCardCalculatorUtils.markContractsToRefresh(this.contractsToRefresh);
        }
    }

    public void finish(Database.BatchableContext context) {
        if (!Test.isRunningTest()) {
            Database.executeBatch(new TimeCardCalculator()); // calculate billing rate and salary for new time cards(after 2017-12-01 we are using employee snapshot for calculations)
        }
    }

    private String getDateText(Date dateRecord) {
        return DateTime.newInstance(dateRecord.year(), dateRecord.month(), dateRecord.day()).format('yyyy-MM-dd');
    }
}