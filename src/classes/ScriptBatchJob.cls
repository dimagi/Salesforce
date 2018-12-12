/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;
    private Id parentContract;
    private Set<Id> contracts;

    public ScriptBatchJob() {
        this.helperDate = Date.today();
    }

    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
        
    }

    public ScriptBatchJob(Date helperDate, Id parentContract) {
        this.helperDate = helperDate;
        this.parentContract = parentContract;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Software_Plan_Version__c, Softwareplan_Edition__c, Accounting_Customer_PlanVersion__c FROM Accounting_Invoice__c WHERE Invoice_Type__c = \'Customer\'');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Accounting_Invoice__c> customerInvoicesToUpda = new List<Accounting_Invoice__c>();
        for (SObject otc : scope) {
            Accounting_Invoice__c customerInv = (Accounting_Invoice__c) otc;
            if (String.isNotBlank(customerInv.Software_Plan_Version__c)) {
                List<String> versionIds = customerInv.Software_Plan_Version__c.split(',');
                String planName = '';
                Decimal highestMonthlyFee = -1;
                Id highestPlanId = null;

                for (Accounting_SoftwarePlanVersion__c spv : [SELECT Id,  id__c, Accounting_SoftwarePlan__r.edition__c,
                                                                     Software_Product_Rate__r.monthly_fee__c FROM Accounting_SoftwarePlanVersion__c]) {
                    Decimal tmpMonthlyFee = spv.Software_Product_Rate__r.monthly_fee__c != null ? spv.Software_Product_Rate__r.monthly_fee__c : 0;
                    if (tmpMonthlyFee > highestMonthlyFee) {
                        highestMonthlyFee = tmpMonthlyFee;
                        planName = spv.Accounting_SoftwarePlan__r.edition__c != null ? spv.Accounting_SoftwarePlan__r.edition__c : '';
                        highestPlanId = spv.Id;
                    }
                }

                if (highestPlanId != null) {
                    customerInv.Softwareplan_Edition__c = planName;
                    customerInv.Accounting_Customer_PlanVersion__c = highestPlanId;
                    customerInvoicesToUpda.add(customerInv);
                }
            }
        }

        if (customerInvoicesToUpda.size() > 0) {
            update customerInvoicesToUpda;
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}