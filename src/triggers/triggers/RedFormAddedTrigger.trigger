trigger RedFormAddedTrigger on Record_of_Emergency_Data_Form__c (after insert) {
    List<Record_of_Emergency_Data_Form__c> redFormsToDel = new List<Record_of_Emergency_Data_Form__c>();
    List<SFDC_Employee__c> employeesToUpdate = new List<SFDC_Employee__c>();
    for (Record_of_Emergency_Data_Form__c newRedForm : Trigger.new) {
        List<SFDC_Employee__c> employees = [SELECT Id, Employee_First_Name__c, Employee_Last_Name__c, Employee_Middle_Name__c,
                                            DOB__c, Citizenship__c, Gender__c, Personal_Phone_Number__c,
                                            Passport_No__c, Passport_Expiration_Date__c, Current_Address_City__c,
                                            Current_Address_Street__c, Current_Address_State__c, Current_Address_Country__c,
                                            EMERGENCY_CONTACT__c, Emergency_Contact_Phone__c, Emergency_Contact_Country_of_Residence__c,
                                            Emergency_Email__c, Emergency_Contact_Relationship__c, Emergency_Contact_next_of_kin__c,
                                            Local_Emerg_Cont_Country_of_Residence__c, Local_Emergency_Contact_next_of_kin__c,
                                            LOCAL_EMERGENCY_CONTACT__c, Local_Emergency_Contact_Relationship__c, Local_Emergency_Contact_Phone__c,
                                            Local_Emergency_Contact_Email__c, Red_Form_Filled_Date__c, Height__c, Eye_Colour__c, Blood_Group__c,
                                            Religion_Impact__c, Distinguishing_Features__c, Medical_Conditions_Allergies__c,
                                            Regular_Medication__c, Medical_Permission__c, Additional_Comments__c
                                            FROM SFDC_Employee__c WHERE Id =: newRedForm.Employee__c];

        if (employees.size() > 0) {
            SFDC_Employee__c emplToUpdate = employees.get(0);

            emplToUpdate.Red_Form_Filled_Date__c = newRedForm.Filled_Date__c;

            // Personal Details
            emplToUpdate.Employee_First_Name__c = newRedForm.Employee_First_Name__c;
            emplToUpdate.Employee_Last_Name__c = newRedForm.Employee_Last_Name__c;
            emplToUpdate.Employee_Middle_Name__c = newRedForm.Employee_Middle_Name__c;
            emplToUpdate.DOB__c = newRedForm.DOB__c;
            emplToUpdate.Citizenship__c = newRedForm.Citizenship__c;
            emplToUpdate.Gender__c = newRedForm.Gender__c;
            emplToUpdate.Personal_Phone_Number__c = newRedForm.Personal_Phone_Number__c;
            emplToUpdate.Passport_No__c = newRedForm.Passport_No__c;
            emplToUpdate.Passport_Expiration_Date__c = newRedForm.Passport_Expiration_Date__c;
            emplToUpdate.Current_Address_City__c = newRedForm.Current_Address_City__c;
            emplToUpdate.Current_Address_Street__c = newRedForm.Current_Address_Street__c;
            emplToUpdate.Current_Address_State__c = newRedForm.Current_Address_State__c;
            emplToUpdate.Current_Address_Country__c = newRedForm.Current_Address_Country__c;

            // Emergency Contact
            emplToUpdate.EMERGENCY_CONTACT__c = newRedForm.Emergency_Contact__c;
            emplToUpdate.Emergency_Contact_Relationship__c = newRedForm.Emergency_Contact_Relationship__c;
            emplToUpdate.Emergency_Contact_Phone__c = newRedForm.Emergency_Contact_Phone__c;
            emplToUpdate.Emergency_Email__c = newRedForm.Emergency_Email__c;
            emplToUpdate.Emergency_Contact_Country_of_Residence__c = newRedForm.Emergency_Contact_Country_of_Residence__c;
            emplToUpdate.Emergency_Contact_next_of_kin__c = newRedForm.Emergency_Contact_next_of_kin__c;

            // Local Emergency Contact
            emplToUpdate.LOCAL_EMERGENCY_CONTACT__c = newRedForm.Local_Emergency_Contact__c;
            emplToUpdate.Local_Emergency_Contact_Relationship__c = newRedForm.Local_Emergency_Contact_Relationship__c;
            emplToUpdate.Local_Emergency_Contact_Phone__c = newRedForm.Local_Emergency_Contact_Phone__c;
            emplToUpdate.Local_Emergency_Contact_Email__c = newRedForm.Local_Emergency_Email__c;
            emplToUpdate.Local_Emerg_Cont_Country_of_Residence__c = newRedForm.Local_Emerg_Cont_Country_of_Residence__c;
            emplToUpdate.Local_Emergency_Contact_next_of_kin__c = newRedForm.Local_Emergency_Contact_next_of_kin__c;

            // Voluntary Information
            emplToUpdate.Height__c = newRedForm.Height__c;
            emplToUpdate.Eye_Colour__c = newRedForm.Eye_Colour__c;
            emplToUpdate.Blood_Group__c = newRedForm.Blood_Group__c;
            emplToUpdate.Religion_Impact__c = newRedForm.Religion_Impact__c;
            emplToUpdate.Distinguishing_Features__c = newRedForm.Distinguishing_Features__c;
            emplToUpdate.Medical_Conditions_Allergies__c = newRedForm.Medical_Conditions_Allergies__c;
            emplToUpdate.Regular_Medication__c = newRedForm.Regular_Medication__c;
            emplToUpdate.Medical_Permission__c = newRedForm.Medical_Permission__c;
            emplToUpdate.Additional_Comments__c = newRedForm.Additional_Comments__c;

            employeesToUpdate.add(emplToUpdate);
            redFormsToDel.add(newRedForm);
        }
    }

    if (employeesToUpdate.size() > 0) {
        update employeesToUpdate;
    }
}