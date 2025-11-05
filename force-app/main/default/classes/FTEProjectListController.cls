/**
 * Controller for FTE_Project_List_View, allows to manage FTE contracts.
 * Test class - FTETrackerTest
 */
public class FTEProjectListController extends FTEController {

    public Id contractId { get; set;}
    public DContract__c contract {get;set;} 
    public list<DContract__c> list_contracts {get;set;}
    public boolean Isexportexcel{get;set;}
    public boolean Isexportpdf{get;set;}
    public string modevar{get;set;}

    public FTEProjectListController() {
        contract = new DContract__c();
        contract.Project_Years__c = String.valueOf(Date.today().year());
        list_contracts = new list<DContract__c>();
        ListToSubmit();
    }

    public void ListToSubmit() { //AND Status__c = 'Active'
        
        date filteredDate;
        filteredDate = date.newInstance(Integer.valueOf(contract.Project_Years__c ), 01, 01);
        list_contracts = [SELECT Id, Name, Contract_End_Date__c, Project_Manager__c, Project_Manager__r.Name, Contract_Start_Date__c, Status__c, FTE_Tracker__c FROM DContract__c WHERE FTE_Tracker__c = 'Yes' 
                                     AND  (Status__c = 'Active' OR Status__c = 'Complete')  
                                     AND Contract_End_Date__c >=: filteredDate ORDER BY Name];
      
    }
    
    public PageReference export_projects_excel(){
        ListToSubmit();
        Isexportexcel =  true;
        Isexportpdf = false;
        ListToSubmit();
        //pagereference page = new pagereference('/apex/FTE_exportprojectsinTabs');
      //  pagereference page = new pagereference('/apex/FTE_projectListExport');
        PageReference pageRef = Page.FTE_projectListExport;
        pageRef.getParameters().put('fteYear', String.valueOf(contract.Project_Years__c));
        pageRef.getParameters().put('Isexportexcel', 'true');
        modevar = 'application/vnd.ms-excel#Projectsreport.xls';
        pageRef.getParameters().put('mode', modevar);
       
        return pageRef;
    }
    
    public PageReference export_projects_pdf(){
        Isexportexcel =  false;
        Isexportpdf = true;
        ListToSubmit(); 
        pagereference page = new pagereference('/apex/FTE_ExportallProjects_PDF');
     /*   page.getParameters().put('mode', 'pdf');
        String PDFGeneratedFileName = 'ProjectsPDFreport.pdf';
        page.getHeaders().put('content-disposition', 'attachment; filename='+PDFGeneratedFileName); */
        page.getParameters().put('fteYear', String.valueOf(contract.Project_Years__c));
        return page;
    }

    public PageReference goToIndividualProjectView() {
        PageReference pageRef = Page.FTE_Individual_Project_View;
        pageref.getParameters().put('contractId', this.contractId);
      //  pageref.getParameters().put(new List<DContract__c>(), this.list_contracts);
        return pageref;
    }
}