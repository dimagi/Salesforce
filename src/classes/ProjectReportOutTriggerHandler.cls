/**
 * Handler for Project Report Out custom object. It updates relation on Contract to tthe latest PRO.
 */
public class ProjectReportOutTriggerHandler {

    public static void afterInsert(List<Project_Report_Out__c> newRecords) {
        Map<Id, Project_Report_Out__c> proMap = new Map<Id, Project_Report_Out__c>();
        for (Project_Report_Out__c newPRO : newRecords) {
            if (newPRO.Contract__c != null) {
                if (proMap.containsKey(newPRO.Contract__c)) {
                    if (proMap.get(newPRO.Contract__c).Report_Out_Date__c < newPRO.Report_Out_Date__c) {
                        proMap.put(newPRO.Contract__c, newPRO); // replace, we want update to the latest date
                    }
                } else {
                    proMap.put(newPRO.Contract__c, newPRO);
                }
            }
        }

        Map<Id, DContract__c> proContractsMap = new Map<Id, DContract__c>
                                                        ([SELECT Id, Last_Project_Report_Out__c, Last_Project_Report_Out__r.Report_Out_Date__c, Last_Report_Out_Status__c
                                                          FROM DContract__c WHERE Id IN: proMap.keySet()]);
        Set<DContract__c> contractsToUpdate = new Set<DContract__c>();

        for (Id contractId : proMap.keySet()) {
            Project_Report_Out__c newPRO = proMap.get(contractId);
            if (newPRO != null && newPRO.Contract__c != null) {
                DContract__c dContract = proContractsMap.get(newPRO.Contract__c);

                if (dContract != null &&
                        (dContract.Last_Project_Report_Out__c == null || newPro.Report_Out_Date__c > dContract.Last_Project_Report_Out__r.Report_Out_Date__c)) {
                    dcontract.Last_Report_Out_Status__c = newPro.Status__c;
                    dcontract.Last_Project_Report_Out__c = newPro.Id;
                    dcontract.Last_PRO_Client_Facing_Deadlines__c = newPro.Client_Facing__c;
                    dcontract.Last_PRO_Internal_Developer_Deadlines__c = newPro.Requires_Developer_Work__c;
                    dcontract.Last_PRO_Issues_Questions_Notables__c = newPro.Issues_Questions_Notables__c;
                    dcontract.Last_PRO_Key_accompl_last_two_weeks__c = newPro.Key_Accomplishments_Last_Two_Weeks__c;
                    dcontract.Last_PRO_Key_next_steps_next_two_weeks__c = newPro.Key_Next_Steps_next_2_weeks__c;
                    contractsToUpdate.add(dContract);
                }
            }
        }

        if (contractsToUpdate.size() > 0) {
            List<DContract__c> toUpdateList = new List<DContract__c>();
            toUpdateList.addAll(contractsToUpdate);
            update toUpdateList;
        }
    }

    public static void afterUpdate(List<Project_Report_Out__c> updatedRecords, Map<Id, Project_Report_Out__c> oldMap) {
        Set<Id> contractIds = new Set<Id>();
        for (Project_Report_Out__c updatedPro : updatedRecords) {
            contractIds.add(updatedPro.Contract__c);
        }

        Map<Id, DContract__c> proContractsMap = new Map<Id, DContract__c>
                                                        ([SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c
                                                          FROM DContract__c WHERE Id IN: contractIds]);
        List<DContract__c> contractToUpdate = new List<DContract__c>();

        for (Project_Report_Out__c updatedPro : updatedRecords) {
            DContract__c dContract = proContractsMap.get(updatedPro.Contract__c);

            // Perform update only when PRO is last one, it must be connected to the contrat object
            if (dContract != null && dContract.Last_Project_Report_Out__c != null
                    && dContract.Last_Project_Report_Out__c == updatedPro.Id) {
                Project_Report_Out__c oldPro = oldMap.get(updatedPro.Id);
                if (oldPro != null && updatedPro.Contract__c != null && oldPro.Status__c != updatedPro.Status__c) {
                    dcontract.Last_Report_Out_Status__c = updatedPro.Status__c;
                }
                dcontract.Last_PRO_Client_Facing_Deadlines__c = updatedPro.Client_Facing__c;
                dcontract.Last_PRO_Internal_Developer_Deadlines__c = updatedPro.Requires_Developer_Work__c;
                dcontract.Last_PRO_Issues_Questions_Notables__c = updatedPro.Issues_Questions_Notables__c;
                dcontract.Last_PRO_Key_accompl_last_two_weeks__c = updatedPro.Key_Accomplishments_Last_Two_Weeks__c;
                dcontract.Last_PRO_Key_next_steps_next_two_weeks__c = updatedPro.Key_Next_Steps_next_2_weeks__c;
                contractToUpdate.add(dContract);
            }
        }

        if (contractToUpdate.size() > 0) {
            update contractToUpdate;
        }
    }
}