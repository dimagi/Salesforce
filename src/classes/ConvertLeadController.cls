public with sharing class ConvertLeadController {

    @AuraEnabled
    public static ConvertResult convertLead(
        Id leadId,
        String conversionOutcome,
        String dispositionNotes,
        String reEngagementPathway,
        Date reEngageDate,
        Id existingAccountId,
        Id existingContactId,
        String opportunityName,
        String contactStatus,
        Boolean gspPrimaryContact
    ) {
        // Capture current status before we change anything — this becomes Lead_Stage_at_Exit__c
        Lead currentLead = [SELECT Id, Status, Company, Opportunity_Owner_Division__c, Opportunity_Owner_Sub_Division__c
                            FROM Lead WHERE Id = :leadId LIMIT 1];

        // Write context fields + stage at exit before calling convertLead, so the data is
        // preserved even if conversion fails and the rep needs to retry.
        Lead leadUpdate = new Lead(Id = leadId);
        leadUpdate.Conversion_Outcome__c = conversionOutcome;
        leadUpdate.Disposition_Notes__c = dispositionNotes;
        leadUpdate.Re_engagement_Pathway__c = reEngagementPathway;
        leadUpdate.Re_engage_Date__c = reEngageDate;
        leadUpdate.Lead_Stage_at_Exit__c = currentLead.Status;
        update leadUpdate;

        Boolean createOpportunity = conversionOutcome == 'With Opportunity';

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setConvertedStatus('Converted');
        lc.setDoNotCreateOpportunity(!createOpportunity);

        if (existingAccountId != null) {
            lc.setAccountId(existingAccountId);
        }
        if (existingContactId != null) {
            lc.setContactId(existingContactId);
        }
        if (createOpportunity && String.isNotBlank(opportunityName)) {
            lc.setOpportunityName(opportunityName);
        }

        ConvertResult cr = new ConvertResult();
        try {
            Database.LeadConvertResult result = Database.convertLead(lc);

            if (!result.isSuccess()) {
                cr.success = false;
                cr.errorMessage = result.getErrors()[0].getMessage();
                return cr;
            }

            cr.accountId = result.getAccountId();
            cr.contactId = result.getContactId();
            cr.opportunityId = result.getOpportunityId();

            // Update Contact: status (existing behavior) + lead context fields
            if (cr.contactId != null) {
                Contact c = [SELECT Id, Lead_Cycle_Count__c, Lead__c FROM Contact WHERE Id = :cr.contactId LIMIT 1];
                c.Status__c = String.isNotBlank(contactStatus) ? contactStatus : '1- Working - Active Opp Development';
                if (c.Lead__c == null) c.Lead__c = leadId;
                c.GSP_Primary_Contact__c = gspPrimaryContact;
                c.Last_Lead_Outcome__c = conversionOutcome;
                c.Last_Lead_Context__c = dispositionNotes;
                c.Follow_up_Date__c = reEngageDate;
                c.Last_Lead_Re_engagement_Pathway__c = reEngagementPathway;
                c.Last_Lead_Date__c = Date.today();
                c.Lead_Cycle_Count__c = (c.Lead_Cycle_Count__c == null ? 0 : c.Lead_Cycle_Count__c) + 1;
                update c;
            }

            // Set Opportunity defaults — mirrors the existing LeadConversionController behavior
            if (cr.opportunityId != null) {
                Opportunity opp = new Opportunity(Id = cr.opportunityId);
                opp.StageName = 'Stage 4 - Proposal Development';
                opp.Probability = 20;
                opp.of_Execution_budget_for_GS__c = 0;
                opp.Channel_Response__c = 'Inside Sales';
                opp.Implementation_Type__c = 'Self Service';
                opp.Opportunity_Source__c = 'Inbound';
                opp.Duration_months__c = 12;
                opp.CloseDate = Date.today().addMonths(2).toStartOfMonth().addDays(-1);
                opp.Renewal_expected__c = true;
                opp.Opportunity_Owner_Division__c = currentLead.Opportunity_Owner_Division__c;
                opp.Opportunity_Owner_Sub_Division__c = currentLead.Opportunity_Owner_Sub_Division__c;
                opp.Expected_Buffer__c = 0;
                opp.Execution_Owner_Division__c = currentLead.Opportunity_Owner_Division__c;
                opp.Execution_Owner_Practice__c = currentLead.Opportunity_Owner_Sub_Division__c;
                opp.Source_Lead__c = leadId;

                List<Business_Unit__c> bus = [SELECT Id FROM Business_Unit__c WHERE Name = 'Inc' LIMIT 1];
                if (!bus.isEmpty()) {
                    opp.Opportunity_Owning_Entity__c = bus[0].Id;
                }
                update opp;
            }

            cr.success = true;
        } catch (DmlException e) {
            cr.success = false;
            cr.errorMessage = e.getDmlMessage(0);
        } catch (Exception e) {
            cr.success = false;
            cr.errorMessage = e.getMessage();
        }

        return cr;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchTerm) {
        String s = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        return [SELECT Id, Name FROM Account WHERE Name LIKE :s ORDER BY Name LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> searchContacts(String searchTerm) {
        String s = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        return [SELECT Id, Name, Email, Account.Name, Status__c, GSP_Primary_Contact__c
                FROM Contact WHERE Name LIKE :s OR Email LIKE :s ORDER BY Name LIMIT 10];
    }

    @AuraEnabled(cacheable=true)
    public static Lead getLeadDetails(Id leadId) {
        List<Lead> leads = [SELECT Id, FirstName, LastName, Name, Company, Email, Status FROM Lead WHERE Id = :leadId LIMIT 1];
        return leads.isEmpty() ? null : leads[0];
    }

    @AuraEnabled
    public static SuggestedMatches getSuggestedMatches(Id leadId) {
        SuggestedMatches m = new SuggestedMatches();
        List<Lead> leads = [SELECT account_name__c, Company, Email FROM Lead WHERE Id = :leadId LIMIT 1];
        if (leads.isEmpty()) return m;
        Lead lead = leads[0];
        if (lead.account_name__c != null) {
            List<Account> accts = [SELECT Id, Name FROM Account WHERE Id = :lead.account_name__c LIMIT 1];
            if (!accts.isEmpty()) {
                m.accountId = accts[0].Id;
                m.accountName = accts[0].Name;
            }
        } else if (String.isNotBlank(lead.Company)) {
            List<Account> accts = [SELECT Id, Name FROM Account WHERE Name = :lead.Company LIMIT 1];
            if (!accts.isEmpty()) {
                m.accountId = accts[0].Id;
                m.accountName = accts[0].Name;
            }
        }
        if (String.isNotBlank(lead.Email)) {
            List<Contact> cons = [SELECT Id, Name, Follow_up_Date__c, Status__c, GSP_Primary_Contact__c
                                  FROM Contact WHERE Email = :lead.Email LIMIT 1];
            if (!cons.isEmpty()) {
                m.contactId = cons[0].Id;
                m.contactName = cons[0].Name;
                m.contactFollowUpDate = cons[0].Follow_up_Date__c;
                m.contactStatus = cons[0].Status__c;
                m.contactGspPrimaryContact = cons[0].GSP_Primary_Contact__c;
            }
        }
        return m;
    }

    public class SuggestedMatches {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public Date contactFollowUpDate;
        @AuraEnabled public String contactStatus;
        @AuraEnabled public Boolean contactGspPrimaryContact;
    }

    public class ConvertResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id opportunityId;
    }
}
