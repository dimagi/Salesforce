trigger ContactEmailTrigger on Contact (after update) {

    if (Trigger.New == null) {
        return;
    }

    List<Contact> updatedEmails = new List<Contact>();
    for (Contact updatedContact : Trigger.New) {
        Contact oldContact = Trigger.OldMap.get(updatedContact.Id);
        if (updatedContact.Email != oldContact.Email) {
            updatedEmails.add(updatedContact);
        }
    }

    if (updatedEmails.size() > 0 && !Test.isRunningTest()) {
        try {
            List<AuthSession> sessions = [SELECT LoginType, SessionType, LoginHistoryId, UsersId FROM AuthSession
                                      WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = true ORDER BY CreatedDate DESC];
            User u = [SELECT Id, Name FROM User WHERE Id =: UserInfo.getUserId()];
            List<LoginHistory> logHistory = [SELECT Id, Application FROM LoginHistory WHERE Id =: sessions.get(0).LoginHistoryId];
            String emailBody = '<html><body><p> <b>User :</b> ' + u.Name + ' with Id : ' + u.Id;
            emailBody += '</br></br> Updated emails : ';
            for (Contact con : updatedEmails) {
                Contact oldContact = Trigger.OldMap.get(con.Id);
                emailBody += '</br> Id: ' + con.Id + ' from : ' + oldContact.Email + ' to : ' + con.Email + ' , ';
            }
            emailBody += '</br></br> Session data : ';
            emailBody += '</br> <b>LoginType :</b> ' + sessions.get(0).LoginType;
            emailBody += '</br> <b>SessionType :</b> ' + sessions.get(0).SessionType;
            emailBody += '</br> <b>LoginHistoryId :</b> ' + sessions.get(0).LoginHistoryId;
            emailBody += '</br> <b>UsersId :</b> ' + sessions.get(0).UsersId;
            emailBody += '</br> <b>Application :</b> ' + logHistory.get(0).Application + '</p></body></html>';
            EmailHelper.sendEmail(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Contact Emails updated', emailBody);
        } catch (Exception ex) {
            BatchDefaultSettings__c settings = BatchDefaultSettings__c.getOrgDefaults();
            EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','),
                'ContactEmailTrigger error', 'Cannot load user session', ex);
        }
    }
}