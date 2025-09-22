@isTest
public class ComplianceCheckerTest {
    @testSetup
    static void setupTestData() {
        ComplianceRule__c rule = new ComplianceRule__c(
            RequiredKeyword__c = 'employment',
            Region__c = 'US',
            DocumentType__c = 'Employment',
            IsActive__c = true
        );
        insert rule;
    }
    
    @isTest
    static void testComplianceValidation() {
        String compliantClause = 'This employment agreement follows US laws';
        
        Test.startTest();
        Boolean result = ComplianceChecker.validateClause(compliantClause, 'US', 'Employment');
        Test.stopTest();
        
        System.assertEquals(true, result);
        
        // Verify audit trail
        List<AuditTrail__c> audits = [SELECT Action__c FROM AuditTrail__c];
        System.assertEquals(1, audits.size());
        System.assertEquals('Compliance Check Passed', audits[0].Action__c);
    }
}



// version v4

// @isTest
// public class ComplianceCheckerTest {
    
//     @testSetup
//     static void setupTestData() {
//         ComplianceRule__c rule = new ComplianceRule__c(
//             RuleName__c = &#39;US Employment Rule&#39;,
//             Region__c = &#39;US&#39;,
//             DocumentType__c = &#39;Employment&#39;,
//             RequiredKeywords__c = &#39;authorized signatory;US employment laws&#39;,
//             IsActive__c = true
//         );
//         insert rule;
//     }
    
//     @isTest
//     static void testComplianceValidation() {
//         String compliantClause = &#39;This agreement includes authorized signatory rights under US employment laws.&#39;;
        
//         Test.startTest();
//         Boolean isCompliant = ComplianceChecker.validateClause(compliantClause, &#39;US&#39;, &#39;Employment&#39;);
//         Test.stopTest();
        
//         System.assertEquals(true, isCompliant, &#39;Compliant clause should pass validation&#39;);
        
//         // Verify audit trail
//         List<AuditTrail__c> audits = [SELECT Id FROM AuditTrail__c WHERE EventType__c = 'Compliance Success'];
//         System.assertEquals(1, audits.size(), 'Should log compliance success');
//     }
    
//     @isTest
//     static void testComplianceFailure() {
//         String nonCompliantClause = 'This is a basic agreement without required terms.';
        
//         Test.startTest();
//         Boolean isCompliant = ComplianceChecker.validateClause(nonCompliantClause, 'US', 'Employment');
//         Test.stopTest();
        
//         System.assertEquals(false, isCompliant, 'Non-compliant clause should fail validation');
        
//         // Verify violation audit trail
//         List<AuditTrail__c> violations = [SELECT Id FROM AuditTrail__c WHERE EventType__c = 'Compliance Violation'];
//         System.assert(violations.size() > 0, 'Should log compliance violations');
//     }
// }
