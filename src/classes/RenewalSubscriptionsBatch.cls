/**
 * RenewalSubscriptionsBatch creates new Opps and Fogbugz cases for ending Domain Subscriptions.
 */
public without sharing class RenewalSubscriptionsBatch implements Database.Batchable<Accounting_Subscription__c>, Database.AllowsCallouts, Database.Stateful {

    private Date currentDate;
    private Business_Unit__c incBusinessUnit;
    private User defaultOppOwner;
    private Subscription_Renewal_Settings__c settings;
    private List<DatabaseErrorInfo> oppsErrors;
    private List<DatabaseErrorInfo> subsErrors;

    public RenewalSubscriptionsBatch () {
        this.currentDate = Date.today();
    }

    public RenewalSubscriptionsBatch (Date currentDate) {
        this.currentDate = currentDate;
    }

    public List<Accounting_Subscription__c> start(Database.BatchableContext context) {
        List<Accounting_Subscription__c> subscriptions = [SELECT Id, Accounting_subscriber_domain__r.Name FROM Accounting_Subscription__c
                                                          WHERE Accounting_subscriber_domain__r.Name != '' AND date_start__c >: this.currentDate
                                                          AND date_end__c != null];

        this.settings = Subscription_Renewal_Settings__c.getOrgDefaults();

        this.incBusinessUnit = [SELECT Id FROM Business_Unit__c WHERE Name =: settings.Default_Business_Unit__c];
        this.defaultOppOwner = [SELECT Id FROM User WHERE Name =: settings.Default_Opportunity_Owner__c];

        if (this.incBusinessUnit == null || this.defaultOppOwner == null) {
            EmailHelper.sendEmail(settings.Error_Emails__c.split(','), 'Subscription Renewal ERROR',
                                  'Cannot find default Opportunity owner or INC business unit');
            throw new NoDataFoundException('Cannot find default Opportunity owner or INC business unit');
        }

        Set<String> domainsWithFutureSubscriptions = new Set<String>();
        for (Accounting_Subscription__c sb : subscriptions) {
            if (!domainsWithFutureSubscriptions.contains(sb.Accounting_subscriber_domain__r.Name)) {
                domainsWithFutureSubscriptions.add(sb.Accounting_subscriber_domain__r.Name);
            }
        }

        this.oppsErrors = new List<DatabaseErrorInfo>();
        this.subsErrors = new List<DatabaseErrorInfo>();

        return [SELECT Id, date_end__c, service_type__c, Accounting_subscriber_domain__c, Accounting_subscriber_domain__r.Name, Dimagi_Contact__c,
                Accounting_subscriber_domain__r.cpAllWebUsers__c, Software_Plan_Edition__c, Renewal_Opportunity_created__c FROM Accounting_Subscription__c
                WHERE Accounting_subscriber_domain__r.Name != '' AND date_start__c <=: currentDate
                AND date_end__c != null AND date_end__c <=: this.currentDate.addDays(60) AND Renewal_Opportunity_created__c = false
                AND Accounting_subscriber_domain__r.Name NOT IN: domainsWithFutureSubscriptions
                ORDER BY Accounting_subscriber_domain__r.Name];
    }

    public void execute(Database.BatchableContext context, List<Accounting_Subscription__c> subs) {
        // NEW FIELDS : SUBSCRIPTION Renewal_Opportunity_created__c, Dimagi_Contact__c OPP :  Subscriptions_web_users__c, Prior Dimagi contact__c
        List<Opportunity> newOpps = new List<Opportunity>();

        for (Accounting_Subscription__c subscription : subs) {
            Opportunity newOpp = new Opportunity(
                                                    Prior_Dimagi_contact__c = subscription.Dimagi_Contact__c,
                                                    Name = subscription.Software_Plan_Edition__c + ' - Renewal', // TODO account name ?????
                                                    Subscriptions_web_users = Accounting_subscriber_domain__r.cpAllWebUsers__c,
                                                    Probability = 0.25,
                                                    Duration_months__c = 12,
                                                    Expected_Buffer__c = 1,
                                                    of_Execution_budget_for_GS__c = 0,
                                                    CloseDate = subscription.date_end__c,
                                                    Domain_Name__c = subscription.Accounting_subscriber_domain__c,
                                                    Product_Text__c = subscription.Software_Plan_Edition__c,
                                                    Stage = 'Stage 3 - Prospect',
                                                    Owner = this.defaultOppOwner,
                                                    Implementation_Type__c = 'Self Service',
                                                    Opportunity_Owning_Entity__c = this.incBusinessUnit,
                                                    Contract_Owner_BU__c = this.incBusinessUnit,
                                                    Implementing_Business_Unit__c = this.incBusinessUnit
                                                );

            if (subscription.service_type__c == 'Implementation' || subscription.service_type__c == 'Product') {
                newOpp.Opportunity_Source__c = 'Implementation Renewal';
            } else {
                newOpp.Opportunity_Source__c = 'Product Renewal';
            }
            subscription.Renewal_Opportunity_created__c = true;
        }

        // Create new Opps
        if (newOpps.size() > 0) {
            List<Database.SaveResult> insertResults = Database.insert(newOpps, false);
            for(Integer i = 0; i < insertResults.size(); i++){
                if (!insertResults.get(i).isSuccess()){
                    Database.Error error = insertResults.get(i).getErrors().get(0);
                    this.oppsError.add(new DatabaseErrorInfo(insertList.get(i).Domain_Name__c, error.getMessage()));
                }
            }
        }

        // Update subscriptions
        List<Database.SaveResult> updateResults = Database.update(subs, false);
        for(Integer i = 0; i < updateResults.size(); i++){
            if (!updateResults.get(i).isSuccess()){
                Database.Error error = updateResults.get(i).getErrors().get(0);
                this.subsErrors.add(new DatabaseErrorInfo(updateResults.get(i).Id, error.getMessage()));
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        String emailBody = 'RenewalSubscriptionsBatch : ' + Date.today() + '</br></br>OPP Errors : </br>';
        Boolean tableStart = false;

        if (oppsErrors.size() > 0) {
            emailBody += '<table border="1"><tr><td>Domain Id</td><td>Error Message</td></tr>';
            for (DatabaseErrorInfo er : this.oppsErrors) {
                emailBody += '<tr><td>' + er.objectId + '</td><td>' + er.errorMessage + '</td></tr>';
            }
            emailBody += '</table></br></br>Subs Errors : </br>';
        }

        if (subsErrors.size() > 0) {
            emailBody += '<table border="1"><tr><td>Sub Id</td><td>Error Message</td></tr>';
            for (DatabaseErrorInfo er : this.subsErrors) {
                emailBody += '<tr><td>' + er.objectId + '</td><td>' + er.errorMessage + '</td></tr>';
            }
            emailBody += '</table>';
        }

        EmailHelper.sendEmail(settings.Error_Emails__c.split(','), 'Subscription Renewal Job Status', emailBody);
    }

    public class DatabaseErrorInfo {

        public DatabaseErrorInfo (String id, String message) {
            this.objectId = id;
            this.errorMessage = message;
        }

        public String objectId { get; set; }
        public String errorMessage { get; set; }

    }
}