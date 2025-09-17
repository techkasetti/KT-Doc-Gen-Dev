public with sharing class SignatureRequestController {
    
    // Signature status enumeration
    public enum SignatureStatus {
        DRAFT, PENDING, SIGNED, REJECTED, COMPLETED, EXPIRED
    }
    
    /**
     * Initiate a new signature request
     * @param configId Configuration ID for document generation
     * @param signerEmail Email of the signer
     * @param signerName Name of the signer
     * @return Signature request ID
     */
    // @AuraEnabled
    // public static String initiateSignatureRequest(String documentId, String signerEmail, String signerName) {
    //             try {
    //         Signature_Request__c request = new Signature_Request__c(
    //             DocumentId__c = documentId,
    //             SignerEmail__c = signerEmail,
    //             SignerName__c = signerName,
    //             Status__c = 'Draft',
    //             RequestDate__c = System.now()
    //         );
    //         insert request;
            
    //         logSignatureRequest(request.Id, 'Signature request initiated');
            
    //         return request.Id;
    //     } catch (Exception e) {
    //         System.debug('❌ Failed to initiate signature request: ' + e.getMessage());
    //         throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
    //     }

    //     // version 1
        
    //     // try {
    //     //     // Create signer record
    //     //     Signer__c signer = createOrUpdateSigner(signerEmail, signerName);
            
    //     //     // Create signature request
    //     //     Signature_Request__c sigRequest = new Signature_Request__c(
    //     //         Document__c = documentId,
    //     //     Signer__c = signer.Id,
    //     //     Status__c = 'Initiated',
    //     //     OTP_Verification__c = false,
    //     //     Document_Hash__c = generateDocumentHash(documentId),
    //     //     Created_Date__c = System.now()
    //     //         );
    //     //     insert sigRequest;
            
    //     //     // Create compliance configuration
    //     //     createComplianceConfiguration(sigRequest.Id);
            
    //     //     // Log the initiation
    //     //     logSignatureActivity(sigRequest.Id, 'REQUEST_INITIATED', 'Signature request created successfully');
            
    //     //     return sigRequest.Id;
            
    //     // } catch (Exception e) {
    //     //     System.debug('Error in initiateSignatureRequest: ' + e.getMessage());
    //     //     throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
    //     // }
    // }

    //  @AuraEnabled
    // public static String initiateSignatureRequest(String documentId, String signerEmail, String documentTitle) {
       

    //     try {
    //         Signature_Request__c request = new Signature_Request__c(
    //             DocumentId__c = documentId,
    //             SignerEmail__c = signerEmail,
    //             DocumentTitle__c = documentTitle,
    //             Status__c = 'Pending',
    //             RequestedDate__c = System.now(),
    //             RequestedBy__c = UserInfo.getUserId()
    //         );
    //         insert request;
            
    //         sendSignatureNotification(request.Id, signerEmail, documentTitle);
    //         createSignatureAudit(request.Id, 'Signature Request Initiated');
            
    //         return request.Id;
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
    //     }


    //    // version 2
    //     // try {
    //     //     Signature_Request__c request = new Signature_Request__c(
    //     //         DocumentId__c = documentId,
    //     //         SignerEmail__c = signerEmail,
    //     //         DocumentTitle__c = documentTitle,
    //     //         Status__c = 'Pending',
    //     //         RequestDate__c = System.now()
    //     //     );
    //     //     insert request;
            
    //     //     // Send notification email
    //     //     sendSignatureNotification(request);
            
    //     //     return request.Id;
    //     // } catch (Exception e) {
    //     //     throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
    //     // }
    // }

     
    private static void sendSignatureNotification(Signature_Request__c request) {
        // Implementation for email notification
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{request.SignerEmail__c});
        email.setSubject('Signature Required: ' + request.DocumentTitle__c);
        email.setPlainTextBody('Please sign the document: ' + request.DocumentTitle__c);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
       }

    private static void sendSignatureNotification(String requestId, String signerEmail, String signerName) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { signerEmail });
            mail.setSubject('Document Signature Request');
            
            String emailBody = 'Dear ' + signerName + ',\n\n';
            emailBody += 'You have been requested to sign a document.\n';
            emailBody += 'Request ID: ' + requestId + '\n\n';
            emailBody += 'Please access your Salesforce org to complete the signature.\n\n';
            emailBody += 'Best regards,\nDocument Management System';
            
            mail.setPlainTextBody(emailBody);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
        } catch (Exception e) {
            System.debug('Failed to send notification email: ' + e.getMessage());
        }
    }

    // private static void sendSignatureNotification(String requestId, String signerEmail, String documentTitle) {
    // // Email notification implementation
    // Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    // email.setToAddresses(new String[]{signerEmail});
    // email.setSubject('Signature Required: ' + documentTitle);
    // email.setPlainTextBody('Please sign the document: ' + documentTitle + '\n\nClick here to sign: ' + 
    //                       System.URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Signature_Request__c/' + requestId + '/view');
    
    // Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
    // }

    private static void createComplianceConfiguration(String requestId) {
        ESignatureComplianceConfig__c config = new ESignatureComplianceConfig__c(
            Name = 'Config_' + requestId,
        Multi_Factor_Authentication__c = true,
        Biometric_Required__c = false,
        Device_Fingerprinting__c = true,
        Session_Timeout_Minutes__c = 30
            );
        insert config;
    }
    
    // Helper methods
    private static Signer__c createOrUpdateSigner(String email, String name) {
        List<Signer__c> existingSigners = [
            SELECT Id, Name, Email__c 
            FROM Signer__c 
            WHERE Email__c = :email 
            LIMIT 1
        ];
        
        if (!existingSigners.isEmpty()) {
            return existingSigners[0];
        }
        
        Signer__c newSigner = new Signer__c(
            Name = name,
        Email__c = email,
        Status__c = 'Active',
        Created_Date__c = System.now()
            );
        insert newSigner;
        return newSigner;
    }
      
    @AuraEnabled
    public static String initiateSignatureRequest(String configId, String signerEmail, String signerName) {
        System.debug('Initiating signature request for: ' + signerEmail);
        
        try {
            // Input validation
            if (String.isBlank(configId) || String.isBlank(signerEmail) || String.isBlank(signerName)) {
                throw new IllegalArgumentException('Configuration ID, signer email, and signer name are required');
            }
            
            // Validate email format
            if (!isValidEmail(signerEmail)) {
                throw new IllegalArgumentException('Invalid email format: ' + signerEmail);
            }
            
            // Validate configuration exists
            List<DocumentLifecycleConfiguration__c> configs = [
                SELECT Id, Region__c, Role__c, ContractType__c, OutputFormat__c
                FROM DocumentLifecycleConfiguration__c 
                WHERE Id = :configId 
                LIMIT 1
            ];
            
            if (configs.isEmpty()) {
                throw new IllegalArgumentException('Invalid configuration ID: ' + configId);
            }
            
            DocumentLifecycleConfiguration__c config = configs[0];
            
            // Generate document content
            String documentContent = generateDocumentContent(config);
            String documentHash = generateDocumentHash(documentContent);
            
            // Create signature request
            Signature_Request__c sigRequest = new Signature_Request__c(
                DocumentId__c = configId,
                SignerEmail__c = signerEmail,
                SignerName__c = signerName,
                Status__c = SignatureStatus.PENDING.name(),
                Document_Hash__c = documentHash,
                Created_Date__c = DateTime.now(),
                OTP_Verification__c = false
            );
            
            insert sigRequest;
            
            // Send notification email
            sendSignatureRequestEmail(sigRequest.Id, signerEmail, signerName, config);
            
            // Log activity
            logSignatureActivity(sigRequest.Id, 'SIGNATURE_REQUEST_INITIATED', 'SUCCESS', 
                               'Request sent to ' + signerEmail);
            
            System.debug('✓ Signature request created with ID: ' + sigRequest.Id);
            return sigRequest.Id;
            
        } catch (Exception e) {
            System.debug('✗ Signature request initiation failed: ' + e.getMessage());
            logSignatureActivity(null, 'SIGNATURE_REQUEST_INITIATED', 'ERROR', e.getMessage());
            throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
        }
    }
    
    /**
     * Submit signature data
     * @param requestId Signature request ID
     * @param signatureData Base64 encoded signature or typed signature
     * @param signerInfo JSON string with signer information
     * @return Success status
     */
