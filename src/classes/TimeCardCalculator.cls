/**
 * TimeCardCalculator class is used for calculating time card cost, billing rate and services spend field in contract.
 */
public without sharing class TimeCardCalculator implements Database.Batchable<sObject>, Database.Stateful {

    // job managment
    private String mode; // we want use mode to avoid other implementations because we want only one instace of this job at one time
    private Date runDate;
    private Boolean billingRateHistoryChanged;
    private Set<Id> contractIds;
    private Set<Id> timeCardsIds;

    // salary update for contract
    private Map<Id, Decimal> servicesSpendMap;

    // salary calc
    private Id lastEmployee;
    private List<SalaryHistoryRecord> employeeSalaryHistory;
    private SalaryHistoryHelper salaryHistoryHelper;

    // Rate calc
    private Map<String, List<SalaryHistoryRecord>> billingRateHistoryMap;
    private List<SalaryHistoryRecord> currentRateHistory;
    private String lastRateName = '';
    private Set<Id> updatedRateSet;

    // billing rate ui
    private List<Project_Billing_Rate_Update__c> updateRanges;

    public TimeCardCalculator(String mode) {
        this(mode, Date.today());
    }

    public TimeCardCalculator(List<Project_Billing_Rate_Update__c> updateRanges) {
        this('client_update', Date.today());
        this.updateRanges = updateRanges;
    }

    public TimeCardCalculator(Id contractId) {
        this('billing_rate_ui', Date.today());
        this.contractIds = new Set<Id> { contractId };
    }

    public TimeCardCalculator(Set<Id> timeCardsIds) {
        this('rec', Date.today());
        this.timeCardsIds = timeCardsIds;
    }

    public TimeCardCalculator(String mode, Date runDate) {
        this.mode = mode;
        this.runDate = runDate;
        this.billingRateHistoryChanged = false;

        this.servicesSpendMap = new Map<Id, Decimal>();
        this.billingRateHistoryMap = new  Map<String, List<SalaryHistoryRecord>>();
        this.currentRateHistory = new List<SalaryHistoryRecord>();
        this.updatedRateSet = new Set<Id>();

        this.employeeSalaryHistory = new List<SalaryHistoryRecord>();
        this.salaryHistoryHelper = new SalaryHistoryHelper();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = '';

        if (this.mode == 'daily') { // in daily job we want update new time cards and update changed billing rate in contracts
            List<DContract__c> contractsList = [SELECT Id, Project_Billing_Rate_Updated__c FROM DContract__c WHERE Project_Billing_Rate_Updated__c = true];
            for (DContract__c dContract : contractsList) {
                dContract.Project_Billing_Rate_Updated__c = false;
                this.updatedRateSet.add(dContract.Id);
            }
            Database.update(contractsList, false);

            query = 'SELECT Id, Date__c, Client__c, Employee__c, Billing_Rate__c, Time_Card_Salary__c, Client__r.Parent_Contract__c, Client__r.Project_Billing_Rate__c, Total__c, CreatedDate FROM Time_Card__c WHERE CreatedDate = TODAY ORDER BY Employee__c, Date__c';
        } else if (this.mode == 'client_update') { // we want run job ony for thsi contract and for it family
            for (DContract__c dContract : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Id IN: contractIds]) {
                if (dContract.Parent_Contract__c != null) {
                    contractIds.add(dContract.Parent_Contract__c);
                }
            }
            for (DContract__c dContract : [SELECT Id FROM DContract__c WHERE Parent_Contract__c IN: contractIds]) {
                contractIds.add(dContract.Id);
            }
            query = 'SELECT Id, Date__c, Client__c, Employee__c, Billing_Rate__c, Time_Card_Salary__c, Client__r.Parent_Contract__c, Client__r.Project_Billing_Rate__c, Total__c, CreatedDate FROM Time_Card__c WHERE Client__c IN: contractIds ORDER BY Employee__c, Date__c';
        } else if (this.mode == 'billing_rate_ui') { // run from billing rate ui
            String rateName = this.updateRanges.get(0).Name;
            String dateString = '';
            Boolean isFirst = true;
            for (Project_Billing_Rate_Update__c updateInfo : this.updateRanges) {
                if (!isFirst) {
                    dateString += 'OR';
                }
                isFirst = false;
                dateString += ' (Date__c >= ' + getDateText(updateInfo.From_Range__c) + ' AND Date__c <= ' + getDateText(updateInfo.To_Range__c) + ' AND Client__r.Project_Billing_Rate__c = \'' + updateInfo.Name + '\''+ ') ';
            }
            query = 'SELECT Id, Date__c, Client__c, Employee__c, Billing_Rate__c, Time_Card_Salary__c, Client__r.Parent_Contract__c, Client__r.Project_Billing_Rate__c, Total__c, CreatedDate FROM Time_Card__c WHERE (' + dateString + ') ORDER BY Employee__c, Client__r.Project_Billing_Rate__c';
            this.billingRateHistoryChanged = true;
        } else if (this.mode == 'rec') { // manually run for recalulations if something will be wrong
            query = 'SELECT Id, Date__c, Client__c, Employee__c, Billing_Rate__c, Time_Card_Salary__c, Client__r.Parent_Contract__c, Client__r.Project_Billing_Rate__c, Total__c, CreatedDate FROM Time_Card__c WHERE Id IN: timeCardsIds ORDER BY Employee__c, Date__c';
        }

        System.debug('Query : ' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        // Salary helpers
        Date lastFromSalaryDate = Date.newInstance(1900, 1, 1);
        Date lastToSalaryDate = Date.today().addYears(1);
        Decimal lastSalary = 0;

        // Rate helpers
        Date lastFromRateDate = Date.newInstance(1900, 1, 1);
        Date lastToRateDate = Date.today().addYears(1);
        Decimal contractRate = 1.0;

        if (this.employeeSalaryHistory.size() > 0) {
            lastToSalaryDate = this.employeeSalaryHistory.size() > 1 ? this.employeeSalaryHistory.get(1).getValueDate() : Date.today().addYears(1);
            lastSalary = this.employeeSalaryHistory.get(0).getValue();
        }

        if (this.currentRateHistory.size() > 0) {
            lastToRateDate = this.currentRateHistory.size() > 1 ? this.currentRateHistory.get(1).getValueDate() : Date.today().addYears(1);
            contractRate = this.currentRateHistory.get(0).getValue();
        }

        List<Time_Card__c> toUpdateList = new List<Time_Card__c>(); // time card which cost really was updated

        for (sObject obj : scope) {
            Time_Card__c tc = (Time_Card__c) obj;

            Boolean updateBillingRate = false;
            Boolean updateSalary = false;
            Boolean wasUpdated = false;

            if (this.updatedRateSet.contains(tc.Client__c) || mode == 'rec') { // if rate was updated in contract we must change it in time card object
                updateBillingRate = true;
            }

            if (this.billingRateHistoryChanged == true) {
                updateBillingRate = true;
            }

            if (this.runDate.isSameDay(tc.CreatedDate.date()) || mode == 'rec') { // if new time card added we must set all values
                updateBillingRate = true;
                updateSalary = true;
            }

            /**************************************************/
            /*** Find salary entry for given time card date ***/
            /**************************************************/
            if (updateSalary == true) {
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
            }

            /****************************************************************************/
            /*** Load Project Billing Rate entry for given time card project and date ***/
            /****************************************************************************/
            if (updateBillingRate == true) {
                if (!this.billingRateHistoryMap.containsKey(tc.Client__r.Project_Billing_Rate__c)) { // Load missin billing rate
                    this.billingRateHistoryMap.put(tc.Client__r.Project_Billing_Rate__c, this.salaryHistoryHelper.loadBillingRatesHistory(tc.Client__r.Project_Billing_Rate__c));
                }

                if (tc.Client__r.Project_Billing_Rate__c != this.lastRateName) {
                    this.lastRateName = tc.Client__r.Project_Billing_Rate__c;
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
            }

            /****************************************/
            /*** Update time card salary and rate ***/
            /****************************************/
            if (tc.Time_Card_Salary__c != lastSalary || tc.Billing_Rate__c != contractRate) {
                Decimal oldValue = tc.Total__c * (tc.Billing_Rate__c != null ? tc.Billing_Rate__c : 0) * (tc.Time_Card_Salary__c != null ? tc.Time_Card_Salary__c : 0);
                tc.Time_Card_Salary__c = lastSalary;
                tc.Billing_Rate__c = contractRate;
                Decimal value = tc.Total__c * (tc.Time_Card_Salary__c != null ? tc.Time_Card_Salary__c : 0) * (tc.Billing_Rate__c != null ? tc.Billing_Rate__c : 0);
                addServicesSpend(value - oldValue, tc.Client__c, tc.Client__r.Parent_Contract__c);
                toUpdateList.add(tc);
            }
        }

        if (toUpdateList.size() > 0) { // update racalculated time cards
            update toUpdateList;
        }

        // Reset for the next batch iteration
        this.lastRateName = '';
    }

    public void finish(Database.BatchableContext context) {
        if (!this.servicesSpendMap.isEmpty()) {
            List<DContract__c> contractList = new List<DContract__c>();
            for (DContract__c dContract : [SELECT Id, Services_Spend__c FROM DContract__c WHERE Id IN: this.servicesSpendMap.keySet()]) { // update services spend in contract object
                contractList.add(new DContract__c(Id = dContract.Id, Services_Spend__c = (dContract.Services_Spend__c != null ? dContract.Services_Spend__c : 0) + this.servicesSpendMap.get(dContract.Id)));
            }
            Database.update(contractList, false);
        }
    }

    private void addServicesSpend(Decimal value, Id contractId, Id parentId) {
        if (this.servicesSpendMap.containsKey(contractId)) {
            this.servicesSpendMap.put(contractId, value + this.servicesSpendMap.get(contractId));
        } else {
            this.servicesSpendMap.put(contractId, value);
        }

        if (parentId != null) { // we must also add childs service spend to the parent object
            if (this.servicesSpendMap.containsKey(parentId)) {
                this.servicesSpendMap.put(parentId, value + this.servicesSpendMap.get(parentId));
            } else {
                this.servicesSpendMap.put(parentId, value);
            }
        }
    }

    private String getDateText(Date dateRecord) {
        return DateTime.newInstance(dateRecord.year(), dateRecord.month(), dateRecord.day()).format('yyyy-MM-dd');
    }
}