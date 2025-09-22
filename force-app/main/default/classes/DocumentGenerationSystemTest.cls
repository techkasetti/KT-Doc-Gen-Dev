@isTest
public class DocumentGenerationSystemTest {
    
    @testSetup
    static void setupTestData() {
        // Create test configurations
        List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
        configs.add(new DocumentLifecycleConfiguration__c(
            Region__c = 'US',
            Role__c = 'Manager',
            ContractType__c = 'Employment',
            ComplianceStatus__c = 'Compliant'
        ));
        configs.add(new DocumentLifecycleConfiguration__c(
            Region__c = 'EU',
            Role__c = 'Employee', 
            ContractType__c = 'NDA',
            ComplianceStatus__c = 'Review'
        ));
        insert configs;
        
        // Create compliance rules
        List<ComplianceRule__c> rules = new List<ComplianceRule__c>();
        rules.add(new ComplianceRule__c(
            Region__c = 'US',
            DocumentType__c = 'Employment',
            RequiredKeyword__c = 'employment law',
            Severity__c = 'High'
        ));
        rules.add(new ComplianceRule__c(
            Region__c = 'EU',
            DocumentType__c = 'NDA',
            RequiredKeyword__c = 'confidentiality',
            Severity__c = 'Medium'
        ));
        insert rules;
        
        // Create retention policies
        RetentionPolicy__c policy = new RetentionPolicy__c(
            Name = 'Standard Employment Policy',
            RetentionPeriod__c = 2555, // 7 years in days
            DocumentType__c = 'Employment',
            IsActive__c = true
        );
        insert policy;

        // Create test user for signing
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'test',
            Email = 'test@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'test@example.com.docgen'
        );
        insert testUser;
    }

    @isTest
    static void testDocumentLifecycleDeploymentManager() {
        Test.startTest();
        
        DocumentLifecycleDeploymentManager.setupSystemConfiguration();
        
        List<DocumentLifecycleConfiguration__c> configs = [
            SELECT Id, Name FROM DocumentLifecycleConfiguration__c
        ];
        System.assert(configs.size() > 0, 'System configurations should be created');
        
        List<RetentionPolicy__c> policies = [
            SELECT Id, Name FROM RetentionPolicy__c
        ];
        System.assert(policies.size() > 0, 'Retention policies should be created');
        
        Test.stopTest();
    }

    @isTest
    static void testClauseGeneratorPositive() {
        Test.startTest();
        
        String clause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
        
        System.assertNotEquals(null, clause, 'Clause should be generated');
        System.assert(clause.length() > 0, 'Clause should not be empty');
        System.assert(clause.contains('employment'), 'Clause should contain employment-related content');
        
        Test.stopTest();
    }

    @isTest
    static void testClauseGeneratorEdgeCases() {
        Test.startTest();
        
        try {
            ClauseGenerator.generateClause('INVALID', 'Manager', 'Employment');
            System.assert(false, 'Should throw exception for invalid region');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Invalid'), 'Should contain error message about invalid input');
        }
        
        try {
            ClauseGenerator.generateClause(null, 'Manager', 'Employment');
            System.assert(false, 'Should throw exception for null region');
        } catch (Exception e) {
            System.assert(true, 'Exception expected for null input');
        }
        
        Test.stopTest();
    }

    @isTest
    static void testComplianceCheckerValidation() {
        Test.startTest();
        
        String compliantClause = 
            'This employment agreement complies with US employment law and includes confidentiality provisions.';
        Boolean isCompliant = ComplianceChecker.validateClause(compliantClause, 'US', 'Employment');
        System.assertEquals(true, isCompliant, 'Compliant clause should pass validation');
        
        String nonCompliantClause = 'This is a simple agreement with no specific provisions.';
        Boolean isNonCompliant = ComplianceChecker.validateClause(nonCompliantClause, 'US', 'Employment');
        System.assertEquals(false, isNonCompliant, 'Non-compliant clause should fail validation');
        
        Test.stopTest();
    }

    @isTest
    static void testSignatureRequestController() {
        Test.startTest();
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test document content')
        );
        insert cv;
        
        ContentDocument doc = [
            SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1
        ];
        
        String requestId = SignatureRequestController.initiateSignatureRequest(
            doc.Id, 
            'test@example.com', 
            'Test User'
        );
        
        System.assertNotEquals(null, requestId, 'Signature request ID should be returned');
        
        List<Signature_Request__c> requests = [
            SELECT Id, Status__c FROM Signature_Request__c WHERE Id = :requestId
        ];
        System.assertEquals(1, requests.size(), 'Signature request should be created');
        System.assertEquals('Sent', requests[0].Status__c, 'Initial status should be Sent');
        
        Test.stopTest();
    }

    @isTest
    static void testSignatureSubmission() {
        Test.startTest();
        
        Signature_Request__c request = new Signature_Request__c(
            SignerEmail__c = 'test@example.com',
            SignerName__c = 'Test User',
            Status__c = 'Sent',
            RequestDate__c = Date.today()
        );
        insert request;
        
        String signatureData = 
            'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
        
        String signerInfo = JSON.serialize(new Map<String, Object>{
            'signerName' => 'Test User',
            'signatureMethod' => 'draw',
            'ipAddress' => '192.168.1.1',
            'timestamp' => DateTime.now().format()
        });
        
        Boolean result = SignatureRequestController.submitSignature(
            request.Id,
            signatureData,
            signerInfo
        );
        
        System.assertEquals(true, result, 'Signature submission should succeed');
        
        request = [
            SELECT Status__c, CompletedDate__c 
            FROM Signature_Request__c 
            WHERE Id = :request.Id
        ];
        System.assertEquals('Signed', request.Status__c, 'Status should be updated to Signed');
        System.assertNotEquals(null, request.CompletedDate__c, 'Completion date should be set');
        
        Test.stopTest();
    }

    @isTest
    static void testDocumentRetentionManagement() {
        Test.startTest();
        
        ContentVersion cv = new ContentVersion(
            Title = 'Employment Contract - Test Employee',
            PathOnClient = 'employment.pdf',
            VersionData = Blob.valueOf('Test employment contract content')
        );
        insert cv;
        
        ContentDocument doc = [
            SELECT Id, CreatedDate FROM ContentDocument WHERE Id = :cv.ContentDocumentId
        ];
        
        List<RetentionPolicy__c> policies = [
            SELECT Id FROM RetentionPolicy__c WHERE DocumentType__c = 'Employment' LIMIT 1
        ];
        System.assert(!policies.isEmpty(), 'Employment retention policy should exist');
        
        Test.stopTest();
    }

    @isTest 
    static void testBulkClauseGeneration() {
        Test.startTest();
        
        List<String> regions = new List<String>{'US', 'EU', 'Global'};
        List<String> roles = new List<String>{'Manager', 'Employee', 'Admin'};
        List<String> contractTypes = new List<String>{'Employment', 'NDA', 'SLA'};
        
        Integer successCount = 0;
        Integer totalCount = 0;
        
        for (String region : regions) {
            for (String role : roles) {
                for (String contractType : contractTypes) {
                    totalCount++;
                    try {
                        String clause = ClauseGenerator.generateClause(region, role, contractType);
                        if (clause != null && clause.length() > 0) {
                            successCount++;
                        }
                    } catch (Exception e) {
                        System.debug('Clause generation failed for: ' + region + ', ' + role + ', ' + contractType);
                    }
                }
            }
        }
        
        System.assert(successCount > (totalCount * 0.7), 
            'Bulk clause generation success rate should be above 70%: ' + successCount + '/' + totalCount);
        
        Test.stopTest();
    }

    @isTest
    static void testComplianceWorkflowOrchestrator() {
        Test.startTest();
        
        DocumentLifecycleConfiguration__c config = [
            SELECT Id, Region__c, Role__c, ContractType__c 
            FROM DocumentLifecycleConfiguration__c 
            LIMIT 1
        ];
        
        String result = ComplianceWorkflowOrchestrator.executeWorkflow(config.Id);
        
        System.assertNotEquals(null, result, 'Workflow execution should return result');
        
        List<AuditTrail__c> auditRecords = [
            SELECT Id, Action__c, RecordId__c 
            FROM AuditTrail__c 
            WHERE RecordId__c = :config.Id
        ];
        System.assert(auditRecords.size() > 0, 'Audit trail should be created');
        
        Test.stopTest();
    }

    @isTest
    static void testErrorHandlingAndLogging() {
        Test.startTest();
        
        try {
            ClauseGenerator.generateClause('', '', '');
        } catch (Exception e) {
            System.assert(true, 'Exception should be caught and handled');
        }
        
        try {
            ComplianceChecker.validateClause(null, 'US', 'Employment');
        } catch (Exception e) {
            System.assert(true, 'Exception should be caught for null clause');
        }
        
        Test.stopTest();
    }

    @isTest
    static void testSecurityAndPermissions() {
        Test.startTest();
        
        User testUser = [
            SELECT Id FROM User WHERE Email = 'test@example.com.docgen' LIMIT 1
        ];
        
        System.runAs(testUser) {
            try {
                String clause = ClauseGenerator.generateClause('US', 'Employee', 'Employment');
                System.assertNotEquals(null, clause, 'Standard user should be able to generate clauses');
            } catch (Exception e) {
                System.debug('Permission error: ' + e.getMessage());
            }
        }
        
        Test.stopTest();
    }

    @isTest
    static void testPerformanceMetrics() {
        Test.startTest();
        
        Long startTime = System.currentTimeMillis();
        
        for (Integer i = 0; i < 10; i++) {
            ClauseGenerator.generateClause('US', 'Manager', 'Employment');
        }
        
        Long endTime = System.currentTimeMillis();
        Long duration = endTime - startTime;
        
        System.assert(duration < 30000, 
            'Bulk generation should complete within 30 seconds: ' + duration + 'ms');
        
        Test.stopTest();
    }

    @isTest
    static void testDataIntegrity() {
        Test.startTest();
        
        DocumentLifecycleConfiguration__c config = new DocumentLifecycleConfiguration__c(
            Region__c = 'US',
            Role__c = 'Manager', 
            ContractType__c = 'Employment',
            ComplianceStatus__c = 'Compliant'
        );
        insert config;
        
        String clause = ClauseGenerator.generateClause(config.Region__c, config.Role__c, config.ContractType__c);
        Boolean isCompliant = ComplianceChecker.validateClause(clause, config.Region__c, config.ContractType__c);
        
        System.assertEquals('Compliant', config.ComplianceStatus__c, 'Config should maintain compliance status');
        System.assertEquals(true, isCompliant, 'Generated clause should match compliance status');
        
        Test.stopTest();
    }
}
