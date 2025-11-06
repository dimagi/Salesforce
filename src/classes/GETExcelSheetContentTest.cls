@isTest
private class GETExcelSheetContentTest {

    @isTest
    static void testSendEmail() {
        // Make sure OrgWideEmailAddress record exists in the org (required by main class)
        List<OrgWideEmailAddress> oweList = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'dimagi-salesforce@dimagi.com' LIMIT 1];
        System.assert(!oweList.isEmpty(), 'OrgWideEmailAddress with dimagi-salesforce@dimagi.com is required for this test to run.');

        // Prepare input parameters
        String emailIds = 'test1@example.com;test2@example.com';
        String subject = 'Test Subject';
        String body = '<p>This is a test email body</p>';

        // Create a fake PageReference with mocked HTML content containing <body> tags
        Test.setMock(HttpCalloutMock.class, new FakeHtmlReportMock());

        String urlForReport = '/apex/fakeReportPage'; // This URL won't be used, as getContent() is mocked

        // Run method
        Test.startTest();
        GETExcelSheetContent.sendEmail(emailIds, subject, body, urlForReport);
        Test.stopTest();
    }

    // Inner mock class to override PageReference.getContent()
    public class FakeHtmlReportMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/html');
            res.setBody('<html><body>Mock Report Content for Test</body></html>');
            res.setStatusCode(200);
            return res;
        }
    }
}