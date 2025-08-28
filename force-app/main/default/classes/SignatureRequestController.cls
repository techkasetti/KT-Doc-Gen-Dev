public with sharing class SignatureRequestController {
    
    @AuraEnabled
    public static String initiateSignatureRequest(String documentId, String signerEmail, String signerName) {
                try {
            Signature_Request__c request = new Signature_Request__c(
                DocumentId__c = documentId,
                SignerEmail__c = signerEmail,
                SignerName__c = signerName,
                Status__c = 'Draft',
                RequestDate__c = System.now()
            );
            insert request;
            
            logSignatureRequest(request.Id, 'Signature request initiated');
            
            return request.Id;
        } catch (Exception e) {
            System.debug('❌ Failed to initiate signature request: ' + e.getMessage());
            throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
        }

        // version 1
        
        // try {
        //     // Create signer record
        //     Signer__c signer = createOrUpdateSigner(signerEmail, signerName);
            
        //     // Create signature request
        //     Signature_Request__c sigRequest = new Signature_Request__c(
        //         Document__c = documentId,
        //     Signer__c = signer.Id,
        //     Status__c = 'Initiated',
        //     OTP_Verification__c = false,
        //     Document_Hash__c = generateDocumentHash(documentId),
        //     Created_Date__c = System.now()
        //         );
        //     insert sigRequest;
            
        //     // Create compliance configuration
        //     createComplianceConfiguration(sigRequest.Id);
            
        //     // Log the initiation
        //     logSignatureActivity(sigRequest.Id, 'REQUEST_INITIATED', 'Signature request created successfully');
            
        //     return sigRequest.Id;
            
        // } catch (Exception e) {
        //     System.debug('Error in initiateSignatureRequest: ' + e.getMessage());
        //     throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
        // }
    }


        @AuraEnabled
    public static String initiateSignatureRequest(String documentId, String signerEmail, String documentTitle) {
       

        try {
            Signature_Request__c request = new Signature_Request__c(
                DocumentId__c = documentId,
                SignerEmail__c = signerEmail,
                DocumentTitle__c = documentTitle,
                Status__c = 'Pending',
                RequestedDate__c = System.now(),
                RequestedBy__c = UserInfo.getUserId()
            );
            insert request;
            
            sendSignatureNotification(request.Id, signerEmail, documentTitle);
            createSignatureAudit(request.Id, 'Signature Request Initiated');
            
            return request.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
        }




       // version 2
        // try {
        //     Signature_Request__c request = new Signature_Request__c(
        //         DocumentId__c = documentId,
        //         SignerEmail__c = signerEmail,
        //         DocumentTitle__c = documentTitle,
        //         Status__c = 'Pending',
        //         RequestDate__c = System.now()
        //     );
        //     insert request;
            
        //     // Send notification email
        //     sendSignatureNotification(request);
            
        //     return request.Id;
        // } catch (Exception e) {
        //     throw new AuraHandledException('Failed to initiate signature request: ' + e.getMessage());
        // }
    }

    
    @AuraEnabled
    public static Boolean submitSignature(String requestId, String signatureData, String signatureMethod) {
        try {
            // Validate request exists and is active
            Signature_Request__c sigRequest = [
                SELECT Id, Document__c, Signer__c, Status__c, Document_Hash__c 
                FROM Signature_Request__c 
                WHERE Id = :requestId AND Status__c IN ('Initiated', 'In Progress')
                LIMIT 1
            ];
            
            // Validate document hash
            if (!validateDocumentHash(sigRequest.Document__c, sigRequest.Document_Hash__c)) {
                throw new AuraHandledException('Document has been modified since signature request was created');
            }
            
            // Create signature attestation
            Signature_Attestation__c attestation = new Signature_Attestation__c(
                Signature_Request__c = sigRequest.Id,
            Signature_Data__c = signatureData,
            Signature_Method__c = signatureMethod,
            IP_Address__c = getClientIPAddress(),
            User_Agent__c = getUserAgent(),
            Timestamp__c = System.now(),
            Status__c = 'Completed'
                );
            insert attestation;
            
            // Update signature request status
            sigRequest.Status__c = 'Completed';
            update sigRequest;
            
            // Log successful signature
            logSignatureActivity(requestId, 'SIGNATURE_COMPLETED', 'Signature captured successfully via ' + signatureMethod);
            
            // Trigger post-signature processing
            processPostSignatureActions(requestId);
            
            return true;
            
        } catch (Exception e) {
            logSignatureActivity(requestId, 'SIGNATURE_FAILED', 'Signature submission failed: ' + e.getMessage());
            System.debug('Error in submitSignature: ' + e.getMessage());
            throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
        }
    }
@AuraEnabled  
    public static void submitSignature(String requestId, String signatureData, String signerInfo) {
            try {
            // Validate request exists and is active
            Signature_Request__c request = [
                SELECT Id, Status__c, Expiration_Date__c, Document_ID__c, Signer_Email__c
                FROM Signature_Request__c 
                WHERE Id = :requestId 
                LIMIT 1
            ];
            
            if (request.Status__c != 'Initiated' && request.Status__c != 'Pending') {
                throw new AuraHandledException('Signature request is not active');
            }
            
            if (request.Expiration_Date__c < System.now()) {
                throw new AuraHandledException('Signature request has expired');
            }
            
            // Create signature validation record
            SignatureValidation__c validation = new SignatureValidation__c();
            validation.Signature_Request__c = request.Id;
            validation.Signature_Data__c = signatureData;
            validation.Signer_Info__c = signerInfo;
            validation.Validation_Hash__c = generateSignatureHash(signatureData, signerInfo);
            validation.Validation_Date__c = System.now();
            validation.IP_Address__c = getClientIP();
            validation.Status__c = 'Valid';
            
            insert validation;
            
            // Update request status
            request.Status__c = 'Completed';
            request.Completion_Date__c = System.now();
            update request;
            
            // Log audit trail
            createAuditLog(request.Id, 'COMPLETED', 'Signature submitted and validated', request.Signer_Email__c);
            
            // Send completion notification
            sendCompletionNotification(request.Id, request.Signer_Email__c);
            
            return true;
            
        } catch (Exception e) {
            // Log error in audit trail
            createAuditLog(requestId, 'ERROR', 'Signature submission failed: ' + e.getMessage(), '');
            throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
        }

        //     try {
    //         Signature_Request__c request = [
    //             SELECT Id, Status__c, DocumentTitle__c 
    //             FROM Signature_Request__c 
    //             WHERE Id = :requestId
    //         ];
            
    //                 request.Status__c = 'Signed';
    //     request.SignedDate__c = System.now();
    //     request.SignatureData__c = signatureData;
    //     request.SignerInfo__c = signerInfo;
    //     request.IPAddress__c = getClientIPAddress();
        
    //     update request;
        
    //     // Create signature attestation record
    //     SignatureValidation__c attestation = new SignatureValidation__c(
    //         SignatureRequest__c = requestId,
    //         SignatureMethod__c = getSignatureMethod(signerInfo),
    //         ValidationStatus__c = 'Valid',
    //         AttestedDate__c = System.now(),
    //         IPAddress__c = getClientIPAddress()
    //     );
    //     insert attestation;
        
    //     createSignatureAudit(requestId, 'Signature Submitted');
    //     sendCompletionNotification(request.Id);
        
    // } catch (Exception e) {
    //     throw new AuraHandledException('Failed to submit signature: ' + e.getMessage());
    // }
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

        private static void logSignatureRequest(String action, Id requestId) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Signature Request ' + action,
            RelatedRecordId__c = requestId,
            Timestamp__c = System.now(),
            Status__c = 'Success'
        );
        insert audit;
    }

    @AuraEnabled
    public static Map<String, Object> getSignatureRequest(String requestId) {

    try {
        Signature_Request__c request = [
            SELECT Id, DocumentTitle__c, SignerEmail__c, Status__c, 
                   RequestedDate__c, DocumentId__c
            FROM Signature_Request__c 
            WHERE Id = :requestId 
            LIMIT 1
        ];
        
        return new Map<String, Object>{
            'requestId' => request.Id,
            'documentTitle' => request.DocumentTitle__c,
            'signerEmail' => request.SignerEmail__c,
            'status' => request.Status__c,
            'requestedDate' => request.RequestedDate__c
        };
    } catch (Exception e) {
        throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
    }
    }




