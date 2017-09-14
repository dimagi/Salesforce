public class FTEFileController {

    public String fileName {get; set;}
    public String csvFile {get; set;}

    public static final String CSV_LONG_EMPTY_ROW = '"","","","","","","","","","","","","","","","",""';
    public static final String CSV_SHORT_EMPTY_ROW = '"","","","","","","","","","","","","","",""';
    public static final String NEW_LINE = '\n';

    private Decimal total = 0;
    private Decimal totalUnassigned = 0;
    private Decimal[] unassignedHours;
    private Map<Id, Decimal[]> contractMap;
    private Map<Id, String> contractNameMap;
    private Integer monthDays;
    private String monthYearText;

    public FTEFileController() {
        String employeeId = ApexPages.currentPage().getParameters().get('employeeId');
        Integer employeeMonth = Integer.valueOf(ApexPages.currentPage().getParameters().get('employeeMonth'));
        Integer fteYear = 2017; // TODO ADD settings

        SFDC_Employee__c employee = [SELECT Id, Name, Unloaded_Daily_Rate__c FROM SFDC_Employee__c WHERE Id =: employeeId LIMIT 1];
        this.monthYearText = DateTime.newInstance(fteYear, employeeMonth, 1).format('MMMM yyyy');
        this.fileName = employee.Name.replaceAll(' ', '_') + '_' + this.monthYearText.replaceAll(' ', '_') + '.csv';

        List<Time_Card__c> timeCards = [SELECT Id, Client__c, Client__r.FTE_Tracker__c, Client__r.Name, Total__c, FTE_hours__c, FTE_Contract__c, FTE_Contract__r.Name,
                                        FTE_Contract__r.FTE_Tracker__c, Date__c FROM Time_Card__c
                                        WHERE Employee__c =: employeeId AND Client__c != null
                                        AND CALENDAR_YEAR(Date__c) =: fteYear AND CALENDAR_MONTH(Date__c) =: employeeMonth
                                        ORDER BY Client__r.Name];

        this.monthDays = Date.daysInMonth(fteYear, employeeMonth);
        this.unassignedHours = new Decimal[monthDays];
        this.contractMap = new Map<Id, Decimal[]>();
        this.contractNameMap = new Map<Id, String>();

        for (Time_Card__c timeCard : timeCards) {
            Decimal loggedTime = (timeCard.Total__c != null ? timeCard.Total__c : 0);
            Decimal movedTime = (timeCard.FTE_hours__c != null ? timeCard.FTE_hours__c : 0);
            // "Moved from" part
            calculateLoggedTime(timeCard.Client__r.FTE_Tracker__c == 'Yes', timeCard.Client__c, timeCard.Client__r.Name, (loggedTime - movedTime), timeCard.Date__c.day());
            // If no FTE Tag values we don't need to process moved hours
            if (timeCard.FTE_Contract__c == null || movedTime == 0) {
                continue;
            }
            // "Moved to" part
            calculateLoggedTime(timeCard.FTE_Contract__r.FTE_Tracker__c == 'Yes', timeCard.FTE_Contract__c, timeCard.FTE_Contract__r.Name, movedTime, timeCard.Date__c.day());
        }

        generateCsv(employee.Name, employeeMonth, fteYear);
    }

    private void calculateLoggedTime(Boolean fteTracker, Id clientId, String clientName, Decimal loggedHours, Integer day) {
        this.contractNameMap.put(clientId, clientName);

        if (fteTracker == true) {
            if (!this.contractMap.containsKey(clientId)) {
                this.contractMap.put(clientId, new Decimal[this.monthDays]);
            }
            Decimal[] decimalMap = this.contractMap.get(clientId);
            if (decimalMap[day - 1] != null) {
                decimalMap[day - 1] += loggedHours;
            } else {
                decimalMap[day - 1] = loggedHours;
            }
            total += loggedHours;
        } else {
            if (unassignedHours[day - 1] != null) {
                unassignedHours[day - 1] += loggedHours;
            } else {
                unassignedHours[day - 1] = loggedHours;
            }
            totalUnassigned += loggedHours;
        }
    }

    private void generateCsv(String emplName, Integer Year, Integer month) {
        this.csvFile = CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Employee Name",';
        this.csvFile += '"' + emplName + '",';
        this.csvFile += CSV_SHORT_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Period of Time",';
        this.csvFile += '"' + this.monthYearText + '",';
        this.csvFile += CSV_SHORT_EMPTY_ROW + NEW_LINE;
        this.csvFile += CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Projects",';
        for (Integer i = 1; i <= 16; i++) {
             addCsvCell(String.valueOf(i), i, 16);
        }

        for (Id contractId : contractMap.keySet()) {
            Decimal[] records = contractMap.get(contractId);
            this.csvFile += '"' + contractNameMap.get(contractId) + '",';
            for (Integer i = 0; i < 16; i++) {
                addCsvCell(records[i] != null ? String.valueOf(records[i]).replaceFirst('/.', ',') : '0', i, 15);
            }
        }
        this.csvFile += '"Overhead",';
        for (Integer i = 0; i < 16; i++) {
            addCsvCell(unassignedHours[i] != null ? String.valueOf(unassignedHours[i]).replaceFirst('/.', ',') : '0', i, 15);
        }

        this.csvFile += CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Projects",';
        for (Integer i = 17; i <= monthDays; i++) {
             addCsvCell(String.valueOf(i), i, monthDays);
        }

        for (Id contractId : contractMap.keySet()) {
            Decimal[] records = contractMap.get(contractId);
            this.csvFile += '"' + contractNameMap.get(contractId) + '",';
            for (Integer i = 16; i < monthDays; i++) {
                addCsvCell(records[i] != null ? String.valueOf(records[i]).replaceFirst('/.', ',') : '0', i, monthDays - 1);
            }
        }
        this.csvFile += '"Overhead",';
        for (Integer i = 16; i < monthDays; i++) {
            addCsvCell(unassignedHours[i] != null ? String.valueOf(unassignedHours[i]).replaceFirst('/.', ',') : '0', i, monthDays - 1);
        }

        this.csvFile += CSV_LONG_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Total Assigned",';
        this.csvFile += '"' + total + '",';
        this.csvFile += CSV_SHORT_EMPTY_ROW + NEW_LINE;
        this.csvFile += '"Total Overhead",';
        this.csvFile += '"' + totalUnassigned + '",';
        this.csvFile += CSV_SHORT_EMPTY_ROW + NEW_LINE;
    }

    private void addCsvCell(String val, Integer countValue,  Integer limitValue) {
         if (countValue != limitValue) {
            this.csvFile += '"' + val + '",';
        } else {
            this.csvFile += '"' + val + '"'+ NEW_LINE;
        }
    }
}