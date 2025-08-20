public class CalculateAllTimeIncomeBatch implements Database.Batchable<Sobject>, Database.AllowsCallouts, Database.Stateful {
    public Integer recordsProcessed = 0;
    public Id contractId;
    
    public CalculateAllTimeIncomeBatch(Id recordId){
        this.contractId = recordId;
    }
    public CalculateAllTimeIncomeBatch(){
        this.contractId = null;
    }
    public List<DContract__c> start(Database.BatchableContext context) {
        String baseQuery = 'SELECT Id ,Interdivision_Child_Contract_1__c,Interdivision_Child_Contract_2__c,'+
            'Interdivision_Child_Contract_1__r.ALL_TIME_Income__c,Interdivision_Child_Contract_2__r.ALL_TIME_Income__c,'+
            'ID_Subcontract_Spend__c ,ID_Subcontract_2_Spend__c '+
            'from DContract__c ';
        String forSingleRecord = 'WHERE Id = \''+ this.contractId + '\'';
        String query;
        
        if(this.contractId != null){
            query = baseQuery + forSingleRecord;
        }
        else{
            query = baseQuery;
        }
        System.debug('Query: '+ query);
        return Database.query(query);
    }
    
    public void execute(Database.BatchableContext context, List<DContract__c> scope) {
        List<DContract__c> contractObjList = new List<DContract__c>();
        for (DContract__c contractObj : scope) {
            if(contractObj.Interdivision_Child_Contract_1__c != null || contractObj.Interdivision_Child_Contract_2__c != null) {
                if(contractObj.Interdivision_Child_Contract_1__c != null && contractObj.Interdivision_Child_Contract_2__c == null){
                    contractObj.ID_Subcontract_Spend__c = contractObj.Interdivision_Child_Contract_1__r.ALL_TIME_Income__c != null ? contractObj.Interdivision_Child_Contract_1__r.ALL_TIME_Income__c : 0;
                    contractObj.ID_Subcontract_2_Spend__c = 0;
                }
                else if(contractObj.Interdivision_Child_Contract_1__c == null && contractObj.Interdivision_Child_Contract_2__c != null){
                    contractObj.ID_Subcontract_Spend__c = 0;
                    contractObj.ID_Subcontract_2_Spend__c = contractObj.Interdivision_Child_Contract_2__r.ALL_TIME_Income__c != null ? contractObj.Interdivision_Child_Contract_2__r.ALL_TIME_Income__c : 0;
                }
                else {
                    contractObj.ID_Subcontract_Spend__c = contractObj.Interdivision_Child_Contract_1__r.ALL_TIME_Income__c != null ? contractObj.Interdivision_Child_Contract_1__r.ALL_TIME_Income__c : 0;
                    contractObj.ID_Subcontract_2_Spend__c = contractObj.Interdivision_Child_Contract_2__r.ALL_TIME_Income__c != null ? contractObj.Interdivision_Child_Contract_2__r.ALL_TIME_Income__c : 0;
                }
            } else {
                contractObj.ID_Subcontract_Spend__c = 0;
                contractObj.ID_Subcontract_2_Spend__c = 0;
            }
            contractObjList.add(contractObj);
            this.recordsProcessed++;
        }
        try{
            update contractObjList;
        } catch(Exception ex) {
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot Update Contracts', 'Error : ', ex);
            }
            System.debug('The following exception has occurred: ' + ex.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext context) {
        try {
            if (!Test.isRunningTest()) {
                if(this.contractId != null){
                    Database.executeBatch(new UpdateTotalAmountRemainingBatch(this.contractId));
                }
                else{
                    Database.executeBatch(new UpdateTotalAmountRemainingBatch(), 100);
                }               
            }
        } catch (Exception ex) {
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot Update Contracts', 'Error : ', ex);
            }
            System.debug('The following exception has occurred: ' + ex.getMessage());
        }
        StatusLoggerUtils.logInfo(StatusLoggerUtils.CONTRACT_ALL_TIME_INCOME_LOGGER, 'Calculate All Time Income Script', this.recordsProcessed,
                                  'Finished Calculate All Time Income Job with date : ' + Date.today());
        StatusLoggerUtils.sendLog(StatusLoggerUtils.CONTRACT_ALL_TIME_INCOME_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        
    }
}