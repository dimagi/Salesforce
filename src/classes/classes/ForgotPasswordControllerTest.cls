@isTest
private class ForgotPasswordControllerTest {
    @isTest static void testForgotPassword() {
        ForgotPasswordController controller = new ForgotPasswordController();
        controller.username = 'test@salesforce.com';

        Test.startTest();
        PageReference result = controller.forgotPassword();
        System.assertEquals(null, result); // Typically returns null when not run in guest site context
        Test.stopTest();
    }
}