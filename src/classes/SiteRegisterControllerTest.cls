@isTest
private class SiteRegisterControllerTest {
    @isTest static void testRegistration() {
        SiteRegisterController controller = new SiteRegisterController();
        controller.username = 'test@force.com';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';

        Test.startTest();
        // This will return null outside guest context
        System.assertEquals(null, controller.registerUser());

        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123'; 
        System.assertEquals(null, controller.registerUser());
        Test.stopTest();
    }
}