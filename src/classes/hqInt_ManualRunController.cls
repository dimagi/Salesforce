public with sharing class hqInt_ManualRunController 
{
	public Boolean batchIsRunning{get;set;}
	public String batchSubmittedDate{get;set;}
	public AsyncApexJob batchClassJob{get;set;}
	public Boolean phase2Running{get;set;}
	public list <JobWrapper> phase2Jobs{get;set;}

	//public AsyncApexJob 

	public hqInt_ManualRunController() 
	{
		fetchRunningInstances();	
		fetchRunningInstancesPhase2();
	}


	public void fetchRunningInstances()
	{
		ApexClass batchClass;
		batchIsRunning = false;
		try
		{
			batchClass = [SELECT id FROM ApexClass WHERE Name='hqInt_MainClassBatch' limit 1];
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Class not found'));
		}
		
		batchClassJob = null;
		AsyncApexJob[] batchClassJobList = [SELECT id,JobItemsProcessed,TotalJobItems,createdDate FROM AsyncApexJob WHERE ApexClassID = :batchClass.id AND Status IN ('Holding','Queued','Preparing','Processing') order by createdDate desc limit 1];
		if(batchClassJobList != null && batchClassJobList.size() > 0)
		{
			batchIsRunning = true;
			batchClassJob = batchClassJobList[0];
			batchSubmittedDate = batchClassJobList[0].createdDate.format();
		}
		
	} 

	public pagereference runBatchJob()
	{
		fetchRunningInstances();
		if(!batchIsRunning)
			Database.executeBatch(new hqInt_MainClassBatch(),1);
		fetchRunningInstances();
		return null;
	}

	//FOR phase 2
	public void fetchRunningInstancesPhase2()
	{
		list <String> objectNames = new list <String>();
		map <String,String> mapClassNameToSimplifiedName = new map <String,String>();
		
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectFeature',accounting_feature__c.SObjectType.getDescribe().getLabel());
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectSoftwarePlan',Accounting_Softwareplan__c.SObjectType.getDescribe().getLabel());
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectSubscriber',Accounting_Subscriber__c.SObjectType.getDescribe().getLabel());
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectFeatureRate',Accounting_Featurerate__c.SObjectType.getDescribe().getLabel());
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectSoftwarePlanVer',Accounting_SoftwarePlanVersion__c.SObjectType.getDescribe().getLabel());
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectBillingAccount',Accounting_Billingaccount__c.SObjectType.getDescribe().getLabel());
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectSubscription',Accounting_Subscription__c.SObjectType.getDescribe().getLabel());
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectAcctingInvoice',Accounting_Invoice__c.SObjectType.getDescribe().getLabel());
		mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectLineItem',Accounting_LineItems__c.SObjectType.getDescribe().getLabel());
        mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectBillingContactInfo',Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel());
        mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectPaymentMethod',Accounting_PaymentMethod__c.SObjectType.getDescribe().getLabel());
        mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectBillingAccAdmin',Accounting_BillingAccountAdmin__c.SObjectType.getDescribe().getLabel());
        mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectPaymentRec',Accounting_Paymentrecord__c.SObjectType.getDescribe().getLabel());
        mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectSubcriptionAdj',Accounting_SubscriptionAdjustment__c.SObjectType.getDescribe().getLabel());
        mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectCreditLine',Accounting_CreditLine__c.SObjectType.getDescribe().getLabel());
        mapClassNameToSimplifiedName.put('hqInt_BatchFetchObjectCreditAdjustment',Accounting_CreditAdjustment__c.SObjectType.getDescribe().getLabel());
        
		
		objectNames.add(accounting_feature__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_BillingAccountAdmin__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_Softwareplan__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_Subscriber__c.SObjectType.getDescribe().getLabel());
		
		objectNames.add(Accounting_Featurerate__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_SoftwarePlanVersion__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_PaymentMethod__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_BillingContactInfo__c.SObjectType.getDescribe().getLabel());

		objectNames.add(Accounting_Paymentrecord__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_Billingaccount__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_Subscription__c.SObjectType.getDescribe().getLabel());
		objectNames.add(Accounting_Invoice__c.SObjectType.getDescribe().getLabel());

        objectNames.add(Accounting_LineItems__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_SubscriptionAdjustment__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_CreditLine__c.SObjectType.getDescribe().getLabel());
        objectNames.add(Accounting_CreditAdjustment__c.SObjectType.getDescribe().getLabel());
        
		batchClassJob = null;
		AsyncApexJob[] batchClassJobList = [SELECT id,JobItemsProcessed,TotalJobItems,createdDate,ApexClass.id,ApexClass.Name,Status,CompletedDate
											FROM AsyncApexJob 
											WHERE ApexClass.Name in :mapClassNameToSimplifiedName.keyset() 
											ORDER BY createdDate desc ];
		
		phase2Jobs = new list <JobWrapper>();
		set <id> classesAddedToList = new set <id>();									
		phase2Running = false;

		//Create empty wrapper

		for(String jobName : objectNames)
		{
			JobWrapper jobWrapper = new jobWrapper();
			jobWrapper.jobName = jobName;
			phase2Jobs.add(jobWrapper);
		}

		for(AsyncApexJob asyncApexJob : batchClassJobList)
		{
			if(!classesAddedToList.contains(asyncApexJob.ApexClass.id))
			{
				JobWrapper jobWrapper;
				for(JobWrapper job : phase2Jobs)
				{
					if(job.jobName == mapClassNameToSimplifiedName.get(asyncApexJob.ApexClass.Name))
					{
						jobWrapper = job;
						break;	
					}
				}
				//jobWrapper.jobName = mapClassNameToSimplifiedName.get(asyncApexJob.ApexClass.Name);
				jobWrapper.batchClassId = asyncApexJob.ApexClass.Id;
				jobWrapper.jobItemsProcessed = asyncApexJob.JobItemsProcessed;
				jobWrapper.totalJobItems = asyncApexJob.TotalJobItems;
				if(asyncApexJob.Status == 'Holding' || asyncApexJob.Status == 'Queued' || asyncApexJob.Status == 'Preparing' || asyncApexJob.Status ==  'Processing')
				{
					phase2Running = true;
					jobWrapper.isRunning = true;	
				}
				else
					jobWrapper.isRunning = false;		
				jobWrapper.submittedDate = 	asyncApexJob.createdDate.format();
				if(asyncApexJob.completedDate != null)
					jobWrapper.completedDate = 	asyncApexJob.CompletedDate.format();
				//phase2Jobs.add(jobWrapper);

			}
			classesAddedToList.add(asyncApexJob.ApexClass.id);
		}									
		
		
	}

	public pagereference runBatchJobPhase2()
	{
		fetchRunningInstancesPhase2();
		if(!phase2Running)
			hqInt_BatchFetchObjectHelperClass.runNextBatch(1);
		fetchRunningInstancesPhase2();
		return null;
	}

	public class JobWrapper 
	{
		public String jobName{get;set;}
		public Id batchClassId{get;set;}
		public Boolean isRunning{get;set;}
		public String submittedDate{get;set;}
		public String completedDate{get;set;}
		public integer jobItemsProcessed{get;set;}
		public integer totalJobItems{get;set;}
	}
}