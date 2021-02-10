trigger FTEWorkCardTrigger on FTE_Work_Card__c (after insert) {
    
    	 if(Trigger.isAfter && Trigger.isInsert) {
        FTEWorkCardTriggerHandler.handleAfterInsert(Trigger.new);
    } 
}