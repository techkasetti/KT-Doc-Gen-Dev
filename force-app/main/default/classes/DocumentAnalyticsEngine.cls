public with sharing class DocumentAnalyticsEngine {
    
    @AuraEnabled(cacheable=true)
    public static DocumentAnalytics getDocumentAnalytics(Id documentId) {
        try {
            DocumentAnalytics analytics = new DocumentAnalytics();
            
            // Get view analytics
            analytics.viewMetrics = getViewMetrics(documentId);
            
            // Get compliance analytics
            analytics.complianceMetrics = getComplianceMetrics(documentId);
            
            // Get collaboration analytics
            analytics.collaborationMetrics = getCollaborationMetrics(documentId);
            
            // Get performance metrics
            analytics.performanceMetrics = getPerformanceMetrics(documentId);
            
            return analytics;
            
        } catch (Exception e) {
            throw new AuraHandledException('Analytics generation failed: ' + e.getMessage());
        }
    }
    
    private static ViewMetrics getViewMetrics(Id documentId) {
        ViewMetrics metrics = new ViewMetrics();
        
        List<AggregateResult> viewStats = [
            SELECT COUNT(Id) totalViews, 
                   AVG(Session_Duration__c) avgDuration,
                   COUNT(DISTINCT User_ID__c) uniqueUsers
            FROM DocumentViewTracking__c 
            WHERE Document_ID__c = :documentId
        ];
        
        if (!viewStats.isEmpty()) {
            AggregateResult stats = viewStats[0];
            metrics.totalViews = (Integer)stats.get('totalViews');
            metrics.averageDuration = (Decimal)stats.get('avgDuration');
            metrics.uniqueUsers = (Integer)stats.get('uniqueUsers');
        }
        
        // Get recent view activity (last 7 days)
        metrics.recentViews = [
            SELECT User_ID__c, View_Date__c, Session_Duration__c
            FROM DocumentViewTracking__c 
            WHERE Document_ID__c = :documentId 
            AND View_Date__c >= :Date.today().addDays(-7)
            ORDER BY View_Date__c DESC
        ];
        
        return metrics;
    }
    
    private static ComplianceMetrics getComplianceMetrics(Id documentId) {
        ComplianceMetrics metrics = new ComplianceMetrics();
        
        List<DocumentComplianceTracking__c> complianceHistory = [
            SELECT Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c, 
                   Analysis_Date__c
            FROM DocumentComplianceTracking__c 
            WHERE Document_ID__c = :documentId 
            ORDER BY Analysis_Date__c DESC
        ];
        
        if (!complianceHistory.isEmpty()) {
            DocumentComplianceTracking__c latest = complianceHistory[0];
            metrics.currentScore = latest.Compliance_Score__c;
            metrics.gdprCompliant = latest.GDPR_Compliant__c;
            metrics.hipaaCompliant = latest.HIPAA_Compliant__c;
            metrics.lastAnalysisDate = latest.Analysis_Date__c;
            
            // Calculate compliance trend
            if (complianceHistory.size() > 1) {
                Decimal previousScore = complianceHistory[1].Compliance_Score__c;
                metrics.scoreTrend = latest.Compliance_Score__c - previousScore;
            }
        }
        
        metrics.complianceHistory = complianceHistory;
        
        return metrics;
    }
    
    private static CollaborationMetrics getCollaborationMetrics(Id documentId) {
        CollaborationMetrics metrics = new CollaborationMetrics();
        
        // Get collaborator count
        List<ContentDocumentLink> links = [
            SELECT LinkedEntityId, LinkedEntity.Type, ShareType
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :documentId
        ];
        
        metrics.totalCollaborators = links.size();
        metrics.shareTypes = new Map<String, Integer>();
        
        for (ContentDocumentLink link : links) {
            String shareType = link.ShareType;
            if (metrics.shareTypes.containsKey(shareType)) {
                metrics.shareTypes.put(shareType, metrics.shareTypes.get(shareType) + 1);
            } else {
                metrics.shareTypes.put(shareType, 1);
            }
        }
        
        return metrics;
    }
    
    private static PerformanceMetrics getPerformanceMetrics(Id documentId) {
        PerformanceMetrics metrics = new PerformanceMetrics();
        
        // Get document size and processing metrics
        List<ContentDocument> docs = [
            SELECT ContentSize, CreatedDate, LastModifiedDate
            FROM ContentDocument 
            WHERE Id = :documentId
        ];
        
        if (!docs.isEmpty()) {
            ContentDocument doc = docs[0];
            metrics.documentSize = doc.ContentSize;
            metrics.createdDate = doc.CreatedDate;
            metrics.lastModifiedDate = doc.LastModifiedDate;
            
            // Calculate processing time estimate based on size
            metrics.estimatedProcessingTime = calculateProcessingTime(doc.ContentSize);
        }
        
        return metrics;
    }
    
    private static Decimal calculateProcessingTime(Integer contentSize) {
        // Base processing time calculation (simplified)
        Decimal baseTime = 2.0; // 2 seconds base
        Decimal sizeMultiplier = contentSize / 1000000.0; // Per MB
        return baseTime + (sizeMultiplier * 0.5);
    }
    
    // Wrapper Classes
    public class DocumentAnalytics {
        @AuraEnabled public ViewMetrics viewMetrics { get; set; }
        @AuraEnabled public ComplianceMetrics complianceMetrics { get; set; }
        @AuraEnabled public CollaborationMetrics collaborationMetrics { get; set; }
        @AuraEnabled public PerformanceMetrics performanceMetrics { get; set; }
    }
    
    public class ViewMetrics {
        @AuraEnabled public Integer totalViews { get; set; }
        @AuraEnabled public Decimal averageDuration { get; set; }
        @AuraEnabled public Integer uniqueUsers { get; set; }
        @AuraEnabled public List<DocumentViewTracking__c> recentViews { get; set; }
    }
    
    public class ComplianceMetrics {
        @AuraEnabled public Decimal currentScore { get; set; }
        @AuraEnabled public Boolean gdprCompliant { get; set; }
        @AuraEnabled public Boolean hipaaCompliant { get; set; }
        @AuraEnabled public DateTime lastAnalysisDate { get; set; }
        @AuraEnabled public Decimal scoreTrend { get; set; }
        @AuraEnabled public List<DocumentComplianceTracking__c> complianceHistory { get; set; }
    }
    
    public class CollaborationMetrics {
        @AuraEnabled public Integer totalCollaborators { get; set; }
        @AuraEnabled public Map<String, Integer> shareTypes { get; set; }
    }
    
    public class PerformanceMetrics {
        @AuraEnabled public Integer documentSize { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
        @AuraEnabled public Decimal estimatedProcessingTime { get; set; }
    }
}
