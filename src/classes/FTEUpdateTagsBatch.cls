/**
 * Batch job used to add FTE Tracker tags from removed time cards.
 */
public without sharing class FTEUpdateTagsBatch implements Database.Batchable<FTE_Tag__c>, Database.Stateful {

    private List<Time_Card__c> timeCardsToUpsert;

    public FTEUpdateTagsBatch() {
        this.timeCardsToUpsert = new List<Time_Card__c>();
    }

    public List<FTE_Tag__c> start(Database.BatchableContext BC) {
        return [SELECT Id, Hours__c, Date__c, Employee__c, TC_Contract__c, FTE_Contract__c FROM FTE_Tag__c
                        WHERE Action__c = 'Tag Deleted'];
    }

    public void execute(Database.BatchableContext BC, List<FTE_Tag__c> scope) {
        // If tag was deleted it means that we need one time car without tag, if not we need add FTE_only time card
        Set<Id> timeCardsIds = new Set<Id>();
        for (FTE_Tag__c removedTag : scope) {
            List<Time_Card__c> timeCards = [SELECT Id, FTE_hours__c, FTE_Contract__c FROM Time_Card__c
                                            WHERE Employee__c =: removedTag.Employee__c AND Client__c != null
                                            AND Client__c =: removedTag.TC_Contract__c
                                            AND (FTE_Contract__c = null OR FTE_Contract__c = '')
                                            AND CALENDAR_MONTH(Date__c) =: removedTag.Date__c.month()
                                            AND CALENDAR_YEAR(Date__c) =: removedTag.Date__c.year()
                                            AND Id NOT IN: timeCardsIds LIMIT 1];
            if (timeCards.size() > 0) {
                Time_Card__c tc = timeCards.get(0);
                tc.FTE_Contract__c = removedTag.FTE_Contract__c;
                tc.FTE_hours__c = removedTag.Hours__c;
                timeCardsIds.add(tc.Id);
                timeCardsToUpsert.add(tc);
            } else {
                timeCardsToUpsert.add(new Time_Card__c(Client__c = removedTag.TC_Contract__c, Employee__c = removedTag.Employee__c,
                                                       Date__c = removedTag.Date__c, FTE_Contract__c = removedTag.FTE_Contract__c,
                                                       FTE_only__c = true, Total__c = 0, FTE_hours__c = removedTag.Hours__c));
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        if (this.timeCardsToUpsert.size() > 0) {
            upsert this.timeCardsToUpsert;
        }
        List<FTE_Tag__c> tagsToDelete = [SELECT Id FROM FTE_Tag__c WHERE Action__c = 'Tag Deleted'];
        if (tagsToDelete.size() > 0) {
            delete tagsToDelete;
        }
    }
}