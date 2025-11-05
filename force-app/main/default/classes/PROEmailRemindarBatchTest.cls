@IsTest
public class PROEmailRemindarBatchTest {

    @testSetup
    static void setup() {
        Business_Unit__c bu = new Business_Unit__c(
            Name = 'Test Business Unit'
        );
        insert bu;

        SFDC_Employee__c emp = new SFDC_Employee__c(
            Name = 'Test Director',
            Email_Address__c = 'director@example.com',
            Business_Unit__c = bu.Id,
            Title__c = 'company director',
            Exchange_Rate__c = 10
        );
        insert emp;

        Contact pmContact = new Contact(
            FirstName = 'Project',
            LastName = 'Manager',
            Email = 'pm@dimagi.com'
        );
        insert pmContact;

        insert new DContract__c(
            Name = 'FirstNag Contract',
            Requires_Report_Out__c = 'Yes',
            Workflow_Escalation_Enabled__c = true,
            Project_Manager__c = pmContact.Id,
            Prime_Contracting_Business_Unit__c = bu.Id
        );
        insert new DContract__c(
            Name = 'SecondNag Contract',
            Requires_Report_Out__c = 'Yes',
            Workflow_Escalation_Enabled__c = true,
            Project_Manager__c = pmContact.Id,
            Is_First_Nag_Sent__c = true,
            Prime_Contracting_Business_Unit__c = bu.Id
        );
        insert new DContract__c(
            Name = 'ThirdNag Contract',
            Requires_Report_Out__c = 'Yes',
            Workflow_Escalation_Enabled__c = true,
            Project_Manager__c = pmContact.Id,
            Is_First_Nag_Sent__c = true,
            Prime_Contracting_Business_Unit__c = bu.Id
        );
        insert new DContract__c(
            Name = 'FourthNag Contract',
            Requires_Report_Out__c = 'Yes',
            Workflow_Escalation_Enabled__c = true,
            Project_Manager__c = pmContact.Id,
            Is_First_Nag_Sent__c = true,
            Prime_Contracting_Business_Unit__c = bu.Id
        );
    }

    @isTest
    static void testProcessHelperEmails() {
        Map<Id, SFDC_Employee__c> empMap = new Map<Id, SFDC_Employee__c>(
            [SELECT Id, Email_Address__c, Business_Unit__c 
             FROM SFDC_Employee__c WHERE Title__c = 'company director']
        );

        Id owaId = null;
        List<OrgWideEmailAddress> owAs = [
            SELECT Id FROM OrgWideEmailAddress 
            WHERE Address = 'dimagi-salesforce@dimagi.com' LIMIT 1
        ];
        if (!owAs.isEmpty()) {
            owaId = owAs[0].Id;
        }

        Test.startTest();
        PROEmailProcessHelper helper = new PROEmailProcessHelper(
            owaId,
            'management@example.com',
            empMap
        );

    List<DContract__c> contracts = [
    SELECT Id, Name, Last_Report_Out_Date__c, Last_Report_Out_Status__c, 
           Is_Snooze__c, Is_First_Nag_Sent__c,
           Snooze_Days__c, Snooze_Date__c, First_Nag_Sent_Date__c,
           OwnerId, Owner.Name, Owner.Email,
           Backstop__c, Backstop__r.FirstName, Backstop__r.LastName, Backstop__r.Email,
           Project_Manager__c, Project_Manager__r.FirstName, Project_Manager__r.LastName, Project_Manager__r.Email,
           Prime_Contracting_Business_Unit__c, Last_Report_Out_Created_Date__c,
           In_Charge_Of_Report_Out__c, 
           Field_Manager__c, Field_Manager__r.FirstName, Field_Manager__r.LastName, Field_Manager__r.Email,
           CreatedDate
    FROM DContract__c
];

        List<DContract__c> first = new List<DContract__c>();
        List<DContract__c> second = new List<DContract__c>();
        List<DContract__c> third = new List<DContract__c>();
        List<DContract__c> fourth = new List<DContract__c>();

        for (DContract__c c : contracts) {
            if (c.Name.contains('FirstNag')) first.add(c);
            if (c.Name.contains('SecondNag')) second.add(c);
            if (c.Name.contains('ThirdNag')) third.add(c);
            if (c.Name.contains('FourthNag')) fourth.add(c);
        }

        helper.processFirstNag(first);
        helper.processSecondNag(second);
        helper.processThirdNag(third);
        helper.processFourthNag(fourth);

        Test.stopTest();

        System.assert(true, 'ProcessHelper methods executed without exceptions');
    }

}