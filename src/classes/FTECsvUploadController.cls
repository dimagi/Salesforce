/**
 * CSV File Upload controller.
 */
public class FTECsvUploadController {

    public static final String COLUMN_SEPARATOR = '\t';

    public Blob fileContent { get; set;}
    public String fileName { get; set;}

    public Pagination fteDataPagination { get; set;}
    public Pagination fteStatusPagination { get; set;}

    public JobWrapper fteJobStatus { get; set;}

    private Set<String> employeeNameSet;
    private Map<String, SFDC_Employee__c> employeeMap;

    public FTECsvUploadController() {
        this.fteDataPagination = new Pagination();
        this.fteStatusPagination = new Pagination();
        loadWorkCardJobStatus();
    }

    public List<FTE_Data_Record__c> getFTEDataRecords() {
        List<FTE_Data_Record__c> result = [SELECT Year__c, Year_Text__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c,
                                            Month_10__c, Month_11__c, Month_12__c, Message__c, Employee__c, Employee__r.Name, Processed__c, Contract__c, Contract__r.Name, Line_Number__c
                                            FROM FTE_Data_Record__c ORDER BY Line_Number__c LIMIT : this.fteDataPagination.pageSize OFFSET : this.fteDataPagination.getOffsetValue()];
        this.fteDataPagination.handleResulSize([SELECT count() FROM FTE_Data_Record__c]);
        return result;
    }

    public List<FTE_Data_Record_Status__c> getFTEStatusRecords() {
        List<FTE_Data_Record_Status__c> result = [SELECT Status__c, Status_Message__c, Line_Number__c, Line_Number_Text__c FROM FTE_Data_Record_Status__c
                                                    ORDER BY Line_Number__c LIMIT : this.fteStatusPagination.pageSize OFFSET : this.fteStatusPagination.getOffsetValue()];
        this.fteStatusPagination.handleResulSize([SELECT count() FROM FTE_Data_Record_Status__c]);
        return result;
    }

    public void removeFTEDataRecords() {
        List<FTE_Data_Record__c> toRemove = [SELECT Id FROM FTE_Data_Record__c];
        if (toRemove.size() > 0) {
            delete toRemove;
            ApexPages.getMessages().clear();
        }
    }

    public void removeFTEDataStatusRecords() {
        List<FTE_Data_Record_Status__c> toRemove = [SELECT Id FROM FTE_Data_Record_Status__c];
        if (toRemove.size() > 0) {
            delete toRemove;
            ApexPages.getMessages().clear();
        }
    }

    public void loadWorkCardJobStatus() {
        this.fteJobStatus = FTETrackerHelper.loadWorkCardJobStatus();
    }

    public void processFTEDataRecords() {
        loadWorkCardJobStatus();
        if (this.fteJobStatus.isRunning == false && this.fteDataPagination.resultSize > 0) {
            removeFTEDataStatusRecords(); // Remove status of last batch upload

            if (!Test.isRunningTest()) {
                Database.executeBatch(new FTEHoursUploadBatch(), 1);
            } else {
                Database.executeBatch(new FTEHoursUploadBatch()); // no more then one batch execute can be invoked from test
            }

            loadWorkCardJobStatus();
            ApexPages.getMessages().clear();
        }
    }

    public PageReference goToEmployeeListView() {
        return Page.FTE_Employee_List_View;
    }

    public PageReference parseCsvFile() {
        loadWorkCardJobStatus();
        if (this.fteJobStatus.isRunning == true) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot upload csv file. FTE Tracker is calculating time.'));
            return null;
        }

        if (this.fileName == null || this.fileName == '' || this.fileContent == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Choose file from your computer to upload.'));
            return null;
        }

        removeFTEDataRecords();
        this.employeeNameSet = new Set<String>();

        List<FTE_Data_Record__c> fteData = new List<FTE_Data_Record__c>();
        List<String> fileRows;

        try {
            fileRows = fileContent.toString().replaceAll('\r', '').replaceAll('\\u00A0', ' ').split('\n'); //remove all \r to be sure we will not have some bar elements
        } catch (Exception e) {
            fileRows = FTETrackerHelper.blobToString(fileContent, 'ISO 8859-2').replaceAll('\r', '').replaceAll('\\u00A0', ' ').split('\n'); // Try parse if file is not valid UTF-8
        }
        Integer lineNum = 1;

        // Remove empty rows to load contract name, 
        lineNum += removeEmptyRows(fileRows);

