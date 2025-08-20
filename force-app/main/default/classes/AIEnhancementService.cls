public with sharing class AIEnhancementService {
    
    private static final String AI_SERVICE_ENDPOINT = 'callout:AnARA_AI_Service';
    private static final Integer TIMEOUT_SECONDS = 30;
    
    public class AIProcessingRequest {
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String content { get; set; }
        @AuraEnabled public String documentType { get; set; }
        @AuraEnabled public List<String> requestedAnalysis { get; set; }
        @AuraEnabled public Map<String, String> metadata { get; set; }
        
        public AIProcessingRequest() {
            this.requestedAnalysis = new List<String>();
            this.metadata = new Map<String, String>();
        }
    }
}
