// Advanced monitoring and alerting system
public class DocumentLifecycleMonitoringSystem {
    
    // Scheduled monitoring job
    @future(callout=false)
    public static void executeScheduledMonitoring() {
        try {
            // Monitor expiring documents
            monitorExpiringDocuments();
            
            // Monitor retention compliance
            monitorRetentionCompliance();
            
            // Monitor AI processing health
            monitorAIProcessingHealth();
            
            // Monitor system performance
            monitorSystemPerformance();
            
            // Generate daily summary report
            generateDailySummaryReport();
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Scheduled monitoring failed: ' + e.getMessage());
            createSystemAlert('MONITORING_SYSTEM_FAILURE', e.getMessage(), 'CRITICAL');
        }
    }
    
    private static void monitorExpiringDocuments() {
        // Find documents expiring within next 30 days
        List<DocumentExpirationTracking__c> expiringDocs = [
            SELECT Document_Id__c, Days_Until_Expiration__c, Expiration_Status__c
            FROM DocumentExpirationTracking__c
            WHERE Days_Until_Expiration__c <= 30
            AND Days_Until_Expiration__c > 0
            AND Expiration_Status__c != 'EXPIRED'
        ];
        
        for (DocumentExpirationTracking__c doc : expiringDocs) {
            if (doc.Days_Until_Expiration__c <= 7) {
                createSystemAlert(
                    'DOCUMENT_EXPIRING_SOON',
                    'Document expiring in ' + doc.Days_Until_Expiration__c + ' days',
                    'HIGH'
                );
            } else if (doc.Days_Until_Expiration__c <= 30) {
                createSystemAlert(
                    'DOCUMENT_EXPIRING',
                    'Document expiring in ' + doc.Days_Until_Expiration__c + ' days',
                    'MEDIUM'
                );
            }
        }
    }
    
    private static void monitorRetentionCompliance() {
        // Find documents with retention violations
        List<DocumentRetentionSchedule__c> violatingDocs = [
            SELECT Document_Id__c, Retention_End_Date__c, Status__c
            FROM DocumentRetentionSchedule__c
            WHERE Retention_End_Date__c <= TODAY
            AND Status__c = 'ACTIVE'
        ];
        
        for (DocumentRetentionSchedule__c doc : violatingDocs) {
            Integer daysOverdue = doc.Retention_End_Date__c.daysBetween(Date.today());
            createSystemAlert(
                'RETENTION_VIOLATION',
                'Document retention period exceeded by ' + daysOverdue + ' days',
                daysOverdue > 30 ? 'CRITICAL' : 'HIGH'
            );
        }
    }
    
    private static void createSystemAlert(String alertType, String message, String priority) {
        insert new SystemAlert__c(
            Alert_Type__c = alertType,
            Alert_Message__c = message,
            Priority__c = priority,
            Status__c = 'ACTIVE',
            Created_Date__c = DateTime.now(),
            Requires_Action__c = true
        );
    }
}
