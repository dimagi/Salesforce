/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;
    private Id parentContract;
    private Decimal servicesSpendToDate;
    private Set<Id> contracts;

    public ScriptBatchJob() {
        this.helperDate = Date.today();
    }

    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
        
    }

    public ScriptBatchJob(Date helperDate, Id parentContract) {
        this.helperDate = helperDate;
        this.parentContract = parentContract;
        this.servicesSpendToDate = 0;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        this.contracts = new Set<Id>();
        this.contracts.add(this.parentContract);
        for (DContract__c con : [SELECT Id, Parent_Contract__c FROM DContract__c WHERE Parent_Contract__c IN: this.contracts]) {
            this.contracts.add(con.Id);
        }
        return Database.getQueryLocator('SELECT Id, Time_Card_Rate_Cost__c FROM Time_Card__c WHERE Date__c <=: helperDate AND Client__c IN: contracts');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        for (SObject otc : scope) {
            Time_Card__c tc = (Time_Card__c) otc;
            this.servicesSpendToDate += tc.Time_Card_Rate_Cost__c;
        }
    }

    public void finish(Database.BatchableContext context) {
        List<Pipeline_Snapshot__c> toUpdate = [SELECT Id, Services_Spend__c, GS_Net_Income_to_Date_Handover__c, GS_Net_Income_to_Date__c, Total_Calculated_Costs__c FROM Pipeline_Snapshot__c WHERE Month_Date__c =: this.helperDate
                                                                                                                                                                                    AND Contract__c =: this.parentContract];
        for (Pipeline_Snapshot__c record : toUpdate) {
            record.GS_Net_Income_to_Date_Handover__c = record.GS_Net_Income_to_Date_Handover__c + record.Services_Spend__c - this.servicesSpendToDate;
            record.GS_Net_Income_to_Date__c = record.GS_Net_Income_to_Date__c + record.Services_Spend__c - this.servicesSpendToDate;
            record.Total_Calculated_Costs__c = record.Total_Calculated_Costs__c - record.Services_Spend__c + this.servicesSpendToDate;
            record.Services_Spend__c = this.servicesSpendToDate;
            update record;
        }
    }
}