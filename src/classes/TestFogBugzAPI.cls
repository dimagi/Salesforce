/**
 * Tests for the FogBugzAPI class
 * TODO delete
 */

@isTest
public class TestFogBugzAPI {
    
    public final static String TEST_FB_ID = 'testFBId';
    
    public final static String TEST_SF_ID = 'testSFId';
    
    public final static String GET_CASES_RESPONSE = '<?xml version="1.0" encoding="UTF-8"?>' +
                                                    '<response>' +
                                                    '<cases count="1"><case ixBug="testFBId" operations="edit,assign,resolve,email,remind">' +
                                                    '<sTitle><![CDATA[Test title]]></sTitle>' +
                                                    '<sArea><![CDATA[Test area]]></sArea>' +
                                                    '<sPersonAssignedTo><![CDATA[Test assignee]]></sPersonAssignedTo>' +
                                                    '<sVersion><![CDATA[testSFId]]></sVersion>' +
                                                    '<dtLastUpdated>2012-1-1T00:00:00Z</dtLastUpdated>' +
                                                    '<tags><tag><![CDATA[[1/1]]]></tag></tags>' +
                                                    '<ixPersonOpenedBy>1</ixPersonOpenedBy>' +
                                                    '<hrsElapsed>41.7327995300293</hrsElapsed>' +
                                                    '</case></cases>' +
                                                    '</response>';

    public final static String SET_CURRENT_FILTER_RESPONSE = '<?xml version="1.0" encoding="UTF-8"?><response></response>';

    public final static String UPSERT_CASE_RESPONSE = '<?xml version="1.0" encoding="UTF-8"?><response>' +
                                                      '<case ixBug="testFBId" operations="edit,assign,resolve,email,remind"></response>';

}