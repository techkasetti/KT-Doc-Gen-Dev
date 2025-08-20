public class AIProcessingResponse {
    @AuraEnabled public String processingId { get; set; }
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String classification { get; set; }
    @AuraEnabled public List<AIInsight> insights { get; set; }
    @AuraEnabled public Map<String, Object> complianceAnalysis { get; set; }
    @AuraEnabled public List<String> suggestedClauses { get; set; }
    @AuraEnabled public Integer confidenceScore { get; set; }
    @AuraEnabled public String errorMessage { get; set; }
    
    public AIProcessingResponse() {
        this.insights = new List<AIInsight>();
        this.suggestedClauses = new List<String>();
        this.complianceAnalysis = new Map<String, Object>();
    }
}
