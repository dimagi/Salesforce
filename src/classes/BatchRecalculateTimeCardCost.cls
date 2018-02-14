/**
 * Calculates cost of time cards.
 */
public without sharing class BatchRecalculateTimeCardCost implements Database.Batchable<sObject>, Database.Stateful {

    private Set<Id> timeCardsIds;
    private SalaryHistoryHelper salaryHistoryHelper;
    private List<SalaryHistoryRecord> employeeSalaryHistory;
    private String lastEmployee;

    private Boolean copyContracts;
    private Set<Id> copiedContracts;
    private Boolean onlyRate;
    private List<Id> contractIds;
    private List<Project_Billing_Rate_Update__c> updateRanges;
    private Map<String, List<SalaryHistoryRecord>> billingRateHistoryMap;
    private List<SalaryHistoryRecord> currentRateHistory;
    private String lastRateName = '';

    public BatchRecalculateTimeCardCost(Set<Id> timeCards) {
        this(timeCards, new List<Id>(), new List<Project_Billing_Rate_Update__c>(), false);
    }

    public BatchRecalculateTimeCardCost(List<Id> contractIds, Boolean onlyRate) {
        this(new Set<Id>(), contractIds, new List<Project_Billing_Rate_Update__c>(), onlyRate);
    }

    public BatchRecalculateTimeCardCost(List<Project_Billing_Rate_Update__c> updateRanges, Boolean onlyRate) {
        this(new Set<Id>(), new List<Id>(), updateRanges, onlyRate);
    }

    public BatchRecalculateTimeCardCost(Set<Id> timeCards, List<Id> contractIds, List<Project_Billing_Rate_Update__c> updateRanges, Boolean onlyRate) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();
        this.timeCardsIds = timeCards;
        this.contractIds = contractIds;
        this.employeeSalaryHistory = new List<SalaryHistoryRecord>();
        this.currentRateHistory = new List<SalaryHistoryRecord>();
        this.billingRateHistoryMap = new Map<String, List<SalaryHistoryRecord>>();
        this.onlyRate = onlyRate;
        this.updateRanges = updateRanges;
        this.copyContracts = false;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        this.salaryHistoryHelper = new SalaryHistoryHelper();

        String query;
        System.debug('timeCardsIds ' + timeCardsIds);
        if (this.timeCardsIds != null && this.timeCardsIds.size() > 0) {
            query = 'SELECT Billing_Rate__c, Time_Card_Salary__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Id IN: timeCardsIds AND Employee__c != \'\' ORDER BY Employee__c, Client__r.Project_Billing_Rate__c';
        } else if (this.contractIds != null && this.contractIds.size() > 0) {
            query = 'SELECT Billing_Rate__c, Time_Card_Salary__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Client__c IN: contractIds AND Employee__c != \'\' ORDER BY Employee__c, Client__r.Project_Billing_Rate__c';
        } else if (this.updateRanges.size() > 0) {
            String rateName = this.updateRanges.get(0).Name;
            String dateString = '';
            Boolean isFirst = true;
            for (Project_Billing_Rate_Update__c updateInfo : this.updateRanges) {
                if (!isFirst) {
                    dateString += 'OR';
                }
                isFirst = false;
                dateString += ' (Date__c >= ' + getDateText(updateInfo.From_Range__c) + ' AND Date__c <= ' + getDateText(updateInfo.To_Range__c) + ') ';
            }
            query = 'SELECT Billing_Rate__c, Time_Card_Salary__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Client__r.Project_Billing_Rate__c = \'' + rateName + '\''
                                        + ' AND (' + dateString + ') ORDER BY Employee__c, Client__r.Project_Billing_Rate__c';
            this.copyContracts = true;
            this.copiedContracts = new Set<Id>();
        } else {
            query = 'SELECT Billing_Rate__c, Time_Card_Salary__c, Total__c, Employee__c, Date__c, Client__r.Project_Billing_Rate__c FROM Time_Card__c WHERE Employee__c != \'\' ORDER BY Employee__c, Client__r.Project_Billing_Rate__c';
        }
        System.debug('Query : ' + query);
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

            if (this.copyContracts == true) {
                this.copiedContracts.add(tc.Client__c);
            }

            /**************************************************/
            /*** Find salary entry for given time card date ***/
            /**************************************************/
            if (!onlyRate) {
                if (tc.Employee__c != this.lastEmployee) {
                    this.lastEmployee = tc.Employee__c;
                    this.employeeSalaryHistory = this.salaryHistoryHelper.mergeSalaryHistory([SELECT Name, Hire_Date__c, Expected_Termination_Date__c, Salary__c, Effective_Salary_Date__c,
                                                                                              Exchange_Rate__c, Effective_Exchange_Rate_Date__c, Working_Days__c FROM SFDC_Employee__c WHERE Id =: tc.Employee__c]);
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
        if (this.copiedContracts != null && this.copiedContracts.size() > 0) {
            this.contractIds.addAll(this.copiedContracts);
        }
        if (this.onlyRate && (this.contractIds != null && this.contractIds.size() > 0)) {
            // recalculate whole contract time if we update all rates in contract
            Database.executeBatch(new BatchCalculateTotalHoursOfTimeCard(this.contractIds), 200);
        }
    }

    private String getDateText(Date dateRecord) {
        return DateTime.newInstance(dateRecord.year(), dateRecord.month(), dateRecord.day()).format('yyyy-MM-dd');
    }
}