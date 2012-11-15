public with sharing class TestSyncController {

    public void runSync() {
    	FogBugzSynchronizer synchronizer = new FogBugzSynchronizer();
    	synchronizer.synchronize();
    	
    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info,
    	                                           'Check the opportunities in SF to see if they were updated, ' +
    	                                           'and check FB to see if the externalBugId was set for cases created in FB'));
    }
}