/**
 * Controller for new Lead conversion button.
 */
public with sharing class LeadConversionController {

    private PageReference cancelPage = null;
    private Lead l;

    public LeadConversionController(ApexPages.StandardController sc) {
        cancelPage = sc.cancel();
        this.l = fetchLeadById(sc.getId());
    }

    public PageReference doConversion() {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        if (lcr.isSuccess()) {

            // TODO populate new fields to OPP and Account!!!

            PageReference contrPage = new ApexPages.StandardController(l).view();
            contrPage.setRedirect(true);
            return contrPage;
        } else {
            Database.Error[] errors = lcr.getErrors();
            String message = '';
            if (errors.size() > 0) {
                message += errors[0].getMessage();
            }
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot conver lead : ' + message + '.'));
        }
        return null;
    }

    public PageReference goBack() {
        return cancelPage;
    }

    private Lead fetchLeadById(Id leadId) {
        return null;
    }
}