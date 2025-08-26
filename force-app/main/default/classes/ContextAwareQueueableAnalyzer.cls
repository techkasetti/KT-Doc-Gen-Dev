/**
 * Queueable Job for Real-time Context Analysis
 */
public class ContextAwareQueueableAnalyzer implements Queueable, Database.AllowsCallouts {
    
    private String folderId;
    private String aiModel;
    private String callbackId;

    public ContextAwareQueueableAnalyzer(String folderId, String aiModel, String callbackId) {
        this.folderId = folderId;
        this.aiModel = aiModel;
        this.callbackId = callbackId;
    }

    public void execute(QueueableContext context) {
        try {
            // Perform context-aware analysis using Document Engine
            ContextAwareDocumentEngine.FolderContextAnalysis analysis = 
                ContextAwareDocumentEngine.analyzeFolderContext(this.folderId, this.aiModel);

            // Store analysis results in custom object for retrieval
            Folder_Context_Analysis__c analysisRecord = new Folder_Context_Analysis__c();
            analysisRecord.Folder_Id__c          = this.folderId;
            analysisRecord.AI_Model__c           = this.aiModel;
            analysisRecord.Analysis_Data__c      = JSON.serialize(analysis);
            analysisRecord.Analysis_Status__c    = 'COMPLETED';
            analysisRecord.Callback_Id__c        = this.callbackId;
            analysisRecord.Analysis_Timestamp__c = DateTime.now();
            analysisRecord.Document_Count__c     = (analysis.documents != null) ? analysis.documents.size() : 0;

            insert analysisRecord;

            // Publish platform event to notify completion
            Context_Analysis_Complete__e completionEvent = new Context_Analysis_Complete__e();
            completionEvent.Folder_Id__c           = this.folderId;
            completionEvent.Callback_Id__c         = this.callbackId;
            completionEvent.Analysis_Record_Id__c  = analysisRecord.Id;
            completionEvent.Status__c              = 'SUCCESS';
            
            EventBus.publish(completionEvent);

        } catch (Exception e) {
            // Handle errors and publish failure event
            System.debug('Error in queueable context analysis: ' + e.getMessage());
            
            Context_Analysis_Complete__e errorEvent = new Context_Analysis_Complete__e();
            errorEvent.Folder_Id__c       = this.folderId;
            errorEvent.Callback_Id__c     = this.callbackId;
            errorEvent.Status__c          = 'ERROR';
            errorEvent.Error_Message__c   = e.getMessage();
            
            EventBus.publish(errorEvent);
        }
    }
}
