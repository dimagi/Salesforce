trigger ProjectProduct on Project_Product__c (after insert, after update, after delete) {
	
		if (Trigger.isDelete) {
			ProjectProductTrigger.onUpdate(Trigger.old);
		}
		else ProjectProductTrigger.onUpdate(Trigger.new);


}