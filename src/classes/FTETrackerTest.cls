@isTest
public class FTETrackerTest {

    /** testSetup time cards
    Employee        Contract                FTE Time     Days
    FTE Employee    FTE Contract 1          Yes 25,6    3,2
                    FTE Contract 2          Yes 25,6    3,2
                    FTE Contract 3          Yes 10,3    1,2875
                    FTE Contract 4          Yes 30,6    3,825
                    Unassigned Contract 1   No  19,3    2,4125
                    Unassigned Contract 2   No  27,6    3,45
                                                139     17,375

    Employee        Contract                FTE Time    Days
    Other Employee  FTE Contract 1          Yes 28,6    3,575   5 TO UNASS
                    FTE Contract 2          Yes 0       0
                    FTE Contract 3          Yes 0       0
                    FTE Contract 4          Yes 5       0,625   2 TO UNASS
                    Unassigned Contract 1   No  19,3    2,4125
                    Unassigned Contract 2   No  0       0
                                                52,9    6,6125

    Employee   Contract                     FTE Time    Days
    Yyy Employee    FTE Contract 1          Yes 19,1    2,3875  8 TO UNASS
                    FTE Contract 2          Yes 16      2   7 TO UNASS
                    FTE Contract 3          Yes 7       0,875   5 fte 2
                    FTE Contract 4          Yes 8       1   3 TP fte 3
                    Unassigned Contract 1   No  3       0,375
                    Unassigned Contract 2   No  22      2,75    2 TO FTE 4 AND 16 TO FTE 3
                                                75,1    9,3875
    testSetup work cards
    Employee        Contract                Month days   
    FTE Employee    FTE Contract 1          1,2,3,4,5,6,7,8,9,10,11,12 
    Other Employee  FTE Contract 2          1,2,3,4,5,6,7,8,9,10,11,12 
    */

