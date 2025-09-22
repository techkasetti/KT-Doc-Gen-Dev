
// version v0

// @isTest
// public class DocumentGenerationTest {
    
//     @testSetup
//     static void setupTestData() {
//         DocumentLifecycleDeploymentManager.initializeCompleteSystem();
        
//         ContractSchema__c schema = new ContractSchema__c(
//             Name = 'Test Contract',
//             Region__c = 'US',
//             Role__c = 'Developer',
//             ContractType__c = 'NDA',
//             Clauses__c = 'confidentiality;non-disclosure'
//         );
//         insert schema;
//     }
    
//     @isTest
//     static void testClauseGeneration() {
//         Test.startTest();
        
//         List<String> clauses = new List<String>{'confidentiality', 'non-disclosure'};
//         String result = ClauseGenerator.generateClause('US', 'Developer', 'NDA', clauses);
        
//         Test.stopTest();
        
//         System.assertNotEquals(null, result);
//         System.assert(result.contains('US federal'));
//         System.assert(result.contains('developers'));
        
//         // Verify audit log was created
//         List<ContractAudit__c> audits = [SELECT Id, Action__c FROM ContractAudit__c WHERE Action__c = 'Clause Generated'];
//         System.assertEquals(1, audits.size());
//     }
    
//     @isTest
//     static void testComplianceValidation() {
//         // Create compliance rule
//         // Note: Custom metadata can't be inserted in tests, so we'll mock the behavior
        
//         Test.startTest();
        
//         String clauseText = 'This agreement adheres to US federal regulations for developers.';
//         Boolean isCompliant = ComplianceChecker.validateClause(clauseText, 'US');
        
//         Test.stopTest();
        
//         // Should return true since we're not enforcing specific keywords in this test
//         System.assertEquals(true, isCompliant);
        
//         // Verify audit log was created
//         List<ContractAudit__c> audits = [SELECT Id, ComplianceStatus__c FROM ContractAudit__c WHERE ComplianceStatus__c = 'Compliant'];
//         System.assertEquals(1, audits.size());
//     }
    
//     @isTest
//     static void testSystemInitialization() {
//         // This should already be called in @testSetup, verify it worked
//         List<DocumentLifecycleConfiguration__c> configs = [SELECT Id, Name FROM DocumentLifecycleConfiguration__c];
//         System.assert(configs.size() > 0);
        
//         List<DocumentRetentionPolicy__c> policies = [SELECT Id, Name FROM DocumentRetentionPolicy__c];
//         System.assert(policies.size() > 0);
//     }
// }




// version v1

// @isTest
// public class DocumentGenerationTest {
    
//     @testSetup
//     static void setupTestData() {
//         DocumentLifecycleDeploymentManager.initializeCompleteSystem();
        
//         ContractSchema__c schema = new ContractSchema__c(
//             Name = 'Test Contract',
//             Region__c = 'US',
//             Role__c = 'Developer',
//             ContractType__c = 'NDA',
//             Clauses__c = 'confidentiality;non-disclosure'
//         );
//         insert schema;
//     }
    
//     @isTest
//     static void testClauseGeneration() {
//         Test.startTest();
        
//         List<String> clauses = new List<String>{'confidentiality', 'non-disclosure'};
//         String result = ClauseGenerator.generateClause('US', 'Developer', 'NDA', clauses);
        
//         Test.stopTest();
        
//         System.assertNotEquals(null, result);
//         System.assert(result.contains('US federal'));
//         System.assert(result.contains('developers'));
        
//         // Verify audit log was created
//         List<ContractAudit__c> audits = [SELECT Id, Action__c FROM ContractAudit__c WHERE Action__c = 'Clause Generated'];
//         System.assertEquals(1, audits.size());
//     }
    
//     @isTest
//     static void testComplianceValidation() {
//         // Create compliance rule
//         // Note: Custom metadata can't be inserted in tests, so we'll mock the behavior
        
//         Test.startTest();
        
//         String clauseText = 'This agreement adheres to US federal regulations for developers.';
//         Boolean isCompliant = ComplianceChecker.validateClause(clauseText, 'US');
        
//         Test.stopTest();
        
//         // Should return true since we're not enforcing specific keywords in this test
//         System.assertEquals(true, isCompliant);
        
