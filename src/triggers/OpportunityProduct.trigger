trigger OpportunityProduct on OpportunityLineItem (after delete, after insert, after update) {
	
	if (Trigger.isDelete) {
		OpportunityProductTrigger.onUpdate(Trigger.old);
	}
	else OpportunityProductTrigger.onUpdate(Trigger.new);

}