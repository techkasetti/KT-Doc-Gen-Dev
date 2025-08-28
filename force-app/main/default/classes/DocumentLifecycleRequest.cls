public class DocumentLifecycleRequest {
    @InvocableVariable(required=true)
    public Id documentId;
    
    @InvocableVariable(required=false)
    public String requestId;
    
    @InvocableVariable(required=false)
    public Boolean enableAdvancedAnalytics = false;
    
    @InvocableVariable(required=false)
    public Boolean enableRealTimeMonitoring = false;
    
    @InvocableVariable(required=false)
    public Boolean generateComprehensiveReport = false;
}