/**************************************************
Class Name: OpenOpportunitiesScheduler
Class Description: Weekly Report Schedule class    
Author: Fernando Rodriguez (frodriguez@adooxen.com)
Modified By: Fernando
Update Date: 2013-03-04
Additional Comments: Entry Point for the Weekly Report generation. This class executes the OpenOpportunitiesBatch   
**************************************************/
global class OpenOpportunitiesScheduler implements Schedulable {
	
	public OpenOpportunitiesScheduler() {}
	
	global void execute(SchedulableContext sc) {
	
	   Database.executeBatch(new OpenOpportunitiesBatch(), 1);	
	}

}