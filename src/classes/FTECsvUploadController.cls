/**
 * CSV File Upload controller.
 */
public class FTECsvUploadController extends FTEController {

    public static final String COLUMN_SEPARATOR = ',';

    public Blob fileContent { get; set; }
    public String fileName { get; set; }
    public Pagination fteStatusPagination { get; set; }
    public Map<Id, FTEUploadData> records { get; set; }

    private Map<String, SFDC_Employee__c> employeeMap;

    public FTECsvUploadController() {
        this.fteStatusPagination = new Pagination();
        loadWorkCardJobStatus();
    }

    public List<FTE_Data_Record_Status__c> getFTEStatusRecords() {
        List<FTE_Data_Record_Status__c> result = [SELECT Status__c, Status_Message__c, Line_Number__c, Line_Number_Text__c FROM FTE_Data_Record_Status__c
                                                    ORDER BY Line_Number__c LIMIT : this.fteStatusPagination.pageSize OFFSET : this.fteStatusPagination.getOffsetValue()];
        this.fteStatusPagination.handleResulSize([SELECT count() FROM FTE_Data_Record_Status__c]);
        return result;
    }

    public void removeFTEDataStatusRecords() {
        List<FTE_Data_Record_Status__c> toRemove = [SELECT Id FROM FTE_Data_Record_Status__c];
        if (toRemove.size() > 0) {
            delete toRemove;
            ApexPages.getMessages().clear();
        }
    }

    public Boolean processFTEDataRecords(Integer year) {
         system.debug(this.records.values());
        loadWorkCardJobStatus();
        if (this.workCardJobStatus.isRunning == false) {
            removeFTEDataStatusRecords(); // Remove status of last batch upload

            if (!Test.isRunningTest()) {
                Database.executeBatch(new FTEHoursUploadBatch(this.records.values(), year), 1);
            } else {
                Database.executeBatch(new FTEHoursUploadBatch(this.records.values()), 200); // no more then one batch execute can be invoked from test
            }

            loadWorkCardJobStatus();
            ApexPages.getMessages().clear();
            return true;
        }
        return false;
    }

    public PageReference parseCsvFile() {
        loadWorkCardJobStatus();
        if (this.workCardJobStatus.isRunning == true) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot upload csv file. FTE Tracker is calculating time.'));
            return null;
        }

        if (this.fileName == null || this.fileName == '' || this.fileContent == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Choose file from your computer to upload.'));
            return null;
        }

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

        if (!validateFileData(fileRows)) {
            return null;
        }

        String contractName;
        DContract__c fteContract = null;
        Integer columnsToSkip = 0;

        // Validate headers
        String headers = fileRows.get(0);
        fileRows.remove(0);
        Integer year = -1;

        Boolean contractNameLoaded = false;
        List<String> columnHeders = splitLine(headers);
        Pattern csvPattern = Pattern.compile('([1-9]{1}|[0]{1}[1-9]{1}|[1]{1}[0-2]{1})/[2-9]{1}[0-9]{3}');
        List<Integer> monthMapping = new List<Integer>();

        for (String cellValue : columnHeders) {
            String strHelper = parseCell(cellValue);
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

                        if (!validateColumnHeaderData(year, csvYear, csvMonth, lineNum, strHelper, monthMapping)) {
                            return null;
                        }
                        monthMapping.add(csvMonth);

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

        fteContract = getContract(contractName);
        if (fteContract == null) {
            return null;
        }

        csvPattern = Pattern.compile('(\\d*\\.\\d+)|(\\d+\\.\\d*)');
        this.records = new Map<Id, FTEUploadData>();
        loadEmployeeMap();

        Boolean wasData = false;
        for (String line : fileRows) {
            lineNum++;
            List<String> dataCell = splitLine(line);

            String employeeName =  parseCell(dataCell.get(columnsToSkip));
            if (!validateEmployee(employeeName, lineNum)) {
                return null;
            }

            FTEUploadData emplDataRec = null;
            Id emplId = this.employeeMap.get(employeeName).Id;
            if (this.records.containsKey(emplId)) {
                emplDataRec = this.records.get(emplId);
            } else {
                emplDataRec = new FTEUploadData(emplId, fteContract.Id, employeeName, contractName, year);
            }

            for (Integer i = (1 + columnsToSkip); i < monthMapping.size() + 1 + columnsToSkip; i++) {
                String strHelper = '';
                if (dataCell.size() > i) {
                    strHelper = parseCell(dataCell.get(i));
                }

                Integer index = monthMapping.get(i - 1 - columnsToSkip);
                if (strHelper.isNumeric() || csvPattern.matcher(strHelper).matches()) {
                    emplDataRec.addMonthTime(index, Decimal.valueOf(strHelper));
                    wasData = true;
                } else if (!String.isBlank(strHelper)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'bad number format - ' + strHelper));
                    return null;
                }
            }
            this.records.put(emplId, emplDataRec);
        }

        if (wasData == false || this.records.size() == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Uploaded file does not contain data'));
            return null;
        }

        Boolean success = processFTEDataRecords(year);
        if (success) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'CSV file ' + fileName + ' was parsed. Upload job was scheduled, please wait for results.'));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot upload csv file. FTE Tracker is calculating time.'));
        }

        return null;
    }

    private String parseCell(String cellValue) {
        String tmpCellValue = cellValue.trim();
        return tmpCellValue.startsWith('"') && tmpCellValue.endsWith('"') ? tmpCellValue.substring(1, tmpCellValue.length() - 1).trim() : tmpCellValue;
    }

    private DContract__c getContract(String contractName) {
        List<DContract__c> contracts = [SELECT Id, Name FROM DContract__c WHERE Name =: contractName];
        if (contracts.size() > 0) {
            return contracts.get(0);
        }
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot find contract with name - ' + contractName));
        return null;
    }

    private List<String> splitLine(String fileRow) {
        return fileRow.split(COLUMN_SEPARATOR);
    }

    private Boolean validateFileData(List<String> fileRows) {
        if (fileRows.size() == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'File is empty.'));
            return false;
        } else if (fileRows.size() == 1) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'File contains only one row, no data.'));
            return false;
        }
        return true;
    }

    private Boolean validateEmployee(String employeeName, Integer lineNum) {
        if (!this.employeeMap.containsKey(employeeName)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'cannot find employee with name - ' + employeeName));
            return false;
        }
        return true;
    }

    private Boolean validateColumnHeaderData(Integer year, Integer csvYear, Integer csvMonth, Integer lineNum, String strHelper, List<Integer> loadedMonths) {
        if (year != csvYear) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'csv file can contain data only for one year - ' + strHelper));
            return false;
        }
        if (csvMonth > 12) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'month can not be more than 12  - ' + csvMonth));
            return false;
        }
        if (loadedMonths.contains(csvMonth)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'duplicated month - ' + strHelper));
            return false;
        }
        return true;
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