        if (fileRows.size() == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'File is empty.'));
            return null;
        } else if (fileRows.size() == 1) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'File contains only one row, no data.'));
            return null;
        }

        String contractName;
        DContract__c fteContract = null;
        Integer columnsToSkip = 0;

        // Validate headers
        String headers = fileRows.get(0);
        fileRows.remove(0);
        Integer month = 1;
        Integer year = -1;
        Boolean contractNameLoaded = false;
        List<String> columnHeders = headers.split(COLUMN_SEPARATOR);
        Pattern csvPattern = Pattern.compile('([1-9]{1}|[0]{1}[1-9]{1}|[1]{1}[0-2]{1})/[2-9]{1}[0-9]{3}');
        for (String cellValue : columnHeders) {
            String strHelper = cellValue.replaceAll('"','').trim();
            if (String.isBlank(strHelper)) {
                columnsToSkip++;
            } else {
                if (contractNameLoaded) {
                    if (csvPattern.matcher(strHelper).matches()) {
                        List<String> numbers = strHelper.split('/');
                        Integer csvMonth = Integer.valueOf(numbers.get(0));
                        Integer csvYear = Integer.valueOf(numbers.get(1));
                        if (year == -1) {
                            year = csvYear;
                        }

                        if (year != csvYear || month != csvMonth || month > 12) {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'wrong date order - ' + strHelper));
                            return null;
                        }
                        month++;
                    } else {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'wrong date month/year format - ' + strHelper));
                        return null;
                    }
                } else {
                    contractNameLoaded = true;
                    contractName = strHelper.trim();
                }
            }
        }

        List<DContract__c> contracts = [SELECT Id, Name FROM DContract__c WHERE Name =: contractName];
        if (contracts.size() > 0) {
            fteContract = contracts.get(0);
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find contract with name - ' + contractName));
            return null;
        }

        csvPattern = Pattern.compile('(\\d*\\.\\d+)|(\\d+\\.\\d*)');
        List<FTE_Data_Record__c> records = new List<FTE_Data_Record__c>();
        loadEmployeeMap();

        for (String line : fileRows) {
            lineNum++;
            List<String> dataCell = line.replaceAll('"', '').split(COLUMN_SEPARATOR);

            String employeeName = dataCell.get(columnsToSkip).replaceAll('"','').trim();
            if (!this.employeeMap.containsKey(employeeName)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'cannot find employee with name - ' + employeeName));
                return null;
            }
            if (this.employeeNameSet.contains(employeeName)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'duplicated employee name - ' + employeeName));
                return null;
            }
            this.employeeNameSet.add(employeeName);

            SObject sObj = new FTE_Data_Record__c();
            for (Integer i = 1 + columnsToSkip; i < 13 + columnsToSkip; i++) {
                String strHelper = '';
                if (dataCell.size() > i) {
                    strHelper = dataCell.get(i).trim();
                }

                if (strHelper.isNumeric() || csvPattern.matcher(strHelper).matches()) {
                    sObj.put('Month_' + (i - columnsToSkip) + '__c', Decimal.valueOf(strHelper));
                } else if (String.isBlank(strHelper)) {
                    sObj.put('Month_' + (i - columnsToSkip) + '__c',-1);
                } else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'bad number format - ' + strHelper));
                    return null;
                }
            }
            FTE_Data_Record__c rec = (FTE_Data_Record__c) sObj;
            rec.Year__c = year;
            rec.Contract__c = fteContract.Id;
            rec.Employee__c = this.employeeMap.get(employeeName).Id;
            rec.Line_Number__c = lineNum; // we want order data in same way as it is in csv file
            rec.Message__c = contractName + ' ' + employeeName + ' : ' + lineNum;
            records.add(rec);
        }

        if (records.size() > 0) {
            insert records;
        }

        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'CSV file ' + fileName + ' was parsed.'));
        return null;
    }

    private void loadEmployeeMap() {
        if (this.employeeMap == null) {
            this.employeeMap = new Map<String, SFDC_Employee__c>();
            for (SFDC_Employee__c emp : [SELECT Id, Name FROM SFDC_Employee__c]) {
                this.employeeMap.put(emp.Name, emp);
            }
        }
    }

    private Integer removeEmptyRows(List<String> fileRows) {
        Integer removedRows = 0;
        Boolean foundFirstRow = false;

        while (!foundFirstRow) {
            if (!fileRows.isEmpty()) {
                String line = fileRows.get(0);
                if (line.replaceAll('(,|")','').trim().length() == 0) { // empty line
                    fileRows.remove(0);
                    removedRows++;
                } else {
                    foundFirstRow = true;
                }
            } else {
                break;
            }
        }

        return removedRows;
    }
}