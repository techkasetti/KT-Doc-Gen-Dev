public class DocumentAnalysisResult { 
    
    public List<String> keyTopics; 
    public String primaryLanguage; 
    public Integer pageCount; 
    public Integer wordCount; 
    public Integer characterCount; 
    public String documentComplexity; 
    public Decimal readabilityScore; 
    public List<String> contentCategories; 
    public List<String> extractedEntities; 
    public String sentimentAnalysis; 
    public String analysisError; 
    
    public DocumentAnalysisResult() { 
        this.keyTopics = new List<String>(); 
        this.contentCategories = new List<String>(); 
        this.extractedEntities = new List<String>(); 
    } 
}
