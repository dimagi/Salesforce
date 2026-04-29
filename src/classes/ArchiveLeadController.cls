public with sharing class ArchiveLeadController {

    @AuraEnabled
    public static void archiveLead(Id leadId, String archiveReason, String dispositionNotes) {
        Lead currentLead = [SELECT Id, Status FROM Lead WHERE Id = :leadId LIMIT 1];

        Lead leadUpdate = new Lead(Id = leadId);
        leadUpdate.Status = 'Archived - Not Interested';
        leadUpdate.Archive_Reason__c = archiveReason;
        leadUpdate.Disposition_Notes__c = dispositionNotes;
        leadUpdate.Lead_Stage_at_Exit__c = currentLead.Status;
        update leadUpdate;
    }
}
