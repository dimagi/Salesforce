/**
 * CSV File Upload controller.
 */
public class FTECsvUploadController extends FTEController {

    public static final String COLUMN_SEPARATOR = ',';

    public Blob fileContent { get; set; }
    public String fileName { get; set; }
    public Pagination fteStatusPagination { get; set; }
    public Map<Id, FTEUploadData> records { get; set; }

    private Id contractId;
    private Set<Id> employees;
    private Decimal uploadedYear;
    private Map<String, SFDC_Employee__c> employeeMap;

    public FTECsvUploadController() {
        this.fteStatusPagination = new Pagination();
        loadWorkCardJobStatus();
    }

    public Boolean processFTEDataRecords() {
        Map<Id, FTE_Data_Record__c> mappedTemplates = new Map<Id, FTE_Data_Record__c>();
        for (FTE_Data_Record__c rec : [SELECT Id, Employee__c, Year__c,
                                       Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                       Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                       Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c, Month_Updated_6__c,
                                       Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                       FROM FTE_Data_Record__c
                                       WHERE Contract__c =: this.contractId AND Employee__c IN: this.employees AND Year__c =: this.uploadedYear]) {
            mappedTemplates.put(rec.Employee__c, rec);
        }

        List<FTE_Data_Record__c> finalDataList = new List<FTE_Data_Record__c>();
        for (FTEUploadData rec : this.records.values()) {
            finalDataList.add(rec.mergeData(mappedTemplates.get(rec.getEmployeeId())));
        }

        loadWorkCardJobStatus();
        if (this.workCardJobStatus.isRunning == false) {
            upsert finalDataList;

            if (!Test.isRunningTest()) {
                Database.executeBatch(new FTETimeAllocator(true), 1);
            } // In test we want test only parsing and how records was upserted, Time allocator has seprate tests

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
                            this.uploadedYear = csvYear;
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
        } else if (fteContract.FTE_Tracker__c != 'Yes') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,  'Contract : "' + contractName + '" is not a FTE Tracker contract, please add it to Tracker before uploading CSV Template'));
            return null;
        }
        this.contractId = fteContract.Id;

        csvPattern = Pattern.compile('(\\d*\\.\\d+)|(\\d+\\.\\d*)');
        this.records = new Map<Id, FTEUploadData>();
        this.employees = new Set<Id>();
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
            this.employees.add(emplId);
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
                if (strHelper.isNumeric() || csvPattern.matcher(strHelper).matches()) { // number 0 - ...
                    emplDataRec.addMonthTime(index, Decimal.valueOf(strHelper));
                    wasData = true;
                } else if (!String.isBlank(strHelper)) { // wrong number
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Line ' + lineNum + ' : ' + 'bad number format - ' + strHelper));
                    return null;
                } else { // blank value we must set -1 to it will mean that threshold is removed
                    emplDataRec.addMonthTime(index, -1);
                }
            }
            this.records.put(emplId, emplDataRec);
        }

        if (wasData == false || this.records.size() == 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Uploaded file does not contain data'));
            return null;
        }

        Boolean success = processFTEDataRecords();
        if (success) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'CSV file ' + fileName + ' was parsed. '
                                        + this.records.values().size() + ' records was added for ' + this.records.keySet().size() + ' employees.'));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot upload csv file. FTE Tracker is currently calculating time.'));
        }

        return null;
    }

    private String parseCell(String cellValue) {
        String tmpCellValue = cellValue.trim();
        return tmpCellValue.startsWith('"') && tmpCellValue.endsWith('"') ? tmpCellValue.substring(1, tmpCellValue.length() - 1).trim() : tmpCellValue;
    }

    private DContract__c getContract(String contractName) {
        List<DContract__c> contracts = [SELECT Id, Name, FTE_Tracker__c FROM DContract__c WHERE Name =: contractName];
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