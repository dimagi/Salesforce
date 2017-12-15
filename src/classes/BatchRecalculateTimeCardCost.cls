/**
 * Calculates cost of time cards.
 */
public without sharing class BatchRecalculateTimeCardCost implements Database.Batchable<sObject>, Database.Stateful {

    private Set<Id> timeCardsIds;
    private SalaryHistoryHelper salaryHistoryHelper;
    private List<SalaryHistoryRecord> employeeSalaryHistory;
    private String lastEmployee;

    private Boolean onlyRate;
    private Id contractId;
    private Map<String, List<SalaryHistoryRecord>> billingRateHistoryMap;
    private List<SalaryHistoryRecord> currentRateHistory;
    private String lastRateName = '';

    public BatchRecalculateTimeCardCost(Set<Id> timeCards) {
        this(timeCards, '', false);
    }

    public BatchRecalculateTimeCardCost(Set<Id> timeCards, String contractId, Boolean onlyRate) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();
        this.timeCardsIds = timeCards;
        this.employeeSalaryHistory = new List<SalaryHistoryRecord>();
        this.currentRateHistory = new List<SalaryHistoryRecord>();
        this.billingRateHistoryMap = new Map<String, List<SalaryHistoryRecord>>();
        this.onlyRate = onlyRate;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();

        String query;
        System.debug('timeCardsIds ' + timeCardsIds);
        if (this.timeCardsIds != null && this.timeCardsIds.size() > 0) {
            query = 'SELECT Time_card_cost__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Id In: timeCardsIds AND Employee__c != \'\' ORDER BY Employee__c, Client__r.Project_Billing_Rate__c';
        } else if (this.contractId != null && this.contractId != '') {
            query = 'SELECT Time_card_cost__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Client__c =: contractId AND Employee__c != \'\' ORDER BY Employee__c, Client__r.Project_Billing_Rate__c';
        } else {
            query = 'SELECT Time_card_cost__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Employee__c != \'\' ORDER BY Employee__c, Client__r.Project_Billing_Rate__c';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Time_Card__c> toUpdate = new List<Time_Card__c>();
        Date lastFromSalaryDate = Date.newInstance(1900, 1, 1);
        Date lastToSalaryDate = Date.today().addYears(1);
        Decimal lastSalary = 0;

        Date lastFromRateDate = Date.newInstance(1900, 1, 1);
        Date lastToRateDate = Date.today().addYears(1);
        Decimal contractRate = 1.0;


        if (this.employeeSalaryHistory.size() > 0 && !onlyRate) {
            lastToSalaryDate = this.employeeSalaryHistory.size() > 1 ? this.employeeSalaryHistory.get(1).getValueDate() : Date.today().addYears(1);
            lastSalary = this.employeeSalaryHistory.get(0).getValue();
        }

        if (this.currentRateHistory.size() > 0) {
            lastToRateDate = this.currentRateHistory.size() > 1 ? this.currentRateHistory.get(1).getValueDate() : Date.today().addYears(1);
            contractRate = this.currentRateHistory.get(0).getValue();
        }


        for (sObject obj : scope) {
            Time_Card__c tc = (Time_Card__c) obj;

            /**************************************************/
            /*** Find salary entry for given time card date ***/
            /**************************************************/
            if (!onlyRate) {
                if (tc.Employee__c != this.lastEmployee) {
                    this.lastEmployee = tc.Employee__c;
                    this.employeeSalaryHistory = this.salaryHistoryHelper.mergeSalaryHistory([SELECT Name, Salary__c, Effective_Salary_Date__c, Exchange_Rate__c, Effective_Exchange_Rate_Date__c,
                                                                                            Working_Days__c FROM SFDC_Employee__c WHERE Id =: tc.Employee__c]);
                    System.debug('New employee : ' + tc.Employee__c);
                    lastToSalaryDate = this.employeeSalaryHistory.size() > 1 ? this.employeeSalaryHistory.get(1).getValueDate() : Date.today().addYears(1);
                    lastSalary = this.employeeSalaryHistory.get(0).getValue();
                    lastFromSalaryDate = Date.newInstance(1900, 1, 1);
                }

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
                }
            } else {
                lastSalary = tc.Time_Card_Salary__c;
            }

            /****************************************************************************/
            /*** Load Project Billing Rate entry for given time card project and date ***/
            /****************************************************************************/
            if (!this.billingRateHistoryMap.containsKey(tc.Client__r.Project_Billing_Rate__c)) { // Load missin billing rate
                this.billingRateHistoryMap.put(tc.Client__r.Project_Billing_Rate__c, this.salaryHistoryHelper.loadBillingRatesHistory(tc.Client__r.Project_Billing_Rate__c));
            }

            if (tc.Client__r.Project_Billing_Rate__c != this.lastRateName) {
                this.currentRateHistory = this.billingRateHistoryMap.get(tc.Client__r.Project_Billing_Rate__c);
                lastToRateDate = this.currentRateHistory.size() > 1 ? this.currentRateHistory.get(1).getValueDate() : Date.today().addYears(1);
                lastFromRateDate = Date.newInstance(1900, 1, 1);
                contractRate = this.currentRateHistory.get(0).getValue();
            }

            if (tc.Date__c < lastFromRateDate || tc.Date__c >= lastToRateDate) {
                Integer index = 0;
                for (Integer i = 0; i < this.currentRateHistory.size(); i++) {
                    if (tc.Date__c >= this.currentRateHistory.get(i).getValueDate()) {
                        contractRate = this.currentRateHistory.get(i).getValue();
                        lastFromRateDate = this.currentRateHistory.get(i).getValueDate();
                    } else {
                        index = i - 1;
                        break;
                    }
                }
                lastToRateDate = this.currentRateHistory.size() > index + 1 ? this.currentRateHistory.get(index + 1).getValueDate() : Date.today().addYears(1);
            }

            /****************************************/
            /*** Update time card salary and rate ***/
            /****************************************/
            if (tc.Time_Card_Salary__c != lastSalary || tc.Billing_Rate__c != contractRate) {
                tc.Time_Card_Salary__c = lastSalary; // we can store more data if each record take 2KB, it will speed up changing rates in contrac UI
                tc.Billing_Rate__c = contractRate;
                toUpdate.add(tc);
            }
        }

        if (toUpdate.size() > 0) { // Update time card cost
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
        if (this.onlyRate && this.contractId != null) { // recalculate whole contract time if we update all rates in contract
            Database.executeBatch(new BatchCalculateTotalHoursOfTimeCard(this.contractId), 200);
        }
    }
}