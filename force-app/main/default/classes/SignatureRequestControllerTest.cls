@isTest
public class SignatureRequestControllerTest {
    
    @testSetup
    static void setupTestData() {
        DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
            Region__c = 'US',
            Role__c = 'Manager',
            ContractType__c = 'Employment'
        );
        insert config;
    }
    
    @isTest
    static void testSignatureWorkflow() {
        Test.startTest();
        
        // Step 1: Initiate signature request
        String requestId = SignatureRequestController.initiateSignatureRequest(
            'doc123',
            'test@example.com',
            'Employment Contract'
        );
        System.assertNotEquals(null, requestId);
        
        // Step 2: Submit signature
        SignatureRequestController.submitSignature(
            requestId,
            'signature_data_base64',
            '{"signatureMethod":"draw","timestamp":"2024-01-01"}'
        );
        
        Test.stopTest();
        
        // Verify signature request status
        Signature_Request__c request = [
            SELECT Status__c, SignedDate__c 
            FROM Signature_Request__c 
            WHERE Id = :requestId
        ];
        System.assertEquals('Signed', request.Status__c);
        System.assertNotEquals(null, request.SignedDate__c);
        
        // Verify attestation created
        List<SignatureValidation__c> attestations = [
            SELECT ValidationStatus__c 
            FROM SignatureValidation__c 
            WHERE SignatureRequest__c = :requestId
        ];
        System.assertEquals(1, attestations.size());
        System.assertEquals('Valid', attestations[0].ValidationStatus__c);
    }
}



// version v4


// @isTest
// public class SignatureRequestControllerTest {
    
//     @testSetup
//     static void setupTestData() {
//         DocumentLifecycleConfiguration__c doc = new DocumentLifecycleConfiguration__c(
//             Region__c = 'US',
//             Role__c = 'Manager',
//             ContractType__c = 'Employment',
//             ComplianceStatus__c = 'Compliant'
//         );
//         insert doc;
//     }
    
//     @isTest
//     static void testInitiateSignatureRequest() {
//         DocumentLifecycleConfiguration__c doc = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
//         Test.startTest();
//         String requestId = SignatureRequestController.initiateSignatureRequest(
//             doc.Id, 
//             'test@example.com', 
//             'Test Signer'
//         );
//         Test.stopTest();
        
//         System.assertNotEquals(null, requestId, 'Should return request ID');
        
//         // Verify signature request created
//         Signature_Request__c request = [SELECT Id, Status__c FROM Signature_Request__c WHERE Id = :requestId];
//         System.assertEquals('Draft', request.Status__c, 'Initial status should be Draft');
        
//         // Verify audit trail
//         List<AuditTrail__c> audits = [SELECT Id FROM AuditTrail__c WHERE EventType__c = 'Signature Activity'];
//         System.assertEquals(1, audits.size(), 'Should create audit trail');
//     }
    
//     @isTest
//     static void testSubmitSignature() {
//         DocumentLifecycleConfiguration__c doc = [SELECT Id FROM DocumentLifecycleConfiguration__c LIMIT 1];
        
//         Signature_Request__c request = new Signature_Request__c(
//             DocumentId__c = doc.Id,
//             SignerEmail__c = 'test@example.com',
//             Status__c = 'Draft'
//         );
//         insert request;
        
//         Test.startTest();
//         Boolean result = SignatureRequestController.submitSignature(
//             request.Id,
//             'base64_signature_data_here',
//             'Signer Info: John Doe, IP: 192.168.1.1'
//         );
//         Test.stopTest();
        
//         System.assertEquals(true, result, 'Signature submission should succeed');
        
//         // Verify request updated
//         Signature_Request__c updatedRequest = [SELECT Status__c FROM Signature_Request__c WHERE Id = :request.Id];
//         System.assertEquals('Signed', updatedRequest.Status__c, 'Status should be updated to Signed');
        
