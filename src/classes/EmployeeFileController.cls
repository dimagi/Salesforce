/** 
 * Controller for uploading Record of Emergency Data Form (RED Form).
 */
public class EmployeeFileController {

    public String employeeEmail {get; set;}

    private Record_of_Emergency_Data_Form__c redForm;
    private Id employeeId;
    private SFDC_Employee__c userEmployeeObj;

    public EmployeeFileController() {
    }

    public EmployeeFileController(String employeeEmail) {
        this.employeeEmail = employeeEmail;
    }

    public void saveREDForm() {
        if (this.userEmployeeObj != null && this.employeeEmail != null) {
            redForm.Employee__c = userEmployeeObj.Id;
            redForm.Filled_Date__c = Date.today();
            insert this.redForm;
            delete this.redForm; // we must delete it here, we cannot delete this record in Trigger
            this.redForm.Id = null; // we want each time add a new record, Trigger is working only after instert
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Your Record of Emergency Data Form was added.'));
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot Find Employee. Empl obj : ' + this.userEmployeeObj + ' emplEmail : ' + this.employeeEmail));
        }
    }

    private void copyEmployeeData() {
        List<SFDC_Employee__c> employees = [SELECT Id, Employee_First_Name__c, Employee_Last_Name__c, Employee_Middle_Name__c,
                                            DOB__c, Citizenship__c, Gender__c, Personal_Phone_Number__c,
                                            Passport_No__c, Passport_Expiration_Date__c, Current_Address_City__c,
                                            Current_Address_Street__c, Current_Address_State__c, Current_Address_Country__c,
                                            EMERGENCY_CONTACT__c, Emergency_Contact_Phone__c, Emergency_Contact_Country_of_Residence__c,
                                            Emergency_Email__c, Emergency_Contact_Relationship__c, Emergency_Contact_next_of_kin__c,
                                            Local_Emerg_Cont_Country_of_Residence__c, Local_Emergency_Contact_next_of_kin__c,
                                            LOCAL_EMERGENCY_CONTACT__c, Local_Emergency_Contact_Relationship__c, Local_Emergency_Contact_Phone__c,
                                            Local_Emergency_Contact_Email__c, Height__c, Eye_Colour__c, Blood_Group__c,
                                            Religion_Impact__c, Distinguishing_Features__c, Medical_Conditions_Allergies__c,
                                            Regular_Medication__c, Medical_Permission__c, Additional_Comments__c
                                            FROM SFDC_Employee__c WHERE Email_Address__c =: this.employeeEmail];

        if (employees.size() == 1) { // Load employee Data
            this.userEmployeeObj = employees.get(0);
            // Personal Details
            this.redForm.Employee_First_Name__c = userEmployeeObj.Employee_First_Name__c;
            this.redForm.Employee_Last_Name__c = userEmployeeObj.Employee_Last_Name__c;
            this.redForm.Employee_Middle_Name__c = userEmployeeObj.Employee_Middle_Name__c;
            this.redForm.DOB__c = userEmployeeObj.DOB__c;
            this.redForm.Citizenship__c = userEmployeeObj.Citizenship__c;
            this.redForm.Gender__c = userEmployeeObj.Gender__c;
            this.redForm.Personal_Phone_Number__c = userEmployeeObj.Personal_Phone_Number__c;
            this.redForm.Passport_No__c = userEmployeeObj.Passport_No__c;
            this.redForm.Passport_Expiration_Date__c = userEmployeeObj.Passport_Expiration_Date__c;
            this.redForm.Current_Address_City__c = userEmployeeObj.Current_Address_City__c;
            this.redForm.Current_Address_Street__c = userEmployeeObj.Current_Address_Street__c;
            this.redForm.Current_Address_State__c = userEmployeeObj.Current_Address_State__c;
            this.redForm.Current_Address_Country__c = userEmployeeObj.Current_Address_Country__c;

            // Emergency Contact
            this.redForm.Emergency_Contact__c = userEmployeeObj.EMERGENCY_CONTACT__c;
            this.redForm.Emergency_Contact_Relationship__c = userEmployeeObj.Emergency_Contact_Relationship__c;
            this.redForm.Emergency_Contact_Phone__c = userEmployeeObj.Emergency_Contact_Phone__c;
            this.redForm.Emergency_Email__c = userEmployeeObj.Emergency_Email__c;
            this.redForm.Emergency_Contact_Country_of_Residence__c = userEmployeeObj.Emergency_Contact_Country_of_Residence__c;
            this.redForm.Emergency_Contact_next_of_kin__c = userEmployeeObj.Emergency_Contact_next_of_kin__c;

            // Local Emergency Contact
            this.redForm.Local_Emergency_Contact__c = userEmployeeObj.LOCAL_EMERGENCY_CONTACT__c;
            this.redForm.Local_Emergency_Contact_Relationship__c = userEmployeeObj.Local_Emergency_Contact_Relationship__c;
            this.redForm.Local_Emergency_Contact_Phone__c = userEmployeeObj.Local_Emergency_Contact_Phone__c;
            this.redForm.Local_Emergency_Email__c = userEmployeeObj.Local_Emergency_Contact_Email__c;
            this.redForm.Local_Emerg_Cont_Country_of_Residence__c = userEmployeeObj.Local_Emerg_Cont_Country_of_Residence__c;
            this.redForm.Local_Emergency_Contact_next_of_kin__c = userEmployeeObj.Local_Emergency_Contact_next_of_kin__c;

            // Voluntary Information
            this.redForm.Height__c = userEmployeeObj.Height__c;
            this.redForm.Eye_Colour__c = userEmployeeObj.Eye_Colour__c;
            this.redForm.Blood_Group__c = userEmployeeObj.Blood_Group__c;
            this.redForm.Religion_Impact__c = userEmployeeObj.Religion_Impact__c;
            this.redForm.Distinguishing_Features__c = userEmployeeObj.Distinguishing_Features__c;
            this.redForm.Medical_Conditions_Allergies__c = userEmployeeObj.Medical_Conditions_Allergies__c;
            this.redForm.Regular_Medication__c = userEmployeeObj.Regular_Medication__c;
            this.redForm.Medical_Permission__c = userEmployeeObj.Medical_Permission__c;
            this.redForm.Additional_Comments__c = userEmployeeObj.Additional_Comments__c;
        }
    }

    public Record_of_Emergency_Data_Form__c getRedForm() {
        if (this.redForm == null) {
            this.redForm = new Record_of_Emergency_Data_Form__c();
            if (this.employeeEmail != null) {
                copyEmployeeData();
            }
        }
        return this.redForm;
    }

    public void setRedForm(Record_of_Emergency_Data_Form__c redForm) {
        this.redForm = redForm;
    }
}