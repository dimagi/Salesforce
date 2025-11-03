@IsTest
private class OpenOpportunityFieldsUIControllerTest {

    @IsTest
    static void test_setStageContainer_populatesHtml() {
        Account a = new Account(Name = 'Test Acc');
        insert a;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            AccountId = a.Id,
            Opportunity_Owner_Division__c = 'Global Solutions',
            Opportunity_Owner_Sub_Division__c = 'GS - Leadership'
        );
        insert opp;

        String jsonString =
            '{"opportunities":[{' +
                '"attributes":{"type":"Opportunity"},' +
                '"Id":"' + opp.Id + '",' +
                '"Name":"' + String.escapeSingleQuotes(opp.Name) + '",' +
                '"StageName":"' + opp.StageName + '",' +
                '"CloseDate":"' + String.valueOf(opp.CloseDate) + '"' +
            '}]}';

        OpenOpportunityListData wrapper =
            (OpenOpportunityListData) JSON.deserialize(jsonString, OpenOpportunityListData.class);

        OpenOpportunityFieldsUIController controller = new OpenOpportunityFieldsUIController();
        controller.stageName = 'Prospecting';

        Test.startTest();
        controller.setStageContainer(wrapper);
        Test.stopTest();

        System.assertEquals(wrapper, controller.getStageContainer(),
            'Stage container should match the wrapper');
        System.assertNotEquals(null, controller.htmlTable,
            'HTML table should be populated');
        System.assertEquals(1, controller.getStageContainer().opportunities.size(),
            'Wrapper should contain our Opportunity');
    }
}