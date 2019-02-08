public class ContractPipelineSnapshotBatch implements Database.Batchable<DContract__c>, Database.Stateful {

    private Date runDate;
    private Date monthStart;

    public ContractPipelineSnapshotBatch() {
        this(Date.today());
    }

    public ContractPipelineSnapshotBatch(Date runDate) {
        this.runDate = runDate;
        this.monthStart = this.runDate.toStartOfMonth();
    }

    public List<DContract__c> start(Database.BatchableContext BC) {
        List<Pipeline_Snapshot__c> psTORemove = [SELECT Id FROM Pipeline_Snapshot__c WHERE Month_Date__c =: this.runDate AND Source_Type__c = 'Contract'];
        if (psTORemove.size() > 0) {
            delete psTORemove;
        }

        return [SELECT Id, Name, Invoiced__c, Percent_through_SOW_deliverables__c, Account_ID__c, Total_Amount_REMAINING__c,Services_Spend__c, Funder_Account__c,
                Billing_Deficit__c, Billing_efficiency__c, Contract_End_Date__c, Date_of_Contract_Execution__c, Contract_Start_Date__c, GS_Services_Completed__c,
                Total_Non_Expense_Income_Remaining__c, Country_Text__c, Duration_months__c, Expected_Buffer__c, Direct_Costs_Total_Expenses__c,
                GS_Net_Income_to_Date__c, GS_Net_Income_to_Date_Handover__c, GS_Execution_Budget__c, GS_Project_Services_Budget_Handoff__c,
                GS_Services_Completed_Handover__c, Intracompany_Sub_contract__c, Contracting_Business_Unit__c, Product_Text__c, Product_Spend__c,
                Total_Costs__c, Total_Direct_Costs_Expenses__c, Total_Non_Expense_Income_BUDGET__c, OwnerId, Status__c, Total_Amount_of_Contract__c
                FROM DContract__c
                WHERE Status__c = 'Active' OR (Date_of_Contract_Execution__c >=: this.monthStart AND Date_of_Contract_Execution__c <=: this.runDate)];
    }

    public void execute(Database.BatchableContext BC, List<DContract__c> scope) {
        List<Pipeline_Snapshot__c> newSnapshots = new List<Pipeline_Snapshot__c>();
        for (DContract__c dContract : scope) {
            String nameSuffix = ' - ' + this.runDate.month() + '/' + this.runDate.year();
            String nameSuffixTotal = nameSuffix + ' - Total';
            String namePrefix = dContract.Name;
            String namePrefixTotal = dContract.Name;

            if (namePrefix != null && namePrefix.length() + nameSuffix.length() > 80) {
                Integer charsToCut = namePrefix.length() - (namePrefix.length() + nameSuffix.length() - 80);
                namePrefix = namePrefix.subString(0, charsToCut);
            }

            if (namePrefixTotal != null && namePrefixTotal.length() + nameSuffixTotal.length() > 80) {
                Integer charsToCut = namePrefixTotal.length() - (namePrefixTotal.length() + nameSuffixTotal.length() - 80);
                namePrefixTotal = namePrefix.subString(0, charsToCut);
            }

            if (dContract.Status__c == 'Active') {
                Pipeline_Snapshot__c newPs = buildSnapshot(dContract, namePrefix + nameSuffix, this.runDate, 'Outstanding Contracted');
                Pipeline_Snapshot__c newPsTotal = buildSnapshot(dContract, namePrefixTotal + nameSuffixTotal, this.runDate, 'Total');

                // set custom outstanding fields
                newPs.Invoiced__c = dContract.Invoiced__c;
                newPs.Billing_efficiency__c = dContract.Billing_efficiency__c;
                newPs.Amount__c = dContract.Total_Amount_REMAINING__c;
                newPs.Amount_Minus_Expense_Income__c = dContract.Total_Non_Expense_Income_Remaining__c;
                // set custom total fields
                newPsTotal.Invoiced__c = dContract.Invoiced__c;
                newPsTotal.Billing_efficiency__c = dContract.Billing_efficiency__c;
                newPsTotal.Contract_Expense_Income__c = dContract.Total_Direct_Costs_Expenses__c;
                newPsTotal.Amount__c = dContract.Total_Amount_REMAINING__c;
                newPsTotal.Amount_Minus_Expense_Income__c = dContract.Total_Non_Expense_Income_Remaining__c;


                newPs.recalculateFormulas();
                newPsTotal.recalculateFormulas();
                newPs = SnapshotHelper.calculateForPeriod(newPs, SnapshotHelper.getOldSnapshots(newPs, false));
                newPsTotal = SnapshotHelper.calculateForPeriod(newPsTotal, SnapshotHelper.getOldSnapshots(newPsTotal, true));
                newSnapshots.add(newPs);
                newSnapshots.add(newPsTotal);
            }

            if (dContract.Date_of_Contract_Execution__c >= this.monthStart && dContract.Date_of_Contract_Execution__c <= this.runDate) {
                Pipeline_Snapshot__c newPs = buildSnapshot(dContract, namePrefix + nameSuffix, this.runDate, 'Closed');

                // set custom closed fields
                newPs.Amount__c = dContract.Total_Amount_of_Contract__c;
                newPs.Amount_Minus_Expense_Income__c = dContract.Total_Non_Expense_Income_BUDGET__c;
                newPs.Contract_Expense_Income__c = dContract.Total_Direct_Costs_Expenses__c;
                newPs.Contract_Total_Non_Expense_Income_BUDGET__c = dContract.Total_Non_Expense_Income_BUDGET__c;
                newPs.OwnerId = dContract.OwnerId;

                newPs.recalculateFormulas();
                newPs = SnapshotHelper.calculateForPeriod(newPs, SnapshotHelper.getOldSnapshots(newPs, false));
                newSnapshots.add(newPs);
            }
        }

        if (newSnapshots.size() > 0) {
            insert newSnapshots;
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            // TODO : email notification to users wit emails from settings !!!
            EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Contract Pipeline Snapshots', 'Job finished : ' + Date.today() + ' created for : ' + this.runDate);
        }
    }

    private Pipeline_Snapshot__c buildSnapshot(DContract__c dContract, String name, Date monthDate, String stageName) {
        return new Pipeline_Snapshot__c (
                        Work_Completed__c = dContract.Percent_through_SOW_deliverables__c,
                        Account__c = dContract.Account_ID__c,
                        Billing_Deficit__c = dContract.Billing_Deficit__c,
                        Contract__c = dContract.Id,
                        Total_Amount_REMAINING__c = dContract.Total_Amount_REMAINING__c,
                        Contract_End_Date__c = dContract.Contract_End_Date__c,
                        Contract_Execution_Date__c = dContract.Date_of_Contract_Execution__c,
                        Contract_Start_Date__c = dContract.Contract_Start_Date__c,
                        Contract_Total_Non_Expense_Income_Rmg__c = dContract.Total_Non_Expense_Income_Remaining__c,
                        Country__c = dContract.Country_Text__c,
                        Duration_months__c = dContract.Duration_months__c,
                        Expected_Buffer__c = dContract.Expected_Buffer__c,
                        Expense_Travel_Spend__c = dContract.Direct_Costs_Total_Expenses__c,
                        Funder_Account__c = dContract.Funder_Account__c,
                        GS_Net_Income_to_Date__c = dContract.GS_Net_Income_to_Date__c,
                        GS_Net_Income_to_Date_Handover__c = dContract.GS_Net_Income_to_Date_Handover__c,
                        GS_Execution_Budget__c = dContract.GS_Execution_Budget__c,
                        GS_Project_Services_Budget_Handoff_Cp__c = dContract.GS_Project_Services_Budget_Handoff__c,
                        GS_Services_Completed__c = dContract.GS_Services_Completed__c,
                        GS_Services_Completed_Handover__c = dContract.GS_Services_Completed_Handover__c,
                        Intracompany_Sub_contract__c = dContract.Intracompany_Sub_contract__c,
                        Owning_Entity__c = dContract.Contracting_Business_Unit__c,
                        Products__c = dContract.Product_Text__c,
                        Product_Spend__c = dContract.Product_Spend__c,
                        Services_Spend__c = dContract.Services_Spend__c,
                        Total_Calculated_Costs__c = dContract.Total_Costs__c,
                        Month_Date__c = monthDate,
                        Probability__c = 100,
                        Source_Type__c = 'Contract',
                        Stage__c = stageName,
                        Name = name
                    );
    }
}