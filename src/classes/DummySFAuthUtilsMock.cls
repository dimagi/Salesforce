public class DummySFAuthUtilsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            if (req.getEndpoint().contains('token')) {
                res.setBody('{"access_token":"mockAccessToken","refresh_token":"mockRefreshToken"}');
            } else {
                res.setBody('"mockuser@domain.com"');
            }
            return res;
        }
}