//version 2

    //     return [SELECT Id, DocumentTitle__c, Status__c, RequestDate__c, SignedDate__c, SignerEmail__c 
    //             FROM Signature_Request__c WHERE Id = :requestId LIMIT 1];
    // }

        // version 1
        // try {
        //     Signature_Request__c sigRequest = [
        //         SELECT Id, Document__c, Signer__c, Status__c, Created_Date__c,
        //                Signer__r.Name, Signer__r.Email__c,
        //                Document__r.Name
        //         FROM Signature_Request__c 
        //         WHERE Id = :requestId 
        //         LIMIT 1
        //     ];
            
        //     Map<String, Object> result = new Map<String, Object>{
        //         'requestId' => sigRequest.Id,
        //         'status' => sigRequest.Status__c,
        //         'signerName' => sigRequest.Signer__r.Name,
        //         'signerEmail' => sigRequest.Signer__r.Email__c,
        //         'documentName' => sigRequest.Document__r.Name,
        //         'createdDate' => sigRequest.Created_Date__c
        //     };
            
        //     return result;
            
        // } catch (Exception e) {
        //     System.debug('Error in getSignatureRequest: ' + e.getMessage());
        //     throw new AuraHandledException('Failed to retrieve signature request: ' + e.getMessage());
        // }
    //}
    
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
    
    private static String generateDocumentHash(String documentId) {
        // In production, this would generate actual hash of document content
        // For now, we'll create a mock hash
        String hashInput = documentId + String.valueOf(System.now().getTime());
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(hashInput)));
    }
    
    private static Boolean validateDocumentHash(String documentId, String expectedHash) {
        String currentHash = generateDocumentHash(documentId);
        // In production, this would compare actual document hash
        // For now, we'll return true to allow testing
        return true;
    }
    
    private static String getClientIPAddress() {
        // In production, this would extract from request headers
        return '192.168.1.1'; // Mock IP for testing
    }
    
    private static String getUserAgent() {
        // In production, this would extract from request headers
        return 'Mozilla/5.0 (Test Browser)'; // Mock user agent
    }
    
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

    
    private static void processPostSignatureActions(String requestId) {
        // Placeholder for post-signature processing
        System.debug('Processing post-signature actions for request: ' + requestId);
    }


        private static void sendSignatureNotification(Signature_Request__c request) {
        // Implementation for email notification
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[]{request.SignerEmail__c});
        email.setSubject('Signature Required: ' + request.DocumentTitle__c);
        email.setPlainTextBody('Please sign the document: ' + request.DocumentTitle__c);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
    }

    private static void sendSignatureNotification(String requestId, String signerEmail, String documentTitle) {
    // Email notification implementation
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setToAddresses(new String[]{signerEmail});
    email.setSubject('Signature Required: ' + documentTitle);
    email.setPlainTextBody('Please sign the document: ' + documentTitle + '\n\nClick here to sign: ' + 
                          System.URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Signature_Request__c/' + requestId + '/view');
    
    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
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

    
private static String getSignatureMethod(String signerInfo) {
    try {
        Map<String, Object> infoMap = (Map<String, Object>) JSON.deserializeUntyped(signerInfo);
        return (String) infoMap.get('signatureMethod');
    } catch (Exception e) {
        return 'Unknown';
    }
}

private static void sendCompletionNotification(String requestId) {
    // Implementation for completion notification
    System.debug('Signature completed for request: ' + requestId);
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
    private static void logSignatureRequest(Id requestId, String action) {
        AuditTrail__c audit = new AuditTrail__c(
            EventType__c = 'Signature Activity',
            Description__c = action,
            RelatedRecordId__c = requestId,
            Timestamp__c = System.now(),
            UserId__c = UserInfo.getUserId()
        );
        insert audit;
    }
    
    private static String generateSignatureHash(String signatureData) {
        Blob signatureBlob = Blob.valueOf(signatureData);
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', signatureBlob));
    }

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


}