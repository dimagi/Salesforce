/**
 * Extension controller. Returns a full list on Archived history for given employee record.
 * History in SF is archved after 18 moths. That's why we added for now custom related list.
 * This is remporary, in future we should replace this feature with Field Audit Trails.
 * Notice security settings, object read access hould be disabled in Profiles.
 * Additional security should be enable field cisibility only for correct profiles.
 */
public with sharing class EmployeeHistoryArchiveController {

    private SFDC_Employee__c employee;

    public Map<String, String> userNameMap { get; set; }

    public EmployeeHistoryArchiveController(ApexPages.StandardController stdController) {
        this.employee = (SFDC_Employee__c) stdController.getRecord();
        this.userNameMap = new Map<String, String>();
    }

    public List<EmployeeArchiveWrapper> getEmployeeArchivedHistory() {
        Set<String> loadedHistoryRecords = new Set<String>();
        Map<Id, Employee_History_Archive__c> result = new Map<Id, Employee_History_Archive__c> ([SELECT Employee_Id__c, History_Field_Name__c, History_Id__c, History_User_Id__c,
                                                                                                 History_Is_Deleted__c, History_New_Value__c, History_Old_Value__c, History_Created_Date__c
                                                                                                 FROM Employee_History_Archive__c
                                                                                                 WHERE Employee_Id__c =: this.employee.Id ORDER BY History_Created_Date__c DESC]);

        List<Employee_History_Archive__c> finalResultArchive = new List<Employee_History_Archive__c>();
        List<EmployeeArchiveWrapper> finalResultHistory = new List<EmployeeArchiveWrapper>();
        if (result.size() > 0) {
            for (Employee_History_Archive__c record : result.values()) {
                loadedHistoryRecords.add(record.History_Id__c);
            }

            for (UserRecordAccess userRecordAccess : [SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND RecordId IN: result.keySet()]) {
                if (userRecordAccess.HasReadAccess == true) {
                    finalResultArchive.add(result.get(userRecordAccess.RecordId));
                }
            }
        }

        Set<String> userSet = new Set<String>();
        // We load also data from original history to be sure latest changes will be visible for financial users
        Map<Id, SFDC_Employee__History> emplHistoryRecords = new Map<Id, SFDC_Employee__History> ([SELECT Id, IsDeleted, ParentId, Field, OldValue, NewValue,
                                                                     CreatedById, CreatedDate FROM SFDC_Employee__History
                                                                     WHERE ParentId =: this.employee.Id
                                                                     AND CreatedDate >: DateTime.now().addDays(-7)
                                                                     AND Id NOT IN: loadedHistoryRecords]);
        for (UserRecordAccess userRecordAccess : [SELECT RecordId, HasReadAccess FROM UserRecordAccess
                                                  WHERE UserId =: UserInfo.getUserId()
                                                  AND RecordId IN: emplHistoryRecords.keySet()]) {
            if (userRecordAccess.HasReadAccess == true) {
                SFDC_Employee__History historyRecord = emplHistoryRecords.get(userRecordAccess.RecordId);
                userSet.add(historyRecord.CreatedById);
                finalResultHistory.add(new EmployeeArchiveWrapper(EmployeeArchiveManager.buildArchiveRecord(historyRecord.ParentId, historyRecord.Field, historyRecord.Id,
                                                                            historyRecord.IsDeleted,historyRecord.NewValue, historyRecord.OldValue,
                                                                            historyRecord.CreatedDate, historyRecord.CreatedById)));
            }
        }


        for (Employee_History_Archive__c record : finalResultArchive) {
            userSet.add(record.History_User_Id__c);
            finalResultHistory.add(new EmployeeArchiveWrapper(record));
        }
        finalResultHistory.sort();

        this.userNameMap = new Map<String, String>();
        for (User u : [SELECT Id, Name FROM User WHERE Id IN: userSet]) {
            this.userNameMap.put(u.Id, u.Name);
        }
        this.userNameMap.put(null, '');

        return finalResultHistory;
    }

    public class EmployeeArchiveWrapper implements Comparable {

        public Employee_History_Archive__c record { get ; set; }

        public EmployeeArchiveWrapper(Employee_History_Archive__c record) {
            this.record = record;
        }

        public Integer compareTo(Object compareTo) {
            EmployeeArchiveWrapper compareToWrapper = (EmployeeArchiveWrapper) compareTo;

            if (record.History_Created_Date__c > compareToWrapper.record.History_Created_Date__c) {
                return -1;
            }
            return 1;
        }
    }
}