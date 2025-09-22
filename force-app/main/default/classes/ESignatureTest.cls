
// version v0 


// @isTest
// public class ESignatureTest {
    
//     @testSetup
//     static void setupTestData() {
//         // Create test document
//         Document__c testDoc = new Document__c(
//             Name = 'Test Contract',
//             Status__c = 'Active'
//         );
// insert testDoc;
//     // Create test signer
//     Signer__c testSigner = new Signer__c(
//         Name = 'John Doe',
//         Email__c = 'john.doe@example.com',
//         Status__c = 'Active'
//     );
//     insert testSigner;
// }

// @isTest
// static void testSignatureRequestInitiation() {
//     Document__c testDoc = [SELECT Id FROM Document__c LIMIT 1];
    
//     Test.startTest();
//     String requestId = SignatureRequestController.initiateSignatureRequest(
//         testDoc.Id, 
//         'test.signer@example.com', 
//         'Test Signer'
//     );
//     Test.stopTest();
    
//     // Verify signature request was created
//     System.assertNotEquals(null, requestId);
    
//     Signature_Request__c sigRequest = [SELECT Id, Status__c, Document__c FROM Signature_Request__c WHERE Id = :requestId];
//     System.assertEquals('Initiated', sigRequest.Status__c);
//     System.assertEquals(testDoc.Id, sigRequest.Document__c);
    
//     // Verify audit log was created
//     List<Audit_Log__c> audits = [SELECT Id FROM Audit_Log__c WHERE Record_Id__c = :requestId];
//     System.assertEquals(1, audits.size());
// }

// @isTest
// static void testSignatureSubmission() {
//     Document__c testDoc = [SELECT Id FROM Document__c LIMIT 1];
//     String requestId = SignatureRequestController.initiateSignatureRequest(
//         testDoc.Id, 
//         'test.signer@example.com', 
//         'Test Signer'
//     );
    
//     Test.startTest();
//     Boolean result = SignatureRequestController.submitSignature(
//         requestId, 
//         'base64SignatureData', 
//         'Draw/Ink'
//     );
//     Test.stopTest();
    
//     System.assertEquals(true, result);
    
//     // Verify signature request status updated
//     Signature_Request__c sigRequest = [SELECT Status__c FROM Signature_Request__c WHERE Id = :requestId];
//     System.assertEquals('Completed', sigRequest.Status__c);
    
//     // Verify signature attestation was created
//     List<Signature_Attestation__c> attestations = [SELECT Id FROM Signature_Attestation__c WHERE Signature_Request__c = :requestId];
//     System.assertEquals(1, attestations.size());
// }

// @isTest
// static void testGetSignatureRequest() {
//     Document__c testDoc = [SELECT Id FROM Document__c LIMIT 1];
//     String requestId = SignatureRequestController.initiateSignatureRequest(
//         testDoc.Id, 
//         'test.signer@example.com', 
//         'Test Signer'
//     );
    
//     Test.startTest();
//     Map<String, Object> result = SignatureRequestController.getSignatureRequest(requestId);
//     Test.stopTest();
    
//     System.assertEquals(requestId, result.get('requestId'));
//     System.assertEquals('Initiated', result.get('status'));
//     System.assertEquals('Test Signer', result.get('signerName'));
// }
// }


//version  v1

@isTest
public class ESignatureTest {
    
    @testSetup
    static void setupTestData() {
        // Create test document
        Document__c testDoc = new Document__c(
            Name = 'Test Contract',
            Status__c = 'Active'
        );
insert testDoc;
    // Create test signer
    Signer__c testSigner = new Signer__c(
        Name = 'John Doe',
        Email__c = 'john.doe@example.com',
        Status__c = 'Active'
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
        'Test Signer'
    );
    Test.stopTest();
    
    // Verify signature request was created
    System.assertNotEquals(null, requestId);
    
    Signature_Request__c sigRequest = [SELECT Id, Status__c, Document__c FROM Signature_Request__c WHERE Id = :requestId];
    System.assertEquals('Initiated', sigRequest.Status__c);
    System.assertEquals(testDoc.Id, sigRequest.Document__c);
    
    // Verify audit log was created
    List<Audit_Log__c> audits = [SELECT Id FROM Audit_Log__c WHERE Record_Id__c = :requestId];
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
        'base64SignatureData', 
        'Draw/Ink'
    );
    Test.stopTest();
    
    System.assertEquals(true, result);
    
    // Verify signature request status updated
    Signature_Request__c sigRequest = [SELECT Status__c FROM Signature_Request__c WHERE Id = :requestId];
    System.assertEquals('Completed', sigRequest.Status__c);
    
    // Verify signature attestation was created
    List<Signature_Attestation__c> attestations = [SELECT Id FROM Signature_Attestation__c WHERE Signature_Request__c = :requestId];
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
    Map<String, Object> result = SignatureRequestController.getSignatureRequest(requestId);
    Test.stopTest();
    
    System.assertEquals(requestId, result.get('requestId'));
    System.assertEquals('Initiated', result.get('status'));
    System.assertEquals('Test Signer', result.get('signerName'));
}
}
