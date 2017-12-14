@isTest(SeeAllData=true)
public class ProjectReportOutControllerTest {

    static testMethod void ProjectReportOutControllerTest1() {
        ProjectReportOutController proObj = new ProjectReportOutController();
        proObj.initAction();
        proObj.getProContracts();
        proObj.getProjectsList();

        proObj.getProjectsForFinancialTab();
        proObj.loadContractBudgetAndSpentData();

        List<ProjectReportOutController.PROProject> contractList = proObj.getProjectsList();
        proObj.contractIdName.put(contractList[0].contract.id,contractList[0].contract);
        proObj.reportContractId = contractList[0].contract.id;

        proObj.loadProjectReport();
        proObj.validData();

        proObj.status = 'Red';
        proObj.pro.PM_email__c = 'akanksha@dimagi.com';
        proObj.pro.Report_Out_Date__c = Date.newInstance(2014, 12, 25);
        PageReference pagRef = proObj.save();
        
        proObj.submitAnother();
        proObj.authenticateButton();
 
        List<selectoption> objList = proObj.StatusList;

        ProjectReportOutController.getRandomNonce();
    }

    static testMethod void ProjectReportOutControllerTest2() {
        ProjectReportOutController proObj=new ProjectReportOutController();
        List<ProjectReportOutController.PROProject> contractList= proObj.getProjectsList();
        proObj.selectedProjectId=contractList[0].contract.id;

        proObj.fillProjectDetails();
        proObj.ValidateProject();
        
        proObj.saveProject();
        proObj.currentLoginEmail='aakansha@dimagi.com';
        proObj.AddMe();

        proObj.AddContact();
        proObj.RemoveContact();
        proObj.currentLoginEmail='ltse@dimagi.com';
        proObj.AddMe();
        proObj.AddEmail();
        proObj.RemoveEmail();
        proObj.addProjectToUserList();
        proObj.removeProjectFromUserList();
        proObj.sendReportEmail(contractList[0].contract.id);

        proObj.seachProjectName = 'proj';
        proObj.searchProject();

        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Mustafa Turab',
            Salary__c = 5000,
            Exchange_Rate__c = 10,
            Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24)
        );
        insert employeeObj;
        Time_Card__c timeCardObj1 = new Time_Card__c(
            Date__c = Date.today().addMonths(-1),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId,
            Total__c = 1
        );
        insert timeCardObj1;
        Time_Card__c timeCardObj2 = new Time_Card__c(
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId,
            Total__c = 1
        );
        insert timeCardObj2;
        Time_Card__c timeCardObj3 = new Time_Card__c(
            Date__c = Date.today().addMonths(-3),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId,
            Total__c = 1
        );
        insert timeCardObj3;
        Time_Card__c timeCardObj4 = new Time_Card__c(
            Date__c = Date.today().addMonths(-4),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId,
            Total__c = 1
        );
        insert timeCardObj4;
        Time_Card__c timeCardObj5 = new Time_Card__c(
            Date__c = Date.today().addMonths(-5),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId,
            Total__c = 1
        );
        insert timeCardObj5;
        Time_Card__c timeCardObj6 = new Time_Card__c(
            Date__c = Date.today().addMonths(-6),
            Employee__c = employeeObj.Id,
            Client__c = proObj.financialContractId,
            Total__c = 1
        );
        insert timeCardObj6;

        proObj.getProjectsForFinancialTab();
        proObj.loadContractBudgetAndSpentData();
    }

    /**
     * Tests for Record_of_Emergency_Data_Form__c
     */
    public static testMethod void triggerShouldUpdateEmployeePersonalData() {
        addEmployee('simple-user@test.com');
        SFDC_Employee__c emplRec = [SELECT Id FROM SFDC_Employee__c WHERE Email_Address__c = 'simple-user@test.com'];
        Record_of_Emergency_Data_Form__c redForm = new Record_of_Emergency_Data_Form__c(Employee__c = emplRec.Id, Employee_First_Name__c = 'First Name', Employee_Middle_Name__c = 'Middle Name', Business_Unit__c = 'DSI',
                                                                        Employee_Last_Name__c = 'Last Name', DOB__c = Date.newInstance(Date.today().year() - 30, 3, 3), Citizenship__c = 'France', Gender__c = 'Woman',
                                                                        Personal_Phone_Number__c = '000999111', Passport_No__c = 'poiulkj' ,Passport_Expiration_Date__c = Date.newInstance(Date.today().year() + 7, 5, 5),
                                                                        Current_Address_City__c = 'Simple City', Current_Address_Street__c = 'Other 323', Current_Address_State__c = 'New one',
                                                                        Current_Address_Country__c = 'England', Emergency_Contact__c = 'Emergency Contact', Emergency_Contact_Relationship__c = 'Child',
                                                                        Emergency_Contact_Phone__c = '333111666', Emergency_Email__c = 'p2@test.com', Emergency_Contact_Country_of_Residence__c = 'England',
                                                                        Emergency_Contact_next_of_kin__c = 'No', Local_Emergency_Contact__c = 'Local Emergency', Local_Emergency_Contact_Relationship__c = 'Other',
                                                                        Local_Emergency_Contact_Phone__c = '222222111', Local_Emergency_Email__c = 'p1@test.com',
                                                                        Local_Emerg_Cont_Country_of_Residence__c = 'United States of America (USA)', Local_Emergency_Contact_next_of_kin__c = 'Yes', Height__c = '-',
                                                                        Eye_Colour__c = 'Green', Blood_Group__c = '0', Religion_Impact__c = '1 No', Distinguishing_Features__c = '-',
                                                                        Medical_Conditions_Allergies__c = '2 No', Regular_Medication__c = '3 No', Medical_Permission__c = 'Yes', Additional_Comments__c = 'No Additional Comments');

        Test.startTest();
        insert redForm;
        Test.stopTest();

        EmployeeFileController empFileController = new EmployeeFileController('simple-user@test.com');
        redForm = empFileController.getRedForm();
        assertPersonalDate(redForm, 'First Name', 'Last Name', 'Middle Name', 'DSI', Date.newInstance(Date.today().year() - 30, 3, 3), 'France', 'Woman', '000999111', 'poiulkj', Date.newInstance(Date.today().year() + 7, 5, 5),
                            'Simple City', 'Other 323', 'New one', 'England');
        assertEmergencyContact(redForm, 'Emergency Contact', 'Child', '333111666', 'p2@test.com', 'England', 'No');
        assertLocalEmergencyContact(redForm, 'Local Emergency', 'Other', '222222111','p1@test.com', 'United States of America (USA)', 'Yes');
        assertVoluntaryInformation(redForm, '-', 'Green', '0', '1 No', '-', '2 No', '3 No', 'Yes', 'No Additional Comments');
    }

    public static testMethod void shouldAddRedFormAndUpdateEmployee() {
        addEmployee('simple-user@test.com');
        EmployeeFileController empFileController = new EmployeeFileController('simple-user@test.com');
        Record_of_Emergency_Data_Form__c redForm = empFileController.getRedForm();

        System.assertNotEquals(null, redForm);
        assertPersonalDate(redForm, 'Sample', 'Employee', null, 'Inc', Date.newInstance(Date.today().year() - 40, 2, 2), 'United States of America (USA)', 'Man', '606060606', 'zaq12', Date.newInstance(Date.today().year() + 4, 2, 2),
                            'LA', 'Street 12/B', '-', 'United States of America (USA)');
        assertEmergencyContact(redForm, 'Employee Parent1', 'Parent', '77798999666', 'parent1@test.com', 'Canada', 'Yes');
        assertLocalEmergencyContact(redForm, 'Employee Parent2', 'Parent', '711119666','parent2@test.com', 'Canada', 'No');
        assertVoluntaryInformation(redForm, '25', 'Blue', 'AB', null, null, null, null, null, null);

        Test.startTest(); // we must check all field was updated by trigger

        redForm.Employee_First_Name__c = 'First Name';
        redForm.Employee_Last_Name__c = 'Last Name';
        redForm.Employee_Middle_Name__c = 'Middle Name';
        redForm.Business_Unit__c = 'DSI';
        redForm.DOB__c = Date.newInstance(Date.today().year() - 30, 3, 3);
        redForm.Citizenship__c = 'France';
        redForm.Gender__c = 'Woman';
        redForm.Personal_Phone_Number__c = '000999111';
        redForm.Passport_No__c = 'poiulkj';
        redForm.Passport_Expiration_Date__c = Date.newInstance(Date.today().year() + 7, 5, 5);
        redForm.Current_Address_City__c = 'Simple City';
        redForm.Current_Address_Street__c = 'Other 323';
        redForm.Current_Address_State__c = 'New one';
        redForm.Current_Address_Country__c = 'England';

        redForm.Emergency_Contact__c = 'Emergency Contact';
        redForm.Emergency_Contact_Relationship__c = 'Child';
        redForm.Emergency_Contact_Phone__c = '333111666';
        redForm.Emergency_Email__c = 'p2@test.com';
        redForm.Emergency_Contact_Country_of_Residence__c = 'England';
        redForm.Emergency_Contact_next_of_kin__c = 'No';

        redForm.Local_Emergency_Contact__c = 'Local Emergency';
        redForm.Local_Emergency_Contact_Relationship__c = 'Other';
        redForm.Local_Emergency_Contact_Phone__c = '222222111';
        redForm.Local_Emergency_Email__c = 'p1@test.com';
        redForm.Local_Emerg_Cont_Country_of_Residence__c = 'United States of America (USA)';
        redForm.Local_Emergency_Contact_next_of_kin__c = 'Yes';

        redForm.Height__c = '-';
        redForm.Eye_Colour__c = 'Green';
        redForm.Blood_Group__c = '0';
        redForm.Religion_Impact__c = '1 No';
        redForm.Distinguishing_Features__c = '-';
        redForm.Medical_Conditions_Allergies__c = '2 No';
        redForm.Regular_Medication__c = '3 No';
        redForm.Medical_Permission__c = 'Yes';
        redForm.Additional_Comments__c = 'No Additional Comments';

        empFileController.saveREDForm();
        Test.stopTest();

        // New instance to copy values from updated employee object
        empFileController = new EmployeeFileController('simple-user@test.com');
        redForm = empFileController.getRedForm();
        assertPersonalDate(redForm, 'First Name', 'Last Name', 'Middle Name', 'DSI', Date.newInstance(Date.today().year() - 30, 3, 3), 'France', 'Woman', '000999111', 'poiulkj', Date.newInstance(Date.today().year() + 7, 5, 5),
                            'Simple City', 'Other 323', 'New one', 'England');
        assertEmergencyContact(redForm, 'Emergency Contact', 'Child', '333111666', 'p2@test.com', 'England', 'No');
        assertLocalEmergencyContact(redForm, 'Local Emergency', 'Other', '222222111','p1@test.com', 'United States of America (USA)', 'Yes');
        assertVoluntaryInformation(redForm, '-', 'Green', '0', '1 No', '-', '2 No', '3 No', 'Yes', 'No Additional Comments');
    }

    private static void assertPersonalDate(Record_of_Emergency_Data_Form__c redForm, String fName, String lName, String mName, String bu, Date dob, String citizenship, String gender, String phone,
                                            String passNo, Date passDate, String city, String street, String state, String country) {
        System.assertEquals(fName, redForm.Employee_First_Name__c);
        System.assertEquals(lName, redForm.Employee_Last_Name__c);
        System.assertEquals(mName, redForm.Employee_Middle_Name__c);
        System.assertEquals(bu, redForm.Business_Unit__c);
        System.assertEquals(dob, redForm.DOB__c);
        System.assertEquals(citizenship, redForm.Citizenship__c);
        System.assertEquals(gender, redForm.Gender__c);
        System.assertEquals(phone, redForm.Personal_Phone_Number__c);
        System.assertEquals(passNo, redForm.Passport_No__c);
        System.assertEquals(passDate, redForm.Passport_Expiration_Date__c);
        System.assertEquals(city, redForm.Current_Address_City__c);
        System.assertEquals(street, redForm.Current_Address_Street__c);
        System.assertEquals(state, redForm.Current_Address_State__c);
        System.assertEquals(country, redForm.Current_Address_Country__c);
    }

    private static void assertEmergencyContact(Record_of_Emergency_Data_Form__c redForm, String emergName, String relation, String phone, String email, String country, String nextOfKin) {
        System.assertEquals(emergName, redForm.Emergency_Contact__c);
        System.assertEquals(relation, redForm.Emergency_Contact_Relationship__c);
        System.assertEquals(phone, redForm.Emergency_Contact_Phone__c);
        System.assertEquals(email, redForm.Emergency_Email__c);
        System.assertEquals(country, redForm.Emergency_Contact_Country_of_Residence__c);
        System.assertEquals(nextOfKin, redForm.Emergency_Contact_next_of_kin__c);
    }

    private static void assertLocalEmergencyContact(Record_of_Emergency_Data_Form__c redForm, String emergName, String relation, String phone, String email, String country, String nextOfKin) {
        System.assertEquals(emergName, redForm.Local_Emergency_Contact__c);
        System.assertEquals(relation, redForm.Local_Emergency_Contact_Relationship__c);
        System.assertEquals(phone, redForm.Local_Emergency_Contact_Phone__c);
        System.assertEquals(email, redForm.Local_Emergency_Email__c);
        System.assertEquals(country, redForm.Local_Emerg_Cont_Country_of_Residence__c);
        System.assertEquals(nextOfKin, redForm.Local_Emergency_Contact_next_of_kin__c);
    }

    private static void assertVoluntaryInformation(Record_of_Emergency_Data_Form__c redForm, String height, String eyeColour, String bloodGroup, String religion, String fetures, String medConditions,
                                                    String regularMed, String permission, String comments) {
        System.assertEquals(height, redForm.Height__c);
        System.assertEquals(eyeColour, redForm.Eye_Colour__c);
        System.assertEquals(bloodGroup, redForm.Blood_Group__c);
        System.assertEquals(religion, redForm.Religion_Impact__c);
        System.assertEquals(fetures, redForm.Distinguishing_Features__c);
        System.assertEquals(medConditions, redForm.Medical_Conditions_Allergies__c);
        System.assertEquals(regularMed, redForm.Regular_Medication__c);
        System.assertEquals(permission, redForm.Medical_Permission__c);
        System.assertEquals(comments, redForm.Additional_Comments__c);

    }

    private static void addEmployee(string employeeEmail) {
        List<Business_Unit__c> buList = [SELECT Id, Name FROM Business_Unit__c WHERE Name = 'Inc'];
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Employee_First_Name__c = 'Sample',
            Employee_Last_Name__c = 'Employee', Business_Unit__c = buList.get(0).Id, DOB__c = Date.newInstance(Date.today().year() - 40, 2, 2),
            Citizenship__c = 'United States of America (USA)', Gender__c = 'Man', Personal_Phone_Number__c = '606060606',
            Passport_No__c = 'zaq12', Passport_Expiration_Date__c = Date.newInstance(Date.today().year() + 4, 2, 2),
            Current_Address_City__c = 'LA', Current_Address_Street__c = 'Street 12/B', Current_Address_State__c = '-', Current_Address_Country__c = 'United States of America (USA)',
            EMERGENCY_CONTACT__c = 'Employee Parent1', Emergency_Contact_Relationship__c = 'Parent', Emergency_Contact_Phone__c = '77798999666',
            Emergency_Email__c = 'parent1@test.com', Emergency_Contact_Country_of_Residence__c = 'Canada', Emergency_Contact_next_of_kin__c = 'Yes',
            LOCAL_EMERGENCY_CONTACT__c = 'Employee Parent2', Local_Emergency_Contact_Relationship__c = 'Parent', Local_Emergency_Contact_Phone__c = '711119666',
            Local_Emergency_Contact_Email__c = 'parent2@test.com', Local_Emerg_Cont_Country_of_Residence__c = 'Canada', Local_Emergency_Contact_next_of_kin__c = 'No',
            Height__c = '25', Eye_Colour__c = 'Blue', Blood_Group__c = 'AB', Email_Address__c = employeeEmail);
        insert employeeObj;
    }
}