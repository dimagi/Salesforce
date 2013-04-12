/**
 * Trigger to update the Country_Text__c field in Opportunity with the names of the Opportunity Countries
 *
 * @author  Virginia Fernández
 * @date    04/12/2013
 */
trigger OpportunityCountry on OpportunityCountry__c (after delete, after insert) {
    if (Trigger.isDelete) {
        OpportunityCountryTrigger.onUpdate(Trigger.old);
    }
    else OpportunityCountryTrigger.onUpdate(Trigger.new);
}