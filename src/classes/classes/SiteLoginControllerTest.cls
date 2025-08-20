@isTest
private class SiteLoginControllerTest {
    @isTest static void testSiteLoginController() {
        SiteLoginController controller = new SiteLoginController();
        controller.username = 'test@salesforce.com';
        controller.password = '123456';

        Test.startTest();
        PageReference result = controller.login();
        Test.stopTest();

        System.assertEquals(null, result); 
    }
}