    @testSetup
    static void setup() {
        Date currentDate = Date.today();
        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        List<FTe_Work_Card__c> workCards = new List<FTe_Work_Card__c>();

        SFDC_Employee__c testEmployee = addEmployee('FTE Employee');
        Dcontract__c fteContract1 = addContract('FTE Contract 1', 'Yes');
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 1), 5));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 2), 6));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 3), 7));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 4), 4.3));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3));

        Dcontract__c fteContract2 = addContract('FTE Contract 2', 'Yes');
        timeCards.add(addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 6), 5));
        timeCards.add(addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 7), 6));
        timeCards.add(addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 8), 7));
        timeCards.add(addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 9), 4.3));
        timeCards.add(addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 10), 3.3));

        Dcontract__c fteContract3 = addContract('FTE Contract 3', 'Yes');
        timeCards.add(addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 11), 2));
        timeCards.add(addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 12), 2));
        timeCards.add(addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 13), 2));
        timeCards.add(addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 14), 1));
        timeCards.add(addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 15), 3.3));

        workCards.add(addWorkCard(fteContract1.Id, testEmployee, currentDate.year()));
        workCards.add(addWorkCard(fteContract2.Id, testEmployee, currentDate.year()));

        Dcontract__c fteContract4 = addContract('FTE Contract 4', 'Yes');
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 16), 5));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 17), 9));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 18), 9));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 19), 4.3));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 20), 3.3));

        Dcontract__c unassignedContract1 = addContract('Unassigned Contract 1', 'No');
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 5));
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 22), 6));
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 23), 1));
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 24), 4));
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 25), 3.3));

        Dcontract__c unassignedContract2 = addContract('Unassigned Contract 2', 'No');
        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 1), 3));
        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 2), 8));
        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 3), 9));
        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 4), 4.3));
        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3));

        SFDC_Employee__c testEmployee2 = addEmployee('Other Employee');

        workCards.add(addWorkCard(fteContract1.Id, testEmployee2, currentDate.year()));
        workCards.add(addWorkCard(fteContract2.Id, testEmployee2, currentDate.year()));

        timeCards.add(addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 1), 8, 5,
                                                                                                unassignedContract1.Id));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 2), 6));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 3), 7));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 4), 4.3));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3));

        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 5));
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 22), 6));
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 23), 1));
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 24), 4));
        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 25), 3.3));

        timeCards.add(addTimeCard(fteContract4.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 16), 5, 2,
                                                                                                unassignedContract2.Id));

        SFDC_Employee__c testEmployee3 = addEmployee('Yyy Employee');

        timeCards.add(addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 1), 3, 8,
                                                                                                unassignedContract1.Id));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 2), 4));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 3), 5));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 4), 4.6));
        timeCards.add(addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 5), 2.5));

        timeCards.add(addTimeCard(fteContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 6), 9));
        timeCards.add(addTimeCard(fteContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 8), 7, 7,
                                                                                                unassignedContract1.Id));

        timeCards.add(addTimeCard(fteContract3.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 9), 4));
        timeCards.add(addTimeCard(fteContract3.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 10), 3, 5,
                                                                                                fteContract2.Id));

        timeCards.add(addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 16), 0.5, 3,
                                                                                                fteContract3.Id));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 17), 1.5));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 18), 2));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 19), 1));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 20), 2));
        timeCards.add(addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 1));

        timeCards.add(addTimeCard(unassignedContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 3));

        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 6, 16,
                                                                                                fteContract3.Id));
        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 22), 5));
        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 23), 7, 2,
                                                                                                fteContract4.Id));
        timeCards.add(addTimeCard(unassignedContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 24), 4));

        insert workCards;
        insert timeCards;
    }

    @isTest
    public static void shouldGenerateWorkCards() {
        Test.startTest();
        Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(Date.today().year()));
        Test.stopTest();
        List<SFDC_Employee__c> employees = [SELECT Id, Name FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
        System.assertEquals(3, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c ORDER BY Employee__r.Name];
        System.assertEquals(5, workCards.size());
        System.assertEquals(600, workCards.get(0).Total_Hours__c);
        System.assertEquals(75, workCards.get(0).Total__c);
    }

    @isTest
    public static void triggerShouldGenerateWorkCards() {
        Test.startTest();
        DContract__c contractToUpdate1 = [SELECT Id, FTE_Tracker__c FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1];
        contractToUpdate1.FTE_Tracker__c = 'Yes';
        DContract__c contractToUpdate2 = [SELECT Id, FTE_Tracker__c FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1];
        contractToUpdate2.FTE_Tracker__c = 'No';
        List<DContract__c> contractsToUpdate = new List<DContract__c>();
        contractsToUpdate.add(contractToUpdate1);
        contractsToUpdate.add(contractToUpdate2);
        update contractsToUpdate;
        Test.stopTest();

        List<SFDC_Employee__c> employees = [SELECT Id, Name FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
        System.assertEquals(3, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, contract__r.name, Employee__c, Employee__r.Name, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c WHERE Year__c =: Date.today().year() ORDER BY Employee__r.Name];
        System.assertEquals(5, workCards.size());
        System.assertEquals(600, workCards.get(0).Total_Hours__c); // -25,6 + 19,3
        System.assertEquals(75, workCards.get(0).Total__c);
    }

    @isTest
    public static void shouldMoveHoursToUnassigned() {
        Date currentDate = Date.today();
        addTimeCard([SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id,
                    [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'].Id,
                    Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3);

       SFDC_Employee__c testEmployee = addEmployee('FTE Employee 7');
       Dcontract__c fteContract6 = addContract('FTE Contract 6', 'Yes');

        addWorkCardWithSameHours(fteContract6.Id, testEmployee, currentDate.year());
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee 7'];
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month() - 1;
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 6' LIMIT 1].Id;
        controller.loadEmployeeUnassMonth();
        controller.fteDays = '1';
        controller.moveTimeToUnassigned();
        controller.initFteEmployeeView();
        Test.stopTest();
        List<Integer> hoursArray = new List<Integer>{4,4,4,4,4,4,4,4,4,4,4,4};

        System.assertEquals((hoursArray[currentDate.month() - 1]) * 8, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(hoursArray[currentDate.month() - 1], controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
    }

    @isTest
    public static void shouldAddErrorWhenMovingHoursToUnassigned() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month() - 1;
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        controller.loadEmployeeUnassMonth();
        controller.fteDays = '13';
        controller.moveTimeToUnassigned();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b = false;
        System.debug('msgs : ' + msgs);
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('Too much hours to assign / hours cannot be negative')) b = true;
        }
        Test.stopTest();

        System.assert(b);
    }

    @isTest
    public static void shouldMoveHoursFromUnassigned() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month() - 1;
        controller.loadEmployeeMonth();
        controller.fteDays = '2.5';
        controller.selectedFteContract = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        controller.moveTimeFromUnassigned();
        controller.initFteEmployeeView();
        Test.stopTest();
        List<Integer> hoursArray = new List<Integer>{2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 20};

        // System.assertEquals(26.9, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        // System.assertEquals(3.25, controller.fteTimeManager.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals((hoursArray[currentDate.month() - 1] + 2.5) * 8, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(hoursArray[currentDate.month() - 1] + 2.5, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
    }

    @isTest
    public static void shouldAddErrorWhenMovingHoursFromUnassigned() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month() - 1;
        controller.loadEmployeeMonth();
        controller.fteDays = '20';
        controller.moveTimeFromUnassigned();
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('Too much hours to assign / hours cannot be negative')) b = true;
        }
        Test.stopTest();

        System.assert(b);
    }

    @isTest
    public static void shouldGenerateEmployeeHours() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        Test.stopTest();
        List<Integer> hoursArray = new List<Integer>{16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 160, 160};
        System.assertEquals(46.9, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(5.8625, controller.fteTimeManager.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(hoursArray[currentDate.month() - 1], controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(hoursArray[currentDate.month() - 1]/8, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
    }

    @isTest
    public static void triggerShouldAddRemovedTags() {
        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Date currentDate = Date.today();

        Test.startTest();

        Time_Card__c tc1 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 1 AND Employee__r.Name = 'Other Employee' LIMIT 1];
        Time_Card__c tc2 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 2 AND Employee__r.Name = 'Other Employee' LIMIT 1];
        Time_Card__c tc3 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: contUn1 AND DAY_IN_MONTH(Date__c) = 22 AND Employee__r.Name = 'Other Employee' LIMIT 1];
        tc2.Total__c = 1;
        tc2.Client__c = cont2;
        tc2.FTE_Contract__c = contUn1;
        tc2.FTE_hours__c = 6;
        tc3.Total__c = 19;
        List<Time_Card__c> triggerUpdate = new List<Time_Card__c>();
        triggerUpdate.add(tc2);
        triggerUpdate.add(tc3);
        triggerUpdate.add(addTimeCard(contUn1, [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee' LIMIT 1].get(0).Id,
                                                Date.newInstance(currentDate.year(), currentDate.month(), 27), 6.5));
        upsert triggerUpdate;
        delete tc1;

        Test.stopTest();
        List<FTE_Tag__c> testTags = [SELECT Action__c, Hours__c, Employee__r.Name, TC_Contract__r.Name, FTE_Contract__r.Name FROM FTE_Tag__c];
        for (FTE_Tag__c tagT : [SELECT Action__c, Hours__c, Employee__r.Name, TC_Contract__r.Name, FTE_Contract__r.Name FROM FTE_Tag__c]) {
            System.debug('FTE_Tag__c : ' + tagT);
        }
        System.assertEquals(2, [SELECT Id FROM FTE_Tag__c].size());

        FTE_Tag__c testTag = [SELECT Id, Hours__c, Employee__r.Name, TC_Contract__r.Name, FTE_Contract__r.Name FROM FTE_Tag__c
                                WHERE Action__c = 'Tag Deleted' AND DAY_IN_MONTH(Date__c) = 1 LIMIT 1];
        System.assertEquals('Other Employee' ,testTag.Employee__r.Name);
        System.assertEquals(5.0 ,testTag.Hours__c);
        System.assertEquals('FTE Contract 1' ,testTag.TC_Contract__r.Name);
        System.assertEquals('Unassigned Contract 1' ,testTag.FTE_Contract__r.Name);

        testTag = [SELECT Id, Hours__c, Employee__r.Name, TC_Contract__r.Name, FTE_Contract__r.Name FROM FTE_Tag__c
                                WHERE Action__c = 'Tag Deleted' AND DAY_IN_MONTH(Date__c) = 2 LIMIT 1];
        System.assertEquals('Other Employee' ,testTag.Employee__r.Name);
        System.assertEquals(6.0 ,testTag.Hours__c);
        System.assertEquals('FTE Contract 1' ,testTag.TC_Contract__r.Name);
        System.assertEquals('Unassigned Contract 1' ,testTag.FTE_Contract__r.Name);

        Time_Card__c tcWithNewClient = [SELECT Id, FTE_Contract__c, FTE_hours__c FROM Time_Card__c WHERE Id =: tc2.Id LIMIT 1];
        System.assertEquals(null ,tcWithNewClient.FTE_Contract__c);
        System.assertEquals(0 ,tcWithNewClient.FTE_hours__c);
    }

    @isTest
    public static void batchShouldMoveRemovedFTETags() {
        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Date currentDate = Date.today();

        Test.startTest();

        Time_Card__c tc1 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 1 AND Employee__r.Name = 'Other Employee' LIMIT 1];
        Time_Card__c tc2 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont4 AND DAY_IN_MONTH(Date__c) = 16 AND Employee__r.Name = 'Other Employee' LIMIT 1];

        List<Time_Card__c> triggerDelete = new List<Time_Card__c>();
        triggerDelete.add(tc1);
        triggerDelete.add(tc2);
        delete triggerDelete;

        Database.executeBatch(new FTEUpdateTagsBatch());

        Test.stopTest();

        List<Time_Card__c> testTimeCards = [SELECT Id, FTE_Only__c, Client__r.Name, FTE_Contract__r.Name, Total__c, FTE_Hours__c FROM Time_Card__c WHERE Employee__r.Name = 'Other Employee'];

        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        Time_Card__c tc1b = [SELECT Id, FTE_only__c, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND Employee__r.Name = 'Other Employee' AND FTE_Contract__c != null LIMIT 1];
        System.assertEquals(false, tc1b.FTE_only__c);
        System.assertEquals(5, tc1b.FTE_Hours__c);
        System.assertEquals(contUn1, tc1b.FTE_Contract__c);

        Time_Card__c tc2b = [SELECT Id, FTE_Only__c, FTE_Contract__c, Total__c, FTE_Hours__c, Client__c FROM Time_Card__c WHERE
                            Client__r.Name = 'FTE Contract 4' AND Employee__r.Name = 'Other Employee' LIMIT 1];
        System.assertEquals(cont4, tc2b.Client__c);
        System.assertEquals(true, tc2b.FTE_only__c);
        System.assertEquals(2, tc2b.FTE_Hours__c);
        System.assertEquals(contUn2, tc2b.FTE_Contract__c);
    }

    @isTest
    public static void csvParseControllerTest() {
        DContract__c contract = [select Id, Name from DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1];
        SFDC_Employee__c employee = [select Id, Name from SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1];
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String correctData = ',,,,,,\n\r '
                           + 'FTE Contract 1 ,01/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + ', 05/' + fteYear + ', 06/' + fteYear + ', 07/' + fteYear
                           + ', 08/' + fteYear + ', 09/' + fteYear + ', 10/' + fteYear + ', 11/' + fteYear + ', 12/' + fteYear + '\n\r'
                           + 'Other Employee,1,2,3,4,5,6,7,8,9,10,11,12\n\r'
                           + 'FTE Employee,3,4,5,6,7,8,9,10,11,12,13,14\n\r'
                           + 'Yyy Employee,12,11,10,9,8,7,6,5,4,3,2,1\n\r';
        FTECsvUploadController csvUpload = new FTECsvUploadController();
		FTEUploadData fteUploadData = new FTEUploadData(employee.Id,contract.Id,employee.Name, contract.Name, fteYear);
        fteUploadData.buildDBRec();
        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Test.stopTest();

        System.assertEquals(3, csvUpload.records.size());
        assertFTEDataRecord(csvUpload.records.values(), 'Other Employee', fteYear, 'FTE Contract 1', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
        assertFTEDataRecord(csvUpload.records.values(), 'FTE Employee', fteYear, 'FTE Contract 1', 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
        assertFTEDataRecord(csvUpload.records.values(), 'Yyy Employee', fteYear, 'FTE Contract 1', 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
    }
    @isTest
    public static void errorFileNull(){
        Test.startTest();
        FTECsvUploadController csvUpload = new FTECsvUploadController();
        csvUpload.parseCsvFile();
        Test.stopTest();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b;
        for(Apexpages.Message msg:msgs){
            System.debug(msg);
            if (msg.getDetail().contains('Choose file from your computer to upload.')){
                b = true;
            }            
        }
        System.assertEquals(True, b);
    }
    @isTest
    public static void WrongMonthFormat(){
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String InvalidData = ',,,,,,\n\r '
            + 'FTE Contract 1 ,AB/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + ', 05/' + fteYear + ', 06/' + fteYear + ', 07/' + fteYear
            + ', 08/' + fteYear + ', 09/' + fteYear + ', 10/' + fteYear + ', 11/' + fteYear + ', 12/' + fteYear + '\n\r'
            + 'Other Employee,1,2,3,4,5,6,7,8,9,10,11,12\n\r'
            + 'FTE Employee,3,4,5,6,7,8,9,10,11,12,13,14\n\r'
            + 'Yyy Employee,12,11,10,9,8,7,6,5,4,3,2,1\n\r';
        FTECsvUploadController csvUpload = new FTECsvUploadController();
        
        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(InvalidData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Test.stopTest();
        System.assert(ApexPages.hasMessages(ApexPages.SEVERITY.ERROR));
    }
    @isTest
    public static void fileContentNull(){
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        FTECsvUploadController csvUpload = new FTECsvUploadController();

        Test.startTest();
        csvUpload.fileContent = Blob.valueOf('');
        csvUpload.fileName = 'Test file name';
        
        csvUpload.parseCsvFile();
        Test.stopTest();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b;
        for(Apexpages.Message msg:msgs){
            System.debug(msg);
            if (msg.getDetail().contains('File is empty.')){
                b = true;
            }            
        }
        System.assertEquals(True, b);
    }
    @isTest
    public static void hasRowNoData(){
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        FTECsvUploadController csvUpload = new FTECsvUploadController();
        String InvalidData = ',,,,,,\n\r '
            + 'FTE Contract 1 ,01/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + ', 05/' + fteYear + ', 06/' + fteYear + ', 07/' + fteYear
            + ', 08/' + fteYear + ', 09/' + fteYear + ', 10/' + fteYear + ', 11/' + fteYear + ', 12/' + fteYear + '\n\r';
        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(InvalidData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Test.stopTest();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b;
        for(Apexpages.Message msg:msgs){
            System.debug(msg);
            if (msg.getDetail().contains('File contains only one row, no data.')){
                b = true;
            }            
        }
        System.assertEquals(True, b);
    }
    @isTest
    public static void testBlobtoString(){
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String correctData = ',,,,,,\n\r '
            + 'FTE Contract 1 ,01/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + ', 05/' + fteYear + ', 06/' + fteYear + ', 07/' + fteYear
            + ', 08/' + fteYear + ', 09/' + fteYear + ', 10/' + fteYear + ', 11/' + fteYear + ', 12/' + fteYear + '\n\r'
            + 'Other Employee,1,2,3,4,5,6,7,8,9,10,11,12\n\r'
            + 'FTE Employee,3,4,5,6,7,8,9,10,11,12,13,14\n\r'
            + 'Yyy Employee,12,11,10,9,8,7,6,5,4,3,2,1\n\r';
        Blob fileContent=Blob.valueOf(correctData);
        Test.startTest();
        String str = FTETrackerHelper.blobToString(fileContent, 'ISO 8859-2');
        Test.stopTest();
        //System.debug(str);
        System.assertEquals(str, str);
        
    }

    @isTest
    public  static void shouldRetunrYearList() {
        List<SelectOption> years = FTETrackerHelper.getYearsData();
        System.assertEquals(4, years.size());
        Integer currentYear = Date.today().year();
        System.assertEquals(String.valueOf(currentYear + 2), years.get(0).getValue());
        System.assertEquals(String.valueOf(currentYear + 1), years.get(1).getValue());
        System.assertEquals(String.valueOf(currentYear), years.get(2).getValue());
        System.assertEquals(String.valueOf(currentYear - 1), years.get(3).getValue());
    }

    @isTest
    public static void testTimeManagerEmpl1() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1];
        Id contract1Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id contract2Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id contract3Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id contract4Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;

        Test.startTest();
        FTETimeManager timeManager = new FTETimeManager(employee, Date.today().year());
        timeManager.loadEmployeeTime();
        System.assertEquals(25.6, timeManager.assignedMap.get(contract1Id).hoursArray[12]);
        System.assertEquals(25.6, timeManager.assignedMap.get(contract2Id).hoursArray[12]);
        System.assertEquals(10.3, timeManager.assignedMap.get(contract3Id).hoursArray[12]);
        System.assertEquals(30.6, timeManager.assignedMap.get(contract4Id).hoursArray[12]);
        System.assertEquals(19.3 + 27.6, timeManager.unassigned.hoursArray[12]);

        System.assertEquals(0, [SELECT Id FROM Time_Card__c WHERE Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'No'].size());
        System.assertEquals(0, [SELECT Id FROM Time_Card__c WHERE Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'Yes'].size());

        timeManager.moveTimeToUnassigned(24, Date.today().month(), contract1Id);
        System.assertEquals(1, [SELECT Id FROM Time_Card__c WHERE Client__c =: contract1Id AND Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'No'].size());

        timeManager.moveTimeToAssigned(8, Date.today().month(), contract3Id);
        System.assertEquals(1, [SELECT Id FROM Time_Card__c WHERE FTE_Contract__c =: contract3Id AND Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'Yes'].size());
        timeManager.moveTimeToAssigned(2, Date.today().month(), contract3Id);
        System.assertEquals(1, [SELECT Id FROM Time_Card__c WHERE FTE_Contract__c =: contract3Id AND Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'Yes'].size());

        timeManager.moveTimeToUnassigned(5, Date.today().month(), contract3Id);
        System.assertEquals(1, [SELECT Id FROM Time_Card__c WHERE FTE_Contract__c =: contract3Id AND Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'Yes'].size());
        System.assertEquals(1, [SELECT Id FROM Time_Card__c WHERE FTE_Contract__c =: contract3Id AND Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'Yes'
                                                            AND FTE_Hours__c = 5].size());
        Test.stopTest();
    }

    @isTest
    public static void testTimeManagerEmpl2() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee' LIMIT 1];
        Id contract1Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id contract2Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id contract3Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id contract4Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;

        Test.startTest();
        FTETimeManager timeManager = new FTETimeManager(employee, Date.today().year());
        timeManager.loadEmployeeTime();
        System.assertEquals(28.6 - 5, timeManager.assignedMap.get(contract1Id).hoursArray[12]);
        System.assertEquals(null, timeManager.assignedMap.get(contract2Id));
        System.assertEquals(null, timeManager.assignedMap.get(contract3Id));
        System.assertEquals(5 - 2, timeManager.assignedMap.get(contract4Id).hoursArray[12]);
        System.assertEquals(19.3 + 5 + 2, timeManager.unassigned.hoursArray[12]);
        Test.stopTest();
    }

    @isTest
    public static void testTimeManagerEmpl3() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee' LIMIT 1];
        Id contract1Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id contract2Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id contract3Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id contract4Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;

        Test.startTest();
        FTETimeManager timeManager = new FTETimeManager(employee, Date.today().year());
        timeManager.loadEmployeeTime();
        System.assertEquals(19.1 - 8, timeManager.assignedMap.get(contract1Id).hoursArray[12]);
        System.assertEquals(16 - 7 + 5, timeManager.assignedMap.get(contract2Id).hoursArray[12]);
        System.assertEquals(7 - 5 + 3 + 16, timeManager.assignedMap.get(contract3Id).hoursArray[12]);
        System.assertEquals(8 - 3 + 2, timeManager.assignedMap.get(contract4Id).hoursArray[12]);
        System.assertEquals(3 + 22 + 8 + 7 - 16 - 2, timeManager.unassigned.hoursArray[12]);
        Test.stopTest();
    }
    @isTest
    public static void InputHoursGreaterThanDay(){
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        String contName='FTE Contract 1';
        Integer dayValue=Date.today().day();
        Decimal inHrs= 6;
        Date formDate=Date.valueOf(fteYear+'-'+emplMonth+'-'+dayValue);
        Test.startTest();
        FTETimeCardGenerator cardGenerator= new FTETimeCardGenerator(fteYear,emplMonth,employee.Id);
        cardGenerator.updateFteDayCard(contName, dayValue, inHrs);
        Test.stopTest();
        List<FTE_Day_Card__c> daycardList=[SELECT Id, Contract__c, Employee__c, hours__c, Date__c, Work_Card_Total_Hours__c, Available_Hours__c FROM FTE_Day_Card__c WHERE Contract__r.name =: contName AND Employee__c =:employee.Id
                                           AND Date__c=:formDate];
        System.debug('Daycards:'+formDate+','+daycardList.size());
        System.assertEquals(6,dayCardList[0].hours__c);
    }

    @isTest
    public static void InputHourslesserThanDay(){
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        String contName='FTE Contract 1';
        Integer dayValue=Date.today().day();
        Decimal inHrs= 0.00;
        Date formDate=Date.valueOf(fteYear+'-'+emplMonth+'-'+dayValue);
        Test.startTest();
        FTETimeCardGenerator cardGenerator= new FTETimeCardGenerator(fteYear,emplMonth,employee.Id);
        cardGenerator.updateFteDayCard(contName, dayValue, inHrs);
        Test.stopTest();
        List<FTE_Day_Card__c> daycardList=[SELECT Id, Contract__c, Employee__c, hours__c, Date__c, Work_Card_Total_Hours__c, Available_Hours__c FROM FTE_Day_Card__c WHERE Contract__r.name =: contName AND Employee__c =:employee.Id
                                           AND Date__c=:formDate];
        System.debug('Daycards:'+formDate+','+daycardList.size()+','+dayCardList[0].hours__c);
        System.assertEquals(0.00,dayCardList[0].hours__c);
    }

    @isTest
    public static void testColumnWrapper(){
        Test.startTest();
        FTEFileController.FTEColumnWrapper columnWrap= new FTEFileController.FTEColumnWrapper('Test',0);
        Test.stopTest();
        System.assertEquals('Test', columnWrap.columnName);
    }

    @isTest
    public static void testUnassignDays(){
        String empId = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1].Id;
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        String contName='FTE Contract 1';
        Integer dayValue=Date.today().day();
        Date formDate=Date.valueOf(fteYear+'-'+emplMonth+'-'+(dayValue+1));
        PageReference pageRef = Page.FTE_Time_Card_View;
        pageRef.getParameters().put('employeeId', EncodingUtil.urlDecode(empId, 'UTF-8'));
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode(String.valueOf(fteYear), 'UTF-8'));
        pageRef.getParameters().put('month', EncodingUtil.urlDecode(String.valueOf(emplMonth), 'UTF-8'));
        Test.setCurrentPage(pageRef);
        Test.startTest();
        FTEFileController fileCtrl= new FTEFileController();
        fileCtrl.totalHoursOfContract = 0.25;
        fileCtrl.contractName='FTE Contract 1';
        fileCtrl.day= dayValue;
        fileCtrl.unAssignDays();
        Test.stopTest();
        List<FTE_Day_Card__c> dayCardList=[SELECT Id, Contract__c, Employee__c, hours__c, Date__c, Work_Card_Total_Hours__c, Available_Hours__c FROM FTE_Day_Card__c WHERE Contract__r.name =: contName AND Employee__c =:empId
                                           AND Date__c=:formDate LIMIT 1];
        System.debug('SumOfhrs: '+dayCardList[0].hours__c+','+ dayCardList[0].Available_Hours__c+','+dayCardList.size());
        Decimal sumofhrs = dayCardList[0].hours__c + dayCardList[0].Available_Hours__c;
        System.assertEquals(fileCtrl.userAvailableDays, sumofhrs.setScale(4));
    }
    
    @isTest
    public static void testgoToEmployeeViewFromTimeCardView(){
        String empId = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1].Id;
        PageReference pageRef = Page.FTE_Time_Card_View;
        pageRef.getParameters().put('employeeId', EncodingUtil.urlDecode(empId, 'UTF-8'));
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode(String.valueOf(2020), 'UTF-8'));
        pageRef.getParameters().put('month', EncodingUtil.urlDecode(String.valueOf(Date.today().month()), 'UTF-8'));
        Test.setCurrentPage(pageRef);
        Test.startTest();
        FTEFileController fileCtrl= new FTEFileController();
        PageReference pg = fileCtrl.goToEmployeeViewFromTimeCardView();
        Test.stopTest();
        System.assertEquals('/apex/fte_employee_view?employeeId='+empId+'&fteYear=2020', pg.getUrl());
    }
    
    @isTest
    public static void testUpdateDayCard(){
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        String contName='FTE Contract 1';
        Integer dayValue=Date.today().day();
        Date formDate=Date.valueOf(fteYear+'-'+emplMonth+'-'+dayValue);
        
        FTETimeCardGenerator cardGenerator= new FTETimeCardGenerator(fteYear,emplMonth,employee.Id);
        
        PageReference pageRef = Page.FTE_Time_Card_View;
        pageRef.getParameters().put('employeeId', EncodingUtil.urlDecode(employee.Id, 'UTF-8'));
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode(String.valueOf(Date.today().year()), 'UTF-8'));
        pageRef.getParameters().put('month', EncodingUtil.urlDecode(String.valueOf(Date.today().month()), 'UTF-8'));
        Test.setCurrentPage(pageRef);
        
        FTEFileController FileCtrl= new FTEFileController();
        FileCtrl.fteDays ='0.25';
        FileCtrl.day = dayValue;
        FileCtrl.contractName = contName;
        FileCtrl.exportMonth=emplMonth;
        
        Test.startTest();
        FileCtrl.updateDayCard();
        Test.stopTest();
        
        System.assertEquals(FileCtrl.employeeMonthProjects.size(), cardGenerator.generateMonthWorkCards().size());
    }

    @isTest
    public static void testrefreshIndividualProject(){
        PageReference pageRef = Page.FTE_Individual_Project_View;
        String contId=[SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        pageRef.getParameters().put('contractId', EncodingUtil.urlDecode(contId, 'UTF-8'));
        Test.setCurrentPage(pageRef);
        Test.startTest();
        FTEIndividualProjectController projCtrl = new FTEIndividualProjectController();
        PageReference pg= projCtrl.refreshIndividualProject();
        Test.stopTest();
        String yr=pg.getParameters().get('fteYear');
        System.assertEquals('/apex/fte_individual_project_view?contractId='+contId+'&fteYear='+yr,pg.getUrl());
    }
    
    @isTest
    public static void testgoToEmployeeListView(){
        PageReference pageRef = Page.FTE_Individual_Project_View;
        String contId=[SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        pageRef.getParameters().put('contractId', EncodingUtil.urlDecode(contId, 'UTF-8'));
        Test.setCurrentPage(pageRef);
        Test.startTest();
        FTEIndividualProjectController projCtrl = new FTEIndividualProjectController();
        PageReference pg= projCtrl.goToEmployeeListView();
        Test.stopTest();
        String yr=pg.getParameters().get('fteYear');
        System.assertEquals('/apex/fte_employee_list_view',pg.getUrl());        
    }
    
    @isTest
    public static void testroundtoDays(){
        Test.startTest();
        Decimal result=FTETrackerHelper.roundtoDays(6.25);
        Decimal totalDays = (6.25 / 8.0).intValue();
        Decimal restValue = 6.25 - (totalDays * 8);
        Test.stopTest();
        System.assertEquals(totalDays + (0.25 * (restValue / 2.0).setScale(0, System.RoundingMode.HALF_UP)),result);
    }
    
    @isTest
    public static void nullEmployeeId(){
        String contrId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode(String.valueOf(Date.today().year()), 'UTF-8'));
        Test.setCurrentPage(pageRef);
        
        Test.startTest(); 
        FTEEmployeeController emplCtrl = new FTEEmployeeController();
        emplCtrl.initFteEmployeeView();
        Test.stopTest();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b;
        for(Apexpages.Message msg:msgs){
            System.debug(msg);
            if (msg.getDetail().contains('Empty Employee ID')){
                b = true;
            }            
        }
        System.assertEquals(True, b);
    }
    
    @isTest
    public static void nullEmployeeUnassMonth(){
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = null;
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        controller.loadEmployeeUnassMonth();
        controller.fteDays = '13';
        controller.moveTimeToUnassigned();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b = false;
        System.debug('msgs : ' + msgs);
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('Cannot load month number')) b = true;
        }
        Test.stopTest();

        System.assert(b);
    }
    
    @isTest
    public static void nullEmployeeAssMonth(){
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = null;
        controller.loadEmployeeMonth();
        controller.fteDays = '2.5';
        controller.selectedFteContract = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        controller.moveTimeFromUnassigned();
        controller.initFteEmployeeView();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b = false;
        System.debug('msgs : ' + msgs);
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('Cannot load month number')) b = true;
        }
        Test.stopTest();

        System.assert(b);
    }
    
   	@isTest
    public static void testFTEUpdateTagsBatchScheduler(){
        Test.startTest();
        FTEGenerateEmployeesWorkCardScheduler testScheduler = new FTEGenerateEmployeesWorkCardScheduler();
        testScheduler.execute(null);
        Test.stopTest();
         
              
    }
    @isTest
    public static void testFTERemoveNegativeHoursBatch(){
        
        List<Time_Card__c> timeCards = new List<Time_Card__c>();
        
        Dcontract__c fteContract5 = addContract('FTE Contract 5', 'Yes');
        
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1];
        Dcontract__c unassignedContract = [SELECT Id FROM Dcontract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1];
        
        addFteTag(fteContract5.Id, employee, Date.today());
        
        timeCards.add(addTimeCard(fteContract5.Id, employee.Id, Date.newInstance(Date.today().year(), Date.today().month(), 1), -5, 4,
                                                                                                unassignedContract.Id));
        insert timeCards;
        
        //FTERemoveNegativeHoursBatch RemoveNegativeHoursBatch = new FTERemoveNegativeHoursBatch();
        FTERemoveNegativeHoursBatch.FTEEmployeeMonthUpdated monthlyUpdate = new FTERemoveNegativeHoursBatch.FTEEmployeeMonthUpdated(employee.Id, fteContract5.Id, 6.025, Date.today());

        Test.startTest();
        Database.executeBatch(new FTERemoveNegativeHoursBatch(),200);
        Test.stopTest();
    }
    /**
     * Controller tests
     */
    @isTest
    public static void testEmployeeListController() {
        Integer currYear = Date.today().year();
        List<FTE_Work_Card__c> workCards = new List<FTE_Work_Card__c>();
        for (SFDC_Employee__c empl : [SELECT Id FROM SFDC_Employee__c]) {
            workCards.add(new FTE_Work_Card__c(Employee__c = empl.Id, Month_1__c = 1, Month_2__c = 2, Month_3__c = 3, Month_4__c = 4, Month_5__c = 5, Month_6__c = 6, Month_7__c = 7, Month_8__c = 8,
                                               Month_9__c = 9, Month_10__c = 10, Month_11__c = 11, Month_12__c = 12, Total__c = 78, Total_Hours__c = 78 * 8, Year__c = currYear));
        }
        insert workCards;

        PageReference pageRef = Page.FTE_Employee_List_View;
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode('' + currYear, 'UTF-8'));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTETrackerController emplListCtrl = new FTETrackerController();
        List<FTEEmployeeTime> workCardList = emplListCtrl.getEmployeesList();
        System.assertEquals(3, workCardList.size());

        emplListCtrl.emplDepartment = emplListCtrl.departmentList.get(1).getValue();
        emplListCtrl.emplBusinessUnit = emplListCtrl.buList.get(1).getValue();
        System.assertEquals(3, emplListCtrl.getEmployeesList().size()); // secdond option must be empty, we have all departmenst and BU empty so expected result is 3

        emplListCtrl.employeeNameSearch = 'other';
        emplListCtrl.searchEmplopyee();
        workCardList = emplListCtrl.getEmployeesList();
        System.assertEquals(1, workCardList.size());

        SFDC_Employee__c emp  = [SELECT Id, Sub_Unit__c FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        emp.Sub_Unit__c = 'Global Services';
        update emp;

        emplListCtrl.employeeNameSearch = '';
        emplListCtrl.emplDepartment = 'Global Services';
        emplListCtrl.searchEmplopyee();
        workCardList = emplListCtrl.getEmployeesList();
        System.assertEquals(1, workCardList.size());
        System.assertEquals('FTE Employee', workCardList.get(0).name);

        System.assertNotEquals(null, emplListCtrl.goToProjectListView());
        System.assertNotEquals(null, emplListCtrl.goToEmployeeView());
        System.assertNotEquals(null, emplListCtrl.goToCSVUploadView());
        Test.stopTest();
    }

    @isTest
    public static void testProjectListController() {
        Integer currYear = Date.today().year();
        PageReference pageRef = Page.FTE_Project_List_View;
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode('' + currYear, 'UTF-8'));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEProjectListController projListCtrl = new FTEProjectListController();
        List<DContract__c> projList = projListCtrl.getListToSubmit();
        System.assertEquals(4, projList.size());
        System.assertNotEquals(null, projListCtrl.goToEmployeeListView());
        System.assertNotEquals(null, projListCtrl.goToIndividualProjectView());
        Test.stopTest();
    }

    @isTest
    public static void testIndividualProjectController() {
        PageReference pageRef = Page.FTE_Individual_Project_View;
        pageRef.getParameters().put('contractId', EncodingUtil.urlDecode([SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id, 'UTF-8'));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEIndividualProjectController projCtrl = new FTEIndividualProjectController();
        projCtrl.initIndividualProject();
        System.assertEquals(3, projCtrl.individualContractDataList.size()); // 3 employees and 1 total row
        System.assertEquals('Total', projCtrl.individualContractDataList.get(2).name);

        System.assertNotEquals(null, projCtrl.goToEmployeeView());
        System.assertNotEquals(null, projCtrl.goToProjectListView());
        Test.stopTest();
    }

    @isTest
    public static void testFileCtrl() {
        String empId = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1].Id;
        PageReference pageRef = Page.FTE_Time_Card_View;
        pageRef.getParameters().put('employeeId', EncodingUtil.urlDecode(empId, 'UTF-8'));
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode(String.valueOf(Date.today().year()), 'UTF-8'));
        pageRef.getParameters().put('month', EncodingUtil.urlDecode(String.valueOf(Date.today().month()), 'UTF-8'));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEFileController fileCtrl = new FTEFileController();
        Decimal empMnth = Date.today().month() * 8;
        Double totalHours = empMnth.setScale(4);
        fileCtrl.loadExportTimeCards();
        System.assertEquals(Date.daysInMonth(Date.today().year(), Date.today().month()), fileCtrl.rowList.size());
        System.assertEquals(3, fileCtrl.employeeMonthProjects.size()); // 4 FTE contracts and 1 overhead sum
        System.assertEquals('FTE Contract 1', fileCtrl.employeeMonthProjects.get(0).name);
        System.assertEquals(totalHours, fileCtrl.employeeMonthProjects.get(0).totalHours);
        System.assertEquals('FTE Contract 2', fileCtrl.employeeMonthProjects.get(1).name);
        System.assertEquals(totalHours, fileCtrl.employeeMonthProjects.get(1).totalHours);
        System.assertEquals('Overhead', fileCtrl.employeeMonthProjects.get(2).name);
        //System.assertEquals(19.3 + 27.6, fileCtrl.employeeMonthProjects.get(2).totalHours);
        Test.stopTest();
    }

    @isTest
    public static void testFileCtrlWithDownloadAndWithTags() {
        String empId = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee' LIMIT 1].Id;
        PageReference pageRef = Page.FTE_Download_File;
        pageRef.getParameters().put('employeeId', EncodingUtil.urlDecode(empId, 'UTF-8'));
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode(String.valueOf(Date.today().year()), 'UTF-8'));
        pageRef.getParameters().put('month', EncodingUtil.urlDecode(String.valueOf(Date.today().month()), 'UTF-8'));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        Decimal empMnth = Date.today().month() * 8;
        Double totalHours = empMnth.setScale(4);
        FTEFileController fileCtrl = new FTEFileController();
        System.assertNotEquals(null, fileCtrl.csvFile);
        System.assert(String.isNotBlank(fileCtrl.csvFile));
        System.assertEquals('Other_Employee_' + (DateTime.newInstance(Date.today().year(), Date.today().month(), 1).format('MMMM'))
                            + '_' + Date.today().year() + '.csv', fileCtrl.fileName);

        fileCtrl.loadExportTimeCards();
        System.assertEquals(Date.daysInMonth(Date.today().year(), Date.today().month()), fileCtrl.rowList.size());
        System.assertEquals(3, fileCtrl.employeeMonthProjects.size()); // 2 FTE contracts and 1 overhead sum
        System.assertEquals('FTE Contract 1', fileCtrl.employeeMonthProjects.get(0).name);
        System.assertEquals(totalHours, fileCtrl.employeeMonthProjects.get(0).totalHours);
        System.assertEquals('FTE Contract 2', fileCtrl.employeeMonthProjects.get(1).name);
        System.assertEquals(totalHours, fileCtrl.employeeMonthProjects.get(1).totalHours);
        System.assertEquals('Overhead', fileCtrl.employeeMonthProjects.get(2).name);
        Test.stopTest();
    }

    @isTest
    public static void testEmployeeCtrl() {
        String empId = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1].Id;
        String contrId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', EncodingUtil.urlDecode(empId, 'UTF-8'));
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode(String.valueOf(Date.today().year()), 'UTF-8'));
        Test.setCurrentPage(pageRef);

        Test.startTest(); // other logic was tested before, we want only test moving to other FTE views
        FTEEmployeeController emplCtrl = new FTEEmployeeController();

        PageReference pageRefTest = emplCtrl.goToEmployeeListView();
        System.assertNotEquals(null, pageRefTest);
        System.assertEquals(null, pageRefTest.getParameters().get('fteYear')); //same year we don't need to pass year parameter
        System.debug('pageRefTest.getUrl() - ' + pageRefTest.getUrl());
        System.assert(pageRefTest.getUrl().startsWith('/apex/fte_employee_list_view'));

        pageRefTest = emplCtrl.goToProjectListView();
        System.assertNotEquals(null, pageRefTest);
        System.assert(pageRefTest.getUrl().startsWith('/apex/fte_project_list_view'));

        emplCtrl.contractId = contrId;
        pageRefTest = emplCtrl.goToIndividualProjectView();
        System.assertNotEquals(null, pageRefTest);
        System.assertEquals(String.valueOf(Date.today().year()), pageRefTest.getParameters().get('fteYear'));
        System.assertEquals(contrId, pageRefTest.getParameters().get('contractId'));
        System.assert(pageRefTest.getUrl().startsWith('/apex/fte_individual_project_view'));

        emplCtrl.exportMonth = 2;
        pageRefTest = emplCtrl.goToTimeCardView();
        System.assertEquals(String.valueOf(Date.today().year()), pageRefTest.getParameters().get('fteYear'));
        System.assertEquals(empId, pageRefTest.getParameters().get('employeeId'));
        System.assertEquals('2', pageRefTest.getParameters().get('month'));
        System.assert(pageRefTest.getUrl().startsWith('/apex/fte_time_card_view'));
        Test.stopTest();
    }

    private static void assertFTEDataRecord(List<FTEUploadData> elements, String emplName, Integer fteYear, String contractName,
                                                Decimal m1, Decimal m2, Decimal m3, Decimal m4, Decimal m5, Decimal m6,
                                                Decimal m7, Decimal m8, Decimal m9, Decimal m10, Decimal m11, Decimal m12) {
        FTEUploadData rec;
        for (FTEUploadData el : elements) {
            if (el.getEmployeeName() == emplName) {
                if (rec != null) {
                    System.assert(false);
                }
                rec = el;
            }
        }

        System.assertEquals(fteYear, rec.getFTEYear());
        System.assertEquals(emplName, rec.getEmployeeName());
        System.assertEquals(contractName,  rec.getContractName());
        System.assertEquals(m1, rec.getMonthTime(1));
        System.assertEquals(m2, rec.getMonthTime(2));
        System.assertEquals(m3, rec.getMonthTime(3));
        System.assertEquals(m4, rec.getMonthTime(4));
        System.assertEquals(m5, rec.getMonthTime(5));
        System.assertEquals(m6, rec.getMonthTime(6));
        System.assertEquals(m7, rec.getMonthTime(7));
        System.assertEquals(m8, rec.getMonthTime(8));
        System.assertEquals(m9, rec.getMonthTime(9));
        System.assertEquals(m10, rec.getMonthTime(10));
        System.assertEquals(m11, rec.getMonthTime(11));
        System.assertEquals(m12, rec.getMonthTime(12));
    }

    private static String buildDataRow(String employeeName, Integer month, Decimal value) {
        String hoursRow = '';
        for (Integer i = 1; i <= 12; i++) {
            if (i != month) {
                hoursRow += ',' + ' 0 ';
            } else {
                hoursRow += ',' + value;
            }
        }

        return employeeName + hoursRow + '\n\r';
    }

    private static List<Decimal> sumHours(List<Time_Card__c> timeCards) {
        Decimal hoursTotalSum = 0;
        Decimal hoursMovedSum = 0;
        for (Time_Card__c tc : timeCards) {
            hoursTotalSum += tc.Total__c;
            if (tc.FTE_Contract__c != null) {
                hoursMovedSum += tc.FTE_Hours__c;
            }
        }

        return new Decimal[] {hoursTotalSum, hoursMovedSum};
    }

    private static SFDC_Employee__c addEmployee(String employeeName) {
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            Name = employeeName,
            Salary__c = 50000,
            Employee_Status__c = 'Active',
            Employee_Type__c = 'Employee',
            Exchange_Rate__c = 1,
            Hire_Date__c = Date.newInstance(Date.today().year(), 1, 1),
            Per_Week_Hours__c = 40
        );
        insert employeeObj;
        return employeeObj;
    }

    private static DContract__c addContract(String contractName, String fteTracker) {
        DContract__c contractObj = new DContract__c(
            Name = contractName,
            FTE_Tracker__c = fteTracker,
            Status__c = 'Active'
        );
        insert contractObj;
        return contractObj;
    }

    private static Time_Card__c addTimeCard(Id contractId, Id employeeId, Date timeCardDate, Decimal hours) {
        Time_Card__c timeCardObj = new Time_Card__c(
            Total__c = hours,
            Date__c = timeCardDate,
            Employee__c = employeeId,
            Client__c = contractId
        );
        return timeCardObj;
    }

    private static Time_Card__c addTimeCard(Id contractId, Id employeeId, Date timeCardDate, Decimal hours, Decimal fteHours, Id fteId) {
        Time_Card__c timeCardObj = new Time_Card__c(
            Total__c = hours,
            Date__c = timeCardDate,
            Employee__c = employeeId,
            Client__c = contractId,
            FTE_Hours__c = fteHours,
            FTE_Contract__c = fteId
        );
        return timeCardObj;
    }

    private static FTE_Work_Card__c addWorkCard(Id contractId,  SFDC_Employee__c employee, Decimal workCardYear) {
        FTE_Work_Card__c workCardObj = new FTE_Work_Card__c(Contract__c = contractId,  Employee__c = employee.Id, 
                                                                 Year__c = workCardYear, Month_1__c = 1,
                                                                 Month_2__c = 2, Month_3__c = 3, Month_4__c = 4, Month_5__c = 5, Month_6__c = 6,
                                                                 Month_7__c = 7, Month_8__c = 8, Month_9__c = 9, Month_10__c = 10, Month_11__c = 10,
                                                                 Month_12__c = 10, Total__c = 75, Total_Hours__c = 600
        );
        return workCardObj;
    }
    
    private static FTE_Work_Card__c addWorkCardWithSameHours(Id contractId,  SFDC_Employee__c employee, Decimal workCardYear) {
        FTE_Work_Card__c workCardObj = new FTE_Work_Card__c(Contract__c = contractId,  Employee__c = employee.Id, 
                                                                 Year__c = workCardYear, Month_1__c = 5,
                                                                 Month_2__c = 5, Month_3__c = 5, Month_4__c = 5, Month_5__c = 5, Month_6__c = 5,
                                                                 Month_7__c = 5, Month_8__c = 5, Month_9__c = 5, Month_10__c = 5, Month_11__c = 5,
                                                                 Month_12__c = 5, Total__c = 60, Total_Hours__c = 480
        );
        insert workCardObj;
        return workCardObj;
    }
    
    private static FTE_Tag__c addFteTag(Id contractId,  SFDC_Employee__c employee, Date currentDate) {
        FTE_Tag__c fteTagObj = new FTE_Tag__c(TC_Contract__c = contractId,  Employee__c = employee.Id, 
                                                                 Date__c = currentDate, Hours__c = -10, Action__c = 'Updated'
        );
        insert fteTagObj;
        return fteTagObj;
    }
}