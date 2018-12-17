/**
 * Controller used to generate FTE Time Cards as csv file body.
 */
public class FTEFileController {

    public Id employeeId { get; set;}
    public Integer exportMonth {get; set;}
    public Integer monthDays {get; set;}
    public Integer fteYear {get; set;}
    public List<FTEMonthTimeCard> employeeMonthProjects { get; set;}
    public List<Integer> exportMonthDays {get; set;}
    public String monthYearText {get; set;}
    public SFDC_Employee__c employee { get; set;}
    private Boolean downloadPage;

    public String fileName {get; set;}
    public String csvFile {get; set;}

    public FTEFileController() {
        this.downloadPage = false;
        if (ApexPages.currentPage().getUrl().contains('FTE_Download_File')) {
            this.downloadPage = true;
        }

        String yearString = ApexPages.currentPage().getParameters().get('fteYear');
        if (yearString != null && yearString.isNumeric()) {
            this.fteYear = Integer.valueOf(yearString);
        } else {
            this.fteYear = Date.today().year();
        }

        String monthString = ApexPages.currentPage().getParameters().get('month');
        if (monthString != null && monthString.isNumeric()) {
            this.exportMonth = Integer.valueOf(monthString);
        } else {
            this.exportMonth = 1; // Default January
        }

        this.monthDays = Date.daysInMonth(fteYear, this.exportMonth);
        this.exportMonthDays = new List<Integer>();
        this.monthYearText = DateTime.newInstance(fteYear, this.exportMonth, 1).format('MMMM yyyy');

        String emplId = ApexPages.currentPage().getParameters().get('employeeId');
        if (emplId != null && emplId InstanceOf Id) {
            this.employeeId = (Id) emplId;
            List<SFDC_Employee__c> emplList = [SELECT Id, Name, Hire_Date__c FROM SFDC_Employee__c WHERE Id =: this.employeeId LIMIT 1];
            if (emplList.size() > 0) {
                this.employee = emplList.get(0);
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty Employee ID'));
            if (this.downloadPage) {
                throw new CalloutException('Cannot generate file. Employee Id is empty.');
            }
        }

        if (this.downloadPage) {
            FTETimeCardGenerator generator = new FTETimeCardGenerator(this.fteyear, this.exportMonth, this.employeeId);
            generator.generateMonthTimeCards();
            generator.generateCsv();
            this.fileName = generator.fileName;
            this.csvFile = generator.csvFile;
        }
    }

    public void loadExportTimeCards() {
        if (this.employeeId == null) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Empty Employee ID'));
            return;
        }

        for (Integer i = 0; i < this.monthDays; i++) {
            this.exportMonthDays.add(i); // We need something to iterate if we want add dynamic columns on UI
        }
        if (exportMonth != null) {
            FTETimeCardGenerator generator = new FTETimeCardGenerator(this.fteYear, this.exportMonth, this.employeeId);
            this.employeeMonthProjects = generator.generateMonthTimeCards();
        }
    }

    public PageReference goToEmployeeViewFromTimeCardView() {
        PageReference pageRef = Page.FTE_Employee_View;
        pageref.getParameters().put('employeeId', this.employeeId);
        pageref.getParameters().put('fteYear', String.valueOf(this.fteYear));
        return pageRef;
    }
}