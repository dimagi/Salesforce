/**
 * Helper class used for creating Snasphots objects in the System.
 */
public class SnapshotHelper {

    public static Map<Id, PRO_Contract_Snapshot__c> getOldPROSnapshot(List<DContract__c> contracts) {
        Map<Id, PRO_Contract_Snapshot__c> snapshotsMap =  new Map<Id, PRO_Contract_Snapshot__c>();
        List<PRO_Contract_Snapshot__c> snapshotsList = [SELECT Id, Percent_Of_Work_Completed__c, Services_Spend__c, Expense_And_Travel_Spend__c, Product_Spend__c, Total_Calculated_Costs__c, GS_Services_Completed_Handover__c
                                          GS_Services_Completed__c, GS_Net_Income_to_Date__c, GS_Net_Income_to_Date_Handover__c FROM PRO_Contract_Snapshot__c WHERE Snapshot_Date__c <: Date.today()
                                          AND Contract__c IN: contracts ORDER BY Snapshot_Date__c DESC];

        for (PRO_Contract_Snapshot__c sn : snapshotsList) {
            if (!snapshotsMap.containcKey(sn.Contract__c)) {
                snapshotsMap.put(sn.Contract__c, sn);
            }
        }

        return snapshotsMap;
    }

    public static PRO_Contract_Snapshot__c getLastPROSnapshot(DContract__c dcontract) {
        List<PRO_Contract_Snapshot__c> snapshotsList = [SELECT Id, Percent_Of_Work_Completed__c, Services_Spend__c, Expense_And_Travel_Spend__c, Product_Spend__c, Total_Calculated_Costs__c, GS_Services_Completed_Handover__c
                                          GS_Services_Completed__c, GS_Net_Income_to_Date__c, GS_Net_Income_to_Date_Handover__c FROM PRO_Contract_Snapshot__c WHERE Snapshot_Date__c <: Date.today()
                                          AND Contract__c =: dcontract ORDER BY Snapshot_Date__c DESC LIMIT 1];
        if (snapshotsList.size() > 0) {
            return snapshotsList.get(0);
        }

        return new PRO_Contract_Snapshot__c();
    }

    public static PRO_Contract_Snapshot__c fillPROSnapshot(PRO_Contract_Snapshot__c proContractSnapshot, DContract__c dcontract, PRO_Contract_Snapshot__c oldSnapshot) {
            proContractSnapshot.Budget_Used__c = dcontract.Budget_Used__c;
            proContractSnapshot.Percent_Of_Work_Completed__c = dcontract.Percent_through_SOW_deliverables__c;
            proContractSnapshot.Percent_Services_Budget_For_GS__c = dcontract.of_Services_budget_for_GS__c;
            proContractSnapshot.Buffer_By_Deliverables_Complete__c = dcontract.Buffer_by_SOW_Completed__c;
            proContractSnapshot.Execution_Efficiency__c = dcontract.Execution_Efficiency__c;
            proContractSnapshot.Expected_Buffer__c = dcontract.Expected_Buffer__c;
            proContractSnapshot.Expense_And_Travel_Spend__c = dcontract.Direct_Costs_Total_Expenses__c;
            proContractSnapshot.Net_Income_By_Deliverables_Complete__c = dcontract.Net_Income_based_on_SOW_Completed__c;
            proContractSnapshot.Product_Spend__c = dcontract.Product_Spend__c;
            proContractSnapshot.Services_Spend__c = dcontract.Services_Spend__c;
            proContractSnapshot.Total_Calculated_Costs__c = dcontract.Total_Costs__c;
            proContractSnapshot.Contract__c = dcontract.Id;
            proContractSnapshot.Name = dcontract.Name;
            proContractSnapshot.Snapshot_Date__c = Date.today();
            proContractSnapshot.GS_Execution_Budget__c = dcontract.GS_Execution_Budget__c;
            proContractSnapshot.GS_Services_Completed_Handover__c = dcontract.GS_Services_Completed_Handover__c;
            proContractSnapshot.GS_Services_Completed__c = dcontract.GS_Services_Completed__c;
            proContractSnapshot.GS_Net_Income_to_Date__c = dcontract.GS_Net_Income_to_Date__c;
            proContractSnapshot.GS_Net_Income_to_Date_Handover__c = dcontract.GS_Net_Income_to_Date_Handover__c;

            proContractSnapshot.Work_Completed_for_Period__c = (dcontract.Percent_through_SOW_deliverables__c != null ? dcontract.Percent_through_SOW_deliverables__c : 0) - (oldSnapshot.Percent_Of_Work_Completed__c != null ? oldSnapshot.Percent_Of_Work_Completed__c : 0);
            proContractSnapshot.Services_Spend_for_Period__c = (dcontract.Services_Spend__c != null ? dcontract.Services_Spend__c : 0) - (oldSnapshot.Services_Spend__c != null ? oldSnapshot.Services_Spend__c : 0);
            proContractSnapshot.Expense_Travel_Spend_for_Period__c = (dcontract.Direct_Costs_Total_Expenses__c != null ? dcontract.Direct_Costs_Total_Expenses__c : 0) - (oldSnapshot.Expense_And_Travel_Spend__c != null ? oldSnapshot.Expense_And_Travel_Spend__c : 0);
            proContractSnapshot.Product_Spend_for_Period__c = (dcontract.Product_Spend__c != null ? dcontract.Product_Spend__c : 0) - (oldSnapshot.Product_Spend__c != null ? oldSnapshot.Product_Spend__c : 0);
            proContractSnapshot.Total_Calculated_Costs_for_Period__c = (dcontract.Total_Costs__c != null ? dcontract.Total_Costs__c : 0) - (oldSnapshot.Total_Calculated_Costs__c != null ? oldSnapshot.Total_Calculated_Costs__c : 0);
            proContractSnapshot.GS_Services_Handover_Completed_for_Per__c = (dcontract.GS_Services_Completed_Handover__c != null ? dcontract.GS_Services_Completed_Handover__c : 0) - (oldSnapshot.GS_Services_Completed_Handover__c != null ? oldSnapshot.GS_Services_Completed_Handover__c : 0);
            proContractSnapshot.GS_Services_Completed_for_Period__c = (dcontract.GS_Services_Completed__c != null ? dcontract.GS_Services_Completed__c : 0) - (oldSnapshot.GS_Services_Completed__c != null ? oldSnapshot.GS_Services_Completed__c : 0);
            proContractSnapshot.GS_Net_Income_for_Period__c = (dcontract.GS_Net_Income_to_Date__c != null ? dcontract.GS_Net_Income_to_Date__c : 0) - (oldSnapshot.GS_Net_Income_to_Date__c != null ? oldSnapshot.GS_Net_Income_to_Date__c : 0);
            proContractSnapshot.GS_Net_Income_for_Period_by_Handover__c = (dcontract.GS_Net_Income_to_Date_Handover__c != null ? dcontract.GS_Net_Income_to_Date_Handover__c : 0) - (oldSnapshot.GS_Net_Income_to_Date_Handover__c != null ? oldSnapshot.GS_Net_Income_to_Date_Handover__c : 0);

            return proContractSnapshot;
    }
}