// Document Expiration Management System
public class DocumentExpirationEngine {

    @future(callout=false)
    public static void processExpiringDocuments(Set<Id> documentIds) {
        for (Id docId : documentIds) {
            try {
                processDocumentExpiration(docId);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to process expiration for document ' + docId + ': ' + e.getMessage());

                // Log expiration processing error
                insert new DocumentExpirationError__c(
                    Document_Id__c = docId,
                    Error_Type__c = 'EXPIRATION_PROCESSING_FAILURE',
                    Error_Message__c = e.getMessage(),
                    Stack_Trace__c = e.getStackTraceString(),
                    Timestamp__c = DateTime.now(),
                    Status__c = 'PENDING_RETRY'
                );
            }
        }
    }

    private static void processDocumentExpiration(Id documentId) {
        // Get document expiration policy
        DocumentExpirationPolicy__c policy = [
            SELECT Id, Expiration_Date__c, Warning_Period_Days__c, Auto_Archive__c, 
                   Auto_Delete__c, Notification_Recipients__c, Grace_Period_Days__c,
                   Expiration_Action__c, Business_Justification_Required__c
            FROM DocumentExpirationPolicy__c 
            WHERE Document_Id__c = :documentId 
            LIMIT 1
        ];

        Date today = Date.today();
        Date expirationDate = policy.Expiration_Date__c;
        Date warningDate = expirationDate.addDays(-(Integer)policy.Warning_Period_Days__c);

        ExpirationProcessingResult result = new ExpirationProcessingResult();
        result.documentId = documentId;
        result.policyId = policy.Id;
        result.processingStartTime = DateTime.now();
        result.currentDate = today;
        result.expirationDate = expirationDate;

        try {
            // Determine expiration status
            if (today.daysBetween(expirationDate) <= 0) {
                // Document has expired
                result.expirationStatus = 'EXPIRED';
                result.daysOverdue = today.daysBetween(expirationDate) * -1;

                // Check if still within grace period
                Date gracePeriodEnd = expirationDate.addDays((Integer)policy.Grace_Period_Days__c);
                if (today <= gracePeriodEnd) {
                    result.withinGracePeriod = true;
                    result.graceDaysRemaining = today.daysBetween(gracePeriodEnd);
                } else {
                    result.withinGracePeriod = false;
                    result.graceDaysExceeded = gracePeriodEnd.daysBetween(today);
                }

                // Execute expiration actions
                executeExpirationActions(documentId, policy, result);

            } else if (today >= warningDate) {
                // Document is in warning period
                result.expirationStatus = 'WARNING';
                result.daysUntilExpiration = today.daysBetween(expirationDate);

                // Send warning notifications
                sendExpirationWarnings(documentId, policy, result);

            } else {
                // Document is still valid
                result.expirationStatus = 'VALID';
                result.daysUntilWarning = today.daysBetween(warningDate);
                result.daysUntilExpiration = today.daysBetween(expirationDate);
            }

            // Update document expiration tracking
            updateExpirationTracking(documentId, result);

            result.success = true;

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.stackTrace = e.getStackTraceString();
        }

        result.processingEndTime = DateTime.now();
        result.totalProcessingTime = result.processingEndTime.getTime() - result.processingStartTime.getTime();

        // Log processing result
        logExpirationProcessingResult(result);
    }

    private static void executeExpirationActions(Id documentId, DocumentExpirationPolicy__c policy, ExpirationProcessingResult result) {
        List<String> actionsExecuted = new List<String>();

        try {
            // Action 1: Document Access Restriction
            if (policy.Expiration_Action__c.contains('RESTRICT_ACCESS')) {
                restrictDocumentAccess(documentId);
                actionsExecuted.add('ACCESS_RESTRICTED');
            }

            // Action 2: Automatic Archival
            if (policy.Auto_Archive__c && policy.Expiration_Action__c.contains('AUTO_ARCHIVE')) {
                ArchivalResult archivalResult = archiveExpiredDocument(documentId, policy);
                if (archivalResult.success) {
                    actionsExecuted.add('ARCHIVED');
                    result.archivalReferenceId = archivalResult.archiveReferenceId;
                } else {
                    result.archivalError = archivalResult.errorMessage;
                }
            }

            // Action 3: Automatic Deletion (only if archival successful or not required)
            if (policy.Auto_Delete__c && 
                policy.Expiration_Action__c.contains('AUTO_DELETE') && 
                (!policy.Auto_Archive__c || result.archivalReferenceId != null)) {

                DeletionResult deletionResult = deleteExpiredDocument(documentId, policy);
                if (deletionResult.success) {
                    actionsExecuted.add('DELETED');
                    result.documentDeleted = true;
                } else {
                    result.deletionError = deletionResult.errorMessage;
                }
            }

            // Action 4: Stakeholder Notifications
            if (policy.Expiration_Action__c.contains('NOTIFY_STAKEHOLDERS')) {
                sendExpirationNotifications(documentId, policy, result);
                actionsExecuted.add('STAKEHOLDERS_NOTIFIED');
            }

            // Action 5: Compliance Violation Logging
            if (policy.Business_Justification_Required__c) {
                createComplianceViolationRecord(documentId, policy, result);
                actionsExecuted.add('COMPLIANCE_VIOLATION_LOGGED');
            }

            result.actionsExecuted = actionsExecuted;

        } catch (Exception e) {
            result.actionExecutionError = e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Failed to execute expiration actions: ' + e.getMessage());
        }
    }

    private static void updateExpirationTracking(Id documentId, ExpirationProcessingResult result) {
        // Upsert expiration tracking record
        List<DocumentExpirationTracking__c> existingTracking = [
            SELECT Id FROM DocumentExpirationTracking__c 
            WHERE Document_Id__c = :documentId LIMIT 1
        ];

        DocumentExpirationTracking__c tracking;
        if (!existingTracking.isEmpty()) {
            tracking = existingTracking[0];
        } else {
            tracking = new DocumentExpirationTracking__c(
                Document_Id__c = documentId
            );
        }

        tracking.Expiration_Status__c = result.expirationStatus;
        tracking.Days_Until_Expiration__c = result.daysUntilExpiration;
        tracking.Days_Overdue__c = result.daysOverdue;
        tracking.Within_Grace_Period__c = result.withinGracePeriod;
        tracking.Grace_Days_Remaining__c = result.graceDaysRemaining;
        tracking.Last_Check_Date__c = result.currentDate;
        tracking.Last_Processing_Time__c = DateTime.now();
        tracking.Actions_Executed__c = String.join(result.actionsExecuted, ';');
        tracking.Document_Deleted__c = result.documentDeleted;
        tracking.Archival_Reference_Id__c = result.archivalReferenceId;

        upsert tracking;
        result.trackingRecordId = tracking.Id;
    }
}
