public class AggregateExecutionEfficiencySnpJob {

    @future
    public static void createAggregateExecutionEfficiencySnapshot() {
        Corporate_Dashboard_Settings__c corporateDashboardSettings = Corporate_Dashboard_Settings__c.getOrgDefaults();
        List<Global_Metric_Graph__c> aggregateEff = new List<Global_Metric_Graph__c>();
        AggregateResult[] resultContr = [SELECT Efficiency_Owner_BU__r.Name, SUM(Services_Budget__c), SUM(Weighted_Efficiency__c) FROM DContract__c
                                         WHERE (NOT Name LIKE '%internal%') AND Total_Amount_of_Contract__c > 0
                                         AND (NOT Name LIKE '%MOTECH suite%') AND Implementation_Type__c != 'Self Service'
                                         AND Implementation_Type__c != '' AND Efficiency_Owner_BU__c != null
                                         AND Intracompany_Sub_contract__c = 'No' AND Percent_through_SOW_deliverables__c != 100
                                         AND Status__c != 'Complete'
                                         GROUP BY Efficiency_Owner_BU__r.Name ORDER BY Efficiency_Owner_BU__r.Name];

        Decimal totalSumServices = 0;
        Decimal totalSumEff = 0;

        Aggregate_Execution_Efficiency_Snapshot__c snapshot = new Aggregate_Execution_Efficiency_Snapshot__c(Date__c = Date.today());
        SObject sObjSnapshot = (SObject) snapshot;

        if (resultContr.size() > 0) {
            for (AggregateResult ar : resultContr) {
                String currName = (String) ar.get('Name');

                Decimal sumServices = ar.get('expr0') != null ? (Decimal) ar.get('expr0') : 0;
                Decimal sumEff = ar.get('expr0') != null ? (Decimal) ar.get('expr1') : 0;

                totalSumServices += sumServices;
                totalSumEff += sumEff;
                Decimal valuetoSet = 1;

                if (sumServices > 0 && totalSumEff != 0) {
                    valuetoSet = (sumServices / sumEff) * 100.00;
                } else if (sumEff == 0) {
                    valuetoSet = 0;
                }

                String fieldName = (currName + '__c').toLowerCase();
                if (hasSObjectField(fieldName, sObjSnapshot)) {
                    sObjSnapshot.put(fieldName, valuetoSet);
                }
            }
        }

        Decimal totalValue = 1;
        if (totalSumServices > 0 && totalSumEff != 0) {
            totalValue = (totalSumServices / totalSumEff) * 100.00;
        } else if (totalSumEff == 0) {
            totalValue = 0;
        }

        snapshot = (Aggregate_Execution_Efficiency_Snapshot__c) sObjSnapshot;
        snapshot.Total_Aggregate_Execution_Efficiency__c = totalValue;
        insert snapshot;
    }

    private static Boolean hasSObjectField(String fieldName, SObject so) {
        return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName);
    }
}