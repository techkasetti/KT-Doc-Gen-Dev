@IsTest
private class SignatureRequestControllerTest {
    // Simple HttpCalloutMock
    private class MockSig implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"envelopeId":"env-123"}');
            return res;
        }
    }

    @IsTest static void testCreateSignatureRequest() {
        Test.setMock(HttpCalloutMock.class, new MockSig());
        Test.startTest();
        Id icId = SignatureRequestController.createSignatureRequest('doc-1','test@example.com');
        Test.stopTest();
        System.assertNotEquals(null, icId);
        Integration_Call__c ic = [SELECT Id, StatusCode__c, Response__c FROM Integration_Call__c WHERE Id = :icId LIMIT 1];
        System.assertEquals(201, ic.StatusCode__c);
    }
}
