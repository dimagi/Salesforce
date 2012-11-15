/**
 * Client for the FogBugzAPI
 *
 * @author  Antonio Grassi
 * @date    11/13/2012
 */
public with sharing class FogBugzAPI {
	
	private static final String    FB_API_URL          = 'https://manage.dimagi.com/api.asp?';
	private static final String    FB_TOKEN            = 'p0dcc843cnbkhart9mroa53qjlkb58';
    private static final String    FB_CASE_COLS        = 'sTitle,sArea,sPersonAssignedTo,sVersion,dtLastUpdated,tags'; 

    public Map<String, FogBugzCase> getCases() {

        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(FB_API_URL + '&token=' + FB_TOKEN + '&cmd=search&cols=' + FB_CASE_COLS);
        req.setMethod('GET');
        
        HTTP connection = new HTTP();

        HTTPResponse res = connection.send(req);
        
        if (res.getBody() != null) {
        	return parseCases(res.getBody());
        }
        else {
        	System.debug(LoggingLevel.ERROR, 'FogBugzAPI::getCases() - Error while retrieving cases');
        	return new Map<String, FogBugzCase>();
        }
    }
    
	public String setCurrentFilter(Integer filterId) {
		HTTPRequest req = new HTTPRequest();
        req.setEndpoint(FB_API_URL + 'token=' + FB_TOKEN + '&cmd=setCurrentFilter&sFilter=' + filterId.format());
        req.setMethod('GET');
        
        HTTP connection = new HTTP();
        
        return connection.send(req).getBody();
	}
	
	public String createCase(FogBugzCase fbCase) {
		
		Map<String, String> params = new Map<String, String> {
			'cmd' => 'new',
			'sTitle' => fbCase.title,
			'sVersion' => fbCase.externalBugID,
			'sProject' => fbCase.project,
			'sArea' => fbCase.area,
			'sPersonAssignedTo' => fbCase.assignedTo,
			'sStatus' => fbCase.status,
			'ixPriority' => fbCase.priority.format()
		};
		
		HTTPRequest req = new HttpRequest();
		req.setEndpoint(FB_API_URL + 'token=' + FB_TOKEN + '&' + encodeParameters(params));
		req.setMethod('GET');
		
		HTTP connection = new HTTP();
		HTTPResponse res = connection.send(req);
		
		fbCase.caseId = parseUpsertId(res.getBody());
		return fbCase.caseId;
	}
	
	public String updateCase(FogBugzCase fbCase) {
        Map<String, String> params = new Map<String, String> {
            'cmd' => 'edit',
            'ixBug' => fbCase.caseId,
            'sVersion' => fbCase.externalBugID
        };
        
        HTTPRequest req = new HttpRequest();
        req.setEndpoint(FB_API_URL + 'token=' + FB_TOKEN + '&' + encodeParameters(params));
        req.setMethod('GET');
        
        HTTP connection = new HTTP();
        HTTPResponse res = connection.send(req);
        
        return parseUpsertId(res.getBody());		
	}

    /**
     * Encodes request parameters to be passed on GET URL or POST body
     */	
    private String encodeParameters(Map<String, String> parameters) {
        
        String res = '';
        
        for (String name:parameters.keySet()) {
            res += (res == '' ? '' : '&') + name + '=' + EncodingUtil.urlEncode(parameters.get(name), 'UTF-8');
        }
        
        return res;
    }

	/**
	 * XML Parsing
	 */
	private String parseUpsertId(String xmlString) {
		
		String res = null;
		
		XMLDom dom = new XMLDom(xmlString);
        XMLDom.Element responseNode = dom.root.getElementByTagName('response');
        
        if (responseNode != null) {
        	XMLDom.Element caseNode = responseNode.getElementByTagName('case');
        	
        	if (caseNode != null) {
        		res = caseNode.getAttribute('ixBug');
        	}
        }
        
        return res;
	}
	
	public Map<String, FogBugzCase> parseCases(String xmlString) {
		
		XMLDom dom = new XMLDom(xmlString);
		XMLDom.Element casesNode = dom.root.getElementByTagName('cases');
		
		Map<String, FogBugzCase> cases = new Map<String, FogBugzCase>();
		
		for (XMLDom.Element caseNode:casesNode.childNodes) {
			FogBugzCase fbCase = parseCase(caseNode);
			cases.put(fbCase.caseId, fbCase);
		}

		return cases;
	}
	
		
	public FogBugzCase parseCase(XMLDom.Element caseNode) {
		
		FogBugzCase fbCase = new FogBugzCase();
		
		fbCase.title = caseNode.getElementByTagName('sTitle').nodeValue;
		fbCase.area = caseNode.getElementByTagName('sArea').nodeValue;
		fbCase.assignedTo = caseNode.getElementByTagName('sPersonAssignedTo').nodeValue;
		fbCase.externalBugID = caseNode.getElementByTagName('sVersion').nodeValue;
		fbCase.caseId = caseNode.getAttribute('ixBug');
		
		String dtLastUpdatedValue = caseNode.getElementByTagName('dtLastUpdated').nodeValue;
		
		if (dtLastUpdatedValue != null && dtLastUpdatedValue.length() > 0) {
            fbCase.lastModifiedDate = FogBugzUtils.parseRFC822UTCTime(dtLastUpdatedValue);
		}
		
		// Search for deal size & probability
		for (XMLDom.Element node:caseNode.getElementsByTagName('tag')) {
			
			String value = node.nodeValue;
			Integer slashLoc = value.indexOf('/');
			
			if (slashLoc != -1) {
				
				try	{
					fbCase.dealSize = Integer.valueOf(value.substring(1, slashLoc));
					fbCase.probability = Decimal.valueOf(value.substring(slashLoc + 1, value.length() - 1));
				}
				catch (Exception e) {
  					system.debug(LoggingLevel.ERROR, 'ERROR - FogBugzAPI::parseCase() - ' + e.getMessage());  
				}
			}
		}	
		
		return fbCase;
	}
}