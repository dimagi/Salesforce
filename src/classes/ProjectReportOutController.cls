/**
 * This class provides functionality to Dimagi Project Report Outs Site.
 *
 * @author Virginia Fernández
 * @modifiedBy Nick Nestle - nnestle@dimagi.com
 * @modifiedBy Pablo Vigil - pablo.vigil@roundfusion.com
 * @since 2014-05
 */
public with sharing class ProjectReportOutController {
    public Map<Id, String> contractIdName = new Map<Id, String> {};

    public String dateAlert {get; set;}
    public Project_Report_Out__c pro {get; set;}
    public String contractId {get; set;}
    public Boolean showDevWork {get; set;}

    public Boolean isAuthenticated {get; set;}
    public String password {get; set;}

    public ProjectReportOutController() {
        isAuthenticated = false;
        showDevWork = false;
    }

    // What to do initially.
    public void initAction() {
        pro = new Project_Report_Out__c();
    }

    // Creates the list of countries to display in the select list.
    public List<DContract__c> getContracts() {
        // Change made on 4/1/2014 by Nick N.
        // Removed the Active requirement from the filter.
        DContract__c[] contracts = [SELECT Id, Name, Requires_Developer_Work__c
                                           FROM DContract__c 
                                           WHERE Requires_Report_Out__c = 'Yes' 
                                           ORDER BY Name];
        for (DContract__c cnt : contracts) {
            contractIdName.put(cnt.Id, cnt.Name);
        }
        return contracts;
    }

    /**
     * Checks if the date entered is the second or fourth thursday.
     * @return True if the date format it's right, false otherwise.
     */
    public boolean validData() {
        Date startOfWeek = pro.Report_Out_Date__c.toStartOfWeek();
        integer dayOfMonth = pro.Report_Out_Date__c.day();

        // Check if user has selected one project.
        if (contractId == null || contractId == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select a project.'));
            return false;
        }

        // If it's not a Thursday return invalid.
        if (startOfWeek.daysBetween(pro.Report_Out_Date__c) != 4) {
            alertInvalidDate();
            return false;
        }
        // If it is a thursday check that it's the second or fourth.
        else if(dayOfMonth < 8) {
            alertInvalidDate();
            return false;
        }
        else if(dayOfMonth < 15) {
            return true;
        }
        else if(dayOfMonth < 22) {
            alertInvalidDate();
            return false;
        }
        else if (dayOfMonth < 29) {
            return true;
        }
        else {
            alertInvalidDate();
            return false;
        }
    }

    // Alert that the day is wrong.
    private void alertInvalidDate() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'You must select the second or fourth Thursday of the month.'));
    }

    // What to do when submit is clicked.
    public PageReference save() {
        PageReference page = null;

        // Check all required fields are set, otherwise returns an error message.
        if (validData()) {
            pro.Contract__c = contractId;
            pro.Name = contractIdName.get(pro.Contract__c) + ' - [' + pro.Report_Out_Date__c.format() + ']';

            try {
                insert pro;
                page =  new PageReference('/apex/ProjectReportOutSubmitted');
            } catch (Exception e) {
                System.debug(e.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'There was an error trying to save. Please try again.'));
            }
        }
        return page;
    }

    public PageReference submitAnother() {
        PageReference newPage = new PageReference('/apex/ProjectReportOut');
        return newPage ;
    }

    public void authenticate() {
        Misc_Settings__c settings = Misc_Settings__c.getOrgDefaults();

        if (password == settings.Project_Report_Out_Password__c) {
            isAuthenticated = true;
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Wrong password.'));
        }
    }
}