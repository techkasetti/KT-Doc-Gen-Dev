public class AdvancedRetentionOrchestrator {

    public static void executeRetentionWorkflow(String policyId) {
        DocumentRetentionPolicy__c policy = getRetentionPolicy(policyId);
        List<ContentDocument> eligibleDocuments = findEligibleDocuments(policy);

        for (ContentDocument doc : eligibleDocuments) {
            RetentionExecutionResult result = processDocumentRetention(doc, policy);
            logRetentionExecution(result);
        }
    }

    private static RetentionExecutionResult processDocumentRetention(ContentDocument doc, DocumentRetentionPolicy__c policy) {
        RetentionExecutionResult result = new RetentionExecutionResult();
        result.documentId = doc.Id;
        result.policyId = policy.Id;
        result.executionStartTime = DateTime.now();

        try {
            // Step 1: Legal Hold Check
            Boolean isUnderLegalHold = checkLegalHoldStatus(doc.Id);
            result.legalHoldStatus = isUnderLegalHold;

            if (isUnderLegalHold) {
                result.action = 'SKIPPED_LEGAL_HOLD';
                result.status = 'COMPLETED';
                return result;
            }

            // Step 2: Pre-Archival Validation
            ValidationResult validation = validateDocumentForArchival(doc, policy);
            result.validationResult = validation;

            if (!validation.isValid) {
                result.action = 'VALIDATION_FAILED';
                result.status = 'FAILED';
                result.errorMessage = validation.errorMessage;
                return result;
            }

            // Step 3: Create Archival Record
            DocumentArchivalRecord__c archivalRecord = createArchivalRecord(doc, policy);

            // Step 4: Execute Archival Process
            if (policy.Archive_Before_Deletion__c) {
                ArchivalResult archivalResult = executeDocumentArchival(doc, policy, archivalRecord);
                result.archivalResult = archivalResult;

                if (!archivalResult.success) {
                    result.status = 'FAILED';
                    result.errorMessage = archivalResult.errorMessage;
                    return result;
                }
            }

            // Step 5: Document Deletion (if enabled)
            if (policy.Auto_Delete_Enabled__c && !policy.Pre_Deletion_Review__c) {
                DeletionResult deletionResult = executeDocumentDeletion(doc, policy, archivalRecord);
                result.deletionResult = deletionResult;

                if (deletionResult.success) {
                    archivalRecord.Original_Document_Deleted__c = true;
                    archivalRecord.Deletion_Timestamp__c = DateTime.now();
                }
            }

            // Step 6: Compliance Verification
            ComplianceVerificationResult complianceResult = verifyRetentionCompliance(archivalRecord, policy);
            result.complianceResult = complianceResult;

            // Step 7: Update Archival Record
            archivalRecord.Final_Status__c = result.status;
            archivalRecord.Execution_Completed__c = DateTime.now();
            archivalRecord.Compliance_Score__c = complianceResult.complianceScore;
            update archivalRecord;

            result.status = 'COMPLETED';
            result.action = 'ARCHIVED_AND_PROCESSED';

        } catch (Exception e) {
            result.status = 'ERROR';
            result.errorMessage = e.getMessage();
            result.stackTrace = e.getStackTraceString();

            // Create error notification
            createRetentionErrorNotification(doc.Id, policy.Id, e);
        }

        result.executionEndTime = DateTime.now();
        result.totalExecutionTime = result.executionEndTime.getTime() - result.executionStartTime.getTime();

        return result;
    }

    private static ArchivalResult executeDocumentArchival(ContentDocument doc, DocumentRetentionPolicy__c policy, DocumentArchivalRecord__c archivalRecord) {
        ArchivalResult result = new ArchivalResult();
        result.startTime = DateTime.now();

        try {
            // Get document content
            ContentVersion latestVersion = [
                SELECT Id, VersionData, Title, FileType, ContentSize
                FROM ContentVersion 
                WHERE ContentDocumentId = :doc.Id 
                AND IsLatest = true 
                LIMIT 1
            ];

            // Generate document hash for integrity verification
            String documentHash = generateDocumentHash(latestVersion.VersionData);

            // Prepare archival payload
            Map<String, Object> archivalPayload = new Map<String, Object>{
                'document_id' => doc.Id,
                'title' => latestVersion.Title,
                'file_type' => latestVersion.FileType,
                'content_size' => latestVersion.ContentSize,
                'document_hash' => documentHash,
                'retention_policy_id' => policy.Id,
                'archive_location' => policy.Archive_Location__c,
                'encryption_required' => policy.Encryption_Required__c,
                'compliance_metadata' => generateComplianceMetadata(doc, policy),
                'archival_timestamp' => DateTime.now().getTime(),
                'org_id' => UserInfo.getOrganizationId()
            };

            // Execute archival based on archive location
            switch on policy.Archive_Location__c {
                when 'SALESFORCE_SECURE_STORAGE' {
                    result = archiveToSalesforceStorage(latestVersion, archivalPayload);
                }
                when 'EXTERNAL_CLOUD_STORAGE' {
                    result = archiveToExternalStorage(latestVersion, archivalPayload);
                }
                when 'IMMUTABLE_BLOCKCHAIN_STORAGE' {
                    result = archiveToBlockchainStorage(latestVersion, archivalPayload);
                }
                when 'SNOWFLAKE_ARCHIVE' {
                    result = archiveToSnowflake(latestVersion, archivalPayload);
                }
                when else {
                    throw new ArchivalException('Unsupported archive location: ' + policy.Archive_Location__c);
                }
            }

            // Update archival record with results
            archivalRecord.Archive_Reference_Id__c = result.archiveReferenceId;
            archivalRecord.Archive_Hash__c = documentHash;
            archivalRecord.Archive_Size_MB__c = (Double) latestVersion.ContentSize / (1024 * 1024);
            archivalRecord.Archive_Status__c = result.success ? 'ARCHIVED' : 'FAILED';

            result.endTime = DateTime.now();
            result.duration = result.endTime.getTime() - result.startTime.getTime();

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.endTime = DateTime.now();
        }

        return result;
    }

    private static ArchivalResult archiveToSnowflake(ContentVersion version, Map<String, Object> payload) {
        ArchivalResult result = new ArchivalResult();

        try {
            // Convert document to base64 for storage
            String base64Content = EncodingUtil.base64Encode(version.VersionData);
            payload.put('document_content', base64Content);

            // Make HTTP callout to Snowflake archive endpoint
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:SnowflakeArchive/api/v1/archive-document');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + getSnowflakeToken());
            req.setTimeout(120000); // 2 minutes for large documents
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                result.success = true;
                result.archiveReferenceId = (String) responseData.get('archive_id');
                result.archiveLocation = 'SNOWFLAKE_ARCHIVE';
                result.verificationHash = (String) responseData.get('verification_hash');

                System.debug('Successfully archived document to Snowflake: ' + result.archiveReferenceId);

            } else {
                throw new CalloutException('Snowflake Archive API Error: ' + res.getStatusCode() + ' - ' + res.getBody());
            }

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Snowflake archival failed: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, result.errorMessage);
        }

        return result;
    }
}
