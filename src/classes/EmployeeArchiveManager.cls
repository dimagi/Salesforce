/**
 * Employee Archive Manager is class responsible for inserting new created history records. New records are added to to Employee History Archive.
 */
public class EmployeeArchiveManager {

    public static void archiveNewHistoryData() {
        archiveNewHistoryData(DateTime.now().addDays(-7));
    }

    public static void archiveNewHistoryData(DateTime rangeDate) {
        archiveNewHistoryDataFuture(rangeDate);
    }

    @future
    public static void archiveNewHistoryDataFuture(DateTime rangeDate) {
        System.debug('Future method : archiveNewHistoryData called with parameter : ' + rangeDate);
        List<Employee_History_Archive__c> archive = new List<Employee_History_Archive__c>();
        for (SFDC_Employee__History historyRecord : getHistory(rangeDate)) {
            archive.add(buildArchiveRecord(historyRecord.ParentId, historyRecord.Field, historyRecord.Id,
                                            historyRecord.IsDeleted,historyRecord.NewValue, historyRecord.OldValue,
                                            historyRecord.CreatedDate, historyRecord.CreatedById));
        }

        if (archive.size() > 0) {
            insert archive;
            System.debug('Future method : archiveNewHistoryData created : ' + archive.size() + ' records');
        }
    }

    public static Employee_History_Archive__c buildArchiveRecord(Id parentId, String fieldName, Id recId, Boolean isDeleted,
                                                                 Object objNewWValue, Object objOldValue, DateTime historyCreatedDate,
                                                                 Id historyCreatedById) {
        String newValue = valueOf(objNewWValue);
        String oldValue = valueOf(objOldValue);

        return new Employee_History_Archive__c(
                            Employee_Id__c = parentId,
                            History_Field_Name__c = fieldName,
                            History_Id__c = recId,
                            History_Is_Deleted__c = isDeleted,
                            History_New_Value__c = newValue,
                            History_Old_Value__c = oldValue,
                            History_Created_Date__c = historyCreatedDate,
                            History_User_Id__c = historyCreatedById);
    }

    public static List<SFDC_Employee__History> getHistory(DateTime rangeDate) {
        // We don't want look back all the time, we must assume that all data was added.
        Set<String> lastAddedHistoryRecords = new Set<String>();
        for (Employee_History_Archive__c archRecords : [SELECT History_Id__c FROM Employee_History_Archive__c
                                                        WHERE History_Created_Date__c >: rangeDate
                                                        ORDER BY History_Created_Date__c DESC]) {
            lastAddedHistoryRecords.add(archRecords.History_Id__c);
        }

        return [SELECT Id, IsDeleted, ParentId, Field, OldValue, NewValue,
                CreatedById, CreatedDate FROM SFDC_Employee__History
                WHERE CreatedDate >: rangeDate
                AND Id NOT IN: lastAddedHistoryRecords];
    }

    private static String valueOf(Object objValue) {
        if (objValue != null) {
            if (objValue instanceof Decimal) {
                return String.valueOf((Decimal) objValue);
            } else if (objValue instanceof Date) {
                return '' + ((Date) objValue);
            } else if (objValue instanceof DateTime) {
                return '' + ((DateTime) objValue);
            } else if (objValue instanceof Boolean) {
                return '' + ((Boolean) objValue);
            } else {
                return (String) objValue;
            }
        }

        return null;
    }
}