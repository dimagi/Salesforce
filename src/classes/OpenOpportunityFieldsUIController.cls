/**************************************************
Class Name: OpenOpportunityFieldsUIController
Class Description: UI controller for the HTML component that renders the Open Opportunities given a Stage and a list of opportunities.   
Author: Fernando Rodriguez (frodriguez@adooxen.com)
Modified By: Fernando
Update Date: 2013-03-04
Additional Comments:

The VF page for the Open Opportunities report is composed by the VF page itself and this component.
This component is renderes for each Stage and builds the Open Opportunity table. 
The flow for this component is more or less the same as the batchs execution:
1. OpenOpportunityFieldsUIController receives a list of opportunities and a stage
2. OpenOpportunityEmailUtils creates the HTML table to be displayed for this stage (Same as the batch)
3. The content, instead of being sent through the email is rendered on the VF page.   
**************************************************/
public with sharing class OpenOpportunityFieldsUIController {

    public OpenOpportunityListData stageContainer;
    public String stageName {get; set;}
    public String htmlTable {get; set;}


    public OpenOpportunityFieldsUIController() {}
    
    
    public void setStageContainer(OpenOpportunityListData value) {

        stageContainer = value;    	
        htmlTable = OpenOpportunityEmailUtils.buildEmailStageTable(stageName, stageContainer.opportunities);
    }
    
    public OpenOpportunityListData getStageContainer() {
    	
    	return stageContainer;
    }
}