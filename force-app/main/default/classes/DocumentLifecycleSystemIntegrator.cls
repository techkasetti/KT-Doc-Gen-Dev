// Complete system integration wrapper
public class DocumentLifecycleSystemIntegrator {
    
    @InvocableMethod(label='Execute Complete Document Lifecycle Management' description='Executes comprehensive document lifecycle management for specified documents')
    public static List<DocumentLifecycleResult> executeCompleteLifecycleManagement(List<DocumentLifecycleRequest> requests) {
        List<DocumentLifecycleResult> results = new List<DocumentLifecycleResult>();
        
        for (DocumentLifecycleRequest request : requests) {
            DocumentLifecycleResult result = new DocumentLifecycleResult();
            result.documentId = request.documentId;
            result.requestId = request.requestId;
            result.startTime = DateTime.now();
            
            try {
                // Execute orchestration
                OrchestrationResult orchestrationResult = DocumentLifecycleOrchestrator.executeFullLifecycleOrchestration(request.documentId);
                
                // Map orchestration result to lifecycle result
                result.success = orchestrationResult.success;
                result.orchestrationStatus = orchestrationResult.orchestrationStatus;
                result.complianceScore = orchestrationResult.complianceScore;
                result.processingTime = orchestrationResult.totalOrchestrationTime;
                result.phasesExecuted = orchestrationResult.phaseResults.size();
                result.successfulPhases = countSuccessfulPhases(orchestrationResult.phaseResults);
                result.failedPhases = countFailedPhases(orchestrationResult.phaseResults);
                result.auditTrailId = orchestrationResult.auditTrailId;
                result.errorMessage = orchestrationResult.errorMessage;
                
                // Execute additional integrations if requested
                if (request.enableAdvancedAnalytics) {
                    executeAdvancedAnalytics(request.documentId, result);
                }
                
                if (request.enableRealTimeMonitoring) {
                    enableRealTimeMonitoring(request.documentId, result);
                }
                
                if (request.generateComprehensiveReport) {
                    generateComprehensiveReport(request.documentId, result);
                }
                
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = e.getMessage();
                result.stackTrace = e.getStackTraceString();
            }
            
            result.endTime = DateTime.now();
            result.totalExecutionTime = result.endTime.getTime() - result.startTime.getTime();
            
            results.add(result);
        }
        
        return results;
    }
    
    private static void executeAdvancedAnalytics(Id documentId, DocumentLifecycleResult result) {
        try {
            // Execute advanced analytics
            DocumentAnalyticsEngine.enhanceDocumentIntelligence(new Set<Id>{documentId});
            result.advancedAnalyticsEnabled = true;
        } catch (Exception e) {
            result.analyticsError = e.getMessage();
        }
    }
    
    private static void enableRealTimeMonitoring(Id documentId, DocumentLifecycleResult result) {
        try {
            // Enable real-time monitoring
            insert new DocumentRealTimeMonitoring__c(
                Document_Id__c = documentId,
                Monitoring_Enabled__c = true,
                Alert_Threshold__c = 'MEDIUM',
                Notification_Frequency__c = 'DAILY',
                Last_Check__c = DateTime.now(),
                Status__c = 'ACTIVE'
            );
            result.realTimeMonitoringEnabled = true;
        } catch (Exception e) {
            result.monitoringError = e.getMessage();
        }
    }
}