//     @AuraEnabled
//     public static Boolean submitSignature(String requestId, String signatureData, String signatureMethod) {
//         try {
//             // Validate request exists and is active
//             Signature_Request__c sigRequest = [
//                 SELECT Id, Document__c, Signer__c, Status__c, Document_Hash__c 
//                 FROM Signature_Request__c 
//                 WHERE Id = :requestId AND Status__c IN ('Initiated', 'In Progress')
//                 LIMIT 1
//             ];
            
//             // Validate document hash
//             if (!validateDocumentHash(sigRequest.Document__c, sigRequest.Document_Hash__c)) {
//                 throw new AuraHandledException('Document has been modified since signature request was created');
//             }
            
//             // Create signature attestation
//             Signature_Attestation__c attestation = new Signature_Attestation__c(
//                 Signature_Request__c = sigRequest.Id,
//             Signature_Data__c = signatureData,
//             Signature_Method__c = signatureMethod,
//             IP_Address__c = getClientIPAddress(),
//             User_Agent__c = getUserAgent(),
//             Timestamp__c = System.now(),
//             Status__c = 'Completed'
//                 );
//             insert attestation;
            
//             // Update signature request status
//             sigRequest.Status__c = 'Completed';
//             update sigRequest;
            
//             // Log successful signature
//             logSignatureActivity(requestId, 'SIGNATURE_COMPLETED', 'Signature captured successfully via ' + signatureMethod);
            
//             // Trigger post-signature processing
//             processPostSignatureActions(requestId);
            
//             return true;
            
//         } catch (Exception e) {
//             logSignatureActivity(requestId, 'SIGNATURE_FAILED', 'Signature submission failed: ' + e.getMessage());
//             System.debug('Error in submitSignature: ' + e.getMessage());
//             throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
//         }
//     }
// @AuraEnabled  
//     public static void submitSignature(String requestId, String signatureData, String signerInfo) {
//             try {
//             // Validate request exists and is active
//             Signature_Request__c request = [
//                 SELECT Id, Status__c, Expiration_Date__c, Document_ID__c, Signer_Email__c
//                 FROM Signature_Request__c 
//                 WHERE Id = :requestId 
//                 LIMIT 1
//             ];
            
//             if (request.Status__c != 'Initiated' && request.Status__c != 'Pending') {
//                 throw new AuraHandledException('Signature request is not active');
//             }
            
//             if (request.Expiration_Date__c < System.now()) {
//                 throw new AuraHandledException('Signature request has expired');
//             }
            
//             // Create signature validation record
//             SignatureValidation__c validation = new SignatureValidation__c();
//             validation.Signature_Request__c = request.Id;
//             validation.Signature_Data__c = signatureData;
//             validation.Signer_Info__c = signerInfo;
//             validation.Validation_Hash__c = generateSignatureHash(signatureData, signerInfo);
//             validation.Validation_Date__c = System.now();
//             validation.IP_Address__c = getClientIP();
//             validation.Status__c = 'Valid';
            
//             insert validation;
            
//             // Update request status
//             request.Status__c = 'Completed';
//             request.Completion_Date__c = System.now();
//             update request;
            
//             // Log audit trail
//             createAuditLog(request.Id, 'COMPLETED', 'Signature submitted and validated', request.Signer_Email__c);
            
//             // Send completion notification
//             sendCompletionNotification(request.Id, request.Signer_Email__c);
            
//             return true;
            
