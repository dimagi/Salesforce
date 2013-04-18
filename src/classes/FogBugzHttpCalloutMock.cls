global class FogBugzHttpCalloutMock implements HttpCalloutMock {
    
    private String responseBody;
    public static final String RESPONSE_TAGS = '<?xml version="1.0" encoding="UTF-8"?><response><cases count="1">' +
                                                 '<case ixBug="testFBId" operations="edit,assign,resolve,email,remind">'+
                                                 '<tags><tag><![CDATA[[0/20]]]><tag><![CDATA[Test]]></tags></case>'+
                                                 '</cases></response>';
    public static final String RESPONSE_UPDATE = '<?xml version="1.0" encoding="UTF-8"?><response>' +
                                                 '<case ixBug="testFBId" operations="edit,assign,resolve,email,remind">'+
                                                 '</case></response>';
                                                 
    public static final String RESPONSE_SEARCH = '<?xml version="1.0" encoding="UTF-8"?><response><cases count="1">' +
                                                 '<case ixBug="testFBId"><ixBug>testFBId</ixBug><sTitle>Title</sTitle><sArea>area</sArea><sPersonAssignedTo>salesforce</sPersonAssignedTo><sVersion>1</sVersion><ixPersonOpenedBy>salesforce</ixPersonOpenedBy><dtLastUpdated></dtLastUpdated>'+
                                                 '</case></cases></response>';
    
    public FogBugzHttpCalloutMock() {
    	this.responseBody = RESPONSE_UPDATE;
    }
    
    public FogBugzHttpCalloutMock(String responseBody) {
    	this.responseBody = responseBody;
    }
    
    global HTTPResponse respond(HTTPRequest req) {
    	HTTPResponse res = new HTTPResponse();        
        res.setBody(responseBody);
        return res;
    }
}