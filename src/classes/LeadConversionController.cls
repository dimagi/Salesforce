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

        return null;
    }

    public PageReference goBack() {
        return cancelPage;
    }

    private Lead fetchLeadById(Id leadId) {
        return null;
    }
}