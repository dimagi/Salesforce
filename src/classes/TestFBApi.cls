/**
 * Tests for the FogBugzAPI class.
 */
@isTest
public class TestFBApi {

    private final static String GET_CASES_RESPONSE = '<?xml version="1.0" encoding="UTF-8"?>' +
                                                    '<response>' +
                                                    '<cases count="1"><case ixBug="testFBId" operations="edit,assign,resolve,email,remind">' +
                                                    '<sTitle><![CDATA[Test title]]></sTitle>' +
                                                    '<sArea><![CDATA[Test area]]></sArea>' +
                                                    '<sPersonAssignedTo><![CDATA[Test assignee]]></sPersonAssignedTo>' +
                                                    '<sVersion><![CDATA[testSFId]]></sVersion>' +
                                                    '<dtLastUpdated>2012-1-1T00:00:00Z</dtLastUpdated>' +
                                                    '<tags><tag><![CDATA[[1/1]]]></tag></tags>' +
                                                    '<ixPersonOpenedBy>1</ixPersonOpenedBy>' +
                                                    '<hrsElapsed>41.7327995300293</hrsElapsed>' +
                                                    '</case></cases>' +
                                                    '</response>';

    @isTest
    public static void listLastUpdatedCaseTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        List<FogBugzCase> cases = api.getLastUpdatedCases(Date.today());
        System.assertEquals(cases.size(), 2);

        FogBugzCase fbCase1 = cases.get(0);
        FogBugzCase fbCase2 = cases.get(1);
        System.assertEquals('11111', fbCase1.caseId);
        System.assertEquals('22222', fbCase2.caseId);
        System.assertEquals('area 1', fbCase1.area);
        System.assertEquals('area 2', fbCase2.area);
        System.assertEquals('Test 1', fbCase1.project);
        System.assertEquals('Test 2', fbCase2.project);
        System.assertEquals('111', fbCase1.client);
        System.assertEquals('222', fbCase2.client);
        System.assertEquals('Title 1', fbCase1.title);
        System.assertEquals('Title 2', fbCase2.title);

