public with sharing class DocumentViewController {
    
    // Document Retrieval and Processing Methods
    @AuraEnabled(cacheable=true)
    public static DocumentWrapper getDocumentContent(Id documentId) {
        try {
            ContentDocument doc = [
                SELECT Id, Title, FileExtension, ContentSize, CreatedDate, LastModifiedDate,
                       CreatedBy.Name, LastModifiedBy.Name
                FROM ContentDocument 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            ContentVersion version = [
                SELECT Id, VersionData, VersionNumber, ReasonForChange
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true 
                LIMIT 1
            ];
            
            DocumentWrapper wrapper = new DocumentWrapper();
            wrapper.documentId = doc.Id;
            wrapper.title = doc.Title;
            wrapper.fileExtension = doc.FileExtension;
            wrapper.contentSize = doc.ContentSize;
            wrapper.createdBy = doc.CreatedBy.Name;
            wrapper.createdDate = doc.CreatedDate.format('MMM dd, yyyy');
            wrapper.lastModifiedBy = doc.LastModifiedBy.Name;
            wrapper.versionNumber = version.VersionNumber;
            wrapper.reasonForChange = version.ReasonForChange;
            
            // Get document content based on file type
            if (doc.FileExtension == 'pdf') {
                wrapper.content = EncodingUtil.base64Encode(version.VersionData);
                wrapper.contentType = 'application/pdf';
            } else {
                wrapper.content = version.VersionData.toString();
                wrapper.contentType = 'text/plain';
            }
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving document: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static ComplianceAnalysisResult analyzeDocumentCompliance(Id documentId) {
        try {
            ComplianceAnalysisResult result = new ComplianceAnalysisResult();
            
            // Get document content
            ContentVersion version = [
                SELECT VersionData, ContentDocument.Title
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true 
                LIMIT 1
            ];
            
            String documentContent = version.VersionData.toString();
            
            // Analyze compliance using AI service
            ComplianceEngine engine = new ComplianceEngine();
            result = engine.analyzeCompliance(documentContent, documentId);
            
            // Store compliance results
            DocumentComplianceTracking__c tracking = new DocumentComplianceTracking__c();
            tracking.Document_ID__c = documentId;
            tracking.Compliance_Score__c = result.complianceScore;
            tracking.GDPR_Compliant__c = result.gdprCompliant;
            tracking.HIPAA_Compliant__c = result.hipaaCompliant;
            tracking.Analysis_Date__c = System.now();
            insert tracking;
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Compliance analysis failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String updateSignatureStatus(Id documentId, String signatureStatus, String signerEmail) {
        try {
            DocumentSignatureTracking__c signatureRecord = new DocumentSignatureTracking__c();
            signatureRecord.Document_ID__c = documentId;
            signatureRecord.Signer_Email__c = signerEmail;
            signatureRecord.Signature_Status__c = signatureStatus;
            signatureRecord.Signature_Date__c = System.now();
            signatureRecord.IP_Address__c = ''; // Would be populated from request context
            insert signatureRecord;
            
            // Update document status
            ContentDocument doc = [SELECT Id FROM ContentDocument WHERE Id = :documentId];
            // Custom field update logic would go here
            
            return 'SUCCESS';
            
        } catch (Exception e) {
            throw new AuraHandledException('Signature update failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String generateDocumentHash(Id documentId) {
        try {
            ContentVersion version = [
                SELECT VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true 
                LIMIT 1
            ];
            
            Blob documentBlob = version.VersionData;
            Blob hashBlob = Crypto.generateDigest('SHA-256', documentBlob);
            String documentHash = EncodingUtil.convertToHex(hashBlob);
            
            // Store hash for integrity verification
            DocumentIntegrityTracking__c integrity = new DocumentIntegrityTracking__c();
            integrity.Document_ID__c = documentId;
            integrity.Document_Hash__c = documentHash;
            integrity.Hash_Algorithm__c = 'SHA-256';
            integrity.Generated_Date__c = System.now();
            insert integrity;
            
            return documentHash;
            
        } catch (Exception e) {
            throw new AuraHandledException('Hash generation failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void trackDocumentView(Id documentId, Id userId) {
        try {
            DocumentViewTracking__c viewRecord = new DocumentViewTracking__c();
            viewRecord.Document_ID__c = documentId;
            viewRecord.User_ID__c = userId;
            viewRecord.View_Date__c = System.now();
            viewRecord.Session_Duration__c = 0; // Would be updated on session end
            insert viewRecord;
            
        } catch (Exception e) {
            System.debug('View tracking failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<CollaboratorWrapper> getCollaborators(Id documentId) {
        try {
            List<CollaboratorWrapper> collaborators = new List<CollaboratorWrapper>();
            
            List<ContentDocumentLink> links = [
                SELECT LinkedEntityId, LinkedEntity.Name, LinkedEntity.Type,
                       ShareType, Visibility
                FROM ContentDocumentLink 
                WHERE ContentDocumentId = :documentId
            ];
            
            for (ContentDocumentLink link : links) {
                CollaboratorWrapper wrapper = new CollaboratorWrapper();
                wrapper.entityId = link.LinkedEntityId;
                wrapper.entityName = link.LinkedEntity.Name;
                wrapper.entityType = link.LinkedEntity.Type;
                wrapper.shareType = link.ShareType;
                wrapper.visibility = link.Visibility;
                collaborators.add(wrapper);
            }
            
            return collaborators;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving collaborators: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String exportToPDF(Id documentId, Map<String, Object> exportOptions) {
        try {
            // Get document content
            DocumentWrapper docWrapper = getDocumentContent(documentId);
            
            // Use PDF generation service
            PDFGenerationService pdfService = new PDFGenerationService();
            Blob pdfBlob = pdfService.convertToPDF(docWrapper.content, exportOptions);
            
            // Create new PDF version
            ContentVersion pdfVersion = new ContentVersion();
            pdfVersion.ContentDocumentId = documentId;
            pdfVersion.VersionData = pdfBlob;
            pdfVersion.Title = docWrapper.title + '_Export.pdf';
            pdfVersion.PathOnClient = docWrapper.title + '_Export.pdf';
            insert pdfVersion;
            
            return pdfVersion.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('PDF export failed: ' + e.getMessage());
        }
    }
    
    // Wrapper Classes
    public class DocumentWrapper {
        @AuraEnabled public Id documentId { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public Integer contentSize { get; set; }
        @AuraEnabled public String createdBy { get; set; }
        @AuraEnabled public String createdDate { get; set; }
        @AuraEnabled public String lastModifiedBy { get; set; }
        @AuraEnabled public Integer versionNumber { get; set; }
        @AuraEnabled public String reasonForChange { get; set; }
        @AuraEnabled public String content { get; set; }
        @AuraEnabled public String contentType { get; set; }
    }
    
    public class CollaboratorWrapper {
        @AuraEnabled public Id entityId { get; set; }
        @AuraEnabled public String entityName { get; set; }
        @AuraEnabled public String entityType { get; set; }
        @AuraEnabled public String shareType { get; set; }
        @AuraEnabled public String visibility { get; set; }
    }
    
    public class ComplianceAnalysisResult {
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public Boolean gdprCompliant { get; set; }
        @AuraEnabled public Boolean hipaaCompliant { get; set; }
        @AuraEnabled public List<String> violations { get; set; }
        @AuraEnabled public List<String> recommendations { get; set; }
    }
}
