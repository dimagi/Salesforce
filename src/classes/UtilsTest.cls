@isTest
public class UtilsTest {

    @isTest
    public static void shouldReplaceCountWord() {
        String testValue = '{ "test_1": "2", "count": "1111", "count222": "11", "count_x": "44"}';
        Test.startTest();
        testValue = SFUtils.replaceCountWords(testValue);
        Test.stopTest();
        System.assertEquals('{ "test_1": "2", "x_count": "1111", "count222": "11", "count_x": "44"}', testValue);
    }

    @isTest
    public static void shouldBuildUrlParams() {
        Map<String, String> testValue = new Map<String, String> { 'test_1' => 'value_1', 'test_2' => 'value_2', 'test_3' => 'value_3'};
        String testResult = '';
        Test.startTest();
        testResult = SFUtils.buildURLParams(testValue);
        Test.stopTest();
        System.assertEquals('test_1=value_1&test_2=value_2&test_3=value_3', testResult);
    }

    @isTest
    public static void shouldGetPicklistValues() {
        List<SelectOption> testResult;
        Test.startTest();
        testResult = SFUtils.getPicklistValues(new DContract__c(), 'Requires_Report_Out__c');
        Test.stopTest();
        System.assertEquals(3, testResult.size());
        System.debug(testResult);
        System.assertEquals('No', testResult.get(0).getValue());
        System.assertEquals('Yes', testResult.get(1).getValue());
        System.assertEquals('N/A', testResult.get(2).getValue());
    }

    @isTest
    public static void shouldCalculateWorkingDays() {
        Test.startTest();
        System.assertEquals(0, SFUtils.getWorkingDays(null, null));
        System.assertEquals(8, SFUtils.getWorkingDays(Date.newInstance(2018, 11, 13), Date.newInstance(2018, 11, 22)));
        System.assertEquals(25, SFUtils.getWorkingDays(Date.newInstance(2018, 11, 1), Date.newInstance(2018, 12, 5)));
        Test.stopTest();
    }

    @isTest
    public static void shouldLogErrorsInfoAndWarnings() {
        BatchDefaultSettings__c batchSettings = BatchDefaultSettings__c.getOrgDefaults();
        batchSettings.Error_Emails__c = 'extra_test_1@test_test_test.test,extra_test_2@test_test_test.test';
        insert batchSettings;

        String loggerName = 'Test_Logger';
        StatusLoggerUtils.logInfo(loggerName, 'Title_1', 100, 'Message_1');
        StatusLoggerUtils.logInfo(loggerName, 'Title_2', 1, 'Message_2');
        StatusLoggerUtils.logInfo(loggerName, 'Title_3', 3, 'Message_3');
        StatusLoggerUtils.logWarning(loggerName, 'Title_4', 44, 'Message_4');
        StatusLoggerUtils.logWarning(loggerName, 'Title_5', 55, 'Message_5');
        StatusLoggerUtils.logWarning(loggerName, 'Title_6', 66, 'Message_6');
        StatusLoggerUtils.logWarning(loggerName, 'Title_7', 77, 'Message_7');
        StatusLoggerUtils.logWarning(loggerName, 'Title_8', 88, 'Message_8');
        StatusLoggerUtils.logWarning(loggerName, 'Title_9', 99, 'Message_9');
        StatusLoggerUtils.logError(loggerName, 'Title_10', 77, 'Message_10');
        StatusLoggerUtils.logError(loggerName, 'Title_11', 200, 'Message_11');

        Test.startTest();
        System.assertEquals(true, StatusLoggerUtils.errorsForLogger(loggerName));
        System.assertEquals(true, StatusLoggerUtils.errorsForLoggerWithTitle(loggerName, 'Title_11'));
        System.assertEquals(false, StatusLoggerUtils.errorsForLoggerWithTitle(loggerName, 'Title_1'));
        System.assertEquals(true, StatusLoggerUtils.errorsForLoggerWithoutTitle(loggerName, 'Title_1'));
        System.assertEquals(true, StatusLoggerUtils.errorsForLoggerWithoutTitle(loggerName, 'Title_10'));
        System.assertEquals(3, [SELECT Id FROM Status_Log__c WHERE Status__c =: StatusLoggerUtils.INFO_LOG].size());
        System.assertEquals(6, [SELECT Id FROM Status_Log__c WHERE Status__c =: StatusLoggerUtils.WARNING_LOG].size());
        System.assertEquals(2, [SELECT Id FROM Status_Log__c WHERE Status__c =: StatusLoggerUtils.ERROR_LOG].size());
        StatusLoggerUtils.sendLog(loggerName);
        System.assertEquals(0, [SELECT Id FROM Status_Log__c WHERE Status__c =: StatusLoggerUtils.INFO_LOG].size());
        System.assertEquals(0, [SELECT Id FROM Status_Log__c WHERE Status__c =: StatusLoggerUtils.WARNING_LOG].size());
        System.assertEquals(0, [SELECT Id FROM Status_Log__c WHERE Status__c =: StatusLoggerUtils.ERROR_LOG].size());
        Test.stopTest();
    }
}