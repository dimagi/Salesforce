/**************************************************
Class Name: OpenOpportunityListData
Class Description: Data type which stores all opportunities for a determined stage.
Author: Fernando Rodriguez (frodriguez@adooxen.com)
Modified By: Fernando Rodriguez
Update Date: 2013-03-04
Additional Comments: Used to send the opportunity list to the OpenOpportunityFieldsUIController Controller rendering component 
**************************************************/
 public with sharing class OpenOpportunityListData {

    public String stageName {get; set;}
    public Opportunity[] opportunities {get; set;} 

    public OpenOpportunityListData(String stageName, Opportunity[] opportunities) {
    	
    	this.opportunities = opportunities;
    	this.stageName = stageName;    	
    }

}