@isTest(SeeAllData=true)
public class ProjectReportOutControllerTest {

    static testMethod void ProjectReportOutControllerTest1() {
        ProjectReportOutController proObj=new ProjectReportOutController();
        proObj.initAction();
        proObj.getProContracts();
        proObj.getProjectsList();

        proObj.getProjectsForFinancialTab();
        proObj.loadContractBudgetAndSpentData();

        //proObj.getAllProjectList();
        List<ProjectReportOutController.PROProject> contractList= proObj.getProjectsList();
        proObj.contractIdName.put(contractList[0].contract.id,contractList[0].contract);
        proObj.contractId=contractList[0].contract.id;

        proObj.loadProjectReport();
        //Return false
        proObj.validData();
        
        proObj.status = 'Red';
        proObj.pro.PM_email__c = 'akanksha@gmail.com';
        proObj.pro.Report_Out_Date__c=Date.newInstance(2014, 12, 25);
        proObj.save();
        
        proObj.submitAnother();
        proObj.authenticateButton();
        
        List<selectoption> objList=proObj.StatusList;
        
        ProjectReportOutController.getRandomNonce();
    }

    static testMethod void ProjectReportOutControllerTest2() {
        ProjectReportOutController proObj=new ProjectReportOutController();
        List<ProjectReportOutController.PROProject> contractList= proObj.getProjectsList();
        proObj.selectedProjectId=contractList[0].contract.id;
        
        //proObj.selectedProjectId=contractList[0].id;
        proObj.fillProjectDetails();
        
        //Return False
        proObj.ValidateProject();
        
        proObj.saveProject();
        proObj.currentLoginEmail='aakansha@gmail.com';
        proObj.AddMe();

        proObj.AddContact();
        proObj.RemoveContact();
        proObj.currentLoginEmail='ltse@dimagi.com';
        proObj.AddMe();
        proObj.AddEmail();
        proObj.RemoveEmail();
        proObj.addProjectToUserList();
        proObj.removeProjectFromUserList();
        proObj.SendEmail(contractList[0].contract.id);
        //proObj.financialContractId = contractList[0].contract.id;

        proObj.seachProjectName = 'proj';
        proObj.searchProject();

        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Mustafa Turab',
            Salary__c = 5000,
            Exchange_Rate__c = 10
        );
        insert employeeObj;

        Time_Card__c timeCardObj1 = new Time_Card__c(
            Date__c = Date.today().addMonths(-1),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialCintractElement
        );
        insert timeCardObj1;
        Time_Card__c timeCardObj2 = new Time_Card__c(
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId
        );
        insert timeCardObj2;
        Time_Card__c timeCardObj3 = new Time_Card__c(
            Date__c = Date.today().addMonths(-3),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId
        );
        insert timeCardObj3;
        Time_Card__c timeCardObj4 = new Time_Card__c(
            Date__c = Date.today().addMonths(-4),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId
        );
        insert timeCardObj4;
        Time_Card__c timeCardObj5 = new Time_Card__c(
            Date__c = Date.today().addMonths(-5),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId
        );
        insert timeCardObj5;
        Time_Card__c timeCardObj6 = new Time_Card__c(
            Date__c = Date.today().addMonths(-6),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId
        );
        insert timeCardObj6;

        proObj.getProjectsForFinancialTab();
        proObj.loadContractBudgetAndSpentData();
    }
}