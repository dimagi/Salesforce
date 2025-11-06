@isTest
private class ChangePasswordControllerTest {
    @isTest static void testChangePasswordController() {
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1';
        controller.verifyNewPassword = 'qwerty1';

        Test.startTest();
        PageReference result = controller.changePassword();
        System.assertEquals(null, result); // Will be null unless called from a real site context
        Test.stopTest();
    }
}