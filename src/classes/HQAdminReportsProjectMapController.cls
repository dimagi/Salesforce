public class HQAdminReportsProjectMapController {

    public String mapAccessToken { get; set; }

    public HQAdminReportsProjectMapController() {
        this.mapAccessToken = Admin_Reports_Settings__c.getOrgDefaults().DM_Map_Token__c;
    }

}