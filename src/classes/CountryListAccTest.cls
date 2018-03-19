/**
  Tests for Global Account View
*/
@isTest
public class CountryListAccTest {

    @testSetup
    static void setup() {
        // insereting opps domains contracts etc.
        Account acc1 = new Account(Name = 'Acc 1', Status__c = 'Active');
        insert acc1;
        Account acc2 = new Account(Name = 'Acc 2 Test', Status__c = 'Active');
        insert acc2;
        Account acc3 = new Account(Name = 'Acc 3 NY', Status__c = 'Active');
        insert acc3;
        Account acc4 = new Account(Name = 'Child 4', Status__c = 'Active', ParentId = acc1.Id);
        insert acc4;
    }

    @isTest
    public static void shouldLoadAllAccountsByName() {
        Test.startTest();
        CountryListAcc globalAccountViewController = new CountryListAcc();

        globalAccountViewController.searchString = 'Acc'; // 4 results
        globalAccountViewController.search();

        System.assertEquals(4, globalAccountViewController.wrapperList.size());

        globalAccountViewController.searchString = 'Acc 1'; // 2 results
        globalAccountViewController.search();

        System.assertEquals(2, globalAccountViewController.wrapperList.size());

        globalAccountViewController.searchString = 'NY'; // 1 results
        globalAccountViewController.search();

        System.assertEquals(1, globalAccountViewController.wrapperList.size());

        Test.stopTest();
    }

    @isTest
    public static void shouldLoadRecordsConnectedWithChoosenAccount() {
        Test.startTest();
        
        Test.stopTest();
    }
}