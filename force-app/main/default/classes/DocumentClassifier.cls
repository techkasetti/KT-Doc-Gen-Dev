public class DocumentClassifier { 
    
    public static String classifyDocument(String documentId) { 
        try { 
            DocumentAnalysisRecord__c analysis = [ 
                SELECT Key_Topics__c 
                FROM DocumentAnalysisRecord__c 
                WHERE Document__c = :documentId 
                ORDER BY CreatedDate DESC 
                LIMIT 1 
            ]; 
            
            ContentVersion version = [ 
                SELECT Title, FileType 
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true 
                LIMIT 1 
            ]; 
            
            String title = version.Title.toLowerCase(); 
            List<String> topics = analysis.Key_Topics__c != null 
                ? analysis.Key_Topics__c.split(';') 
                : new List<String>(); 
            
            // Classification logic 
            if (title.contains('contract') || topics.contains('CONTRACT')) { 
                return 'LEGAL_CONTRACT'; 
            } else if (title.contains('invoice') || title.contains('receipt')) { 
                return 'FINANCIAL_DOCUMENT'; 
            } else if (title.contains('medical') || topics.contains('MEDICAL')) { 
                return 'HEALTHCARE_RECORD'; 
            } else if (title.contains('policy') || title.contains('procedure')) { 
                return 'POLICY_DOCUMENT'; 
            } else if (title.contains('report') || title.contains('analysis')) { 
                return 'BUSINESS_REPORT'; 
            } else { 
                return 'GENERAL_DOCUMENT'; 
            } 
        } catch (Exception e) { 
            return 'UNKNOWN'; 
        } 
    } 
}
