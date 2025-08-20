public with sharing class DocumentGenerationController {
    
    @AuraEnabled
    public static String createDocumentRequest(
        String documentType, 
        String region, 
        String role, 
        String templateId, 
        String clauseContent
    ) {
        try {
            // Create document generation request
            DocumentGenerationRequest__c request = new DocumentGenerationRequest__c(
                DocumentType__c = documentType,
                Region__c = region,
                Role__c = role,
                TemplateId__c = templateId,
                ClauseContent__c = clauseContent,
                Status__c = 'Generated',
                GeneratedDate__c = System.now(),
                RequestedBy__c = UserInfo.getUserId()
            );
            insert request;
            
            // Create audit trail
            AuditTrail__c audit = new AuditTrail__c(
                Action__c = 'Document Generated',
                Details__c = 'Document Type: ' + documentType + ', Region: ' + region,
                Timestamp__c = System.now(),
                UserId__c = UserInfo.getUserId(),
                RelatedRecordId__c = request.Id
            );
            insert audit;
            
            return request.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to create document: ' + e.getMessage());
        }
    }
        @AuraEnabled
    public static String createDocumentRequest(
        String documentType, 
        String region, 
        String role, 
        String clauseContent,
        String additionalRequirements,
        String complianceStatus
    ) {
        try {
            DocumentLifecycleConfiguration__c docRequest = new DocumentLifecycleConfiguration__c(
                Region__c = region,
                Role__c = role,
                ContractType__c = documentType,
                Clauses__c = clauseContent,
                ComplianceStatus__c = complianceStatus,
                OutputFormat__c = 'PDF',
                CreatedBy__c = UserInfo.getUserId(),
                CreatedDate__c = System.now()
            );
            
            // Add additional requirements if provided
            if (String.isNotBlank(additionalRequirements)) {
                docRequest.Clauses__c += '\n\nAdditional Requirements:\n' + additionalRequirements;
            }
            
            insert docRequest;
            
            // Create audit trail
            createDocumentAudit(docRequest.Id, 'Document Request Created');
            
            return docRequest.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to create document request: ' + e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAvailableTemplates(String documentType, String region) {
        try {
            List<Map<String, Object>> templates = new List<Map<String, Object>>();
            
            // Query available templates based on type and region
            List<DocumentTemplate__c> templateRecords = [
                SELECT Id, Name, TemplateType__c, Region__c, Description__c
                FROM DocumentTemplate__c 
                WHERE TemplateType__c = :documentType 
                AND Region__c = :region 
                AND IsActive__c = true
                LIMIT 10
            ];
            
            for (DocumentTemplate__c template : templateRecords) {
                templates.add(new Map<String, Object>{
                    'id' => template.Id,
                    'name' => template.Name,
                    'type' => template.TemplateType__c,
                    'region' => template.Region__c,
                    'description' => template.Description__c
                });
            }
            
            // If no templates found, return default options
            if (templates.isEmpty()) {
                templates.add(new Map<String, Object>{
                    'id' => 'default',
                    'name' => 'Standard ' + documentType + ' Template',
                    'type' => documentType,
                    'region' => region,
                    'description' => 'Default template for ' + region + ' region'
                });
            }
            
            return templates;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve templates: ' + e.getMessage());
        }
    }

    
    @AuraEnabled(cacheable=true)
    public static DocumentGenerationRequest__c getDocumentRequest(String requestId) {
        return [
            SELECT Id, DocumentType__c, Region__c, Role__c, Status__c, 
                   ClauseContent__c, GeneratedDate__c
            FROM DocumentGenerationRequest__c 
            WHERE Id = :requestId 
            LIMIT 1
        ];
    }
        private static void createDocumentAudit(String documentId, String action) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = action,
            RelatedRecordId__c = documentId,
            Timestamp__c = System.now(),
            UserId__c = UserInfo.getUserId(),
            Details__c = 'Document generation request processed'
        );
        insert audit;
    }

}
