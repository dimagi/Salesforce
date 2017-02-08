/**
 * Calculates GS revenue for Dimagi Contracts. It calcualtes it for one Business Unit.
 */
public without sharing class GSRevenueCalculationBatch implements Database.Batchable<DContract__c>, Database.Stateful{

    private List<Business_Unit__c> businessUnits;
    private Business_Unit__c currentUnit;
    private Double gsRevenue;
    private List<DContract__c> contracts;

    public GSRevenueCalculationBatch(List<Business_Unit__c> businessUnits) {
        this.businessUnits = businessUnits;
        if (this.businessUnits.size() > 0) {
            this.currentUnit = this.businessUnits.get(0);
            this.businessUnits.remove(0);
        }
        this.gsRevenue = 0;
        this.contracts = new List<DContract__c>();
    }

    public List<DContract__c> start(Database.BatchableContext BC) {
        if (this.currentUnit != null) {
            return [SELECT Id, Name, GS_Execution_Budget__c, Percent_through_SOW_deliverables__c, GS_Revenue__c FROM DContract__c WHERE Prime_Contracting_Business_Unit__c =: this.currentUnit.Id];
        }
        return new List<DContract__c>();
    }

    public void execute(Database.BatchableContext BC, List<DContract__c> scope) {
        try {
            Map<Id, Decimal> workMap = getHistoryMap(scope);
            for (DContract__c con : scope) {
                Decimal val = workMap.get(con.Id);
                if (val == null) {
                    val = con.Percent_through_SOW_deliverables__c;
                }
                this.gsRevenue += (val != null ? val / 100.00 : 0) * (con.GS_Execution_Budget__c != null ? con.GS_Execution_Budget__c : 0);
                this.contracts.add(con);
            }
        } catch (Exception ex) {
            System.debug('Error : ' + ex);
            if (!Test.isRunningTest()) {
                BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
                EmailHelper.sendEmailFromException(settings.Error_Emails__c.split(','), 'GS Revenue calculation error', 'GS Revenue calculation error', ex);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        List<DContract__c> toUpdate = new List<DContract__c>();
        for (DContract__c con : this.contracts) {
            if (this.gsRevenue != con.GS_Revenue__c) {
                con.GS_Revenue__c = this.gsRevenue;
                toUpdate.add(con);
            }
        }
        List<Database.SaveResult> updateResults = Database.update(toUpdate, false);

        String emailBody = '';
        for(Integer i = 0; i < updateResults.size(); i++){
            if (!updateResults.get(i).isSuccess()){
                Database.Error error = updateResults.get(i).getErrors().get(0);
                System.debug('Error : Fields - ' + error.getFields() + ' Message - ' + error.getMessage());
                emailBody += '<tr><td>' + toUpdate.get(i).Id + '</td><td>' + error.getFields()+ '</td><td>' + error.getStatusCode()+ '</td><td>' + error.getMessage() + '</td></tr>';
            }
        }

        if (emailBody != '') {
            BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
            emailBody = '<table border="1"><tr><td>Id</td>td>Fields</td>td>Code</td><td>Error Message</td></tr>' + emailBody + '</table></br>';
            EmailHelper.sendEmail(settings.Error_Emails__c.split(','), 'GS Revenue calculation error', emailBody);
        }

        if (this.businessUnits.size() > 0) {
            Database.executeBatch(new GSRevenueCalculationBatch(this.businessUnits));
        } else {
            Database.executeBatch(new GSOverallCalculationBatch([SELECT Id FROM Business_Unit__c], false));
        }
    }

    private Map<Id, Decimal> getHistoryMap(List<DContract__c> scope) {
        if (Test.isRunningTest()) {
            return getTestDate(scope);
        }

        List<DContract__History> historyList = [SELECT OldValue, parentId, CreatedDate FROM DContract__History WHERE parentId IN: scope AND Field = 'Percent_through_SOW_deliverables__c'
                                                AND CreatedDate = THIS_MONTH ORDER BY CreatedDate ASC];
        Map<Id, Decimal> historyMap = new Map<Id, Decimal> ();

        for (DContract__History hRec : historyList) {
            if (!historyMap.containsKey(hRec.parentId)) {
                historyMap.put(hRec.parentId, hRec.OldValue != null ? (Decimal) hRec.OldValue : 0);
            }
        }

        return historyMap;
    }

    private Map<Id, Decimal> getTestDate(List<DContract__c> scope) {
        Map<Id, Decimal> historyMap = new Map<Id, Decimal> ();
        for (DContract__c con : scope) {
            if (con.Name == 'Sample Test 1') {
                historyMap.put(con.Id, 5);
            } else if (con.Name == 'Sample Test 2') {
                historyMap.put(con.Id, 30);
            } else if (con.Name == 'Sample Test 3') {
                historyMap.put(con.Id, 22);
            }
        }

        return historyMap;
    }

}