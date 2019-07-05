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




    /**
     * Work Cards tests
     */
    @isTest
    public static void shouldGenerateWorkCards() {
        FTE_Work_Card__c oldWorkCard =  new FTE_Work_Card__c(Employee__c = [SELECT Id FROM SFDC_Employee__c LIMIT 1].Id, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be deleted
        insert oldWorkCard;

        Test.startTest();
        Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch());
        Test.stopTest();
        List<SFDC_Employee__c> employees = [SELECT Id, Name FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
        System.assertEquals(3, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c WHERE Year__c =: Date.today().year() ORDER BY Employee__r.Name];
        System.assertEquals(3, workCards.size());
        System.assertEquals(92.1, workCards.get(0).Total_Hours__c);
        System.assertEquals(11.5, workCards.get(0).Total__c);
        System.assertEquals(0, [SELECT Id FROM FTE_Work_Card__c WHERE Id =: oldWorkCard.Id].size());
    }

    @isTest
    public static void shouldGenerateWorkCardsByWorkCardId() {
        Id employeeId = [SELECT Id FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name LIMIT 1].Id;
        FTE_Work_Card__c oldWorkCard =  new FTE_Work_Card__c(Employee__c = employeeId, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be deleted
        insert oldWorkCard;

        Test.startTest();
        Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch(new Set<Id> { oldWorkCard.Id }));
        Test.stopTest();
        List<SFDC_Employee__c> employees = [SELECT Id, Name FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
        System.assertEquals(3, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c WHERE Year__c =: Date.today().year() ORDER BY Employee__r.Name];
        System.assertEquals(1, workCards.size());
        System.assertEquals(92.1, workCards.get(0).Total_Hours__c);
        System.assertEquals(11.5, workCards.get(0).Total__c);
    }

    @isTest
    public static void shouldGenerateWorkCardsWIthTemplateData() {
        List<SFDC_Employee__c> employees = [SELECT Id, Name FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];

        DContract__c fteContract1 = [SELECT Id, FTE_Tracker__c FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1];
        Dcontract__c fteContract2 = addContract('FTE Contract Fake 1', 'Yes');
        Dcontract__c fteContract3 = addContract('FTE Contract Fake 2', 'No');

        FTE_Data_Record__c record1 =  new FTE_Data_Record__c(Employee__c = employees.get(0).Id, Contract__c = fteContract2.Id, Year__c = Date.today().year());
        FTE_Data_Record__c record2 =  new FTE_Data_Record__c(Employee__c = employees.get(0).Id, Contract__c = fteContract3.Id, Year__c = Date.today().year()); // this should be skipped
        FTE_Data_Record__c record3 =  new FTE_Data_Record__c(Employee__c = employees.get(0).Id, Contract__c = fteContract1.Id, Year__c = Date.today().year());
        SObject sObj1 = (SObject) record1;
        SObject sObj2 = (SObject) record2;
        SObject sObj3 = (SObject) record3;
        sObj1.put(FTETrackerHelper.getFieldName(Date.today().month()), 4);
        sObj2.put(FTETrackerHelper.getFieldName(Date.today().month()), 8);
        sObj3.put(FTETrackerHelper.getFieldName(Date.today().month()), 6);
        insert sObj1;
        insert sObj2;
        insert sObj3;

        Test.startTest();
        Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch());
        Test.stopTest();

        System.assertEquals(3, employees.size());
        List<FTE_Work_Card__c> workCards = [SELECT Id, Employee__c, Employee__r.Name, Month_1__c, Month_2__c, Month_3__c,
                                   Month_4__c, Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                   Total__c, Total_Hours__c, Year__c FROM FTE_Work_Card__c WHERE Year__c =: Date.today().year() ORDER BY Employee__r.Name];
        System.assertEquals(3, workCards.size());
        System.assertEquals(146.5, workCards.get(0).Total_Hours__c);
        System.assertEquals(18.25, workCards.get(0).Total__c);
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
        Database.executeBatch(new FTEGenerateEmployeesWorkCardBatch());
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




    /**
     * Tags tests
     */
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
     * FTE Triggers tests
     */
    @isTest
    public static void testContractTrigger() {
        SFDC_Employee__c empl1 = addEmployee('FTE test1');
        SFDC_Employee__c empl2 = addEmployee('FTE test2');
        DContract__c dContract1 = addContract('Trigger contract 1', 'No');
        DContract__c dContract2 = addContract('Trigger contract 2', 'No');
        DContract__c  dContract3 = addContract('Trigger contract 2', 'No');

        insert new List<FTE_Data_Record__c> {
                        new FTE_Data_Record__c(Contract__c = dContract1.Id, Employee__c = empl1.Id),
                        new FTE_Data_Record__c(Contract__c = dContract2.Id, Employee__c = empl1.Id),
                        new FTE_Data_Record__c(Contract__c = dContract3.Id, Employee__c = empl1.Id),
                        new FTE_Data_Record__c(Contract__c = dContract1.Id, Employee__c = empl2.Id)
                    };

        Test.startTest();
        dContract1.FTE_Tracker__c = 'Yes';
        dContract2.FTE_Tracker__c = 'Yes';
        dContract3.FTE_Tracker__c = 'Yes';
        update new List<DContract__c> { dContract1, dContract2, dContract3 };
        Test.stopTest();

        List<FTE_Data_Record__c> tamplates = [SELECT Id, Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c,
                                              Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                              FROM FTE_Data_Record__c];
        System.assertEquals(4, tamplates.size());
        assertTemplateUpdated(tamplates.get(0));
        assertTemplateUpdated(tamplates.get(1));
        assertTemplateUpdated(tamplates.get(2));
        assertTemplateUpdated(tamplates.get(3));
    }

    @isTest
    public static void testTimeLoggedTrigger() {
        SFDC_Employee__c empl1 = addEmployee('FTE test1');
        SFDC_Employee__c empl2 = addEmployee('FTE test2');
        DContract__c dContract1 = addContract('Trigger contract 1', 'Yes');
        DContract__c dContract2 = addContract('Trigger contract 2', 'Yes');
        DContract__c  dContract3 = addContract('Trigger contract 3', 'Yes');
        Integer currentYear = Date.today().year();
        insert new List<FTE_Data_Record__c> {
                        new FTE_Data_Record__c(Year__c = currentYear, Contract__c = dContract1.Id, Employee__c = empl1.Id),
                        new FTE_Data_Record__c(Year__c = currentYear, Contract__c = dContract2.Id, Employee__c = empl1.Id),
                        new FTE_Data_Record__c(Year__c = currentYear, Contract__c = dContract3.Id, Employee__c = empl1.Id),
                        new FTE_Data_Record__c(Year__c = currentYear, Contract__c = dContract1.Id, Employee__c = empl2.Id)
                    };

        Test.startTest();
        List<Time_Card__c> testTimeCards = new List<Time_Card__c> {
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 3, 1), Employee__c = empl1.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 3, 21), Employee__c = empl1.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 3, 3), Employee__c = empl1.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 1, 1), Employee__c = empl1.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 1, 5), Employee__c = empl1.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 1, 6), Employee__c = empl1.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 9, 7), Employee__c = empl1.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 12, 5), Employee__c = empl1.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 12, 6), Employee__c = empl1.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 12, 7), Employee__c = empl1.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 11, 5), Employee__c = empl1.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 10, 6), Employee__c = empl1.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 9, 7), Employee__c = empl1.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 10, 5), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 7, 6), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 6, 7), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 6, 5), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 6, 6), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 5, 7), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 3, 5), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 4, 6), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 8, 7), Employee__c = empl2.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 8, 5), Employee__c = empl2.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 8, 6), Employee__c = empl2.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 8, 7), Employee__c = empl2.Id, Client__c = dContract1.Id)
                    };
        insert testTimeCards;
        Test.stopTest();

        List<FTE_Data_Record__c> tamplates = [SELECT Id, Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c,
                                              Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                              FROM FTE_Data_Record__c];
        System.assertEquals(4, tamplates.size());

        FTE_Data_Record__c testTemplate = [SELECT Id, Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c,
                                           Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                           FROM FTE_Data_Record__c WHERE Contract__c =: dContract1.Id AND Employee__c =: empl1.Id LIMIT 1];
        assertTemplateUpdated(testTemplate, true, false, true, false, false, false, false, false, true, false, false, false);

        testTemplate = [SELECT Id, Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c,
                                           Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                           FROM FTE_Data_Record__c WHERE Contract__c =: dContract2.Id AND Employee__c =: empl1.Id LIMIT 1];
        assertTemplateUpdated(testTemplate, false, false, false, false, false, false, false, false, true, true, true, true);

        testTemplate = [SELECT Id, Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c,
                                           Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                           FROM FTE_Data_Record__c WHERE Contract__c =: dContract3.Id AND Employee__c =: empl1.Id LIMIT 1];
        assertTemplateUpdated(testTemplate, false, false, true, true, true, true, true, false, false, true, false, false);

        testTemplate = [SELECT Id, Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c,
                                           Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                           FROM FTE_Data_Record__c WHERE Contract__c =: dContract1.Id AND Employee__c =: empl2.Id LIMIT 1];
        assertTemplateUpdated(testTemplate, false, false, false, false, false, false, false, true, false, false, false, false);
    }

    @isTest
    public static void testTriggerWhenUnassignedWasLogged() {
        SFDC_Employee__c empl1 = addEmployee('FTE test1');
        DContract__c dContract1 = addContract('Trigger contract 1', 'Yes');
        DContract__c dContract2 = addContract('Trigger contract 2', 'Yes');
        DContract__c  dContract3 = addContract('Trigger contract 3', 'No');
        DContract__c  dContract4 = addContract('Trigger contract 4', 'No');
        Integer currentYear = Date.today().year();
        insert new List<FTE_Data_Record__c> {
                        new FTE_Data_Record__c(Year__c = currentYear, Contract__c = dContract1.Id, Employee__c = empl1.Id)
                    };

        Test.startTest();
        List<Time_Card__c> testTimeCards = new List<Time_Card__c> {
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 3, 1), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 3, 21), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 3, 3), Employee__c = empl1.Id, Client__c = dContract3.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(currentYear, 1, 1), Employee__c = empl1.Id, Client__c = dContract3.Id)
                    };
        insert testTimeCards;
        Test.stopTest();

        List<FTE_Data_Record__c> tamplates = [SELECT Id, Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c,
                                              Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                              FROM FTE_Data_Record__c];
        System.assertEquals(1, tamplates.size());
        assertTemplateUpdated(tamplates.get(0), true, false, true, false, false, false, false, false, false, false, false, false);
    }




    /**
     * FTE Data Manager tests
     */
    @isTest
    public static void testTimeManagerEmpl1() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1];
        Id contract1Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id contract2Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id contract3Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id contract4Id = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;

        Test.startTest();
        FTEDataManager timeManager = new FTEDataManager(Date.today().year(), employee.Id);
        timeManager.loadEmployeeTime();
        Integer month = Date.today().month();

        System.assertEquals(25.6, timeManager.assignedMap.get(contract1Id).hoursArray[month - 1]);
        System.assertEquals(25.6, timeManager.assignedMap.get(contract2Id).hoursArray[month - 1]);
        System.assertEquals(10.3, timeManager.assignedMap.get(contract3Id).hoursArray[month - 1]);
        System.assertEquals(30.6, timeManager.assignedMap.get(contract4Id).hoursArray[month - 1]);
        System.assertEquals(19.3 + 27.6, timeManager.unassigned.hoursArray[month - 1]);

        System.assertEquals(0, [SELECT Id FROM Time_Card__c WHERE Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'No'].size());
        System.assertEquals(0, [SELECT Id FROM Time_Card__c WHERE Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'Yes'].size());

        timeManager.removeTime(contract1Id, 24, Date.today().month());
        System.assertEquals(1, [SELECT Id FROM Time_Card__c WHERE Client__c =: contract1Id AND Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'No'].size());

        timeManager.addTime(contract3Id, 8, Date.today().month());
        System.assertEquals(1, [SELECT Id FROM Time_Card__c WHERE FTE_Contract__c =: contract3Id AND Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'Yes'].size());
        timeManager.addTime(contract3Id, 2, Date.today().month());
        System.assertEquals(1, [SELECT Id FROM Time_Card__c WHERE FTE_Contract__c =: contract3Id AND Employee__c =: employee.Id AND FTE_Contract__r.FTE_Tracker__c = 'Yes'].size());

        timeManager.removeTime(contract3Id, 5, Date.today().month());
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
        FTEDataManager timeManager = new FTEDataManager(Date.today().year(), employee.Id);
        timeManager.loadEmployeeTime();
        Integer month = Date.today().month();

        System.assertEquals(28.6 - 5, timeManager.assignedMap.get(contract1Id).hoursArray[month - 1]);
        System.assertEquals(null, timeManager.assignedMap.get(contract2Id));
        System.assertEquals(null, timeManager.assignedMap.get(contract3Id));
        System.assertEquals(5 - 2, timeManager.assignedMap.get(contract4Id).hoursArray[month - 1]);
        System.assertEquals(19.3 + 5 + 2, timeManager.unassigned.hoursArray[month - 1]);
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
        FTEDataManager timeManager = new FTEDataManager(Date.today().year(), employee.Id);
        timeManager.loadEmployeeTime();
        Integer month = Date.today().month();

        System.assertEquals(19.1 - 8, timeManager.assignedMap.get(contract1Id).hoursArray[month - 1]);
        System.assertEquals(16 - 7 + 5, timeManager.assignedMap.get(contract2Id).hoursArray[month - 1]);
        System.assertEquals(7 - 5 + 3 + 16, timeManager.assignedMap.get(contract3Id).hoursArray[month - 1]);
        System.assertEquals(8 - 3 + 2, timeManager.assignedMap.get(contract4Id).hoursArray[month - 1]);
        System.assertEquals(3 + 22 + 8 + 7 - 16 - 2, timeManager.unassigned.hoursArray[month - 1]);
        Test.stopTest();
    }




    /**
     * Time Allocation tests
     */
    @isTest
    public static void shouldSetDefaultValuesForTemplate() {
        Id employeeId = [SELECT Id FROM SFDC_Employee__c LIMIT 1].Id;
        Id contractId = [SELECT Id FROM DContract__c WHERE FTE_Tracker__c = 'Yes' LIMIT 1].Id;

        FTE_Data_Record__c newRecord = new FTE_Data_Record__c(Employee__c = employeeId, Year__c = Date.today().year(), Contract__c = contractId);
        insert newRecord;

        FTE_Data_Record__c dataFromDB = [SELECT Id, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                         Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                         Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c,
                                         Month_Updated_5__c, Month_Updated_6__c, Month_Updated_7__c, Month_Updated_8__c,
                                         Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                         FROM FTE_Data_Record__c WHERE Id =: newRecord.Id LIMIT 1];
        SObject sObj = (SObject) dataFromDB;
        for (Integer month = 1; month <= 12; month++) {
            System.assertEquals(-1, sObj.get(FTETrackerHelper.getFieldName(month)));
            System.assertEquals(false, sObj.get(FTETrackerHelper.getFieldUpdatedName(month)));
        }
    }

    @isTest
    public static void shouldGenerateCorrectEmployeeMonths() {
        FTETimeAllocator allocator = new FTETimeAllocator(true);
        List<FTEEmployeeMonthWrapper> employeeMonths = allocator.start(null);
        System.assertEquals(0, employeeMonths.size());

        List<SFDC_Employee__c> emplList = [SELECT Id FROM SFDC_Employee__c];
        Id employee1Id = emplList.get(0).Id;
        Id employee2Id = emplList.get(1).Id;
        List<DContract__c> contractList = [SELECT Id FROM DContract__c WHERE FTE_Tracker__c = 'Yes'];
        Id contract1Id = contractList.get(0).Id;
        Id contract2Id = contractList.get(1).Id;

        FTE_Data_Record__c newRecord = new FTE_Data_Record__c(Employee__c = employee1Id, Year__c = Date.today().year(), Contract__c = contract1Id);
        insert newRecord;
        employeeMonths = allocator.start(null);
        System.assertEquals(0, employeeMonths.size());

        update new FTE_Data_Record__c(Id = newRecord.Id, Month_Updated_2__c = true);
        employeeMonths = allocator.start(null);
        System.assertEquals(1, employeeMonths.size());

        update new FTE_Data_Record__c(Id = newRecord.Id, Month_Updated_3__c = true);
        employeeMonths = allocator.start(null);
        System.assertEquals(2, employeeMonths.size());

        update new FTE_Data_Record__c(Id = newRecord.Id, Month_Updated_5__c = true);
        employeeMonths = allocator.start(null);
        System.assertEquals(3, employeeMonths.size());

        insert new FTE_Data_Record__c(Employee__c = employee1Id, Year__c = Date.today().year(), Contract__c = contract2Id, Month_Updated_5__c = true);
        employeeMonths = allocator.start(null);
        System.assertEquals(3, employeeMonths.size());

        insert new FTE_Data_Record__c(Employee__c = employee1Id, Year__c = Date.today().year() - 1, Contract__c = contract2Id, Month_Updated_5__c = true);
        employeeMonths = allocator.start(null);
        System.assertEquals(4, employeeMonths.size());

        insert new FTE_Data_Record__c(Employee__c = employee2Id, Year__c = Date.today().year(), Contract__c = contract2Id, Month_Updated_4__c = true, Month_Updated_5__c = true);
        employeeMonths = allocator.start(null);
        System.assertEquals(6, employeeMonths.size());
    }

    @isTest
    public static void shouldAllocateTimeForEmployees() {
        Id employee1 = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1].Id;
        Id employee2 = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee' LIMIT 1].Id;
        Id employee3 = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee' LIMIT 1].Id;
        Id contract1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id contract2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        Id contract3 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 3' LIMIT 1].Id;
        Id contract4 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Integer month = Date.today().month();
        Integer year = Date.today().year();

        // Templates
        insert new List<FTE_Data_Record__c> {
                                                buildContractTEmplate(employee1, contract1, 3.0),
                                                buildContractTEmplate(employee1, contract2, 3.0),
                                                buildContractTEmplate(employee1, contract3, 1.0),
                                                buildContractTEmplate(employee2, contract1, 4.0),
                                                buildContractTEmplate(employee2, contract2, 3.0),
                                                buildContractTEmplate(employee2, contract3, 0.0),
                                                buildContractTEmplate(employee2, contract4, 0.0),
                                                buildContractTEmplate(employee3, contract1, 2.5),
                                                buildContractTEmplate(employee3, contract2, 1.0),
                                                buildContractTEmplate(employee3, contract4, 1.0)
                                            };

        Test.startTest();
        Database.executeBatch(new FTETimeAllocator(false));
        Test.stopTest();

        // Assert Employee 1 : FTE Employee
        FTEDataManager timeManager = new FTEDataManager(year, month, employee1, true);
        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();

        timeManager.assignedMap.get(contract1).calculateDaysAndTotal();
        System.assertEquals(24, timeManager.assignedMap.get(contract1).hoursArray[month - 1]);
        System.assertEquals(3, timeManager.assignedMap.get(contract1).templateArray[month - 1]);
        System.assertEquals(3, timeManager.assignedMap.get(contract1).daysArray[month - 1]);

        timeManager.assignedMap.get(contract2).calculateDaysAndTotal();
        System.assertEquals(24, timeManager.assignedMap.get(contract2).hoursArray[month - 1]);
        System.assertEquals(3, timeManager.assignedMap.get(contract2).templateArray[month - 1]);
        System.assertEquals(3, timeManager.assignedMap.get(contract2).daysArray[month - 1]);

        timeManager.assignedMap.get(contract3).calculateDaysAndTotal();
        System.assertEquals(8, timeManager.assignedMap.get(contract3).hoursArray[month - 1]);
        System.assertEquals(1, timeManager.assignedMap.get(contract3).templateArray[month - 1]);
        System.assertEquals(1, timeManager.assignedMap.get(contract3).daysArray[month - 1]);

        timeManager.assignedMap.get(contract4).calculateDaysAndTotal();
        System.assertEquals(30.6, timeManager.assignedMap.get(contract4).hoursArray[month - 1]);
        System.assertEquals(-1, timeManager.assignedMap.get(contract4).templateArray[month - 1]);
        System.assertEquals(3.75, timeManager.assignedMap.get(contract4).daysArray[month - 1]);

        timeManager.unassigned.calculateDaysAndTotal();
        System.assertEquals(52.4, timeManager.unassigned.hoursArray[month - 1]);
        System.assertEquals(6.5, timeManager.unassigned.daysArray[month - 1]);

        // Assert Employee 2 : Other Employe
        timeManager = new FTEDataManager(year, month, employee2, true);
        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();

        timeManager.assignedMap.get(contract1).calculateDaysAndTotal();
        System.assertEquals(32, timeManager.assignedMap.get(contract1).hoursArray[month - 1]);
        System.assertEquals(4, timeManager.assignedMap.get(contract1).templateArray[month - 1]);
        System.assertEquals(4, timeManager.assignedMap.get(contract1).daysArray[month - 1]);

        timeManager.assignedMap.get(contract2).calculateDaysAndTotal();
        System.assertEquals(20.9, timeManager.assignedMap.get(contract2).hoursArray[month - 1]);
        System.assertEquals(3, timeManager.assignedMap.get(contract2).templateArray[month - 1]);
        System.assertEquals(3, timeManager.assignedMap.get(contract2).daysArray[month - 1]);

        timeManager.assignedMap.get(contract3).calculateDaysAndTotal();
        System.assertEquals(0, timeManager.assignedMap.get(contract3).hoursArray[month - 1]);
        System.assertEquals(0, timeManager.assignedMap.get(contract3).templateArray[month - 1]);
        System.assertEquals(0, timeManager.assignedMap.get(contract3).daysArray[month - 1]);

        timeManager.assignedMap.get(contract4).calculateDaysAndTotal();
        System.assertEquals(0, timeManager.assignedMap.get(contract4).hoursArray[month - 1]);
        System.assertEquals(0, timeManager.assignedMap.get(contract4).templateArray[month - 1]);
        System.assertEquals(0, timeManager.assignedMap.get(contract4).daysArray[month - 1]);

        timeManager.unassigned.calculateDaysAndTotal();
        System.assertEquals(0, timeManager.unassigned.hoursArray[month - 1]);
        System.assertEquals(0, timeManager.unassigned.daysArray[month - 1]);

        // Assert Employee 3 : Yyy Employe
        timeManager = new FTEDataManager(year, month, employee3, true);
        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();

        timeManager.assignedMap.get(contract1).calculateDaysAndTotal();
        System.assertEquals(20, timeManager.assignedMap.get(contract1).hoursArray[month - 1]);
        System.assertEquals(2.5, timeManager.assignedMap.get(contract1).templateArray[month - 1]);
        System.assertEquals(2.5, timeManager.assignedMap.get(contract1).daysArray[month - 1]);

        timeManager.assignedMap.get(contract2).calculateDaysAndTotal();
        System.assertEquals(8, timeManager.assignedMap.get(contract2).hoursArray[month - 1]);
        System.assertEquals(1, timeManager.assignedMap.get(contract2).templateArray[month - 1]);
        System.assertEquals(1, timeManager.assignedMap.get(contract2).daysArray[month - 1]);

        timeManager.assignedMap.get(contract3).calculateDaysAndTotal();
        System.assertEquals(21, timeManager.assignedMap.get(contract3).hoursArray[month - 1]);
        System.assertEquals(-1, timeManager.assignedMap.get(contract3).templateArray[month - 1]);
        System.assertEquals(2.75, timeManager.assignedMap.get(contract3).daysArray[month - 1]);

        timeManager.assignedMap.get(contract4).calculateDaysAndTotal();
        System.assertEquals(8, timeManager.assignedMap.get(contract4).hoursArray[month - 1]);
        System.assertEquals(1, timeManager.assignedMap.get(contract4).templateArray[month - 1]);
        System.assertEquals(1, timeManager.assignedMap.get(contract4).daysArray[month - 1]);

        timeManager.unassigned.calculateDaysAndTotal();
        System.assertEquals(18.1, timeManager.unassigned.hoursArray[month - 1]);
        System.assertEquals(2.25, timeManager.unassigned.daysArray[month - 1]);
    }




    /**
     * Time Cards generation tests
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
    public static void shouldGenerateTimeCardsForFuture() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1];
        DContract__c dContract1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1];
        DContract__c dContract2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1];

        Integer fteMonth = 4; // we want know when is weekend
        Integer fteYear = 2019;

        insert buildContractTemplate(employee.Id, dContract1.Id, 8, fteYear, fteMonth);
        insert buildContractTemplate(employee.Id, dContract2.Id, 6, fteYear, fteMonth);

        Test.startTest();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(fteYear, fteMonth, employee.Id);
        List<FTEMonthTimeCard> employeeMonthProjects = generator.generateMonthTimeCards();
        Test.stopTest();

        System.assertEquals(3, employeeMonthProjects.size()); // FTE 1, FTE 2, Overhead

        // Overhead
        System.assertEquals(0, employeeMonthProjects.get(2).hours[0]);
        System.assertEquals(0, employeeMonthProjects.get(2).hours[1]);
        System.assertEquals(0, employeeMonthProjects.get(2).totalHours);
        System.assertEquals(-1, employeeMonthProjects.get(2).templateExpectedTime);

        // FTE Contract 1
        System.assertEquals(8, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[3]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[4]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[7]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[8]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[9]);
        System.assertEquals(8 * 8, employeeMonthProjects.get(0).totalHours);
        System.assertEquals(8, employeeMonthProjects.get(0).templateExpectedTime);

        // FTE Contract 2
        System.assertEquals(8, employeeMonthProjects.get(1).hours[10]);
        System.assertEquals(8, employeeMonthProjects.get(1).hours[11]);
        System.assertEquals(8, employeeMonthProjects.get(1).hours[14]);
        System.assertEquals(8, employeeMonthProjects.get(1).hours[15]);
        System.assertEquals(8, employeeMonthProjects.get(1).hours[16]);
        System.assertEquals(8, employeeMonthProjects.get(1).hours[17]);
        System.assertEquals(8 * 6, employeeMonthProjects.get(1).totalHours);
        System.assertEquals(6, employeeMonthProjects.get(1).templateExpectedTime);
    }

    @isTest
    public static void shouldGenerateTimeCardsForFutureOverEigthHours() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1];
        DContract__c dContract1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1];
        DContract__c dContract2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1];

        Integer fteMonth = 4; // we want know when is weekend, 22 possible working days
        Integer fteYear = 2019;

        insert buildContractTemplate(employee.Id, dContract1.Id, 20, fteYear, fteMonth);
        insert buildContractTemplate(employee.Id, dContract2.Id, 2.5, fteYear, fteMonth);

        Test.startTest();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(fteYear, fteMonth, employee.Id);
        List<FTEMonthTimeCard> employeeMonthProjects = generator.generateMonthTimeCards();
        Test.stopTest();

        System.assertEquals(3, employeeMonthProjects.size()); // FTE 1, FTE 2, Overhead

        // FTE Contract 1
        System.assertEquals(8, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[2]);
        System.assertEquals(8, employeeMonthProjects.get(0).hours[3]);

        // FTE Contract 2
        System.assertEquals(8, employeeMonthProjects.get(1).hours[29]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[0]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[1]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[2]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[3]);
        System.assertEquals(0, employeeMonthProjects.get(1).hours[4]);

        System.assertEquals(2.5 * 8, employeeMonthProjects.get(1).totalHours);
        System.assertEquals(2.5, employeeMonthProjects.get(1).templateExpectedTime);
    }

    @isTest
    public static void shouldFillFutureTimeForContractDays() {
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee' LIMIT 1];
        DContract__c dContract1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1];
        DContract__c dContract2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1];
        DContract__c unassigned1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1];

        Integer fteMonth = 4; // we want know when is weekend, 22 possible working days
        Integer fteYear = 2019;

        insert buildContractTemplate(employee.Id, dContract1.Id, 8, fteYear, fteMonth);

        List<Time_Card__c> testTimeCards = new List<Time_Card__c> { // Assigned time by days 1 -> 7, 2 -> 7, 5 -> 7, 9 -> 8, 10 -> 7, 11 -> 8, 22 -> 8, 23 -> 7, 24 -> 7, 25 -> 6, 26 -> 9
                        new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(fteYear, fteMonth, 1), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(fteYear, fteMonth, 2), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(fteYear, fteMonth, 5), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 6, Date__c = Date.newInstance(fteYear, fteMonth, 9), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(fteYear, fteMonth, 10), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(fteYear, fteMonth, 11), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(fteYear, fteMonth, 22), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(fteYear, fteMonth, 23), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(fteYear, fteMonth, 24), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(fteYear, fteMonth, 25), Employee__c = employee.Id, Client__c = dContract1.Id),
                        new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(fteYear, fteMonth, 26), Employee__c = employee.Id, Client__c = dContract1.Id),

                        new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(fteYear, fteMonth, 1), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(fteYear, fteMonth, 2), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(fteYear, fteMonth, 3), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(fteYear, fteMonth, 4), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 3, Date__c = Date.newInstance(fteYear, fteMonth, 5), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(fteYear, fteMonth, 9), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 5, Date__c = Date.newInstance(fteYear, fteMonth, 10), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(fteYear, fteMonth, 11), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 7, Date__c = Date.newInstance(fteYear, fteMonth, 22), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(fteYear, fteMonth, 23), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 2, Date__c = Date.newInstance(fteYear, fteMonth, 24), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 1, Date__c = Date.newInstance(fteYear, fteMonth, 25), Employee__c = employee.Id, Client__c = dContract2.Id),
                        new Time_Card__c(Total__c = 4, Date__c = Date.newInstance(fteYear, fteMonth, 26), Employee__c = employee.Id, Client__c = dContract2.Id)
                    };
        insert testTimeCards;

        Test.startTest();
        FTETimeCardGenerator generator = new FTETimeCardGenerator(fteYear, fteMonth, employee.Id);
        List<FTEMonthTimeCard> employeeMonthProjects = generator.generateMonthTimeCards();
        Test.stopTest();

        System.assertEquals(3, employeeMonthProjects.size()); // FTE 1, FTE 2, Overhead

        // FTE Contract 1
        System.assertEquals(7, employeeMonthProjects.get(0).hours[0]);
        System.assertEquals(5, employeeMonthProjects.get(0).hours[1]);
        System.assertEquals(3, employeeMonthProjects.get(0).hours[2]); // generated
        System.assertEquals(3, employeeMonthProjects.get(0).hours[3]); // generated
        System.assertEquals(5, employeeMonthProjects.get(0).hours[4]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[5]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[6]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[7]); // generated
        System.assertEquals(6, employeeMonthProjects.get(0).hours[8]);
        System.assertEquals(3, employeeMonthProjects.get(0).hours[9]);
        System.assertEquals(1, employeeMonthProjects.get(0).hours[10]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[11]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[12]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[13]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[14]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[15]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[16]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[17]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[18]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[19]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[20]);
        System.assertEquals(1, employeeMonthProjects.get(0).hours[21]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[22]);
        System.assertEquals(6, employeeMonthProjects.get(0).hours[23]);
        System.assertEquals(7, employeeMonthProjects.get(0).hours[24]);
        System.assertEquals(5, employeeMonthProjects.get(0).hours[25]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[26]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[27]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[28]);
        System.assertEquals(0, employeeMonthProjects.get(0).hours[29]);

        System.assertEquals(8 * 8, employeeMonthProjects.get(0).totalHours);
        System.assertEquals(8, employeeMonthProjects.get(0).templateExpectedTime);

        // FTE Contract 2
        System.assertEquals(1, employeeMonthProjects.get(1).hours[0]);
        System.assertEquals(3, employeeMonthProjects.get(1).hours[1]);
        System.assertEquals(5, employeeMonthProjects.get(1).hours[2]); // generated
        System.assertEquals(5, employeeMonthProjects.get(1).hours[3]); // generated
        System.assertEquals(3, employeeMonthProjects.get(1).hours[4]);
        System.assertEquals(2, employeeMonthProjects.get(1).hours[8]);
        System.assertEquals(5, employeeMonthProjects.get(1).hours[9]);
        System.assertEquals(7, employeeMonthProjects.get(1).hours[10]);
        System.assertEquals(7, employeeMonthProjects.get(1).hours[21]);
        System.assertEquals(2, employeeMonthProjects.get(1).hours[22]);
        System.assertEquals(2, employeeMonthProjects.get(1).hours[23]);
        System.assertEquals(1, employeeMonthProjects.get(1).hours[24]);
        System.assertEquals(4, employeeMonthProjects.get(1).hours[25]);
        System.assertEquals(0, employeeMonthProjects.get(1).hours[26]);

        System.assertEquals(47, employeeMonthProjects.get(1).totalHours);
        System.assertEquals(-1, employeeMonthProjects.get(1).templateExpectedTime);
    }




    /**
     * CSV Parser Tests
     */
    @isTest
    public static void csvParseControllerTestFullFile() {
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String correctData = ',,,,,,\n\r '
                           + 'FTE Contract 1 ,01/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + ', 05/' + fteYear + ', 06/' + fteYear + ', 07/' + fteYear
                           + ', 08/' + fteYear + ', 09/' + fteYear + ', 10/' + fteYear + ', 11/' + fteYear + ', 12/' + fteYear + '\n\r'
                           + 'Other Employee,1,2,3,4,5,6,7,8,9,10,11,12\n\r'
                           + 'FTE Employee,3,4,5,6,7,8,9,10,11,12,13,14\n\r'
                           + 'Yyy Employee,12,11,10,9,8,7,6,5,4,3,2,1\n\r';
        FTECsvUploadController csvUpload = new FTECsvUploadController();

        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Test.stopTest();

        System.assertEquals(3, csvUpload.records.size());
        assertFTEDataRecord(csvUpload.records.values(), 'Other Employee', fteYear, 'FTE Contract 1', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
        assertFTEDataRecord(csvUpload.records.values(), 'FTE Employee', fteYear, 'FTE Contract 1', 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
        assertFTEDataRecord(csvUpload.records.values(), 'Yyy Employee', fteYear, 'FTE Contract 1', 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);

        List<FTE_Data_Record__c> dbTemplates = [SELECT Id, Employee__r.Name, Contract__r.Name, Year__c,
                                                Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                                Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                                Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c, Month_Updated_6__c,
                                                Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                                FROM FTE_Data_Record__c
                                                WHERE Year__c =: fteYear ORDER BY Employee__r.Name];
        System.assertEquals(3, dbTemplates.size());

        assertFTEDBDataRecord(dbTemplates.get(0), 'FTE Employee', fteYear, 'FTE Contract 1', 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14);
        assertFTEDBDataRecord(dbTemplates.get(1), 'Other Employee', fteYear, 'FTE Contract 1', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
        assertFTEDBDataRecord(dbTemplates.get(2), 'Yyy Employee', fteYear, 'FTE Contract 1', 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1);
    }

    @isTest
    public static void csvParseControllerTestPartialFile() {
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String correctData = ',,,,,,\n\r '
                           + 'FTE Contract 1 ,01/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + '\n\r'
                           + 'Other Employee,1,,,0\n\r'
                           + 'Other Employee,5,2,,\n\r'
                           + 'Yyy Employee,4,4,4,0\n\r'
                           + 'FTE Employee,3,3,,1\n\r'
                           + 'Yyy Employee,,0,,2\n\r';
        FTECsvUploadController csvUpload = new FTECsvUploadController();

        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Test.stopTest();

        System.assertEquals(3, csvUpload.records.size());
        assertFTEDataRecord(csvUpload.records.values(), 'Other Employee', fteYear, 'FTE Contract 1', 6, 2, -1, 0, -2, -2, -2, -2, -2, -2, -2, -2);
        assertFTEDataRecord(csvUpload.records.values(), 'FTE Employee', fteYear, 'FTE Contract 1', 3, 3, -1, 1, -2, -2, -2, -2, -2, -2, -2, -2);
        assertFTEDataRecord(csvUpload.records.values(), 'Yyy Employee', fteYear, 'FTE Contract 1', 4, 4, 4, 2, -2, -2, -2, -2, -2, -2, -2, -2);

        List<FTE_Data_Record__c> dbTemplates = [SELECT Id, Employee__r.Name, Contract__r.Name, Year__c,
                                                Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                                Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                                Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c, Month_Updated_6__c,
                                                Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                                FROM FTE_Data_Record__c
                                                WHERE Year__c =: fteYear ORDER BY Employee__r.Name];
        System.assertEquals(3, dbTemplates.size());

        assertFTEDBDataRecord(dbTemplates.get(0), 'FTE Employee', fteYear, 'FTE Contract 1', 3, 3, -1, 1, -1, -1, -1, -1, -1, -1, -1, -1);
        assertFTEDBDataRecord(dbTemplates.get(1), 'Other Employee', fteYear, 'FTE Contract 1', 6, 2, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1);
        assertFTEDBDataRecord(dbTemplates.get(2), 'Yyy Employee', fteYear, 'FTE Contract 1', 4,4, 4, 2, -1, -1, -1, -1, -1, -1, -1, -1);
    }

    @isTest
    public static void csvParseControllerTestMergeTemplate() {
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        Id contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id employeeId1 = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'  LIMIT 1].Id;
        Id employeeId2 = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee' LIMIT 1].Id;
        insert new List<FTE_Data_Record__c> {
                            new FTE_Data_Record__c(Year__c = fteYear, Employee__c = employeeId1, Contract__c = contractId, Month_1__c = 3, Month_2__c = -1, Month_3__c = -1, Month_4__c = 0),
                            new FTE_Data_Record__c(Year__c = fteYear, Employee__c = employeeId2, Contract__c = contractId, Month_1__c = 3, Month_2__c = 4, Month_3__c = 0, Month_4__c = 2)
                          };

        String correctData = ',,,,,,\n\r '
                           + 'FTE Contract 1 ,01/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + '\n\r'
                           + 'Other Employee,1,,,0\n\r'
                           + 'Other Employee,5,2,,\n\r'
                           + 'Yyy Employee,4,4,4,0\n\r'
                           + 'FTE Employee,3,3,,1\n\r'
                           + 'Yyy Employee,,0,,2\n\r';
        FTECsvUploadController csvUpload = new FTECsvUploadController();
        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Test.stopTest();

        System.assertEquals(3, csvUpload.records.size());
        assertFTEDataRecord(csvUpload.records.values(), 'Other Employee', fteYear, 'FTE Contract 1', 6, 2, -1, 0, -2, -2, -2, -2, -2, -2, -2, -2);
        assertFTEDataRecord(csvUpload.records.values(), 'FTE Employee', fteYear, 'FTE Contract 1', 3, 3, -1, 1, -2, -2, -2, -2, -2, -2, -2, -2);
        assertFTEDataRecord(csvUpload.records.values(), 'Yyy Employee', fteYear, 'FTE Contract 1', 4, 4, 4, 2, -2, -2, -2, -2, -2, -2, -2, -2);

        List<FTE_Data_Record__c> dbTemplates = [SELECT Id, Employee__r.Name, Contract__r.Name, Year__c,
                                                Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                                Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                                Month_Updated_1__c, Month_Updated_2__c, Month_Updated_3__c, Month_Updated_4__c, Month_Updated_5__c, Month_Updated_6__c,
                                                Month_Updated_7__c, Month_Updated_8__c, Month_Updated_9__c, Month_Updated_10__c, Month_Updated_11__c, Month_Updated_12__c
                                                FROM FTE_Data_Record__c
                                                WHERE Year__c =: fteYear ORDER BY Employee__r.Name];
        for (FTE_Data_Record__c templ : dbTemplates) {
            System.debug('Template data : ' + templ.Employee__r.Name + ' ' + templ.Year__c + ' ' + templ.Contract__r.Name);
        }
        System.assertEquals(3, dbTemplates.size());

        assertFTEDBDataRecord(dbTemplates.get(0), 'FTE Employee', fteYear, 'FTE Contract 1', 3, 3, -1, 1, -1, -1, -1, -1, -1, -1, -1, -1);
        assertFTEDBDataRecord(dbTemplates.get(1), 'Other Employee', fteYear, 'FTE Contract 1', 6, 2, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1);
        assertFTEDBDataRecord(dbTemplates.get(2), 'Yyy Employee', fteYear, 'FTE Contract 1', 4, 4, 4, 2, -1, -1, -1, -1, -1, -1, -1, -1);
        assertTemplateUpdated(dbTemplates.get(0), false, true, false, true, false, false, false, false, false, false, false, false);
        assertTemplateUpdated(dbTemplates.get(1), true, true, false, true, false, false, false, false, false, false, false, false);
        assertTemplateUpdated(dbTemplates.get(2), true, false, true, false, false, false, false, false, false, false, false, false);
    }

    @isTest
    public static void shouldUploadAndMoveCSVDataSample1() {
        Integer fteYear = Date.today().year();
        integer fteMonth = Date.today().month();
        String correctData = ',,,,,,\n\r '
                           + 'FTE Contract 1 ,01/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + ', 05/' + fteYear + ', 06/' + fteYear + ', 07/' + fteYear
                           + ', 08/' + fteYear + ', 09/' + fteYear + ', 10/' + fteYear + ', 11/' + fteYear + ', 12/' + fteYear + '\n\r'
                           + buildDataRow('Other Employee', fteMonth, 5.0)
                           + buildDataRow('FTE Employee', fteMonth, 7.0)
                           + buildDataRow('Yyy Employee', fteMonth, 4.0);

        FTECsvUploadController csvUpload = new FTECsvUploadController();

        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Database.executeBatch(new FTETimeAllocator(true));
        Test.stopTest();

        // FTE Employee
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Id contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1'].Id;
        FTEDataManager timeManager = new FTEDataManager(fteYear, employee.Id);

        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();
        System.assertEquals(56, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDaysAndTotal();
        System.assertEquals(7, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(7, timeManager.assignedMap.get(contractId).templateArray[fteMonth - 1]);
        assertTemplatesValue(-1, new Set<Integer> { fteMonth }, timeManager.assignedMap.get(contractId));

        // FTE Employee
        employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        timeManager = new FTEDataManager(fteYear, employee.Id);
        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();

        System.assertEquals(40, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDaysAndTotal();
        System.assertEquals(5, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(5, timeManager.assignedMap.get(contractId).templateArray[fteMonth - 1]);
        assertTemplatesValue(-1, new Set<Integer> { fteMonth }, timeManager.assignedMap.get(contractId));

        // FTE Employee
        employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee'];
        timeManager = new FTEDataManager(fteYear, employee.Id);
        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();

        System.assertEquals(32, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDaysAndTotal();
        System.assertEquals(4, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(4, timeManager.assignedMap.get(contractId).templateArray[fteMonth - 1]);
        assertTemplatesValue(-1, new Set<Integer> { fteMonth }, timeManager.assignedMap.get(contractId));
    }

    @isTest
    public static void shouldUploadAndMoveCSVDataSample2() {
        Integer fteYear = Date.today().year();
        Integer fteMonth = Date.today().month();
        String correctData = ',,,,,,\n\r '
                           + 'FTE Contract 1 ,01/' + fteYear + ', 02/' + fteYear + ', 03/' + fteYear + ', 04/' + fteYear + ', 05/' + fteYear + ', 06/' + fteYear + ', 07/' + fteYear
                           + ', 08/' + fteYear + ', 09/' + fteYear + ', 10/' + fteYear + ', 11/' + fteYear + ', 12/' + fteYear + '\n\r'
                           + buildDataRow('Other Employee', fteMonth, 1.0)
                           + buildDataRow('FTE Employee', fteMonth, 1.0)
                           + buildDataRow('Yyy Employee', fteMonth, 1.0);

        FTECsvUploadController csvUpload = new FTECsvUploadController();

        Test.startTest();
        csvUpload.fileContent = Blob.valueOf(correctData);
        csvUpload.fileName = 'Test file name';

        csvUpload.parseCsvFile();
        Database.executeBatch(new FTETimeAllocator(true));
        Test.stopTest();

        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];
        Id contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1'].Id;
        FTEDataManager timeManager = new FTEDataManager(fteYear, employee.Id);
        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();

        System.assertEquals(8, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDaysAndTotal();
        System.assertEquals(1, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(64.5, timeManager.unassigned.hoursArray[fteMonth - 1]);
        timeManager.unassigned.calculateDaysAndTotal();
        System.assertEquals(8, timeManager.unassigned.daysArray[fteMonth - 1]);
        assertTemplatesValue(-1, new Set<Integer> { fteMonth }, timeManager.assignedMap.get(contractId));

        employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'];
        timeManager = new FTEDataManager(fteYear, employee.Id);
        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();

        System.assertEquals(8, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDaysAndTotal();
        System.assertEquals(1, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(41.9, timeManager.unassigned.hoursArray[fteMonth - 1]);
        timeManager.unassigned.calculateDaysAndTotal();
        System.assertEquals(5.25, timeManager.unassigned.daysArray[fteMonth - 1]);
        assertTemplatesValue(-1, new Set<Integer> { fteMonth }, timeManager.assignedMap.get(contractId));

        employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Yyy Employee'];
        timeManager = new FTEDataManager(fteYear, employee.Id);
        timeManager.loadEmployeeTime();
        timeManager.loadTemplateTime();

        System.assertEquals(8, timeManager.assignedMap.get(contractId).hoursArray[fteMonth - 1]);
        timeManager.assignedMap.get(contractId).calculateDaysAndTotal();
        System.assertEquals(1, timeManager.assignedMap.get(contractId).daysArray[fteMonth - 1]);
        System.assertEquals(25.1, timeManager.unassigned.hoursArray[fteMonth - 1]);
        timeManager.unassigned.calculateDaysAndTotal();
        System.assertEquals(3.25, timeManager.unassigned.daysArray[fteMonth - 1]);
        assertTemplatesValue(-1, new Set<Integer> { fteMonth }, timeManager.assignedMap.get(contractId));
    }




    /**
     * Controller tests
     */
    @isTest
    public static void testEmployeeListController() {
        Integer currYear = Date.today().year();
        List<FTE_Work_Card__c> workCards = new List<FTE_Work_Card__c>();
        for (SFDC_Employee__c empl : [SELECT Id FROM SFDC_Employee__c]) {
            workCards.add(new FTE_Work_Card__c(Employee__c = empl.Id, Month_1__c = 1, Month_2__c = 2, Month_3__c = 3, Month_4__c = 22, Month_5__c = 5, Month_6__c = 6, Month_7__c = 7, Month_8__c = 8,
                                               Month_9__c = 9, Month_10__c = 10, Month_11__c = 11, Month_12__c = 12, Total__c = 78, Total_Hours__c = 78 * 8, Year__c = currYear,
                                               Month_Future_9__c = true, Month_Blocked_4__c = true, Month_Future_5__c = true,  Month_Blocked_5__c = true));
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
        System.assertEquals(4, projCtrl.individualContractDataList.size()); // 3 employees and 1 total row
        System.assertEquals('Total', projCtrl.individualContractDataList.get(3).name);

        System.assertNotEquals(null, projCtrl.goToEmployeeView());
        System.assertNotEquals(null, projCtrl.goToProjectListView());
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

    @isTest
    public static void shouldGenerateEmployeeHoursEmplCtrl() {
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
    public static void shouldMoveHoursToUnassignedEmplCtrl() {
        Date currentDate = Date.today();
        addTimeCard([SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id,
                    [SELECT Id FROM SFDC_Employee__c WHERE Name = 'Other Employee'].Id,
                    Date.newInstance(currentDate.year(), currentDate.month(), 5), 3.3);
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];

        insert new FTE_Work_Card__c(Employee__c = employee.Id, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be updated

        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month();
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 2' LIMIT 1].Id;
        controller.fteDays = '3';

        controller.unassignTime();
        controller.initFteEmployeeView();
        Test.stopTest();

        System.assertEquals(70.9, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(8.75, controller.fteTimeManager.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(68.1, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(8.5, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
        assertWorkCardMonthAndTotal(currentDate.month(), employee.Id, 8.5, 8.5, false, false);
    }

    @isTest
    public static void shouldMoveHoursFromUnassignedEmplCtrl() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];

        insert new FTE_Work_Card__c(Employee__c = employee.Id, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be updated

        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month();
        controller.fteDays = '2.5';
        controller.selectedFteContract = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;

        controller.assignTime();
        controller.initFteEmployeeView();
        Test.stopTest();

        System.assertEquals(26.9, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(3.25, controller.fteTimeManager.unassigned.daysArray[currentDate.month() - 1]);
        System.assertEquals(112.1, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(14, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
        assertWorkCardMonthAndTotal(currentDate.month(), employee.Id, 14, 14, false, false);
    }

    @isTest
    public static void shouldSetBlockedTemplateEmplCtrl() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];

        insert new FTE_Work_Card__c(Employee__c = employee.Id, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be updated

        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month();
        controller.fteDays = '6.00';
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;

        controller.setThreshold();
        controller.initFteEmployeeView();
        Test.stopTest();

        System.assertEquals(48, controller.fteTimeManager.assignedMap.get(controller.contractId).hoursArray[currentDate.month() - 1]);
        System.assertEquals(24.5, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(114.5, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(14.25, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
        System.assertEquals(6, controller.fteTimeManager.assignedMap.get(controller.contractId).templateArray[currentDate.month() - 1]);
        System.assertEquals('fteCell blocked', controller.fteTimeManager.assignedMap.get(controller.contractId).cssStyle[currentDate.month() - 1]);
        assertTemplatesValue(-1, new Set<Integer> { currentDate.month() }, controller.fteTimeManager.assignedMap.get(controller.contractId));

        List<FTE_Data_Record__c> futureTemplates = [SELECT Contract__c, Contract__r.Name, Employee__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c,
                                                  Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                                  FROM FTE_Data_Record__c];
        System.assertEquals(1, futureTemplates.size());
        assertWorkCardMonthAndTotal(currentDate.month(), employee.Id, 14.25, 14.25, false, true);
    }

    @isTest
    public static void shouldSetFutureTemplateEmplCtrl() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];

        insert new FTE_Work_Card__c(Employee__c = employee.Id, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be updated

        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month();
        controller.fteDays = '12.00';
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;

        controller.setThreshold();
        controller.initFteEmployeeView();
        Test.stopTest();

        System.assertEquals(72.5, controller.fteTimeManager.assignedMap.get(controller.contractId).hoursArray[currentDate.month() - 1]); // no 96 hours contains orginal time for contracts
        System.assertEquals(12, controller.fteTimeManager.assignedMap.get(controller.contractId).daysArray[currentDate.month() - 1]); // no 96 hours contains orginal time for contracts
        System.assertEquals(0, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        // in merged records like totals and in hours we have merged data with templates,
        // we don't do this in other hours array like unassigned assignedMap and unassignedMap because we are using them for calculations when moving time
        System.assertEquals(162.5, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(20.25, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
        System.assertEquals(12, controller.fteTimeManager.assignedMap.get(controller.contractId).templateArray[currentDate.month() - 1]);
        System.assertEquals('fteCell future', controller.fteTimeManager.assignedMap.get(controller.contractId).cssStyle[currentDate.month() - 1]);
        assertTemplatesValue(-1, new Set<Integer> { currentDate.month() }, controller.fteTimeManager.assignedMap.get(controller.contractId));

        List<FTE_Data_Record__c> futureTemplates = [SELECT Contract__c, Contract__r.Name, Employee__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c,
                                                  Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                                  FROM FTE_Data_Record__c];
        System.assertEquals(1, futureTemplates.size());
        assertWorkCardMonthAndTotal(currentDate.month(), employee.Id, 20.25, 20.25, true, false);
    }

    @isTest
    public static void shouldUpdateTemplateEmplCtrl() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];

        insert new FTE_Work_Card__c(Employee__c = employee.Id, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be updated

        Id testContract = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        FTE_Data_Record__c newRecord = new FTE_Data_Record__c(Employee__c = employee.Id, Year__c = currentDate.year(), Contract__c = testContract);
        SObject sObjRec = (SObject) newRecord;
        sObjRec.put(FTETrackerHelper.getFieldName(currentDate.month()), 6);
        insert newRecord;

        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month();
        controller.fteDays = '12.00';
        controller.contractId = testContract;

        controller.setThreshold();
        controller.initFteEmployeeView();
        Test.stopTest();

        System.assertEquals(72.5, controller.fteTimeManager.assignedMap.get(controller.contractId).hoursArray[currentDate.month() - 1]); // no 96 hours contains orginal time for contracts
        System.assertEquals(12, controller.fteTimeManager.assignedMap.get(controller.contractId).daysArray[currentDate.month() - 1]); // no 96 hours contains orginal time for contracts
        System.assertEquals(0, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        // in merged records like totals and in hours we have merged data with templates,
        // we don't do this in other hours array like unassigned assignedMap and unassignedMap because we are using them for calculations when moving time
        System.assertEquals(162.5, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(20.25, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
        System.assertEquals(12, controller.fteTimeManager.assignedMap.get(controller.contractId).templateArray[currentDate.month() - 1]);
        System.assertEquals('fteCell future', controller.fteTimeManager.assignedMap.get(controller.contractId).cssStyle[currentDate.month() - 1]);
        assertTemplatesValue(-1, new Set<Integer> { currentDate.month() }, controller.fteTimeManager.assignedMap.get(controller.contractId));

        List<FTE_Data_Record__c> futureTemplates = [SELECT Id, Contract__c, Contract__r.Name, Employee__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c,
                                                  Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                                  FROM FTE_Data_Record__c];
        System.assertEquals(1, futureTemplates.size());
        System.assertEquals(newRecord.Id, futureTemplates.get(0).Id);
        assertWorkCardMonthAndTotal(currentDate.month(), employee.Id, 20.25, 20.25, true, false);
    }

    @isTest
    public static void shouldSetZeroInTemplateEmplCtrl() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];

        insert new FTE_Work_Card__c(Employee__c = employee.Id, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be updated

        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month();
        controller.fteDays = '0.00';
        controller.contractId = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;

        controller.setThreshold();
        controller.initFteEmployeeView();
        Test.stopTest();

        System.assertEquals(0, controller.fteTimeManager.assignedMap.get(controller.contractId).hoursArray[currentDate.month() - 1]);
        System.assertEquals(72.5, controller.fteTimeManager.unassigned.hoursArray[currentDate.month() - 1]);
        System.assertEquals(66.5, controller.totalAssignedDays.hoursArray[currentDate.month() - 1]);
        System.assertEquals(8.25, controller.totalAssignedDays.daysArray[currentDate.month() - 1]);
        System.assertEquals(0, controller.fteTimeManager.assignedMap.get(controller.contractId).templateArray[currentDate.month() - 1]);
        System.assertEquals('fteCell blocked', controller.fteTimeManager.assignedMap.get(controller.contractId).cssStyle[currentDate.month() - 1]);
        assertTemplatesValue(-1, new Set<Integer> { currentDate.month() }, controller.fteTimeManager.assignedMap.get(controller.contractId));

        List<FTE_Data_Record__c> futureTemplates = [SELECT Contract__c, Contract__r.Name, Employee__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c,
                                                  Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                                  FROM FTE_Data_Record__c];
        System.assertEquals(1, futureTemplates.size());
        assertWorkCardMonthAndTotal(currentDate.month(), employee.Id, 8.25, 8.25, false, true);
    }

    @isTest
    public static void shouldResetTemplateEmplCtrl() {
        Date currentDate = Date.today();
        SFDC_Employee__c employee = [SELECT Id FROM SFDC_Employee__c WHERE Name = 'FTE Employee'];

        insert new FTE_Work_Card__c(Employee__c = employee.Id, Year__c = Date.today().year(), Month_1__c = 0,
                                    Month_2__c = 0, Month_3__c = 0, Month_4__c = 0, Month_5__c = 0, Month_6__c = 0,
                                    Month_7__c = 0, Month_8__c = 0, Month_9__c = 0, Month_10__c = 0, Month_11__c = 0,
                                    Month_12__c = 0, Total__c = 0, Total_Hours__c = 0); // should be updated

        Id testContract = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        FTE_Data_Record__c newRecord = new FTE_Data_Record__c(Employee__c = employee.Id, Year__c = currentDate.year(), Contract__c = testContract);
        SObject sObjRec = (SObject) newRecord;
        sObjRec.put(FTETrackerHelper.getFieldName(currentDate.month()), 6);
        insert newRecord;

        PageReference pageRef = Page.FTE_Employee_View;
        pageRef.getParameters().put('employeeId', String.valueOf(employee.Id));
        Test.setCurrentPage(pageRef);

        Test.startTest();
        FTEEmployeeController controller = new FTEEmployeeController();
        controller.initFteEmployeeView();
        controller.employeeMonth = currentDate.month();
        controller.fteDays = '';
        controller.contractId = testContract;

        controller.setThreshold();
        controller.initFteEmployeeView();
        Test.stopTest();

        List<FTE_Data_Record__c> futureTemplates = [SELECT Id, Contract__c, Contract__r.Name, Employee__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c,
                                                  Month_5__c, Month_6__c, Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c
                                                  FROM FTE_Data_Record__c];
        System.assertEquals(1, futureTemplates.size());
        System.assertEquals(newRecord.Id, futureTemplates.get(0).Id);
        System.assertEquals(-1, (Decimal) ((SObject) futureTemplates.get(0)).get(FTETrackerHelper.getFieldName(currentDate.month())));
        assertWorkCardMonthAndTotal(currentDate.month(), employee.Id, 11.5, 11.5, false, false);
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




    /**
     * Utils tests
     */
    @isTest
    public static void testIsContractFTE() {
        Id fte1 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 1' LIMIT 1].Id;
        Id fte2 = [SELECT Id FROM DContract__c WHERE Name = 'FTE Contract 4' LIMIT 1].Id;
        Id noFte1 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 1' LIMIT 1].Id;
        Id noFte2 = [SELECT Id FROM DContract__c WHERE Name = 'Unassigned Contract 2' LIMIT 1].Id;
        System.assertEquals(true, FTETrackerHelper.isContractFTE(fte1));
        System.assertEquals(true, FTETrackerHelper.isContractFTE(fte2));
        System.assertEquals(false, FTETrackerHelper.isContractFTE(noFte1));
        System.assertEquals(false, FTETrackerHelper.isContractFTE(noFte2));
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
    public static void shouldBuildCorrectFieldNames() {
        System.assertEquals('Month_Updated_4__c', FTETrackerHelper.getFieldUpdatedName(4));
        System.assertEquals('Month_Updated_11__c', FTETrackerHelper.getFieldUpdatedName(11));
        System.assertEquals('Month_Blocked_4__c', FTETrackerHelper.getFieldTemplateBlockedName(4));
        System.assertEquals('Month_Blocked_7__c', FTETrackerHelper.getFieldTemplateBlockedName(7));
        System.assertEquals('Month_Future_9__c', FTETrackerHelper.getFieldTemplateFutureName(9));
        System.assertEquals('Month_Future_7__c', FTETrackerHelper.getFieldTemplateFutureName(7));
        System.assertEquals('Month_6__c', FTETrackerHelper.getFieldName(6));
        System.assertEquals('Month_10__c', FTETrackerHelper.getFieldName(10));
    }

    @isTest
    public static void shouldRoundHoursToDays() {
        System.assertEquals(0.25, FTETrackerHelper.roundtoDays(1));
        System.assertEquals(0.25, FTETrackerHelper.roundtoDays(2));
        System.assertEquals(0.5, FTETrackerHelper.roundtoDays(3));
        System.assertEquals(0.5, FTETrackerHelper.roundtoDays(4));
        System.assertEquals(0.75, FTETrackerHelper.roundtoDays(5));
        System.assertEquals(0.75, FTETrackerHelper.roundtoDays(6));
        System.assertEquals(1, FTETrackerHelper.roundtoDays(7));
        System.assertEquals(1, FTETrackerHelper.roundtoDays(8));
        System.assertEquals(1.25, FTETrackerHelper.roundtoDays(9));
        System.assertEquals(1.25, FTETrackerHelper.roundtoDays(10));
        System.assertEquals(1.5, FTETrackerHelper.roundtoDays(11));
        System.assertEquals(1.5, FTETrackerHelper.roundtoDays(12));
        System.assertEquals(1.75, FTETrackerHelper.roundtoDays(13));
        System.assertEquals(1.75, FTETrackerHelper.roundtoDays(14));
        System.assertEquals(0.25, FTETrackerHelper.roundtoDays(1.5));
        System.assertEquals(0.25, FTETrackerHelper.roundtoDays(2.5));
        System.assertEquals(0.5, FTETrackerHelper.roundtoDays(3.5));
        System.assertEquals(0.5, FTETrackerHelper.roundtoDays(4.5));
        System.assertEquals(0.75, FTETrackerHelper.roundtoDays(5.5));
        System.assertEquals(0.75, FTETrackerHelper.roundtoDays(6.5));
    }

    @isTest
    public static void testEmployeeDataWrappers() {
        List<SFDC_Employee__c> employees = [SELECT Id, Name FROM SFDC_Employee__c WHERE Employee_Status__c = 'Active' ORDER BY Name];
        Id fteEmployee = employees.get(0).Id;
        Id otherEmployee = employees.get(1).Id;
        Id yyyEmployee = employees.get(2).Id;

        Integer currentYear = Date.today().year();
        Integer pYear = currentYear - 1;
        Integer nYear = currentYear + 1;

        Set<FTEEmployeeWrapper> emplWrappers = new Set<FTEEmployeeWrapper>();
        emplWrappers.add(new FTEEmployeeWrapper(fteEmployee, currentYear));
        emplWrappers.add(new FTEEmployeeWrapper(otherEmployee, currentYear));
        emplWrappers.add(new FTEEmployeeWrapper(fteEmployee, pYear));
        emplWrappers.add(new FTEEmployeeWrapper(fteEmployee, pYear));
        emplWrappers.add(new FTEEmployeeWrapper(otherEmployee, currentYear));
        emplWrappers.add(new FTEEmployeeWrapper(fteEmployee, nYear));
        emplWrappers.add(new FTEEmployeeWrapper(fteEmployee, currentYear));
        emplWrappers.add(new FTEEmployeeWrapper(fteEmployee, nYear));

        System.assertEquals(4, emplWrappers.size());

        Set<FTEEmployeeMonthWrapper> emplMonthWrappers = new Set<FTEEmployeeMonthWrapper>();
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(fteEmployee, 1, currentYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(otherEmployee, 1, currentYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(fteEmployee, 1, pYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(fteEmployee, 1, pYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(otherEmployee, 1, currentYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(fteEmployee, 1, nYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(fteEmployee, 1, currentYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(fteEmployee, 1, nYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(fteEmployee, 7, nYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(otherEmployee, 2, nYear));
        emplMonthWrappers.add(new FTEEmployeeMonthWrapper(fteEmployee, 3, nYear));

        System.assertEquals(7, emplMonthWrappers.size());
        List<FTEEmployeeMonthWrapper> sortedList = new List<FTEEmployeeMonthWrapper>();
        sortedList.addAll(emplMonthWrappers);
        sortedList.sort();

        System.assertEquals(7, sortedList.size());
        System.assertEquals(sortedList.get(0).getEmployeeId(), sortedList.get(1).getEmployeeId());
        System.assertEquals(sortedList.get(5).getEmployeeId(), sortedList.get(6).getEmployeeId());
    }

    @isTest
    public static void testEmployeeTimeDays() {
        FTEEmployeeTime emplTime = new FTEEmployeeTime(null, null);
        for (Integer i = 0; i < 12; i++) {
            emplTime.hoursArray[i] = (i + 1) * 2;
        }
        emplTime.templateArray[4] = 2;
        emplTime.templateArray[5] = 3;
        emplTime.calculateDaysAndTotal();

        System.assert(!emplTime.merged);
        System.assertEquals(0.25, emplTime.daysArray[0]);
        System.assertEquals(0.5, emplTime.daysArray[1]);
        System.assertEquals(0.75, emplTime.daysArray[2]);
        System.assertEquals(1, emplTime.daysArray[3]);
        System.assertEquals(2, emplTime.daysArray[4]);
        System.assertEquals(3, emplTime.daysArray[5]);
    }

    @isTest
    public static void testEmployeeTimeMerge() {
        FTEEmployeeTime emplTime1 = new FTEEmployeeTime(null, null);
        FTEEmployeeTime emplTime2 = new FTEEmployeeTime(null, null);
        FTEEmployeeTime emplTime3 = new FTEEmployeeTime(null, null);
        for (Integer i = 0; i < 12; i++) {
            emplTime1.hoursArray[i] = i + 1;
            emplTime2.hoursArray[i] = i + 3;
            emplTime3.hoursArray[i] = i + 2;
        }

        emplTime1.templateArray[4] = 2;
        emplTime3.templateArray[4] = 3;
        emplTime3.templateArray[1] = 4;

        FTEEmployeeTime mergedData = new FTEEmployeeTime(null, null);
        mergedData.mergeEmployeeTime(emplTime1);
        System.assert(mergedData.merged);
        System.assertEquals(1, mergedData.hoursArray[0]);
        System.assertEquals(2, mergedData.hoursArray[1]);
        System.assertEquals(3, mergedData.hoursArray[2]);
        System.assertEquals(4, mergedData.hoursArray[3]);
        System.assertEquals(16, mergedData.hoursArray[4]);
        System.assertEquals(-1, mergedData.templateArray[0]);
        System.assertEquals(-1, mergedData.templateArray[1]);
        System.assertEquals(-1, mergedData.templateArray[2]);
        System.assertEquals(-1, mergedData.templateArray[3]);
        System.assertEquals(16, mergedData.templateArray[4]);

        mergedData.mergeEmployeeTime(emplTime2);
        System.assertEquals(1 + 3, mergedData.hoursArray[0]);
        System.assertEquals(2 + 4, mergedData.hoursArray[1]);
        System.assertEquals(3 + 5, mergedData.hoursArray[2]);
        System.assertEquals(4 + 6, mergedData.hoursArray[3]);
        System.assertEquals(16 + 7, mergedData.hoursArray[4]);
        System.assertEquals(-1, mergedData.templateArray[0]);
        System.assertEquals(-1, mergedData.templateArray[1]);
        System.assertEquals(-1, mergedData.templateArray[2]);
        System.assertEquals(-1, mergedData.templateArray[3]);
        System.assertEquals(16 + 7, mergedData.templateArray[4]);

        mergedData.mergeEmployeeTime(emplTime3);
        System.assertEquals(1 + 3 + 2, mergedData.hoursArray[0]);
        System.assertEquals(2 + 4 + 32, mergedData.hoursArray[1]);
        System.assertEquals(3 + 5 + 4, mergedData.hoursArray[2]);
        System.assertEquals(4 + 6 + 5, mergedData.hoursArray[3]);
        System.assertEquals(16 + 7 + 24, mergedData.hoursArray[4]);
        System.assertEquals(-1, mergedData.templateArray[0]);
        System.assertEquals(2 + 4 + 32, mergedData.templateArray[1]);
        System.assertEquals(-1, mergedData.templateArray[2]);
        System.assertEquals(-1, mergedData.templateArray[3]);
        System.assertEquals(16 + 7 + 24, mergedData.templateArray[4]);

        mergedData.calculateDaysAndTotal();
        System.assertEquals(0.75, mergedData.daysArray[0]);
        System.assertEquals(4.75, mergedData.daysArray[1]);
        System.assertEquals(1.5, mergedData.daysArray[2]);
        System.assertEquals(2, mergedData.daysArray[3]);
        System.assertEquals(6, mergedData.daysArray[4]);
    }

    @isTest
    public static void testIsWorkingDay() {
        System.assertEquals(false, FTETrackerHelper.isWorkingDay(2019, 5, 26));
        System.assertEquals(true, FTETrackerHelper.isWorkingDay(2019, 5, 27));
        System.assertEquals(true, FTETrackerHelper.isWorkingDay(2019, 5, 28));
        System.assertEquals(true, FTETrackerHelper.isWorkingDay(2019, 5, 29));
        System.assertEquals(true, FTETrackerHelper.isWorkingDay(2019, 5, 30));
        System.assertEquals(true, FTETrackerHelper.isWorkingDay(2019, 5, 31));
        System.assertEquals(false, FTETrackerHelper.isWorkingDay(2019, 6, 1));
        System.assertEquals(false, FTETrackerHelper.isWorkingDay(2019, 6, 2));
        System.assertEquals(true, FTETrackerHelper.isWorkingDay(2019, 6, 3));
    }




    /**
     * Tests helper methods
     */
    private static void assertWorkCardMonthAndTotal(Integer month, Id employeeId, Decimal value, Decimal totalValue, Boolean futureFlag, Boolean blockedFlag) {
        List<FTE_Work_Card__c> employeeWorkCards = [SELECT Id, Total__c, Month_1__c, Month_2__c, Month_3__c, Month_4__c, Month_5__c, Month_6__c,
                                                    Month_7__c, Month_8__c, Month_9__c, Month_10__c, Month_11__c, Month_12__c,
                                                    Month_Future_1__c, Month_Future_2__c, Month_Future_3__c, Month_Future_4__c, Month_Future_5__c, Month_Future_6__c,
                                                    Month_Future_7__c, Month_Future_8__c, Month_Future_9__c, Month_Future_10__c, Month_Future_11__c, Month_Future_12__c,
                                                    Month_Blocked_1__c, Month_Blocked_2__c, Month_Blocked_3__c, Month_Blocked_4__c, Month_Blocked_5__c, Month_Blocked_6__c,
                                                    Month_Blocked_7__c, Month_Blocked_8__c, Month_Blocked_9__c, Month_Blocked_10__c, Month_Blocked_11__c, Month_Blocked_12__c
                                                    FROM FTE_Work_Card__c WHERE Employee__c =: employeeId AND Year__c =: Date.today().year()];
        System.assertEquals(1, employeeWorkCards.size());
        FTE_Work_Card__c worcCard = employeeWorkCards.get(0);
        SObject workCardSObj = (SObject) worcCard;
        Decimal cardValue = (Decimal) workCardSObj.get(FTETrackerHelper.getFieldName(month));
        Decimal totalCardValue = (Decimal) workCardSObj.get('Total__c');
        Boolean futureFlagCard = (Boolean) workCardSObj.get(FTETrackerHelper.getFieldTemplateFutureName(month));
        Boolean blockedFlagCard = (Boolean)workCardSObj.get(FTETrackerHelper.getFieldTemplateBlockedName(month));

        System.assertEquals(value, cardValue);
        System.assertEquals(totalValue, totalCardValue);
        System.assertEquals(futureFlag, futureFlagCard);
        System.assertEquals(blockedFlag, blockedFlagCard);
    }

    private static void assertTemplateUpdated(FTE_Data_Record__c template) {
        assertTemplateUpdated(template, true, true, true, true, true, true, true, true, true, true, true, true);
    }

    private static void assertTemplateUpdated(FTE_Data_Record__c template, Boolean m1, Boolean m2, Boolean m3, Boolean m4, Boolean m5,
                                              Boolean m6, Boolean m7, Boolean m8, Boolean m9, Boolean m10, Boolean m11, Boolean m12) {
        System.assertEquals(m1, template.Month_Updated_1__c);
        System.assertEquals(m2, template.Month_Updated_2__c);
        System.assertEquals(m3, template.Month_Updated_3__c);
        System.assertEquals(m4, template.Month_Updated_4__c);
        System.assertEquals(m5, template.Month_Updated_5__c);
        System.assertEquals(m6, template.Month_Updated_6__c);
        System.assertEquals(m7, template.Month_Updated_7__c);
        System.assertEquals(m8, template.Month_Updated_8__c);
        System.assertEquals(m9, template.Month_Updated_9__c);
        System.assertEquals(m10, template.Month_Updated_10__c);
        System.assertEquals(m11, template.Month_Updated_11__c);
        System.assertEquals(m12, template.Month_Updated_12__c);
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

    private static void assertFTEDBDataRecord(FTE_Data_Record__c rec, String emplName, Integer fteYear, String contractName,
                                                Decimal m1, Decimal m2, Decimal m3, Decimal m4, Decimal m5, Decimal m6,
                                                Decimal m7, Decimal m8, Decimal m9, Decimal m10, Decimal m11, Decimal m12) {
        System.assertEquals(fteYear, rec.Year__c);
        System.assertEquals(emplName, rec.Employee__r.Name);
        System.assertEquals(contractName,  rec.Contract__r.Name);
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

    private static void assertTemplatesValue(Decimal expectedValue, Set<Integer> monthsToSkip, FTEEmployeeTime emplTime) {
        for (Integer month = 1; month <= 12; month++) {
            if (!monthsToSkip.contains(month)) {
                System.assertEquals(expectedValue, emplTime.templateArray[month -1]);
            }
        }
    }

    private static String buildDataRow(String employeeName, Integer month, Decimal value) {
        String hoursRow = '';
        for (Integer i = 1; i <= 12; i++) {
            if (i != month) {
                hoursRow += ',' + ' ';
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

    private static FTE_Data_Record__c buildContractTemplate(Id emplId, Id contractId, Decimal value) {
        return buildContractTemplate(emplId, contractId, value, Date.today().year(), Date.today().month());
    }

    private static FTE_Data_Record__c buildContractTemplate(Id emplId, Id contractId, Decimal value, Integer year, Integer month) {
        FTE_Data_Record__c template = new FTE_Data_Record__c(Year__c = year, Contract__c = contractId, Employee__c = emplId);
        SObject sObj = (SObject) template;
        sObj.put(FTETrackerHelper.getFieldName(month), value);
        sObj.put(FTETrackerHelper.getFieldUpdatedName(month), true);
        return template;
    }
}