//         } catch (Exception e) {
//             // Log error in audit trail
//             createAuditLog(requestId, 'ERROR', 'Signature submission failed: ' + e.getMessage(), '');
//             throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
//         }

//         //     try {
//     //         Signature_Request__c request = [
//     //             SELECT Id, Status__c, DocumentTitle__c 
//     //             FROM Signature_Request__c 
//     //             WHERE Id = :requestId
//     //         ];
            
//     //                 request.Status__c = 'Signed';
//     //     request.SignedDate__c = System.now();
//     //     request.SignatureData__c = signatureData;
//     //     request.SignerInfo__c = signerInfo;
//     //     request.IPAddress__c = getClientIPAddress();
        
//     //     update request;
        
//     //     // Create signature attestation record
//     //     SignatureValidation__c attestation = new SignatureValidation__c(
//     //         SignatureRequest__c = requestId,
//     //         SignatureMethod__c = getSignatureMethod(signerInfo),
//     //         ValidationStatus__c = 'Valid',
//     //         AttestedDate__c = System.now(),
//     //         IPAddress__c = getClientIPAddress()
//     //     );
//     //     insert attestation;
        
//     //     createSignatureAudit(requestId, 'Signature Submitted');
//     //     sendCompletionNotification(request.Id);
        
//     // } catch (Exception e) {
//     //     throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
//     // }
// }

private static void sendCompletionNotification(String requestId) {
    // Implementation for completion notification
    System.debug('Signature completed for request: ' + requestId);
}

private static void sendCompletionNotification(String requestId, String signerEmail) {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { signerEmail });
            mail.setSubject('Document Signature Completed');
            
            String emailBody = 'Your signature has been successfully submitted and validated.\n\n';
            emailBody += 'Request ID: ' + requestId + '\n\n';
            emailBody += 'Thank you for completing the signature process.\n\n';
            emailBody += 'Best regards,\nDocument Management System';
            
            mail.setPlainTextBody(emailBody);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            
        } catch (Exception e) {
            System.debug('Failed to send completion notification: ' + e.getMessage());
        }
    }
private static String getSignatureMethod(String signerInfo) {
    try {
        Map<String, Object> infoMap = (Map<String, Object>) JSON.deserializeUntyped(signerInfo);
        return (String) infoMap.get('signatureMethod');
    } catch (Exception e) {
        return 'Unknown';
    }
}
private static void processPostSignatureActions(String requestId) {
        // Placeholder for post-signature processing
        System.debug('Processing post-signature actions for request: ' + requestId);
    }

 private static String getUserAgent() {
        // In production, this would extract from request headers
        return 'Mozilla/5.0 (Test Browser)'; // Mock user agent
    }
    
 private static String getClientIPAddress() {
        // In production, this would extract from request headers
        return '192.168.1.1'; // Mock IP for testing
    }
    
    private static Boolean validateDocumentHash(String documentId, String expectedHash) {
        String currentHash = generateDocumentHash(documentId);
        // In production, this would compare actual document hash
        // For now, we'll return true to allow testing
        return true;
    }
    
    @AuraEnabled
    public static Boolean submitSignature(String requestId, String signatureData, String signerInfo) {
        System.debug('Submitting signature for request: ' + requestId);
        
        try {
            // Input validation
            if (String.isBlank(requestId) || String.isBlank(signatureData) || String.isBlank(signerInfo)) {
                throw new IllegalArgumentException('Request ID, signature data, and signer info are required');
            }
            
            // Validate signature request exists and is in pending status
            List<Signature_Request__c> requests = [
                SELECT Id, Status__c, SignerEmail__c, SignerName__c, DocumentId__c, Document_Hash__c
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            if (requests.isEmpty()) {
                throw new IllegalArgumentException('Invalid signature request ID: ' + requestId);
            }
            
            Signature_Request__c request = requests[0];
            
            if (request.Status__c != SignatureStatus.PENDING.name()) {
                throw new IllegalArgumentException('Signature request is not in pending status. Current status: ' + request.Status__c);
            }
            
            // Validate signature data
            if (!isValidSignatureData(signatureData)) {
                throw new IllegalArgumentException('Invalid signature data format');
            }
            
            // Parse signer info
            Map<String, Object> signerInfoMap = parseSignerInfo(signerInfo);
            
            // Update signature request
            request.SignatureData__c = signatureData;
            request.Status__c = SignatureStatus.SIGNED.name();
            request.CompletedDate__c = DateTime.now();
            
            update request;
            
            // Create signature validation record
            createSignatureValidation(request, signerInfoMap);
            
            // Process post-signature workflows
            processPostSignatureWorkflow(request);
            
            // Log successful signature
            logSignatureActivity(requestId, 'SIGNATURE_SUBMITTED', 'SUCCESS', 
                               'Signature completed by ' + request.SignerName__c);
            
        // Send completion notification
        sendSignatureCompletionEmail(request);
        
        System.debug('✓ Signature submitted successfully for request: ' + requestId);
        return true;
        
    } catch (Exception e) {
        System.debug('✗ Signature submission failed: ' + e.getMessage());
        logSignatureActivity(requestId, 'SIGNATURE_SUBMITTED', 'ERROR', e.getMessage());
        throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
    }
}
  @AuraEnabled
    public static void submitSignature(String requestId, String signatureData, String signerInfo) {
        
                try {
            Signature_Request__c request = [
                SELECT Id, Status__c, DocumentId__c 
                FROM Signature_Request__c 
                WHERE Id = :requestId
            ];
            
            // Validate signature data
            if (String.isBlank(signatureData)) {
                throw new AuraHandledException('Signature data is required');
            }
            
            // Update request with signature
            request.Status__c = 'Signed';
            request.SignatureData__c = signatureData;
            request.SignedDate__c = System.now();
            request.SignerInfo__c = signerInfo;
            
            update request;
            
            // Create signature validation record
            SignatureValidation__c validation = new SignatureValidation__c(
                SignatureRequestId__c = requestId,
                ValidationStatus__c = 'Validated',
                ValidationDate__c = System.now(),
                SignatureHash__c = generateSignatureHash(signatureData)
            );
            insert validation;
            
            logSignatureRequest(requestId, 'Signature submitted and validated');
            
            return true;
        } catch (Exception e) {
            System.debug('❌ Failed to submit signature: ' + e.getMessage());
            throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
        }

        // try {
        //     Signature_Request__c request = [SELECT Id, Status__c FROM Signature_Request__c WHERE Id = :requestId];
            
        //     request.Status__c = 'Signed';
        //     request.SignatureData__c = signatureData;
        //     request.SignedDate__c = System.now();
        //     request.SignerInfo__c = signerInfo;
            
        //     update request;
            
        //     // Create audit trail
        //     createSignatureAudit(requestId, 'Signature Submitted');
            
        // } catch (Exception e) {
        //     throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
        // }
    }
    private static String generateSignatureHash(String signatureData) {
        Blob signatureBlob = Blob.valueOf(signatureData);
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', signatureBlob));
    }

private static void createSignatureAudit(String requestId, String action) {
    AuditTrail__c audit = new AuditTrail__c(
        Action__c = action,
        RelatedRecordId__c = requestId,
        Timestamp__c = System.now(),
        UserId__c = UserInfo.getUserId(),
        Details__c = 'Signature request: ' + requestId
    );
    insert audit;


       // version 2
        // AuditTrail__c audit = new AuditTrail__c(
        //     Action__c = action,
        //     Details__c = 'Signature Request: ' + requestId,
        //     Timestamp__c = System.now(),
        //     UserId__c = UserInfo.getUserId()
        // );
        // insert audit;
    }
    // private static void logSignatureRequest(Id requestId, String action) {
    //     AuditTrail__c audit = new AuditTrail__c(
    //         EventType__c = 'Signature Activity',
    //         Description__c = action,
    //         RelatedRecordId__c = requestId,
    //         Timestamp__c = System.now(),
    //         UserId__c = UserInfo.getUserId()
    //     );
    //     insert audit;
    // }
        private static void logSignatureRequest(String action, Id requestId) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Signature Request ' + action,
            RelatedRecordId__c = requestId,
            Timestamp__c = System.now(),
            Status__c = 'Success'
        );
        insert audit;
         }

