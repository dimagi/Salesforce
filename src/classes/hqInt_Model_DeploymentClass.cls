public class hqInt_Model_DeploymentClass {

    public String city;
    public String[] countries;
    public DateTime x_date;
    public String description;
    public String Domain;
    public Boolean x_Public;
    public String region;
    public String country;

    public Deployment__c createDbObject(String serverName) {
        Deployment__c deploymentObj = new Deployment__c();
        deploymentObj.city__c = this.city;
        deploymentObj.date__c = this.x_date;
        deploymentObj.description__c = this.description;
        deploymentObj.public__c = this.x_Public;
        deploymentObj.region__c = this.region;
        deploymentObj.country__c = this.country;
        deploymentObj.countries__c = String.join(this.countries,',');
        deploymentObj.Server_Name__c = serverName;

        return deploymentObj;
    }
}