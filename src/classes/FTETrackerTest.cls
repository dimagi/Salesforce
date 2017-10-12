@isTest
public class FTETrackerTest {

    @testSetup
    static void setup() {
        Date currentDate = Date.today();
        SFDC_Employee__c testEmployee = addEmployee('FTE Employee');
        Dcontract__c fteContract1 = addContract('FTE Contract 1', 'Yes');
        addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 1), 5);
        addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 2), 6);
        addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 3), 7);
        addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 4), 4.3);
        addTimeCard(fteContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3);

        Dcontract__c fteContract2 = addContract('FTE Contract 2', 'Yes');
        addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 6), 5);
        addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 7), 6);
        addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 8), 7);
        addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 9), 4.3);
        addTimeCard(fteContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 10), 3.3);

        Dcontract__c fteContract3 = addContract('FTE Contract 3', 'Yes');
        addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 11), 2);
        addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 12), 2);
        addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 13), 2);
        addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 14), 1);
        addTimeCard(fteContract3.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 15), 3.3);

        Dcontract__c fteContract4 = addContract('FTE Contract 4', 'Yes');
        addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 16), 5);
        addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 17), 9);
        addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 18), 9);
        addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 19), 4.3);
        addTimeCard(fteContract4.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 20), 3.3);

        Dcontract__c unassignedContract1 = addContract('Unassigned Contract 1', 'No');
        addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 5);
        addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 22), 6);
        addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 23), 1);
        addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 24), 4);
        addTimeCard(unassignedContract1.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 25), 3.3);

        Dcontract__c unassignedContract2 = addContract('Unassigned Contract 2', 'No');
        addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 1), 3);
        addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 2), 8);
        addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 3), 9);
        addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 4), 4.3);
        addTimeCard(unassignedContract2.Id, testEmployee.Id, Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3);

        SFDC_Employee__c testEmployee2 = addEmployee('Other Employee');

        addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 1), 8, 5,
                                                                                                unassignedContract1.Id);
        addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 2), 6);
        addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 3), 7);
        addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 4), 4.3);
        addTimeCard(fteContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3);

        addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 5);
        addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 22), 6);
        addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 23), 1);
        addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 24), 4);
        addTimeCard(unassignedContract1.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 25), 3.3);

        addTimeCard(fteContract4.Id, testEmployee2.Id, Date.newInstance(currentDate.year(), currentDate.month(), 16), 5, 2,
                                                                                                unassignedContract2.Id);

        SFDC_Employee__c testEmployee3 = addEmployee('Yyy Employee');

        addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 1), 3, 8,
                                                                                                unassignedContract1.Id);
        addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 2), 4);
        addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 3), 5);
        addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 4), 4.6);
        addTimeCard(fteContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 5), 2.5);

        addTimeCard(fteContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 6), 8);
        addTimeCard(fteContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 8), 8, 7,
                                                                                                unassignedContract1.Id);

        addTimeCard(fteContract3.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 9), 4);
        addTimeCard(fteContract3.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 10), 3, 5,
                                                                                                fteContract2.Id);

        addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 16), 0.5, 3,
                                                                                                fteContract3.Id);
        addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 17), 1.5);
        addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 18), 2);
        addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 19), 1);
        addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 20), 2);
        addTimeCard(fteContract4.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 1);

        addTimeCard(unassignedContract1.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 3);

        addTimeCard(unassignedContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 6, 16,
                                                                                                fteContract3.Id);
        addTimeCard(unassignedContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 5);
        addTimeCard(unassignedContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 7, 2,
                                                                                                fteContract4.Id);
        addTimeCard(unassignedContract2.Id, testEmployee3.Id, Date.newInstance(currentDate.year(), currentDate.month(), 21), 4);

        FTE_Tracker_Settings__c settings = FTE_Tracker_Settings__c.getOrgDefaults();
        settings.FTE_Year__c = Date.today().year();
        insert settings;
    }

    @isTest
    public static void shouldGenerateWorkCards() {
        Test.startTest();
        Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(Date.today().year()));
        Test.stopTest();
        List<SFDC_Employee__c> employees = [SELECT Id, Name, Unloaded_Daily_Rate__c FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
        System.assertEquals(3, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Employee__r.Unloaded_Daily_Rate__c, Month_1__c, Month_2__c, Month_3__c,
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

        List<SFDC_Employee__c> employees = [SELECT Id, Name, Unloaded_Daily_Rate__c FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
        System.assertEquals(3, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Employee__r.Unloaded_Daily_Rate__c, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c ORDER BY Employee__r.Name];
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
        FTETrackerController controller = new FTETrackerController();
        controller.employeeId = employee.Id;
        controller.loadEmployeeTimeHistory();
        controller.employeeMonth = currentDate.month() - 1;
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        controller.loadEmployeeUnassMonth();
        controller.fteDays = '3';
        controller.moveTimeToUnassigned();
        controller.backToEmployeeView();
        controller.loadEmployeeTimeHistory();
        System.assertEquals(70.9, controller.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(8.75, controller.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(68.1, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(8.5, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
    }

    @isTest
    public static void shouldAddErrorWhenMovingHoursToUnassigned() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        FTETrackerController controller = new FTETrackerController();
        controller.employeeId = employee.Id;
        controller.loadEmployeeTimeHistory();
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
        System.assert(b);
    }

    @isTest
    public static void shouldMoveHoursFromUnassigned() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        FTETrackerController controller = new FTETrackerController();
        controller.employeeId = employee.Id;
        controller.loadEmployeeTimeHistory();
        controller.employeeMonth = currentDate.month() - 1;
        controller.loadEmployeeMonth();
        controller.fteDays = '2.5';
        controller.selectedFteContract = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        controller.moveTimeFromUnassigned();
        controller.backToEmployeeView();
        controller.loadEmployeeTimeHistory();
        System.assertEquals(26.9, controller.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(3.25, controller.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(112.1, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(14, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
    }

    @isTest
    public static void shouldAddErrorWhenMovingHoursFromUnassigned() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        FTETrackerController controller = new FTETrackerController();
        controller.employeeId = employee.Id;
        controller.loadEmployeeTimeHistory();
        controller.employeeMonth = currentDate.month() - 1;
        controller.loadEmployeeMonth();
        controller.fteDays = '6';
        controller.moveTimeFromUnassigned();

        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains('Too much hours to assign / hours cannot be negative')) b = true;
        }
        System.assert(b);
    }

    @isTest
    public static void shouldGenerateEmployeeHours() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        FTETrackerController controller = new FTETrackerController();
        controller.employeeId = employee.Id;
        controller.loadEmployeeTimeHistory();
        System.assertEquals(46.9, controller.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(5.75, controller.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(92.1, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(11.5, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
    }

    @isTest
    public static void triggerShouldAddRemovedTags() {
        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;

        Date currentDate = Date.today();

        FTE_Tracker_Settings__c settings = FTE_Tracker_Settings__c.getOrgDefaults();
        settings.FTE_Trigger__c = true;
        update settings;

        Test.startTest();

        Time_Card__c tc1 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 1 AND Employee__r.Name = 'Other Employee' LIMIT 1];
        Time_Card__c tc2 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 2 AND Employee__r.Name = 'Other Employee' LIMIT 1];
        Time_Card__c tc3 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: contUn1 AND DAY_IN_MONTH(Date__c) = 22 AND Employee__r.Name = 'Other Employee' LIMIT 1];
        tc2.Total__c = 1;
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
        System.assertEquals(5, [SELECT Id FROM FTE_Tag__c].size());

        FTE_Tag__c testTag = [SELECT Id, Hours__c, Employee__r.Name, TC_Contract__r.Name, FTE_Contract__r.Name FROM FTE_Tag__c
                                WHERE Action__c = 'Tag Deleted' LIMIT 1];
        System.assertEquals('Other Employee' ,testTag.Employee__r.Name);
        System.assertEquals(5.0 ,testTag.Hours__c);
        System.assertEquals('FTE Contract 1' ,testTag.TC_Contract__r.Name);
        System.assertEquals('Unassigned Contract 1' ,testTag.FTE_Contract__r.Name);

        testTag = [SELECT Id, Hours__c, Employee__r.Name, TC_Contract__r.Name, FTE_Contract__r.Name FROM FTE_Tag__c
                    WHERE Action__c = 'Updated' AND DAY_IN_MONTH(Date__c) = 2 LIMIT 1];

        System.assertEquals('Other Employee' ,testTag.Employee__r.Name);
        System.assertEquals(-5.0 ,testTag.Hours__c);
        System.assertEquals('FTE Contract 1' ,testTag.TC_Contract__r.Name);

        testTag = [SELECT Id, Hours__c, Employee__r.Name, TC_Contract__r.Name, FTE_Contract__r.Name FROM FTE_Tag__c
                        WHERE Action__c = 'Updated' AND DAY_IN_MONTH(Date__c) = 22 LIMIT 1];

        System.assertEquals('Other Employee' ,testTag.Employee__r.Name);
        System.assertEquals(13.0 ,testTag.Hours__c);
        System.assertEquals('Unassigned Contract 1' ,testTag.TC_Contract__r.Name);

        testTag = [SELECT Id, Hours__c, Employee__r.Name, TC_Contract__r.Name, FTE_Contract__r.Name FROM FTE_Tag__c
                    WHERE Action__c = 'Updated' AND DAY_IN_MONTH(Date__c) = 27 LIMIT 1];
        System.assertEquals('Other Employee' ,testTag.Employee__r.Name);
        System.assertEquals(6.5 ,testTag.Hours__c);
        System.assertEquals('Unassigned Contract 1' ,testTag.TC_Contract__r.Name);
    }

    @isTest
    public static void batchShouldMoveRemovedFTETags() {
        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;

        Date currentDate = Date.today();

        FTE_Tracker_Settings__c settings = FTE_Tracker_Settings__c.getOrgDefaults();
        settings.FTE_Trigger__c = true;
        update settings;

        Test.startTest();

        Time_Card__c tc1 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont1 AND DAY_IN_MONTH(Date__c) = 1 AND Employee__r.Name = 'Other Employee' LIMIT 1];
        Time_Card__c tc2 = [SELECT Id, FTE_Contract__c, Total__c, FTE_Hours__c FROM Time_Card__c WHERE
                            Client__c =: cont4 AND DAY_IN_MONTH(Date__c) = 16 AND Employee__r.Name = 'Other Employee' LIMIT 1];

        List<Time_Card__c> triggerDelete = new List<Time_Card__c>();
        triggerDelete.add(tc1);
        triggerDelete.add(tc2);
        delete triggerDelete;

        Database.executeBatch(new FTEUpdateTagsBatch(false));

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
    public static void batchShouldFilleeNegativeFTETags1() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        FTE_Tracker_Settings__c settings = FTE_Tracker_Settings__c.getOrgDefaults();
        settings.FTE_Trigger__c = true;
        update settings;

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
        toUpd.add(tc3);
        toUpd.add(tc4);

        delete toDel;
        update toUpd;

        Database.executeBatch(new FTEUpdateTagsBatch(true));

        Test.stopTest();

        List<Time_Card__c> testTimeCards = [SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont1 AND Employee__r.Name = 'Other Employee'];

        Decimal hoursTotalSum = 0;
        Decimal hoursMovedSum = 0;
        for (Time_Card__c tc : testTimeCards) {
            hoursTotalSum += tc.Total__c;
            if (tc.FTE_Contract__c != null) {
                hoursMovedSum += tc.FTE_Hours__c;
            }
        }

        System.assertEquals(18.6, hoursTotalSum);
        System.assertEquals(5, hoursMovedSum);

        Time_Card__c tc2b = [SELECT Id, FTE_Only__c, FTE_Contract__c, Total__c, FTE_Hours__c, Client__c FROM Time_Card__c WHERE
                            Client__r.Name = 'FTE Contract 4' AND Employee__r.Name = 'Other Employee' LIMIT 1];
        System.assertEquals(cont4, tc2b.Client__c);
        System.assertEquals(true, tc2b.FTE_only__c);
        System.assertEquals(0, tc2b.FTE_Hours__c);
        System.assertEquals(null, tc2b.FTE_Contract__c);
    }

    @isTest
    public static void batchShouldFilleeNegativeFTETags2() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        Id cont1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id cont4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id contUn1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id contUn2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;

        FTE_Tracker_Settings__c settings = FTE_Tracker_Settings__c.getOrgDefaults();
        settings.FTE_Trigger__c = true;
        update settings;

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

        delete toDel;
        Database.executeBatch(new FTEUpdateTagsBatch(true));

        Test.stopTest();

        List<Time_Card__c> testTimeCards = [SELECT Id, Total__c, FTE_Hours__c, FTE_Contract__c FROM Time_Card__c WHERE Client__c =: cont1 AND Employee__r.Name = 'Other Employee'];

        Decimal hoursTotalSum = 0;
        Decimal hoursMovedSum = 0;
        for (Time_Card__c tc : testTimeCards) {
            hoursTotalSum += tc.Total__c;
            if (tc.FTE_Contract__c != null) {
                hoursMovedSum += tc.FTE_Hours__c;
            }
        }

        System.assertEquals(3.3, hoursTotalSum);
        System.assertEquals(3.3, hoursMovedSum);

        Time_Card__c tc2b = [SELECT Id, FTE_Only__c, FTE_Contract__c, Total__c, FTE_Hours__c, Client__c FROM Time_Card__c WHERE
                            Client__r.Name = 'FTE Contract 4' AND Employee__r.Name = 'Other Employee' LIMIT 1];
        System.assertEquals(cont4, tc2b.Client__c);
        System.assertEquals(true, tc2b.FTE_only__c);
        System.assertEquals(0, tc2b.FTE_Hours__c);
        System.assertEquals(null, tc2b.FTE_Contract__c);
    }

    @isTest
    public static void shouldGenerateCSVDataWithoutTags() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Integer emplMonth = Date.today().month();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(emplMonth, employee.Id);
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

        // FTE Contract 1
        System.assertEquals(5, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(7, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(0).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(0).hours[4]);

        // FTE Contract 2
        System.assertEquals(5, employeeMonthProjects.get(1).hours[5]);
        System.assertEquals(6, employeeMonthProjects.get(1).hours[6]);
        System.assertEquals(7, employeeMonthProjects.get(1).hours[7]);
        System.assertEquals(4.3, employeeMonthProjects.get(1).hours[8]);
        System.assertEquals(3.3, employeeMonthProjects.get(1).hours[9]);

        // FTE Contract 3
        System.assertEquals(2, employeeMonthProjects.get(2).hours[10]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[11]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[12]);
        System.assertEquals(1, employeeMonthProjects.get(2).hours[13]);
        System.assertEquals(3.3, employeeMonthProjects.get(2).hours[14]);

        // FTE Contract 4
        System.assertEquals(5, employeeMonthProjects.get(3).hours[15]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[16]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[17]);
        System.assertEquals(4.3, employeeMonthProjects.get(3).hours[18]);
        System.assertEquals(3.3, employeeMonthProjects.get(3).hours[19]);
    }

    @isTest
    public static void shouldGenerateCSVDataWithTags() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Integer emplMonth = Date.today().month();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(emplMonth, employee.Id);

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
        System.assertEquals(0, employeeMonthProjects.get(4).hours[0]);
        System.assertEquals(1.5, employeeMonthProjects.get(4).hours[1]);
        System.assertEquals(9, employeeMonthProjects.get(4).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(4).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(4).hours[4]);

        // FTE Contract 1
        System.assertEquals(0, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(4.3, employeeMonthProjects.get(0).hours[3]);
        System.assertEquals(3.3, employeeMonthProjects.get(0).hours[4]);

        // FTE Contract 2
        System.assertEquals(1, employeeMonthProjects.get(1).hours[0]);
        System.assertEquals(6, employeeMonthProjects.get(1).hours[1]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[2]);
        System.assertEquals(5, employeeMonthProjects.get(1).hours[5]);
        System.assertEquals(6, employeeMonthProjects.get(1).hours[6]);
        System.assertEquals(7, employeeMonthProjects.get(1).hours[7]);
        System.assertEquals(4.3, employeeMonthProjects.get(1).hours[8]);
        System.assertEquals(3.3, employeeMonthProjects.get(1).hours[9]);

        // FTE Contract 3
        System.assertEquals(2, employeeMonthProjects.get(2).hours[10]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[11]);
        System.assertEquals(2, employeeMonthProjects.get(2).hours[12]);
        System.assertEquals(1, employeeMonthProjects.get(2).hours[13]);
        System.assertEquals(3.3, employeeMonthProjects.get(2).hours[14]);

        // FTE Contract 4
        System.assertEquals(7, employeeMonthProjects.get(3).hours[0]);
        System.assertEquals(6.5, employeeMonthProjects.get(3).hours[1]);
        System.assertEquals(5, employeeMonthProjects.get(3).hours[15]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[16]);
        System.assertEquals(9, employeeMonthProjects.get(3).hours[17]);
        System.assertEquals(4.3, employeeMonthProjects.get(3).hours[18]);
        System.assertEquals(3.3, employeeMonthProjects.get(3).hours[19]);
    }

    private static SFDC_Employee__c addEmployee(String employeeName) {
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            Name = employeeName,
            Salary__c = 50000,
            Employee_Status__c = 'Active',
            Exchange_Rate__c = 1
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
        insert timeCardObj;
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
        insert timeCardObj;
        return timeCardObj;
    }
}