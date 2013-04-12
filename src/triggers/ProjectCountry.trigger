/**
 * Updates the Country_Text__c field in Project with the names of the Project Countries
 *
 * @author  Virginia Fernández
 * @date    04/12/2013
 */
trigger ProjectCountry on ProjectCountry__c (after delete, after insert) {
    if (Trigger.isDelete) {
        ProjectCountryTrigger.onUpdate(Trigger.old);
    }
    else ProjectCountryTrigger.onUpdate(Trigger.new);
}