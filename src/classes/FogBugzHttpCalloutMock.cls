/**
 * Mock for testing callouts for FogBugzAPI
 */
public class FogBugzHttpCalloutMock implements HttpCalloutMock {

    private String customListCases;
    private Boolean returnBlankString;

    public final static String TEST_FB_ID = 'testFBId';
    public final static String EMPTY_ID = 'emptyFBId';
    public final static String TEST_SF_ID = 'testSFId';
    public static final String RESPONSE_TAGS = '<?xml version="1.0" encoding="UTF-8"?><response><cases count="1">' +
                                                 '<case ixBug="testFBId" operations="edit,assign,resolve,email,remind">' +
                                                 '<tags><tag><![CDATA[[0/20]]]></tag><tag><![CDATA[Test]]></tag><tag><![CDATA[CommCare]]></tag></case>' +
                                                 '</cases></response>';
    public static final String RESPONSE_UPDATE = '<?xml version="1.0" encoding="UTF-8"?><response>' +
                                                 '<case ixBug="testFBId" operations="edit,assign,resolve,email,remind">' +
                                                 '</case></response>';
    public static final String RESPONSE_SEARCH = '<?xml version="1.0" encoding="UTF-8"?><response><cases count="1">' +
                                                 '<case ixBug="testFBId"><ixBug>testFBId</ixBug><sTitle>Test title</sTitle><sArea>Test area</sArea><sPersonAssignedTo>Test assignee</sPersonAssignedTo><sVersion>1</sVersion><ixPersonOpenedBy>salesforce</ixPersonOpenedBy><dtLastUpdated>2012-1-1T00:00:00Z</dtLastUpdated><hrsElapsed>41.7327995300293</hrsElapsed>' +
                                                 '<event><s>event</s></event></case></cases></response>';
    public static final String RESPONSE_LIST_CASES = '<?xml version="1.0" encoding="UTF-8"?><response><cases count="2">' +
                                                     '<case ixBug="testFBId"><ixBug>testFBId</ixBug><sTitle>Title</sTitle><sArea>area</sArea><sPersonAssignedTo>salesforce</sPersonAssignedTo><sVersion>1</sVersion><ixPersonOpenedBy>salesforce</ixPersonOpenedBy><dtLastUpdated>2007-05-06T22:47:59Z</dtLastUpdated></case>' +
                                                     '<case ixBug="testFBId2"><ixBug>testFBId2</ixBug><sTitle>Title</sTitle><sArea>area</sArea><sPersonAssignedTo>salesforce</sPersonAssignedTo><sVersion>1</sVersion><ixPersonOpenedBy>salesforce</ixPersonOpenedBy><dtLastUpdated></dtLastUpdated></case>' +
                                                     '</cases></response>';
    public static final String RESPONSE_LAST_UPDATED_CASES = '<?xml version="1.0" encoding="UTF-8"?><response><cases count="2">' +
                                                     '<case ixBug="11111"><ixBug>11111</ixBug><sTitle>Title 1</sTitle><sArea>area 1</sArea><sProject><![CDATA[Test 1]]></sProject><Client>111</Client></case>' +
                                                     '<case ixBug="22222"><ixBug>22222</ixBug><sTitle>Title 2</sTitle><sArea>area 2</sArea><sProject><![CDATA[Test 2]]></sProject><Client>222</Client></case>' +
                                                     '</cases></response>';
    public static final String RESPONSE_VIEW_PERSON = '<?xml version="1.0" encoding="UTF-8"?><response>' +
                                                      '<person><sEmail>salesforce</sEmail></person></response>';
    public static final String RESPONSE_FILTER = '<response></response>';

    public FogBugzHttpCalloutMock() {
        this(false);
    }

    public FogBugzHttpCalloutMock(Boolean returnBlankString) {
        this(returnBlankString, null);
    }

    public FogBugzHttpCalloutMock(Boolean returnBlankString, String customListCases) {
        this.returnBlankString = returnBlankString;
        this.customListCases = customListCases;
    }

    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(200);
        if (this.returnBlankString == true) {
            res.setBody('');
            return res;
        }
        String reqBody = req.getBody();

        String[] parameters = reqBody.split('&');
        Map<String, String> params = new Map<String, String>();

        for (String param : parameters) {
            String[] p = param.split('=');
            params.put(p[0],p[1]);
        }

        if (params.get('cmd') == 'search') {
            if (params.containsKey('q') && params.get('q').startsWith('edited')) {
                res.setBody(RESPONSE_LAST_UPDATED_CASES);
            } else if (params.containsKey('q')) {
                if (params.get('cols') == 'tags') {
                    res.setBody(RESPONSE_TAGS);
                } else {
                    res.setBody(RESPONSE_SEARCH);
                }
            } else {
                res.setBody(this.customListCases != null ? this.customListCases : RESPONSE_LIST_CASES); // enable custome return for some tests
            }
        } else if (params.get('cmd') == 'setCurrentFilter') {
            res.setBody(RESPONSE_FILTER);
        } else if ((params.get('cmd') == 'new') || (params.get('cmd') == 'resolve') || (params.get('cmd') == 'close') || (params.get('cmd') == 'edit') || (params.get('cmd') == 'reopen')) {
            res.setBody(RESPONSE_UPDATE);
        } else if (params.get('cmd') == 'viewPerson') {
            res.setBody(RESPONSE_VIEW_PERSON);
        }

        return res;
    }
}