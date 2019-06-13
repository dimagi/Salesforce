public with sharing class ProjectCountrySubSector {

    public static void updateCountrySubSector(Country__c country) {
        Set<Id> deletedProjects = new Set<Id>();
        updateCountrySubSector(country, deletedProjects);
    }

    public static void updateCountrySubSector(Country__c country, Set<Id> deletedProjects) {
        String newSubSectorsString;
        String newSectorsString;
        Set<String> newSubSectorsSet = new Set<String>();
        Set<String> newSectorsSet = new Set<String>();
        Country__c currentCountry = country;
        Set<Id> deletedProjectIds = deletedProjects;

        // Loop through each deployment and add each deployments subsectors to the Set
        for (ProjectCountry__c pc : [SELECT Project__c, Project__r.Sub_Area__c, Project__r.Area__c
                                     FROM ProjectCountry__c
                                     WHERE Country__r.Id = :currentCountry.Id
                                     AND Project__r.Id NOT IN: deletedProjectIds
                                     AND Project__r.Id != null]) {
            // Add each deployment's sub sector to the full set of subsectors
            if (pc.Project__r.Sub_Area__c != null) {
                newSubSectorsSet.addAll(pc.Project__r.Sub_Area__c.split(';'));
            }
            if (pc.Project__r.Area__c != null) {
                newSectorsSet.addAll(pc.Project__r.Area__c.split(';'));
            }
        }

         // Turn the new Sets set into strings
         currentCountry.Sub_Area__c = toString(newSubSectorsSet);
         currentCountry.Area__c = toString(newSectorsSet);
         update currentCountry;
        }

    // Gets all country Ids of Countries attached to a Deployment
    public static Set<Country__c> getCountries(Set<Id> projectId) {
        Set<ID> pIds = projectId;
        Set<Country__c> countries = new Set<Country__c>([SELECT Id FROM Country__c WHERE Id IN
                                                            (SELECT Country__c FROM ProjectCountry__c WHERE Project__r.Id IN: pIds)]);
        return countries;
    }

    public static String toString(Set<String> inputSet) {
        String result = '';
        for (String s : inputSet) {
             result += s +'; ';
        }
        if(String.isEmpty(result)) {
            result = '';
        }
        return result.replace('null', '').removeEnd('; ');
    }

    public static testMethod void unitTest() {

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