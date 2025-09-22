@isTest
public class DocumentGenerationControllerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test template
        DocumentTemplate__c template = new DocumentTemplate__c(
            Name = 'Test Employment Template',
            TemplateType__c = 'Employment',
            Region__c = 'US',
            Description__c = 'Test template for employment contracts',
            IsActive__c = true
        );
        insert template;
    }
    
    @isTest
    static void testCreateDocumentRequest() {
        Test.startTest();
        
        String docId = DocumentGenerationController.createDocumentRequest(
            'Employment',
            'US', 
            'Manager',
            'This is a test employment clause',
            'Additional test requirements',
            'Compliant'
        );
        
        Test.stopTest();
        
        // Verify document request created
        DocumentLifecycleConfiguration__c doc = [
            SELECT Region__c, Role__c, ContractType__c, ComplianceStatus__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :docId
        ];
        
        System.assertEquals('US', doc.Region__c);
        System.assertEquals('Manager', doc.Role__c);
        System.assertEquals('Employment', doc.ContractType__c);
        System.assertEquals('Compliant', doc.ComplianceStatus__c);
        
        // Verify audit trail created
        List<AuditTrail__c> audits = [
            SELECT Action__c FROM AuditTrail__c 
            WHERE RelatedRecordId__c = :docId
        ];
        System.assertEquals(1, audits.size());
        System.assertEquals('Document Request Created', audits[0].Action__c);
    }
    
    @isTest
    static void testGetAvailableTemplates() {
        Test.startTest();
        
        List<Map<String, Object>> templates = 
            DocumentGenerationController.getAvailableTemplates('Employment', 'US');
        
        Test.stopTest();
        
        System.assert(templates.size() > 0);
        System.assertEquals('Test Employment Template', templates[0].get('name'));
        System.assertEquals('Employment', templates[0].get('type'));
        System.assertEquals('US', templates[0].get('region'));
    }
}
