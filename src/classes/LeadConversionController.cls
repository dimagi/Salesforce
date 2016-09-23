/**
 * Controller for new Lead conversion button.
 */
public with sharing class LeadConversionController {

    private Lead l;

    public LeadConversionController(ApexPages.StandardController sc) {
        o = fetchLeadById(sc.getId());
    }

    public PageReference doConversion() {

        PageReference contrPage = new ApexPages.StandardController(l).view();
        contrPage.setRedirect(true);
        return contrPage;
    }

    private Lead fetchLeadById(Id leadId) {
        return null;
    }
}