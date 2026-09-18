public with sharing class LeadDupeBypass {
    public class Request {
        @InvocableVariable(required=true)
        public Lead leadToInsert;
    }
    public class Result {
        @InvocableVariable public String newLeadId;
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String errorMessage;
    }
    @InvocableMethod(label='Insert Lead Bypassing Duplicate Rules'
        description='Inserts a Lead with Database DML duplicate-rule bypass (allowSave=true).')
    public static List<Result> insertLeads(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result r = new Result();
            r.isSuccess = false;
            try {
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.AllowSave = true;
                Database.SaveResult sr = Database.insert(req.leadToInsert, dml);
                if (sr.isSuccess()) {
                    r.isSuccess = true;
                    r.newLeadId = sr.getId();
                } else {
                    r.errorMessage = sr.getErrors()[0].getMessage();
                }
            } catch (Exception e) {
                r.errorMessage = e.getMessage();
            }
            results.add(r);
        }
        return results;
    }
}
