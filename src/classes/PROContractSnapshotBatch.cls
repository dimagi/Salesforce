/*
* Batch responsible for creating the PRO Contract Snapshot custom object for projects that
* are active but do not require a report out.
*/
global class PROContractSnapshotBatch implements Database.Batchable<DContract__c>, Database.Stateful {

    public PROContractSnapshotBatch(){

    }

    global List<DContract__c> start(Database.BatchableContext context) {
       return null; //GetContract();
    }

    global void execute(Database.BatchableContext context, List<DContract__c> contracts) {
        //TODO save PRO contract snapshot
    }

    global void finish(Database.BatchableContext context) {
        // TODO send mails
    }
}