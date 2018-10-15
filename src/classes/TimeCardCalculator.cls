/**
 * TimeCardCalculator class is used for calculating time card cost, billing rate and services spend field in contract.
 */
public without sharing class TimeCardCalculator implements Database.Batchable<sObject>, Database.Stateful {

    private Set<String> billingRatesUpdate;
    private List<Project_Billing_Rate_Update__c> updatesList;
    private Boolean brUpdate;

    private Set<Id> contractsToRecalculate;
    private Boolean recalculateAll;

    private Map<Id, Decimal> childsServicesSpend;
    private DContract__c currentContract;
    private Decimal currentServicesSpend;

    private TimeCardCalculatorHelper timeCardHelper;

    public TimeCardCalculator() {
        this(new Set<Id>());
    }

    public TimeCardCalculator(Boolean recalculateAll) {
        this(new Set<Id>(), recalculateAll, new List<Project_Billing_Rate_Update__c>());
    }

    public TimeCardCalculator(Set<Id> contractsToRecalculate) {
        this(contractsToRecalculate, false, new List<Project_Billing_Rate_Update__c>());
    }

    public TimeCardCalculator(List<Project_Billing_Rate_Update__c> updatesList) {
        this(new Set<Id>(), false, updatesList);
    }

    private TimeCardCalculator(Set<Id> contractsToRecalculate, Boolean recalculateAll, List<Project_Billing_Rate_Update__c> updatesList) {
        this.contractsToRecalculate = contractsToRecalculate;
        this.recalculateAll = recalculateAll;

        this.childsServicesSpend = new Map<Id, Decimal>();
        this.timeCardHelper = new TimeCardCalculatorHelper();

        this.updatesList = updatesList;
        this.billingRatesUpdate = new Set<String>();
        this.brUpdate = true;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String selectTc = 'SELECT Id, Need_recalculation__c, Date__c, Billing_Rate__c, Time_Card_Salary__c, Client__c, Total__c FROM Time_Card__c ';
        String whereTc = 'WHERE Client__c IN: contractsToRecalculate';
        String orderBy = ' ORDER BY Client__r.Is_child_contract__c DESC, Client__c, Date__c DESC';

        if (this.contractsToRecalculate.size() > 0) { // Contract UI button or manual run
            this.contractsToRecalculate.addAll(TimeCardCalculatorUtils.getParentAndChildContracts(this.contractsToRecalculate));
        } else if (this.recalculateAll) { // run manually only
            Map<Id, DContract__c> contracts = new Map<Id, DContract__c>([SELECT Id FROM DContract__c]);
            Set<Id> setId = new Set<Id>();
            setId.addAll(contracts.keySet());
            this.contractsToRecalculate.addAll(setId);
        } else if (this.updatesList.size() > 0) { // Billing Rate manager button
            for (Project_Billing_Rate_Update__c brUp : this.updatesList) {
                if (!this.billingRatesUpdate.contains(brUp.Name)) {
                    this.billingRatesUpdate.add(brUp.Name);
                    this.brUpdate = true;
                }
            }
            Map<Id, DContract__c> contracts = new Map<Id, DContract__c> ([SELECT Id FROM DContract__c WHERE Project_Billing_Rate__c IN: this.billingRatesUpdate]);
            Set<Id> setId = new Set<Id>();
            setId.addAll(contracts.keySet());
            this.contractsToRecalculate.addAll(TimeCardCalculatorUtils.getParentAndChildContracts(setId));
        } else { // daily
            for (Project_Billing_Rate_Update__c brUp : [SELECT Id, Name FROM Project_Billing_Rate_Update__c]) {
                if (!this.billingRatesUpdate.contains(brUp.Name)) {
                    this.billingRatesUpdate.add(brUp.Name);
                    this.brUpdate = true;
                }
            }
            Map<Id, DContract__c> contracts = new Map<Id, DContract__c>([SELECT Id FROM DContract__c WHERE Require_Services_Spend_Refresh__c = true
                                                                            OR Project_Billing_Rate_Updated__c = true OR Project_Billing_Rate__c IN: this.billingRatesUpdate]);
            Set<Id> setId = new Set<Id>();
            setId.addAll(contracts.keySet());
            this.contractsToRecalculate.addAll(TimeCardCalculatorUtils.getParentAndChildContracts(setId));
        }

        return Database.getQueryLocator(selectTc + whereTc + orderBy);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();

        String lastRateName = '';
        Date lastFromRateDate = Date.newInstance(1900, 1, 1);
        Date lastToRateDate = Date.today().addYears(1);
        Decimal contractRate = 1.0;

        for (sObject tcSObj : scope) {
            Time_Card__c timeCard = (Time_Card__c) tcSObj;

            if (this.currentContract == null || this.currentContract.Id != timeCard.Client__c) { // we started new contract
                if (this.currentContract != null) {
                    if (this.currentContract.Is_child_contract__c == true) {
                        // If child we store sum in the map for parent
                        if (this.childsServicesSpend.containsKey(this.currentContract.Parent_Contract__c)) {
                            this.childsServicesSpend.put(this.currentContract.Parent_Contract__c, 
                                            this.currentServicesSpend + this.childsServicesSpend.get(this.currentContract.Parent_Contract__c));
                        } else {
                            this.childsServicesSpend.put(this.currentContract.Parent_Contract__c, this.currentServicesSpend);
                        }
                        // Save child contract value
                         Database.update(new DContract__c(Id = this.currentContract.Id, Services_Spend__c = this.currentServicesSpend.setScale(2)), false);
                    } else {
                        // If parent we must load value from child map
                        if (this.childsServicesSpend.containsKey(this.currentContract.Id)) {
                            this.currentServicesSpend += this.childsServicesSpend.get(this.currentContract.Id);
                        }
                        // Save parent contract value
                        Database.update(new DContract__c(Id = this.currentContract.Id, Services_Spend__c = this.currentServicesSpend.setScale(2)), false);
                    }
                }

                // Fetch new Contract
                this.currentServicesSpend = 0;
                this.currentContract = [SELECT Id, Parent_Contract__c, Project_Billing_Rate__c, Is_child_contract__c, Project_Billing_Rate_Updated__c, Require_Services_Spend_Refresh__c
                                                    FROM DContract__c WHERE Id =: timeCard.Client__c];
                                                                        // we remove it from list because we want set 0 to contracts without time cards, for example situation if client will change so we must set 0 to contracts without time cards
                this.contractsToRecalculate.remove(this.currentContract.Id);
                Database.update(new DContract__c(Id = this.currentContract.Id, Project_Billing_Rate_Updated__c = false, Require_Services_Spend_Refresh__c = false), false);
            }

            if (this.currentContract.Project_Billing_Rate_Updated__c == true) {
                timeCard.Billing_Rate__c = this.timeCardHelper.getBillingRate(this.currentContract.Project_Billing_Rate__c, timeCard.Date__c);
                timeCardsToUpdate.add(timeCard);
            } else if (this.brUpdate && this.billingRatesUpdate.contains(this.currentContract.Project_Billing_Rate__c)) {
                timeCard.Billing_Rate__c = this.timeCardHelper.getBillingRate(this.currentContract.Project_Billing_Rate__c, timeCard.Date__c);
                timeCardsToUpdate.add(timeCard);
            }

            this.currentServicesSpend += (timeCard.Total__c * (timeCard.Time_Card_Salary__c != null ? timeCard.Time_Card_Salary__c : 0.0) * (timeCard.Billing_Rate__c != null ? timeCard.Billing_Rate__c : 0.0)).setScale(8);
        }

        if (timeCardsToUpdate.size() > 0) {
            update timeCardsToUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
        List<DContract__c> contractsForSave = new List<DContract__c>();
        if (this.currentContract != null) { // save last contract
            if (this.currentContract.Is_child_contract__c == true) {
                if (this.childsServicesSpend.containsKey(this.currentContract.Parent_Contract__c)) {
                    this.childsServicesSpend.put(this.currentContract.Parent_Contract__c, 
                                    this.currentServicesSpend + this.childsServicesSpend.get(this.currentContract.Parent_Contract__c));
                } else {
                    this.childsServicesSpend.put(this.currentContract.Parent_Contract__c, this.currentServicesSpend);
                }
                Database.update(new DContract__c(Id = this.currentContract.Id, Services_Spend__c = this.currentServicesSpend.setScale(2)), false);
                this.contractsToRecalculate.remove(this.currentContract.Id);
                this.currentContract = [SELECT Id, Project_Billing_Rate__c, Is_child_contract__c FROM DContract__c WHERE Id =: this.currentContract.Parent_Contract__c];
                this.currentServicesSpend = 0;
            }

            if (this.childsServicesSpend.containsKey(this.currentContract.Id)) {
                this.currentServicesSpend += this.childsServicesSpend.get(this.currentContract.Id);
            }

            this.contractsToRecalculate.remove(this.currentContract.Id);
            contractsForSave.add(new DContract__c(Id = this.currentContract.Id, Services_Spend__c = this.currentServicesSpend.setScale(2), Require_Services_Spend_Refresh__c = false, Project_Billing_Rate_Updated__c = false));
        }

        for (Id contrId : this.contractsToRecalculate) {
            Decimal value = 0;
            if (this.childsServicesSpend.containsKey(contrId)) {
                value = this.childsServicesSpend.get(contrId);
            }
            contractsForSave.add(new DContract__c(Id = contrId, Services_Spend__c = value.setScale(2), Require_Services_Spend_Refresh__c = false, Project_Billing_Rate_Updated__c = false));
        }

        if (contractsForSave.size() > 0) {
            Database.SaveResult[] srList = Database.update(contractsForSave, false);
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromDatabaseSaveResultErrors(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                    '   Contract Update Errors', 'Cannot Update Contracts : ', srList);
            }
        }

        if (!Test.isRunningTest()) {
            StatusLoggerUtils.logInfo(StatusLoggerUtils.TIME_CARD_LOGGER, 'Time Card Calculator', 0, 'Finished Time Card Calculator Job');
            StatusLoggerUtils.sendLog(StatusLoggerUtils.TIME_CARD_LOGGER,  BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        }
    }

    private String getDateText(Date dateRecord) {
        return DateTime.newInstance(dateRecord.year(), dateRecord.month(), dateRecord.day()).format('yyyy-MM-dd');
    }
}