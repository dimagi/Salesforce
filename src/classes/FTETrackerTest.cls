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
    */

    @testSetup
    static void setup() {
        Date currentDate = Date.today();
        List<Time_Card__c> timeCards = new List<Time_Card__c>();

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
        System.assertEquals(3, workCards.size());
        System.assertEquals(92.1, workCards.get(0).Total_Hours__c);
        System.assertEquals(11.5, workCards.get(0).Total__c);
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
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c WHERE Year__c =: Date.today().year() ORDER BY Employee__r.Name];
        System.assertEquals(3, workCards.size());
        System.assertEquals(85.8, workCards.get(0).Total_Hours__c); // -25,6 + 19,3
        System.assertEquals(10.75, workCards.get(0).Total__c);
    }

    @isTest
    public static void shouldMoveHoursToUnassigned() {
        Date currentDate = Date.today();
        addTimeCard([SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id,
                    [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'].Id,
                    Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3);
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
        controller.fteDays = '3';
        controller.moveTimeToUnassigned();
        controller.initFteEmployeeView();
        Test.stopTest();

        System.assertEquals(70.9, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(8.75, controller.fteTimeManager.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(68.1, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(8.5, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
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

        System.assertEquals(26.9, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(3.25, controller.fteTimeManager.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(112.1, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(14, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
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
        controller.fteDays = '6';
        controller.moveTimeFromUnassigned();

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

        System.assertEquals(46.9, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(5.75, controller.fteTimeManager.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(92.1, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(11.5, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
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

/**
    @isTest
    public static void batchShouldFillNegativeFTETags1() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        SFDC_Employee__c employee2 = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee'];
        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont3 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        Test.startTest();

        List<Time_Card__c> toDel = new List<Time_Card__c>();
        List<Time_Card__c> toUpd = new List<Time_Card__c>();

        Time_Card__c tc1 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont4 LIMIT 1];
        Time_Card__c tc2 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont1 AND Total__c = 6 LIMIT 1];
        toDel.add(tc1);
        toDel.add(tc2);

        Time_Card__c tc3 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont1 AND Total__c = 4.3 LIMIT 1];
        Time_Card__c tc4 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont1 AND Total__c = 3.3 LIMIT 1];
        tc3.Total__c = 1.3;
        tc4.Total__c = 2.3;

        toDel.addAll([SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont4]);
        Time_Card__c tc5 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont1 AND Total__c = 4 LIMIT 1];
        Time_Card__c tc6 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont1 AND Total__c = 5 LIMIT 1];
        tc5.Total__c = 1;
        tc6.Total__c = 1;

        toUpd.add(tc3);
        toUpd.add(tc4);
        toUpd.add(tc5);
        toUpd.add(tc6);

        delete toDel;
        update toUpd;

        Database.executeBatch(new FTEUpdateTagsBatch(true));

        Test.stopTest();

        List<Decimal> results = sumHours([SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont1 AND Employee__r.Name = 'Other Employee']);
        System.assertEquals(18.6, results.get(0));
        System.assertEquals(5, results.get(1));

        Time_Card__c testTimeCard = [SELECT Id, FTE_Only__c, FTE_Contract__c, Total__c, FTE_Hours__c, Client__c FROM Time_Card__c WHERE
                            Client__r.Name = 'FTE Contract 4' AND Employee__r.Name = 'Other Employee' LIMIT 1];
        System.assertEquals(cont4, testTimeCard.Client__c);
        System.assertEquals(true, testTimeCard.FTE_only__c);
        System.assertEquals(0, testTimeCard.FTE_Hours__c);
        System.assertEquals(null, testTimeCard.FTE_Contract__c);

        results = sumHours([SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont1 AND Employee__r.Name = 'Yyy Employee']);
        System.assertEquals(12.1, results.get(0));
        System.assertEquals(8, results.get(1));

        testTimeCard = [SELECT Id, FTE_Only__c, FTE_Contract__c, Total__c, FTE_Hours__c, Client__c FROM Time_Card__c WHERE
                            Client__r.Name = 'FTE Contract 4' AND Employee__r.Name = 'Yyy Employee' LIMIT 1];
        System.assertEquals(cont4, testTimeCard.Client__c);
        System.assertEquals(true, testTimeCard.FTE_only__c);
        System.assertEquals(0, testTimeCard.Total__c);
        System.assertEquals(2, testTimeCard.FTE_Hours__c);
        System.assertEquals(cont3, testTimeCard.FTE_Contract__c);
    }

    @isTest
    public static void batchShouldFillNegativeFTETags2() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        SFDC_Employee__c employee2 = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee'];
        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id cont3 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        Test.startTest();

        List<Time_Card__c> toDel = new List<Time_Card__c>();
        List<Time_Card__c> toUpd = new List<Time_Card__c>();

        Time_Card__c tc1 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont4 LIMIT 1];
        Time_Card__c tc2 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont1 AND Total__c = 6 LIMIT 1];
        Time_Card__c tc3 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont1 AND Total__c = 8 LIMIT 1];
        Time_Card__c tc4 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont1 AND Total__c = 7 LIMIT 1];
        Time_Card__c tc5 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee.Id AND Client__c =: cont1 AND Total__c = 4.3 LIMIT 1];
        toDel.add(tc1);
        toDel.add(tc2);
        toDel.add(tc3);
        toDel.add(tc4);
        toDel.add(tc5);

        Time_Card__c tc6 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont1 AND Total__c = 4 LIMIT 1];
        Time_Card__c tc7 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont1 AND Total__c = 5 LIMIT 1];
        Time_Card__c tc8 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont1 AND Total__c = 4.6 LIMIT 1];
        Time_Card__c tc9 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont1 AND Total__c = 2.5 LIMIT 1];
        tc6.Total__c = 0.5;
        tc7.Total__c = 0.5;
        tc8.Total__c = 0.5;
        toDel.add(tc9);
        toUpd.add(tc6);
        toUpd.add(tc7);
        toUpd.add(tc8);

        Time_Card__c tc10 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont2 AND Total__c = 7 LIMIT 1];
        Time_Card__c tc11 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont2 AND Total__c = 9 LIMIT 1];
        tc10.Total__c = 1;
        tc11.Total__c = 7;
        toUpd.add(tc10);
        toUpd.add(tc11);

        Time_Card__c tc12 = [SELECT Id, Total__c FROM Time_Card__c WHERE Employee__c =: employee2.Id AND Client__c =: cont3 AND Total__c = 4 LIMIT 1];
        toDel.add(tc12);

        toDel.addAll([SELECT Id FROM Time_Card__c WHERE Client__c =: contUn2 AND Employee__r.Name = 'Yyy Employee']);

        delete toDel;
        update toUpd;
        Database.executeBatch(new FTEUpdateTagsBatch(true));

        Test.stopTest();

        List<Decimal> results = sumHours([SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont1 AND Employee__r.Name = 'Other Employee']);
        System.assertEquals(3.3, results.get(0));
        System.assertEquals(3.3, results.get(1));

        Time_Card__c tc2b = [SELECT Id, FTE_Only__c, FTE_Contract__c, Total__c, FTE_Hours__c, Client__c FROM Time_Card__c WHERE
                            Client__r.Name = 'FTE Contract 4' AND Employee__r.Name = 'Other Employee' LIMIT 1];
        System.assertEquals(cont4, tc2b.Client__c);
        System.assertEquals(true, tc2b.FTE_only__c);
        System.assertEquals(0, tc2b.FTE_Hours__c);
        System.assertEquals(null, tc2b.FTE_Contract__c);

        results = sumHours([SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont1 AND Employee__r.Name = 'Yyy Employee']);
        System.assertEquals(4.5, results.get(0));
        System.assertEquals(4.5, results.get(1));

        results = sumHours([SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont2 AND Employee__r.Name = 'Yyy Employee']);
        System.assertEquals(8, results.get(0));
        System.assertEquals(7, results.get(1));

        results = sumHours([SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont3 AND Employee__r.Name = 'Yyy Employee']);
        System.assertEquals(3, results.get(0));
        System.assertEquals(5, results.get(1));

        results = sumHours([SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: contUn2 AND Employee__r.Name = 'Yyy Employee']);
        System.assertEquals(0, results.get(0));
        System.assertEquals(0, results.get(1));

        results = sumHours([SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont4 AND Employee__r.Name = 'Yyy Employee']);
        System.assertEquals(8, results.get(0));
        System.assertEquals(3, results.get(1));
    }
*/

    @isTest
    public static void shouldGenerateCSVDataWithoutTags() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(fteYear, emplMonth, employee.Id);
        List<FTEMonthTimeCard> employeeMonthProjects = generator.generateMonthTimeCards();
        System.assertEquals(5, employeeMonthProjects.size());

        // Overhead
        System.assertEquals('Overhead', employeeMonthProjects.get(4).name);

        // Overhead - Unassigned Contract 1
        System.assertEquals(5, employeeMonthProjects.get(4).hours[20]);
        System.assertEquals(6, employeeMonthProjects.get(4).hours[21]);
        System.assertEquals(1, employeeMonthProjects.get(4).hours[22]);
        System.assertEquals(4, employeeMonthProjects.get(4).hours[23]);
        System.assertEquals(3.3, employeeMonthProjects.get(4).hours[24]);

        // Overhead - Unassigned Contract 2
        System.assertEquals(3, employeeMonthProjects.get(4).hours[0]);
        System.assertEquals(8, employeeMonthProjects.get(4).hours[1]);
        System.assertEquals(9, employeeMonthProjects.get(4).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(4).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(4).hours[4]);
        System.assertEquals(27.6 + 19.3, employeeMonthProjects.get(4).totalHours);

        // FTE Contract 1
        System.assertEquals(5, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(7, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(0).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(0).hours[4]);
        System.assertEquals(25.6, employeeMonthProjects.get(0).totalHours);

        // FTE Contract 2
        System.assertEquals(5, employeeMonthProjects.get(1).hours[5]);
        System.assertEquals(6, employeeMonthProjects.get(1).hours[6]);
        System.assertEquals(7, employeeMonthProjects.get(1).hours[7]);
        System.assertEquals(4.3, employeeMonthProjects.get(1).hours[8]);
        System.assertEquals(3.3, employeeMonthProjects.get(1).hours[9]);
        System.assertEquals(25.6, employeeMonthProjects.get(1).totalHours);

        // FTE Contract 3
        System.assertEquals(2, employeeMonthProjects.get(2).hours[10]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[11]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[12]);
        System.assertEquals(1, employeeMonthProjects.get(2).hours[13]);
        System.assertEquals(3.3, employeeMonthProjects.get(2).hours[14]);
        System.assertEquals(10.3, employeeMonthProjects.get(2).totalHours);

        // FTE Contract 4
        System.assertEquals(5, employeeMonthProjects.get(3).hours[15]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[16]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[17]);
        System.assertEquals(4.3, employeeMonthProjects.get(3).hours[18]);
        System.assertEquals(3.3, employeeMonthProjects.get(3).hours[19]);
        System.assertEquals(30.6, employeeMonthProjects.get(3).totalHours);
    }

    @isTest
    public static void shouldGenerateCSVDataWithTagsV1() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(fteYear, emplMonth, employee.Id);

        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id cont3 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        List<Time_Card__c> tcToUpdate = new List<Time_Card__c>();
        Time_Card__c tc1 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 3 LIMIT 1];
        tc1.FTE_Hours__c = 8;
        tc1.FTE_Contract__c = cont2;
        tcToUpdate.add(tc1);

        Time_Card__c tc2 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 2 LIMIT 1];
        tc2.FTE_Hours__c = 4;
        tc2.FTE_Contract__c = contUn2;
        tcToUpdate.add(tc2);

        Time_Card__c tc3 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: contUn1 AND DAY_IN_MONTH(Date__c) = 22 LIMIT 1];
        tc3.FTE_Hours__c = 13.5;
        tc3.FTE_Contract__c = cont4;
        tcToUpdate.add(tc3);

        update tcToUpdate;

        Test.setCreatedDate(cont1, DateTime.newInstance(Date.today().year() - 1, 1, 1));
        Test.setCreatedDate(cont2, DateTime.newInstance(Date.today().year() - 1, 2, 1));
        Test.setCreatedDate(cont3, DateTime.newInstance(Date.today().year() - 1, 3, 1));
        Test.setCreatedDate(cont4, DateTime.newInstance(Date.today().year() - 1, 4, 1));
        Test.setCreatedDate(contUn1, DateTime.newInstance(Date.today().year() - 1, 5, 1));
        Test.setCreatedDate(contUn2, DateTime.newInstance(Date.today().year() - 1, 6, 1));

        Test.startTest();
        List<FTEMonthTimeCard> employeeMonthProjects = generator.generateMonthTimeCards();
        System.assertEquals(5, employeeMonthProjects.size());
        Test.stopTest();

        // Overhead
        System.assertEquals('Overhead', employeeMonthProjects.get(4).name);

        // Overhead - Unassigned Contract 1
        System.assertEquals(0, employeeMonthProjects.get(4).hours[20]);
        System.assertEquals(0, employeeMonthProjects.get(4).hours[21]);
        System.assertEquals(0, employeeMonthProjects.get(4).hours[22]);
        System.assertEquals(2.5, employeeMonthProjects.get(4).hours[23]);
        System.assertEquals(3.3, employeeMonthProjects.get(4).hours[24]);

        // Overhead - Unassigned Contract 2
        System.assertEquals(3, employeeMonthProjects.get(4).hours[0]);
        System.assertEquals(11, employeeMonthProjects.get(4).hours[1]);
        System.assertEquals(10, employeeMonthProjects.get(4).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(4).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(4).hours[4]);
        System.assertEquals(5.8 + 31.6, employeeMonthProjects.get(4).totalHours);

        // FTE Contract 1
        System.assertEquals(0, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(0).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(0).hours[4]);
        System.assertEquals(13.6, employeeMonthProjects.get(0).totalHours);

        // FTE Contract 2
        System.assertEquals(5, employeeMonthProjects.get(1).hours[0]);
        System.assertEquals(3, employeeMonthProjects.get(1).hours[1]);
        System.assertEquals(5, employeeMonthProjects.get(1).hours[5]);
        System.assertEquals(6, employeeMonthProjects.get(1).hours[6]);
        System.assertEquals(7, employeeMonthProjects.get(1).hours[7]);
        System.assertEquals(4.3, employeeMonthProjects.get(1).hours[8]);
        System.assertEquals(3.3, employeeMonthProjects.get(1).hours[9]);
        System.assertEquals(33.6, employeeMonthProjects.get(1).totalHours);

        // FTE Contract 3
        System.assertEquals(2, employeeMonthProjects.get(2).hours[10]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[11]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[12]);
        System.assertEquals(1, employeeMonthProjects.get(2).hours[13]);
        System.assertEquals(3.3, employeeMonthProjects.get(2).hours[14]);
        System.assertEquals(10.3, employeeMonthProjects.get(2).totalHours);

        // FTE Contract 4
        System.assertEquals(5, employeeMonthProjects.get(3).hours[15]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[16]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[17]);
        System.assertEquals(4.3, employeeMonthProjects.get(3).hours[18]);
        System.assertEquals(3.3, employeeMonthProjects.get(3).hours[19]);
        System.assertEquals(5, employeeMonthProjects.get(3).hours[20]);
        System.assertEquals(6, employeeMonthProjects.get(3).hours[21]);
        System.assertEquals(1, employeeMonthProjects.get(3).hours[22]);
        System.assertEquals(1.5, employeeMonthProjects.get(3).hours[23]);
        System.assertEquals(44.1, employeeMonthProjects.get(3).totalHours);
    }

    @isTest
    public static void shouldGenerateCSVDataWithTagsV2() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(fteYear, emplMonth, employee.Id);

        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id cont3 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        List<Time_Card__c> tcToUpdate = new List<Time_Card__c>();
        Time_Card__c tc1 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont2 AND DAY_IN_MONTH(Date__c) = 6 LIMIT 1];
        tc1.FTE_Hours__c = 30;
        tc1.FTE_Contract__c = cont1;
        tcToUpdate.add(tc1);

        Time_Card__c tc2 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont3 AND DAY_IN_MONTH(Date__c) = 11 LIMIT 1];
        tc2.FTE_Hours__c = 8;
        tc2.FTE_Contract__c = cont2;
        tcToUpdate.add(tc2);

        Time_Card__c tc3 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 1 LIMIT 1];
        tc3.FTE_Hours__c = 12;
        tc3.FTE_Contract__c = cont3;
        tcToUpdate.add(tc3);

        update tcToUpdate;

        Test.setCreatedDate(cont1, DateTime.newInstance(Date.today().year() - 1, 1, 1));
        Test.setCreatedDate(cont2, DateTime.newInstance(Date.today().year() - 1, 2, 1));
        Test.setCreatedDate(cont3, DateTime.newInstance(Date.today().year() - 1, 3, 1));
        Test.setCreatedDate(cont4, DateTime.newInstance(Date.today().year() - 1, 4, 1));
        Test.setCreatedDate(contUn1, DateTime.newInstance(Date.today().year() - 1, 5, 1));
        Test.setCreatedDate(contUn2, DateTime.newInstance(Date.today().year() - 1, 6, 1));

        Test.startTest();
        List<FTEMonthTimeCard> employeeMonthProjects = generator.generateMonthTimeCards();
        System.assertEquals(5, employeeMonthProjects.size());
        Test.stopTest();

        // Overhead
        System.assertEquals('Overhead', employeeMonthProjects.get(4).name);

        // Overhead - Unassigned Contract 1
        System.assertEquals(5, employeeMonthProjects.get(4).hours[20]);
        System.assertEquals(6, employeeMonthProjects.get(4).hours[21]);
        System.assertEquals(1, employeeMonthProjects.get(4).hours[22]);
        System.assertEquals(4, employeeMonthProjects.get(4).hours[23]);
        System.assertEquals(3.3, employeeMonthProjects.get(4).hours[24]);

        // Overhead - Unassigned Contract 2
        System.assertEquals(3, employeeMonthProjects.get(4).hours[0]);
        System.assertEquals(8, employeeMonthProjects.get(4).hours[1]);
        System.assertEquals(9, employeeMonthProjects.get(4).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(4).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(4).hours[4]);
        System.assertEquals(19.3 + 27.6, employeeMonthProjects.get(4).totalHours);

        // FTE Contract 1
        System.assertEquals(0, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(0).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(0).hours[4]);
        System.assertEquals(5, employeeMonthProjects.get(0).hours[5]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[6]);
        System.assertEquals(7, employeeMonthProjects.get(0).hours[7]);
        System.assertEquals(4.3, employeeMonthProjects.get(0).hours[8]);
        System.assertEquals(3.3, employeeMonthProjects.get(0).hours[9]);
        System.assertEquals(2, employeeMonthProjects.get(0).hours[10]);
        System.assertEquals(2, employeeMonthProjects.get(0).hours[11]);
        System.assertEquals(0.4, employeeMonthProjects.get(0).hours[12]);
        System.assertEquals(43.6, employeeMonthProjects.get(0).totalHours);

        // FTE Contract 2
        System.assertEquals(0, employeeMonthProjects.get(1).hours[5]);
        System.assertEquals(0, employeeMonthProjects.get(1).hours[6]);
        System.assertEquals(0, employeeMonthProjects.get(1).hours[7]);
        System.assertEquals(0, employeeMonthProjects.get(1).hours[8]);
        System.assertEquals(0, employeeMonthProjects.get(1).hours[9]);
        System.assertEquals(0, employeeMonthProjects.get(1).hours[10]);
        System.assertEquals(0, employeeMonthProjects.get(1).hours[11]);
        System.assertEquals(1.6, employeeMonthProjects.get(1).hours[12]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[13]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[14]);
        System.assertEquals(3.6, employeeMonthProjects.get(1).totalHours);

        // FTE Contract 3
        System.assertEquals(5, employeeMonthProjects.get(2).hours[0]);
        System.assertEquals(6, employeeMonthProjects.get(2).hours[1]);
        System.assertEquals(1, employeeMonthProjects.get(2).hours[2]);
        System.assertEquals(0, employeeMonthProjects.get(2).hours[10]);
        System.assertEquals(0, employeeMonthProjects.get(2).hours[11]);
        System.assertEquals(0, employeeMonthProjects.get(2).hours[12]);
        System.assertEquals(0, employeeMonthProjects.get(2).hours[13]);
        System.assertEquals(2.3, employeeMonthProjects.get(2).hours[14]);
        System.assertEquals(14.3, employeeMonthProjects.get(2).totalHours);

        // FTE Contract 4
        System.assertEquals(5, employeeMonthProjects.get(3).hours[15]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[16]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[17]);
        System.assertEquals(4.3, employeeMonthProjects.get(3).hours[18]);
        System.assertEquals(3.3, employeeMonthProjects.get(3).hours[19]);
        System.assertEquals(30.6, employeeMonthProjects.get(3).totalHours);
    }

    @isTest
    public static void shouldGenerateCSVDataWithTagsV3() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(fteYear, emplMonth, employee.Id);

        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id cont3 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        Test.setCreatedDate(cont1, DateTime.newInstance(Date.today().year() - 1, 1, 1));
        Test.setCreatedDate(cont2, DateTime.newInstance(Date.today().year() - 1, 2, 1));
        Test.setCreatedDate(cont3, DateTime.newInstance(Date.today().year() - 1, 3, 1));
        Test.setCreatedDate(cont4, DateTime.newInstance(Date.today().year() - 1, 4, 1));
        Test.setCreatedDate(contUn1, DateTime.newInstance(Date.today().year() - 1, 5, 1));
        Test.setCreatedDate(contUn2, DateTime.newInstance(Date.today().year() - 1, 6, 1));

        Test.startTest();
        List<FTEMonthTimeCard> employeeMonthProjects = generator.generateMonthTimeCards();
        System.assertEquals(3, employeeMonthProjects.size());
        Test.stopTest();

        // Overhead
        System.assertEquals('Overhead', employeeMonthProjects.get(2).name);

        // Overhead - Unassigned Contract 1
        System.assertEquals(5, employeeMonthProjects.get(2).hours[20]);
        System.assertEquals(6, employeeMonthProjects.get(2).hours[21]);
        System.assertEquals(1, employeeMonthProjects.get(2).hours[22]);
        System.assertEquals(4, employeeMonthProjects.get(2).hours[23]);
        System.assertEquals(3.3, employeeMonthProjects.get(2).hours[24]);

        // Overhead - Unassigned Contract 2
        System.assertEquals(2, employeeMonthProjects.get(2).hours[15]);
        System.assertEquals(24.3 + 2, employeeMonthProjects.get(2).totalHours);

        // FTE Contract 1
        System.assertEquals(3, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(7, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(0).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(0).hours[4]);
        System.assertEquals(23.6, employeeMonthProjects.get(0).totalHours);

        // FTE Contract 4
        System.assertEquals(3, employeeMonthProjects.get(1).hours[15]);
        System.assertEquals(3, employeeMonthProjects.get(1).totalHours);
    }

    @isTest
    public static void shouldGenerateCSVDataWithTagsV4() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee'];
        Integer emplMonth = Date.today().month();
        Integer fteYear = Date.today().year();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(fteYear, emplMonth, employee.Id);

        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id cont3 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        List<Time_Card__c> tcToUpdate = new List<Time_Card__c>();
        Time_Card__c tc1 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont2 AND DAY_IN_MONTH(Date__c) = 6 LIMIT 1];
        tc1.FTE_Hours__c = 30;
        tc1.FTE_Contract__c = cont1;
        tcToUpdate.add(tc1);

        Time_Card__c tc2 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont3 AND DAY_IN_MONTH(Date__c) = 11 LIMIT 1];
        tc2.FTE_Hours__c = 8;
        tc2.FTE_Contract__c = cont2;
        tcToUpdate.add(tc2);

        Time_Card__c tc3 = [SELECT Id, FTE_Contract__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 1 LIMIT 1];
        tc3.FTE_Hours__c = 12;
        tc3.FTE_Contract__c = cont3;
        tcToUpdate.add(tc3);

        update tcToUpdate;

        Test.setCreatedDate(cont1, DateTime.newInstance(Date.today().year() - 1, 1, 1));
        Test.setCreatedDate(cont2, DateTime.newInstance(Date.today().year() - 1, 2, 1));
        Test.setCreatedDate(cont3, DateTime.newInstance(Date.today().year() - 1, 3, 1));
        Test.setCreatedDate(cont4, DateTime.newInstance(Date.today().year() - 1, 4, 1));
        Test.setCreatedDate(contUn1, DateTime.newInstance(Date.today().year() - 1, 5, 1));
        Test.setCreatedDate(contUn2, DateTime.newInstance(Date.today().year() - 1, 6, 1));

        Test.startTest();
        List<FTEMonthTimeCard> employeeMonthProjects = generator.generateMonthTimeCards();
        System.assertEquals(5, employeeMonthProjects.size());
        Test.stopTest();

        // Overhead
        System.assertEquals('Overhead', employeeMonthProjects.get(4).name);

        // Overhead - Unassigned Contract 1
        System.assertEquals(3, employeeMonthProjects.get(4).hours[0]);
        System.assertEquals(4, employeeMonthProjects.get(4).hours[1]);
        System.assertEquals(1, employeeMonthProjects.get(4).hours[2]);
        System.assertEquals(7, employeeMonthProjects.get(4).hours[5]);
        System.assertEquals(3, employeeMonthProjects.get(4).hours[20]);

        // Overhead - Unassigned Contract 2
        System.assertEquals(0, employeeMonthProjects.get(4).hours[21]);
        System.assertEquals(0, employeeMonthProjects.get(4).hours[22]);
        System.assertEquals(4, employeeMonthProjects.get(4).hours[23]);
        System.assertEquals(18 + 4, employeeMonthProjects.get(4).totalHours);

        // FTE Contract 1
        System.assertEquals(0, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(4, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(4.6, employeeMonthProjects.get(0).hours[3]);
        System.assertEquals(2.5, employeeMonthProjects.get(0).hours[4]);
        System.assertEquals(11.1, employeeMonthProjects.get(0).totalHours);

        // FTE Contract 2
        System.assertEquals(2, employeeMonthProjects.get(1).hours[5]);
        System.assertEquals(7, employeeMonthProjects.get(1).hours[7]);
        System.assertEquals(4, employeeMonthProjects.get(1).hours[8]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[9]);
        System.assertEquals(14, employeeMonthProjects.get(1).totalHours);

        // FTE Contract 3
        System.assertEquals(0, employeeMonthProjects.get(2).hours[8]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[9]);
        System.assertEquals(0.5, employeeMonthProjects.get(2).hours[15]);
        System.assertEquals(1.5, employeeMonthProjects.get(2).hours[16]);
        System.assertEquals(1, employeeMonthProjects.get(2).hours[17]);
        System.assertEquals(6, employeeMonthProjects.get(2).hours[20]);
        System.assertEquals(5, employeeMonthProjects.get(2).hours[21]);
        System.assertEquals(5, employeeMonthProjects.get(2).hours[22]);
        System.assertEquals(21, employeeMonthProjects.get(2).totalHours);

        // FTE Contract 4
        System.assertEquals(0, employeeMonthProjects.get(3).hours[15]);
        System.assertEquals(0, employeeMonthProjects.get(3).hours[16]);
        System.assertEquals(1, employeeMonthProjects.get(3).hours[17]);
        System.assertEquals(1, employeeMonthProjects.get(3).hours[18]);
        System.assertEquals(2, employeeMonthProjects.get(3).hours[19]);
        System.assertEquals(1, employeeMonthProjects.get(3).hours[20]);
        System.assertEquals(2, employeeMonthProjects.get(3).hours[22]);
        System.assertEquals(7, employeeMonthProjects.get(3).totalHours);
    }

    @isTest
    public static void csvParseControllerTest() {
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String correctData = '\t\t\t\t\t\t\n\r '
                           + 'FTE Contract 1 \t01/' + fteYear + '\t 02/' + fteYear + '\t 03/' + fteYear + '\t 04/' + fteYear + '\t 05/' + fteYear + '\t 06/' + fteYear + '\t 07/' + fteYear
                           + '\t 08/' + fteYear + '\t 09/' + fteYear + '\t 10/' + fteYear + '\t 11/' + fteYear + '\t 12/' + fteYear + '\n\r'
                           + 'Other Employee\t1\t2\t3\t4\t5\t6\t7\t8\t9\t10\t11\t12\n\r'
                           + 'FTE Employee\t3\t4\t5\t6\t7\t8\t9\t10\t11\t12\t13\t14\n\r'
                           + 'Yyy Employee\t12\t11\t10\t9\t8\t7\t6\t5\t4\t3\t2\t1\n\r';
        FTECsvUploadController csvUpload = new FTECsvUploadController();

        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Test.stopTest();

        System.assertEquals(3, [SELECT count() FROM FTE_Data_Record__c]);
        assertFTEDataRecord('Other Employee', fteYear, 'FTE Contract 1', 3, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
        assertFTEDataRecord('FTE Employee', fteYear, 'FTE Contract 1', 4, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
        assertFTEDataRecord('Yyy Employee', fteYear, 'FTE Contract 1', 5, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
    }

    @isTest
    public static void shouldUploadAndMoveCSVDataSample1() {
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String correctData = '\t\t\t\t\t\t\n\r '
                           + 'FTE Contract 1 \t01/' + fteYear + '\t 02/' + fteYear + '\t 03/' + fteYear + '\t 04/' + fteYear + '\t 05/' + fteYear + '\t 06/' + fteYear + '\t 07/' + fteYear
                           + '\t 08/' + fteYear + '\t 09/' + fteYear + '\t 10/' + fteYear + '\t 11/' + fteYear + '\t 12/' + fteYear + '\n\r'
                           + buildDataRow('Other Employee', fteMonth, 5.0)
                           + buildDataRow('FTE Employee', fteMonth, 7.0)
                           + buildDataRow('Yyy Employee', fteMonth, 4.0);

        FTECsvUploadController csvUpload = new FTECsvUploadController();

        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        System.assertEquals(3, [SELECT count() FROM FTE_Data_Record__c]);

        csvUpload.getFTEDataRecords();
        csvUpload.processFTEDataRecords();
        Test.stopTest();

        for (FTE_Data_Record_Status__c rec : [SELECT Status__c, Status_Message__c, Line_Number__c, Line_Number_Text__c FROM FTE_Data_Record_Status__c]) {
            System.debug('Status Error Record : ' + rec);
        }
        System.assertEquals(0, [SELECT count() FROM FTE_Data_Record_Status__c]);

        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Id contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1'].Id;
        FTETimeManager timeManager = new FTETimeManager(employee, fteYear);
        timeManager.loadEmployeeTime();

        System.assertEquals(56, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDays();
        System.assertEquals(7, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);

        employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        timeManager = new FTETimeManager(employee, fteYear);
        timeManager.loadEmployeeTime();

        System.assertEquals(40, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDays();
        System.assertEquals(5, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);

        employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee'];
        timeManager = new FTETimeManager(employee, fteYear);
        timeManager.loadEmployeeTime();

        System.assertEquals(32, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDays();
        System.assertEquals(4, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
    }

    @isTest
    public static void shouldUploadAndMoveCSVDataSample2() {
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String correctData = '\t\t\t\t\t\t\n\r '
                           + 'FTE Contract 1 \t01/' + fteYear + '\t 02/' + fteYear + '\t 03/' + fteYear + '\t 04/' + fteYear + '\t 05/' + fteYear + '\t 06/' + fteYear + '\t 07/' + fteYear
                           + '\t 08/' + fteYear + '\t 09/' + fteYear + '\t 10/' + fteYear + '\t 11/' + fteYear + '\t 12/' + fteYear + '\n\r'
                           + buildDataRow('Other Employee', fteMonth, 1.0)
                           + buildDataRow('FTE Employee', fteMonth, 1.0)
                           + buildDataRow('Yyy Employee', fteMonth, 1.0);

        FTECsvUploadController csvUpload = new FTECsvUploadController();

        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        System.assertEquals(3, [SELECT count() FROM FTE_Data_Record__c]);

        csvUpload.getFTEDataRecords();
        csvUpload.processFTEDataRecords();
        Test.stopTest();

        for (FTE_Data_Record_Status__c rec : [SELECT Status__c, Status_Message__c, Line_Number__c, Line_Number_Text__c FROM FTE_Data_Record_Status__c]) {
            System.debug('Status Error Record : ' + rec);
        }
        System.assertEquals(0, [SELECT count() FROM FTE_Data_Record_Status__c]);

        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Id contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1'].Id;
        FTETimeManager timeManager = new FTETimeManager(employee, fteYear);
        timeManager.loadEmployeeTime();

        System.assertEquals(8, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDays();
        System.assertEquals(1, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(64.5, timeManager.unassigned.hoursArray[fteMonth - 1]);
        timeManager.unassigned.calculateDays();
        System.assertEquals(8, timeManager.unassigned.daysArray[fteMonth - 1]);

        employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        timeManager = new FTETimeManager(employee, fteYear);
        timeManager.loadEmployeeTime();

        System.assertEquals(8, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDays();
        System.assertEquals(1, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(41.9, timeManager.unassigned.hoursArray[fteMonth - 1]);
        timeManager.unassigned.calculateDays();
        System.assertEquals(5.25, timeManager.unassigned.daysArray[fteMonth - 1]);

        employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee'];
        timeManager = new FTETimeManager(employee, fteYear);
        timeManager.loadEmployeeTime();

        System.assertEquals(8, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDays();
        System.assertEquals(1, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(25.1, timeManager.unassigned.hoursArray[fteMonth - 1]);
        timeManager.unassigned.calculateDays();
        System.assertEquals(3.25, timeManager.unassigned.daysArray[fteMonth - 1]);
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

        emplListCtrl.employeeNameSearch = 'other';
        emplListCtrl.searchEmplopyee();
        workCardList = emplListCtrl.getEmployeesList();

        System.assertEquals(1, workCardList.size());
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
        System.assertEquals(4, projCtrl.individualContractDataList.size()); // 3 employees and 1 total row
        System.assertEquals('Total', projCtrl.individualContractDataList.get(3).name);

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
        fileCtrl.loadExportTimeCards();
        System.assertEquals(Date.daysInMonth(Date.today().year(), Date.today().month()), fileCtrl.rowList.size());
        System.assertEquals(5, fileCtrl.employeeMonthProjects.size()); // 4 FTE contracts and 1 overhead sum
        System.assertEquals('FTE Contract 1', fileCtrl.employeeMonthProjects.get(0).name);
        System.assertEquals(25.6, fileCtrl.employeeMonthProjects.get(0).totalHours);
        System.assertEquals('FTE Contract 2', fileCtrl.employeeMonthProjects.get(1).name);
        System.assertEquals(25.6, fileCtrl.employeeMonthProjects.get(1).totalHours);
        System.assertEquals('FTE Contract 3', fileCtrl.employeeMonthProjects.get(2).name);
        System.assertEquals(10.3, fileCtrl.employeeMonthProjects.get(2).totalHours);
        System.assertEquals('FTE Contract 4', fileCtrl.employeeMonthProjects.get(3).name);
        System.assertEquals(30.6, fileCtrl.employeeMonthProjects.get(3).totalHours);
        System.assertEquals('Overhead', fileCtrl.employeeMonthProjects.get(4).name);
        System.assertEquals(19.3 + 27.6, fileCtrl.employeeMonthProjects.get(4).totalHours);
        Test.stopTest();
    }

    @isTest
    public static void testFileCtrlWithDownloadAndWithTags() {
        String empId = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee' LIMIT 1].Id;
        PageReference pageRef = Page.FTE_Download_File;
        pageRef.getParameters().put('employeeId', EncodingUtil.urlDecode(empId, 'UTF-8'));
        pageRef.getParameters().put('fteYear', EncodingUtil.urlDecode(String.valueOf(Date.today().year()), 'UTF-8'));
        pageRef.getParameters().put('month', EncodingUtil.urlDecode(String.valueOf(Date.today().month()), 'UTF-8'));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEFileController fileCtrl = new FTEFileController();
        System.assertNotEquals(null, fileCtrl.csvFile);
        System.assert(String.isNotBlank(fileCtrl.csvFile));
        System.assertEquals('Yyy_Employee_' + (DateTime.newInstance(Date.today().year(), Date.today().month(), 1).format('MMMM'))
                                            + '_' + Date.today().year() + '.csv', fileCtrl.fileName);

        fileCtrl.loadExportTimeCards();
        System.assertEquals(Date.daysInMonth(Date.today().year(), Date.today().month()), fileCtrl.rowList.size());
        System.assertEquals(5, fileCtrl.employeeMonthProjects.size()); // 4 FTE contracts and 1 overhead sum
        System.assertEquals('FTE Contract 1', fileCtrl.employeeMonthProjects.get(0).name);
        System.assertEquals(19.1 - 8, fileCtrl.employeeMonthProjects.get(0).totalHours);
        System.assertEquals('FTE Contract 2', fileCtrl.employeeMonthProjects.get(1).name);
        System.assertEquals(16 - 7 + 5, fileCtrl.employeeMonthProjects.get(1).totalHours);
        System.assertEquals('FTE Contract 3', fileCtrl.employeeMonthProjects.get(2).name);
        System.assertEquals(7 - 5 + 3 + 16, fileCtrl.employeeMonthProjects.get(2).totalHours);
        System.assertEquals('FTE Contract 4', fileCtrl.employeeMonthProjects.get(3).name);
        System.assertEquals(8 - 3 + 2 , fileCtrl.employeeMonthProjects.get(3).totalHours);
        System.assertEquals('Overhead', fileCtrl.employeeMonthProjects.get(4).name);
        System.assertEquals(3 + 22 + 8 + 7 - 16 - 2, fileCtrl.employeeMonthProjects.get(4).totalHours);
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

    private static void assertFTEDataRecord(String emplName, Integer fteYear, String contractName, Integer lineNum, Decimal m1, Decimal m2, Decimal m3, Decimal m4,
                                                Decimal m5, Decimal m6, Decimal m7, Decimal m8, Decimal m9, Decimal m10, Decimal m11, Decimal m12) {
        FTE_Data_Record__c rec = [SELECT Year__c, Year_Text__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c,
                                Month_10__c, Month_11__c, Month_12__c, Message__c, Employee__c, Employee__r.Name, Processed__c, Contract__c, Contract__r.Name, Line_Number__c
                                FROM FTE_Data_Record__c WHERE Employee__r.Name =: emplName LIMIT 1];
        System.assertEquals(fteYear, rec.Year__c);
        System.assertEquals(emplName, rec.Employee__r.Name);
        System.assertEquals(contractName,  rec.Contract__r.Name);
        System.assertEquals(lineNum, rec.Line_Number__c);
        System.assertEquals(m1, rec.Month_1__c);
        System.assertEquals(m2, rec.Month_2__c);
        System.assertEquals(m3, rec.Month_3__c);
        System.assertEquals(m4, rec.Month_4__c);
        System.assertEquals(m5, rec.Month_5__c);
        System.assertEquals(m6, rec.Month_6__c);
        System.assertEquals(m7, rec.Month_7__c);
        System.assertEquals(m8, rec.Month_8__c);
        System.assertEquals(m9, rec.Month_9__c);
        System.assertEquals(m10, rec.Month_10__c);
        System.assertEquals(m11, rec.Month_11__c);
        System.assertEquals(m12, rec.Month_12__c);
    }

    private static String buildDataRow(String employeeName, Integer month, Decimal value) {
        String hoursRow = '';
        for (Integer i = 1; i <= 12; i++) {
            if (i != month) {
                hoursRow += '\t' + ' 0 ';
            } else {
                hoursRow += '\t' + value;
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
}