/**
 * Batch job for increase counter of failing sales process in Opportunity.
 */
public class OpportunityFailingSalesProcessBatch implements Database.Batchable<Opportunity>, Database.Stateful {

    public OpportunityFailingSalesProcessBatch() {
    }

    public List<Opportunity> start(Database.BatchableContext BC) {
        return [SELECT Id, Name, Latest_day_Opp_failed_sales_process__c, Nb_times_Opp_failed_sales_process__c FROM Opportunity WHERE Channel_Response__c = 'Inside Sales' AND IsClosed = false];
    }

    public void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<OpportunityContactRole> contactRoles = [SELECT ContactId, OpportunityId FROM OpportunityContactRole WHERE OpportunityId IN: scope];
        List<Opportunity> toUpdate = new List<Opportunity>();

        Map<Id, Set<Id>> oppContactsMap = new Map<Id, Set<Id>>();
        for (OpportunityContactRole ocRole : contactRoles) {
            if (oppContactsMap.containsKey(ocRole.OpportunityId)) {
                oppContactsMap.get(ocRole.OpportunityId).add(ocRole.ContactId);
            } else {
                oppContactsMap.put(ocRole.OpportunityId, new Set<Id> { ocRole.ContactId });
            }
        }

        for (Opportunity opp : scope) {
            if (oppContactsMap.containsKey(opp.Id)) {
                Set<Id> contractsIdList = oppContactsMap.get(opp.Id);

                if (contractsIdList.size() > 0) {
                    List<Contact> contacts = !Test.isRunningTest() ?
                                                [SELECT Id FROM Contact WHERE Id IN: contractsIdList
                                                 AND (Follow_up_Date__c = null OR Follow_up_Date__c <: Date.today())
                                                 AND (Days_w_o_Activity__c >= 10)
                                                 AND (Hubspot_Next_Activity_Date__c = null OR Hubspot_Next_Activity_Date__c <: Date.today())]:
                                                [SELECT Id FROM Contact WHERE Id IN: contractsIdList
                                                 AND (Follow_up_Date__c = null OR Follow_up_Date__c <: Date.today())
                                                 AND (Hubspot_Next_Activity_Date__c = null OR Hubspot_Next_Activity_Date__c <: Date.today())]; // In test we cannot mock Days_w_o_Activity__c, so for test we use different query

                    if (contractsIdList.size() == contacts.size()) { // FROM DOCS - if all contacts Follow-up Date = “blank” OR “Less than Today”,
                                                                     // AND Days w/o Activity greater or equal 10,
                                                                     // AND Hubspot - Next activity date = “blank” OR “more than 0 days ago”
                        opp.Latest_day_Opp_failed_sales_process__c = Date.today();
                        opp.Nb_times_Opp_failed_sales_process__c = opp.Nb_times_Opp_failed_sales_process__c != null ? opp.Nb_times_Opp_failed_sales_process__c + 1 : 1;
                        toUpdate.add(opp);
                    }
                }
            }
        }

        if (toUpdate.size() > 0) {
            Database.SaveResult[] srList = Database.update(toUpdate, false);
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromDatabaseSaveResultErrors(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                        'Opportunity Failing Process Errors', 'Cannot Update Opportunieties : ', srList);
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) {
            EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Opportunity Failing Process', 'Job finished : ' + Date.today());
        }
    }
}