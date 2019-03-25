public class DomainTriggerController {

    public static void handleBeforeUpdate(List<Domain__c> newDomains, Map<Id, Domain__c> oldMap) {
        Set<Id> opps = new Set<Id>();
        Map<Id, Id> domainToOpp = new Map<Id, Id>();
        for (Domain__c domain : newDomains) {
            Domain__c oldDomain = oldMap.get(domain.Id);
            System.debug('domain : ' + domain.Opportunity__c + ' ' + domain.Name + ' ' + oldDomain.Opportunity__c);
            if ((domain.Opportunity__c != null && oldDomain.Opportunity__c == null)
                || (domain.Opportunity__c != null && domain.Opportunity__c != oldDomain.Opportunity__c)) {
                opps.add(domain.Opportunity__c);
                domainToOpp.put(domain.Id, domain.Opportunity__c);
                System.debug('domain added');
            }
        }

        if (opps.size() > 0) {
            List<OpportunityContactRole> contactRoles = [SELECT ContactId, OpportunityId FROM OpportunityContactRole WHERE IsPrimary = true AND OpportunityId IN: opps];
            Map<Id, Id> oppToContactMap = new Map<Id, Id>();
            for (OpportunityContactRole role : contactRoles) {
                oppToContactMap.put(role.OpportunityId, role.ContactId);
            }
            Map<Id, Opportunity> oppToAccMap = new Map<Id, Opportunity>([SELECT Id, AccountId FROM Opportunity WHERE Id IN: opps]);

            for (Domain__c domain : newDomains) {
                if (!domainToOpp.containsKey(domain.Id)) {
                    continue;
                }
                Id oppId = domainToOpp.get(domain.Id);
                Id accountId = oppToAccMap.get(oppId).AccountId;
                if (oppId != null && oppToContactMap.containsKey(oppId)) {
                    domain.Primary_Contact__c = oppToContactMap.get(oppId);
                }
                if (oppId != null && accountId != null) {
                    domain.Account__c = accountId;
                }
            }
        }
    }
}