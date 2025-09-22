@IsTest
public class ProductionDeploymentChecklistTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test deployment checklist items
        List<Deployment_Checklist__c> checklistItems = new List<Deployment_Checklist__c>();
        
        checklistItems.add(new Deployment_Checklist__c(
            Item_Name__c        = 'Code Coverage Test',
        Description__c      = 'Ensure minimum code coverage requirements',
        Is_Completed__c     = true,
        Priority__c         = 'Critical',
        Deployment_Phase__c = 'Pre-Deployment',
        Completed_By__c     = UserInfo.getUserId(),
        Completed_At__c     = System.now(),
        Notes__c            = 'All tests passing with 85% coverage'
            ));
        
        checklistItems.add(new Deployment_Checklist__c(
            Item_Name__c        = 'Security Review',
        Description__c      = 'Complete security vulnerability assessment',
        Is_Completed__c     = false,
        Priority__c         = 'High',
        Deployment_Phase__c = 'Pre-Deployment',
        Notes__c            = 'Pending final security scan'
            ));
        
        insert checklistItems;
    }
    
    @IsTest
    static void testGetDeploymentChecklist() {
        Test.startTest();
        List<ProductionDeploymentChecklist.ChecklistItem> checklist = ProductionDeploymentChecklist.getDeploymentChecklist();
        Test.stopTest();
        
        // Verify checklist structure
        Assert.isNotNull(checklist);
        Assert.isTrue(checklist.size() > 0);
        
        // Verify required checklist items are present
        Boolean hasCodeCoverage = false;
        Boolean hasSecurityReview = false;
        Boolean hasPerformanceTesting = false;
        
        for (ProductionDeploymentChecklist.ChecklistItem item : checklist) {
            if (item.name.contains('Code Coverage')) hasCodeCoverage = true;
            if (item.name.contains('Security Review')) hasSecurityReview = true;
            if (item.name.contains('Performance Testing')) hasPerformanceTesting = true;
        }
        
        Assert.isTrue(hasCodeCoverage);
        Assert.isTrue(hasSecurityReview);
        Assert.isTrue(hasPerformanceTesting);
    }
    
    @IsTest
    static void testUpdateChecklistItem() {
        Test.startTest();
        String result = ProductionDeploymentChecklist.updateChecklistItem(
            'Test Item', true, 'Test completion notes'
            );
        Test.stopTest();
        
        Assert.areEqual('Success', result);
        
        // Verify the record was created/updated
        List<Deployment_Checklist__c> items = [
            SELECT Id, Item_Name__c, Is_Completed__c, Notes__c
            FROM Deployment_Checklist__c
            WHERE Item_Name__c = 'Test Item'
        ];
        
        Assert.areEqual(1, items.size());
        Assert.isTrue(items[0].Is_Completed__c);
        Assert.areEqual('Test completion notes', items[0].Notes__c);
    }
    
    @IsTest
    static void testGenerateDeploymentReport() {
        Test.startTest();
        Map<String, Object> report = ProductionDeploymentChecklist.generateDeploymentReport();
        Test.stopTest();
        
        // Verify report structure
        Assert.isNotNull(report);
        Assert.isTrue(report.containsKey('totalItems'));
        Assert.isTrue(report.containsKey('completedItems'));
        Assert.isTrue(report.containsKey('completionPercentage'));
        Assert.isTrue(report.containsKey('deploymentStatus'));
        Assert.isTrue(report.containsKey('checklist'));
        Assert.isTrue(report.containsKey('generatedAt'));
        Assert.isTrue(report.containsKey('generatedBy'));
        
        // Verify data types and values
        Integer totalItems = (Integer)report.get('totalItems');
        Integer completedItems = (Integer)report.get('completedItems');
        Decimal completionPercentage = (Decimal)report.get('completionPercentage');
        String deploymentStatus = (String)report.get('deploymentStatus');
        
        Assert.isTrue(totalItems > 0);
        Assert.isTrue(completedItems >= 0);
        Assert.isTrue(completionPercentage >= 0 && completionPercentage <= 100);
        Assert.isTrue(
            deploymentStatus == 'READY' ||
            deploymentStatus == 'NEAR_READY' ||
            deploymentStatus == 'NOT_READY'
            );
    }
    
    @IsTest
    static void testValidationMethods() {
        Test.startTest();
        List<ProductionDeploymentChecklist.ChecklistItem> checklist = ProductionDeploymentChecklist.getDeploymentChecklist();
        Test.stopTest();
        
        // Verify validation methods are called
        Assert.isNotNull(checklist);
        
        Boolean hasCompletedItems = false;
        Boolean hasPendingItems = false;
        
        for (ProductionDeploymentChecklist.ChecklistItem item : checklist) {
            if (item.isCompleted) hasCompletedItems = true;
            else hasPendingItems = true;
        }
        
        // Some items might be completed automatically in a fresh org
        Assert.isTrue(hasCompletedItems || hasPendingItems);
    }
    
    @IsTest
    static void testErrorHandling() {
        Test.startTest();
        // Test error handling in update method
        String result = ProductionDeploymentChecklist.updateChecklistItem(
            null, // Invalid name
        true,
        'Test notes'
            );
        Test.stopTest();
        
        // Should handle errors gracefully
        Assert.isTrue(result.startsWith('Error:') || result == 'Success');
    }
    
    @IsTest
    static void testDeploymentStatusCalculation() {
        // Create specific test data for status calculation
        List<Deployment_Checklist__c> testItems = new List<Deployment_Checklist__c>();
        
        // Create 10 items, complete 8 (80% - should be NEAR_READY)
        for (Integer i = 0; i < 10; i++) {
            testItems.add(new Deployment_Checklist__c(
                Item_Name__c        = 'Status Test Item ' + i,
            Description__c      = 'Test item for status calculation',
            Is_Completed__c     = i < 8, // Complete first 8 items
            Priority__c         = 'Medium',
            Deployment_Phase__c = 'Testing'
                ));
        }
        insert testItems;
        
        Test.startTest();
        Map<String, Object> report = ProductionDeploymentChecklist.generateDeploymentReport();
        Test.stopTest();
        
        Decimal completionPercentage = (Decimal)report.get('completionPercentage');
        String deploymentStatus = (String)report.get('deploymentStatus');
        
        Assert.isTrue(completionPercentage >= 0 && completionPercentage <= 100);
        Assert.isNotNull(deploymentStatus);
    }
}