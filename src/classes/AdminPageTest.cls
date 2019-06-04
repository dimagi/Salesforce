@isTest
public class AdminPageTest {


    @testSetup
    static void setup() {
        Integer currentYear = Date.today().year();
        List<ICDS_Domain_Snapshot__c> testData = new List<ICDS_Domain_Snapshot__c>();
        for (Integer i = 1; i <= 12; i++) {
            testData.add(new ICDS_Domain_Snapshot__c(Date__c = Date.newInstance(currentYear, i, Date.daysInMonth(currentYear, i)),
                                                     Active_Users__c = i * 10, Forms__c = i * 100, WAMs__c = i * 5));
        }
        insert testData;
    }

    @isTest
    public static void testRefresh() {
        AdminPageMainController pageCtrl = new AdminPageMainController();
        Test.setMock(HttpCalloutMock.class, new CorporateDashboardTest.DashboardCalloutMock());

        Test.startTest();
        pageCtrl.refreshSalesforcePage();
        pageCtrl.refreshDimagiToolsPage();
        Test.stopTest();
    }

    @isTest
    public static void testBatchErrorList() {
        AdminPageMainController pageCtrl = new AdminPageMainController();
        Test.startTest();
        System.assertEquals(0, pageCtrl.getBatchData().size());
        System.assertEquals(50, pageCtrl.batchPagination.pageSize);
        Test.stopTest();
    }

    @isTest
    public static void testIcdsDataList() {
        AdminPageMainController pageCtrl = new AdminPageMainController();

        Test.startTest();
        System.assertEquals(10, pageCtrl.getIcdsData().size());

        ICDS_Domain_Snapshot__c record = pageCtrl.getIcdsData().get(0);
        System.assertEquals(Date.newInstance(Date.today().year(), 12, 31), record.Date__c);
        System.assertEquals(120, record.Active_Users__c);
        System.assertEquals(1200, record.Forms__c);
        System.assertEquals(60, record.WAMs__c);

        record = pageCtrl.getIcdsData().get(9);
        System.assertEquals(Date.newInstance(Date.today().year(), 3, 31), record.Date__c);
        System.assertEquals(30, record.Active_Users__c);
        System.assertEquals(300, record.Forms__c);
        System.assertEquals(15, record.WAMs__c);

        pageCtrl.icdsPagination.nextPage();
        System.assertEquals(2, pageCtrl.getIcdsData().size());

        record = pageCtrl.getIcdsData().get(0);
        System.assertEquals(Date.newInstance(Date.today().year(), 2, Date.daysInMonth(Date.today().year(), 2)), record.Date__c);
        System.assertEquals(20, record.Active_Users__c);
        System.assertEquals(200, record.Forms__c);
        System.assertEquals(10, record.WAMs__c);
        Test.stopTest();
    }

    @isTest
    public static void testIcdsCRUD() {
        AdminPageMainController pageCtrl = new AdminPageMainController();

        Test.startTest();
        System.assertEquals(false, pageCtrl.upsertMode);
        pageCtrl.switchToAddRecord();
        System.assertEquals(true, pageCtrl.upsertMode);
        pageCtrl.icdsRecord.Active_Users__c = 1;
        pageCtrl.icdsRecord.Forms__c = 2;
        pageCtrl.icdsRecord.WAMs__c = 3;
        pageCtrl.saveIcdsRecord();
        System.assertEquals(false, pageCtrl.upsertMode);
        List<ICDS_Domain_Snapshot__c> dataList = [SELECT Id, Active_Users__c, WAMs__c, Forms__c FROM ICDS_Domain_Snapshot__c];
        System.assertEquals(13, dataList.size());

        pageCtrl.helperId = dataList.get(0).Id;
        pageCtrl.switchToUpdateRecord();
        pageCtrl.icdsRecord.Active_Users__c = 1;
        pageCtrl.icdsRecord.Forms__c = 2;
        pageCtrl.icdsRecord.WAMs__c = 3;
        pageCtrl.saveIcdsRecord();

        ICDS_Domain_Snapshot__c assertRecords = [SELECT Id, Active_Users__c, WAMs__c, Forms__c FROM ICDS_Domain_Snapshot__c WHERE Id =: dataList.get(0).Id];
        System.assertEquals(1, assertRecords.Active_Users__c);
        System.assertEquals(2, assertRecords.Forms__c);
        System.assertEquals(3, assertRecords.WAMs__c);

        pageCtrl.helperId = dataList.get(0).Id;
        pageCtrl.switchToUpdateRecord();
        pageCtrl.deleteIcdsRecord();

        dataList = [SELECT Id, Active_Users__c, WAMs__c, Forms__c FROM ICDS_Domain_Snapshot__c WHERE Id =: dataList.get(0).Id];
        System.assertEquals(0, dataList.size());
        Test.stopTest();
    }

    @isTest
    public static void testGIRAndMaltTabs() {
        Commcare_Job_Settings__c settings = Commcare_Job_Settings__c.getOrgDefaults();
        insert settings;

        CommcareToSalesforceSettings__c testCustomSetting = new CommcareToSalesforceSettings__c();
        testCustomSetting.CommCare_User_Name__c = 'CommCareUserName@gmail.com';
        testCustomSetting.CommCare_Password__c = 'CommCarePassword';
        testCustomSetting.Server_URL__c = 'https://www.test.org/hq/admin/api/global/';
        testCustomSetting.Skip_in_batch_job__c = false;
        testCustomSetting.API_Limit_Parameter__c = 10;
        testCustomSetting.Name = 'CommCare HQ';
        insert testCustomSetting;

        AdminPageMainController pageCtrl = new AdminPageMainController();
        System.assertEquals(false, pageCtrl.isMaltOrGIRJobScheduled());
        System.assertEquals(false, pageCtrl.isSyncDateValid(2019, 3));
        System.assertEquals(false, pageCtrl.isSyncDateValid(2017, 1));
        System.assertEquals(false, pageCtrl.isSyncDateValid(Date.today().year(), Date.today().month()));
        System.assertEquals(true, pageCtrl.isSyncDateValid(2019, 5));
        System.assertEquals(true, pageCtrl.isSyncDateValid(Date.today().addMonths(-1).year(), Date.today().addMonths(-1).month()));

        Test.startTest();
        pageCtrl.scheduleMaltSync();
        pageCtrl.scheduleWamSync();
        System.assertEquals(true, pageCtrl.isMaltOrGIRJobScheduled());
        Test.stopTest();
    }
}