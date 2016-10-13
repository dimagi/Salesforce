trigger LeadConversionTrigger on Lead (after update) {
    if (Trigger.new.size() == 1) {
        // After conversion
        if (Trigger.old[0].isConverted == false && Trigger.new[0].isConverted == true) {
            if (Trigger.new[0].ConvertedOpportunityId != null) {
                Opportunity opp = [SELECT Id, Lead_Status__c, Lead_Status_Reason__c, Lead_Ever_Responded__c, Lead_first_call_held__c, Lead_follow_up_calls_held__c
                                   FROM Opportunity WHERE Id = :Trigger.new[0].ConvertedOpportunityId];
                opp.Lead_Status__c = Trigger.new[0].Status;
                opp.Lead_Status_Reason__c = Trigger.new[0].Lead_Status_Reason__c;
                opp.Lead_Ever_Responded__c = Trigger.new[0].Ever_Responded__c == 0 ? false : true;
                opp.Lead_first_call_held__c = Trigger.new[0].First_call_held__c == 0 ? false : true;
                opp.Lead_follow_up_calls_held__c = Trigger.new[0].Follow_up_calls_held__c;
                update opp;
            }
        }
    }
}