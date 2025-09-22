@isTest  
public class ClauseGeneratorTest {
    @isTest
    static void testClauseGeneration() {
        Test.startTest();
        String clause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
        Test.stopTest();
        
        System.assertNotEquals(null, clause);
        System.assert(clause.contains('authorized signatory'));
        System.assert(clause.contains('US employment laws'));
        
        // Verify logging
        List<ClauseLibrary__c> logs = [SELECT GeneratedClause__c FROM ClauseLibrary__c];
        System.assertEquals(1, logs.size());
    }
}

// version v4


// @isTest
// public class ClauseGeneratorTest {
    
//     @isTest
//     static void testClauseGeneration() {
//         Test.startTest();
        
//         String clause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
        
//         Test.stopTest();
        
//         // Verify clause was generated
//         System.assertNotEquals(null, clause, 'Clause should be generated');
//         System.assert(clause.contains('authorized signatory'), 'Should include role-specific terms');
//         System.assert(clause.contains('US employment laws'), 'Should include region-specific terms');
        
//         // Verify audit trail
//         List<AuditTrail__c> audits = [
//             SELECT Id
//             FROM AuditTrail__c
//             WHERE EventType__c = 'Clause Generation'
//         ];
        
//         System.assertEquals(1, audits.size(), 'Should log clause generation');
//     }
// }


// version v5 


// @isTest
// public class ClauseGeneratorTest {
    
//     @isTest
//     static void testClauseGeneration() {
//         Test.startTest();
//         String clause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
//         Test.stopTest();
        
//         System.assert(clause.contains('authorized signatory'));
//         System.assert(clause.contains('US employment laws'));
        
//         // Verify audit log created
//         List<AuditTrail__c> audits = [SELECT Id FROM AuditTrail__c WHERE Action__c = 'Clause Generated'];
//         System.assertEquals(1, audits.size());
//     }
// }


// version v6

// @isTest
// public class ClauseGeneratorTest {
    
//     @isTest
//     static void testClauseGeneration() {
//         Test.startTest();
//         String clause = ClauseGenerator.generateClause('US', 'Manager', 'Employment');
//         Test.stopTest();
        
//         // Verify clause content
//         System.assert(clause.contains('authorized signatory'), 'Should contain manager-specific terms');
//         System.assert(clause.contains('US employment laws'), 'Should contain region-specific terms');
        
//         // Verify audit log created
//         List<AuditTrail__c> audits = [SELECT Id FROM AuditTrail__c WHERE Action__c = 'CLAUSE_GENERATED'];
//         System.assertEquals(1, audits.size(), 'Should create audit log');
//     }
// }


