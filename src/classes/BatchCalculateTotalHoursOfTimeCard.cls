global class BatchCalculateTotalHoursOfTimeCard implements Database.Batchable<sObject>{

    global final string query;
    global string contractId;

    global BatchCalculateTotalHoursOfTimeCard(){
        query = 'SELECT Name, Services_Spend__c FROM DContract__c WHERE Parent_Contract__c = \'\'';
    }

    global BatchCalculateTotalHoursOfTimeCard(String contrctId){
        contractId = contrctId;
        query = 'SELECT Name, Services_Spend__c FROM DContract__c Where Id = :contractId ';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<DContract__c> contractsToUpdate = new List<DContract__c>();
        Map<Id, Decimal> resultsBycontractId = new Map<Id, Decimal>();
        Map<Id, DContract__c> contractIdContractMap = new Map<Id, DContract__c>();

        for (sObject s : scope) {
            DContract__c obj = (DContract__c) s;
            Decimal parentTotal = calculateTotal(obj.Id);
            resultsBycontractId.put(obj.Id, parentTotal);
            contractIdContractMap.put(obj.Id, obj);
        }

        List<DContract__c> childContracts = [SELECT Name, Parent_Contract__c, Services_Spend__c FROM DContract__c WHERE Parent_Contract__c IN :contractIdContractMap.keySet()];
        for (DContract__c dc : childContracts) {
            Decimal total = calculateTotal(dc.Id);
            resultsBycontractId.put(dc.Id, total);
            contractIdContractMap.put(dc.Id, dc);

            if (resultsBycontractId.containsKey(dc.Parent_Contract__c)) {
                resultsBycontractId.put(dc.Parent_Contract__c, resultsBycontractId.get(dc.Parent_Contract__c) + total);
            }
        }

        for (DContract__c contract : contractIdContractMap.values()) {
            Integer total = 0;

            if (resultsBycontractId.containsKey(contract.Id)) {
                total = resultsBycontractId.get(contract.Id).intValue();
            }

            if (contract.Services_Spend__c != total) {
                contract.Services_Spend__c = total;
                contractsToUpdate.add(contract);
            }
        }

        System.debug('contractsToUpdate: ' + contractsToUpdate);

        try{
            if(contractsToUpdate.isEmpty() == false) {
                Database.SaveResult[] saveResults = Database.update(contractsToUpdate, false);
                System.debug(saveResults);
            }
        }catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error occured.' + e.getMessage() + ' - ' +  e.getLineNumber());
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug(LoggingLevel.WARN,'Batch Job Complete');
    }

    private Integer calculateTotal(Id contractId) {
        Decimal total = 0;
        for (Time_Card__c ch : [SELECT labor_cost__c FROM Time_Card__c WHERE Client__c =: contractId]) {
            if (ch.labor_cost__c != null) {
                total += ch.labor_cost__c;
            }
        }

        return total.intValue();
    }
}