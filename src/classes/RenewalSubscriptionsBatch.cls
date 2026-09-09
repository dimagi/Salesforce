/**
 * RenewalSubscriptionsBatch creates new Opps for ending Domain Subscriptions.
 */
public without sharing class RenewalSubscriptionsBatch implements Database.Batchable<Accounting_Subscription__c>, Database.AllowsCallouts, Database.Stateful {

    private static final String IMPL_RENEWAL = 'Implementation Renewal';
    private static final String PROD_RENEWAL = 'Product Renewal';

    private Integer recordCounter;
    private Date currentDate;
    private Business_Unit__c incBusinessUnit;
    private User implementationNonEnterpriseOwner;
    private User implementationEnterpriseOwner;
    private User productNonEnterpriseOwner;
    private User productEnterpriseOwner;
    private Subscription_Renewal_Settings__c settings;

    private Map<String, PricebookEntry> priceBookEntries;
    private PricebookEntry commCareEntry;
    // Batch Apex hands execute() one chunk (scope) at a time - RenewalSubscriptionsScheduler
    // uses a scope of 10 - and does not guarantee chunks run in query order. A grouped
    // billing account can easily have more than 10 domains (see analysis), so grouping
    // can't happen per-chunk: every eligible subscription is accumulated here across all
    // execute() calls, and grouped/processed once in finish(), after the whole dataset is in.
    private List<Accounting_Subscription__c> collectedSubscriptions;

    public RenewalSubscriptionsBatch () {
        this(Date.today());
    }

    public RenewalSubscriptionsBatch (Date currentDate) {
        this.currentDate = currentDate;
        this.recordCounter = 0;
    }

    public List<Accounting_Subscription__c> start(Database.BatchableContext context) {
        this.collectedSubscriptions = new List<Accounting_Subscription__c>();
        List<Accounting_Subscription__c> subscriptions = getFutureSubscriptions();
        this.settings = Subscription_Renewal_Settings__c.getOrgDefaults();

        this.incBusinessUnit = [SELECT Id FROM Business_Unit__c WHERE Name =: settings.Default_Business_Unit__c];
		system.debug('==' + this.incBusinessUnit);
        this.implementationNonEnterpriseOwner = [SELECT Id FROM User WHERE Name =: settings.Implementation_non_Enterprise_Owner__c];
        this.implementationEnterpriseOwner = [SELECT Id FROM User WHERE Name =: settings.Implementation_Enterprise_Owner__c];
        this.productNonEnterpriseOwner = [SELECT Id FROM User WHERE Name =: settings.Product_non_Enterprise_Owner__c];
        this.productEnterpriseOwner = [SELECT Id FROM User WHERE Name =: settings.Product_Enterprise_Owner__c];

        if (this.incBusinessUnit == null || this.implementationNonEnterpriseOwner == null || this.implementationEnterpriseOwner == null
                || this.productNonEnterpriseOwner == null || this.productEnterpriseOwner == null) {
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

        return getSubscriptionsForRenewal(domainsWithFutureSubscriptions);
    }

    public void execute(Database.BatchableContext context, List<Accounting_Subscription__c> subs) {
        // Just accumulate - grouping by billing account has to see the whole dataset at
        // once (see the comment on collectedSubscriptions), so the real work happens in
        // finish(), once every chunk has been through execute().
        this.collectedSubscriptions.addAll(subs);
    }

    private void processCollectedSubscriptions() {
        Set<Id> domainsSet = new Set<Id>();
        for (Accounting_Subscription__c subscription : this.collectedSubscriptions) {
            domainsSet.add(subscription.Accounting_subscriber_domain__c);
        }

        Map<Id, Domain__c> domains = new Map<Id, Domain__c> ([SELECT Id, Name, Opportunity__c FROM Domain__c WHERE Id IN: domainsSet]);

        String dateString = (this.currentDate.month() < 10 ? '0' + this.currentDate.month() : '' + this.currentDate.month())
                                + (this.currentDate.day() < 10 ? '0' + this.currentDate.day() : '' + this.currentDate.day())
                                + ('' + this.currentDate.year());

        // Pick at most one subscription per domain - the one ending furthest out - across
        // the FULL dataset. Comparing date_end__c directly (rather than relying on query
        // order) keeps this correct regardless of what order execute() chunks run in.
        Map<Id, Accounting_Subscription__c> chosenSubscriptionByDomain = new Map<Id, Accounting_Subscription__c>();
        for (Accounting_Subscription__c subscription : this.collectedSubscriptions) {
            Id domainId = subscription.Accounting_subscriber_domain__c;
            Accounting_Subscription__c current = chosenSubscriptionByDomain.get(domainId);
            if (current == null || subscription.date_end__c > current.date_end__c) {
                chosenSubscriptionByDomain.put(domainId, subscription);
            }
        }

        // Group those per-domain subscriptions by billing account (Accounting_BillingAccount__c),
        // so a grouped subscription with several project-space domains produces ONE renewal
        // Opportunity instead of one per domain. A subscription with no billing account
        // (Account__c null) falls back to being its own single-domain group.
        Map<Id, List<Accounting_Subscription__c>> subscriptionsByGroup = new Map<Id, List<Accounting_Subscription__c>>();
        for (Accounting_Subscription__c subscription : chosenSubscriptionByDomain.values()) {
            Id groupKey = subscription.Account__c != null ? subscription.Account__c : subscription.Accounting_subscriber_domain__c;
            if (!subscriptionsByGroup.containsKey(groupKey)) {
                subscriptionsByGroup.put(groupKey, new List<Accounting_Subscription__c>());
            }
            subscriptionsByGroup.get(groupKey).add(subscription);
        }

        for (List<Accounting_Subscription__c> groupSubs : subscriptionsByGroup.values()) {

            // If any domain in the group already has an open (or very recently closed) renewal
            // Opportunity, the group has already been handled - don't create another one.
            Boolean groupAlreadyHasOpp = false;
            for (Accounting_Subscription__c s : groupSubs) {
                if (s.Accounting_subscriber_domain__r.Opportunity__c != null &&
                     (s.Accounting_subscriber_domain__r.Opportunity__r.IsClosed == false ||
                       (s.Accounting_subscriber_domain__r.Opportunity__r.IsClosed == true && s.Accounting_subscriber_domain__r.Opportunity__r.CloseDate >= this.currentDate))) {
                    groupAlreadyHasOpp = true;
                    break;
                }
            }
            if (groupAlreadyHasOpp) {
                continue;
            }

            // Represent the group with the subscription that's actually billed
            // (do_not_invoice__c = false) where one exists, otherwise the domain ending soonest.
            Accounting_Subscription__c subscription = pickRepresentativeSubscription(groupSubs);

            String oppSource = '';
            Id ownerId = null;
            if (subscription.service_type__c == 'IMPLEMENTATION' && subscription.Software_Plan_Edition__c != 'Enterprise') {
                oppSource = IMPL_RENEWAL;
                ownerId = this.implementationNonEnterpriseOwner.Id;
            } else if (subscription.service_type__c == 'IMPLEMENTATION' && subscription.Software_Plan_Edition__c == 'Enterprise') {
                oppSource = IMPL_RENEWAL;
                ownerId = this.implementationEnterpriseOwner.Id;
            } else if ((subscription.service_type__c == 'PRODUCT' || subscription.service_type__c == 'TRIAL' || subscription.service_type__c == 'NOT_SET')
                            && subscription.Software_Plan_Edition__c != 'Enterprise') {
                oppSource = PROD_RENEWAL;
                ownerId = this.productNonEnterpriseOwner.Id;
            } else if ((subscription.service_type__c == 'PRODUCT' || subscription.service_type__c == 'TRIAL' || subscription.service_type__c == 'NOT_SET')
                            && subscription.Software_Plan_Edition__c == 'Enterprise') {
                oppSource = PROD_RENEWAL;
                ownerId = this.productEnterpriseOwner.Id;
            } else {
                continue; // representative subscription's service type isn't renewable - skip this group
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
                                                    Probability = 30,
                                                    Duration_months__c = 12,
                                                    Expected_Buffer__c = 100,
                                                    of_Execution_budget_for_GS__c = 0,
                                                    CloseDate = subscription.date_end__c,
                                                    // Domain_Name__c is a single lookup and can only reference the
                                                    // representative domain - the full set of domains this
                                                    // Opportunity covers is on Domain__c.Opportunity__c below.
                                                    Domain_Name__c = subscription.Accounting_subscriber_domain__c,
                                                    StageName = 'Stage 3 - Prospect',
                                                    OwnerId = ownerId,
                                                    Implementation_Type__c = 'Self Service',
                                                    Channel_Response__c = 'Inside Sales',
                                                    Opportunity_Owning_Entity__c = this.incBusinessUnit.Id,
                                                    Contract_Owner_BU__c = this.incBusinessUnit.Id,
                                                    Implementing_Business_Unit__c = this.incBusinessUnit.Id,
                                                    Opportunity_Source__c = oppSource,
                                                    Opportunity_Owner_Division__c = 'CommCare',
                                                    Opportunity_Owner_Sub_Division__c = 'CommCare Sales',
                                                    AccountId = subscription.Accounting_subscriber_domain__r.Account__r.id
                                                );

            PricebookEntry pbe = this.priceBookEntries.get(subscription.Software_Plan_Edition__c);
            // SAL-515: price the renewal from the subscription's current monthly fee;
            // fall back to the Pricebook list price (no custom setting / hardcoded values).
            Decimal price = (subscription.accounting_software_monthly_fee__c != null && subscription.accounting_software_monthly_fee__c > 0)
                                ? subscription.accounting_software_monthly_fee__c
                                : (pbe != null ? pbe.UnitPrice : null);
            if (pbe == null || price == null) {
                System.debug(' Missing Pricebook entry or price for edition: ' + subscription.Software_Plan_Edition__c);
                StatusLoggerUtils.logError(
                    StatusLoggerUtils.RENEWAL_LOGGER,
                    subscription.Name,
                    0,
                    'Missing Pricebook entry or price for edition: ' + subscription.Software_Plan_Edition__c
                );
                continue; // skip this group safely
            }

            List<Domain__c> domainsToUpdate = new List<Domain__c>();
            for (Accounting_Subscription__c s : groupSubs) {
                Domain__c domainToUpdate = domains.get(s.Accounting_subscriber_domain__c);
                if (domainToUpdate != null) {
                    domainsToUpdate.add(domainToUpdate);
                }
            }

            Savepoint sp = Database.setSavepoint();
            try {
                insert newOpp;
                // Stamp every domain in the group, not just the representative's domain -
                // that's what makes next week's run skip the whole group.
                for (Domain__c domainToUpdate : domainsToUpdate) {
                    domainToUpdate.Opportunity__c = newOpp.Id;
                }
                update domainsToUpdate;

                insert new OpportunityLineItem(PricebookEntryId = pbe.Id, Quantity = 12, UnitPrice = price, OpportunityId = newOpp.Id);
                // SAL-48 removing commcare: product pricebook entry
                // insert new OpportunityLineItem(PricebookEntryId = commCareEntry.Id, Quantity = 1, UnitPrice = commCareEntry.UnitPrice, OpportunityId = newOpp.Id);
                this.recordCounter++;
            } catch (DMLException e) {
                Database.rollback(sp);
                StatusLoggerUtils.logError(StatusLoggerUtils.RENEWAL_LOGGER, subscription.Accounting_subscriber_domain__r.Name + ' - ' + subscription.Name, 0, e.getMessage());
            }
        }
    }

    /**
     * Picks the subscription to represent a grouped billing account's renewal Opportunity:
     * the one actually billed (do_not_invoice__c = false) if one exists in the group,
     * otherwise the domain ending soonest. Ties broken by earliest date_end__c.
     */
    private Accounting_Subscription__c pickRepresentativeSubscription(List<Accounting_Subscription__c> groupSubs) {
        Accounting_Subscription__c best = null;
        for (Accounting_Subscription__c s : groupSubs) {
            if (s.do_not_invoice__c == false && (best == null || s.date_end__c < best.date_end__c)) {
                best = s;
            }
        }
        if (best != null) {
            return best;
        }
        for (Accounting_Subscription__c s : groupSubs) {
            if (best == null || s.date_end__c < best.date_end__c) {
                best = s;
            }
        }
        return best;
    }

    public void finish(Database.BatchableContext context) {
        processCollectedSubscriptions();
        StatusLoggerUtils.logInfo(StatusLoggerUtils.RENEWAL_LOGGER, 'Renewal Script', this.recordCounter,
                                                    'Finished Renewal Job with date : ' + this.currentDate);
        if (Test.isRunningTest()) {
            return;
        }
        StatusLoggerUtils.sendLog(StatusLoggerUtils.RENEWAL_LOGGER, BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
    }
    

    /**
     * Returns Subscriptions which ends after 60 days
     */
    public List<Accounting_Subscription__c> getFutureSubscriptions() {
        List<String> service_type = new List<String>();

for (Accounting_Subscription_service_type__mdt record : [SELECT service_types__c FROM Accounting_Subscription_service_type__mdt]) {
    String serviceType = record.service_types__c;
    service_type.add(serviceType);
}
        return [SELECT Id, date_start__c, date_end__c, Accounting_subscriber_domain__r.Name FROM Accounting_Subscription__c
                WHERE service_type__c NOT IN :service_type AND Accounting_subscriber_domain__r.Name != '' AND is_trial__c = false AND is_hidden_to_ops__c = false
                AND date_start__c >: this.currentDate
                AND (Server_Name__c = 'CommCareHQ' OR Server_Name__c = 'CommCareHQ India' OR Server_Name__c = 'CommCareHQ EU')];
    }
    

    /**
     * Returns Subscriptions which ends in 60 days for domains which dosen't contain subscriptions from future (which ends after 60 days).
     */
    public List<Accounting_Subscription__c> getSubscriptionsForRenewal(Set<String> domainsWithFutureSubscriptions) {
        List<String> service_type = new List<String>();

for (Accounting_Subscription_service_type__mdt record : [SELECT service_types__c FROM Accounting_Subscription_service_type__mdt]) {
    String serviceType = record.service_types__c;
    service_type.add(serviceType);
}
        return [SELECT Id, Name, date_start__c, date_end__c, service_type__c, Accounting_subscriber_domain__c, Accounting_subscriber_domain__r.Name, Dimagi_Contact__c, Accounting_subscriber_domain__r.Account__r.Name,
                Accounting_subscriber_domain__r.cpAllWebUsers__c, Software_Plan_Edition__c, accounting_software_monthly_fee__c,
                Accounting_subscriber_domain__r.Opportunity__r.CreatedDate, Accounting_subscriber_domain__r.Opportunity__c,
                Accounting_subscriber_domain__r.Opportunity__r.CloseDate, Accounting_subscriber_domain__r.Opportunity__r.IsClosed,
                Account__c, do_not_invoice__c
                FROM Accounting_Subscription__c
                WHERE service_type__c NOT IN :service_type AND Accounting_subscriber_domain__r.Name != '' AND date_end__c != null AND date_end__c <=: this.currentDate.addDays(90)
                AND date_end__c >=: this.currentDate AND Accounting_subscriber_domain__r.Name NOT IN: domainsWithFutureSubscriptions AND is_active__c = true
                AND is_hidden_to_ops__c = false AND is_trial__c = false AND (Server_Name__c = 'CommCareHQ' OR Server_Name__c = 'CommCareHQ India' OR Server_Name__c = 'CommCareHQ EU') ORDER BY date_end__c DESC];
    }
}