public class OrchestrationResult {
    public Id documentId;
    public DateTime orchestrationStartTime;
    public DateTime orchestrationEndTime;
    public Long totalOrchestrationTime;
    public String orchestrationStatus;
    public Boolean success;
    public String errorMessage;
    public String stackTrace;
    public String currentPhase;
    public List<PhaseResult> phaseResults = new List<PhaseResult>();
    public Id lifecycleTrackingId;
    public Id versionTreeId;
    public Id retentionScheduleId;
    public Id expirationPolicyId;
    public Id aiEnhancementId;
    public Id auditTrailId;
    public Decimal complianceScore;
    public Decimal aiConfidenceScore;
    public Integer complianceViolations;
    public List<String> complianceRecommendations;
}