/**
 * Generic class for flagging all Batch job errors from last 24 hours.
 */
public class GenericErrorMessangerBatch implements Database.Batchable<AsyncApexJob>, Database.Stateful {

    private DateTime lastJobDateTime;
    private DateTime currentRunTime;
    private List<String> errorMessages;

    public GenericErrorMessangerBatch() {
        BatchDefaultSettings__c batchSettings = BatchDefaultSettings__c.getOrgDefaults();
        this.lastJobDateTime = batchSettings.Last_Batch_Error_Check_Date__c;
        if (this.lastJobDateTime == null) {
            this.lastJobDateTime = DateTime.now().addHours(-24);
        }
        this.currentRunTime = DateTime.now();
        this.errorMessages = new List<String>();
    }

    public List<AsyncApexJob> start(Database.BatchableContext BC) {
        return [SELECT Id, ApexClassID, JobItemsProcessed, TotalJobItems, ExtendedStatus, Status, NumberOfErrors, CompletedDate, CreatedDate FROM AsyncApexJob WHERE
                                CompletedDate >=: this.lastJobDateTime
                                AND (Status IN ('Aborted', 'Failed') OR (Status = 'Completed' AND ExtendedStatus != null AND ExtendedStatus != ''))
                                ORDER BY createdDate DESC]; // we also loading (Status = 'Completed' AND ExtendedStatus != null AND ExtendedStatus != '') because we can have error in finish methods
    }

    public void execute(Database.BatchableContext BC, List<AsyncApexJob> scope) {
        Set<Id> classSet = new Set<Id>();
        for (AsyncApexJob jobInfo : scope) {
            classSet.add(jobInfo.ApexClassID);
        }

        Map<Id, ApexClass> classMapping = new Map<Id, ApexClass> ([SELECT Id, Name FROM ApexClass WHERE Id IN: classSet]);
        for (AsyncApexJob jobInfo : scope) {
            errorMessages.add('<tr><td>' + classMapping.get(jobInfo.ApexClassID).Name + '</td>' +
                              '<td>' + jobInfo.Status + '</td>' +
                              '<td>' + jobInfo.ExtendedStatus + '</td>' +
                              '<td>' + jobInfo.NumberOfErrors + '</td>' +
                              '<td>' + jobInfo.CompletedDate + '</td></tr>');
        }
    }

    public void finish(Database.BatchableContext BC) {
        BatchDefaultSettings__c batchSettings = BatchDefaultSettings__c.getOrgDefaults();
        batchSettings.Last_Batch_Error_Check_Date__c = this.currentRunTime;
        update batchSettings;

        if (this.errorMessages.size() > 0) {
            String message = '<table border="1"><tr><th>Class Name</th><th>Status</th><th>Extended Status</th><th>Number Of Errors</th><th>Completed Date</th></tr>';
            for (String tableLine : this.errorMessages) {
                message += tableLine;
            }
            message += '</table>';

            if (!Test.isRunningTest()) {
                EmailHelper.sendEmail(batchSettings.Error_Emails__c.split(','), 'Generic Error Messanger', message);
            }
        }
    }
}