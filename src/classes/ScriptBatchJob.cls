/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<Project_Report_Out__c>, Database.Stateful {

    public ScriptBatchJob(Date helperDate) {
    }

    public ScriptBatchJob() {
    }

    public List<Project_Report_Out__c> start(Database.BatchableContext context) {
        return [SELECT Id, Contract_Snapshot__c FROM Project_Report_Out__c WHERE Contract_Snapshot__c != null AND Report_Out_Date__c >: Date.newInstance(2017,4,1)];
    }

    public void execute(Database.BatchableContext context, List<Project_Report_Out__c> scope) {
        Set<Id> snpIds = new Set<Id>();
        List<PRO_Contract_Snapshot__c> snapshotList;

        for (Project_Report_Out__c pro : scope) {
            snpIds.add(pro.Contract_Snapshot__c);
        }

        snapshotList = [SELECT Id, Budget_Used__c, Percent_Of_Work_Completed__c, Services_Spend__c, GS_Execution_Budget__c, Percent_Services_Budget_For_GS__c,
                             Execution_Efficiency__c, Buffer_By_Deliverables_Complete__c FROM PRO_Contract_Snapshot__c WHERE Id IN: snpIds];
        for (PRO_Contract_Snapshot__c snp : snapshotList) {

            if (snp.Services_Spend__c != null & snp.Services_Spend__c != 0 &&
                    snp.GS_Execution_Budget__c != null && snp.GS_Execution_Budget__c != 0 && snp.Percent_Services_Budget_For_GS__c != null &&
                    snp.Percent_Services_Budget_For_GS__c != 0) {
                Decimal servicesBudget = snp.GS_Execution_Budget__c / (snp.Percent_Services_Budget_For_GS__c / 100.00);

                Decimal newEE = 100;
                if (servicesBudget > 0 && snp.Services_Spend__c > 0) {
                    newEE = 100.00 * ((servicesBudget * (snp.Percent_Of_Work_Completed__c / 100.00)) / snp.Services_Spend__c);
                }
                snp.Execution_Efficiency__c = newEE;
            }

            snp.Buffer_By_Deliverables_Complete__c = (snp.Percent_Of_Work_Completed__c != null ? snp.Percent_Of_Work_Completed__c : 0 )
                            - (snp.Budget_Used__c != null ? snp.Budget_Used__c : 0);

        }

        if (snapshotList.size() > 0) {
            update snapshotList;
        }
    }

    public void finish(Database.BatchableContext context) {
    }
}