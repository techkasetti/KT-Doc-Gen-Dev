@isTest
public class DocumentLifecycleDeploymentManagerTest {
    @isTest
    static void testSystemInitialization() {
        Test.startTest();
        DocumentLifecycleDeploymentManager.initializeCompleteSystem();
        Test.stopTest();
        
        // Verify configurations created
        List<DocumentLifecycleConfiguration__c> configs = [
            SELECT Region__c, Role__c 
            FROM DocumentLifecycleConfiguration__c
        ];
        System.assertEquals(2, configs.size());
        
        // Verify audit trail
        List<AuditTrail__c> audits = [
            SELECT Action__c 
            FROM AuditTrail__c 
            WHERE Action__c = 'System Initialization'
        ];
        System.assertEquals(1, audits.size());
    }
}



// version v4

// @isTest
// public class DocumentLifecycleDeploymentManagerTest {
    
//     @isTest
//     static void testSystemInitialization() {
//         Test.startTest();
//         DocumentLifecycleDeploymentManager.initializeCompleteSystem();
//         Test.stopTest();
        
//         // Verify configurations created
//         List&lt;DocumentLifecycleConfiguration__c&gt; configs = [
//             SELECT Id, Region__c, ComplianceStatus__c 
//             FROM DocumentLifecycleConfiguration__c
//         ];
//         System.assertEquals(2, configs.size(), &#39;Should create 2 configurations&#39;);
        
//         // Verify audit trail
//         List&lt;AuditTrail__c&gt; audits = [
//             SELECT Id, EventType__c 
//             FROM AuditTrail__c 
//             WHERE EventType__c = &#39;System Initialization&#39;
//         ];
//         System.assertEquals(1, audits.size(), &#39;Should create audit trail entry&#39;);
//     }
// }



// version v5

// @isTest
// public class DocumentLifecycleDeploymentManagerTest {
    
//     @isTest
//     static void testSystemInitialization() {
//         Test.startTest();
//         String result = DocumentLifecycleDeploymentManager.initializeCompleteSystem();
//         Test.stopTest();
        
//         System.assertEquals('System initialized successfully', result);
        
//         // Verify configurations created
//         List<DocumentLifecycleConfiguration__c> configs = 
//             [SELECT Id FROM DocumentLifecycleConfiguration__c];
//         System.assertEquals(2, configs.size());
        
//         // Verify audit trail
//         List<AuditTrail__c> audits = [SELECT Id FROM AuditTrail__c];
//         System.assertEquals(1, audits.size());
//     }
// }


// version v6

// @isTest
// public class DocumentLifecycleDeploymentManagerTest {
    
//     @isTest
//     static void testSystemInitialization() {
//         Test.startTest();
//         DocumentLifecycleDeploymentManager.initializeCompleteSystem();
//         Test.stopTest();
        
//         // Verify configurations created
//         List<DocumentLifecycleConfiguration__c> configs = [SELECT Id FROM DocumentLifecycleConfiguration__c];
//         System.assertEquals(2, configs.size(), 'Should create 2 configurations');
        
//         // Verify audit trail
//         List<AuditTrail__c> audits = [SELECT Id FROM AuditTrail__c WHERE Action__c = 'SYSTEM_INITIALIZATION'];
//         System.assertEquals(1, audits.size(), 'Should create 1 audit record');
//     }
// }
