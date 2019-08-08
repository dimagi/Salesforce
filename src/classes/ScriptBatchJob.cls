/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private Date helperDate;
    private Date dateThreshold = Date.newInstance(2017, 12, 1);

    public ScriptBatchJob() {
        this.helperDate = Date.today();
    }

    public ScriptBatchJob(Date helperDate) {
        this.helperDate = helperDate;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id, Client__c, Client__r.Project_Billing_Rate__c, Employee__c, '
                                      + 'Time_Card_Salary__c, Billing_Rate__c, Date__c '
                                      + 'FROM Time_Card__c WHERE Date__c >=: dateThreshold ORDER BY Employee__c, Date__c');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Time_Card__c> toUpdate = new List<Time_Card__c>();
        List<Time_Card__c> timeCards = new List<Time_Card__c>();

        for (SObject objRec : scope) {
            timeCards.add((Time_Card__c) objRec);
        }

        TimeCardCalculatorHelper calculatorHelper = new TimeCardCalculatorHelper();
        calculatorHelper.loadEmployeesSalary(timeCards);

        for (Time_Card__c timeCard : timeCards) {

            if (timeCard.Date__c >= this.dateThreshold && calculatorHelper.wasContractor(timeCard.Employee__c, timeCard) == true) {
                timeCard.Billing_Rate__c = calculatorHelper.getBillingRate(TimeCardTriggerController.CONTRACTOR_RATE_NAME, timeCard.Date__c);
                timeCard.Uses_Contractor_Billing_Rate__c = true;
            } else {
                timeCard.Uses_Contractor_Billing_Rate__c = false;
            }
            toUpdate.add(timeCard);

        }

        if (toUpdate.size() > 0) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}