//         // Verify validation record created
//         List<SignatureValidation__c> validations = [SELECT Id FROM SignatureValidation__c WHERE SignatureRequestId__c = :request.Id];
//         System.assertEquals(1, validations.size(), 'Should create signature validation record');
//     }
// }


// version v6


// @isTest
// public class SignatureRequestControllerTest {
    
//     @TestSetup
//     static void setupTestData() {
//         // Create test data
//         Signature_Request__c testRequest = new Signature_Request__c();
//         testRequest.Document_ID__c = 'TEST_DOC_001';
//         testRequest.Signer_Email__c = 'test@example.com';
//         testRequest.Signer_Name__c = 'Test Signer';
//         testRequest.Status__c = 'Initiated';
//         testRequest.Request_Date__c = System.now();
//         testRequest.Expiration_Date__c = System.now().addDays(30);
        
//         insert testRequest;
//     }
    
//     @isTest
//     static void testInitiateSignatureRequest() {
//         Test.startTest();
        
//         String requestId = SignatureRequestController.initiateSignatureRequest(
//             'TEST_DOC_002', 
//             'newtest@example.com', 
//             'New Test Signer'
//         );
        
//         Test.stopTest();
        
//                 // Verify request was created
//         Signature_Request__c request = [
//             SELECT Id, Document_ID__c, Signer_Email__c, Status__c
//             FROM Signature_Request__c 
//             WHERE Id = :requestId
//         ];
        
//         System.assertNotEquals(null, request, 'Request should be created');
//         System.assertEquals('TEST_DOC_002', request.Document_ID__c, 'Document ID should match');
//         System.assertEquals('newtest@example.com', request.Signer_Email__c, 'Email should match');
//         System.assertEquals('Initiated', request.Status__c, 'Status should be Initiated');
        
//         // Verify audit trail was created
//         List<AuditTrail__c> audits = [
//             SELECT Id, Action__c 
//             FROM AuditTrail__c 
//             WHERE Signature_Request__c = :requestId
//         ];
//         System.assertEquals(1, audits.size(), 'Should create audit trail');
//         System.assertEquals('INITIATED', audits[0].Action__c, 'Action should be INITIATED');
//     }
    
//     @isTest
//     static void testSubmitSignature() {
//         Signature_Request__c testRequest = [
//             SELECT Id FROM Signature_Request__c 
//             WHERE Signer_Email__c = 'test@example.com' 
//             LIMIT 1
//         ];
        
//         String signatureData = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
//         String signerInfo = '{"name":"Test Signer","email":"test@example.com","date":"2024-01-01"}';
        
//         Test.startTest();
//         Boolean result = SignatureRequestController.submitSignature(
//             testRequest.Id,
//             signatureData,
//             signerInfo
//         );
//         Test.stopTest();
        
//         // Verify signature was submitted successfully
//         System.assertEquals(true, result, 'Signature submission should succeed');
        
//         // Verify request status updated
//         Signature_Request__c updatedRequest = [
//             SELECT Id, Status__c, Completion_Date__c 
//             FROM Signature_Request__c 
//             WHERE Id = :testRequest.Id
//         ];
//         System.assertEquals('Completed', updatedRequest.Status__c, 'Status should be updated to Completed');
//         System.assertNotEquals(null, updatedRequest.Completion_Date__c, 'Completion date should be set');
        
//         // Verify signature validation record created
//         List<SignatureValidation__c> validations = [
//             SELECT Id, Status__c 
//             FROM SignatureValidation__c 
//             WHERE Signature_Request__c = :testRequest.Id
//         ];
//         System.assertEquals(1, validations.size(), 'Should create signature validation');
//         System.assertEquals('Valid', validations[0].Status__c, 'Validation status should be Valid');
//     }
    
//     @isTest
//     static void testSubmitSignatureExpiredRequest() {
//         Signature_Request__c testRequest = [
//             SELECT Id FROM Signature_Request__c 
//             WHERE Signer_Email__c = 'test@example.com' 
//             LIMIT 1
//         ];
        
