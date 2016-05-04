trigger NetEVDifferenceTrigger on Pipeline_Snapshot__c (after insert)
{
	TriggerFactory.createHandler(Pipeline_Snapshot__c.sObjectType);
}