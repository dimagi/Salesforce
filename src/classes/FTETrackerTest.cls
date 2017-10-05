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
        System.assertEquals(1, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Employee__r.Unloaded_Daily_Rate__c, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c ORDER BY Employee__r.Name];
        System.assertEquals(1, workCards.size());
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
        System.assertEquals(1, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Employee__r.Unloaded_Daily_Rate__c, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c ORDER BY Employee__r.Name];
        System.assertEquals(1, workCards.size());
        System.assertEquals(85.8, workCards.get(0).Total_Hours__c); // -25,6 + 19,3
        System.assertEquals(10.75, workCards.get(0).Total__c);
    }

    @isTest
    public static void shouldMoveHoursToUnassigned() {
        Date currentDate = Date.today();
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
}