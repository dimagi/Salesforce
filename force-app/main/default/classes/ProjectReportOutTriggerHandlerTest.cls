@isTest
public class ProjectReportOutTriggerHandlerTest {

    @testSetup
    static void setup() {
        DContract__c testContract1 = new DContract__c(Name = 'Test Contract 1');
        DContract__c testContract2 = new DContract__c(Name = 'Test Contract 2');
        DContract__c testContract3 = new DContract__c(Name = 'Test Contract 3');
        insert new List<DContract__c> { testContract1, testContract2, testContract3 };

        Project_Report_Out__c pro1_1 = new Project_Report_Out__c(Name = 'Test Contract 1 - PRO1', Status__c = 'Green',
                                                                 Contract__c = testContract1.Id, Report_Out_Date__c = Date.newInstance(2019, 7, 11),
                                                                 Client_Facing__c = '1_1_Client_Facing__c',
                                                                 Requires_Developer_Work__c = '1_1_Requires_Developer_Work__c',
                                                                 Issues_Questions_Notables__c = '1_1_Issues_Questions_Notables__c',
                                                                 Key_Accomplishments_Last_Two_Weeks__c = '1_1_Key_Accomplishments_Last_Two_Weeks__c',
                                                                 Key_Next_Steps_next_2_weeks__c = '1_1_Key_Next_Steps_next_2_weeks__c');
        Project_Report_Out__c pro1_2 = new Project_Report_Out__c(Name = 'Test Contract 1 - PRO2', Status__c = 'Yellow',
                                                                 Contract__c = testContract1.Id, Report_Out_Date__c = Date.newInstance(2019, 7, 25),
                                                                 Client_Facing__c = '1_2_Client_Facing__c',
                                                                 Requires_Developer_Work__c = '1_2_Requires_Developer_Work__c',
                                                                 Issues_Questions_Notables__c = '1_2_Issues_Questions_Notables__c',
                                                                 Key_Accomplishments_Last_Two_Weeks__c = '1_2_Key_Accomplishments_Last_Two_Weeks__c',
                                                                 Key_Next_Steps_next_2_weeks__c = '1_2_Key_Next_Steps_next_2_weeks__c');
        Project_Report_Out__c pro2_1 = new Project_Report_Out__c(Name = 'Test Contract 2 - PRO1', Status__c = 'Green',
                                                                 Contract__c = testContract2.Id, Report_Out_Date__c = Date.newInstance(2019, 7, 25),
                                                                 Client_Facing__c = '2_1_Client_Facing__c',
                                                                 Requires_Developer_Work__c = '2_1_Requires_Developer_Work__c',
                                                                 Issues_Questions_Notables__c = '2_1_Issues_Questions_Notables__c',
                                                                 Key_Accomplishments_Last_Two_Weeks__c = '2_1_Key_Accomplishments_Last_Two_Weeks__c',
                                                                 Key_Next_Steps_next_2_weeks__c = '2_1_Key_Next_Steps_next_2_weeks__c');
        insert new List<Project_Report_Out__c> { pro1_1, pro1_2, pro2_1 };
    }