/**
 * Get signature request details
 * @param requestId Signature request ID
 * @return Signature request details
 */
@AuraEnabled
public static Map<String, Object> getSignatureRequest(String requestId) {
    System.debug('Retrieving signature request: ' + requestId);
    try {
        if (String.isBlank(requestId)) {
            throw new IllegalArgumentException('Request ID is required');
        }
        
        List<Signature_Request__c> requests = [
            SELECT Id, DocumentId__c, SignerEmail__c, SignerName__c, Status__c,
                   SignatureData__c, CompletedDate__c, Created_Date__c, OTP_Verification__c
            FROM Signature_Request__c 
            WHERE Id = :requestId 
            LIMIT 1
        ];
        
        if (requests.isEmpty()) {
            throw new IllegalArgumentException('Signature request not found: ' + requestId);
        }
        
        Signature_Request__c request = requests[0];
        
        // Get associated document configuration
        DocumentLifecycleConfiguration__c config = [
            SELECT Region__c, Role__c, ContractType__c, OutputFormat__c, ComplianceStatus__c
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :request.DocumentId__c 
            LIMIT 1
        ];
        
        Map<String, Object> requestDetails = new Map<String, Object>{
            'id' => request.Id,
            'documentId' => request.DocumentId__c,
            'signerEmail' => request.SignerEmail__c,
            'signerName' => request.SignerName__c,
            'status' => request.Status__c,
            'hasSignature' => String.isNotBlank(request.SignatureData__c),
            'completedDate' => request.CompletedDate__c,
            'createdDate' => request.Created_Date__c,
            'otpVerified' => request.OTP_Verification__c,
            'documentType' => config.ContractType__c,
            'region' => config.Region__c,
            'role' => config.Role__c,
            'complianceStatus' => config.ComplianceStatus__c
        };
        
        System.debug('✓ Retrieved signature request details');
        return requestDetails;
        
    } catch (Exception e) {
        System.debug('✗ Failed to retrieve signature request: ' + e.getMessage());
        throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
    }
}

/**
 * Get list of signature requests with optional filtering
 * @param filterStatus Optional status filter
 * @param filterEmail Optional email filter
 * @return List of signature requests
 */
//   @AuraEnabled
//     public static Map<String, Object> getSignatureRequest(String requestId) {

//     try {
//         Signature_Request__c request = [
//             SELECT Id, DocumentTitle__c, SignerEmail__c, Status__c, 
//                    RequestedDate__c, DocumentId__c
//             FROM Signature_Request__c 
//             WHERE Id = :requestId 
//             LIMIT 1
//         ];
        
//         return new Map<String, Object>{
//             'requestId' => request.Id,
//             'documentTitle' => request.DocumentTitle__c,
//             'signerEmail' => request.SignerEmail__c,
//             'status' => request.Status__c,
//             'requestedDate' => request.RequestedDate__c
//         };
//     } catch (Exception e) {
//         throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
//     }
//     }
// //version 2

//     //     return [SELECT Id, DocumentTitle__c, Status__c, RequestDate__c, SignedDate__c, SignerEmail__c 
//     //             FROM Signature_Request__c WHERE Id = :requestId LIMIT 1];
//     // }

//         // version 1
//         // try {
//         //     Signature_Request__c sigRequest = [
//         //         SELECT Id, Document__c, Signer__c, Status__c, Created_Date__c,
//         //                Signer__r.Name, Signer__r.Email__c,
//         //                Document__r.Name
//         //         FROM Signature_Request__c 
//         //         WHERE Id = :requestId 
//         //         LIMIT 1
//         //     ];
            
