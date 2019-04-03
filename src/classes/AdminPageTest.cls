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
}