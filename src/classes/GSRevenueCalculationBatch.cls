/**
 * Calculates GS revenue for Dimagi Contracts. It calcualtes it for one Business Unit.
 */
public without sharing class GSRevenueCalculationBatch implements Database.Batchable<DContract__c>, Database.Stateful{

    private List<Business_Unit__c> businessUnits;
    private Business_Unit__c currentUnit;
    private Double gsRevenue;

    public GSRevenueCalculationBatch(List<Business_Unit__c> businessUnits) {
        this.businessUnits = businessUnits;
        if (this.businessUnits.size() > 0) {
            this.currentUnit = this.businessUnits.get(0);
            this.businessUnits.remove(0);
        }
    }

    public List<DContract__c> start(Database.BatchableContext BC) {
        if (this.currentUnit != null) {
            return [SELECT Id, GS_Execution_Budget__c, Percent_through_SOW_deliverables__c FROM DContract__c ];
        }
        return new List<DContract__c>();
    }

    public void execute(Database.BatchableContext BC, List<DContract__c> scope) {
        Map<Id, Double> workMap = new Map<Id, Double>(); // TODO Fetch 2 months history 
        for (DContract__c con : scope) {
            Double val = workMap.get(con.Id);
            if (val = null) {
                val = con.Percent_through_SOW_deliverables__c;
            }
            this.gsRevenue += (val != null ? val / 100.00 : 0) * (con.GS_Execution_Budget__c != null ? con.GS_Execution_Budget__c : 0);
        }
    }

    public void finish(Database.BatchableContext BC) {
        // TODO update contracts !!!
        if (this.businessUnits.size() > 0) {
            // TODO Calculate for other BU
            //Database.executeBatch(new BatchCalculateEVDiff(Date.today().toStartOfMonth().addDays(-1), false));
        }
    }

    private Map<Id, Double> getHistoryMap() {
        return null;
    }
}