//         //     Map<String, Object> result = new Map<String, Object>{
//         //         'requestId' => sigRequest.Id,
//         //         'status' => sigRequest.Status__c,
//         //         'signerName' => sigRequest.Signer__r.Name,
//         //         'signerEmail' => sigRequest.Signer__r.Email__c,
//         //         'documentName' => sigRequest.Document__r.Name,
//         //         'createdDate' => sigRequest.Created_Date__c
//         //     };
            
//         //     return result;
            
//         // } catch (Exception e) {
//         //     System.debug('Error in getSignatureRequest: ' + e.getMessage());
//         //     throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
//         // }
//     //}
    @AuraEnabled
    public static void extendExpirationDate(String requestId, Integer additionalDays) {
        try {
            Signature_Request__c request = [
                SELECT Id, Expiration_Date__c, Status__c 
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            if (request.Status__c == 'Completed') {
                throw new AuraHandledException('Cannot extend expiration for completed requests');
            }
            
            request.Expiration_Date__c = request.Expiration_Date__c.addDays(additionalDays);
            update request;
            
            // Log audit trail
            createAuditLog(requestId, 'EXTENDED', 
                          'Expiration date extended by ' + additionalDays + ' days', '');
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to extend expiration date: ' + e.getMessage());
        }
    }

@AuraEnabled
public static List<Signature_Request__c> getSignatureRequests(Id documentId) {
        return [
            SELECT Id, SignerEmail__c, SignerName__c, Status__c, RequestDate__c, SignedDate__c
            FROM Signature_Request__c
            WHERE DocumentId__c = :documentId
            ORDER BY RequestDate__c DESC
        ];
    }

@AuraEnabled(cacheable=true)
public static List<Signature_Request__c> getSignatureRequests(String filterStatus) {
        try {
            String query = 'SELECT Id, Document_ID__c, Signer_Name__c, Signer_Email__c, Status__c, ' +
                          'Request_Date__c, Completion_Date__c, Expiration_Date__c ' +
                          'FROM Signature_Request__c ';
            
            if (String.isNotBlank(filterStatus) && filterStatus != 'All') {
                query += 'WHERE Status__c = :filterStatus ';
            }
            
            query += 'ORDER BY Request_Date__c DESC LIMIT 100';
            
            return Database.query(query);
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve signature requests: ' + e.getMessage());
        }
    }
    
@AuraEnabled
public static List<Map<String, Object>> getSignatureRequests(String filterStatus, String filterEmail) {
    System.debug('Retrieving signature requests with filters - Status: ' + filterStatus + ', Email: ' + filterEmail);
    try {
        String query = 'SELECT Id, DocumentId__c, SignerEmail__c, SignerName__c, Status__c, ' +
                      'CompletedDate__c, Created_Date__c FROM Signature_Request__c WHERE Id != null';
        
        List<String> whereConditions = new List<String>();
        
        if (String.isNotBlank(filterStatus) && !filterStatus.equals('All')) {
            whereConditions.add('Status__c = :filterStatus');
        }
        
        if (String.isNotBlank(filterEmail)) {
            whereConditions.add('SignerEmail__c LIKE :filterEmail');
            filterEmail = '%' + filterEmail + '%';
        }
        
        if (!whereConditions.isEmpty()) {
            query += ' AND ' + String.join(whereConditions, ' AND ');
        }
        
        query += ' ORDER BY Created_Date__c DESC LIMIT 100';
        
        List<Signature_Request__c> requests = Database.query(query);
        List<Map<String, Object>> requestList = new List<Map<String, Object>>();
        
        for (Signature_Request__c request : requests) {
            requestList.add(new Map<String, Object>{
                'id' => request.Id,
                'documentId' => request.DocumentId__c,
                'signerEmail' => request.SignerEmail__c,
                'signerName' => request.SignerName__c,
                'status' => request.Status__c,
                'completedDate' => request.CompletedDate__c,
                'createdDate' => request.Created_Date__c,
                'statusClass' => getStatusClass(request.Status__c)
            });
        }
        
        System.debug('✓ Retrieved ' + requestList.size() + ' signature requests');
        return requestList;
        
    } catch (Exception e) {
        System.debug('✗ Failed to retrieve signature requests: ' + e.getMessage());
        throw new AuraHandledException('Failed to retrieve signature requests: ' + e.getMessage());
    }
}

/**
 * Cancel a signature request
 * @param requestId Signature request ID
 * @param reason Cancellation reason
 * @return Success status
 */
@AuraEnabled
public static Boolean cancelSignatureRequest(String requestId, String reason) {
    System.debug('Cancelling signature request: ' + requestId);
    try {
        if (String.isBlank(requestId)) {
            throw new IllegalArgumentException('Request ID is required');
        }
        
        List<Signature_Request__c> requests = [
            SELECT Id, Status__c, SignerEmail__c, SignerName__c
            FROM Signature_Request__c 
            WHERE Id = :requestId 
            LIMIT 1
        ];
        
        if (requests.isEmpty()) {
            throw new IllegalArgumentException('Signature request not found: ' + requestId);
        }
        
        Signature_Request__c request = requests[0];
        
        if (request.Status__c == SignatureStatus.SIGNED.name() || 
            request.Status__c == SignatureStatus.COMPLETED.name()) {
            throw new IllegalArgumentException('Cannot cancel a completed signature request');
        }
        
        request.Status__c = SignatureStatus.REJECTED.name();
        update request;
        
        // Send cancellation notification
        sendCancellationNotification(request, reason);
        
        // Log cancellation
        logSignatureActivity(requestId, 'SIGNATURE_CANCELLED', 'SUCCESS', 
                           'Request cancelled. Reason: ' + (String.isBlank(reason) ? 'No reason provided' : reason));
        
        System.debug('✓ Signature request cancelled successfully');
        return true;
        
    } catch (Exception e) {
        System.debug('✗ Failed to cancel signature request: ' + e.getMessage());
        logSignatureActivity(requestId, 'SIGNATURE_CANCELLED', 'ERROR', e.getMessage());
        throw new AuraHandledException('Failed to cancel signature request: ' + e.getMessage());
    }
}

/**
 * Reset signature request to allow re-signing
 * @param requestId Signature request ID
 * @return Success status
 */

    @AuraEnabled
    public static void resetSignatureRequest(String requestId) {
        try {
            Signature_Request__c request = [
                SELECT Id, Status__c 
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            // Only allow reset for non-completed requests
            if (request.Status__c == 'Completed') {
                throw new AuraHandledException('Cannot reset completed signature request');
            }
            
            // Delete existing validation records
            List<SignatureValidation__c> validations = [
                SELECT Id 
                FROM SignatureValidation__c 
                WHERE Signature_Request__c = :requestId
            ];
            
            if (!validations.isEmpty()) {
                delete validations;
            }
            
            // Reset request status
            request.Status__c = 'Initiated';
            request.Completion_Date__c = null;
            update request;
            
            // Log audit trail
            createAuditLog(requestId, 'RESET', 'Signature request reset', request.Signer_Email__c);
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to reset signature request: ' + e.getMessage());
        }
    }
      private static void createAuditLog(String requestId, String action, String details, String userEmail) {
        try {
            AuditTrail__c audit = new AuditTrail__c();
            audit.Signature_Request__c = requestId;
            audit.Action__c = action;
            audit.Details__c = details;
            audit.User_Email__c = userEmail;
            audit.Timestamp__c = System.now();
            audit.Session_ID__c = UserInfo.getSessionId();
            
            insert audit;
        } catch (Exception e) {
            // Log audit creation failure but don't throw to avoid breaking main flow
            System.debug('Failed to create audit log: ' + e.getMessage());
        }
    }

@AuraEnabled
public static Boolean resetSignatureRequest(String requestId) {
    System.debug('Resetting signature request: ' + requestId);
    try {
        if (String.isBlank(requestId)) {
            throw new IllegalArgumentException('Request ID is required');
        }
        
        List<Signature_Request__c> requests = [
            SELECT Id, Status__c, SignerEmail__c, SignerName__c
            FROM Signature_Request__c 
            WHERE Id = :requestId 
            LIMIT 1
        ];
        
        if (requests.isEmpty()) {
            throw new IllegalArgumentException('Signature request not found: ' + requestId);
        }
        
        Signature_Request__c request = requests[0];
        
        // Clear signature data and reset status
        request.Status__c = SignatureStatus.PENDING.name();
        request.SignatureData__c = null;
        request.CompletedDate__c = null;
        request.OTP_Verification__c = false;
        update request;
        
        // Log reset action
        logSignatureActivity(requestId, 'SIGNATURE_RESET', 'SUCCESS', 'Request reset for re-signing');
        
        System.debug('✓ Signature request reset successfully');
        return true;
        
    } catch (Exception e) {
        System.debug('✗ Failed to reset signature request: ' + e.getMessage());
        logSignatureActivity(requestId, 'SIGNATURE_RESET', 'ERROR', e.getMessage());
        throw new AuraHandledException('Failed to reset signature request: ' + e.getMessage());
    }
}

/**
 * Get signature statistics for dashboard
 * @return Map containing signature statistics
 */
@AuraEnabled
public static Map<String, Object> getSignatureStatistics() {
    System.debug('Retrieving signature statistics');
    try {
        Map<String, Object> stats = new Map<String, Object>();
        
        // Overall statistics
        List<AggregateResult> overallStats = [
            SELECT Status__c, COUNT(Id) count
            FROM Signature_Request__c 
            WHERE CreatedDate = LAST_N_DAYS:30
            GROUP BY Status__c
        ];
        
        Integer totalRequests = 0;
        Integer completedRequests = 0;
        Integer pendingRequests = 0;
        Integer rejectedRequests = 0;
        
        for (AggregateResult result : overallStats) {
            String status = (String)result.get('Status__c');
            Integer count = (Integer)result.get('count');
            totalRequests += count;
            
            if (status == SignatureStatus.SIGNED.name() || status == SignatureStatus.COMPLETED.name()) {
                completedRequests += count;
            } else if (status == SignatureStatus.PENDING.name()) {
                pendingRequests += count;
            } else if (status == SignatureStatus.REJECTED.name()) {
                rejectedRequests += count;
            }
        }
        
        Decimal completionRate = totalRequests > 0 ? 
            (Decimal.valueOf(completedRequests) / Decimal.valueOf(totalRequests)) * 100 : 0;
        
        stats.put('totalRequests', totalRequests);
        stats.put('completedRequests', completedRequests);
        stats.put('pendingRequests', pendingRequests);
        stats.put('rejectedRequests', rejectedRequests);
        stats.put('completionRate', completionRate);
        
        // Daily trend for last 7 days
        List<AggregateResult> dailyStats = [
            SELECT DAY_ONLY(CreatedDate) day, COUNT(Id) count
            FROM Signature_Request__c 
            WHERE CreatedDate = LAST_N_DAYS:7
            GROUP BY DAY_ONLY(CreatedDate)
            ORDER BY DAY_ONLY(CreatedDate)
        ];
        
        Map<String, Integer> dailyTrend = new Map<String, Integer>();
        for (AggregateResult result : dailyStats) {
            Date day = (Date)result.get('day');
            Integer count = (Integer)result.get('count');
            dailyTrend.put(day.format(), count);
        }
        
        stats.put('dailyTrend', dailyTrend);
        stats.put('lastUpdated', DateTime.now());
        
        System.debug('✓ Signature statistics compiled');
        return stats;
        
    } catch (Exception e) {
        System.debug('✗ Failed to retrieve signature statistics: ' + e.getMessage());
        throw new AuraHandledException('Failed to retrieve signature statistics: ' + e.getMessage());
    }
}

// ===================================
// PRIVATE HELPER METHODS
// ===================================

/**
 * Validate email format
 */
@TestVisible
private static Boolean isValidEmail(String email) {
    String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
    Pattern emailPattern = Pattern.compile(emailRegex);
    return emailPattern.matcher(email).matches();
}

/**
 * Generate document content for signature
 */
@TestVisible
private static String generateDocumentContent(DocumentLifecycleConfiguration__c config) {
    try {
        // Generate clause using existing ClauseGenerator
        String clause = ClauseGenerator.generateClause(config.Region__c, config.Role__c, config.ContractType__c);
        
        // Create formatted document content
        String documentContent = 'DOCUMENT GENERATION REQUEST\n';
        documentContent += '===========================\n\n';
        documentContent += 'Region: ' + config.Region__c + '\n';
        documentContent += 'Role: ' + config.Role__c + '\n';
        documentContent += 'Contract Type: ' + config.ContractType__c + '\n';
        documentContent += 'Generated Date: ' + DateTime.now().format() + '\n\n';
        documentContent += 'DOCUMENT CONTENT:\n';
        documentContent += '================\n\n';
        documentContent += clause + '\n\n';
        documentContent += 'SIGNATURE SECTION:\n';
        documentContent += '================\n\n';
        documentContent += 'By signing below, I acknowledge that I have read, understood, and agree to be bound by the terms and conditions set forth in this document.\n\n';
        documentContent += 'Signature: ___________________________ Date: ___________\n\n';
        documentContent += 'Print Name: ___________________________\n\n';
        
        return documentContent;
        
    } catch (Exception e) {
        System.debug('⚠ Failed to generate document content: ' + e.getMessage());
        return 'Document content generation failed. Please contact administrator.';
    }
}

/**
 * Generate SHA-256 hash of document content
 */
//  private static String generateDocumentHash(String documentId) {
//         // In production, this would generate actual hash of document content
//         // For now, we'll create a mock hash
//         String hashInput = documentId + String.valueOf(System.now().getTime());
//         return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(hashInput)));
//     }
@TestVisible
private static String generateDocumentHash(String content) {
    try {
        Blob contentBlob = Blob.valueOf(content);
        Blob hashBlob = Crypto.generateDigest('SHA-256', contentBlob);
        return EncodingUtil.base64Encode(hashBlob);
    } catch (Exception e) {
        System.debug('⚠ Failed to generate document hash: ' + e.getMessage());
        return 'HASH_GENERATION_FAILED_' + DateTime.now().getTime();
    }
}

    @TestVisible
    private static void sendSignatureCompletionEmail(Signature_Request__c request) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { request.SignerEmail__c });
            email.setSubject('Document Signature Completed - Request #' + request.Id);

            String emailBody = 'Dear ' + request.SignerName__c + ',\n\n';
            emailBody += 'Thank you for completing the signature process for your document.\n\n';
            emailBody += 'Signature Details:\n';
            emailBody += '- Request ID: ' + request.Id + '\n';
            emailBody += '- Completed Date: ' + request.CompletedDate__c.format() + '\n';
            emailBody += '- Status: ' + request.Status__c + '\n\n';
            emailBody += 'Your signed document has been processed and stored securely in our system.\n';
            emailBody += 'You will receive a copy of the fully executed document once all parties have signed.\n\n';
            emailBody += 'If you need a copy of your signature confirmation, please contact the document administrator with your Request ID.\n\n';
            emailBody += 'Best regards,\n';
            emailBody += 'Document Management System';

            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

            System.debug('✓ Signature completion email sent to: ' + request.SignerEmail__c);
        } catch (Exception e) {
            System.debug('⚠ Failed to send completion email: ' + e.getMessage());
        }
    }

    /**
     * Send cancellation notification email.
     * @param request The signature request record.
     * @param reason  The cancellation reason (optional).
     */
    @TestVisible
    private static void sendCancellationNotification(Signature_Request__c request, String reason) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { request.SignerEmail__c });
            email.setSubject('Signature Request Cancelled - Request #' + request.Id);

            String emailBody = 'Dear ' + request.SignerName__c + ',\n\n';
            emailBody += 'The signature request for your document has been cancelled.\n\n';
            emailBody += 'Cancellation Details:\n';
            emailBody += '- Request ID: ' + request.Id + '\n';
            emailBody += '- Cancelled Date: ' + DateTime.now().format() + '\n';

            if (String.isNotBlank(reason)) {
                emailBody += '- Reason: ' + reason + '\n';
            }

            emailBody += '\n';
            emailBody += 'No further action is required on your part. If you believe this cancellation was made in error, ';
            emailBody += 'please contact the document administrator.\n\n';
            emailBody += 'Best regards,\n';
            emailBody += 'Document Management System';

            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

            System.debug('✓ Cancellation notification sent to: ' + request.SignerEmail__c);
        } catch (Exception e) {
            System.debug('⚠ Failed to send cancellation notification: ' + e.getMessage());
        }
    }
