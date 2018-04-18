/**
 * Updates Services Spend field value in Dimagi contracts.
 */
public class BatchUpdateContractServicesSpend implements Database.Batchable<DContract__c>, Database.Stateful {

    private Map<Id, Decimal> servicesSpendMap;
    private String mode;

    public BatchUpdateContractServicesSpend(Map<Id, Decimal> servicesSpendMap) {
        this(servicesSpendMap, 'replace');
    }

    public BatchUpdateContractServicesSpend(Map<Id, Decimal> servicesSpendMap, String mode) {
        this.servicesSpendMap = servicesSpendMap;
        this.mode = mode;
    }

    public List<DContract__c> start(Database.BatchableContext context) {
        List<DContract__c> childList = [SELECT Name, Parent_Contract__c FROM DContract__c WHERE Parent_Contract__c != ''
                                            AND Id IN: this.servicesSpendMap.keySet()];
        for (DContract__c chCont : childList) { // We must add missing parents
            if (!this.servicesSpendMap.containsKey(chCont.Parent_Contract__c)) {
                this.servicesSpendMap.put(chCont.Parent_Contract__c, 0);
            }
        }

        return [SELECT Name, Calculated_Services_Spend__c, Services_Spend__c FROM DContract__c WHERE Parent_Contract__c = '' AND Id IN: this.servicesSpendMap.keySet()];
    }

    public void execute(Database.BatchableContext context, List<DContract__c> contracts) {
        List<DContract__c> childContracts = [SELECT Name, Parent_Contract__c, Calculated_Services_Spend__c, Services_Spend__c FROM DContract__c WHERE Parent_Contract__c IN :contracts];
        List<DContract__c> contractsToUpdate = new List<DContract__c>();

        for (DContract__c contract : childContracts) {
            if (!this.servicesSpendMap.containsKey(contract.Id)) {
                continue;
            }

            Decimal contractValue = servicesSpendMap.get(contract.Id); // we move values also to parent contract
            if (this.servicesSpendMap.containsKey(contract.Parent_Contract__c)) {
                this.servicesSpendMap.put(contract.Parent_Contract__c, this.servicesSpendMap.get(contract.Parent_Contract__c) + contractValue);
            } else {
                this.servicesSpendMap.put(contract.Parent_Contract__c, contractValue);
            }
            contract.Calculated_Services_Spend__c = contractValue;
            contract.Services_Spend__c = contractValue.setScale(2);
            contractsToUpdate.add(contract);
        }

        for (DContract__c contract : contracts) {
            if (!servicesSpendMap.containsKey(contract.Id)) {
                continue;
            }

            Decimal contractValue = servicesSpendMap.get(contract.Id);
            contract.Calculated_Services_Spend__c = contractValue;
            contract.Services_Spend__c = contractValue.setScale(2);
            contractsToUpdate.add(contract);
        }

        Database.update(contractsToUpdate, false); // TODO Generate mailer with mode!!! 
    }

    public void finish(Database.BatchableContext context) {

    }
}