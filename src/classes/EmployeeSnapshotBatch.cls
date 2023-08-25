/**
 * Batch Job class used to cerate Monthly Employee Snapshots.
 */
 public without sharing class EmployeeSnapshotBatch implements Database.Batchable<SFDC_Employee__c>, Database.Stateful {

    private Date currentDate;

    public EmployeeSnapshotBatch() {
        this.currentDate =  Date.today();
    }

    public EmployeeSnapshotBatch(Date currDate) {
        this.currentDate = currDate;
    }

    public List<SFDC_Employee__c> start(Database.BatchableContext context) {
       return [SELECT Id, Name, X401K__c, Additional_Education__c, Salary__c, Annual_Salary_in_USD__c, At_Will_Employment_Agreement__c, ABSO__c, Account_Number__c, Account_Type__c,
                      BU_Description__c, Bonus_Potential__c, BizDev__c, Base_location__c, Bank_Name__c, Business_Unit__c, Call_Center__c, Citizenship__c, Citizenship_2__c, COL_Location__c,
                      Consented_to_share_salary__c, Contact__c, Corp_Photo__c, Country__c, Country_of_Visa__c, Current_Address__c, Current_Address_City__c, Current_Address_Country__c,
                      Current_Address_State__c, Current_Address_Street__c, Current_Address_Zip_Postal_Code__c, Data__c, Date_joining__c, Date_of_Policy_Expiry__c,
                      Days_Employed__c, Education__c, Dental_Benefits__c, Dental_Insurance__c, Sub_Unit__c, Desk_Terminal__c, Email_Address__c, Direct_Cost__c, Direct_Manager_Lookup__c,
                      Direct_Manager__c, DLAC__c, DMoz__c, DOB__c, DSA__c, DSI__c, DWA__c, Effective_Exchange_Rate_Date__c, Effective_Salary_Date__c, EMERGENCY_CONTACT__c,
                      Emergency_Contact_Phone__c, Emergency_Contact_Relationship__c, Emergency_Email__c, EMP_ID__c, Employee_Fax__c, Employee_First_Name__c, Employee_Folder_Dropbox_Location__c,
                      Employee_ID__c, Employee_Last_Name__c, Employee_Middle_Name__c, Employee_Status__c, Employee_Type__c, Entity__c, Ethnicity__c, Exchange_Rate__c, Federal_Tax_Withholding__c,
                      Field_Location__c, Former_Employer_1__c, Former_Employer__c, Former_Employer_3__c, Gender__c, Global_Services__c, Group__c, Gym_Member__c, Hire_Date__c, Home_Address__c,
                      Hourly_Rate_Time_Reports__c, Hours_Per_Pay_Period__c, Per_Week_Hours__c, INC__c, Insurance_Beneficiary__c, IsAssistant__c, Job_Function__c, JPG__c, Language_1_Proficiency__c,
                      Language_2_Proficiency__c, Language_3_Proficiency__c, Language_4_Proficiency__c, Language_5_Proficiency__c, Language_6_Proficiency__c, Languages_Spoken__c, Language_Spoken_2__c,
                      Language_Spoken_3__c, Language_Spoken_4__c, Language_Spoken_5__c, Language_Spoken_6__c, Payroll_Notes__c, Last_Review_Date__c, Loaded_Daily_Rate__c, Currency__c, LOCAL_EMERGENCY_CONTACT__c,
                      Local_Emergency_Contact_Email__c, Local_Emergency_Contact_Phone__c, Local_Emergency_Contact_Relationship__c, Local_Loaded_Daily_Rate__c, Local_Unloaded_Daily_Rate__c, Mail_Drop__c, Marital_Status__c,
                      Marketing_Communications__c, Policy_No__c, Medical_Benefits__c, Member_ID__c, Insurance_Provider__c, Med_Type__c, Medical_Plan_Coverage_Type__c, Method_of_Payment__c,
                      Myanmar__c, OCI_No__c, Dimagi_Extension__c, Phone_Number__c, Ops__c, Org_Unit__c, Passport_Expiration_Date__c, Passport_Expiration_Date_2__c, Passport_No__c, Passport_2__c,
                      Pay_Level__c, PayPal_User_ID__c, Pay_Rate__c, Payroll_Frequency__c, Pay_Update_Notes__c, Pension_Plan__c, Home_Email__c, Personal_Phone_Number__c, Position_Date__c,
                      Position_ID__c, Years_of_exp__c, Re_Hire_Date__c, Roth_401K_Deduction_or__c, Routing_Number__c, Secondary_Manager__c, Section_Sup__c, Expected_Termination_Date__c,
                      SF_User__c, Signature_on_File__c, Signed_Travel_Waiver__c, SI_Type__c, Skype_ID__c, Special_Skills__c, SSN_PAN_ID_Number__c, State_Tax_Withholding__c, Stock_Options__c,
                      Stock_Value_Day_1__c, Supervisor_Emp_ID__c, Swift_Code_IFSC_Code__c, Tax_Address_City__c, Tax_Address_Country__c, Tax_Address_State__c, Tax_Address_Street__c, Tax_Address_Zip_Postal_Code__c,
                      Tax_Number__c, Tech__c, TEMP_Annual_Local_Salary__c, TEMP_Pay_Rate_Per_Pay_Period__c, Termination_Date__c, Title__c, Total_Business_Unit_Time_Split__c, Total_Department_Time_Split__c,
                      Total_Stock_Value__c, X401K_Payroll_Deduction__c, Unit__c, Unloaded_Daily_Rate__c, USD_Currency_Per_Pay_period__c, User_link__c, User_ID__c, Vacation_Days__c, Visa_Expiration_Date__c,
                      VISA_No__c, VISA_Type__c, Voter_ID__c, Yearly_Comp__c, Working_Days__c, Additional_Comments__c, Blood_Group__c, Distinguishing_Features__c, Emergency_Contact_Country_of_Residence__c,
                      Emergency_Contact_next_of_kin__c, Eye_Colour__c, Height__c, Local_Emerg_Cont_Country_of_Residence__c, Local_Emergency_Contact_next_of_kin__c, Medical_Conditions_Allergies__c,
                      Medical_Permission__c, Red_Form_Filled_Date__c, Religion_Impact__c, Regular_Medication__c, New_Business__c, BizOps__c, Sub_Department__c, Division__c, Sub_Division__c FROM SFDC_Employee__c ];
    }

    public void execute(Database.BatchableContext context, List<SFDC_Employee__c> scope) {
        List<SFDC_Employee_Snapshot__c> emplSnpList = new List<SFDC_Employee_Snapshot__c>();
        try {
            for (SFDC_Employee__c empl : scope) {
                emplSnpList.add(new SFDC_Employee_Snapshot__c(Name = empl.Name, Snapshot_Date__c = this.currentDate, Employee_Record__c = empl.Id,
                                X401K__c = empl.X401K__c, Additional_Education__c = empl.Additional_Education__c, Salary__c = empl.Salary__c, Annual_Salary_in_USD__c = empl.Annual_Salary_in_USD__c,
                                At_Will_Employment_Agreement__c = empl.At_Will_Employment_Agreement__c, ABSO__c = empl.ABSO__c, Account_Number__c = empl.Account_Number__c, Account_Type__c = empl.Account_Type__c,
                                Bank_Name__c = empl.Bank_Name__c, Base_location__c = empl.Base_location__c, BizDev__c = empl.BizDev__c, Bonus_Potential__c = empl.Bonus_Potential__c, BU_Description__c = empl.BU_Description__c,
                                Business_Unit__c = empl.Business_Unit__c, Call_Center__c = empl.Call_Center__c, Citizenship__c = empl.Citizenship__c, Citizenship_2__c = empl.Citizenship_2__c, COL_Location__c = empl.COL_Location__c,
                                Consented_to_share_salary__c = empl.Consented_to_share_salary__c, Contact__c = empl.Contact__c, Corp_Photo__c = empl.Corp_Photo__c, Country__c = empl.Country__c,
                                Country_of_Visa__c = empl.Country_of_Visa__c, Current_Address__c = empl.Current_Address__c, Current_Address_City__c = empl.Current_Address_City__c,
                                Current_Address_Country__c = empl.Current_Address_Country__c, Current_Address_State__c = empl.Current_Address_State__c, Current_Address_Street__c = empl.Current_Address_Street__c,
                                Current_Address_Zip_Postal_Code__c = empl.Current_Address_Zip_Postal_Code__c, Data__c = empl.Data__c, Date_joining__c = empl.Date_joining__c, Date_of_Policy_Expiry__c = empl.Date_of_Policy_Expiry__c,
                                Days_Employed__c = empl.Days_Employed__c, Education__c = empl.Education__c, Dental_Benefits__c = empl.Dental_Benefits__c, Dental_Insurance__c = empl.Dental_Insurance__c, Sub_Unit__c = empl.Sub_Unit__c,
                                Desk_Terminal__c = empl.Desk_Terminal__c, Email_Address__c = empl.Email_Address__c, Direct_Cost__c = empl.Direct_Cost__c, Direct_Manager_Lookup__c = empl.Direct_Manager_Lookup__c,
                                Direct_Manager__c = empl.Direct_Manager__c, DLAC__c = empl.DLAC__c, DMoz__c = empl.DMoz__c, DOB__c = empl.DOB__c, DSA__c = empl.DSA__c, DSI__c = empl.DSI__c, DWA__c = empl.DWA__c,
                                Effective_Exchange_Rate_Date__c = empl.Effective_Exchange_Rate_Date__c, Effective_Salary_Date__c = empl.Effective_Salary_Date__c, EMERGENCY_CONTACT__c = empl.EMERGENCY_CONTACT__c,
                                Emergency_Contact_Phone__c = empl.Emergency_Contact_Phone__c, Emergency_Contact_Relationship__c = empl.Emergency_Contact_Relationship__c, Emergency_Email__c = empl.Emergency_Email__c,
                                EMP_ID__c = empl.EMP_ID__c, Employee_Fax__c = empl.Employee_Fax__c, Employee_First_Name__c = empl.Employee_First_Name__c, Employee_Folder_Dropbox_Location__c = empl.Employee_Folder_Dropbox_Location__c,
                                Employee_ID__c = empl.Employee_ID__c, Employee_Last_Name__c = empl.Employee_Last_Name__c, Employee_Middle_Name__c = empl.Employee_Middle_Name__c, Employee_Status__c = empl.Employee_Status__c,
                                Employee_Type__c = empl.Employee_Type__c, Entity__c = empl.Entity__c, Ethnicity__c = empl.Ethnicity__c, Exchange_Rate__c = empl.Exchange_Rate__c, Federal_Tax_Withholding__c = empl.Federal_Tax_Withholding__c,
                                Field_Location__c = empl.Field_Location__c, Former_Employer_1__c = empl.Former_Employer_1__c, Former_Employer__c = empl.Former_Employer__c, Former_Employer_3__c = empl.Former_Employer_3__c,
                                Gender__c = empl.Gender__c, Global_Services__c = empl.Global_Services__c, Group__c = empl.Group__c, Gym_Member__c = empl.Gym_Member__c, Hire_Date__c = empl.Hire_Date__c, Home_Address__c = empl.Home_Address__c,
                                Hourly_Rate_Time_Reports__c = empl.Hourly_Rate_Time_Reports__c, Hours_Per_Pay_Period__c = empl.Hours_Per_Pay_Period__c, Per_Week_Hours__c = empl.Per_Week_Hours__c, INC__c = empl.INC__c,
                                Insurance_Beneficiary__c = empl.Insurance_Beneficiary__c, IsAssistant__c = empl.IsAssistant__c, Job_Function__c = empl.Job_Function__c, JPG__c = empl.JPG__c, Language_1_Proficiency__c = empl.Language_1_Proficiency__c,
                                Language_2_Proficiency__c = empl.Language_2_Proficiency__c, Language_3_Proficiency__c = empl.Language_3_Proficiency__c, Language_4_Proficiency__c = empl.Language_4_Proficiency__c,
                                Language_5_Proficiency__c = empl.Language_5_Proficiency__c, Language_6_Proficiency__c = empl.Language_6_Proficiency__c, Languages_Spoken__c = empl.Languages_Spoken__c, Language_Spoken_2__c = empl.Language_Spoken_2__c,
                                Language_Spoken_3__c = empl.Language_Spoken_3__c, Language_Spoken_4__c = empl.Language_Spoken_4__c, Language_Spoken_5__c = empl.Language_Spoken_5__c, Language_Spoken_6__c = empl.Language_Spoken_6__c,
                                Payroll_Notes__c = empl.Payroll_Notes__c, Last_Review_Date__c = empl.Last_Review_Date__c, Loaded_Daily_Rate__c = empl.Loaded_Daily_Rate__c, Currency__c = empl.Currency__c, LOCAL_EMERGENCY_CONTACT__c = empl.LOCAL_EMERGENCY_CONTACT__c,
                                Local_Emergency_Contact_Email__c = empl.Local_Emergency_Contact_Email__c, Local_Emergency_Contact_Phone__c = empl.Local_Emergency_Contact_Phone__c, Local_Emergency_Contact_Relationship__c = empl.Local_Emergency_Contact_Relationship__c,
                                Local_Loaded_Daily_Rate__c = empl.Local_Loaded_Daily_Rate__c, Local_Unloaded_Daily_Rate__c = empl.Local_Unloaded_Daily_Rate__c, Mail_Drop__c = empl.Mail_Drop__c, Marital_Status__c = empl.Marital_Status__c,
                                Marketing_Communications__c = empl.Marketing_Communications__c, Policy_No__c = empl.Policy_No__c, Medical_Benefits__c = empl.Medical_Benefits__c, Member_ID__c = empl.Member_ID__c,
                                Insurance_Provider__c = empl.Insurance_Provider__c, Med_Type__c = empl.Med_Type__c, Medical_Plan_Coverage_Type__c = empl.Medical_Plan_Coverage_Type__c, Method_of_Payment__c = empl.Method_of_Payment__c,
                                Myanmar__c = empl.Myanmar__c, OCI_No__c = empl.OCI_No__c, Dimagi_Extension__c = empl.Dimagi_Extension__c, Phone_Number__c = empl.Phone_Number__c, Ops__c = empl.Ops__c, Org_Unit__c = empl.Org_Unit__c,
                                Passport_Expiration_Date__c = empl.Passport_Expiration_Date__c, Passport_Expiration_Date_2__c = empl.Passport_Expiration_Date_2__c, Passport_No__c = empl.Passport_No__c, Passport_2__c = empl.Passport_2__c,
                                Pay_Level__c = empl.Pay_Level__c, PayPal_User_ID__c = empl.PayPal_User_ID__c, Pay_Rate__c = empl.Pay_Rate__c, Payroll_Frequency__c = empl.Payroll_Frequency__c, Pay_Update_Notes__c = empl.Pay_Update_Notes__c,
                                Pension_Plan__c = empl.Pension_Plan__c, Home_Email__c = empl.Home_Email__c, Personal_Phone_Number__c = empl.Personal_Phone_Number__c, Position_Date__c = empl.Position_Date__c,
                                Position_ID__c = empl.Position_ID__c, Years_of_exp__c = empl.Years_of_exp__c, Re_Hire_Date__c = empl.Re_Hire_Date__c, Roth_401K_Deduction_or__c = empl.Roth_401K_Deduction_or__c,
                                Routing_Number__c = empl.Routing_Number__c, Secondary_Manager__c = empl.Secondary_Manager__c, Section_Sup__c = empl.Section_Sup__c, Expected_Termination_Date__c = empl.Expected_Termination_Date__c,
                                SF_User__c = empl.SF_User__c, Signature_on_File__c = empl.Signature_on_File__c, Signed_Travel_Waiver__c = empl.Signed_Travel_Waiver__c, SI_Type__c = empl.SI_Type__c, Skype_ID__c = empl.Skype_ID__c,
                                Special_Skills__c = empl.Special_Skills__c, SSN_PAN_ID_Number__c = empl.SSN_PAN_ID_Number__c, State_Tax_Withholding__c = empl.State_Tax_Withholding__c, Stock_Options__c = empl.Stock_Options__c,
                                Stock_Value_Day_1__c = empl.Stock_Value_Day_1__c, Supervisor_Emp_ID__c = empl.Supervisor_Emp_ID__c, Swift_Code_IFSC_Code__c = empl.Swift_Code_IFSC_Code__c, Tax_Address_City__c = empl.Tax_Address_City__c,
                                Tax_Address_Country__c = empl.Tax_Address_Country__c, Tax_Address_State__c = empl.Tax_Address_State__c, Tax_Address_Street__c = empl.Tax_Address_Street__c, Tax_Address_Zip_Postal_Code__c = empl.Tax_Address_Zip_Postal_Code__c,
                                Tax_Number__c = empl.Tax_Number__c, Tech__c = empl.Tech__c, TEMP_Annual_Local_Salary__c = empl.TEMP_Annual_Local_Salary__c, TEMP_Pay_Rate_Per_Pay_Period__c = empl.TEMP_Pay_Rate_Per_Pay_Period__c,
                                Termination_Date__c = empl.Termination_Date__c, Title__c = empl.Title__c, Total_Business_Unit_Time_Split__c = empl.Total_Business_Unit_Time_Split__c, Total_Department_Time_Split__c = empl.Total_Department_Time_Split__c,
                                Total_Stock_Value__c = empl.Total_Stock_Value__c, X401K_Payroll_Deduction__c = empl.X401K_Payroll_Deduction__c, Unit__c = empl.Unit__c, Unloaded_Daily_Rate__c = empl.Unloaded_Daily_Rate__c,
                                USD_Currency_Per_Pay_period__c = empl.USD_Currency_Per_Pay_period__c, User_link__c = empl.User_link__c, User_ID__c = empl.User_ID__c, Vacation_Days__c = empl.Vacation_Days__c, Visa_Expiration_Date__c = empl.Visa_Expiration_Date__c,
                                VISA_No__c = empl.VISA_No__c, VISA_Type__c = empl.VISA_Type__c, Voter_ID__c = empl.Voter_ID__c, Yearly_Comp__c = empl.Yearly_Comp__c, Working_Days__c = empl.Working_Days__c,
                                Additional_Comments__c = empl.Additional_Comments__c, Blood_Group__c = empl.Blood_Group__c, Distinguishing_Features__c = empl.Distinguishing_Features__c, Emergency_Contact_Country_of_Residence__c = empl.Emergency_Contact_Country_of_Residence__c,
                                Emergency_Contact_next_of_kin__c = empl.Emergency_Contact_next_of_kin__c, Eye_Colour__c = empl.Eye_Colour__c, Height__c = empl.Height__c, Local_Emerg_Cont_Country_of_Residence__c = empl.Local_Emerg_Cont_Country_of_Residence__c,
                                Local_Emergency_Contact_next_of_kin__c = empl.Local_Emergency_Contact_next_of_kin__c, Medical_Conditions_Allergies__c = empl.Medical_Conditions_Allergies__c, Medical_Permission__c = empl.Medical_Permission__c,
                                Red_Form_Filled_Date__c = empl.Red_Form_Filled_Date__c, Religion_Impact__c = empl.Religion_Impact__c, Regular_Medication__c = empl.Regular_Medication__c, New_Business__c = empl.New_Business__c,
                                BizOps__c = empl.BizOps__c, Sub_Department__c = empl.Sub_Department__c, Division__c = empl.Division__c, Sub_Division__c = empl.Sub_Division__c
                            ));
            }

            if (emplSnpList.size() > 0) {
                insert emplSnpList;
            }
        } catch (Exception ex) {
            if (!Test.isRunningTest()) {
                EmailHelper.sendEmailFromException(BatchDefaultSettings__c.getOrgDefaults().Error_Emails__c.split(','), 'Cannot create Employee Snapshot', 'Error : ', ex);
            }
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}