//         // Set expiration date in the past
//         testRequest.Expiration_Date__c = System.now().addDays(-1);
//         update testRequest;
        
//         String signatureData = 'test-signature-data';
//         String signerInfo = '{"name":"Test Signer"}';
        
//         Test.startTest();
//         try {
//             SignatureRequestController.submitSignature(
//                 testRequest.Id,
//                 signatureData,
//                 signerInfo
//             );
//             System.assert(false, 'Should throw exception for expired request');
//         } catch (AuraHandledException e) {
//             System.assert(e.getMessage().contains('expired'), 'Should indicate request has expired');
//         }
//         Test.stopTest();
//     }
    
//     @isTest
//     static void testResetSignatureRequest() {
//         Signature_Request__c testRequest = [
//             SELECT Id FROM Signature_Request__c 
//             WHERE Signer_Email__c = 'test@example.com' 
//             LIMIT 1
//         ];
        
//         // Create a validation record to simulate previous signature attempt
//         SignatureValidation__c validation = new SignatureValidation__c();
//         validation.Signature_Request__c = testRequest.Id;
//         validation.Signature_Data__c = 'test-data';
//         validation.Status__c = 'Valid';
//         insert validation;
        
//         Test.startTest();
//         SignatureRequestController.resetSignatureRequest(testRequest.Id);
//         Test.stopTest();
        
//         // Verify request was reset
//         Signature_Request__c resetRequest = [
//             SELECT Id, Status__c, Completion_Date__c 
//             FROM Signature_Request__c 
//             WHERE Id = :testRequest.Id
//         ];
//         System.assertEquals('Initiated', resetRequest.Status__c, 'Status should be reset to Initiated');
//         System.assertEquals(null, resetRequest.Completion_Date__c, 'Completion date should be null');
        
//         // Verify validation records were deleted
//         List<SignatureValidation__c> validations = [
//             SELECT Id FROM SignatureValidation__c 
//             WHERE Signature_Request__c = :testRequest.Id
//         ];
//         System.assertEquals(0, validations.size(), 'Validation records should be deleted');
//     }
    
//     @isTest
//     static void testGetSignatureRequests() {
//         Test.startTest();
//         List<Signature_Request__c> allRequests = SignatureRequestController.getSignatureRequests('All');
//         List<Signature_Request__c> initiatedRequests = SignatureRequestController.getSignatureRequests('Initiated');
//         Test.stopTest();
        
//         System.assertNotEquals(0, allRequests.size(), 'Should return all requests');
//         System.assertEquals(1, initiatedRequests.size(), 'Should return only initiated requests');
//         System.assertEquals('Initiated', initiatedRequests[0].Status__c, 'Status should be Initiated');
//     }
    
//     @isTest
//     static void testExtendExpirationDate() {
//         Signature_Request__c testRequest = [
//             SELECT Id, Expiration_Date__c 
//             FROM Signature_Request__c 
//             WHERE Signer_Email__c = 'test@example.com' 
//             LIMIT 1
//         ];
        
//         DateTime originalExpiration = testRequest.Expiration_Date__c;
        
//         Test.startTest();
//         SignatureRequestController.extendExpirationDate(testRequest.Id, 7);
//         Test.stopTest();
        
//         // Verify expiration date was extended
//         Signature_Request__c updatedRequest = [
//             SELECT Id, Expiration_Date__c 
//             FROM Signature_Request__c 
//             WHERE Id = :testRequest.Id
//         ];
        
//         System.assertEquals(
//             originalExpiration.addDays(7), 
//             updatedRequest.Expiration_Date__c, 
//             'Expiration should be extended by 7 days'
//         );
        
//         // Verify audit trail was created
//         List<AuditTrail__c> audits = [
//             SELECT Id, Action__c 
//             FROM AuditTrail__c 
//             WHERE Signature_Request__c = :testRequest.Id AND Action__c = 'EXTENDED'
//         ];
//         System.assertEquals(1, audits.size(), 'Should create audit trail for extension');
//     }
// }



