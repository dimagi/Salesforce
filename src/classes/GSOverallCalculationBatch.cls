/**
 * Calculates GS Quality for Overall Status and for Customer Satisfaction in PRO Snapshots.
 */
public without sharing class GSOverallCalculationBatch implements Database.Batchable<Project_Report_Out__c>, Database.Stateful {

    private List<Business_Unit__c> businessUnits;
    private Business_Unit__c currentUnit;

    private Double gsOverall;
    private Double gsSatisfaction;
    private Double gsBudget;
    private Double gsTotalOverall;
    private Double gsTotalSatisfaction;
    private Double gsTotalBudget;
    private Date currentDate;
    private Date cycleStartDate;
    private Contract_Statistic__c contractStats;

    public GSOverallCalculationBatch(List<Business_Unit__c> businessUnits) {
        this.businessUnits = businessUnits;
        if (this.businessUnits.size() > 0) {
            this.currentUnit = this.businessUnits.get(0);
            this.businessUnits.remove(0);
        }
        this.gsOverall = 0;
        this.gsSatisfaction = 0;
        this.gsBudget = 0;
        this.gsTotalOverall = 0;
        this.gsTotalSatisfaction = 0;
        this.gsTotalBudget = 0;
        this.currentDate = Date.today();
        this.contractStats = new Contract_Statistic__c();
    }

    public GSOverallCalculationBatch(List<Business_Unit__c> businessUnits, Contract_Statistic__c contractStats, Date currentDate,
                                        Double gsTotalOverall, Double gsTotalSatisfaction, Double gsTotalBudget) {
        this.businessUnits = businessUnits;
        if (this.businessUnits.size() > 0) {
            this.currentUnit = this.businessUnits.get(0);
            this.businessUnits.remove(0);
        }
        this.gsOverall = 0;
        this.gsSatisfaction = 0;
        this.gsBudget = 0;
        this.gsTotalOverall = gsTotalOverall;
        this.gsTotalSatisfaction = gsTotalSatisfaction;
        this.gsTotalBudget = gsTotalBudget;
        this.currentDate = currentDate;
        this.contractStats = contractStats;
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

        this.cycleStartDate = startDate;

        if (this.currentUnit == null) {
            return new List<Project_Report_Out__c>();
        }
        return [SELECT Id, Contract__c, Report_Out_Date__c, Contract_Snapshot__c, Contract_Snapshot__r.Project_Quality_Overall_Status__c,
                Contract_Snapshot__r.Customer_Satisfaction_of_services__c, Contract_Snapshot__r.GS_Execution_Budget__c
                FROM Project_Report_Out__c WHERE Contract__r.Prime_Contracting_Business_Unit__c =: this.currentUnit.Id AND Contract_Snapshot__c != ''
                AND Report_Out_Date__c >=: startDate AND Report_Out_Date__c <: endDate];
    }

    public void execute(Database.BatchableContext BC, List<Project_Report_Out__c> scope) {
        try {
            System.debug('scope ; ' + scope.size());
            for (Project_Report_Out__c pro : scope) {
                System.debug(pro.Report_Out_Date__c);
                this.gsOverall += pro.Contract_Snapshot__r.Project_Quality_Overall_Status__c != null ? pro.Contract_Snapshot__r.Project_Quality_Overall_Status__c : 0;
                this.gsSatisfaction += pro.Contract_Snapshot__r.Customer_Satisfaction_of_services__c != null ? pro.Contract_Snapshot__r.Customer_Satisfaction_of_services__c : 0;
                this.gsBudget += pro.Contract_Snapshot__r.GS_Execution_Budget__c != null ? pro.Contract_Snapshot__r.GS_Execution_Budget__c : 0;
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
            System.debug('this.gsOverall : ' + this.gsOverall);
            System.debug('this.gsSatisfaction : ' + this.gsSatisfaction);
            System.debug('this.gsBudget : ' + this.gsBudget);
            this.gsTotalOverall += this.gsOverall;
            this.gsTotalSatisfaction += this.gsSatisfaction;
            this.gsTotalBudget += this.gsBudget;

            if (this.gsBudget == 0) {
                this.gsOverall = 0;
                this.gsSatisfaction = 0;
            } else {
                this.gsOverall = 100 * (this.gsOverall / this.gsBudget);
                this.gsSatisfaction = 100 * (this.gsSatisfaction / this.gsBudget);
            }

            String qualityField = (this.currentUnit.Name + '_GS_Overall_Status__c').toLowerCase();
            String customerField = (this.currentUnit.Name + '_GS_Customer_Sat__c').toLowerCase();
            Sobject sobj = (Sobject) this.contractStats;
            if (hasSObjectField(qualityField, sobj) && hasSObjectField(customerField, sobj)) {
                sobj.put(qualityField, this.gsOverall);
                sobj.put(customerField, this.gsSatisfaction);
            } else {
                System.debug('cannot find field with name : ' + qualityField + ' ' + customerField);
                if (!Test.isRunningTest()) {
                    EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot find sObject field for GS Quality',
                                    'Cannot find fields: ' + qualityField + ', ' + customerField);
                }
            }
        } catch (Exception ex) {
            System.debug('Error : ' + ex);
            if (!Test.isRunningTest()) {
                BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
                EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'GS Quality calculation error', 'GS Quality calculation error', ex);
            }
        }

        if (this.businessUnits.size() > 0) {
            GSOverallCalculationBatch overallBatch = new GSOverallCalculationBatch(this.businessUnits, this.contractStats, this.currentDate, this.gsTotalOverall,
                                                                                    this.gsTotalSatisfaction, this.gsTotalBudget);
            Database.executeBatch(overallBatch);
        } else {
            if (this.gsTotalBudget != 0) {
                this.gsTotalSatisfaction = 100 * (this.gsTotalSatisfaction / this.gsTotalBudget);
                this.gsTotalOverall = 100 * (this.gsTotalOverall / this.gsTotalBudget);
            } else {
                this.gsTotalSatisfaction = 0;
                this.gsTotalOverall = 0;
            }
            this.contractStats.PRO_Cycle_Date__c = this.cycleStartDate;
            this.contractStats.GS_Quality_Total_Overall_Status__c = this.gsTotalOverall;
            this.contractStats.GS_Quality_Total_Customer_Satisfaction__c = this.gsTotalSatisfaction;
            insert this.contractStats;
        }
    }

    private Boolean hasSObjectField(String fieldName, SObject so) {
        return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName);
    }
}