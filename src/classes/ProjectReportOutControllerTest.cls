@isTest
public class ProjectReportOutControllerTest {

    @isTest
    public static void shouldRedirectFromOldPROController() {
        PRO_OAuth_Settings__c newSettings = new PRO_OAuth_Settings__c(Auth_Callback_URL__c = 'www.test-test.com', Name = 'Test Name');
        insert newSettings;
        ProjectReportOutController proController = new ProjectReportOutController();

        PageReference pageRef = Page.ProjectReportOut;
        pageRef.getParameters().put('state', 'test-state');
        Test.setCurrentPage(pageRef);

        Test.startTest();
        PageReference testPageRef = proController.redirectToSFTools();
        System.assertNotEquals(null, testPageRef);
        System.assertEquals('www.test-test.com?state=test-state', testPageRef.getUrl());
        System.assertEquals(1, testPageRef.getParameters().size());
        System.assertEquals('test-state', testPageRef.getParameters().get('state'));
        Test.stopTest();
    }

    @isTest
    public static void shouldValidatePRO() {
        Id p = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        User user = new User(Alias = 'test1234', Email = 'test1234@no1email.com',
                            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US', ProfileId = p, Country = 'United States', IsActive = true,
                            TimezoneSidKey = 'America/Los_Angeles', username='tester1234@no1email.com');
        insert user;

        DContract__c dcontract1 = null;
        System.runAs(user) { // Make new user owner of a contract to fill in all data in PRO component
            dcontract1 = new DContract__c(Name = 'Sample Test 1', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
            insert dcontract1;
        }

        PROComponentController proCtrl = new PROComponentController();
        proCtrl.employeeEmail = 'test1234@no1email.com';
        proCtrl.pageController = new DimagiToolsController();

        Test.startTest();
        proCtrl.getProContracts();
        proCtrl.reportContractId = null;
        proCtrl.pro.PM_email__c = null;
        proCtrl.pro.Report_Out_Date__c = null;
        proCtrl.proTabContractPercntgethroughSOW = null;

        System.assertEquals(false, proCtrl.validData());
        proCtrl.reportContractId = dcontract1.Id;
        System.assertEquals(false, proCtrl.validData());
        proCtrl.status = 'Green';
        System.assertEquals(false, proCtrl.validData());
        proCtrl.pro.PM_email__c = 'test1234@no1email.com';
        System.assertEquals(false, proCtrl.validData());
        proCtrl.pro.Report_Out_Date__c = Date.today();
        System.assertEquals(false, proCtrl.validData());
        proCtrl.proTabContractPercntgethroughSOW = 10;
        System.assertEquals(true, proCtrl.validData());
        Test.stopTest();
    }

    @isTest
    public static void shouldSaveAndUpdatePRO() {
        Id p = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        User user = new User(Alias = 'test1234', Email = 'test1234@no1email.com',
                            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US', ProfileId = p, Country = 'United States', IsActive = true,
                            TimezoneSidKey = 'America/Los_Angeles', username='tester1234@no1email.com');
        insert user;

        DContract__c dcontract1 = null;
        System.runAs(user) { // Make new user owner of a contract to fill in all data in PRO component
            dcontract1 = new DContract__c(Name = 'Sample Test 1', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
            insert dcontract1;
        }

        PROComponentController proCtrl = new PROComponentController();
        proCtrl.employeeEmail = 'test1234@no1email.com';
        proCtrl.pageController = new DimagiToolsController();

        Test.startTest();
        proCtrl.getProContracts();
        proCtrl.status = 'Green';
        proCtrl.proTabContractPercntgethroughSOW = 10;
        System.assertEquals(true, proCtrl.validData());
        proCtrl.pro.Report_Out_Date__c = Date.newInstance(2018, 11, 8);
        proCtrl.save();
        System.assertNotEquals(null, [SELECT Id FROM Project_Report_Out__c WHERE Status__c = 'Green' LIMIT 1]);
        proCtrl.loadSubmittedPro();
        proCtrl.submitAnother();
        proCtrl.status = 'Red';
        proCtrl.pro.Report_Out_Date__c = Date.newInstance(2018, 11, 8);
        proCtrl.proTabContractPercntgethroughSOW = 10;
        System.assertEquals(true, proCtrl.validData());
        proCtrl.save();
        Test.stopTest();

        Project_Report_Out__c newPro = [SELECT Id, Name, Last_Report_ID__c, Contract_Snapshot__c, Contract__c,
                                           Status__c, Ability_to_meet_Schedule__c, Ability_to_stay_within_Scope__c,
                                           Current_System_Usage__c, Partner_Relationship__c, User_Name__c,
                                           Key_Accomplishments_Last_Two_Weeks__c, Key_Next_Steps_next_2_weeks__c,
                                           Issues_Questions_Notables__c, Client_Facing__c, Requires_Developer_Work__c,
                                           Project_Dashboard__c, Resource_Planning__c, Cap_planning_GDoc__c, PM_email__c
                                           FROM Project_Report_Out__c LIMIT 1];
        System.assertNotEquals(null, newPro);
        System.assertEquals('Red', newPro.Status__c);
        System.assertEquals(dcontract1.Id, newPro.Contract__c);
        System.assertNotEquals(null, newPro.Contract_Snapshot__c);
        System.assertEquals('test1234@no1email.com', newPro.PM_email__c);
    }

    @isTest
    public static void shouldLoadFinancialData() {
        DContract__c dcontract1 = new DContract__c(Name = '1_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract1;
        DContract__c dcontract2 = new DContract__c(Name = '2_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract2;
        DContract__c dcontract3 = new DContract__c(Name = '3_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract3;
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Sample Employee', Email_Address__c = 'test1234@no1email.com', Salary__c = 50000, Exchange_Rate__c = 1, Per_Week_Hours__c = 40);
        insert employeeObj;
        insert new List<Time_Card__c> { new Time_Card__c(Date__c = Date.today(), Total__c = 8, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 6, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 4, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 5, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 6, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 3, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 2, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 3, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 8, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 9, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 5, Client__c = dcontract1.Id, Employee__c = employeeObj.Id),
                                        new Time_Card__c(Date__c = Date.today(), Total__c = 5, Client__c = dcontract1.Id, Employee__c = employeeObj.Id)};

        PRO_Searched_Contract__c proSearchCon = new PRO_Searched_Contract__c(Email__c = 'test1234@no1email.com', Contract__c = dcontract1.Id);
        insert proSearchCon;

        PROFinancialComponentController financialCtrl = new PROFinancialComponentController();
        financialCtrl.employeeEmail = 'test1234@no1email.com';
        financialCtrl.pageController = new DimagiToolsController();

        Test.startTest();
        System.assertEquals(1, financialCtrl.getProjectsForFinancialTab().size());
        System.assertEquals(true, financialCtrl.executionStatusList.size() > 0);
        System.assertEquals(true, financialCtrl.timeSpendHistoryList.size() > 0);
        System.assertEquals(true, financialCtrl.proExpenseSpendList.size() > 0);
        System.assertEquals(true, financialCtrl.proBudgetList.size() > 0);

        Test.stopTest();
    }

    @isTest
    public static void shouldAddRemoveUserToFinancialData() {
        DContract__c dcontract1 = new DContract__c(Name = '1_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract1;
        DContract__c dcontract2 = new DContract__c(Name = '2_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract2;
        DContract__c dcontract3 = new DContract__c(Name = '3_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract3;
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(Name = 'Sample Employee', Email_Address__c = 'test1234@no1email.com', Salary__c = 50000, Exchange_Rate__c = 1, Per_Week_Hours__c = 40);
        insert employeeObj;
        insert new Time_Card__c(Date__c = Date.today(), Total__c = 8, Client__c = dcontract1.Id, Employee__c = employeeObj.Id);

        PROFinancialComponentController financialCtrl = new PROFinancialComponentController();
        financialCtrl.employeeEmail = 'test1234@no1email.com';
        financialCtrl.pageController = new DimagiToolsController();

        Test.startTest();
        System.assertEquals(0, financialCtrl.getProjectsForFinancialTab().size());
        financialCtrl.seachProjectName = '2_Sample';
        financialCtrl.searchProject();
        System.assertEquals(1, financialCtrl.searchedProjects.size());
        financialCtrl.contractToAdd = dcontract2.Id;
        financialCtrl.addProjectToUserList();
        System.assertEquals(1, financialCtrl.getProjectsForFinancialTab().size());
        financialCtrl.contractToRemove = dcontract2.Id;
        financialCtrl.removeProjectFromUserList();
        System.assertEquals(0, financialCtrl.getProjectsForFinancialTab().size());
        Test.stopTest();
    }

    @isTest
    public static void shouldLoadAllProjectsList() {
        DContract__c dcontract1 = new DContract__c(Name = '1_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract1;
        DContract__c dcontract2 = new DContract__c(Name = '2_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract2;
        DContract__c dcontract3 = new DContract__c(Name = '3_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract3;

        PROAllProjectsComponentController allprojectsCtrl = new PROAllProjectsComponentController();
        allprojectsCtrl.employeeEmail = 'test1234@no1email.com';
        allprojectsCtrl.pageController = new DimagiToolsController();

        Test.startTest();
        System.assertEquals(3, allprojectsCtrl.getProjectsList().size());
        Test.stopTest();
    }

    @isTest
    public static void shouldUpdateDataInAllProjectsTab() {
        DContract__c dcontract1 = new DContract__c(Name = '1_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract1;
        DContract__c dcontract2 = new DContract__c(Name = '2_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract2;
        DContract__c dcontract3 = new DContract__c(Name = '3_Sample Test', Services_Spend__c = 100, Total_Amount_of_Contract__c = 1000, Requires_Report_Out__c = 'Yes');
        insert dcontract3;
        Contact cont1 = new Contact(FirstName = 'contact1', LastName = 'test',Email = 'a.b.test@dimagi.com');
        insert cont1;
        Contact cont2 = new Contact(FirstName = 'contact2', LastName = 'test',Email = 'b.c.test@dimagi.com');
        insert cont2;
        Contact cont3 = new Contact(FirstName = 'me', LastName = 'test',Email = 'test1234@dimagi.com');
        insert cont3;

        PROAllProjectsComponentController allprojectsCtrl = new PROAllProjectsComponentController();
        allprojectsCtrl.employeeEmail = 'test1234@dimagi.com';
        allprojectsCtrl.pageController = new DimagiToolsController();

        Test.startTest();
        System.assertEquals(3, allprojectsCtrl.getProjectsList().size());
        System.assertEquals(0, allprojectsCtrl.contractContacts.size());
        allprojectsCtrl.addMe();
        allprojectsCtrl.addEmail();
        allprojectsCtrl.contractContacts[1].Email__c = 'clientteest@testclien.com';
        allprojectsCtrl.addContact();
        allprojectsCtrl.contractContacts[2].Contact__c = cont2.Id;
        allprojectsCtrl.saveContact();
        System.assertEquals(3, allprojectsCtrl.contractContacts.size());

        allprojectsCtrl.project.In_Charge_Of_Report_Out__c = 'Backstop';
        allprojectsCtrl.project.Project_Manager__c = cont1.Id;
        allprojectsCtrl.project.Backstop__c = cont2.Id;
        allprojectsCtrl.project.Field_Manager__c = cont3.Id;
        allprojectsCtrl.saveProjectOnly();

        allprojectsCtrl = new PROAllProjectsComponentController();
        allprojectsCtrl.employeeEmail = 'test1234@dimagi.com';
        allprojectsCtrl.pageController = new DimagiToolsController();
        System.assertEquals(3, allprojectsCtrl.getProjectsList().size());
        System.assertEquals(3, allprojectsCtrl.contractContacts.size());
        // System.assertEquals('Backstop', allprojectsCtrl.project.In_Charge_Of_Report_Out__c);
        System.assertEquals(cont1.Id, allprojectsCtrl.project.Project_Manager__c);
        System.assertEquals(cont2.Id, allprojectsCtrl.project.Backstop__c);
        System.assertEquals(cont3.Id, allprojectsCtrl.project.Field_Manager__c);

        allprojectsCtrl.removeContactId = cont2.Id;
        allprojectsCtrl.removeContact();
        allprojectsCtrl.removeEmailId = 'clientteest@testclien.com';
        allprojectsCtrl.removeEmail();
        allprojectsCtrl.project.Field_Manager__c = null;
        allprojectsCtrl.project.In_Charge_Of_Report_Out__c = 'Project Manager';
        allprojectsCtrl.saveProject();

        allprojectsCtrl = new PROAllProjectsComponentController();
        allprojectsCtrl.employeeEmail = 'test1234@dimagi.com';
        allprojectsCtrl.pageController = new DimagiToolsController();
        System.assertEquals(3, allprojectsCtrl.getProjectsList().size());
        System.assertEquals(1, allprojectsCtrl.contractContacts.size());
        System.assertEquals('Project Manager', allprojectsCtrl.project.In_Charge_Of_Report_Out__c);
        System.assertEquals(cont1.Id, allprojectsCtrl.project.Project_Manager__c);
        System.assertEquals(cont2.Id, allprojectsCtrl.project.Backstop__c);
        System.assertEquals(null, allprojectsCtrl.project.Field_Manager__c);
        Test.stopTest();
    }

    @isTest
    public static void shouldLoadEmptyGraphData() {
        GlobalMetricsComponentController metricsCtrl = new GlobalMetricsComponentController();
        metricsCtrl.employeeEmail = 'test1234@dimagi.com';
        metricsCtrl.pageController = new DimagiToolsController();

        Test.startTest(); // we want try without data because we don;t want exception on DimagiSfTools
        metricsCtrl.getZendeskData();
        metricsCtrl.setZendeskData(''); // invoke empty setters to increase code coverage, we need it to avoid is not property issue

        metricsCtrl.getHeadCountData();
        metricsCtrl.setHeadCountData('');

        metricsCtrl.getIcdsData();
        metricsCtrl.setIcdsData('');

        metricsCtrl.getEvExpected();
        metricsCtrl.setEvExpected('');

        metricsCtrl.getOppExpected();
        metricsCtrl.setOppExpected('');

        metricsCtrl.getBufferEvGen();
        metricsCtrl.setBufferEvGen('');

        metricsCtrl.getAggregateEffData();
        metricsCtrl.setAggregateEffData('');

        metricsCtrl.getGsRevenueData();
        metricsCtrl.setGsRevenueData('');

        metricsCtrl.getMrrData();
        metricsCtrl.setMrrData('');

        metricsCtrl.getGsGraphData();
        metricsCtrl.setGsGraphData('');

        metricsCtrl.getPerformanceGraphData();
        metricsCtrl.setPerformanceGraphData('');

        metricsCtrl.getUserGraphData();
        metricsCtrl.setUserGraphData('');

        metricsCtrl.getFormGraphData();
        metricsCtrl.setFormGraphData('');

        metricsCtrl.getWamGraphData();
        metricsCtrl.setWamGraphData('');

        metricsCtrl.getProgramGraphData();
        metricsCtrl.setProgramGraphData('');

        metricsCtrl.loadScaleData();
        Test.stopTest();
    }

    /**
     * Tests for Record_of_Emergency_Data_Form__c
     */
    @isTest
    public static void triggerShouldUpdateEmployeePersonalData() {
        addEmployee('simple-user@test.com');
        SFDC_Employee__c emplRec = [SELECT Id FROM SFDC_Employee__c WHERE Email_Address__c = 'simple-user@test.com'];
        Record_of_Emergency_Data_Form__c redForm = new Record_of_Emergency_Data_Form__c(Employee__c = emplRec.Id, Employee_First_Name__c = 'First Name', Employee_Middle_Name__c = 'Middle Name',
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

        EmployeeFileController empFileController = new EmployeeFileController();
        empFileController.employeeEmail = 'simple-user@test.com';
        empFileController.pageController = new DimagiToolsController();
        redForm = empFileController.getRedForm();
        assertPersonalDate(redForm, 'First Name', 'Last Name', 'Middle Name', 'DSI', Date.newInstance(Date.today().year() - 30, 3, 3), 'France', 'Woman', '000999111', 'poiulkj', Date.newInstance(Date.today().year() + 7, 5, 5),
                            'Simple City', 'Other 323', 'New one', 'England');
        assertEmergencyContact(redForm, 'Emergency Contact', 'Child', '333111666', 'p2@test.com', 'England', 'No');
        assertLocalEmergencyContact(redForm, 'Local Emergency', 'Other', '222222111','p1@test.com', 'United States of America (USA)', 'Yes');
        assertVoluntaryInformation(redForm, '-', 'Green', '0', '1 No', '-', '2 No', '3 No', 'Yes', 'No Additional Comments');
    }

    @isTest
    public static void shouldAddRedFormAndUpdateEmployee() {
        addEmployee('simple-user@test.com');
        EmployeeFileController empFileController = new EmployeeFileController();
        empFileController.employeeEmail = 'simple-user@test.com';
        empFileController.pageController = new DimagiToolsController();
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
        empFileController = new EmployeeFileController();
        empFileController.employeeEmail = 'simple-user@test.com';
        empFileController.pageController = new DimagiToolsController();
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
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Sample Employee', Salary__c = 50000, Exchange_Rate__c = 1, Effective_Salary_Date__c = Date.newInstance(2016, 2, 24),
            Effective_Exchange_Rate_Date__c = Date.newInstance(2016, 2, 24), Employee_First_Name__c = 'Sample',
            Employee_Last_Name__c = 'Employee', DOB__c = Date.newInstance(Date.today().year() - 40, 2, 2),
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