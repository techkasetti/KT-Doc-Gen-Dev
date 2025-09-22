@isTest
public class IntegratedDocGenSignatureTest {
    
    @TestSetup
    static void makeData() {
        // Create test data
        DocumentLifecycleConfiguration__c testDoc = new DocumentLifecycleConfiguration__c(
            Region__c = 'US',
            Role__c = 'Manager',
            ContractType__c = 'Employment',
            DocumentTitle__c = 'Test Integration Document',
            ProcessingStatus__c = 'Draft'
        );
        insert testDoc;
        
        Signature_Request__c testSigRequest = new Signature_Request__c(
            Document_Id__c = testDoc.Id,
            Signer_Email__c = 'test@example.com',
            Status__c = 'Pending',
            Expiration_Date__c = Date.today().addDays(30)
        );
        insert testSigRequest;
    }
    
    @isTest
    static void testCompleteWorkflowIntegration() {
        Test.startTest();
        
        // Test complete workflow
        Map<String, Object> result = DocGenESignIntegrationController.generateAndInitiateSignature(
            'US', 'Manager', 'Employment', 'Integration Test Document', 'test@example.com'
        );
        
        Test.stopTest();
        
        System.assert((Boolean)result.get('success'), 'Integration should succeed');
        System.assertNotEquals(null, result.get('documentId'), 'Document ID should be returned');
        System.assertNotEquals(null, result.get('signatureRequestId'), 'Signature Request ID should be returned');
        
        // Verify document status updated
        DocumentLifecycleConfiguration__c doc = [SELECT E_Signature_Status__c, Integration_Status__c 
                                               FROM DocumentLifecycleConfiguration__c 
                                               WHERE Id = :(String)result.get('documentId')];
        System.assertEquals('In_Progress', doc.E_Signature_Status__c);
        System.assertEquals('Ready_For_Signature', doc.Integration_Status__c);
    }
    
    @isTest
    static void testSignatureCompletionProcess() {
        Signature_Request__c sigRequest = [SELECT Id FROM Signature_Request__c LIMIT 1];
        
        // Mock signature data
        sigRequest.Signature_Data__c = 'base64signaturedata';
        sigRequest.Document_Hash__c = 'mockhashvalue';
        sigRequest.Status__c = 'Completed';
        update sigRequest;
        
        Test.startTest();
        
        Map<String, Object> result = DocGenESignIntegrationController.processSignatureCompletion(sigRequest.Id);
        
        Test.stopTest();
        
        System.assert((Boolean)result.get('success'), 'Signature completion should succeed');
        System.assertEquals('COMPLETED', result.get('status'));
        
        // Verify final document created
        List<DocumentLifecycleConfiguration__c> finalDocs = [SELECT ProcessingStatus__c 
                                                           FROM DocumentLifecycleConfiguration__c 
                                                           WHERE ProcessingStatus__c = 'Final'];
        System.assertEquals(1, finalDocs.size(), 'Final document should be created');
    }
    
    @isTest
    static void testWorkflowFailureHandling() {
        Test.startTest();
        
        // Test with invalid data to trigger failure
        Map<String, Object> result = DocGenESignIntegrationController.generateAndInitiateSignature(
            '', '', '', '', 'invalid-email'
        );
        
        Test.stopTest();
        
        System.assertEquals(false, (Boolean)result.get('success'), 'Should fail with invalid data');
        System.assert(((String)result.get('error')).contains('failed'), 'Should contain error message');
    }
    
    @isTest
    static void testIntegratedWorkflowController() {
        Test.startTest();
        
        Map<String, Object> documentParams = new Map<String, Object>{
            'region' => 'US',
            'role' => 'Manager',
            'contractType' => 'Employment',
            'documentTitle' => 'Workflow Test Document',
            'signerEmail' => 'workflow@example.com'
        };
        
        Map<String, Object> signatureParams = new Map<String, Object>{
            'signerEmail' => 'workflow@example.com'
        };
        
        Map<String, Object> result = IntegratedWorkflowController.executeCompleteWorkflow(
            documentParams, signatureParams
        );
        
        Test.stopTest();
        
        System.assert((Boolean)result.get('success'), 'Workflow should succeed');
        
        // Verify workflow instance created
        List<Workflow_Instance__c> workflows = [SELECT Status__c FROM Workflow_Instance__c];
        System.assertEquals(1, workflows.size(), 'Workflow instance should be created');
    }
}
