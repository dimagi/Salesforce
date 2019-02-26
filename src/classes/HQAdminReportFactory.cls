public class HQAdminReportFactory {

    private static final List<String> supportedReportsParams = new List<String> {'spaceList', 'allprojectSpaces', 'usingMessaging', 'commcareSupply'};
    private static final Map<String, String> supportedReportsMap = new Map<String, String> {'spaceList' => 'Project Space List',
                                                                                                'allprojectSpaces' => 'All Project Spaces',
                                                                                                'usingMessaging' => 'Project Spaces Using Messaging',
                                                                                                'commcareSupply' => 'CommCare Supply Project Spaces'};

    public static List<String> getSupportedReportsParamters() {
        return supportedReportsParams;
    }

    public static Map<String, String> getSupportedReportsMap() {
        return supportedReportsMap;
    }

    public static List<HQAdminReportsGraphHelper.HQAdminGraphMetaData> getGraphsMetadata(String reportParam) {
        List<HQAdminReportsGraphHelper.HQAdminGraphMetaData> graphMetaDataList = new List<HQAdminReportsGraphHelper.HQAdminGraphMetaData>();
        if (reportParam  == 'allprojectSpaces') {
            graphMetaDataList.add(HQAdminReportsGraphHelper.getGraphMetadata(2));
            graphMetaDataList.add(HQAdminReportsGraphHelper.getGraphMetadata(3));
            graphMetaDataList.add(HQAdminReportsGraphHelper.getGraphMetadata(6));
        } else if (reportParam  == 'usingMessaging') {
            graphMetaDataList.add(HQAdminReportsGraphHelper.getGraphMetadata(4));
        } else if (reportParam  == 'commcareSupply') {
            graphMetaDataList.add(HQAdminReportsGraphHelper.getGraphMetadata(5));
        } else {
            graphMetaDataList.add(HQAdminReportsGraphHelper.getGraphMetadata(1));
        }

        return graphMetaDataList;
    }

    public static FacetController getFacetController(String reportParam) {
        FacetController facetCtrl = FacetController.buildFacetController('');
        if (reportParam  == 'allprojectSpaces') {
            facetCtrl.addCurrentFilter('is_test__c', 'false');
        } else if (reportParam  == 'usingMessaging') {
            facetCtrl.addCurrentFilter('is_test__c', 'false');
            facetCtrl.addCurrentFilter('Domain_cp_sms_ever__c', 'true');
        } else if (reportParam  == 'commcareSupply') {
            facetCtrl.addCurrentFilter('is_test__c', 'false');
            facetCtrl.addCurrentFilter('Internal_Properties__r.commtrack_domain__c', 'true');
        }
        return facetCtrl;
    }
}