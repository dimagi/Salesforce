trigger LeadConversionTrigger on Lead (after update) {
    if (Trigger.new.size() > 0) {
        if (!RecursiveTriggerHelper.hasRecursiveFlag()) {
            Decimal threshold = 7;
            Set<Id> leadIds = new Set<Id>();
            Set<Id> convertedLeads = new Set<Id>();
            List<Opportunity> leadOpps = new List<Opportunity>();

            if (Trigger.isUpdate) {
                Lead_Qualifying_Process__c settings = Lead_Qualifying_Process__c.getOrgDefaults();
                if (settings != null && settings.Threshold__c != null) {
                    threshold = settings.Threshold__c;
                }

                System.debug('SIZE: ' + Trigger.new.size());
                for (Lead l : Trigger.new) {
                    // After conversion
                    if (Trigger.oldMap.get(l.Id).isConverted == false && l.isConverted == true) {
                        if (l.ConvertedContactId != null) {
                            convertedLeads.add(l.Id);
                        }
                        if (l.ConvertedOpportunityId != null) {
                            Opportunity opp = new Opportunity(Id = l.ConvertedOpportunityId);
                            opp.Lead_Status__c = l.Status;
                            opp.Lead_Status_Reason__c = l.Lead_Status_Reason__c;
                            opp.Lead_Ever_Responded__c = l.Ever_Responded__c == 0 ? false : true;
                            opp.Lead_first_call_held__c = l.First_call_held__c == 0 ? false : true;
                            opp.Lead_follow_up_calls_held__c = l.Follow_up_calls_held__c;
                            leadOpps.add(opp);
                        }
                    } else {
                        if (!Test.isRunningTest()) {
                            if (l.Failed_Qualifying_process_at_least_once__c == false && l.Days_w_o_Activity__c > threshold && l.Status == 'Working - Talking' && (l.Follow_up_Date__c == null || l.Follow_up_Date__c < Date.today())
                                    && (l.Hubspot_Next_Activity_Date__c == null || l.Hubspot_Next_Activity_Date__c < Date.today())
                                    && (l.Lead_Status_Reason__c == 'Working - Exploratory Call - Trying for' || l.Lead_Status_Reason__c == 'Working - Exploratory Call Held')) { // Failing qualifying process
                                leadIds.add(l.Id);
                            }
                        } else { // We cannot mock LastActivityDate so in test we use Follow_up_calls_held field !!! IMPORTANT for changes
                            System.debug('Name test : ' + l.Name);
                            if (l.Failed_Qualifying_process_at_least_once__c == false && l.Follow_up_calls_held__c > threshold && l.Status == 'Working - Talking' && (l.Follow_up_Date__c == null || l.Follow_up_Date__c < Date.today())
                                    && (l.Hubspot_Next_Activity_Date__c == null || l.Hubspot_Next_Activity_Date__c < Date.today())
                                    && (l.Lead_Status_Reason__c == 'Working - Exploratory Call - Trying for' || l.Lead_Status_Reason__c == 'Working - Exploratory Call Held')) {
                                leadIds.add(l.Id);
                            }
                        }
                    }
                }
            } else {
                for (Lead l : Trigger.new) {
                    if (l.isConverted == true && l.ConvertedContactId != null) {
                        convertedLeads.add(l.Id);
                    }
                }
            }

            if (leadOpps.size() > 0) {
                update leadOpps;
            }

            List<Lead> leads = new List<Lead>();
            if (leadIds.size() > 0) {
                System.debug('leadIds ' + leadIds.size());
                List<Lead> tmpLeads = [SELECT Id, Failed_Qualifying_process_at_least_once__c FROM Lead WHERE Id In: leadIds];
                for (Lead l : tmpLeads) {
                    l.Failed_Qualifying_process_at_least_once__c = true;
                    leads.add(l);
                }
            }

            if (convertedLeads.size() > 0) {
                System.debug('convertedLeads ' + convertedLeads.size());
                List<Lead> tmpLeads = [SELECT Id, ConvertedContactId, Contact_after_Lead_Conversion__c FROM Lead WHERE Id In: convertedLeads];
                for (Lead l : tmpLeads) {
                    l.Contact_after_Lead_Conversion__c = l.ConvertedContactId;
                    leads.add(l);
                }
            }

            if (leads.size() > 0) {
                RecursiveTriggerHelper.setRecursiveFlag();
                update leads;
            }
        }
    }
}