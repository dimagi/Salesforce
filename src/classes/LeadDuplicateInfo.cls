public with sharing class LeadDuplicateInfo {
    public class Request {
        @InvocableVariable(required=true) public Lead lead;
    }
    public class Result {
        @InvocableVariable public String duplicateInfo;
    }
    /**
     * Read-only: runs the duplicate rules against the (un-inserted) Lead and
     * returns a small HTML summary of the matching existing Leads with links,
     * so the screen flow can tell the user how the duplicate was matched.
     */
    @InvocableMethod(label='Describe Lead Duplicates')
    public static List<Result> describe(List<Request> requests) {
        List<Result> out = new List<Result>();
        for (Request req : requests) {
            Result r = new Result();
            Set<Id> ids = new Set<Id>();
            String ruleName = null;
            for (Datacloud.FindDuplicatesResult fdr :
                    Datacloud.FindDuplicates.findDuplicates(new List<Lead>{ req.lead })) {
                for (Datacloud.DuplicateResult dr : fdr.getDuplicateResults()) {
                    if (ruleName == null) ruleName = dr.getDuplicateRule();
                    for (Datacloud.MatchResult mr : dr.getMatchResults()) {
                        for (Datacloud.MatchRecord rec : mr.getMatchRecords()) {
                            ids.add((Id) rec.getRecord().get('Id'));
                        }
                    }
                }
            }
            if (ids.isEmpty()) {
                r.duplicateInfo = '';
                out.add(r);
                continue;
            }
            String html = '<p>This contact matches ' + ids.size() +
                ' existing Lead(s)' + (ruleName != null ? ' on rule <b>' + ruleName + '</b>' : '') + ':</p><ul>';
            for (Lead d : [SELECT Id, Name, Company, Email FROM Lead WHERE Id IN :ids ORDER BY CreatedDate DESC]) {
                String label = d.Name +
                    (String.isNotBlank(d.Company) ? ' — ' + d.Company : '') +
                    (String.isNotBlank(d.Email) ? ' (' + d.Email + ')' : '');
                html += '<li><a href="/' + d.Id + '" target="_blank">' + label + '</a></li>';
            }
            html += '</ul>';
            r.duplicateInfo = html;
            out.add(r);
        }
        return out;
    }
}
