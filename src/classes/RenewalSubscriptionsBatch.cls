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

        // Group by billing account (Accounting_BillingAccount__c), so a grouped subscription
        // with several project-space domains produces ONE renewal Opportunity instead of one
        // per domain. A subscription with no billing account (Account__c null) falls back to
        // being its own single-domain group. Every eligible subscription is kept here (not
        // reduced to one per domain yet) - a domain with more than one candidate still needs
        // all of them available in case its best candidate fails validation below.
        Map<Id, List<Accounting_Subscription__c>> subscriptionsByGroup = new Map<Id, List<Accounting_Subscription__c>>();
        for (Accounting_Subscription__c subscription : this.collectedSubscriptions) {
            Id groupKey = subscription.Account__c != null ? subscription.Account__c : subscription.Accounting_subscriber_domain__c;
            if (!subscriptionsByGroup.containsKey(groupKey)) {
                subscriptionsByGroup.put(groupKey, new List<Accounting_Subscription__c>());
            }
            subscriptionsByGroup.get(groupKey).add(subscription);
        }

        for (List<Accounting_Subscription__c> groupSubs : subscriptionsByGroup.values()) {

            // Drop candidates whose domain already has an open (or very recently closed)
            // renewal Opportunity - that domain has already been handled. Domains that
            // don't still get a shared Opportunity, even if a sibling domain in the same
            // group already has one from a prior run.
            List<Accounting_Subscription__c> eligibleSubs = new List<Accounting_Subscription__c>();
            for (Accounting_Subscription__c s : groupSubs) {
                Boolean domainAlreadyHasOpp = s.Accounting_subscriber_domain__r.Opportunity__c != null &&
                     (s.Accounting_subscriber_domain__r.Opportunity__r.IsClosed == false ||
                       (s.Accounting_subscriber_domain__r.Opportunity__r.IsClosed == true && s.Accounting_subscriber_domain__r.Opportunity__r.CloseDate >= this.currentDate));
                if (!domainAlreadyHasOpp) {
                    eligibleSubs.add(s);
                }
            }
            if (eligibleSubs.isEmpty()) {
                continue;
            }

            // Prefer the subscription that's actually billed (do_not_invoice__c = false),
            // then the one ending soonest, then Id - fully deterministic regardless of
            // execute() chunk arrival order. Walk candidates in that order and use the
            // first one that's actually renewable, so one bad candidate (unmatched service
            // type, missing Pricebook entry) doesn't take the whole group down with it.
            eligibleSubs.sort(new RepresentativeCandidateComparator());

            Accounting_Subscription__c subscription = null;
            String oppSource = '';
            Id ownerId = null;
            PricebookEntry pbe = null;
            Decimal price = null;

            for (Accounting_Subscription__c candidate : eligibleSubs) {
                String candidateOppSource = '';
                Id candidateOwnerId = null;
                if (candidate.service_type__c == 'IMPLEMENTATION' && candidate.Software_Plan_Edition__c != 'Enterprise') {
                    candidateOppSource = IMPL_RENEWAL;
                    candidateOwnerId = this.implementationNonEnterpriseOwner.Id;
                } else if (candidate.service_type__c == 'IMPLEMENTATION' && candidate.Software_Plan_Edition__c == 'Enterprise') {
                    candidateOppSource = IMPL_RENEWAL;
                    candidateOwnerId = this.implementationEnterpriseOwner.Id;
                } else if ((candidate.service_type__c == 'PRODUCT' || candidate.service_type__c == 'TRIAL' || candidate.service_type__c == 'NOT_SET')
                                && candidate.Software_Plan_Edition__c != 'Enterprise') {
                    candidateOppSource = PROD_RENEWAL;
                    candidateOwnerId = this.productNonEnterpriseOwner.Id;
                } else if ((candidate.service_type__c == 'PRODUCT' || candidate.service_type__c == 'TRIAL' || candidate.service_type__c == 'NOT_SET')
                                && candidate.Software_Plan_Edition__c == 'Enterprise') {
                    candidateOppSource = PROD_RENEWAL;
                    candidateOwnerId = this.productEnterpriseOwner.Id;
                } else {
                    continue; // this candidate's service type isn't renewable - try the next one
                }

                PricebookEntry candidatePbe = this.priceBookEntries.get(candidate.Software_Plan_Edition__c);
                // SAL-515: price the renewal from the subscription's current monthly fee;
                // fall back to the Pricebook list price (no custom setting / hardcoded values).
                Decimal candidatePrice = (candidate.accounting_software_monthly_fee__c != null && candidate.accounting_software_monthly_fee__c > 0)
                                    ? candidate.accounting_software_monthly_fee__c
                                    : (candidatePbe != null ? candidatePbe.UnitPrice : null);
                if (candidatePbe == null || candidatePrice == null) {
                    System.debug(' Missing Pricebook entry or price for edition: ' + candidate.Software_Plan_Edition__c);
                    StatusLoggerUtils.logError(
                        StatusLoggerUtils.RENEWAL_LOGGER,
                        candidate.Name,
                        0,
                        'Missing Pricebook entry or price for edition: ' + candidate.Software_Plan_Edition__c
                    );
                    continue; // this candidate has no usable price - try the next one
                }

                subscription = candidate;
                oppSource = candidateOppSource;
                ownerId = candidateOwnerId;
                pbe = candidatePbe;
                price = candidatePrice;
                break;
            }

            if (subscription == null) {
                continue; // nothing in this group could be turned into a valid Opportunity this run
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
                                                    // Domain_Name__c, AccountId, Prior_Dimagi_contact__c and
                                                    // Subscriptions_web_users__c all take a single value and can
                                                    // only reflect the representative domain - the full set of
                                                    // domains this Opportunity covers is on Domain__c.Opportunity__c
                                                    // below. In observed data, grouped domains don't carry a CRM
                                                    // Account of their own (Domain__c.Account__c is null), so this
                                                    // hasn't been seen to diverge across a group in practice.
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

            // Stamp every still-eligible domain in the group, not just the representative's -
            // that's what makes next week's run skip them. Dedup by domain: eligibleSubs can
            // hold more than one candidate for the same domain.
            List<Domain__c> domainsToUpdate = new List<Domain__c>();
            Set<Id> domainIdsAdded = new Set<Id>();
            for (Accounting_Subscription__c s : eligibleSubs) {
                Id domainId = s.Accounting_subscriber_domain__c;
                if (domainIdsAdded.contains(domainId)) {
                    continue;
                }
                Domain__c domainToUpdate = domains.get(domainId);
                if (domainToUpdate != null) {
                    domainsToUpdate.add(domainToUpdate);
                    domainIdsAdded.add(domainId);
                }
            }

            Savepoint sp = Database.setSavepoint();
            try {
                insert newOpp;
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
     * Orders a group's candidate subscriptions for representative selection: the one
     * actually billed (do_not_invoice__c = false) first, then the one ending soonest,
     * then Id - so the choice is fully deterministic regardless of the order execute()
     * chunks happened to run in.
     */
    private class RepresentativeCandidateComparator implements Comparator<Accounting_Subscription__c> {
        public Integer compare(Accounting_Subscription__c a, Accounting_Subscription__c b) {
            Boolean aBilled = a.do_not_invoice__c == false;
            Boolean bBilled = b.do_not_invoice__c == false;
            if (aBilled != bBilled) {
                return aBilled ? -1 : 1;
            }
            if (a.date_end__c != b.date_end__c) {
                return a.date_end__c < b.date_end__c ? -1 : 1;
            }
            return a.Id < b.Id ? -1 : (a.Id > b.Id ? 1 : 0);
        }
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
                AND is_hidden_to_ops__c = false AND is_trial__c = false AND (Server_Name__c = 'CommCareHQ' OR Server_Name__c = 'CommCareHQ India' OR Server_Name__c = 'CommCareHQ EU')];
                // No ORDER BY: representative selection in processCollectedSubscriptions()
                // sorts explicitly and doesn't depend on query order (execute() chunk order
                // isn't guaranteed either, so relying on this would have been unsafe anyway).
    }
}