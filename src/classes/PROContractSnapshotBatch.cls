/*
* Batch responsible for creating the PRO Contract Snapshot custom object for projects that
* are active but do not require a report out.
*/
global class PROContractSnapshotBatch implements Database.Batchable<DContract__c>, Database.Stateful {

    private List<PRO_Contract_Snapshot__c> failedReocrds = new List<PRO_Contract_Snapshot__c>();

    public PROContractSnapshotBatch(){

    }

    global List<DContract__c> start(Database.BatchableContext context) {
       return GetContract();
    }

    global void execute(Database.BatchableContext context, List<DContract__c> contracts) {
        List<PRO_Contract_Snapshot__c> insertList = new List<PRO_Contract_Snapshot__c>();

        for (DContract__c dcontract : contracts) {
            PRO_Contract_Snapshot__c proContractSnapshot = new PRO_Contract_Snapshot__c();

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

            insertList.add(proContractSnapshot);
        }

        List<Database.SaveResult> insertResults = Database.insert(insertList, false);

        for(Integer i = 0; i < insertResults.size(); i++){
            if (!insertResults.get(i).isSuccess()){
                Database.Error error = insertResults.get(i).getErrors().get(0);
                System.debug('DML error ' + error.getMessage());
                System.debug('Failed to create snapshot for Contract: ' + insertResults.get(i).Contract__c);
                failedReocrds.add(insertList.get(i));
            }
        }
    }

    global void finish(Database.BatchableContext context) {
        List<String> toAddresses = new List<String>();
        Contract_Snapshot_Settings__c settings = Contract_Snapshot_Settings__c.getOrgDefaults();

        if(settings.Error_Email__c != null) {
            for(String email : settings.Error_Email__c.split(',')) {
                toAddresses.add(email);
            }

            if(failedReocrds.size() > 0 && toAddresses.size() > 0) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAddresses);
                mail.setSenderDisplayName('');
                mail.setSubject('Contract Snapshot Errors ' + Date.today());
                String htmlBody = 'Failed to save snapshopts for following contracts: <br/>';

                for(PRO_Contract_Snapshot__c snp : failedReocrds) {
                    // TODO
                    htmlBody +=  '<b>Id:</b> ' + snp.Contract__c + '<br/>';
                }

                mail.setUseSignature(false);
                mail.setHtmlBody(htmlBody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }

    private List<DContract__c> GetContract() {
        List<DContract__c> contractList = [SELECT Id, Name, Last_Report_Out_Status__c, Percent_through_SOW_deliverables__c, Budget_Used__c, of_Services_budget_for_GS__c, Total_Costs__c, Services_Spend__c,
                                                Buffer_by_SOW_Completed__c, Execution_Efficiency__c, Expected_Buffer__c, Direct_Costs_Total_Expenses__c, Net_Income_based_on_SOW_Completed__c, Product_Spend__c
                                                FROM DContract__c WHERE   Status__c = 'Active' AND Requires_Report_Out__c = 'No'];
       return contractList;
    }
}