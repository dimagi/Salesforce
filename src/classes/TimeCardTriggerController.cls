public class TimeCardTriggerController {


    public void rollUpTimeCardsTotalSpent(List<Time_Card__c> timeCardList){

        Set<Id> contractIds = new Set<Id>();
    
        for (Time_Card__c obj : timeCardList) {
            if(obj.Client__c != null) {
                contractIds.add(obj.Client__c);
            }
        }
    
        if (contractIds.isEmpty() == false) {
            this.summarizeTimeCardEntries(contractIds);
        }
    }
    
    public void summarizeTimeCardEntries(Set<Id> contractIds) {  
        //List<DContract__c> contracts = loadContracts(contractIds);
    
        //Map<Id, Integer> results = loadTimeCardsTotalAmountByContractIds(contractIds);
        TimeCardTriggerController.loadTimeCardsTotalAmountByContractIds(contractIds);
    
        /*List<DContract__c> contractsToUpdate = new List<DContract__c>();
        for (DContract__c contract : contracts) {
            Integer total = 0;
    
            if (results.containsKey(contract.Id)) {
                total = results.get(contract.Id);
            }
    
            if (contract.Total_Labor_Expenses__c != total) {
                contract.Total_Labor_Expenses__c = total;
                contractsToUpdate.add(contract);
            }
        }
    
        if(contractsToUpdate.isEmpty() == false) {
            Database.SaveResult[] saveResults = Database.update(contractsToUpdate, false);
            System.debug(saveResults);
        }*/
    }

    
    private static List<DContract__c> loadContracts(Set<Id> contractIds) {
        return [SELECT 
                Id 
                ,Services_Spend__c
            FROM 
                DContract__c 
            WHERE 
                Id IN :contractIds];
    }
    
    @future
    public static void loadTimeCardsTotalAmountByContractIds(Set<Id> contractIds) {
    
    
        List<DContract__c> contracts = TimeCardTriggerController.loadContracts(contractIds);
    
        Map<Id, Integer> resultsBycontractId = new Map<Id, Integer>();

        AggregateResult[] results = [Select Client__c, SUM(labor_cost__c) Total from Time_Card__c where Client__c IN : contractIds Group By Client__c];
        for (AggregateResult result : results) {
            Id contractId = (Id) result.get('Client__c');
            Integer total = Integer.valueOf((decimal) result.get('Total'));

            resultsBycontractId.put(contractId, total);
        }
        
        List<DContract__c> contractsToUpdate = new List<DContract__c>();
        for (DContract__c contract : contracts) {
            Integer total = 0;
    
            if (resultsBycontractId.containsKey(contract.Id)) {
                total = resultsBycontractId.get(contract.Id);
            }
    
            if (contract.Services_Spend__c != total) {
                contract.Services_Spend__c = total;
                contractsToUpdate.add(contract);
            }
        }
    
        if(contractsToUpdate.isEmpty() == false) {
            Database.SaveResult[] saveResults = Database.update(contractsToUpdate, false);
            System.debug(saveResults);
        }
        
    }    
    
    
}