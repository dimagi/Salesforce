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

    @isTest
    public static void shouldSendGenericErrorEmail() {
        BatchDefaultSettings__c batchSettings = BatchDefaultSettings__c.getOrgDefaults();
        DateTime testTime = DateTime.now().addHours(-2);
        batchSettings.Last_Batch_Error_Check_Date__c = testTime;
        insert batchSettings;

        Id class1Id = [SELECT Id, Name FROM ApexClass WHERE Name = 'GenericErrorMessangerBatch'].Id;
        Id class2Id = [SELECT Id, Name FROM ApexClass WHERE Name = 'GenericErrorMessangerScheduler'].Id;
        Id class3Id = [SELECT Id, Name FROM ApexClass WHERE Name = 'StatusLoggerUtils'].Id;

        Test.startTest();
        GenericErrorMessangerScheduler testScheduler = new GenericErrorMessangerScheduler();
        testScheduler.execute(null); // Increase CC in scheduler methods
        Test.stopTest();

        // We run each method manually because we cannot insert/mock this records in DB
        GenericErrorMessangerBatch messageBatch = new GenericErrorMessangerBatch();
        System.assertEquals(0, messageBatch.start(null).size());
        messageBatch.execute(null, new List<AsyncApexJob> ());
        messageBatch.finish(null);
        System.assertNotEquals(testTime, BatchDefaultSettings__c.getOrgDefaults().Last_Batch_Error_Check_Date__c);
    }

    @isTest
    public static void shouldSendEmails() {
        Test.startTest();
        EmailHelper.sendEmail('super-test-test@test-org-test.com', 'sub_1', 'body_1');
        EmailHelper.sendEmail(new List<String> { 'super-test-test@test-org-test.com' }, 'sub_2', 'body_2');
        EmailHelper.sendEmails('super-test-test@test-org-test.com', 'sub_3', new List<String> { 'body_3' });
        EmailHelper.sendEmailFromException(new List<String> { 'super-test-test@test-org-test.com' }, 'sub_3', 'head', new CalloutException());
        Test.stopTest();
    }

    @isTest
    public static void shouldGetFieldValueFromJSON() {
        String testResult = SFAuthUtils.getFromJSON('{"menu": { "id": "1", "my_test_field": "67890", "test": { "array_val": [ {"val_1": "4", "val_2": "tt"}, {"val_1": "33", "val_2": "val"}, {"val_1": "2", "val_2": "1"}]}}}',
                                                    'my_test_field');
        System.assertEquals('67890', testResult);
        testResult = SFAuthUtils.getFromJSON('{"menu": { "id": "1", "my_test_field": "67890", "test": { "array_val": [ {"val_1": "4", "val_2": "tt"}, {"val_1": "33", "val_2": "val"}, {"val_1": "2", "val_2": "1"}], "array_type": "my_type"}}}',
                                                    'array_type');
        System.assertEquals('my_type', testResult);
    }

    @isTest
    public static void shouldDoCallout() {
        Test.setMock(HttpCalloutMock.class, new CustomResponseMock('www.test-endpoint.com/test/test-rest', 'Good Response', 200));
        Test.startTest();
        String testResult = SFAuthUtils.basicAuthCallout('www.test-endpoint.com/test/test-rest', '', 'Test-Body', 'POST');
        Test.stopTest();
        System.assertEquals('Good Response', testResult);
    }

    /**
     * QueryBuilder tests.
     */

    @isTest
    public static void queryBuilderShouldBuilidSimpleQuery() {
        QueryBuilder qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c', qBuilder.buildQuery());

        qBuilder = new QueryBuilder();
        qBuilder.selectFrom('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c', qBuilder.buildQuery());
    }

    @isTest
    public static void queryBuilderShouldBuilidAdvancedFilter1() {
        QueryBuilder qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.addAnd('Server_Name__c', 'Test1', QueryBuilder.QB_TEXT_TYPE);
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c WHERE Server_Name__c = \'Test1\'', qBuilder.buildQuery());

        qBuilder = new QueryBuilder();
        qBuilder.selectFrom('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.addAnd('Server_Name__c', new List<String> { 'Test1', 'Test2'}, QueryBuilder.QB_TEXT_TYPE);
        qBuilder.addAnd('Name', 'Test3', QueryBuilder.QB_TEXT_TYPE);
        qBuilder.addLike('Simple__r.relation_string__c', 'my like');
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c WHERE Server_Name__c IN (\'Test1\',\'Test2\') AND Name = \'Test3\' AND Simple__r.relation_string__c LIKE \'%my like%\'', qBuilder.buildQuery());
    }

    @isTest
    public static void queryBuilderShouldBuilidAdvancedFilter2() {
        QueryBuilder qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.addAnd('cpIsActive__c', 'false', QueryBuilder.QB_CHECKBOX_TYPE);
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c WHERE cpIsActive__c = false', qBuilder.buildQuery());

        qBuilder = new QueryBuilder();
        qBuilder.selectFrom('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.addAnd('Server_Name__c', new List<String> { 'Test1', 'Test2'}, QueryBuilder.QB_TEXT_TYPE);
        qBuilder.addAnd('cpIsActive__c', 'true', QueryBuilder.QB_CHECKBOX_TYPE);
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c WHERE Server_Name__c IN (\'Test1\',\'Test2\') AND cpIsActive__c = true', qBuilder.buildQuery());

        qBuilder = new QueryBuilder();
        qBuilder.selectFrom('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.addAnd('cpIsActive__c', new List<String> { 'false', 'true'}, QueryBuilder.QB_CHECKBOX_TYPE);
        qBuilder.addAnd('Server_Name__c', 'value1', QueryBuilder.QB_TEXT_TYPE);
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c WHERE cpIsActive__c IN (false,true) AND Server_Name__c = \'value1\'', qBuilder.buildQuery());
    }

    @isTest
    public static void queryBuilderShouldBuildOrderBy() {
        QueryBuilder qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.orderBy('Name', QueryBuilder.QB_DESC);
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c ORDER BY Name DESC', qBuilder.buildQuery());

        qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.orderBy('Server_Name__c', QueryBuilder.QB_ASC, true);
        qBuilder.orderBy('Name', QueryBuilder.QB_DESC);
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c ORDER BY Server_Name__c ASC NULLS LAST,Name DESC', qBuilder.buildQuery());
    }

    @isTest
    public static void queryBuilderShouldBuildGroupBy() {
        QueryBuilder qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.groupBy('Name');
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c GROUP BY Name', qBuilder.buildQuery());

        qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.groupBy('Server_Name__c');
        qBuilder.groupBy('Name');
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c GROUP BY Server_Name__c,Name', qBuilder.buildQuery());
    }

    @isTest
    public static void queryBuilderShouldBuildLimitAndOffset() {
        QueryBuilder qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.setLimit(500);
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c LIMIT 500', qBuilder.buildQuery());

        qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.setLimit(250);
        qBuilder.setOffset(500);
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c LIMIT 250 OFFSET 500', qBuilder.buildQuery());
    }

    @isTest
    public static void queryBuilderAllInOne() {
        QueryBuilder qBuilder = new QueryBuilder('Domain__c');
        qBuilder.addColumn('Id');
        qBuilder.addColumns(new List<String> { 'Name', 'Server_Name__c' });
        qBuilder.setLimit(50);
        qBuilder.setOffset(1000);
        qBuilder.orderBy('Server_Name__c', QueryBuilder.QB_ASC, true);
        qBuilder.orderBy('Name', QueryBuilder.QB_DESC);
        qBuilder.groupBy('Server_Name__c');
        qBuilder.groupBy('Name');
        qBuilder.addAnd('Server_Name__c', new List<String> { 'Test1', 'Test2'}, QueryBuilder.QB_TEXT_TYPE);
        qBuilder.addAnd('Name', 'Test3', QueryBuilder.QB_TEXT_TYPE);
        qBuilder.addLike('Simple__r.relation_string__c', 'my like');
        System.assertEquals('SELECT Id,Name,Server_Name__c FROM Domain__c WHERE Server_Name__c IN (\'Test1\',\'Test2\') AND Name = \'Test3\' AND Simple__r.relation_string__c LIKE \'%my like%\' GROUP BY Server_Name__c,Name ORDER BY Server_Name__c ASC NULLS LAST,Name DESC LIMIT 50 OFFSET 1000', qBuilder.buildQuery());
    }

    public class CustomResponseMock implements HttpCalloutMock {

        private String customUrl;
        private String expectedResBody;
        private Integer expectedCode;

        public CustomResponseMock(String customUrl, String expectedResBody, Integer expectedCode) {
            this.customUrl = customUrl;
            this.expectedResBody = expectedResBody;
            this.expectedCode = expectedCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            String endpoint = req.getEndpoint();

            if (req.getEndpoint() == this.customUrl) {
                res.setStatusCode(this.expectedCode);
                res.setBody(this.expectedResBody);
            } else {
                res.setStatusCode(500);
                res.setBody('Internal Server Error');
            }

            return res;
        }
    }
}