    @isTest
    public static void shouldHandleInsert() {
        DContract__c contract1 = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                                  Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                                  Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Name = 'Test Contract 1'];
        DContract__c contract2 = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                                  Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                                  Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Name = 'Test Contract 2'];
        DContract__c contract3 = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                                  Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                                  Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Name = 'Test Contract 3'];
        Project_Report_Out__c pro1_1 = [SELECT Id FROM Project_Report_Out__c WHERE Name = 'Test Contract 1 - PRO1'];
        Project_Report_Out__c pro1_2 = [SELECT Id FROM Project_Report_Out__c WHERE Name = 'Test Contract 1 - PRO2'];
        Project_Report_Out__c pro2_1 = [SELECT Id FROM Project_Report_Out__c WHERE Name = 'Test Contract 2 - PRO1'];

        assertContract(contract1, pro1_2.Id, 'Yellow', '1_2_Client_Facing__c', '1_2_Requires_Developer_Work__c',
                            '1_2_Issues_Questions_Notables__c', '1_2_Key_Accomplishments_Last_Two_Weeks__c', '1_2_Key_Next_Steps_next_2_weeks__c');
        assertContract(contract2, pro2_1.Id, 'Green', '2_1_Client_Facing__c', '2_1_Requires_Developer_Work__c',
                            '2_1_Issues_Questions_Notables__c', '2_1_Key_Accomplishments_Last_Two_Weeks__c', '2_1_Key_Next_Steps_next_2_weeks__c');
        assertContract(contract3,null, null, null, null, null, null, null);

        Project_Report_Out__c newPro1 = new Project_Report_Out__c(Name = 'Test Contract 1 - PRO3', Status__c = 'Red',
                                                                  Contract__c = contract1.Id, Report_Out_Date__c = Date.newInstance(2019, 8, 8),
                                                                  Client_Facing__c = 'New_1_Client_Facing__c',
                                                                  Requires_Developer_Work__c = 'New_1_Requires_Developer_Work__c',
                                                                  Issues_Questions_Notables__c = 'New_1_Issues_Questions_Notables__c',
                                                                  Key_Accomplishments_Last_Two_Weeks__c = 'New_1_Key_Accomplishments_Last_Two_Weeks__c',
                                                                  Key_Next_Steps_next_2_weeks__c = 'New_1_Key_Next_Steps_next_2_weeks__c');
        Project_Report_Out__c newPro2 = new Project_Report_Out__c(Name = 'Test Contract 3 - PRO1', Status__c = 'Yellow',
                                                                  Contract__c = contract3.Id, Report_Out_Date__c = Date.newInstance(2019, 7, 25),
                                                                  Client_Facing__c = 'New_2_Client_Facing__c',
                                                                  Requires_Developer_Work__c = 'New_2_Requires_Developer_Work__c',
                                                                  Issues_Questions_Notables__c = 'New_2_Issues_Questions_Notables__c',
                                                                  Key_Accomplishments_Last_Two_Weeks__c = 'New_2_Key_Accomplishments_Last_Two_Weeks__c',
                                                                  Key_Next_Steps_next_2_weeks__c = 'New_2_Key_Next_Steps_next_2_weeks__c');
        Project_Report_Out__c newPro3 = new Project_Report_Out__c(Name = 'Test Contract 2 - PRO2', Status__c = 'Red',
                                                                  Contract__c = contract2.Id, Report_Out_Date__c = Date.newInstance(2019, 6, 27),
                                                                  Client_Facing__c = 'Bad',
                                                                  Requires_Developer_Work__c = 'Bad',
                                                                  Issues_Questions_Notables__c = 'Bad',
                                                                  Key_Accomplishments_Last_Two_Weeks__c = 'Bad',
                                                                  Key_Next_Steps_next_2_weeks__c = 'Bad');

        Test.startTest();
        insert new List<Project_Report_Out__c> { newPro1, newPro2, newPro3};
        Test.stopTest();

        DContract__c assertContract = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                                       Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                                       Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Id =: contract1.Id];
        assertContract(assertContract, newPro1.Id, 'Red', 'New_1_Client_Facing__c', 'New_1_Requires_Developer_Work__c',
                            'New_1_Issues_Questions_Notables__c', 'New_1_Key_Accomplishments_Last_Two_Weeks__c', 'New_1_Key_Next_Steps_next_2_weeks__c');
        assertContract = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                          Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                          Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Id =: contract2.Id];
        assertContract(assertContract, pro2_1.Id, 'Green', '2_1_Client_Facing__c', '2_1_Requires_Developer_Work__c',
                            '2_1_Issues_Questions_Notables__c', '2_1_Key_Accomplishments_Last_Two_Weeks__c', '2_1_Key_Next_Steps_next_2_weeks__c');
        assertContract = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                          Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                          Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Id =: contract3.Id];
        assertContract(assertContract, newPro2.Id, 'Yellow', 'New_2_Client_Facing__c', 'New_2_Requires_Developer_Work__c',
                            'New_2_Issues_Questions_Notables__c', 'New_2_Key_Accomplishments_Last_Two_Weeks__c', 'New_2_Key_Next_Steps_next_2_weeks__c');
    }

    @isTest
    public static void shouldHandleUpdate() {
        DContract__c contract1 = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                                  Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                                  Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Name = 'Test Contract 1'];
        DContract__c contract2 = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                                  Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                                  Last_PRO_Key_next_steps_next_two_weeks__c  FROM DContract__c WHERE Name = 'Test Contract 2'];
        DContract__c contract3 = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                                  Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                                  Last_PRO_Key_next_steps_next_two_weeks__c  FROM DContract__c WHERE Name = 'Test Contract 3'];
        Project_Report_Out__c pro1_1 = [SELECT Id, Status__c FROM Project_Report_Out__c WHERE Name = 'Test Contract 1 - PRO1'];
        Project_Report_Out__c pro1_2 = [SELECT Id, Status__c FROM Project_Report_Out__c WHERE Name = 'Test Contract 1 - PRO2'];
        Project_Report_Out__c pro2_1 = [SELECT Id, Status__c FROM Project_Report_Out__c WHERE Name = 'Test Contract 2 - PRO1'];

        assertContract(contract1, pro1_2.Id, 'Yellow', '1_2_Client_Facing__c', '1_2_Requires_Developer_Work__c',
                            '1_2_Issues_Questions_Notables__c', '1_2_Key_Accomplishments_Last_Two_Weeks__c', '1_2_Key_Next_Steps_next_2_weeks__c');
        assertContract(contract2, pro2_1.Id, 'Green', '2_1_Client_Facing__c', '2_1_Requires_Developer_Work__c',
                            '2_1_Issues_Questions_Notables__c', '2_1_Key_Accomplishments_Last_Two_Weeks__c', '2_1_Key_Next_Steps_next_2_weeks__c');
        assertContract(contract3, null, null, null, null, null, null, null);

        pro1_2.Status__c = 'Green';
        pro1_2.Client_Facing__c = 'updated_1';
        pro1_2.Requires_Developer_Work__c = 'updated_2';
        pro1_2.Issues_Questions_Notables__c = 'updated_3';
        pro1_2.Key_Accomplishments_Last_Two_Weeks__c = 'updated_4';
        pro1_2.Key_Next_Steps_next_2_weeks__c = 'updated_5';
        pro2_1.Status__c = 'Red';
        pro2_1.Client_Facing__c = 'u_1';
        pro2_1.Requires_Developer_Work__c = 'u_2';
        pro2_1.Issues_Questions_Notables__c = 'u_3';
        pro2_1.Key_Accomplishments_Last_Two_Weeks__c = 'u_4';
        pro2_1.Key_Next_Steps_next_2_weeks__c = 'u_5';

        Test.startTest();
        update new List<Project_Report_Out__c> { pro1_2, pro2_1 };
        Test.stopTest();

        DContract__c assertContract = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                                       Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                                       Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Id =: contract1.Id];
        assertContract(assertContract, pro1_2.Id, 'Green', 'updated_1', 'updated_2', 'updated_3', 'updated_4', 'updated_5');
        assertContract = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                          Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                          Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Id =: contract2.Id];
        assertContract(assertContract, pro2_1.Id, 'Red', 'u_1', 'u_2', 'u_3', 'u_4', 'u_5');
        assertContract = [SELECT Id, Last_Project_Report_Out__c, Last_Report_Out_Status__c, Last_PRO_Client_Facing_Deadlines__c,
                          Last_PRO_Internal_Developer_Deadlines__c, Last_PRO_Issues_Questions_Notables__c, Last_PRO_Key_accompl_last_two_weeks__c,
                          Last_PRO_Key_next_steps_next_two_weeks__c FROM DContract__c WHERE Id =: contract3.Id];
        assertContract(contract3, null, null, null, null, null, null, null);
    }

     private static void assertContract(DContract__c dContract, Id proId, String status, String textArea1, String textArea2,
                                       String textArea3, String textArea4, String textArea5) {
        System.assertEquals(proId, dContract.Last_Project_Report_Out__c);
        System.assertEquals(status, dContract.Last_Report_Out_Status__c);
        System.assertEquals(textArea1, dContract.Last_PRO_Client_Facing_Deadlines__c);
        System.assertEquals(textArea2, dContract.Last_PRO_Internal_Developer_Deadlines__c);
        System.assertEquals(textArea3, dContract.Last_PRO_Issues_Questions_Notables__c);
        System.assertEquals(textArea4, dContract.Last_PRO_Key_accompl_last_two_weeks__c);
        System.assertEquals(textArea5, dContract.Last_PRO_Key_next_steps_next_two_weeks__c);
    }
}