@isTest
private class MyProfilePageControllerTest {
    @isTest static void testSave() {
        List<User> existingPortalUsers = [
            SELECT id, profileId, userRoleId, Fax, Contact.Fax 
            FROM User 
            WHERE UserRoleId != null AND UserType = 'CustomerSuccess' LIMIT 1
        ];

        if (existingPortalUsers.isEmpty()) {
            User currentUser = [SELECT id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
                                FROM User WHERE id = :UserInfo.getUserId()];
            MyProfilePageController controller = new MyProfilePageController();
            System.assertEquals(currentUser.Id, controller.getUser().Id);
            System.assert(controller.getIsEdit() == false);

            controller.edit();
            System.assert(controller.getIsEdit());

            controller.cancel();
            System.assert(controller.getIsEdit() == false);

            Contact c = new Contact(LastName = 'TestContact');
            insert c;

            Test.startTest();
            controller.save();
            Test.stopTest();

            System.assertEquals(Page.ChangePassword.getUrl(), controller.changePassword().getUrl());
        } else {
            User existingPortalUser = existingPortalUsers[0];
            String randFax = String.valueOf(Math.rint(Math.random() * 1000)) + '5551234';

            System.runAs(existingPortalUser) {
                MyProfilePageController controller = new MyProfilePageController();
                System.assertEquals(existingPortalUser.Id, controller.getUser().Id);
                System.assert(controller.getIsEdit() == false);

                controller.edit();
                System.assert(controller.getIsEdit());

                controller.cancel();
                System.assert(controller.getIsEdit() == false);

                controller.getUser().Fax = randFax;

                Test.startTest();
                controller.save();
                Test.stopTest();

                System.assert(controller.getIsEdit() == false);
            }

            existingPortalUser = [
                SELECT id, fax, Contact.Fax 
                FROM User 
                WHERE id = :existingPortalUser.Id
            ];
            System.assertEquals(randFax, existingPortalUser.Fax);
            System.assertEquals(randFax, existingPortalUser.Contact.Fax);
        }
    }
    @isTest
    static void testSetContactFields() {
        // Create a mock User
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test.user@example.com',
            Username = 'test.user@example.com.test',
            Alias = 'tuser',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Title = 'Manager',
            Phone = '1234567890',
            MobilePhone = '0987654321',
            Fax = '1112223333',
            Street = '123 Test St',
            City = 'Testville',
            State = 'CA',
            PostalCode = '90001',
            Country = 'USA'
        );
        insert u;

        // Create a Contact to populate
        Contact c = new Contact();

        MyProfilePageController.setContactFields(c, u);

        System.assertEquals(u.Title, c.Title);
        System.assertEquals(u.FirstName, c.FirstName);
        System.assertEquals(u.LastName, c.LastName);
        System.assertEquals(u.Email, c.Email);
        System.assertEquals(u.Phone, c.Phone);
        System.assertEquals(u.MobilePhone, c.MobilePhone);
        System.assertEquals(u.Fax, c.Fax);
        System.assertEquals(u.Street, c.MailingStreet);
        System.assertEquals(u.City, c.MailingCity);
        System.assertEquals(u.State, c.MailingState);
        System.assertEquals(u.PostalCode, c.MailingPostalCode);
        System.assertEquals(u.Country, c.MailingCountry);
    }
}