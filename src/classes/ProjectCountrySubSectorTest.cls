@istest
public class ProjectCountrySubSectorTest {
@istest
 public static void unitTest() {

        Account account = new Account(Name='test');
        insert account;
        Project__c project = new Project__c(Name = 'Testing', Implementing_Account__c = account.Id);
        insert project;
        Country__c country = new Country__c(Name = 'Testing Country');
        insert country;
        ProjectCountry__c pc = new ProjectCountry__c(Country__c = country.Id, Project__c = project.Id);
        insert pc;

        project.Sub_Area__c = 'Agriculture;Health';
        update project;
    }
}