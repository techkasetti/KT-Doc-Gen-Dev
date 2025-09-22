@isTest
public class ESignatureTest {
    
    @testSetup
    static void setupTestData() {
        // Create test document
        Document__c testDoc = new Document__c(
            Name = 'Test Document',
            DocumentType__c = 'Contract',
            Status__c = 'Draft'
        );
        insert testDoc;
        
        // Create test signer
        Signer__c testSigner = new Signer__c(
            Name = 'Test Signer',
            Email__c = 'test.signer@example.com',
            Phone__c = '+1234567890'
        );
        insert testSigner;
    }
    
    @isTest
    static void testSignatureRequestInitiation() {
        Document__c testDoc = [SELECT Id FROM Document__c LIMIT 1];
        
        Test.startTest();
        String requestId = SignatureRequestController.initiateSignatureRequest(
            testDoc.Id,
            'test.signer@example.com',
            'Test Contract Document'
        );
        Test.stopTest();
        
        // Verify signature request was created
        Signature_Request__c request = [SELECT Id, Status__c, DocumentId__c, SignerEmail__c 
                                      FROM Signature_Request__c WHERE Id = :requestId];
        System.assertEquals('Pending', request.Status__c);
        System.assertEquals('test.signer@example.com', request.SignerEmail__c);
        
        // Verify audit trail was created
        List<AuditTrail__c> audits = [SELECT Id, Action__c FROM AuditTrail__c];
        System.assertEquals(1, audits.size());
    }
    
    @isTest
    static void testSignatureSubmission() {
        Document__c testDoc = [SELECT Id FROM Document__c LIMIT 1];
        String requestId = SignatureRequestController.initiateSignatureRequest(
            testDoc.Id,
            'test.signer@example.com',
            'Test Signer'
        );
        
        Test.startTest();
        Boolean result = SignatureRequestController.submitSignature(
            requestId,
            'base64_signature_data_here',
            'Signer Info: John Doe, IP: 192.168.1.1'
        );
        Test.stopTest();
        
        // Verify signature was submitted
        Signature_Request__c request = [SELECT Status__c, SignatureData__c FROM Signature_Request__c WHERE Id = :requestId];
        System.assertEquals('Signed', request.Status__c);
        System.assertNotEquals(null, request.SignatureData__c);
        
        // Verify audit attestations were created
        List<AuditTrail__c> attestations = [SELECT Id FROM AuditTrail__c WHERE Action__c = 'Signature Submitted'];
        System.assertEquals(1, attestations.size());
    }
    
    @isTest
    static void testGetSignatureRequest() {
        Document__c testDoc = [SELECT Id FROM Document__c LIMIT 1];
        String requestId = SignatureRequestController.initiateSignatureRequest(
            testDoc.Id,
            'test.signer@example.com',
            'Test Signer'
        );
        
        Test.startTest();
        Signature_Request__c result = SignatureRequestController.getSignatureRequest(requestId);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('test.signer@example.com', result.SignerEmail__c);
        System.assertEquals('Pending', result.Status__c);
    }
}
