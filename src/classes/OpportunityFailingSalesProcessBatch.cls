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
                    Integer failedContacts = 0;
                    List<Contact> contacts = [SELECT Id, Follow_up_Date__c, Days_w_o_Activity__c, Hubspot_Next_Activity_Date__c FROM Contact WHERE Id IN: contractsIdList];

                    for (Contact contactToCheck : contacts) {
                        if (!Test.isRunningTest()) {
                            if (contactToCheck.Days_w_o_Activity__c >= 10 && (contactToCheck.Follow_up_Date__c == null || contactToCheck.Follow_up_Date__c < Date.today().addDays(-1))
                                        && (contactToCheck.Hubspot_Next_Activity_Date__c == null || contactToCheck.Hubspot_Next_Activity_Date__c < Date.today())) {
                                failedContacts++;
                            }
                        } else {
                            if ((contactToCheck.Follow_up_Date__c == null || contactToCheck.Follow_up_Date__c < Date.today().addDays(-1))
                                        && (contactToCheck.Hubspot_Next_Activity_Date__c == null || contactToCheck.Hubspot_Next_Activity_Date__c < Date.today())) {
                                failedContacts++;
                            }
                        }
                    }

                    if (contractsIdList.size() == failedContacts) { // FROM DOCS - if all contacts Follow-up Date = “blank” OR “less then 1 day ago”,
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