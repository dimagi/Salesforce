public with sharing class ArchiveLeadController {

    @AuraEnabled
    public static void archiveLead(Id leadId, String archiveReason, String dispositionNotes) {
        List<Lead> leads = [SELECT Id, Status FROM Lead WHERE Id = :leadId LIMIT 1];
        if (leads.isEmpty()) {
            throw new AuraHandledException('Lead not found or has been deleted.');
        }

        Lead leadUpdate = new Lead(Id = leadId);
        leadUpdate.Status = 'Archived - Not Interested';
        leadUpdate.Archive_Reason__c = archiveReason;
        leadUpdate.Disposition_Notes__c = dispositionNotes;
        leadUpdate.Lead_Stage_at_Exit__c = leads[0].Status;
        try {
            update leadUpdate;
        } catch (DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }
}
