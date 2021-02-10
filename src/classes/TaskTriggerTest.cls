@isTest
public class TaskTriggerTest {

    @isTest
    static void testbatch() {
        Account theAccount = new Account(
            Name ='Test Account'
        );
        insert theAccount;

        Contact theContact = new Contact(
            LastName = 'Test Contact 1',
            AccountId = theAccount.Id
        );
        insert theContact;

        Opportunity theOpp1 = new Opportunity(
            Name = 'Test Opp',
            CloseDate = date.today()+ 1,
            StageName = 'Stage 2 - Talking',
            Opportunity_Owner_Division__c = 'Solutions',
            Opportunity_Owner_Sub_Division__c='Inbound Sales'
        );
        insert theOpp1;

        Opportunity theOpp2 = new Opportunity(
            Name = 'Test Opp2',
            CloseDate = date.today()+ 1,
            StageName = 'Stage 2 - Talking',
            Opportunity_Owner_Division__c = 'Solutions',
            Opportunity_Owner_Sub_Division__c='Inbound Sales'
        );
        insert theOpp2;

        OpportunityContactRole contactRole1 = new OpportunityContactRole(
            OpportunityId = theOpp1.id,
            ContactId = theContact.Id
        );
        insert contactRole1;

        OpportunityContactRole contactRole2 = new OpportunityContactRole(
            OpportunityId = theOpp2.id,
            ContactId = theContact.Id
        );
        insert contactRole2;

        Task theTask = new Task(
            Subject = 'Call',
            WhoId = theContact.Id,
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert theTask;

        List<Task> taskList = [SELECT Id FROM Task WHERE WhatId =: theOpp2.Id];
        System.assertNotEquals(taskList, null);
    }
}