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
        System.assertEquals(92.1, workCards.get(0).Total_Hours__c, 1);
        System.assertEquals(11.5, workCards.get(0).Total__c, 1);
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