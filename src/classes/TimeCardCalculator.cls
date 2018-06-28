/**
 * TimeCardCalculator class is used for calculating time card cost, billing rate and services spend field in contract.
 */
public without sharing class TimeCardCalculator implements Database.Batchable<sObject>, Database.Stateful {

    private DateTime lastUpdatedDateTime;
    private Map<String, List<SalaryHistoryRecord>> billingRateHistoryMap;
    private List<SalaryHistoryRecord> currentRateHistory;
    private SalaryHistoryHelper salaryHistoryHelper;
    private Boolean onlyRate;
    private Boolean isDaily;

    private Set<Id> updatedContracts;
    private List<Id> timeCardsIds;
    private List<Project_Billing_Rate_Update__c> updatesList;
    private List<DContract__c> contractsList;

    public TimeCardCalculator() {
        this(DateTime.now().addDays(-1));
    }

    public TimeCardCalculator(Set<Id> updatedContracts) {
        this(DateTime.now().addDays(-1));
        this.updatedContracts = updatedContracts;
        this.onlyRate = true;
    }

    public TimeCardCalculator(List<Id> timeCardsIds) {
        this(DateTime.now().addDays(-1));
        this.timeCardsIds = timeCardsIds;
        this.onlyRate = false;
    }

    public TimeCardCalculator(Set<Id> updatedContracts, Boolean onlyRate) {
        this(DateTime.now().addDays(-1));
        this.updatedContracts = updatedContracts;
        this.onlyRate = onlyRate;
    }

    public TimeCardCalculator(List<Project_Billing_Rate_Update__c> updatesList) {
        this(DateTime.now().addDays(-1));
        this.updatesList = updatesList;
    }

    public TimeCardCalculator(DateTime lastUpdatedDateTime) {
        this.lastUpdatedDateTime = lastUpdatedDateTime;
        this.billingRateHistoryMap = new  Map<String, List<SalaryHistoryRecord>>();
        this.currentRateHistory = new List<SalaryHistoryRecord>();
        this.salaryHistoryHelper = new SalaryHistoryHelper();
        this.onlyRate = false;
        this.isDaily = false;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'SELECT Id, Need_recalculation__c, Date__c, Employee__c, Employee__r.Salary__c, Employee__r.Exchange_Rate__c, Employee__r.Per_Week_Hours__c, Billing_Rate__c, Time_Card_Salary__c, Client__c, Client__r.Parent_Contract__c, Client__r.Project_Billing_Rate__c, Total__c ';

        if (this.updatedContracts != null) { // Contract UI run
            for (DContract__c dContract : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Id IN: this.updatedContracts]) {
                if (dContract.Parent_Contract__c != null) {
                    this.updatedContracts.add(dContract.Parent_Contract__c);
                }
            }
            for (DContract__c dContract : [SELECT Id FROM DContract__c WHERE Parent_Contract__c IN: this.updatedContracts]) {
                this.updatedContracts.add(dContract.Id);
            }

            List<DContract__c> toUpdateList = [SELECT Id, Project_Billing_Rate_Updated__c FROM DContract__c WHERE Id IN: this.updatedContracts];
            for (DContract__c dContract : toUpdateList) {
                dContract.Project_Billing_Rate_Updated__c = false;
            }

            Database.SaveResult[] srList = Database.update(toUpdateList, false);
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromDatabaseSaveResultErrors(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Contract Update Errors', 'Cannot Update Contracts : ', srList);
            }
            query = query + 'FROM Time_Card__c WHERE Client__c IN: updatedContracts ORDER BY Employee__c, Date__c';
        } else if (this.updatesList != null) { // BR UI run
            String dateString = '';
            Boolean isFirst = true;
            Set<String> updatedRates = new Set<String>();
            for (Project_Billing_Rate_Update__c updateInfo : this.updatesList) {
                updatedRates.add(updateInfo.Name);
                if (!isFirst) {
                    dateString += 'OR';
                }
                isFirst = false;
                dateString += ' (Date__c >= ' + getDateText(updateInfo.From_Range__c) + ' AND Date__c <= ' + getDateText(updateInfo.To_Range__c) + ' AND Client__r.Project_Billing_Rate__c = \'' + updateInfo.Name + '\') ';
            }

            Map<Id, DContract__c> contractMapping = new Map<Id, DContract__c>([SELECT Id FROM DContract__c WHERE Project_Billing_Rate__c IN: updatedRates]);
            this.updatedContracts = contractMapping.keySet();

            query = query + 'FROM Time_Card__c WHERE (' + dateString + ') ORDER BY Employee__c, Date__c';
        } else if (this.timeCardsIds != null) { // time cards from list
            query = query + 'FROM Time_Card__c WHERE Id IN: timeCardsIds ORDER BY Employee__c, Date__c';
        } else { // daily - last created, with updated billing rate, with updated client (we calculate it here because we don't want exception when FB is upserting time cards)
            this.contractsList = [SELECT Id, Project_Billing_Rate_Updated__c FROM DContract__c WHERE Project_Billing_Rate_Updated__c = true];
            for (DContract__c dContract : contractsList) {
                dContract.Project_Billing_Rate_Updated__c = false;
            }

            Database.SaveResult[] srList = Database.update(contractsList, false);
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromDatabaseSaveResultErrors(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Contract Update Errors', 'Cannot Update Contracts : ', srList);
            }
            this.isDaily = true;
            query = query + 'FROM Time_Card__c WHERE CreatedDate>=:lastUpdatedDateTime OR Need_recalculation__c = true OR Client__c IN: contractsList ORDER BY Employee__c, Date__c';
        }

        System.debug('Query : ' + query);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Time_Card__c> toUpdateList = new List<Time_card__c>();

        SFDC_Employee_Snapshot__c lastEmpSnp;
        String lastRateName = '';
        Date lastFromRateDate = Date.newInstance(1900, 1, 1);
        Date lastToRateDate = Date.today().addYears(1);

        Decimal contractRate = 1.0;
        Decimal salary = 0.0;

        for (sObject obj : scope) {
            Time_Card__c tc = (Time_Card__c) obj;

            if (tc.Date__c >= Date.newInstance(2017, 12, 1) && this.onlyRate == false) {
                // Load empl snapshot
                if (lastEmpSnp == null || lastEmpSnp.Employee_Record__c != tc.Employee__c || lastEmpSnp.Snapshot_Date__c < tc.Date__c) { // Time Cards are sort by employee, date so first we will change empl and then we will change time card

                    List<SFDC_Employee_Snapshot__c> emplList = new List<SFDC_Employee_Snapshot__c>();
                    if (Date.today().month() != tc.Date__c.month() || Date.today().year() != tc.Date__c.year()) { // if current month Employee Snapshot wasn't created yet so we don't need make sql query
                        emplList = [SELECT Id, Employee_Record__c, Salary__c, Exchange_Rate__c, Per_Week_Hours__c, Snapshot_Date__c FROM SFDC_Employee_Snapshot__c
                                WHERE Employee_Record__c =: tc.Employee__c AND Snapshot_Date__c =: Date.newInstance(tc.Date__c.year(), tc.Date__c.month(), Date.daysInMonth(tc.Date__c.year(), tc.Date__c.month()))];
                    }
                    if (emplList.size() > 0) {
                        lastEmpSnp = emplList.get(0);
                        salary = TimeCardCalculatorUtils.calculateSalaryForEmplSnapshot(lastEmpSnp);
                    } else {
                        salary = (((tc.Employee__r.Salary__c != null ? tc.Employee__r.Salary__c : 0)
                                    / (tc.Employee__r.Exchange_Rate__c != null && tc.Employee__r.Exchange_Rate__c != 0 ? tc.Employee__r.Exchange_Rate__c : 1.0))
                                    / (260.0 * ((tc.Employee__r.Per_Week_Hours__c != null && tc.Employee__r.Per_Week_Hours__c != 0 ? tc.Employee__r.Per_Week_Hours__c : 40.0) / 40.0)))
                                    / 8.0;
                        salary = salary.setScale(8);
                    }
                }
            }

            if (!this.billingRateHistoryMap.containsKey(tc.Client__r.Project_Billing_Rate__c)) { // Load missin billing rate
                this.billingRateHistoryMap.put(tc.Client__r.Project_Billing_Rate__c, this.salaryHistoryHelper.loadBillingRatesHistory(tc.Client__r.Project_Billing_Rate__c));
            }

            if (tc.Client__r.Project_Billing_Rate__c != lastRateName) {
                lastRateName = tc.Client__r.Project_Billing_Rate__c;
                this.currentRateHistory = this.billingRateHistoryMap.get(tc.Client__r.Project_Billing_Rate__c);
                lastToRateDate = this.currentRateHistory.size() > 1 ? this.currentRateHistory.get(1).getValueDate() : Date.today().addYears(1);
                lastFromRateDate = Date.newInstance(1900, 1, 1);
                contractRate = this.currentRateHistory.get(0).getValue();
            }

            if (tc.Date__c < lastFromRateDate || tc.Date__c >= lastToRateDate) {
                Integer index = 0;
                for (Integer i = 0; i < this.currentRateHistory.size(); i++) {
                    index = i;
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

            if (tc.Time_Card_Salary__c != salary || tc.Billing_Rate__c != contractRate || tc.Need_recalculation__c == true) {
                if (tc.Date__c >= Date.newInstance(2017, 12, 1) && this.onlyRate == false) { // only update salary for time cards when empl snp was added
                    tc.Time_Card_Salary__c = salary;
                }
                tc.Billing_Rate__c = contractRate;
                tc.Need_recalculation__c = false;
                toUpdateList.add(tc);
            }
        }

        if (toUpdateList.size() > 0) { // update racalculated time cards
            update toUpdateList;
        }
    }

    public void finish(Database.BatchableContext context) {
        if (!Test.isRunningTest()) {
            if (this.isDaily == true) {
                Database.executeBatch(new BatchCalculateTotalHoursOfTimeCard(true));
            } else if (this.updatedContracts.size() > 0) {
                Database.executeBatch(new BatchCalculateTotalHoursOfTimeCard(this.updatedContracts, false));
            }
        }
    }

    private String getDateText(Date dateRecord) {
        return DateTime.newInstance(dateRecord.year(), dateRecord.month(), dateRecord.day()).format('yyyy-MM-dd');
    }
}