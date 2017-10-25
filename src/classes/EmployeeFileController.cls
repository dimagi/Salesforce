/** 
 * Controller for uploading Record of Emergency Data Form (RED Form).
 */
public class EmployeeFileController {

    // TODO private OAuth2Manager oAuthManager;
    public Record_of_Emergency_Data_Form__c redForm {get; set;}

    private Id employeeId;
    private String employeeEmail;
    private Boolean authenticated;
    private SFDC_Employee__c userEmployeeObj;

    public EmployeeFileController() {}

    public void loadEmployeeData() {
        this.employeeEmail = 'mpalmer@test.com';
        redForm = new Record_of_Emergency_Data_Form__c();
        List<SFDC_Employee__c> employees = [SELECT Id, Employee_First_Name__c, Employee_Last_Name__c, Employee_Middle_Name__c, Business_Unit__r.Name,
                                            DOB__c, Citizenship__c, Gender__c, Personal_Phone_Number__c,
                                            Passport_No__c, Passport_Expiration_Date__c, Current_Address_City__c,
                                            Current_Address_Street__c, Current_Address_State__c, Current_Address_Country__c,
                                            EMERGENCY_CONTACT__c, Emergency_Contact_Phone__c, Emergency_Contact_Country_of_Residence__c,
                                            Emergency_Email__c, Emergency_Contact_Relationship__c, Emergency_Contact_next_of_kin__c,
                                            Local_Emerg_Cont_Country_of_Residence__c, Local_Emergency_Contact_next_of_kin__c,
                                            LOCAL_EMERGENCY_CONTACT__c, Local_Emergency_Contact_Relationship__c, Local_Emergency_Contact_Phone__c,
                                            Local_Emergency_Contact_Email__c
                                            FROM SFDC_Employee__c WHERE Email_Address__c =: employeeEmail];

        if (employees.size() == 1) { // Load employee Data
            this.userEmployeeObj = employees.get(0);
            // Personal Details
            redForm.Employee_First_Name__c = userEmployeeObj.Employee_First_Name__c;
            redForm.Employee_Last_Name__c = userEmployeeObj.Employee_Last_Name__c;
            redForm.Employee_Middle_Name__c = userEmployeeObj.Employee_Middle_Name__c;
            redForm.Business_Unit__c = userEmployeeObj.Business_Unit__r.Name;
            redForm.DOB__c = userEmployeeObj.DOB__c;
            redForm.Citizenship__c = userEmployeeObj.Citizenship__c;
            redForm.Gender__c = userEmployeeObj.Gender__c;
            redForm.Personal_Phone_Number__c = userEmployeeObj.Personal_Phone_Number__c;
            redForm.Passport_No__c = userEmployeeObj.Passport_No__c;
            redForm.Passport_Expiration_Date__c = userEmployeeObj.Passport_Expiration_Date__c;
            redForm.Current_Address_City__c = userEmployeeObj.Current_Address_City__c;
            redForm.Current_Address_Street__c = userEmployeeObj.Current_Address_Street__c;
            redForm.Current_Address_State__c = userEmployeeObj.Current_Address_State__c;
            redForm.Current_Address_Country__c = userEmployeeObj.Current_Address_Country__c;

            // Emergency Contact
            redForm.Emergency_Contact__c = userEmployeeObj.EMERGENCY_CONTACT__c;
            redForm.Emergency_Contact_Relationship__c = userEmployeeObj.Emergency_Contact_Relationship__c;
            redForm.Emergency_Contact_Phone__c = userEmployeeObj.Emergency_Contact_Phone__c;
            redForm.Emergency_Email__c = userEmployeeObj.Emergency_Email__c;
            redForm.Emergency_Contact_Country_of_Residence__c = userEmployeeObj.Emergency_Contact_Country_of_Residence__c;
            redForm.Emergency_Contact_next_of_kin__c = userEmployeeObj.Emergency_Contact_next_of_kin__c;

            // Local Emergency Contact
            redForm.Local_Emergency_Contact__c = userEmployeeObj.LOCAL_EMERGENCY_CONTACT__c;
            redForm.Local_Emergency_Contact_Relationship__c = userEmployeeObj.Local_Emergency_Contact_Relationship__c;
            redForm.Local_Emergency_Contact_Phone__c = userEmployeeObj.Local_Emergency_Contact_Phone__c;
            redForm.Local_Emergency_Email__c = userEmployeeObj.Local_Emergency_Contact_Email__c;
            redForm.Local_Emerg_Cont_Country_of_Residence__c = userEmployeeObj.Local_Emerg_Cont_Country_of_Residence__c;
            redForm.Local_Emergency_Contact_next_of_kin__c = userEmployeeObj.Local_Emergency_Contact_next_of_kin__c;

            // Voluntary Information
            redForm.Height__c = userEmployeeObj.Height__c;
            redForm.Eye_Colour__c = userEmployeeObj.Eye_Colour__c;
            redForm.Blood_Group__c = userEmployeeObj.Blood_Group__c;
            redForm.Religion_Impact__c = userEmployeeObj.Religion_Impact__c;
            redForm.Distinguishing_Features__c = userEmployeeObj.Distinguishing_Features__c;
            redForm.Medical_Conditions_Allergies__c = userEmployeeObj.Medical_Conditions_Allergies__c;
            redForm.Regular_Medication__c = userEmployeeObj.Regular_Medication__c;
            redForm.Medical_Permission__c = userEmployeeObj.Medical_Permission__c;
            redForm.Additional_Comments__c = userEmployeeObj.Additional_Comments__c;
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot Find Employee.'));
        }
    }

    public void saveREDForm() {
        if (this.userEmployeeObj != null) {
            redForm.Employee__c = userEmployeeObj.Id;
            redForm.Filled_Date__c = Date.today();
            insert this.redForm;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Your Record of Emergency Data Form was added.'));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot Find Employee.'));
        }
    }

    public Boolean isAuthenticated() {
        return authenticated;
    }
}