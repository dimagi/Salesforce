/**
 * TimeCardCalculator class is used for calculating time card cost, billing rate and services spend field in contract.
 */
public without sharing class TimeCardCalculator implements Database.Batchable<sObject>, Database.Stateful {

    /**
     * Billing Rate Updates from BR manager.
     */
    private Set<String> billingRatesUpdate;
    private List<Project_Billing_Rate_Update__c> updatesList;
    private Boolean brUpdate;

    /**
     * Contracts with updated Billing Rate or added/removed time cards.
     */
    private Set<Id> contractsToRecalculate;
    private Set<Id> contractsToRecalculateQuery;
    private Boolean recalculateAll;

    /**
     * Calculation helpers.
     */
    private Map<Id, Decimal> servicesSpend;

    /**
     * Billing Rate calculations helper.
     */
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

        this.servicesSpend = new Map<Id, Decimal>();
        this.timeCardHelper = new TimeCardCalculatorHelper();

        this.updatesList = updatesList;
        this.billingRatesUpdate = new Set<String>();
        this.brUpdate = false;

        fillRatesMap();
    }

    public void fillRatesMap() {
        if (this.updatesList == null || this.updatesList.size() == 0) {
            this.updatesList = [SELECT Id, Name FROM Project_Billing_Rate_Update__c WHERE CreatedDate >=: Date.today().addDays(-3)];
        }

        for (Project_Billing_Rate_Update__c brUp : this.updatesList) {
            if (!this.billingRatesUpdate.contains(brUp.Name)) {
                this.billingRatesUpdate.add(brUp.Name);
                this.brUpdate = true;
            }
        }
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String selectTc = 'SELECT Id, Date__c, Billing_Rate__c, Time_Card_Salary__c, Client__c, Total__c, Uses_Contractor_Billing_Rate__c, Client__r.Project_Billing_Rate_Updated__c, Client__r.Project_Billing_Rate__c, Client__r.Parent_Contract__c FROM Time_Card__c ';
        String whereTc = 'WHERE Client__c IN: contractsToRecalculateQuery';
        String orderBy = ' ORDER BY Client__c, Date__c DESC';

        if (this.contractsToRecalculate.size() > 0) {
            // Contract UI button or manual run
            this.contractsToRecalculate.addAll(TimeCardCalculatorUtils.getParentAndChildContracts(this.contractsToRecalculate));
        } else if (this.recalculateAll) {
            // run manually only - uses list of contracts from employee, additionaly loads updated billing rates to recalculate contractor rate
            Map<Id, DContract__c> contracts = new Map<Id, DContract__c>([SELECT Id FROM DContract__c]);
            Set<Id> setId = new Set<Id>();
            setId.addAll(contracts.keySet());
            this.contractsToRecalculate.addAll(setId);
        } else {
            // daily job or scheduled by Billing Rate Manager Page
            Map<Id, DContract__c> contracts = null;
            if (!this.billingRatesUpdate.contains(TimeCardTriggerController.CONTRACTOR_RATE_NAME)) {
                contracts = new Map<Id, DContract__c>([SELECT Id FROM DContract__c WHERE Require_Services_Spend_Refresh__c = true
                                                       OR Project_Billing_Rate_Updated__c = true OR Project_Billing_Rate__c
                                                       IN: this.billingRatesUpdate]);
            } else { // we must fetch all time cards because schema and record numbers dosen't allow to safty fetch such informations from database
                contracts = new Map<Id, DContract__c>([SELECT Id FROM DContract__c]);
            }

            Set<Id> setId = new Set<Id>();
            setId.addAll(contracts.keySet());
            this.contractsToRecalculate.addAll(TimeCardCalculatorUtils.getParentAndChildContracts(setId));
        }

        this.contractsToRecalculateQuery = new Set<Id>(this.contractsToRecalculate);
        fillServicesSpendMap();

        return Database.getQueryLocator(selectTc + whereTc + orderBy);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Time_Card__c> timeCardsToUpdate = new List<Time_Card__c>();

        for (sObject tcSObj : scope) {
            Time_Card__c timeCard = (Time_Card__c) tcSObj;
            Decimal currentServicesSpend = 0;

            if (timeCard.Client__r.Project_Billing_Rate_Updated__c == true && timeCard.Uses_Contractor_Billing_Rate__c == false) {
                timeCard.Billing_Rate__c = this.timeCardHelper.getBillingRate(timeCard.Client__r.Project_Billing_Rate__c, timeCard.Date__c);
                timeCardsToUpdate.add(timeCard);
            } else if (this.brUpdate
                        && (this.billingRatesUpdate.contains(timeCard.Client__r.Project_Billing_Rate__c)
                            || (timeCard.Uses_Contractor_Billing_Rate__c == true
                                && this.billingRatesUpdate.contains(TimeCardTriggerController.CONTRACTOR_RATE_NAME)))) {
                String billingRateName = timeCard.Client__r.Project_Billing_Rate__c;
                if (timeCard.Uses_Contractor_Billing_Rate__c == true) {
                    billingRateName = TimeCardTriggerController.CONTRACTOR_RATE_NAME;
                }
                timeCard.Billing_Rate__c = this.timeCardHelper.getBillingRate(billingRateName, timeCard.Date__c);
                timeCardsToUpdate.add(timeCard);
            }

            currentServicesSpend += (timeCard.Total__c * (timeCard.Time_Card_Salary__c != null ? timeCard.Time_Card_Salary__c : 0.0)
                                        * (timeCard.Billing_Rate__c != null ? timeCard.Billing_Rate__c : 0.0)).setScale(8);
            putServicesSpendForClient(currentServicesSpend, timeCard.Client__c);

            if (timeCard.Client__r.Parent_Contract__c != null) {
                putServicesSpendForClient(currentServicesSpend, timeCard.Client__r.Parent_Contract__c);
            }
        }

        if (timeCardsToUpdate.size() > 0) {
            update timeCardsToUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {
        if (this.servicesSpend.size() > 0) {
            List<DContract__c> contractList = new List<DContract__c>();
            for (DContract__c dContract : [SELECT Id, Services_Spend__c, Require_Services_Spend_Refresh__c, Project_Billing_Rate_Updated__c
                                           FROM DContract__c WHERE Id IN: this.servicesSpend.keySet()]) {
                Decimal contractValue = this.servicesSpend.get(dContract.Id);
                dContract.Services_Spend__c = contractValue != null ? contractValue.setScale(2) : 0;
                dContract.Require_Services_Spend_Refresh__c = false;
                dContract.Project_Billing_Rate_Updated__c = false;
                contractList.add(dContract);
            }

            if (contractList.size() > 0) {
                Database.SaveResult[] srList = Database.update(contractList, false);
                if (!Test.isRunningTest()) {
                    EmailHelper.sendEmailFromDatabaseSaveResultErrors(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Contract Update Errors', 'Cannot Update Contracts : ', srList);
                }
            }
        }
    }

    private void putServicesSpendForClient(Decimal value, Id clientId) {
        if (this.servicesSpend.containsKey(clientId)) {
            this.servicesSpend.put(clientId, value + this.servicesSpend.get(clientId));
        } else {
            this.servicesSpend.put(clientId, value);
        }
    }

    private void fillServicesSpendMap() {
        for (Id clientId : this.contractsToRecalculate) {
            this.servicesSpend.put(clientId, 0);
        }
    }
}