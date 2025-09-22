@isTest
public class SignaturePadTest {

    @testSetup
    static void setupTestData() {
        // Create test signature request
        Signature_Request__c request = new Signature_Request__c(
            DocumentId__c     = 'test_doc_123',
            SignerEmail__c    = 'test@example.com',
            DocumentTitle__c  = 'Test Document',
            Status__c         = 'Pending',
            RequestedDate__c  = System.now()
        );
        insert request;
    }

    @isTest
    static void testSignaturePadIntegration() {
        // Get test request
        Signature_Request__c request = [
            SELECT Id
            FROM Signature_Request__c
            LIMIT 1
        ];

        Test.startTest();
        // Test signature submission
        SignatureRequestController.submitSignature(
            request.Id,
            'data:image/png;base64,test_signature_data',
            '{"signatureMethod":"draw","signerName":"Test User","signerEmail":"test@example.com"}'
        );
        Test.stopTest();

        // Verify signature was processed
        Signature_Request__c updatedRequest = [
            SELECT Status__c, SignedDate__c, SignatureData__c
            FROM Signature_Request__c
            WHERE Id = :request.Id
        ];

        System.assertEquals('Signed', updatedRequest.Status__c);
        System.assertNotEquals(null, updatedRequest.SignedDate__c);
        System.assertNotEquals(null, updatedRequest.SignatureData__c);
    }
}
