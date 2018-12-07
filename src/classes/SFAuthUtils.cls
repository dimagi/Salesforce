public class SFAuthUtils {

    public static final String AUTH_URL = 'https://accounts.google.com/o/oauth2/auth';
    public static final String ACCESS_TOKEN_URL = 'https://accounts.google.com/o/oauth2/token';
    public static final String USER_INFO_URL = 'https://www.googleapis.com/oauth2/v1/userinfo';

    public static String getSignInUrl(PRO_OAuth_Settings__c settings, String callback) {
        return getSignInUrl(settings, callback, null);
    }

    public static String getSignInUrl(PRO_OAuth_Settings__c settings, String callback, String state) {
        String body = 'client_id=' + settings.ClientID__c + '&redirect_uri=' + callback + '&state=' + state;
        String retUrl = SFAuthUtils.AUTH_URL + '?' + body + '&response_type=code&scope=profile+email';
        if (settings.Domain_Name__c != 'gmail.com') {
            retUrl = retUrl + '&hd=' + settings.Domain_Name__c;
        }
        return retUrl;
    }

    public static String getAuthorizedReqToken(PRO_OAuth_Settings__c settings, String callback, String code) {
        String body = 'client_id=' + settings.ClientID__c + '&redirect_uri=' + EncodingUtil.urlEncode(callback, 'UTF-8') + '&client_secret=' +
                            settings.ClientSecret__c + '&code=' + code + '&grant_type=authorization_code';
        String tokenResponse = basicAuthCallout(SFAuthUtils.ACCESS_TOKEN_URL, '', body, 'POST');
        return tokenResponse;
    }

    public static String callForUserInfo(String token) {
        String userInfoURL = SFAuthUtils.USER_INFO_URL + '?access_token=' + token;
        String responseJSON = basicAuthCallout(userInfoURL, '', '', 'GET');
        String response = getFromJSON(responseJSON, 'email');
        return response;
    }

    public static String basicAuthCallout(String endPoint, String header, String body, String method) {
        HttpRequest req = new HttpRequest();

        req.setEndpoint(endPoint);
        req.setMethod(method);
        if (method == 'POST') {
            req.setBody(body);
        }
        Http http = new Http();

        HTTPResponse res = http.send(req);
        System.debug('Auth debug log  - ' + res.getBody() + ' code - ' + res.getStatusCode());
        if (res.getStatusCode() != 200) {
            throw new CalloutException('Incorrect data');
        }
        return res.getBody();
    }

    public static String getFromJSON(String response, String fieldName){
        JSONParser parser = JSON.createParser(response);
        String accessToken='';

        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                (parser.getText() == fieldName)) {
                parser.nextToken();
                accessToken = parser.getText();
            }
        }
        return accessToken;
    }

}