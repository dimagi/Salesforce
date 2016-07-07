/**
 * Updates Services Spend field value in Dimagi contracts.
 */
public class BatchUpdateContractServicesSpend implements Database.Batchable<DContract__c>, Database.Stateful {

    private Map<Id, Integer> servicesSpendMap;

    public BatchUpdateContractServicesSpend() {
        this.servicesSpendMap = new Map<Id, Integer>();
    }

    public BatchUpdateContractServicesSpend(Map<Id, Integer> servicesSpendMap) {
        this.servicesSpendMap = servicesSpendMap;
    }

    public List<DContract__c> start(Database.BatchableContext context) {
       return [SELECT Name, Services_Spend__c FROM DContract__c WHERE Parent_Contract__c = ''];
    }

    public void execute(Database.BatchableContext context, List<DContract__c> contracts) {
        List<DContract__c> childContracts = [SELECT Name, Parent_Contract__c, Services_Spend__c FROM DContract__c WHERE Parent_Contract__c IN :contracts];
        List<DContract__c> contractsToUpdate = new List<DContract__c>();

        for (DContract__c contract : childContracts) {
            if (!servicesSpendMap.containsKey(contract.Id)) {
                continue;
            }

            Integer contractValue = servicesSpendMap.get(contract.Id);
            if (servicesSpendMap.containsKey(contract.Parent_Contract__c)) {
                servicesSpendMap.put(contract.Parent_Contract__c, servicesSpendMap.get(contract.Parent_Contract__c) + contractValue);
            } else {
                servicesSpendMap.put(contract.Parent_Contract__c, contractValue);
            }

            if (contract.Services_Spend__c != contractValue) {
                contract.Services_Spend__c = contractValue;
                contractsToUpdate.add(contract);
            }
        }

        for (DContract__c contract : contracts) {
            if (!servicesSpendMap.containsKey(contract.Id)) {
                continue;
            }

            Integer contractValue = servicesSpendMap.get(contract.Id);
            if (contract.Services_Spend__c != contractValue) {
                contract.Services_Spend__c = contractValue;
                contractsToUpdate.add(contract);
            }
        }

        update contractsToUpdate;
    }

    public void finish(Database.BatchableContext context) {

    }
}