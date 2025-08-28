public class PhaseResult {
    public String phaseName;
    public String status;
    public String message;
    public DateTime executionTime;
    
    public PhaseResult(String phaseName, String status, String message) {
        this.phaseName = phaseName;
        this.status = status;
        this.message = message;
        this.executionTime = DateTime.now();
    }
}