//         // Verify audit log was created
//         List<ContractAudit__c> audits = [SELECT Id, ComplianceStatus__c FROM ContractAudit__c WHERE ComplianceStatus__c = 'Compliant'];
//         System.assertEquals(1, audits.size());
//     }
    
//     @isTest
//     static void testSystemInitialization() {
//         // This should already be called in @testSetup, verify it worked
//         List<DocumentLifecycleConfiguration__c> configs = [SELECT Id, Name FROM DocumentLifecycleConfiguration__c];
//         System.assert(configs.size() > 0);
        
//         List<DocumentRetentionPolicy__c> policies = [SELECT Id, Name FROM DocumentRetentionPolicy__c];
//         System.assert(policies.size() > 0);
//     }
// }



// version v2 

// @isTest
// public class DocumentGenerationTest {
//     @testSetup
//     static void setupTestData() {
//         DocumentLifecycleConfiguration__c testConfig = new DocumentLifecycleConfiguration__c(
//             ConfigurationName__c = 'Test Configuration',
//             IsActive__c = true
//         );
//         insert testConfig;
//     }
    
//     @isTest
//     static void testSystemInitialization() {
//         Test.startTest();
//         DocumentLifecycleDeploymentManager.initializeCompleteSystem();
//         Test.stopTest();
        
//         List<DocumentLifecycleConfiguration__c> configs = [SELECT Id FROM DocumentLifecycleConfiguration__c];
//         System.assert(configs.size() >= 2, 'System configurations should be created');
//     }
// }



// version v6


// @isTest
// public class DocumentGeneratorTest {
    
//     @TestSetup
//     static void setupTestData() {
//         // Initialize system
//         DocumentLifecycleDeploymentManager.initializeCompleteSystem();
        
//         // Create compliance rules
//         ComplianceRule__c rule = new ComplianceRule__c(
//             Name = 'US Employment Rule',
//             Region__c = 'US',
//             Document_Type__c = 'Employment',
//             Required_Keyword__c = 'authorized signatory',
//             Is_Active__c = true
//         );
//         insert rule;
//     }
    
//     @isTest
//     static void testCompleteDocumentGenerationFlow() {
//         Test.startTest();
        
//         // Step 1: Generate clause
//         String clause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
//         System.assertNotEquals(null, clause, 'Clause should be generated');
//         System.assert(clause.contains('authorized signatory'), 'Should contain required terms');
        
//         // Step 2: Validate compliance
//         Boolean isCompliant = ComplianceChecker.validateClause(clause, 'US', 'Employment');
//         System.assertEquals(true, isCompliant, 'Generated clause should be compliant');
        
//         // Step 3: Create signature request
//         String requestId = SignatureRequestController.initiateSignatureRequest(
//             'TEST_DOC_001',
//             'test.manager@company.com',
//             'Test Manager'
//         );
//         System.assertNotEquals(null, requestId, 'Should create signature request');
        
//         // Step 4: Submit signature
//         String signatureData = 'TYPED_SIGNATURE:John Manager';
//         String signerInfo = JSON.serialize(new Map<String, String>{
//             'name' => 'Test Manager',
//             'email' => 'test.manager@company.com',
//             'method' => 'type'
//         });
        
//         Boolean signatureResult = SignatureRequestController.submitSignature(
//             requestId,
//             signatureData,
//             signerInfo
//         );
//         System.assertEquals(true, signatureResult, 'Signature should be submitted successfully');
        
//         Test.stopTest();
        
//         // Verify complete workflow
//         List<AuditTrail__c> auditTrails = [
//             SELECT Id, Action__c 
//             FROM AuditTrail__c 
//             ORDER BY CreatedDate
//         ];
        
//         // Should have audit trails for: system init, clause generation, compliance success, signature initiated, signature completed
//         System.assert(auditTrails.size() >= 5, 'Should have comprehensive audit trail');
//     }
    
//     @isTest
//     static void testErrorHandling() {
//         Test.startTest();
        
//         try {
//             // Test invalid signature request
//             SignatureRequestController.submitSignature('invalid-id', 'test-data', 'test-info');
//             System.assert(false, 'Should throw exception for invalid request ID');
//         } catch (Exception e) {
//             System.assert(e.getMessage().contains('Failed to submit signature'), 'Should handle error gracefully');
//         }
        
//         Test.stopTest();
//     }
// }
