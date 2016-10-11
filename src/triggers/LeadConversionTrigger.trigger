trigger LeadConversionTrigger on Lead (after update) {
    if (Trigger.new.size() == 1) {
        // After conversion
        if (Trigger.old[0].isConverted == false && Trigger.new[0].isConverted == true) {
            if (Trigger.new[0].ConvertedOpportunityId != null) {
                Opportunity opp = [SELECT Id, Converted_Lead__c fROM Opportunity WHERE Id = :Trigger.new[0].ConvertedOpportunityId];
                opp.Converted_Lead__c = Trigger.new[0].Id;
                update opp;
            }
        }
    }
}