        Test.stopTest();
    }

    @isTest
    public static void listCasesTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        Map<String, FogBugzCase> cases = api.listCases();
        System.assertEquals(cases.size(), 2);
        System.assert(cases.containsKey('testFBId'));
        System.assert(cases.containsKey('testFBId2'));
        FogBugzCase fbCase = cases.get('testFBId');
        FogBugzCase fbCase2 = cases.get('testFBId2');
        System.assertEquals(fbCase.caseId, 'testFBId');
        System.assertEquals(fbCase2.caseId, 'testFBId2');
        System.assertEquals(fbCase.ixPersonOpenedBy, 'salesforce');
        System.assertEquals(fbCase2.ixPersonOpenedBy, 'salesforce');
        System.assert(fbCase.lastModifiedDate != null);
        System.assertEquals(fbCase2.lastModifiedDate, null);

        Test.stopTest();
    }

    @isTest
    public static void getCaseTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        FogBugzCase fbCase = api.getCase('testFBId');
        System.assert(fbCase != null);
        System.assertEquals(fbCase.title, 'Test title');
        System.assertEquals(fbCase.area, 'Test area');
        System.assertEquals(fbCase.assignedTo, 'Test assignee');
        System.assertEquals(fbCase.externalBugID, '1');
        System.assertEquals(fbCase.caseId, 'testFBId');
        System.assertEquals(fbCase.ixPersonOpenedBy, 'salesforce');
        System.assertEquals(fbCase.latestEvent, 'event');
        System.assertEquals(fbCase.hrsElapsed, 41.7327995300293);
        System.assertEquals(fbCase.lastModifiedDate, Datetime.valueOfGmt('2012-1-1T00:00:00Z'.replace('T', ' ').removeEnd('Z')));

        Test.stopTest();
    }

    @isTest
    public static void setCurrentFilterTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        String res = api.setCurrentFilter(1);
        System.assertEquals(res, FogBugzHttpCalloutMock.RESPONSE_FILTER);

        Test.stopTest();
    }

    @isTest
    public static void createCaseTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        FogBugzCase fbCase = new FogBugzCase();
        fbCase.externalBugID = 'testSFId';
        fbCase.project = 'Test project';
        fbCase.area = 'Test area';
        fbCase.assignedTo = 'Test assignee';
        fbCase.status = 'Test status';
        fbCase.priority = 1;
        fbCase.title = 'Test title';
        fbCase.probability = 10.0;
        String fbCaseId = api.createCase(fbCase, true);
        System.assertEquals(fbCaseId, 'testFBId');

        Test.stopTest();
    }

    @isTest
    public static void resolveAndCloseCaseTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        FogBugzCase fbCase = new FogBugzCase();
        fbCase.externalBugID = 'testSFId';
        fbCase.project = 'Test project';
        fbCase.area = 'Test area';
        fbCase.assignedTo = 'Test assignee';
        fbCase.status = 'Test status';
        fbCase.priority = 1;
        fbCase.title = 'Test title';
        fbCase.caseId = 'testFBId';
        String fbCaseId = api.resolveCase(fbCase);
        System.assertEquals(fbCaseId, 'testFBId');
        fbCaseId = api.closeCase(fbCase);
        System.assertEquals(fbCaseId, 'testFBId');

        Test.stopTest();
    }

    @isTest
    public static void reopenCaseTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        FogBugzCase fbCase = new FogBugzCase();
        fbCase.externalBugID = 'testSFId';
        fbCase.project = 'Test project';
        fbCase.area = 'Test area';
        fbCase.assignedTo = 'Test assignee';
        fbCase.status = 'Test status';
        fbCase.priority = 1;
        fbCase.title = 'Test title';
        fbCase.caseId = 'testFBId';
        String fbCaseId = api.reopenCase(fbCase);
        System.assertEquals(fbCaseId, 'testFBId');

        Test.stopTest();
    }

    @isTest
    public static void updateCaseTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        FogBugzCase fbCase = new FogBugzCase();
        fbCase.externalBugID = 'testSFId';
        fbCase.project = 'Test project';
        fbCase.area = 'Test area';
        fbCase.assignedTo = 'Test assignee';
        fbCase.status = 'Test status';
        fbCase.priority = 1;
        fbCase.title = 'Test title';
        fbCase.caseId = 'testFBId';
        String fbCaseId = api.updateCase(fbCase);
        System.assertEquals(fbCaseId, 'testFBId');
        fbCase.dealSize = 1000;
        fbCase.probability = 10.0;
        fbCaseId = api.updateCaseTitleStageTag(fbCase, true, new Set<String>(), false, false);
        System.assertEquals(fbCaseId, 'testFBId');

        Test.stopTest();
    }

    @isTest
    public static void updateTagsTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        FogBugzCase fbCase = new FogBugzCase();
        fbCase.externalBugID = 'testSFId';
        fbCase.project = 'Test project';
        fbCase.area = 'Test area';
        fbCase.assignedTo = 'Test assignee';
        fbCase.status = 'Test status';
        fbCase.priority = 1;
        fbCase.title = 'Test title';
        fbCase.caseId = 'testFBId';
        String fbCaseId = api.updateCaseTitleStageTag(fbCase, true, new Set<String>{'CommCare','CommConnect'}, false, true);
        System.assertEquals(fbCaseId, 'testFBId');

        Test.stopTest();
    }

    @isTest
    public static void addNoteTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        String fbCaseId = api.addNote('testFBId', 'note');
        System.assertEquals(fbCaseId, 'testFBId');

        Test.stopTest();
    }

    @isTest
    public static void getPersonEmailTest() {
        FogBugzAPI api = new FogBugzAPI();
        Test.setMock(HttpCalloutMock.class, new FogBugzHttpCalloutMock());
        Test.startTest();

        String fbCaseId = api.getPersonEmail('salesforce');
        System.assertEquals(fbCaseId, 'salesforce');

        Test.stopTest();
    }

    @isTest
    public static void testParseCases() {
        FogBugzAPI api = new FogBugzAPI();
        api.parseCases(GET_CASES_RESPONSE);
        api.parseCaseList(GET_CASES_RESPONSE);
    }
}