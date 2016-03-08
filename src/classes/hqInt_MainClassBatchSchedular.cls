global class hqInt_MainClassBatchSchedular implements Schedulable {
	global void execute(SchedulableContext sc) 
	{
		hqInt_ManualRunController obj = new hqInt_ManualRunController();
		obj.fetchRunningInstances();
		if(obj.batchIsRunning == false)
			Database.executeBatch(new hqInt_MainClassBatch(),1);	
	}
}