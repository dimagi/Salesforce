public class FTEFileController {

    public String fileName {get; set;}
    public String csvFile {get; set;}

    public FTEFileController() {
        String employeeId = ApexPages.currentPage().getParameters().get('employeeId');
        Integer employeeMonth = Integer.valueOf(ApexPages.currentPage().getParameters().get('employeeMonth'));

        FTETimeCardGenerator generator = new FTETimeCardGenerator(employeeMonth, employeeId);
        generator.generateMonthTimeCards();
        generator.generateCsv();
        this.fileName = generator.fileName;
        this.csvFile = generator.csvFile;
    }

}