@isTest
public class CompleteSystemTest {
    @testSetup
    static void setupCompleteTestData() {
        // Create comprehensive test data
        DocumentLifecycleDeploymentManager.initializeCompleteSystem();
        
        // Add additional test configurations
        List<ComplianceRule__c> rules = new List<ComplianceRule__c>();
        rules.add(new ComplianceRule__c(
            RequiredKeyword__c = 'employment',
            RuleName__c = 'US Employment Rule',
            Region__c = 'US',
            DocumentType__c = 'Employment',
            IsActive__c = true,
            ComplianceLevel__c = 'Mandatory',
            ValidationMessage__c = 'Document must contain employment-related clauses'
        ));
        
        rules.add(new ComplianceRule__c(
            RequiredKeyword__c = 'GDPR',
            RuleName__c = 'EU GDPR Compliance',
            Region__c = 'EU',
            DocumentType__c = 'Employment',
            IsActive__c = true,
            ComplianceLevel__c = 'Critical',
            ValidationMessage__c = 'GDPR compliance clauses required for EU employment'
        ));
        
        rules.add(new ComplianceRule__c(
            RequiredKeyword__c = 'confidentiality',
            RuleName__c = 'NDA Confidentiality Rule',
            Region__c = 'Global',
            DocumentType__c = 'NDA',
            IsActive__c = true,
            ComplianceLevel__c = 'Standard',
            ValidationMessage__c = 'Confidentiality provisions must be clearly defined'
        ));
        
        insert rules;
        
        // Create test users with different profiles
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> testUsers = new List<User>();
        testUsers.add(new User(
            FirstName = 'Test',
            LastName = 'Manager',
            Email = 'testmanager@example.com',
            Username = 'testmanager@testcompany.com.test',
            ProfileId = standardProfile.Id,
            Alias = 'tmgr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        ));
        
        testUsers.add(new User(
            FirstName = 'Test',
            LastName = 'Employee',
            Email = 'testemployee@example.com',
            Username = 'testemployee@testcompany.com.test',
            ProfileId = standardProfile.Id,
            Alias = 'temp',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        ));
        
        insert testUsers;
        
        // Create document templates
        List<DocumentTemplate__c> templates = new List<DocumentTemplate__c>();
        templates.add(new DocumentTemplate__c(
            Name = 'US Employment Contract Template',
            TemplateType__c = 'Employment',
            Region__c = 'US',
            Description__c = 'Standard US employment contract with all legal requirements',
            IsActive__c = true,
            TemplateContent__c = 'Employment Agreement between {{company_name}} and {{employee_name}}'
        ));
        
        templates.add(new DocumentTemplate__c(
            Name = 'EU GDPR Employment Contract',
            TemplateType__c = 'Employment',
            Region__c = 'EU',
            Description__c = 'GDPR compliant employment contract for European Union',
            IsActive__c = true,
            TemplateContent__c = 'This GDPR compliant employment agreement ensures data protection rights'
        ));
        
        insert templates;
    }
    
    @isTest
    static void testEndToEndDocumentLifecycle() {
        Test.startTest();
        
        // Step 1: Generate clause
        String generatedClause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
        System.assertNotEquals('', generatedClause, 'Clause should be generated');
        System.assert(generatedClause.contains('employment'), 'Clause should contain employment terms');
        
        // Step 2: Validate compliance
        Boolean isCompliant = ComplianceChecker.validateClause(generatedClause, 'US', 'Employment');
        System.assertEquals(true, isCompliant, 'Generated clause should be compliant');
        
        // Step 3: Create document request
        String docRequestId = DocumentGenerationController.createDocumentRequest(
            'Employment',
            'US', 
            'Manager',
            generatedClause,
            'Additional requirement: Remote work flexibility',
            'Compliant'
        );
        System.assertNotEquals(null, docRequestId, 'Document request should be created');
        
        // Step 4: Initiate signature request
        String signatureRequestId = SignatureRequestController.initiateSignatureRequest(
            docRequestId,
            'manager@testcompany.com',
            'Employment Contract - Manager Position'
        );
        System.assertNotEquals(null, signatureRequestId, 'Signature request should be created');
        
        // Step 5: Submit signature
        String signatureData = 'data:image/png;base64,test_signature_data_here';
        String signerInfo = JSON.serialize(new Map<String, Object>{
            'signatureMethod' => 'draw',
            'signerName' => 'John Manager',
            'signerEmail' => 'manager@testcompany.com',
            'timestamp' => System.now().format(),
            'termsAccepted' => true
        });
        
        SignatureRequestController.submitSignature(signatureRequestId, signatureData, signerInfo);
        
        Test.stopTest();
        
        // Verification Phase
        
        // Verify document request
        DocumentLifecycleConfiguration__c docRequest = [
            SELECT Id, Region__c, Role__c, ContractType__c, ComplianceStatus__c, Clauses__c
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :docRequestId
        ];
        
        System.assertEquals('US', docRequest.Region__c);
        System.assertEquals('Manager', docRequest.Role__c);
        System.assertEquals('Employment', docRequest.ContractType__c);
        System.assertEquals('Compliant', docRequest.ComplianceStatus__c);
        System.assert(docRequest.Clauses__c.contains('Remote work flexibility'));
        
        // Verify signature request completion
        Signature_Request__c sigRequest = [
            SELECT Status__c, SignedDate__c, SignatureData__c
            FROM Signature_Request__c 
            WHERE Id = :signatureRequestId
        ];
        
        System.assertEquals('Signed', sigRequest.Status__c);
        System.assertNotEquals(null, sigRequest.SignedDate__c);
        System.assertNotEquals(null, sigRequest.SignatureData__c);
        
        // Verify audit trail
        List<AuditTrail__c> auditRecords = [
            SELECT Action__c, RelatedRecordId__c
            FROM AuditTrail__c
            ORDER BY CreatedDate ASC
        ];
        
        System.assert(auditRecords.size() >= 2, 'Should have audit records for document and signature');
        
        // Verify signature validation
        List<SignatureValidation__c> validations = [
            SELECT ValidationStatus__c
            FROM SignatureValidation__c
            WHERE SignatureRequest__c = :signatureRequestId
        ];
        
        System.assertEquals(1, validations.size());
        System.assertEquals('Valid', validations[0].ValidationStatus__c);
    }
    
    @isTest
    static void testMultiRegionCompliance() {
        Test.startTest();
        
        // Test US compliance
        String usClause = ClauseGenerator.generateClause('US', 'Employee', 'Employment');
        Boolean usCompliance = ComplianceChecker.validateClause(usClause, 'US', 'Employment');
        
        // Test EU compliance
        String euClause = ClauseGenerator.generateClause('EU', 'Employee', 'Employment');
        Boolean euCompliance = ComplianceChecker.validateClause(euClause, 'EU', 'Employment');
        
        Test.stopTest();
        
        // Verify regional compliance
        System.assertEquals(true, usCompliance, 'US employment clause should be compliant');
        System.assertEquals(true, euCompliance, 'EU employment clause should be compliant');
        
        // Verify clauses contain region-specific content
        System.assert(usClause.contains('employment'), 'US clause should contain employment terms');
        System.assert(euClause.contains('GDPR') || euClause.contains('employment'), 'EU clause should contain GDPR or employment terms');
    }
    
    @isTest
    static void testTemplateRetrieval() {
        Test.startTest();
        
        // Test US template retrieval
        List<Map<String, Object>> usTemplates = DocumentGenerationController.getAvailableTemplates('Employment', 'US');
        
        // Test EU template retrieval
        List<Map<String, Object>> euTemplates = DocumentGenerationController.getAvailableTemplates('Employment', 'EU');
        
        Test.stopTest();
        
        // Verify template retrieval
        System.assertEquals(1, usTemplates.size(), 'Should have one US employment template');
        System.assertEquals('US Employment Contract Template', usTemplates[0].get('name'));
        
        System.assertEquals(1, euTemplates.size(), 'Should have one EU employment template');
        System.assertEquals('EU GDPR Employment Contract', euTemplates[0].get('name'));
    }
    
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        
        // Test invalid region
        try {
            ClauseGenerator.generateClause('INVALID_REGION', 'Manager', 'Employment');
            System.assert(false, 'Should have thrown exception for invalid region');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Unsupported region'), 'Should indicate unsupported region');
        }
        
        // Test invalid signature request
        try {
            SignatureRequestController.submitSignature('INVALID_ID', 'signature_data', '{}');
            System.assert(false, 'Should have thrown exception for invalid request ID');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Failed'), 'Should indicate failure');
        }
        
        Test.stopTest();
        
        // Verify error handling worked as expected
        System.assert(true, 'Error handling tests completed successfully');
    }
    
    @isTest
    static void testBulkOperations() {
        Test.startTest();
        
        // Create multiple document requests
        List<String> docRequestIds = new List<String>();
        
        for (Integer i = 0; i < 5; i++) {
            String docId = DocumentGenerationController.createDocumentRequest(
                'Employment',
                'US',
                'Employee',
                'Standard employment clause for bulk test ' + i,
                'Bulk operation test',
                'Compliant'
            );
            docRequestIds.add(docId);
        }
        
        Test.stopTest();
        
        // Verify bulk operations
        System.assertEquals(5, docRequestIds.size(), 'Should have created 5 document requests');
        
        // Verify all documents were created
        List<DocumentLifecycleConfiguration__c> docs = [
            SELECT Id, ContractType__c, Region__c
            FROM DocumentLifecycleConfiguration__c
            WHERE Id IN :docRequestIds
        ];
        
        System.assertEquals(5, docs.size(), 'Should have 5 documents in database');
        
        for (DocumentLifecycleConfiguration__c doc : docs) {
            System.assertEquals('Employment', doc.ContractType__c);
            System.assertEquals('US', doc.Region__c);
        }
        
        // Verify audit trails for bulk operations
        List<AuditTrail__c> bulkAudits = [
            SELECT RelatedRecordId__c
            FROM AuditTrail__c
            WHERE RelatedRecordId__c IN :docRequestIds
        ];
        
        System.assertEquals(5, bulkAudits.size(), 'Should have audit records for all bulk operations');
    }
    
    @isTest
    static void testSystemPerformance() {
        Test.startTest();
        
        // Record start time
        Long startTime = System.now().getTime();
        
        // Perform typical workflow operations
        String clause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
        Boolean compliance = ComplianceChecker.validateClause(clause, 'US', 'Employment');
        String docId = DocumentGenerationController.createDocumentRequest(
            'Employment', 'US', 'Manager', clause, '', 'Compliant'
        );
        String sigId = SignatureRequestController.initiateSignatureRequest(
            docId, 'test@example.com', 'Performance Test Document'
        );
        
        // Record end time
        Long endTime = System.now().getTime();
        Long executionTime = endTime - startTime;
        
        Test.stopTest();
        
        // Verify performance (should complete within reasonable time)
        System.assert(executionTime < 30000, 'Workflow should complete within 30 seconds: ' + executionTime + 'ms');
        
        // Verify all operations completed successfully
        System.assertNotEquals('', clause);
        System.assertEquals(true, compliance);
        System.assertNotEquals(null, docId);
        System.assertNotEquals(null, sigId);
    }
    
    @isTest
    static void testSystemInitialization() {
        Test.startTest();
        
        // Verify system was initialized properly in test setup
        List<DocumentLifecycleConfiguration__c> configs = [
            SELECT Id, ConfigurationName__c
            FROM DocumentLifecycleConfiguration__c
        ];
        
        List<ComplianceRule__c> rules = [
            SELECT Id, RuleName__c, Region__c, DocumentType__c
            FROM ComplianceRule__c
        ];
        
        List<DocumentTemplate__c> templates = [
            SELECT Id, Name, TemplateType__c, Region__c
            FROM DocumentTemplate__c
        ];
        
        Test.stopTest();
        
        // Verify system components were created
        System.assert(configs.size() >= 1, 'Should have configuration records');
        System.assertEquals(3, rules.size(), 'Should have 3 compliance rules');
        System.assertEquals(2, templates.size(), 'Should have 2 document templates');
        
        // Verify specific rules exist
        Map<String, ComplianceRule__c> ruleMap = new Map<String, ComplianceRule__c>();
        for (ComplianceRule__c rule : rules) {
            ruleMap.put(rule.RuleName__c, rule);
        }
        
        System.assert(ruleMap.containsKey('US Employment Rule'));
        System.assert(ruleMap.containsKey('EU GDPR Compliance'));
        System.assert(ruleMap.containsKey('NDA Confidentiality Rule'));
    }
}
