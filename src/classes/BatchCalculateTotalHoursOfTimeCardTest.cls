@isTest
public class BatchCalculateTotalHoursOfTimeCardTest {
    static testMethod void TimeCardTriggerControllerTest1() {
        DContract__c contractObj = new DContract__c(
            Name = 'Test Contract',
            Requires_Report_Out__c = 'Yes',
            Intracompany_Sub_contract__c = 'No'
        );
        insert contractObj;
    
        SFDC_Employee__c employeeObj = new SFDC_Employee__c(
            name = 'Mustafa Turab',
            Salary__c = 5000,
            Exchange_Rate__c = 10
        );
        insert employeeObj;

        Time_Card__c timeCardObj1 = new Time_Card__c(
            Total__c = 1,
            Date__c = Date.today().addMonths(-1),
            Employee__c = employeeObj.Id,
            Client__c = contractObj.Id
        );
        insert timeCardObj1;
        Time_Card__c timeCardObj2 = new Time_Card__c(
            Total__c = 2,
            Date__c = Date.today().addMonths(-2),
            Employee__c = employeeObj.Id,
            Client__c = contractObj.Id
        );
        insert timeCardObj2;
        Time_Card__c timeCardObj3 = new Time_Card__c(
            Total__c = 12,
            Date__c = Date.today().addMonths(-3),
            Employee__c = employeeObj.Id,
            Client__c = contractObj.Id
        );
        insert timeCardObj3;
        Time_Card__c timeCardObj4 = new Time_Card__c(
            Total__c = 2.5,
            Date__c = Date.today().addMonths(-4),
            Employee__c = employeeObj.Id,
            Client__c = contractObj.Id
        );
        insert timeCardObj4;
        Time_Card__c timeCardObj5 = new Time_Card__c(
            Total__c = 6,
            Date__c = Date.today().addMonths(-5),
            Employee__c = employeeObj.Id,
            Client__c = contractObj.Id
        );
        insert timeCardObj5;
        Time_Card__c timeCardObj6 = new Time_Card__c(
            Total__c = 3,
            Date__c = Date.today().addMonths(-6),
            Employee__c = employeeObj.Id,
            Client__c = contractObj.Id
        );
        insert timeCardObj6;
        
        
        //List<DContract__c> contractQuery = [Select id,Total_Labor_Expenses__c from DContract__c where Id= :contractObj.Id];
        //system.assertEquals(16,contractQuery[0].Total_Labor_Expenses__c);
        BatchCalculateTotalHoursOfTimeCard obj = new BatchCalculateTotalHoursOfTimeCard();
        Database.executeBatch(obj, 200);

    }
}