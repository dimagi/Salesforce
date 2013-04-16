/**************************************************
Class Name: OpenOpportunitiesNeedUpdateScheduler
Class Description: Daily Report Schedule class    
Author: Fernando Rodriguez (frodriguez@adooxen.com)
Modified By: Fernando
Update Date: 2013-03-04
Additional Comments: Entry Point for the Daily "Red Opportunities - Need Update" Report generation. This class executes the OpenOpportunityNeedUpdateBatch   
**************************************************/

global class OpenOpportunitiesNeedUpdateScheduler implements Schedulable {
	
    public OpenOpportunitiesNeedUpdateScheduler() {}
    
    global void execute(SchedulableContext sc) {
    
       Database.executeBatch(new OpenOpportunityNeedUpdateBatch(), 1);
    }

}