// Final system test and validation framework
@isTest
public class DocumentLifecycleManagementTest {
    
    @testSetup
    static void setupTestData() {
        // Create test document
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('Test document content for lifecycle management testing'),
            IsMajorVersion = true
        );
        insert cv;
        
        // Create test retention policy
        DocumentRetentionPolicy__c retentionPolicy = new DocumentRetentionPolicy__c(
            Name = 'Test Retention Policy',
            Retention_Period_Years__c = 7,
            Document_Type__c = 'GENERAL',
            Archive_Before_Deletion__c = true,
            Is_Active__c = true,
            Priority__c = 1
        );
        insert retentionPolicy;
        
        // Create test expiration policy
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        DocumentExpirationPolicy__c expirationPolicy = new DocumentExpirationPolicy__c(
            Document_Id__c = doc.Id,
            Expiration_Date__c = Date.today().addDays(30),
            Warning_Period_Days__c = 7,
            Grace_Period_Days__c = 5,
            Auto_Archive__c = true,
            Auto_Delete__c = false,
            Expiration_Action__c = 'RESTRICT_ACCESS;AUTO_ARCHIVE;NOTIFY_STAKEHOLDERS',
            Notification_Recipients__c = 'test@example.com',
            Business_Justification_Required__c = false
        );
        insert expirationPolicy;
    }
    
    @isTest
    static void testCompleteDocumentLifecycleOrchestration() {
        // Get test document
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        
        Test.startTest();
        
        // Execute complete lifecycle orchestration
        OrchestrationResult result = DocumentLifecycleOrchestrator.executeFullLifecycleOrchestration(doc.Id);
        
        Test.stopTest();
        
        // Verify orchestration success
        System.assert(result.success, 'Document lifecycle orchestration should succeed');
        System.assertEquals('COMPLETED', result.orchestrationStatus, 'Orchestration should complete successfully');
        System.assert(result.phaseResults.size() >= 6, 'All major phases should be executed');
        
        // Verify audit trail creation
        List<DocumentComprehensiveAudit__c> auditTrails = [
            SELECT Id, Overall_Status__c, Final_Compliance_Score__c, Components_Initialized__c
            FROM DocumentComprehensiveAudit__c 
            WHERE Document_Id__c = :doc.Id
        ];
        System.assert(auditTrails.size() > 0, 'Comprehensive audit trail should be created');
        
        // Verify lifecycle tracking
        List<DocumentLifecycleTracking__c> lifecycleTracking = [
            SELECT Id, Status__c, Lifecycle_Stage__c
            FROM DocumentLifecycleTracking__c 
            WHERE Document_Id__c = :doc.Id
        ];
        System.assert(lifecycleTracking.size() > 0, 'Lifecycle tracking should be initialized');
    }
    
    @isTest
    static void testAdvancedVersionControlEngine() {
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        
        Test.startTest();
        
        // Test version control creation
        DocumentVersionNode versionNode = AdvancedVersionControlEngine.createVersionTree(doc.Id);
        
        Test.stopTest();
        
        System.assert(versionNode.success, 'Version tree creation should succeed');
        System.assertNotEquals(null, versionNode.versionTree, 'Version tree should be created');
        
        // Verify version tree record
        List<DocumentVersionTree__c> versionTrees = [
            SELECT Id, Total_Versions__c, Tree_Structure__c
            FROM DocumentVersionTree__c 
            WHERE Document_Id__c = :doc.Id
        ];
        System.assert(versionTrees.size() > 0, 'Version tree record should be created');
    }
    
    @isTest
    static void testDocumentExpirationEngine() {
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        
        Test.startTest();
        
        // Test expiration processing
        DocumentExpirationEngine.processExpiringDocuments(new Set<Id>{doc.Id});
        
        Test.stopTest();
        
        // Verify expiration tracking
        List<DocumentExpirationTracking__c> expirationTracking = [
            SELECT Id, Expiration_Status__c, Last_Check_Date__c
            FROM DocumentExpirationTracking__c 
            WHERE Document_Id__c = :doc.Id
        ];
        System.assert(expirationTracking.size() > 0, 'Expiration tracking should be created');
    }
    
    @isTest
    static void testDocumentLifecycleSystemIntegrator() {
        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        
        // Prepare request
        DocumentLifecycleRequest request = new DocumentLifecycleRequest();
        request.documentId = doc.Id;
        request.requestId = 'TEST_REQUEST_001';
        request.enableAdvancedAnalytics = true;
        request.enableRealTimeMonitoring = true;
        request.generateComprehensiveReport = true;
        
        Test.startTest();
        
        // Execute system integration
        List<DocumentLifecycleResult> results = DocumentLifecycleSystemIntegrator.executeCompleteLifecycleManagement(
            new List<DocumentLifecycleRequest>{request}
        );
        
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        DocumentLifecycleResult result = results[0];
        System.assert(result.success, 'Integration should succeed');
        System.assertEquals(doc.Id, result.documentId, 'Document ID should match');
    }
    
    @isTest
    static void testDocumentAnalyticsEngine() {
        Test.startTest();
        
        // Test comprehensive report generation
        Map<String, Object> parameters = new Map<String, Object>{
            'timeframe' => 'LAST_30_DAYS',
            'includeCompliance' => true,
            'includeAI' => true
        };
        
        ComprehensiveDocumentReport report = DocumentAnalyticsEngine.generateComprehensiveReport(
            'LIFECYCLE_ANALYTICS', parameters
        );
        
        Test.stopTest();
        
        System.assert(report.success, 'Report generation should succeed');
        System.assertEquals('LIFECYCLE_ANALYTICS', report.reportType, 'Report type should match');
        System.assertNotEquals(null, report.generationStartTime, 'Start time should be set');
    }
    
    @isTest
    static void testErrorHandlingAndRecovery() {
        // Test with invalid document ID
        Test.startTest();
        
        OrchestrationResult result = DocumentLifecycleOrchestrator.executeFullLifecycleOrchestration('invalid_id');
        
        Test.stopTest();
        
        System.assert(!result.success, 'Should fail with invalid document ID');
        System.assertNotEquals(null, result.errorMessage, 'Error message should be present');
        System.assertEquals('FAILED', result.orchestrationStatus, 'Status should be FAILED');
    }
    
    @isTest
    static void testPerformanceAndScalability() {
        // Create multiple test documents
        List<ContentVersion> testVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 5; i++) {
            testVersions.add(new ContentVersion(
                Title = 'Performance Test Doc ' + i,
                PathOnClient = 'test' + i + '.pdf',
                VersionData = Blob.valueOf('Test content for performance testing ' + i),
                IsMajorVersion = true
            ));
        }
        insert testVersions;
        
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Title LIKE 'Performance Test Doc%'];
        
        Test.startTest();
        
        Integer startTime = System.currentTimeMillis();
        
        // Process multiple documents
        List<DocumentLifecycleRequest> requests = new List<DocumentLifecycleRequest>();
        for (ContentDocument doc : docs) {
            DocumentLifecycleRequest request = new DocumentLifecycleRequest();
            request.documentId = doc.Id;
            request.enableAdvancedAnalytics = false; // Disable for performance testing
            requests.add(request);
        }
        
        List<DocumentLifecycleResult> results = DocumentLifecycleSystemIntegrator.executeCompleteLifecycleManagement(requests);
        
        Integer endTime = System.currentTimeMillis();
        Integer executionTime = endTime - startTime;
        
        Test.stopTest();
        
        System.assertEquals(docs.size(), results.size(), 'Should process all documents');
        
        // Verify all succeeded
        for (DocumentLifecycleResult result : results) {
            System.assert(result.success, 'Each document processing should succeed');
        }
        
        // Performance should be reasonable (this is environment dependent)
        System.debug('Total execution time for ' + docs.size() + ' documents: ' + executionTime + 'ms');
    }
}
