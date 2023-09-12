public class ClockifyModel {
    public List<Totals> totals {get;set;} 
	public List<Timeentries> timeentries {get;set;}
    public class Totals {
		public Integer entriesCount {get;set;} 
    }
    public class TimeInterval {
		public String end_Z {get;set;} // in json: end
		public Integer duration {get;set;} 
    }
    public class Timeentries {
		public String x_id {get;set;} // in json: _id
		public String description {get;set;} 
		public String taskId {get;set;} 
		public TimeInterval timeInterval {get;set;} 
		public String taskName {get;set;} 
		public List<Tags> tags {get;set;} 
		public String userName {get;set;} 
		public String userEmail {get;set;} 
		public String projectName {get;set;} 
    }
    public class Tags {
		public String name {get;set;} 
    }
    public class CustomFields {

    }
    public static ClockifyModel parse(String stringJson){
        
        String replaced = stringJson.replaceAll('\"_id\"', '\"x_id\"');
        String removeTotals = replaced.replace('\"totals\":[null]', '\"totals\":[]');
        system.debug((ClockifyModel) System.JSON.deserialize(removeTotals, ClockifyModel.class));
        return (ClockifyModel) System.JSON.deserialize(removeTotals, ClockifyModel.class); 	
    }
}