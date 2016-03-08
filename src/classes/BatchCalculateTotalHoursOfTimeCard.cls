global class BatchCalculateTotalHoursOfTimeCard implements Database.Batchable<sObject>{

    global final string query;
    global string contractId;

    global BatchCalculateTotalHoursOfTimeCard(){
        query = 'SELECT Name,Services_Spend__c, (select client__c,labor_cost__c from Time_Cards__r) FROM DContract__c';
    }
    
    global BatchCalculateTotalHoursOfTimeCard(String contrctId){
        contractId = contrctId;
        query = 'SELECT Name,Services_Spend__c, (select client__c,labor_cost__c from Time_Cards__r) FROM DContract__c Where Id = :contractId ';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC,List<sObject> scope){
        List<DContract__c> contractsToUpdate = new List<DContract__c>();
        Map<Id, Decimal> resultsBycontractId = new Map<Id, Decimal>();

        Map<Id,DContract__c> contractIdContractMap = new Map<Id,DContract__c>();
        List<Time_Card__c> timeCardList = new List<Time_Card__c>();
        System.debug('1');
        for (sObject s : scope) {
            DContract__c obj = (DContract__c) s;
                for (Time_Card__c ch : obj.Time_Cards__r) {
                    timeCardList.add(ch);
                }
                contractIdContractMap.put(obj.id,obj);
        }
        System.debug('2');

        for(Time_Card__c timeCard : timeCardList) {
            if(resultsBycontractId.containsKey(timeCard.Client__c)) {
                Decimal laborCost = resultsBycontractId.get(timeCard.Client__c);
                laborCost += timeCard.labor_cost__c != null ? timeCard.labor_cost__c : 0;
                resultsBycontractId.put(timeCard.Client__c, laborCost);
            }else {
                resultsBycontractId.put(timeCard.Client__c,  timeCard.labor_cost__c != null ? timeCard.labor_cost__c : 0);
            }
        }


        for (DContract__c contract : contractIdContractMap.values()) {
            Integer total = 0;

            if (resultsBycontractId.containsKey(contract.Id)) {
                total = Integer.valueOf(resultsBycontractId.get(contract.Id));
            }

            if (contract.Services_Spend__c != total) {
                contract.Services_Spend__c = total;
                contractsToUpdate.add(contract);
            }
        }

        system.debug('contractsToUpdate: '+contractsToUpdate);
        try{
            if(contractsToUpdate.isEmpty() == false) {
                Database.SaveResult[] saveResults = Database.update(contractsToUpdate, false);
                System.debug(saveResults);
            }
        }catch (Exception e) {
            System.debug(LoggingLevel.WARN,'Error occured.'+ e.getMessage()+' - '+ e.getLineNumber() );
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug(LoggingLevel.WARN,'Batch Job Complete');
    }
}