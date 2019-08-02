/**
 * RenewalSubscriptionsBatch creates new Opps and Fogbugz cases for ending Domain Subscriptions.
 */
public without sharing class RenewalSubscriptionsBatch implements Database.Batchable<Accounting_Subscription__c>, Database.AllowsCallouts, Database.Stateful {

    private static final String IMPL_RENEWAL = 'Implementation Renewal';
    private static final String PROD_RENEWAL = 'Product Renewal';

    private Integer recordCounter;
    private Date currentDate;
    private Business_Unit__c incBusinessUnit;
    private User defaultOppOwnerImplementation;
    private User defaultOppOwnerProduct;
    private Subscription_Renewal_Settings__c settings;

    private Map<String, PricebookEntry> priceBookEntries;
    private PricebookEntry commCareEntry;
    private Map<String, Decimal> salesPrices;
    private Set<Id> domainsToSkip;

    public RenewalSubscriptionsBatch () {
        this(Date.today());
    }

    public RenewalSubscriptionsBatch (Date currentDate) {
        this.currentDate = currentDate;
        this.recordCounter = 0;
    }

    public List<Accounting_Subscription__c> start(Database.BatchableContext context) {
        List<Accounting_Subscription__c> subscriptions = getFutureSubscriptions();
        this.settings = Subscription_Renewal_Settings__c.getOrgDefaults();

        this.incBusinessUnit = [SELECT Id FROM Business_Unit__c WHERE Name =: settings.Default_Business_Unit__c];
        this.defaultOppOwnerImplementation = [SELECT Id FROM User WHERE Name =: settings.Default_Opportunity_Owner_Impl__c];
        this.defaultOppOwnerProduct = [SELECT Id FROM User WHERE Name =: settings.Default_Opportunity_Owner_Prod__c];

        if (this.incBusinessUnit == null || this.defaultOppOwnerImplementation == null || this.defaultOppOwnerProduct == null) {
            EmailHelper.sendEmail(settings.Error_Emails__c.split(','), 'Subscription Renewal ERROR',
                                  'Cannot find default Opportunity owner or Inc business unit');
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Cannot find default Opportunity owner or INC business unit');
            throw ex;
        }

        Set<String> domainsWithFutureSubscriptions = new Set<String>();
        for (Accounting_Subscription__c sb : subscriptions) {
            if (!domainsWithFutureSubscriptions.contains(sb.Accounting_subscriber_domain__r.Name)) {
                domainsWithFutureSubscriptions.add(sb.Accounting_subscriber_domain__r.Name);
            }
        }

        this.domainsToSkip = new Set<Id>();
        this.priceBookEntries = new Map<String, PricebookEntry>();

        Set<String> productCodes = new Set<String> { 'Reseller', 'Managed Hosting', 'Advanced', 'Community', 'Enterprise', 'Pro', 'Standard' };
        PriceBook2 dimagiPriceBook = [SELECT Id FROM PriceBook2 WHERE Name = 'Dimagi'];
        List<PricebookEntry> entries = [SELECT Id, ProductCode, UnitPrice FROM PricebookEntry WHERE ProductCode IN: ProductCodes AND Pricebook2Id =: dimagiPriceBook.Id];

        for (PricebookEntry entry : entries) {
            this.priceBookEntries.put(entry.ProductCode, entry);
        }

        this.commCareEntry = [SELECT Id, ProductCode, UnitPrice FROM PricebookEntry WHERE ProductCode = 'CommCare' AND Pricebook2Id =: dimagiPriceBook.Id LIMIT 1];

        if (entries.size() != 7 || this.commCareEntry == null) {
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Cannot find price book entries');
            throw ex;
        }

        this.salesPrices = new Map<String, Decimal>();
        this.salesPrices.put('Community', this.settings.Community__c != null ? this.settings.Community__c : 0);
        this.salesPrices.put('Standard', this.settings.Standard__c != null ? this.settings.Standard__c : 300);
        this.salesPrices.put('Pro', this.settings.Pro__c != null ? this.settings.Pro__c : 500);
        this.salesPrices.put('Advanced', this.settings.Advanced__c != null ? this.settings.Advanced__c : 1000);
        this.salesPrices.put('Enterprise', this.settings.Enterprise__c != null ? this.settings.Enterprise__c : 2000);
        this.salesPrices.put('Managed Hosting', this.settings.Managed_Hosting__c != null ? this.settings.Managed_Hosting__c : 2000);
        this.salesPrices.put('Reseller', this.settings.Reseller__c != null ? this.settings.Reseller__c : 500);

        return getSubscriptionsForRenewal(domainsWithFutureSubscriptions);
    }

    public void execute(Database.BatchableContext context, List<Accounting_Subscription__c> subs) {
        Set<Id> domainsSet = new Set<Id>();
        for (Accounting_Subscription__c subscription : subs) {
            domainsSet.add(subscription.Accounting_subscriber_domain__c);
        }

        Map<Id, Domain__c> domains = new Map<Id, Domain__c> ([SELECT Id, Name, Opportunity__c FROM Domain__c WHERE Id IN: domainsSet]);
        List<Domain__c> domainsToUpdate = new List<Domain__c>();

        String dateString = (this.currentDate.month() < 10 ? '0' + this.currentDate.month() : '' + this.currentDate.month())
                                + (this.currentDate.day() < 10 ? '0' + this.currentDate.day() : '' + this.currentDate.day())
                                + ('' + this.currentDate.year());

        for (Accounting_Subscription__c subscription : subs) {
            if (subscription.Accounting_subscriber_domain__r.Opportunity__c != null &&
                 (subscription.Accounting_subscriber_domain__r.Opportunity__r.IsClosed == false || 
                   (subscription.Accounting_subscriber_domain__r.Opportunity__r.IsClosed == true && subscription.Accounting_subscriber_domain__r.Opportunity__r.CloseDate >= this.currentDate))) {
                this.domainsToSkip.add(subscription.Accounting_subscriber_domain__c);
            }
            if (!this.domainsToSkip.contains(subscription.Accounting_subscriber_domain__c)) {
                String oppSource = '';
                if (subscription.service_type__c == 'IMPLEMENTATION') {
                    oppSource = IMPL_RENEWAL;
                } else if (subscription.service_type__c == 'PRODUCT' || subscription.service_type__c == 'TRIAL' || subscription.service_type__c == 'NOT_SET') {
                    oppSource = PROD_RENEWAL;
                } else {
                    continue; // we skip this subscription
                }

                String oppNameFirstPart = subscription.Accounting_subscriber_domain__r.Account__r.Name != null && subscription.Accounting_subscriber_domain__r.Account__r.Name != '' ?
                                            subscription.Accounting_subscriber_domain__r.Account__r.Name : subscription.Accounting_subscriber_domain__r.Name;

                String oppNamesecondPart = '-' + subscription.Software_Plan_Edition__c + (subscription.service_type__c == 'IMPLEMENTATION' ? '-Implementation' : '') + ' Renewal ' + dateString;

                if (oppNameFirstPart.length() + oppNamesecondPart.length() > 120) {
                    oppNameFirstPart = oppNameFirstPart.subString(0, 120 - oppNamesecondPart.length());
                }

                Opportunity newOpp = new Opportunity(
                                                        Prior_Dimagi_contact__c = subscription.Dimagi_Contact__c,
                                                        Name = oppNameFirstPart + oppNamesecondPart,
                                                        Subscriptions_web_users__c = subscription.Accounting_subscriber_domain__r.cpAllWebUsers__c,
                                                        Fogbugz_Probability__c = 30,
                                                        Probability = 30,
                                                        Duration_months__c = 12,
                                                        Expected_Buffer__c = 100,
                                                        of_Execution_budget_for_GS__c = 0,
                                                        CloseDate = subscription.date_end__c,
                                                        Domain_Name__c = subscription.Accounting_subscriber_domain__c,
                                                        StageName = 'Stage 3 - Prospect',
                                                        OwnerId = (oppSource == IMPL_RENEWAL ? this.defaultOppOwnerImplementation.Id : this.defaultOppOwnerProduct.Id),
                                                        Implementation_Type__c = 'Self Service',
                                                        Channel_Response__c = 'Inside Sales',
                                                        Opportunity_Owning_Entity__c = this.incBusinessUnit.Id,
                                                        Contract_Owner_BU__c = this.incBusinessUnit.Id,
                                                        Implementing_Business_Unit__c = this.incBusinessUnit.Id,
                                                        Opportunity_Source__c = oppSource
                                                    );

                PricebookEntry pbe = this.priceBookEntries.get(subscription.Software_Plan_Edition__c);
                Decimal price = this.salesPrices.get(subscription.Software_Plan_Edition__c);
                Domain__c domainToUpdate = domains.get(subscription.Accounting_subscriber_domain__c);

                Savepoint sp = Database.setSavepoint();
                try {
                    insert newOpp;
                    domainToUpdate.Opportunity__c = newOpp.Id;
                    update domainToUpdate;
                    insert new OpportunityLineItem(PricebookEntryId = pbe.Id, Quantity = 12, UnitPrice = price, OpportunityId = newOpp.Id);
                    insert new OpportunityLineItem(PricebookEntryId = commCareEntry.Id, Quantity = 1, UnitPrice = commCareEntry.UnitPrice, OpportunityId = newOpp.Id);
                    this.recordCounter++;
                } catch (DMLException e) {
                    StatusLoggerUtils.logError(StatusLoggerUtils.RENEWAL_LOGGER, domainToUpdate.Name + ' - ' + subscription.Name, 0, e.getMessage());
                    Database.rollback(sp);
                }
            }

            // we must create Opp only for the latest subscription which will end
            if (!this.domainsToSkip.contains(subscription.Accounting_subscriber_domain__c)) {
                this.domainsToSkip.add(subscription.Accounting_subscriber_domain__c);
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        StatusLoggerUtils.logInfo(StatusLoggerUtils.RENEWAL_LOGGER, 'Renewal Script', this.recordCounter,
                                                    'Finished Renewal Job with date : ' + this.currentDate);
        if (Test.isRunningTest()) {
            return;
        }
        Database.executeBatch(new CreateFBCasesBatch(), 5);
        StatusLoggerUtils.sendLog(StatusLoggerUtils.RENEWAL_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
    }

    /**
     * Returns Subscriptions which ends after 60 days
     */
    public List<Accounting_Subscription__c> getFutureSubscriptions() {
        return [SELECT Id, date_start__c, date_end__c, Accounting_subscriber_domain__r.Name FROM Accounting_Subscription__c
                WHERE Accounting_subscriber_domain__r.Name != '' AND is_trial__c = false AND is_hidden_to_ops__c = false
                AND date_start__c >: this.currentDate
                AND Server_Name__c = 'CommCareHQ'];
    }

    /**
     * Returns Subscriptions which ends in 60 days for domains which dosen't contain subscriptions from future (which ends after 60 days).
     */
    public List<Accounting_Subscription__c> getSubscriptionsForRenewal(Set<String> domainsWithFutureSubscriptions) {
        return [SELECT Id, Name, date_start__c, date_end__c, service_type__c, Accounting_subscriber_domain__c, Accounting_subscriber_domain__r.Name, Dimagi_Contact__c, Accounting_subscriber_domain__r.Account__r.Name,
                Accounting_subscriber_domain__r.cpAllWebUsers__c, Software_Plan_Edition__c,
                Accounting_subscriber_domain__r.Opportunity__r.CreatedDate, Accounting_subscriber_domain__r.Opportunity__c,
                Accounting_subscriber_domain__r.Opportunity__r.CloseDate, Accounting_subscriber_domain__r.Opportunity__r.IsClosed
                FROM Accounting_Subscription__c
                WHERE Accounting_subscriber_domain__r.Name != '' AND date_end__c != null AND date_end__c <=: this.currentDate.addDays(60)
                AND date_end__c >=: this.currentDate AND Accounting_subscriber_domain__r.Name NOT IN: domainsWithFutureSubscriptions AND is_active__c = true
                AND is_hidden_to_ops__c = false AND is_trial__c = false AND Server_Name__c = 'CommCareHQ' ORDER BY date_end__c DESC];
    }
}