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
    // Grouping by billing account has to see every eligible subscription at once - a group
    // can span more than one execute() chunk (RenewalSubscriptionsScheduler uses a scope of
    // 10), and chunk order isn't guaranteed either. start() is the only place that sees the
    // whole candidate set in one call, so grouping and representative selection happen there;
    // only one already-validated representative per group is returned, to be chunked (and
    // its DML bounded) by Batch Apex as usual. The rest of each group's domain Ids are kept
    // here for execute() to stamp alongside the representative's own domain.
    private Map<Id, Set<Id>> domainIdsByGroup;

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

        return selectRepresentativesForRenewal(getSubscriptionsForRenewal(domainsWithFutureSubscriptions));
    }

    /**
     * Groups the full candidate set by billing account (Account__c, falling back to the
     * domain when there isn't one), picks one renewable representative subscription per
     * group, and records the rest of each group's domain Ids in domainIdsByGroup for
     * execute() to stamp later. Only ever called once, from start(), which is the only place
     * that sees every candidate for this run at the same time.
     */
    private List<Accounting_Subscription__c> selectRepresentativesForRenewal(List<Accounting_Subscription__c> allCandidates) {
        Map<Id, List<Accounting_Subscription__c>> subscriptionsByGroup = new Map<Id, List<Accounting_Subscription__c>>();
        for (Accounting_Subscription__c subscription : allCandidates) {
            Id groupKey = subscription.Account__c != null ? subscription.Account__c : subscription.Accounting_subscriber_domain__c;
            if (!subscriptionsByGroup.containsKey(groupKey)) {
                subscriptionsByGroup.put(groupKey, new List<Accounting_Subscription__c>());
            }
            subscriptionsByGroup.get(groupKey).add(subscription);
        }

        this.domainIdsByGroup = new Map<Id, Set<Id>>();
        List<Accounting_Subscription__c> representatives = new List<Accounting_Subscription__c>();

        for (Id groupKey : subscriptionsByGroup.keySet()) {
            List<Accounting_Subscription__c> groupSubs = subscriptionsByGroup.get(groupKey);

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
            // then the one ending latest ("only the latest subscription which will end"),
            // then Id - fully deterministic regardless of data order. Walk candidates in
            // that order and use the first one that's actually renewable, so one bad
            // candidate (unmatched service type, missing Pricebook entry) doesn't take the
            // whole group down with it.
            eligibleSubs.sort(new RepresentativeCandidateComparator());

            Accounting_Subscription__c representative = null;
            for (Accounting_Subscription__c candidate : eligibleSubs) {
                if (resolveRenewalDetails(candidate) != null) {
                    representative = candidate;
                    break;
                }
            }
            if (representative == null) {
                List<String> attemptedNames = new List<String>();
                for (Accounting_Subscription__c s : eligibleSubs) {
                    attemptedNames.add(s.Name + ' (' + s.service_type__c + '/' + s.Software_Plan_Edition__c + ')');
                }
                StatusLoggerUtils.logError(
                    StatusLoggerUtils.RENEWAL_LOGGER,
                    String.join(attemptedNames, ', '),
                    0,
                    'No candidate subscription in this group could be turned into a renewal Opportunity - unrecognized service type or missing Pricebook entry/price for every candidate tried'
                );
                continue; // nothing in this group could be turned into a valid Opportunity this run
            }

            Set<Id> domainIds = new Set<Id>();
            for (Accounting_Subscription__c s : eligibleSubs) {
                domainIds.add(s.Accounting_subscriber_domain__c);
            }
            this.domainIdsByGroup.put(groupKey, domainIds);
            representatives.add(representative);
        }

        return representatives;
    }

    /**
     * Orders a group's candidate subscriptions for representative selection: the one
     * actually billed (do_not_invoice__c = false) first, then the one ending latest, then
     * Id - so the choice is fully deterministic regardless of data order.
     */
    private class RepresentativeCandidateComparator implements Comparator<Accounting_Subscription__c> {
        public Integer compare(Accounting_Subscription__c a, Accounting_Subscription__c b) {
            Boolean aBilled = a.do_not_invoice__c == false;
            Boolean bBilled = b.do_not_invoice__c == false;
            if (aBilled != bBilled) {
                return aBilled ? -1 : 1;
            }
            if (a.date_end__c != b.date_end__c) {
                return a.date_end__c > b.date_end__c ? -1 : 1;
            }
            return a.Id < b.Id ? -1 : (a.Id > b.Id ? 1 : 0);
        }
    }

    private class RenewalDetails {
        String oppSource;
        Id ownerId;
        PricebookEntry pbe;
        Decimal price;
    }

    /**
     * Resolves the renewal owner/source and price for a candidate subscription, or null if
     * it isn't renewable (unrecognized service type, or no usable Pricebook entry/fee).
     * Pure - no SOQL, no logging, no state changes - so it's cheap to call speculatively
     * while walking candidates in start(), and to call again in execute() to get the actual
     * values for the one candidate that was chosen.
     */
    private RenewalDetails resolveRenewalDetails(Accounting_Subscription__c candidate) {
        String oppSource = '';
        Id ownerId = null;
        if (candidate.service_type__c == 'IMPLEMENTATION' && candidate.Software_Plan_Edition__c != 'Enterprise') {
            oppSource = IMPL_RENEWAL;
            ownerId = this.implementationNonEnterpriseOwner.Id;
        } else if (candidate.service_type__c == 'IMPLEMENTATION' && candidate.Software_Plan_Edition__c == 'Enterprise') {
            oppSource = IMPL_RENEWAL;
            ownerId = this.implementationEnterpriseOwner.Id;
        } else if ((candidate.service_type__c == 'PRODUCT' || candidate.service_type__c == 'TRIAL' || candidate.service_type__c == 'NOT_SET')
                        && candidate.Software_Plan_Edition__c != 'Enterprise') {
            oppSource = PROD_RENEWAL;
            ownerId = this.productNonEnterpriseOwner.Id;
        } else if ((candidate.service_type__c == 'PRODUCT' || candidate.service_type__c == 'TRIAL' || candidate.service_type__c == 'NOT_SET')
                        && candidate.Software_Plan_Edition__c == 'Enterprise') {
            oppSource = PROD_RENEWAL;
            ownerId = this.productEnterpriseOwner.Id;
        } else {
            return null; // service type isn't renewable
        }

        PricebookEntry pbe = this.priceBookEntries.get(candidate.Software_Plan_Edition__c);
        // SAL-515: price the renewal from the subscription's current monthly fee;
        // fall back to the Pricebook list price (no custom setting / hardcoded values).
        Decimal price = (candidate.accounting_software_monthly_fee__c != null && candidate.accounting_software_monthly_fee__c > 0)
                            ? candidate.accounting_software_monthly_fee__c
                            : (pbe != null ? pbe.UnitPrice : null);
        if (pbe == null || price == null) {
            return null; // no usable price
        }

        RenewalDetails details = new RenewalDetails();
        details.oppSource = oppSource;
        details.ownerId = ownerId;
        details.pbe = pbe;
        details.price = price;
        return details;
    }

    public void execute(Database.BatchableContext context, List<Accounting_Subscription__c> representatives) {
        Set<Id> domainsSet = new Set<Id>();
        for (Accounting_Subscription__c representative : representatives) {
            Set<Id> groupDomainIds = this.domainIdsByGroup.get(groupKeyFor(representative));
            if (groupDomainIds != null) {
                domainsSet.addAll(groupDomainIds);
            }
        }
        Map<Id, Domain__c> domains = new Map<Id, Domain__c> ([SELECT Id, Name, Opportunity__c FROM Domain__c WHERE Id IN: domainsSet]);

        String dateString = (this.currentDate.month() < 10 ? '0' + this.currentDate.month() : '' + this.currentDate.month())
                                + (this.currentDate.day() < 10 ? '0' + this.currentDate.day() : '' + this.currentDate.day())
                                + ('' + this.currentDate.year());

        for (Accounting_Subscription__c subscription : representatives) {
            RenewalDetails details = resolveRenewalDetails(subscription);
            if (details == null) {
                // Shouldn't happen - start() already confirmed this candidate resolves.
                StatusLoggerUtils.logError(StatusLoggerUtils.RENEWAL_LOGGER, subscription.Name, 0,
                    'Representative subscription no longer resolves to a renewal (service type or Pricebook entry changed since start())');
                continue;
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
                                                    // below.
                                                    Domain_Name__c = subscription.Accounting_subscriber_domain__c,
                                                    StageName = 'Stage 3 - Prospect',
                                                    OwnerId = details.ownerId,
                                                    Implementation_Type__c = 'Self Service',
                                                    Channel_Response__c = 'Inside Sales',
                                                    Opportunity_Owning_Entity__c = this.incBusinessUnit.Id,
                                                    Contract_Owner_BU__c = this.incBusinessUnit.Id,
                                                    Implementing_Business_Unit__c = this.incBusinessUnit.Id,
                                                    Opportunity_Source__c = details.oppSource,
                                                    Opportunity_Owner_Division__c = 'CommCare',
                                                    Opportunity_Owner_Sub_Division__c = 'CommCare Sales',
                                                    AccountId = subscription.Accounting_subscriber_domain__r.Account__r.id
                                                );

            // Stamp every domain in the group, not just the representative's - that's what
            // makes next week's run skip them.
            List<Domain__c> domainsToUpdate = new List<Domain__c>();
            Set<Id> groupDomainIds = this.domainIdsByGroup.get(groupKeyFor(subscription));
            if (groupDomainIds != null) {
                for (Id domainId : groupDomainIds) {
                    Domain__c domainToUpdate = domains.get(domainId);
                    if (domainToUpdate != null) {
                        domainsToUpdate.add(domainToUpdate);
                    }
                }
            }

            Savepoint sp = Database.setSavepoint();
            try {
                insert newOpp;
                for (Domain__c domainToUpdate : domainsToUpdate) {
                    domainToUpdate.Opportunity__c = newOpp.Id;
                }
                update domainsToUpdate;

                insert new OpportunityLineItem(PricebookEntryId = details.pbe.Id, Quantity = 12, UnitPrice = details.price, OpportunityId = newOpp.Id);
                // SAL-48 removing commcare: product pricebook entry
                // insert new OpportunityLineItem(PricebookEntryId = commCareEntry.Id, Quantity = 1, UnitPrice = commCareEntry.UnitPrice, OpportunityId = newOpp.Id);
                this.recordCounter++;
            } catch (DMLException e) {
                Database.rollback(sp);
                StatusLoggerUtils.logError(StatusLoggerUtils.RENEWAL_LOGGER, subscription.Accounting_subscriber_domain__r.Name + ' - ' + subscription.Name, 0, e.getMessage());
            }
        }
    }

    private Id groupKeyFor(Accounting_Subscription__c subscription) {
        return subscription.Account__c != null ? subscription.Account__c : subscription.Accounting_subscriber_domain__c;
    }

    public void finish(Database.BatchableContext context) {
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
                // No ORDER BY: representative selection sorts explicitly and doesn't depend
                // on query order.
    }
}
