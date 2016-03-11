public class hqInt_Model_DeploymentClass
{
    public String city;
    public String[] countries;
    public DateTime x_date;
    public String description;
    public String Domain;
    public Boolean x_Public;
    public String region;
    public String country;
    public String domainId; //for maintaining the domainid
    
    public Deployment__c createDbObject()
    {
        Deployment__c deploymentObj = new Deployment__c();  
        deploymentObj.city__c = this.city;
        deploymentObj.date__c = this.x_date;
        deploymentObj.description__c = this.description;
        //deploymentObj.domain__c = parentDomainId;
        deploymentObj.public__c = this.x_Public;
        deploymentObj.region__c = this.region;
        deploymentObj.country__c = this.country;
        deploymentObj.countries__c = String.join(this.countries,',');
        return deploymentObj;
    }
}