@isTest
global class ClockifyNonUserMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
         String startRange =  String.valueOf(System.today()-1) + 'T17:00:00.000Z';
        String endRange =  String.valueOf(System.today()-1) + 'T18:00:00.000Z';
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        String responseBody = '{'+
            '"totals": ['+
            '{'+
            '"_id": "",'+
            ' "totalTime":'+ 0+','+
            '"totalBillableTime":'+ 0+','+
            '"entriesCount":'+ 1+','+
            '"totalAmount":'+ 0.0+
            '}'+
            ' ],'+
            ' "timeentries": ['+
            '{'+
            '"_id": "600d7f09843909186990142f",'+
            '"description": "",'+
            '"userId": "5fc91947b50fb95d5002cbad",'+
            '"billable": false,'+
            '"taskId": "600c396009c9406808cb77de",'+
            '"projectId": "600c396009c9406808cb77d0",'+
            '"timeInterval": {'+
            '"start": '+ JSON.serialize(startRange) +','+
            '"end": '+ JSON.serialize(endRange) +','+
            '"duration": '+5400+
            '},'+
            '"approvalRequestId":'+ null+','+
            '"taskName": "Onboarding/Offboarding",'+
            '"tags": ['+
            '{'+
            '"name": "Overhead",'+
            '"_id": "600c38be09c9406808cb74e6"'+
            '}'+
            '],'+
            '"isLocked":'+ false+','+
            '"customFields": [],'+
            '"amount":'+ 0.0+','+
            '"rate":'+ 0.0+','+
            '"userName": "Employee 1",'+
            '"userEmail": "employee123@dimagi.com",'+
            '"projectName": "People Operations",'+
            '"projectColor": "#9C27B0",'+
            '"clientName": ""'+
            '}'+
            ']'+
            '}';

        response.setBody(responseBody);
        response.setStatusCode(200);
        return response; 
    }
}