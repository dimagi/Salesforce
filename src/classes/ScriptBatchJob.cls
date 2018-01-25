/**
 * This is editable class, should be used to do data migration. For example filling new fields with relation.
 */
public class ScriptBatchJob implements Database.Batchable<Lead>, Database.Stateful {

    public ScriptBatchJob() {
    }

    public List<Lead> start(Database.BatchableContext context) {
        return [SELECT Id, ConvertedContactId, Contact_after_Lead_Conversion__c FROM Lead WHERE IsConverted = true];
    }

    public void execute(Database.BatchableContext context, List<Lead> scope) {
        List<Lead> leads = new List<Lead>();
        Set<Id> contactIdsSet = new Set<Id>();
        for (Lead l : scope) {
            contactIdsSet.add(l.ConvertedContactId);
        }
        Map<Id, Contact> contactsMap = new Map<Id, Contact>  ([SELECT Id FROM Contact WHERE Id IN: contactIdsSet]);
        for (Lead l : scope) {
            if (contactsMap.containsKey(l.ConvertedContactId)) { // If contact exist
                l.Contact_after_Lead_Conversion__c = l.ConvertedContactId;
                leads.add(l);
            }
        }
        if (leads.size() > 0) {
            update leads;
        }
    }

    public void finish(Database.BatchableContext context) {
    }
}