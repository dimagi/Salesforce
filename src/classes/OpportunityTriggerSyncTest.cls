@isTest
public class OpportunityTriggerSyncTest {

    @isTest
    static void testOpportunityTriggerSyncFlow() {
        Opportunity o = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today(),
            Opportunity_Owner_Division__c = 'Global Solutions',
            Opportunity_Owner_Sub_Division__c = 'Inbound Sales'
        );
        insert o;

        Country__c c = new Country__c(Name = 'United States');
        insert c;

        Location__c l = new Location__c(Name = 'Los Angeles', Country__c = c.Id);
        insert l;

        Opportunity_Location__c ol1 = new Opportunity_Location__c(Opportunity__c = o.Id, Location__c = l.Id);
        insert ol1;

        Opportunity_Location__c ol2 = new Opportunity_Location__c(Opportunity__c = o.Id, Location__c = l.Id);
        insert ol2;

        delete ol1;

        o.StageName = 'Closed Won';
        update o;
    }
}