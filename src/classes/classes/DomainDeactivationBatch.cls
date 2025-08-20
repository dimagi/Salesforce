public class DomainDeactivationBatch  implements Database.Batchable<DuplicateDomainWrapper>, Database.AllowsCallouts {

    public DomainDeactivationBatch() {}

    public List<DuplicateDomainWrapper> start(Database.BatchableContext context) {
        List<DuplicateDomainWrapper> result = new List<DuplicateDomainWrapper>();
        for (AggregateResult aggRes : [SELECT Server_Name__c, Name, Count(Id) FROM Domain__c WHERE Domain_Deleted__c = false GROUP BY Server_Name__c, Name HAVING Count(Id) > 1]) {
            String domainName = (String) aggRes.get('Name');
            String serverName = (String) aggRes.get('Server_Name__c');

            System.debug('Duplicate data : ' + domainName + ' - ' + serverName);
            result.add(new DuplicateDomainWrapper(domainName, serverName));
        }
        return result;
    }

    public void execute(Database.BatchableContext context, List<DuplicateDomainWrapper> scope) {
        List<Exception> errors = new List<Exception>();
        for (DuplicateDomainWrapper domainWrapper : scope) { // Additional loop to avoid "Uncomitted work pending"
            try {
                domainWrapper.realDomainId = HQSyncUtils.getRealDomainId(domainWrapper.domainName, domainWrapper.serverName);
            } catch (Exception e) {
                errors.add(e);
                System.debug('API Error : ' + e.getMessage());
                System.debug('API Error : ' + e.getCause());
                System.debug('API Error : ' + e.getLineNumber());
                System.debug('API Error : ' + e.getStackTraceString());
                System.debug('API Error : ' + e.getTypeName());
                continue;
            }
        }

        for (Exception e : errors) { // Additional loop to avoid "Uncomitted work pending"
            StatusLoggerUtils.logError(StatusLoggerUtils.HQ_SYNC_DUPLICATES_LOGGER, 'Cannot fetch duplicated domain data form HQ', 0, e.getMessage());
        }

        for (DuplicateDomainWrapper domainWrapper : scope) {
            String hqId = domainWrapper.realDomainId;

            if (hqId == null || hqId == '') {
                System.debug('Empty domain id : ' + domainWrapper.domainName + ' - ' + domainWrapper.serverName);
                StatusLoggerUtils.logError(StatusLoggerUtils.HQ_SYNC_DUPLICATES_LOGGER, 'Cannot fetch duplicated domain data form HQ', 0, 'API error ' + domainWrapper.domainName + ' - ' + domainWrapper.serverName);
                continue;
            }

            List<Domain__c> duplicates = [SELECT Id, id__c, Name, Domain_Deleted__c, date_created__c, Opportunity__c, Account__c, Lead__c, Primary_Contact__c, Country_of_deployment_salesforce__c FROM Domain__c
                                          WHERE Server_Name__c =: domainWrapper.serverName AND Name =: domainWrapper.domainName AND Domain_Deleted__c = false
                                          ORDER BY date_created__c];
            if (duplicates.size() < 1) { // no duplicates
                System.debug('No duplicated domains');
                continue;
            }

            Id oppId;
            Id leadId;
            Id accountId;
            Id contactId;
            Id deployId;

            Set<Id> opportunityMapping = new Set<Id>();
            Domain__c realDomain;
            for (Domain__c duplicate : duplicates) {
                if (duplicate.id__c == hqId) {
                    realDomain = duplicate;
                }
            }

            if (realDomain == null) {
                StatusLoggerUtils.logError(StatusLoggerUtils.HQ_SYNC_DUPLICATES_LOGGER, 'Cannot find real domain in DB', 0, 'Cannot find record');
                continue;
            }
            oppId = realDomain.Opportunity__c;
            leadId = realDomain.Lead__c;
            accountId = realDomain.Account__c;
            deployId = realDomain.Country_of_deployment_salesforce__c;
            contactId = realDomain.Primary_Contact__c;

            for (Domain__c duplicate : duplicates) {
                duplicate.Domain_Deleted__c = true;

                if (oppId == null && duplicate.Opportunity__c != null) {
                    oppId = duplicate.Opportunity__c;
                    opportunityMapping.add(oppId);
                }
                if (leadId == null && duplicate.Lead__c != null) { // test converted leads in unit tests
                    leadId = duplicate.Lead__c;
                }
                if (accountId == null && duplicate.Account__c != null) {
                    accountId = duplicate.Account__c;
                }
                if (contactId == null && duplicate.Primary_Contact__c != null) {
                    contactId = duplicate.Primary_Contact__c;
                }
                if (deployId == null && duplicate.Country_of_deployment_salesforce__c != null) {
                    deployId = duplicate.Country_of_deployment_salesforce__c;
                }
            }

            realDomain.Domain_Deleted__c = false;
            realDomain.Opportunity__c = oppId;
            realDomain.Lead__c = leadId;
            realDomain.Account__c = accountId;
            realDomain.Primary_Contact__c = contactId;
            realDomain.Country_of_deployment_salesforce__c = deployId;

            List<Opportunity> opps = new List<Opportunity>();
            for (Id oppIdFor : opportunityMapping) {
                opps.add(new Opportunity(Id = oppIdFor, Domain_Name__c = realDomain.Id));
            }

            List<Contract_Domain__c> contractDomains = [SELECT Id, Domain__c FROM Contract_Domain__c WHERE Domain__c IN: duplicates];
            for (Contract_Domain__c contractDomain : contractDomains) {
                contractDomain.Domain__c = realDomain.Id;
            }

            List<Accounting_Invoice__c> invoices = [SELECT Id, Project_Space__c FROM Accounting_Invoice__c WHERE Project_Space__c IN: duplicates];
            for (Accounting_Invoice__c invoice : invoices) {
                invoice.Project_Space__c = realDomain.Id;
            }

            List<Accounting_Subscriber__c> subscribers = [SELECT Id, domain_lookup__c FROM Accounting_Subscriber__c WHERE domain_lookup__c IN: duplicates];
            for (Accounting_Subscriber__c sub : subscribers) {
                sub.domain_lookup__c = realDomain.Id;
            }

            List<Accounting_Subscription__c> subscriptions = [SELECT Id, Accounting_subscriber_domain__c FROM Accounting_Subscription__c WHERE Accounting_subscriber_domain__c IN: duplicates];
            for (Accounting_Subscription__c sub : subscriptions) {
                sub.Accounting_subscriber_domain__c = realDomain.Id;
            }

            Savepoint sp = Database.setSavepoint();
            try {
                update duplicates;
                if (opps.size() > 0) {
                    update opps;
                }
                if (contractDomains.size() > 0) {
                    update contractDomains;
                }
                if (invoices.size() > 0) {
                    update invoices;
                }
                if (subscribers.size() > 0) {
                    update subscribers;
                }
                if (subscriptions.size() > 0) {
                    update subscriptions;
                }
            } catch (DMLException e) {
                StatusLoggerUtils.logError(StatusLoggerUtils.HQ_SYNC_DUPLICATES_LOGGER, 'Cannot update duplicated domains', 0, e.getMessage());
                Database.rollback(sp);
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        if (!Test.isRunningTest()) {
            StatusLoggerUtils.sendLog(StatusLoggerUtils.HQ_SYNC_DUPLICATES_LOGGER,  BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','));
        }
    }

    public class DuplicateDomainWrapper {

        public String domainName { get; set; }
        public String serverName { get; set; }
        public String realDomainId { get; set; }

        public DuplicateDomainWrapper(String domainName, String serverName) {
            this.domainName = domainName;
            this.serverName = serverName;
        }
    }
}