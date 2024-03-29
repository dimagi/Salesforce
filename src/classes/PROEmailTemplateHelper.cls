public class PROEmailTemplateHelper {
    String baseURL = '';
    String PROURL = 'https://dimagi.my.salesforce-sites.com/sftools';
    String SnoozePageURL = '';

    public PROEmailTemplateHelper() {
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        List<PRO_Email_Remindar_Settings__c> settingList = PRO_Email_Remindar_Settings__c.getALL().values();

        if (settingList != null && settingList.size() > 0) {
            PRO_Email_Remindar_Settings__c settings = settingList[0];
            SnoozePageURL = settings.Snooze_Page_URL__C;
        }
    }

    /*
        Get Project Incharge Email Template for First Nag and Second Nag.
    */
    public String GetProjectInchargeEmailTemplate(String inchargeName, String projectInchargeId, List<DContract__c> contracts, PROEmailContractFilterType filterType) {
        String content = 'Hi ' + inchargeName + ',' + '<br/><br/>';

        if (filterType == PROEmailContractFilterType.FirstNag) {
            content = content + 'The following is a list of project report outs that are due today.  <br/>'
                        + 'Please follow the links to complete your report outs: <br/><br/>';
        } else {
            content = content + 'This is a second reminder that the following report outs still have not been completed.  <br/>'
                        + 'Please follow the links to complete your report outs: <br/><br/>';
        }

        content = content + '<table border="0">';
        for (Integer index = 0; index < contracts.size(); index++) {
            DContract__c contract = contracts.get(index);
            content = content + '<tr>';

            String projectURL = baseURL + '/' + contract.id;
            String buttonURL = SnoozePageURL + '?Id=' + contract.Id + '&NoOfDays=';
            String button1 = '<a href=' + buttonURL + 1 + '>Snooze 1 Day</a>';
            String button2 = '<a href=' + buttonURL + 2 + '>Snooze 2 Days</a>';
            String button3 = '<a href=' + buttonURL + 3 + '>Snooze 3 Days</a>';

            content = content + '<td>' + (index + 1) + ') <a href=' + PROURL + '>' + contract.Name + '</a>&nbsp;&nbsp;' + '</td>';
            content = content + '<td>' + button1 + '</td>';
            content = content + '<td>' + button2 + '</td>';
            content = content + '<td>' + button3 + '</td>';
            content = content + '</tr>';
        }
        content = content + '</table>'; 

        if (filterType == PROEmailContractFilterType.FirstNag) {
            content = content + '<br/><br/>If you would like to delay submitting the report out please follow this link to snooze all report outs.<br/><br/>';
            String buttonURL = SnoozePageURL + '?OwnerId=' + projectInchargeId + '&NoOfDays=';
            String button1 = '<a href=' + buttonURL + 1 + '>Snooze All Reports 1 day</a>';
            String button2 = '<a href=' + buttonURL + 2 + '>Snooze All Reports 2 days</a>';
            String button3 = '<a href=' + buttonURL + 3 + '>Snooze All Reports 3 days</a>';
            content = content + button1 + '&nbsp;&nbsp;' + button2 + '&nbsp;&nbsp;' + button3;
        } else {
            content = content + '<br/><br/>If you would like to delay submitting the report out, please click on one of the buttons next to the report links to snooze the report out.';
        }
        return content;
    }

    /*
        Get second nag email template for backstop.
    */
    public String GetBackstopEmailTemplate(String backstopName, List<DContract__c> contracts) {
        String content = 'Hi ' + backstopName + ',' + '<br/><br/>';
        content = content + 'The following is a list of projects you are backstopping which are still missing report outs for this PRO period.<br/><br/>';

        for (Integer index = 0; index < contracts.size(); index++) {
            DContract__c contract = contracts.get(index);
            String projectURL = baseURL + '/' + contract.Id;
            content = content + (index + 1) + ') <a href=' + PROURL + '>' + contract.Name + '</a>, PM: ' + GetPMName(contract) + ', ' + GetFormatedDateString(contract.Last_Report_Out_Date__c) + ', '
                                    + contract.Last_Report_Out_Status__c + '<br/>';
        }
        return content;
    }

    /*
        Get email template for Third Nag.In third nag all Owner,PM and 
        Contry director have same email address.
    */
    public String GetThirdNagEmailTemplate(List<DContract__c> contracts) {
        String content = 'Hi,' + '<br/><br/>';

        content = content + 'This is a notification for country directors and all PM’s and Backstops still missing report outs.<br/><br/>';
        content = content + 'The following is a list of projects which are missing report outs and have not been snoozed for 3 days.<br/><br/>';

        for (Integer index = 0; index < contracts.size(); index++) {
            DContract__c contract = contracts.get(index);
            String projectURL = baseURL + '/' + contract.Id;

            content = content + (index + 1) + ') <a href=' + PROURL + '>' + contract.Name + '</a>, PM: ' + GetPMName(contract)
                            + ', Backstop: ' + GetBackstopName(contract) + ', ' + GetFormatedDateString(contract.Last_Report_Out_Date__c) + ', ' + contract.Last_Report_Out_Status__c + '<br/>';
        }
        return content; 
    }

    /*
        Get email template for fourth Nag.In fourth nag all Owner,PM,country director and 
        Management team have same email address.
    */
    public String GetFourthNagEmailTemplate(List<DContract__c> contracts) {
        String content = 'Hi,' + '<br/><br/>';
        content = content + 'This is a notification to the management team, country directors, and PMs and Backstops still missing report outs.<br/><br/>';
        content = content + 'The following is a list of projects which are missing report outs and have not been snoozed for 7 days.<br/><br/>';

        for (Integer index = 0; index < contracts.size(); index++) {
            DContract__c contract = contracts.get(index);
            String projectURL = baseURL + '/' + contract.Id;

            content = content + (index + 1) + ') <a href=' + projectURL + '>' + contract.Name + '</a>, PM: ' + GetPMName(contract)
                                + ', Backstop: ' + GetBackstopName(contract) + ', ' + GetFormatedDateString(contract.Last_Report_Out_Date__c) + ', ' + contract.Last_Report_Out_Status__c + '<br/>';
        }
        return content; 
    }

    private String GetPMName(DContract__c contract) {
        String PMName = '';
        if (contract.Project_Manager__r != null){
            if (contract.Project_Manager__r.FirstName != null) {
                PMName = contract.Project_Manager__r.FirstName;
            } else {
                PMName = contract.Project_Manager__r.LastName;
            }
        }
        return PMName.trim();
    }

     private String GetBackstopName(DContract__c contract) {
        String BTName = '';
        if (contract.Backstop__r != null) {
            if (contract.Backstop__r.FirstName != null) {
                BTName = contract.Backstop__r.FirstName;
            } else {
                BTName = contract.Backstop__r.LastName;
            }
        }
        return BTName.trim();
    }

    private String GetFormatedDateString(Date dateObj) {
        if (dateObj == null) {
            return '';
        }
        return dateObj.month() + '-' + dateObj.day() + '-' + dateObj.year();
    }
}