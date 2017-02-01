/**
 * Calculates GS Quality for Overall Status and for Customer Satisfaction in PRO Snapshots.
 */
public without sharing class GSOverallCalculationBatch implements Database.Batchable<Project_Report_Out__c>, Database.Stateful {

    private Double gsOverall;
    private Double gsSatisfaction;
    private Double gsBudget;
    private List<Project_Report_Out__c> proList;
    private Date currentDate;

    public GSOverallCalculationBatch() {
        this.gsOverall = 0;
        this.gsSatisfaction = 0;
        this.gsBudget = 0;
        this.proList = new List<Project_Report_Out__c>();
        this.currentDate = Date.today();
    }

    public GSOverallCalculationBatch(Date currentDate) {
        this.gsOverall = 0;
        this.gsSatisfaction = 0;
        this.gsBudget = 0;
        this.proList = new List<Project_Report_Out__c>();
        this.currentDate = currentDate;
    }

    public List<Project_Report_Out__c> start(Database.BatchableContext BC) {
        List<Date> thursDayList = PROHelper.GetAllThursDayOfMonth(this.currentDate.year(), this.currentDate.month());
        List<Date> thursDayListLastMonth = PROHelper.GetAllThursDayOfMonth(this.currentDate.addMonths(-1).year(), this.currentDate.addMonths(-1).month());
        List<Date> thursDayListNextMonth = PROHelper.GetAllThursDayOfMonth(this.currentDate.addMonths(1).year(), this.currentDate.addMonths(1).month());
        Date startDate;
        Date endDate;
        if (this.currentDate < thursDayList[1]) {
            startDate = thursDayListLastMonth[3];
            endDate = thursDayList[1];
        } else if (this.currentDate < thursDayList[3]) {
            startDate = thursDayList[1];
            endDate = thursDayList[3];
        } else {
            startDate = thursDayList[3];
            endDate = thursDayListNextMonth[1];
        }

        System.debug('Start date : ' + startDate);
        System.debug('End date : ' + endDate);
        return [SELECT Id, Report_Out_Date__c, Contract_Snapshot__c, Contract_Snapshot__r.GS_Quality_Overall_Status__c, Contract_Snapshot__r.GS_Quality_Customer_Satisfaction__c,
                Contract_Snapshot__r.Project_Quality_Overall_Status__c, Contract_Snapshot__r.Customer_Satisfaction_of_services__c, Contract_Snapshot__r.GS_Execution_Budget__c
                FROM Project_Report_Out__c WHERE Contract_Snapshot__c != '' AND Report_Out_Date__c >=: startDate AND Report_Out_Date__c <: endDate];
    }

    public void execute(Database.BatchableContext BC, List<Project_Report_Out__c> scope) {
        try {
            System.debug('scope ; ' + scope.size());
            for (Project_Report_Out__c pro : scope) {
                System.debug(pro.Report_Out_Date__c);
                this.gsOverall += pro.Contract_Snapshot__r.Project_Quality_Overall_Status__c != null ? pro.Contract_Snapshot__r.Project_Quality_Overall_Status__c : 0;
                this.gsSatisfaction += pro.Contract_Snapshot__r.Customer_Satisfaction_of_services__c != null ? pro.Contract_Snapshot__r.Customer_Satisfaction_of_services__c : 0;
                this.gsBudget += pro.Contract_Snapshot__r.GS_Execution_Budget__c != null ? pro.Contract_Snapshot__r.GS_Execution_Budget__c : 0;
                this.proList.add(pro);
            }
        } catch (Exception ex) {
            System.debug('Error : ' + ex);
            if (!Test.isRunningTest()) {
                BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
                EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'GS Quality calculation error', 'GS Quality calculation error', ex);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        try {
            List<PRO_Contract_Snapshot__c> toUpdate = new List<PRO_Contract_Snapshot__c>();
            System.debug('this.gsOverall : ' + this.gsOverall);
            System.debug('this.gsSatisfaction : ' + this.gsSatisfaction);
            System.debug('this.gsBudget : ' + this.gsBudget);
            this.gsOverall = 100 * (this.gsOverall / this.gsBudget);
            this.gsSatisfaction = 100 * (this.gsSatisfaction / this.gsBudget);

            for (Project_Report_Out__c pro : this.proList) {
                if (this.gsOverall != pro.Contract_Snapshot__r.GS_Quality_Overall_Status__c || this.gsSatisfaction != pro.Contract_Snapshot__r.GS_Quality_Customer_Satisfaction__c) {
                    PRO_Contract_Snapshot__c snap = new PRO_Contract_Snapshot__c(Id = pro.Contract_Snapshot__c, GS_Quality_Overall_Status__c = this.gsOverall, GS_Quality_Customer_Satisfaction__c = this.gsSatisfaction);
                    toUpdate.add(snap);
                }
            }
            if (toUpdate.size() > 0) {
                update toUpdate;
            }

        } catch (Exception ex) {
            System.debug('Error : ' + ex);
            if (!Test.isRunningTest()) {
                BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
                EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'GS Quality calculation error', 'GS Quality calculation error', ex);
            }
        }
    }
}