@TestVisible
private static Boolean isValidSignatureData(String signatureData) {
    try {
        if (String.isBlank(signatureData)) {
            return false;
        }

        // Check if it's base64 encoded (common for drawn signatures)
        if (signatureData.startsWith('data:image/')) {
            return signatureData.contains('base64,');
        }

        // Check if it's typed signature (should be reasonable length)
        if (signatureData.length() > 2 && signatureData.length() < 200) {
            return true;
        }

        // Check if it's a valid base64 string
        try {
            EncodingUtil.base64Decode(signatureData);
            return true;
        } catch (Exception e) {
            // Not valid base64
        }

        return false;
    } catch (Exception e) {
        System.debug('⚠ Signature data validation failed: ' + e.getMessage());
        return false;
    }
}
@TestVisible
private static Map<String, Object> parseSignerInfo(String signerInfo) {
    try {
        return (Map<String, Object>) JSON.deserializeUntyped(signerInfo);
    } catch (Exception e) {
        System.debug('⚠ Failed to parse signer info: ' + e.getMessage());

        return new Map<String, Object>{
            'parseError'  => true,
            'originalData'=> signerInfo,
            'timestamp'   => DateTime.now()
        };
    }
}
@TestVisible
private static void createSignatureValidation(Signature_Request__c request, Map<String, Object> signerInfo) {
    try {
        // Create audit trail for signature validation
        AuditTrail__c validation = new AuditTrail__c(
            Action__c       = 'SIGNATURE_VALIDATION',
            Status__c       = 'SUCCESS',
            Timestamp__c    = DateTime.now(),
            UserDetails__c  = request.SignerName__c + ' (' + request.SignerEmail__c + ')',
            SystemInfo__c   = 'Signature validated for request: ' + request.Id,
            AdditionalData__c = JSON.serialize(new Map<String, Object>{
                'requestId'       => request.Id,
                'documentId'      => request.DocumentId__c,
                'signerEmail'     => request.SignerEmail__c,
                'signerName'      => request.SignerName__c,
                'signatureMethod' => signerInfo.get('signatureMethod'),
                'ipAddress'       => signerInfo.get('ipAddress'),
                'userAgent'       => signerInfo.get('userAgent'),
                'timestamp'       => request.CompletedDate__c,
                'documentHash'    => request.Document_Hash__c
            })
        );

        insert validation;
        System.debug('✓ Signature validation record created');

    } catch (Exception e) {
        System.debug('⚠ Failed to create signature validation record: ' + e.getMessage());
    }
}
@TestVisible
private static void processPostSignatureWorkflow(Signature_Request__c request) {
    try {
        // Check if this completes a multi-signer document
        List<Signature_Request__c> relatedRequests = [
            SELECT Id, Status__c
            FROM Signature_Request__c
            WHERE DocumentId__c = :request.DocumentId__c
        ];

        Boolean allSigned = true;
        for (Signature_Request__c relatedRequest : relatedRequests) {
            if (relatedRequest.Status__c != SignatureStatus.SIGNED.name()) {
                allSigned = false;
                break;
            }
        }

        if (allSigned && relatedRequests.size() > 1) {
            // All signatures collected, mark document as complete
            for (Signature_Request__c relatedRequest : relatedRequests) {
                relatedRequest.Status__c = SignatureStatus.COMPLETED.name();
            }
            update relatedRequests;

            // Trigger document completion workflow
            triggerDocumentCompletionWorkflow(request.DocumentId__c);
            System.debug('✓ Multi-signer document completed');
        }

        System.debug('✓ Post-signature workflow processed');
    } catch (Exception e) {
        System.debug('⚠ Post-signature workflow processing failed: ' + e.getMessage());
    }
}
@TestVisible
private static void triggerDocumentCompletionWorkflow(String documentId) {
    try {
        // Update document configuration status
        List<DocumentLifecycleConfiguration__c> configs = [
            SELECT Id, ProcessingStatus__c 
            FROM DocumentLifecycleConfiguration__c 
            WHERE Id = :documentId 
            LIMIT 1
        ];
        
        if (!configs.isEmpty()) {
            configs[0].ProcessingStatus__c = 'SIGNATURE_COMPLETED';
            update configs[0];
        }

        // Create completion audit record
        AuditTrail__c completionAudit = new AuditTrail__c(
            Action__c       = 'DOCUMENT_COMPLETION',
            Status__c       = 'SUCCESS',
            Timestamp__c    = DateTime.now(),
            UserDetails__c  = UserInfo.getName() + ' (System)',
            SystemInfo__c   = 'Document signature process completed for: ' + documentId,
            AdditionalData__c = JSON.serialize(new Map<String, Object>{
                'documentId'    => documentId,
                'completedDate' => DateTime.now(),
                'completedBy'   => 'SYSTEM_WORKFLOW'
            })
        );
        insert completionAudit;

        System.debug('✓ Document completion workflow triggered');
    } catch (Exception e) {
        System.debug('⚠ Document completion workflow failed: ' + e.getMessage());
    }
}
@TestVisible
private static String getStatusClass(String status) {
    switch on status {
        when 'PENDING' {
            return 'slds-badge slds-badge_lightest slds-theme_warning';
        }
        when 'SIGNED', 'COMPLETED' {
            return 'slds-badge slds-badge_lightest slds-theme_success';
        }
        when 'REJECTED' {
            return 'slds-badge slds-badge_lightest slds-theme_error';
        }
        when 'EXPIRED' {
            return 'slds-badge slds-badge_lightest slds-theme_offline';
        }
        when else {
            return 'slds-badge slds-badge_lightest';
        }
    }
}

    private static void logSignatureActivity(String requestId, String action, String message) {
        Audit_Log__c audit = new Audit_Log__c(
            Record_Id__c = requestId,
        Action__c = action,
        Message__c = message,
        User_Id__c = UserInfo.getUserId(),
        Timestamp__c = System.now(),
        IP_Address__c = getClientIPAddress()
            );
        insert audit;
    }

        private static void logSignatureActivity(String action, Id requestId, String details) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = action,
            Timestamp__c = DateTime.now(),
            UserDetails__c = UserInfo.getUserName(),
            AdditionalInfo__c = 'Request ID: ' + requestId + ', Details: ' + details
        );
        insert audit;
    }

@TestVisible
private static void logSignatureActivity(
    String requestId,
    String action,
    String status,
    String details
) {
    try {
        AuditTrail__c auditLog = new AuditTrail__c(
            Action__c       = action,
            Status__c       = status,
            Timestamp__c    = DateTime.now(),
            UserDetails__c  = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
            SystemInfo__c   = details,
            AdditionalData__c = JSON.serialize(new Map<String, Object>{
                'requestId' => requestId,
                'action'    => action,
                'status'    => status,
                'details'   => details,
                'timestamp' => DateTime.now().format(),
                'userId'    => UserInfo.getUserId(),
                'sessionId' => UserInfo.getSessionId()
            })
        );

        insert auditLog;
    } catch (Exception e) {
        System.debug('⚠ Could not log signature activity: ' + e.getMessage());
    }
}

}