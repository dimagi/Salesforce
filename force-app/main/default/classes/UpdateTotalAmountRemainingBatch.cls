public class UpdateTotalAmountRemainingBatch implements Database.Batchable<Sobject>, Database.AllowsCallouts, Database.Stateful {
public Integer recordsProcessed = 0;
    public Id contractId;
    
    public UpdateTotalAmountRemainingBatch(Id recordId){
        this.contractId = recordId;
    }
    public UpdateTotalAmountRemainingBatch(){
        this.contractId = null;
    }
    public List<DContract__c> start(Database.BatchableContext context) {
        String baseQuery = 'SELECT Id ,ID_Support_Services_Contract__c,ID_Sub_contract_Total_Amount_Remaining__c,Total_Amount_REMAINING__c '+
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

            if(contractObj.ID_Support_Services_Contract__c == true){
                contractObj.Total_Amount_REMAINING__c = contractObj.ID_Sub_contract_Total_Amount_Remaining__c != null ? (-1) * contractObj.ID_Sub_contract_Total_Amount_Remaining__c : 0;
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
        StatusLoggerUtils.logInfo(StatusLoggerUtils.CONTRACT_ALL_TIME_INCOME_LOGGER, 'Update Total Amount REMAINING Script', this.recordsProcessed,
                                  'Finished Update Total Amount REMAINING with date : ' + Date.today());
        StatusLoggerUtils.sendLog(StatusLoggerUtils.CONTRACT_ALL_TIME_INCOME_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        
    }
}