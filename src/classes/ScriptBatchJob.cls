/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;

    public ScriptBatchJob() {
        this.helperDate = Date.today();
    }

    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Name, Last_PRO_Client_Facing_Deadlines__c, Last_PRO_Internal_Developer_Deadlines__c,'
                                        + ' Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,'
                                        + ' Last_PRO_Key_next_steps_next_two_weeks__c, Last_Project_Report_Out__r.Requires_Developer_Work__c,'
                                        + ' Last_Project_Report_Out__r.Client_Facing__c, Last_Project_Report_Out__r.Issues_Questions_Notables__c,'
                                        + ' Last_Project_Report_Out__r.Key_Accomplishments_Last_Two_Weeks__c, Last_Project_Report_Out__r.Key_Next_Steps_next_2_weeks__c'
                                        + ' FROM DContract__c WHERE Last_Project_Report_Out__c != null');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<DContract__c> toUpdate = new List<DContract__c>();
        for (SObject objRec : scope) {
            DContract__c dContract = (DContract__c) objRec;
            dContract.Last_PRO_Client_Facing_Deadlines__c = dContract.Last_Project_Report_Out__r.Client_Facing__c;
            dContract.Last_PRO_Internal_Developer_Deadlines__c = dContract.Last_Project_Report_Out__r.Requires_Developer_Work__c;
            dContract.Last_PRO_Issues_Questions_Notables__c = dContract.Last_Project_Report_Out__r.Issues_Questions_Notables__c;
            dContract.Last_PRO_Key_accompl_last_two_weeks__c = dContract.Last_Project_Report_Out__r.Key_Accomplishments_Last_Two_Weeks__c;
            dContract.Last_PRO_Key_next_steps_next_two_weeks__c = dContract.Last_Project_Report_Out__r.Key_Next_Steps_next_2_weeks__c;
            toUpdate.add(dContract);
        }

        if (toUpdate.size() > 0) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}