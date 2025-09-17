public with sharing class ContextAwareDocumentEngine {
    // /**
    //  * Represents the analyzed context of a single document
    //  */
    // public class DocumentContext {
    //     @AuraEnabled public String documentId { get; set; }
    //     @AuraEnabled public String title { get; set; }
    //     @AuraEnabled public String content { get; set; }
    //     @AuraEnabled public List<String> entities { get; set; }
    //     @AuraEnabled public List<String> themes { get; set; }
    //     @AuraEnabled public Map<String, Object> metadata { get; set; }
    //     @AuraEnabled public List<Double> semanticEmbedding { get; set; }
    // }
    

    public class DocumentContext {
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String documentName { get; set; }
        @AuraEnabled public String documentType { get; set; }
        @AuraEnabled public String content { get; set; }
        @AuraEnabled public Map<String, Object> metadata { get; set; }
        @AuraEnabled public List<String> extractedEntities { get; set; }
        @AuraEnabled public Map<String, Object> semanticEmbedding { get; set; }
        @AuraEnabled public List<String> relatedDocuments { get; set; }
    }
    //     public class DocumentContext {
    //     @AuraEnabled public String documentId;
    //     @AuraEnabled public String documentName;
    //     @AuraEnabled public String contentType;
    //     @AuraEnabled public String extractedText;
    //     @AuraEnabled public Map<String, Object> metadata;
    //     @AuraEnabled public List<String> keyEntities;
    //     @AuraEnabled public String summary;
    //     @AuraEnabled public Decimal relevanceScore;
    // }
    




    // /**
    //  * Represents the comprehensive analysis of all documents in a folder
    //  */
    // public class FolderContextAnalysis {
    //     @AuraEnabled public String folderId { get; set; }
    //     @AuraEnabled public List<DocumentContext> documents { get; set; }
    //     @AuraEnabled public List<String> commonThemes { get; set; }
    //     @AuraEnabled public Map<String, Integer> entityFrequency { get; set; }
    //     @AuraEnabled public Map<String, List<String>> documentRelationships { get; set; }
    //     @AuraEnabled public List<String> contextualInsights { get; set; }
    //     @AuraEnabled public List<String> templateSuggestions { get; set; }
    // }
    

    public class FolderContextAnalysis {
        @AuraEnabled public String folderId { get; set; }
        @AuraEnabled public List<DocumentContext> documents { get; set; }
        @AuraEnabled public Map<String, Object> crossDocumentRelations { get; set; }
        @AuraEnabled public List<String> commonThemes { get; set; }
        @AuraEnabled public Map<String, Object> contextSummary { get; set; }
        @AuraEnabled public List<String> suggestedTemplates { get; set; }
    }
    //     public class FolderContextAnalysis {
    //     @AuraEnabled public List<DocumentContext> documents;
    //     @AuraEnabled public Map<String, Object> crossDocumentInsights;
    //     @AuraEnabled public List<String> sharedConcepts;
    //     @AuraEnabled public Map<String, Integer> entityFrequency;
    //     @AuraEnabled public String contextualSummary;
    //     @AuraEnabled public List<String> suggestedQuestions;
    // }


    public class EinsteinIntentResponse {
        public class IntentPrediction {
            public String label { get; set; }
            public Double probability { get; set; }
        }
        public List<IntentPrediction> probabilities { get; set; }
    }

    public class EinsteinSentimentResponse {
        public class SentimentPrediction {
            public String label { get; set; }
            public Double probability { get; set; }
        }
        public List<SentimentPrediction> probabilities { get; set; }
    }

    public class EinsteinLanguageResponse {
        public class EntityPrediction {
            public String label { get; set; }
            public String extractedText { get; set; }
        }
        public List<EntityPrediction> entities { get; set; }
    }



    @AuraEnabled
    public static FolderContextAnalysis analyzeFolderContext(String folderId, String selectedAIModel) {
        FolderContextAnalysis analysis = new FolderContextAnalysis();
        analysis.folderId = folderId;
        analysis.documents = new List<DocumentContext>();
        analysis.entityFrequency = new Map<String, Integer>();
        
        try {
            // Step 1: Retrieve all documents in the folder
            List<ContentDocument> documents = getDocumentsInFolder(folderId);
            
            // Step 2: Analyze each document
            for (ContentDocument doc : documents) {
                DocumentContext docContext = analyzeDocument(doc.Id, selectedAIModel);
                analysis.documents.add(docContext);
                aggregateEntityFrequencies(analysis.entityFrequency, docContext.entities);
            }
            
            // Step 3: Perform cross-document analysis
            analysis.documentRelationships = performCrossDocumentAnalysis(analysis.documents);
            analysis.commonThemes = extractCommonThemes(analysis.documents);
            
            // Step 4: Generate contextual insights
            analysis.contextualInsights = generateContextualInsights(analysis);
            analysis.templateSuggestions = generateTemplateSuggestions(analysis);
            
        } catch (Exception e) {
            System.debug('Folder context analysis failed: ' + e.getMessage());
        }
        
        return analysis;
     }



     
//  @AuraEnabled
//     public static Map<String, Object> analyzeFolderContext(
//         String folderId,
//         String selectedAIModel
//     ) {
//         Map<String, Object> folderContext = new Map<String, Object>();
        
//         try {
//             // --- Fetch Documents in Folder ---
//             List<ContentDocumentLink> folderDocuments = [
//                 SELECT ContentDocumentId, ContentDocument.Title,
//                        ContentDocument.FileExtension, ContentDocument.ContentSize
//                 FROM ContentDocumentLink 
//                 WHERE LinkedEntityId = :folderId
//             ];
            
//             List<Map<String, Object>> documentAnalyses = new List<Map<String, Object>>();
//             Map<String, Object> crossDocumentInsights = new Map<String, Object>();
            
//             // --- Analyze Each Document Individually ---
//             for (ContentDocumentLink docLink : folderDocuments) {
//                 Map<String, Object> docAnalysis = analyzeDocument(
//                     docLink.ContentDocumentId,
//                     selectedAIModel
//                 );
//                 documentAnalyses.add(docAnalysis);
//             }
            
//             // --- Perform Cross-Document Analysis ---
//             crossDocumentInsights = performCrossDocumentAnalysis(
//                 documentAnalyses,
//                 selectedAIModel
//             );
            
//             // --- Generate Contextual Insights ---
//             Map<String, Object> contextualInsights = generateContextualInsights(
//                 documentAnalyses,
//                 crossDocumentInsights
//             );
            
//             // --- Build Final Context Response ---
//             folderContext.put('totalDocuments', folderDocuments.size());
//             folderContext.put('documentAnalyses', documentAnalyses);
//             folderContext.put('crossDocumentInsights', crossDocumentInsights);
//             folderContext.put('contextualInsights', contextualInsights);
//             folderContext.put('analysisTimestamp', DateTime.now());
//             folderContext.put('selectedAIModel', selectedAIModel);
            
//         } catch (Exception e) {
//             folderContext.put('error', 'Context analysis failed: ' + e.getMessage());
//         }
        
//         return folderContext;
//     }
    


    //     @AuraEnabled
    // public static FolderContextAnalysis analyzeFolderContext(String folderId, String queryContext) {
    //     FolderContextAnalysis analysis = new FolderContextAnalysis();
        
    //     try {
    //         // Get all documents in the folder
    //         List<ContentDocument> folderDocs = [
    //             SELECT Id, Title, FileType, ContentSize, CreatedDate, LastModifiedDate
    //             FROM ContentDocument 
    //             WHERE Id IN (
    //                 SELECT ContentDocumentId 
    //                 FROM ContentDocumentLink 
    //                 WHERE LinkedEntityId = :folderId
    //             )
    //             ORDER BY LastModifiedDate DESC
    //         ];
            
    //         analysis.documents = new List<DocumentContext>();
    //         Map<String, Integer> allEntities = new Map<String, Integer>();
    //         List<String> allTexts = new List<String>();
            
    //         // Process each document for context extraction
    //         for (ContentDocument doc : folderDocs) {
    //             DocumentContext docContext = processDocumentForContext(doc, queryContext);
    //             analysis.documents.add(docContext);
                
    //             // Aggregate entities across documents
    //             if (docContext.keyEntities != null) {
    //                 for (String entity : docContext.keyEntities) {
    //                     allEntities.put(entity, allEntities.containsKey(entity) ? 
    //                                   allEntities.get(entity) + 1 : 1);
    //                 }
    //             }
                
    //             if (docContext.extractedText != null) {
    //                 allTexts.add(docContext.extractedText);
    //             }
    //         }
            
    //         // Generate cross-document insights
    //         analysis.entityFrequency = allEntities;
    //         analysis.sharedConcepts = extractSharedConcepts(allTexts);
    //         analysis.crossDocumentInsights = generateCrossDocumentInsights(analysis.documents);
    //         analysis.contextualSummary = generateFolderSummary(analysis.documents, queryContext);
    //         analysis.suggestedQuestions = generateSuggestedQuestions(analysis);
            
    //         return analysis;
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Context analysis failed: ' + e.getMessage());
    //     }
    // }


    // @AuraEnabled
    // public static FolderContextAnalysis analyzeFolderContext(String folderId, String selectedAIModel) {
    //     FolderContextAnalysis analysis = new FolderContextAnalysis();
    //     analysis.folderId = folderId;
    //     analysis.documents = new List<DocumentContext>();
        
    //     try {
    //         // Get all documents in folder
    //         List<ContentDocumentLink> folderDocs = [
    //             SELECT ContentDocument.Id, ContentDocument.Title, 
    //                    ContentDocument.FileType, ContentDocument.ContentSize
    //             FROM ContentDocumentLink 
    //             WHERE LinkedEntityId = :folderId
    //             AND ContentDocument.PublishStatus = 'P'
    //         ];
            
    //         // Analyze each document using selected AI model
    //         for (ContentDocumentLink docLink : folderDocs) {
    //             DocumentContext docContext = analyzeDocument(
    //                 docLink.ContentDocument.Id, 
    //                 selectedAIModel
    //             );
    //             analysis.documents.add(docContext);
    //         }
            
    //         // Perform cross-document analysis
    //         analysis = performCrossDocumentAnalysis(analysis, selectedAIModel);
            
    //         // Generate context summary and suggestions
    //         analysis = generateContextualInsights(analysis, selectedAIModel);
            
    //     } catch (Exception e) {
    //         System.debug('Error analyzing folder context: ' + e.getMessage());
    //         throw new AuraHandledException('Failed to analyze folder context: ' + e.getMessage());
    //     }
        
    //     return analysis;
    // }


    // @AuraEnabled
    // public static Map<String, Object> analyzeFolderContext(String folderId, String selectedAIModel) {
    //     Map<String, Object> result = new Map<String, Object>();
    //     List<DocumentContext> docs = new List<DocumentContext>();

    //     // Step 1: retrieve folder documents
    //     List<ContentDocument> folderDocs = retrieveFolderDocuments(folderId);

    //     for (ContentDocument doc : folderDocs) {
    //         DocumentContext dc = new DocumentContext();
    //         dc.documentId = doc.Id;
    //         dc.title = doc.Title;
    //         dc.content = extractTextContent(doc.Id);
    //         dc.analysis = analyzeDocumentWithAI(dc.content, selectedAIModel);
    //         docs.add(dc);
    //     }

    //     FolderContextAnalysis analysis = new FolderContextAnalysis();
    //     analysis.documents = docs;
    //     analysis.commonThemes = identifyCommonThemes(docs);
    //     analysis.recommendedTemplates = suggestTemplates(docs);
    //     analysis.contextQualityScore = calculateContextQualityScore(docs);
    //     analysis.summary = generateContextSummary(docs);

    //     result.put('documents', docs);
    //     result.put('analysis', analysis);
    //     return result;
    // }

    // Helper methods
    private static List<ContentDocument> retrieveFolderDocuments(String folderId) {
        return [SELECT Id, Title FROM ContentDocument WHERE Id IN 
                (SELECT ContentDocumentId FROM ContentFolderLink WHERE FolderId = :folderId)];
    }

    private static String extractTextContent(String documentId) {
        return DocumentHelper.extractTextContent(documentId);
    }

    private static Map<String, Object> analyzeDocumentWithAI(String content, String selectedAIModel) {
        if (selectedAIModel.startsWith('einstein')) {
            return analyzeWithEinstein(content, selectedAIModel);
        } else {
            return analyzeWithExternalAI(content, selectedAIModel);
        }
    }

    private static Map<String, Object> analyzeWithEinstein(String content, String model) {
        Map<String, Object> analysis = new Map<String, Object>();
        if (model == 'einstein_intent') {
            EinsteinIntentResponse resp = callEinsteinIntent(content);
            analysis.put('intent', resp);
            analysis.put('themes', extractThemesFromIntent(resp));
        } else if (model == 'einstein_sentiment') {
            EinsteinSentimentResponse resp = callEinsteinSentiment(content);
            analysis.put('sentiment', resp);
        } else if (model == 'einstein_language') {
            EinsteinLanguageResponse resp = callEinsteinLanguage(content);
            analysis.put('entities', resp.entities);
        }
        return analysis;

    }



    //  /**
    //  * Analyzes document using Einstein AI models
    //  */
    // private static DocumentContext analyzeWithEinstein(DocumentContext context, String model) {
    //     try {
    //         Map<String, Object> parameters = new Map<String, Object>{
    //             'text' => context.content,
    //             'extractEntities' => true,
    //             'extractThemes' => true
    //         };
            
    //         switch on model {
    //             when 'einstein_intent' {
    //                 context = processEinsteinIntentAnalysis(context, parameters);
    //             }
    //             when 'einstein_sentiment' {
    //                 context = processEinsteinSentimentAnalysis(context, parameters);
    //             }
    //             when 'einstein_ocr' {
    //                 context = processEinsteinOCRAnalysis(context, parameters);
    //             }
    //         }
            
    //     } catch (Exception e) {
    //         System.debug('Einstein analysis failed: ' + e.getMessage());
    //     }
        
    //     return context;
    // }


    // /** version v1
    //  * Einstein Platform Services analysis
    //  */
    // private static DocumentContext analyzeWithEinstein(DocumentContext context, String modelType) {
    //     try {
    //         context.extractedEntities = new List<String>();
    //         context.metadata = new Map<String, Object>();
            
    //         if (modelType == 'einstein_intent') {
    //             // Use Einstein Intent API
    //             String intent = callEinsteinIntentAPI(context.content);
    //             context.metadata.put('primaryIntent', intent);
    //         }
            
    //         if (modelType == 'einstein_sentiment') {
    //             // Use Einstein Sentiment API
    //             String sentiment = callEinsteinSentimentAPI(context.content);
    //             context.metadata.put('sentiment', sentiment);
    //         }
            
    //         if (modelType == 'einstein_ocr' && context.documentType.toLowerCase().contains('pdf')) {
    //             // Use Einstein OCR for PDF analysis
    //             Map<String, Object> ocrResults = callEinsteinOCRAPI(context.documentId);
    //             context.metadata.put('ocrResults', ocrResults);
    //         }
            
    //         // Extract entities using pattern matching and AI
    //         context.extractedEntities = extractEntitiesFromText(context.content);
            
    //     } catch (Exception e) {
    //         System.debug('Einstein analysis error: ' + e.getMessage());
    //     }
        
    //     return context;
    // }

    private static Map<String, Object> analyzeWithExternalAI(String content, String model) {
        Map<String, Object> analysis = new Map<String, Object>();
        analysis.put('message', 'External AI model integration placeholder for: ' + model);
        return analysis;
    }


      private static DocumentContext analyzeWithExternalAI(DocumentContext context, String aiModel) {
        try {
            AIModelManager.AIModelConfig modelConfig = getModelConfig(aiModel);
            
            if (modelConfig != null) {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(modelConfig.endpoint);
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                
                Map<String, Object> requestBody = new Map<String, Object>();
                requestBody.put('text', context.content);
                requestBody.put('model', aiModel);
                requestBody.put('parameters', modelConfig.parameters);
                
                req.setBody(JSON.serialize(requestBody));
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                    
                    context.extractedEntities = (List<String>)response.get('entities');
                    context.metadata = (Map<String, Object>)response.get('metadata');
                }
            }
            
        } catch (Exception e) {
            System.debug('External AI analysis error: ' + e.getMessage());
        }
        return context;
    }



    // /**
    //  * Analyzes document using external AI models
    //  */
    // private static DocumentContext analyzeWithExternalAI(DocumentContext context, String model) {
    //     try {
    //         Map<String, Object> parameters = new Map<String, Object>{
    //             'analyze_entities' => true,
    //             'analyze_themes' => true,
    //             'generate_embeddings' => true
    //         };
            
    //         String response = AIModelManager.processWithEinstein(model, context.content, parameters);
    //         Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response);
            
    //         context.entities = (List<String>) result.get('entities');
    //         context.themes = (List<String>) result.get('themes');
    //         context.semanticEmbedding = (List<Double>) result.get('embedding');
            
    //     } catch (Exception e) {
    //         System.debug('External AI analysis failed: ' + e.getMessage());
    //     }
        
    //     return context;
    // }

  

    // Placeholder stubs
    private static List<String> identifyCommonThemes(List<DocumentContext> docs) { return new List<String>(); }
    private static List<String> suggestTemplates(List<DocumentContext> docs) { return new List<String>(); }
    private static Double calculateContextQualityScore(List<DocumentContext> docs) { return 1.0; }
    private static String generateContextSummary(List<DocumentContext> docs) { return 'Summary'; }

    private static EinsteinIntentResponse callEinsteinIntent(String content) { return new EinsteinIntentResponse(); }
    private static List<String> extractThemesFromIntent(EinsteinIntentResponse resp) { return new List<String>(); }
    private static EinsteinSentimentResponse callEinsteinSentiment(String content) { return new EinsteinSentimentResponse(); }
    private static EinsteinLanguageResponse callEinsteinLanguage(String content) { return new EinsteinLanguageResponse(); }

    // JWT helpers
    private static String generateJwtToken(String clientId, String clientSecret) { return ''; }
    private static String base64UrlEncode(Blob input) { return ''; }

    
    public class ContextAwareGenerationRequest {
        @AuraEnabled public FolderContextAnalysis folderContext { get; set; }
        @AuraEnabled public DocumentTemplate__c template { get; set; }
        @AuraEnabled public String aiModel { get; set; }
        @AuraEnabled public Map<String, Object> parameters { get; set; }
        @AuraEnabled public String userId { get; set; }
        @AuraEnabled public String sessionId { get; set; }
    }
    
    // ===== Core Methods =====
   
            
    
    private static DocumentContext analyzeDocument(String documentId, String aiModel) {
        DocumentContext context = new DocumentContext();
        context.documentId = documentId;
        
        try {
            // Get document content
            List<ContentVersion> versions = [
                SELECT Title, FileType, VersionData, ContentSize
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true
            ];
            
            if (versions.isEmpty()) {
                return context;
            }
            
            ContentVersion version = versions[0];
            context.documentName = version.Title;
            context.documentType = version.FileType;
            
            // Extract text content
            String textContent = extractTextContent(version);
            context.content = textContent;
            
            // AI-powered analysis based on selected model
            if (aiModel.startsWith('einstein')) {
                context = analyzeWithEinstein(context, aiModel);
            } else {
                context = analyzeWithExternalAI(context, aiModel);
            }
            
            // Generate semantic embedding for similarity analysis
            context.semanticEmbedding = generateSemanticEmbedding(textContent, aiModel);
            
        } catch (Exception e) {
            System.debug('Error analyzing document: ' + e.getMessage());
        }
        
        return context;
    }
    

    //   /**
    //  * Analyzes a single document using AI to extract context
    //  */
    // private static DocumentContext analyzeDocument(String documentId, String selectedAIModel) {
    //     DocumentContext context = new DocumentContext();
    //     context.documentId = documentId;
        
    //     try {
    //         // Extract document content
    //         List<ContentVersion> versions = [
    //             SELECT Id, Title, VersionData, FileExtension
    //             FROM ContentVersion 
    //             WHERE ContentDocumentId = :documentId 
    //             AND IsLatest = true
    //         ];
            
    //         if (!versions.isEmpty()) {
    //             ContentVersion version = versions[0];
    //             context.title = version.Title;
    //             context.content = version.VersionData.toString();
                
    //             // AI-powered analysis
    //             if (selectedAIModel.startsWith('einstein_')) {
    //                 context = analyzeWithEinstein(context, selectedAIModel);
    //             } else {
    //                 context = analyzeWithExternalAI(context, selectedAIModel);
    //             }
    //         }
    //     } catch (Exception e) {
    //         System.debug('Document analysis failed for ' + documentId + ': ' + e.getMessage());
    //     }
        
    //     return context;
    // }
    



    //  private static Map<String, Object> analyzeDocument(
    //     String documentId,
    //     String selectedAIModel
    // ) {
    //     Map<String, Object> analysis = new Map<String, Object>();
        
    //     try {
    //         // --- Fetch Document Content ---
    //         ContentVersion docVersion = [
    //             SELECT Id, Title, VersionData, FileExtension
    //             FROM ContentVersion 
    //             WHERE ContentDocumentId = :documentId 
    //             AND IsLatest = true
    //         ];
            
    //         String documentText = docVersion.VersionData.toString();
            
    //         // --- Extract Metadata ---
    //         analysis.put('documentId', documentId);
    //         analysis.put('title', docVersion.Title);
    //         analysis.put('fileType', docVersion.FileExtension);
    //         analysis.put('contentLength', documentText.length());
            
    //         // --- Perform AI Analysis ---
    //         if (selectedAIModel.startsWith('einstein_')) {
    //             analysis.putAll(performEinsteinAnalysis(documentText, selectedAIModel));
    //         } else {
    //             analysis.putAll(performExternalAIAnalysis(documentText, selectedAIModel));
    //         }
            
    //         // --- Enrichment: Entities, Themes, Semantic Embeddings ---
    //         analysis.put('entities', extractEntities(documentText));
    //         analysis.put('themes', identifyThemes(documentText));
    //         analysis.put('semanticEmbedding', generateSemanticEmbedding(documentText));
            
    //     } catch (Exception e) {
    //         analysis.put('error', 'Document analysis failed: ' + e.getMessage());
    //     }
        
    //     return analysis;
    // }


    
    private static FolderContextAnalysis performCrossDocumentAnalysis(FolderContextAnalysis analysis, String aiModel) {
        try {
            analysis.crossDocumentRelations = new Map<String, Object>();
            analysis.commonThemes = new List<String>();
            
            Map<String, List<String>> documentSimilarities = new Map<String, List<String>>();
            
            for (Integer i = 0; i < analysis.documents.size(); i++) {
                DocumentContext doc1 = analysis.documents[i];
                List<String> similarDocs = new List<String>();
                
                for (Integer j = i + 1; j < analysis.documents.size(); j++) {
                    DocumentContext doc2 = analysis.documents[j];
                    
                    Decimal similarity = calculateSemanticSimilarity(
                        doc1.semanticEmbedding, 
                        doc2.semanticEmbedding
                    );
                    
                    if (similarity > 0.7) {
                        similarDocs.add(doc2.documentId);
                        
                        if (!documentSimilarities.containsKey(doc2.documentId)) {
                            documentSimilarities.put(doc2.documentId, new List<String>());
                        }
                        documentSimilarities.get(doc2.documentId).add(doc1.documentId);
                    }
                }
                
                if (!similarDocs.isEmpty()) {
                    documentSimilarities.put(doc1.documentId, similarDocs);
                    doc1.relatedDocuments = similarDocs;
                }
            }
            
            analysis.crossDocumentRelations.put('documentSimilarities', documentSimilarities);
            analysis.commonThemes = extractCommonThemes(analysis.documents, aiModel);
            
        } catch (Exception e) {
            System.debug('Cross-document analysis error: ' + e.getMessage());
        }
        
        return analysis;
    }


    //  /**
    //  * Identifies relationships between documents based on similarity
    //  */
    // private static Map<String, List<String>> performCrossDocumentAnalysis(List<DocumentContext> documents) {
    //     Map<String, List<String>> relationships = new Map<String, List<String>>();
        
    //     // Calculate semantic similarities and identify relationships
    //     for (Integer i = 0; i < documents.size(); i++) {
    //         DocumentContext doc1 = documents[i];
    //         List<String> relatedDocs = new List<String>();
            
    //         for (Integer j = i + 1; j < documents.size(); j++) {
    //             DocumentContext doc2 = documents[j];
    //             Double similarity = calculateSimilarity(doc1, doc2);
                
    //             if (similarity > 0.7) { // Threshold for relationship
    //                 relatedDocs.add(doc2.documentId);
    //             }
    //         }
            
    //         if (!relatedDocs.isEmpty()) {
    //             relationships.put(doc1.documentId, relatedDocs);
    //         }
    //     }
        
    //     return relationships;
    // }


    private static FolderContextAnalysis generateContextualInsights(FolderContextAnalysis analysis, String aiModel) {
        try {
            analysis.contextSummary = new Map<String, Object>();
            analysis.suggestedTemplates = new List<String>();
            
            Map<String, Integer> documentTypes = new Map<String, Integer>();
            Map<String, Integer> entityFrequency = new Map<String, Integer>();
            
            for (DocumentContext doc : analysis.documents) {
                String docType = doc.documentType;
                documentTypes.put(docType, documentTypes.containsKey(docType) ? 
                    documentTypes.get(docType) + 1 : 1);
                
                for (String entity : doc.extractedEntities) {
                    entityFrequency.put(entity, entityFrequency.containsKey(entity) ? 
                        entityFrequency.get(entity) + 1 : 1);
                }
            }
            
            analysis.contextSummary.put('documentTypes', documentTypes);
            analysis.contextSummary.put('entityFrequency', entityFrequency);
            analysis.contextSummary.put('totalDocuments', analysis.documents.size());
            
            analysis.suggestedTemplates = generateTemplateSuggestions(
                analysis.commonThemes, 
                documentTypes, 
                entityFrequency,
                aiModel
            );
            
        } catch (Exception e) {
            System.debug('Contextual insights error: ' + e.getMessage());
        }
        return analysis;
    }
    



    /**
     * Generates contextual insights based on folder analysis
     */
    private static List<String> generateContextualInsights(FolderContextAnalysis analysis) {
        List<String> insights = new List<String>();
        
        Integer docCount = analysis.documents.size();
        Integer themeCount = analysis.commonThemes.size();
        
        // Document and theme overview
        insights.add('Context Analysis: Found ' + docCount + ' documents with ' + themeCount + ' common themes');
        
        // Entity frequency insights
        if (!analysis.entityFrequency.isEmpty()) {
            List<String> topEntities = getTopEntities(analysis.entityFrequency, 5);
            insights.add('Key Entities: ' + String.join(topEntities, ', '));
        }
        
        // Document relationships insights
        if (!analysis.documentRelationships.isEmpty()) {
            insights.add('Document Relationships: Found ' + analysis.documentRelationships.size() + 
                        ' documents with strong thematic connections');
        }
        
        // Theme analysis
        if (!analysis.commonThemes.isEmpty()) {
            insights.add('Dominant Themes: ' + String.join(analysis.commonThemes, ', '));
        }
        
        // Contextual recommendations
        if (docCount >= 3 && themeCount >= 2) {
            insights.add('Strong Context: This folder provides excellent context for AI-powered document generation');
        } else if (docCount >= 1 && themeCount >= 1) {
            insights.add('Fair Context: Additional related documents would improve generation quality');
        } else {
            insights.add('Limited Context: Consider adding more related documents for better results');
        }
        
        return insights;
    }


    @AuraEnabled
    public static String generateContextAwareDocument(
        String folderId,
        String templateId,
        String selectedAIModel,
        Map<String, Object> generationParameters
    ) {
        try {
            FolderContextAnalysis folderContext = analyzeFolderContext(folderId, selectedAIModel);

            DocumentTemplate__c template = [
                SELECT Id, Name, Template_Content__c, Merge_Fields__c, AI_Generation_Rules__c,
                       Context_Aware_Settings__c, Required_Context_Types__c
                FROM DocumentTemplate__c 
                WHERE Id = :templateId 
                LIMIT 1
            ];

            ContextAwareGenerationRequest request = new ContextAwareGenerationRequest();
            request.folderContext = folderContext;
            request.template = template;
            request.aiModel = selectedAIModel;
            request.parameters = generationParameters;
            request.userId = UserInfo.getUserId();

            String generatedContent = performContextAwareGeneration(request);

            AuditTrailManager.logDocumentGeneration(
                templateId, 
                selectedAIModel, 
                'Context-aware generation from folder: ' + folderId
            );
            return generatedContent;

        } catch (Exception e) {
            System.debug('Context-aware generation error: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate context-aware document: ' + e.getMessage());
        }
    }


    
    // @AuraEnabled
    // public static String generateContextAwareDocument(
    //     String folderId,
    //     String templateId,
    //     String selectedAIModel,
    //     Map<String, Object> generationParameters
    // ) {
    //     try {
    //         // Step 1: Analyze folder context
    //         FolderContextAnalysis contextAnalysis = analyzeFolderContext(folderId, selectedAIModel);
            
    //         // Step 2: Retrieve template
    //         DocumentTemplate__c template = getDocumentTemplate(templateId);
            
    //         // Step 3: Generate context-aware content
    //         String generatedContent = generateContentWithContext(
    //             template, 
    //             contextAnalysis, 
    //             selectedAIModel,
    //             generationParameters
    //         );
            
    //         // Step 4: Save generated document
    //         Document__c newDoc = createGeneratedDocument(
    //             generatedContent, 
    //             templateId, 
    //             selectedAIModel, 
    //             contextAnalysis
    //         );
            
    //         insert newDoc;
    //         return newDoc.Id;
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Document generation failed: ' + e.getMessage());
    //     }
    // }

    
    private static String performContextAwareGeneration(ContextAwareGenerationRequest request) {
        try {
            Map<String, Object> generationContext = new Map<String, Object>();
            generationContext.put('folderAnalysis', request.folderContext);
            generationContext.put('templateConfig', request.template);
            generationContext.put('userPreferences', request.parameters);

            Map<String, Object> contextualData = extractContextualData(request.folderContext, request.aiModel);
            Map<String, Object> aiSuggestions = generateAISuggestions(
                request.folderContext,
                request.template,
                request.aiModel,
                contextualData
            );

            String baseContent = request.template.Template_Content__c;
            String contextEnhancedContent = mergeContextWithTemplate(
                baseContent,
                contextualData,
                aiSuggestions,
                request.aiModel
            );

            String finalContent = enhanceContentWithAI(
                contextEnhancedContent,
                request.folderContext,
                request.aiModel,
                request.parameters
            );

            logGenerationAnalytics(request, contextualData, aiSuggestions);

            return finalContent;

        } catch (Exception e) {
            System.debug('Context-aware generation execution error: ' + e.getMessage());
            throw new AuraHandledException('Generation failed: ' + e.getMessage());
        }
    }
    
    
    /**
     * Enhance content with AI-powered improvements
     */
    private static String enhanceContentWithAI(
        String content,
        FolderContextAnalysis folderContext,
        String aiModel,
        Map<String, Object> parameters
    ) {
        try {
            // Apply tone and style adjustments
            String toneSetting = (String) parameters.get('tone');
            String audienceSetting = (String) parameters.get('audience');

            if (String.isNotBlank(toneSetting) || String.isNotBlank(audienceSetting)) {
                content = adjustToneAndStyle(content, toneSetting, audienceSetting, aiModel);
            }

            // Enhance with cross-document insights
            content = addCrossDocumentInsights(content, folderContext, aiModel);

            // Apply compliance enhancements
            Boolean includeCompliance = (Boolean) parameters.get('includeCompliance');
            if (includeCompliance == true) {
                content = addComplianceContent(content, folderContext, aiModel);
            }

            // Add executive summary
            Boolean includeExecutiveSummary = (Boolean) parameters.get('includeExecutiveSummary');
            if (includeExecutiveSummary == true) {
                String executiveSummary = generateExecutiveSummary(folderContext, aiModel);
                content = executiveSummary + '\n\n' + content;
            }

            // Final optimization
            content = optimizeContentFlow(content, aiModel);

            return content;

        } catch (Exception e) {
            System.debug('Error enhancing content with AI: ' + e.getMessage());
            return content;
        }
    }

    
    /**
     * Merge contextual data with template using AI insights
     */
    private static String mergeContextWithTemplate(String baseContent,Map<String, Object> contextualData,Map<String, Object> aiSuggestions,String aiModel) {
        try {
            String mergedContent = baseContent;

            // Apply field suggestions
            Map<String, String> fieldSuggestions = 
                (Map<String, String>) aiSuggestions.get('fieldSuggestions');

            if (fieldSuggestions != null) {
                for (String field : fieldSuggestions.keySet()) {
                    String suggestion = fieldSuggestions.get(field);
                    mergedContent = mergedContent.replace('{{' + field + '}}', suggestion);
                }
            }

            // Apply contextual merge fields
            Map<String, Object> mergeFields = 
                (Map<String, Object>) contextualData.get('mergeFields');

            if (mergeFields != null) {
                for (String fieldName : mergeFields.keySet()) {
                    Object fieldValue = mergeFields.get(fieldName);
                    String valueStr = fieldValue != null ? String.valueOf(fieldValue) : '';
                    mergedContent = mergedContent.replace('{{' + fieldName + '}}', valueStr);
                }
            }

            // Insert citations and references
            List<Map<String, Object>> citations = 
                (List<Map<String, Object>>) aiSuggestions.get('citations');

            if (citations != null && !citations.isEmpty()) {
                mergedContent = insertCitations(mergedContent, citations);
            }

            // Apply section recommendations
            Map<String, List<String>> sectionRecs = 
                (Map<String, List<String>>) aiSuggestions.get('sectionRecommendations');

            if (sectionRecs != null) {
                mergedContent = applySectionRecommendations(mergedContent, sectionRecs);
            }

            return mergedContent;

        } catch (Exception e) {
            System.debug('Error merging context with template: ' + e.getMessage());
            return baseContent;
        }
    }
    
    private static Map<String, Object> generateAISuggestions(FolderContextAnalysis folderContext,DocumentTemplate__c template,String aiModel,Map<String, Object> contextualData) {
    Map<String, Object> suggestions = new Map<String, Object>();

    try {
        // Analyze template requirements
        List<String> templateFields = extractTemplateFields(template.Template_Content__c);
        Map<String, Object> templateContext = parseTemplateContext(template);

        // Generate field-specific suggestions
        Map<String, String> fieldSuggestions = new Map<String, String>();

        for (String field : templateFields) {
            String suggestion = generateFieldSuggestion(field, contextualData, folderContext, aiModel);
            if (String.isNotBlank(suggestion)) {
                fieldSuggestions.put(field, suggestion);
            }
        }

        suggestions.put('fieldSuggestions', fieldSuggestions);

        // Generate section-wise content recommendations
        Map<String, List<String>> sectionRecommendations = generateSectionRecommendations(
            template,
            contextualData,
            folderContext,
            aiModel
        );
        suggestions.put('sectionRecommendations', sectionRecommendations);

        // Context-aware clause suggestions
        List<Map<String, Object>> clauseSuggestions = generateClauseSuggestions(
            folderContext,
            templateContext,
            aiModel
        );
        suggestions.put('clauseSuggestions', clauseSuggestions);

        // Citation recommendations
        List<Map<String, Object>> citationRecommendations = generateCitationRecommendations(
            folderContext,
            contextualData
        );
        suggestions.put('citations', citationRecommendations);
        } catch (Exception e) {
        System.debug('Error generating AI suggestions: ' + e.getMessage());
        }
        return suggestions;
    }


    /**
    * Extract contextual data from analyzed folder documents
    */
    private static Map<String, Object> extractContextualData(
    FolderContextAnalysis folderContext,
    String aiModel
    ) {
        Map<String, Object> contextualData = new Map<String, Object>();

        try {
            // Aggregate entities across all documents
            Map<String, Integer> aggregatedEntities = new Map<String, Integer>();
            Map<String, List<String>> entitySources = new Map<String, List<String>>();

            for (DocumentContext doc : folderContext.documents) {
                for (String entity : doc.extractedEntities) {
                    // Count entity frequency
                    aggregatedEntities.put(entity, 
                    aggregatedEntities.containsKey(entity) ? 
                    aggregatedEntities.get(entity) + 1 : 1
                    );

                    // Track entity sources for citation
                    if (!entitySources.containsKey(entity)) {
                        entitySources.put(entity, new List<String>());
                    }
                    entitySources.get(entity).add(doc.documentName);
                }
            }

            contextualData.put('aggregatedEntities', aggregatedEntities);
            contextualData.put('entitySources', entitySources);

            // Extract key themes and patterns
            List<String> keyThemes = extractKeyThemes(folderContext, aiModel);
            contextualData.put('keyThemes', keyThemes);

            // Generate contextual merge field values
            Map<String, Object> contextMergeFields = generateContextMergeFields(
            folderContext,
            aggregatedEntities,
            aiModel
            );
            contextualData.put('mergeFields', contextMergeFields);

            // Cross-document insights
            Map<String, Object> crossDocInsights = generateCrossDocumentInsights(
            folderContext,
            aiModel
            );
            contextualData.put('crossDocumentInsights', crossDocInsights);

            // Timeline and chronological data
            List<Map<String, Object>> timeline = extractTimelineData(folderContext);
            contextualData.put('timeline', timeline);

        } catch (Exception e) {
            System.debug('Error extracting contextual data: ' + e.getMessage());
        }

        return contextualData;
    }
    // ===== Einstein Integration =====
     /**
     * Einstein Platform Services integration methods
     */

    private static String callEinsteinIntentAPI(String text) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Einstein_Platform/v2/language/intent');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + getEinsteinAccessToken());
            req.setHeader('Content-Type', 'application/json');

            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('document', text);
            req.setBody(JSON.serialize(requestBody));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> probabilities = (List<Object>) response.get('probabilities');
                if (!probabilities.isEmpty()) {
                    Map<String, Object> topIntent = (Map<String, Object>) probabilities[0];
                    return (String) topIntent.get('label');
                }
            }
        } catch (Exception e) {
            System.debug('Einstein Intent API error: ' + e.getMessage());
        }
        return 'UNKNOWN';
    }

    
    private static String callEinsteinSentimentAPI(String text) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Einstein_Platform/v2/language/sentiment');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + getEinsteinAccessToken());
            req.setHeader('Content-Type', 'application/json');

            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('document', text);
            req.setBody(JSON.serialize(requestBody));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> probabilities = (List<Object>) response.get('probabilities');
                if (!probabilities.isEmpty()) {
                    Map<String, Object> topSentiment = (Map<String, Object>) probabilities[0];
                    return (String) topSentiment.get('label');
                }
            }
        } catch (Exception e) {
            System.debug('Einstein Sentiment API error: ' + e.getMessage());
        }
        return 'NEUTRAL';
    }
  private static Map<String, Object> callEinsteinOCRAPI(String documentId) {
        Map<String, Object> results = new Map<String, Object>();
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Einstein_Platform/v2/vision/ocr');
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + getEinsteinAccessToken());

            List<ContentVersion> versions = [
                SELECT VersionData FROM ContentVersion 
                WHERE ContentDocumentId = :documentId AND IsLatest = true LIMIT 1
            ];

            if (!versions.isEmpty()) {
                req.setBodyAsBlob(versions[0].VersionData);
                req.setHeader('Content-Type', 'application/octet-stream');

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200) {
                    results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                }
            }
        } catch (Exception e) {
            System.debug('Einstein OCR API error: ' + e.getMessage());
            results.put('error', e.getMessage());
        }
        return results;
    } 

    

    /**
     * Get Einstein Platform Services access token
     */
    private static String getEinsteinAccessToken() {
        try {
            String token = Cache.Org.get('einstein_access_token');
            if (String.isBlank(token)) {
                token = refreshEinsteinToken();
                Cache.Org.put('einstein_access_token', token, 3600); // 1 hour cache
            }
            return token;
        } catch (Exception e) {
            System.debug('Error getting Einstein access token: ' + e.getMessage());
            return '';
        }
    }


    
    /**
     * Process individual document to extract context
     */
    private static DocumentContext processDocumentForContext(ContentDocument doc, String queryContext) {
        DocumentContext context = new DocumentContext();
        context.documentId   = doc.Id;
        context.documentName = doc.Title;
        context.contentType  = doc.FileType;
        
        try {
            // Fetch latest document version
            ContentVersion version = [
                SELECT VersionData, Title
                FROM ContentVersion
                WHERE ContentDocumentId = :doc.Id
                AND IsLatest = true
                LIMIT 1
            ];
            
            // Extract text based on file type
            if (doc.FileType == 'PDF') {
                context.extractedText = extractTextFromPDF(version.VersionData);
            } else if (doc.FileType == 'DOCX') {
                context.extractedText = extractTextFromWord(version.VersionData);
            } else {
                context.extractedText = version.VersionData.toString();
            }
            
            // Use Einstein Language for NLP tasks
            context.keyEntities   = extractEntitiesWithEinstein(context.extractedText);
            context.summary       = summarizeWithEinstein(context.extractedText, 200);
            context.relevanceScore = calculateRelevanceScore(context.extractedText, queryContext);
            
            // Populate metadata
            context.metadata = new Map<String, Object>{
                'fileSize'     => doc.ContentSize,
                'createdDate'  => doc.CreatedDate,
                'lastModified' => doc.LastModifiedDate,
                'wordCount'    => context.extractedText != null 
                                  ? context.extractedText.split(' ').size() 
                                  : 0
            };
            
        } catch (Exception e) {
            System.debug('Error processing document context: ' + e.getMessage());
            context.extractedText = '[Content extraction failed]';
            context.summary       = 'Unable to process document content';
        }
        
        return context;
    }
    
    // 🔹 TODO: Implement the following helper methods
    // private static List<String> extractSharedConcepts(List<String> texts) { ... }
    // private static Map<String, Object> generateCrossDocumentInsights(List<DocumentContext> docs) { ... }
    // private static String generateFolderSummary(List<DocumentContext> docs, String queryContext) { ... }
    // private static List<String> generateSuggestedQuestions(FolderContextAnalysis analysis) { ... }
    // private static String extractTextFromPDF(Blob fileData) { ... }
    // private static String extractTextFromWord(Blob fileData) { ... }
    // private static List<String> extractEntitiesWithEinstein(String text) { ... }
    // private static String summarizeWithEinstein(String text, Integer length) { ... }
    // private static Decimal calculateRelevanceScore(String text, String queryContext) { ... }



    
    @AuraEnabled
    public static String askContextualQuestion(
        String folderId, 
        String question, 
        String selectedModel, 
        String folderContextJson
    ) {
        try {
            FolderContextAnalysis folderContext = 
                (FolderContextAnalysis) JSON.deserialize(folderContextJson, FolderContextAnalysis.class);
            
            // Build comprehensive context from all documents
            String contextualPrompt = buildContextualPrompt(question, folderContext);
            
            // Process with selected AI model
            String response = AIModelManager.processWithEinstein(selectedModel, question, contextualPrompt);
            
            // Add source attribution (Anara-style)
            response = addSourceAttribution(response, folderContext.documents);
            
            return response;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to process contextual question: ' + e.getMessage());
        }
    }
    

     @AuraEnabled
    public static String askContextualQuestion(
        String folderId,
        String question,
        String selectedAIModel
    ) {
        try {
            // Analyze folder context for the question
            FolderContextAnalysis contextAnalysis = analyzeFolderContext(folderId, selectedAIModel);
            
            // Build question prompt with context
            String prompt = buildQuestionPrompt(question, contextAnalysis);
            
            // Process with AI
            Map<String, Object> parameters = new Map<String, Object>{
                'context' => contextAnalysis,
                'question_type' => 'contextual_query'
            };
            
            return AIModelManager.processWithEinstein(selectedAIModel, prompt, parameters);
            
        } catch (Exception e) {
            throw new AuraHandledException('Question processing failed: ' + e.getMessage());
        }
    }
    
    private static String buildContextualPrompt(String question, FolderContextAnalysis folderContext) {
        StringBuilder contextBuilder = new StringBuilder();
        
        // Add folder-level context (Anara-style)
        contextBuilder.append('=== DOCUMENT COLLECTION CONTEXT ===\n');
        contextBuilder.append('Total Documents: ' + folderContext.documents.size() + '\n');
        contextBuilder.append('Collection Summary: ' + folderContext.contextualSummary + '\n');
        contextBuilder.append('Key Shared Concepts: ' + String.join(folderContext.sharedConcepts, ', ') + '\n\n');
        
        // Add individual document contexts with relevance scoring
        contextBuilder.append('=== INDIVIDUAL DOCUMENT CONTEXTS ===\n');
        for (DocumentContext doc : folderContext.documents) {
            if (doc.relevanceScore > 0.3) { // Only include relevant documents
                contextBuilder.append('Document: ' + doc.documentName + '\n');
                contextBuilder.append('Relevance Score: ' + doc.relevanceScore.setScale(2) + '\n');
                contextBuilder.append('Summary: ' + doc.summary + '\n');
                contextBuilder.append('Key Entities: ' + String.join(doc.keyEntities, ', ') + '\n');
                contextBuilder.append('Content Preview: ' + getTruncatedContent(doc.extractedText, 500) + '\n');
                contextBuilder.append('---\n');
            }
        }
        
        // Add cross-document insights
        contextBuilder.append('=== CROSS-DOCUMENT INSIGHTS ===\n');
        if (folderContext.crossDocumentInsights != null) {
            for (String key : folderContext.crossDocumentInsights.keySet()) {
                contextBuilder.append(key + ': ' + folderContext.crossDocumentInsights.get(key) + '\n');
            }
        }
        
        // Add user question
        contextBuilder.append('\n=== USER QUESTION ===\n');
        contextBuilder.append(question);
        
        return contextBuilder.toString();
    }
    
    private static String addSourceAttribution(String response, List<DocumentContext> documents) {
        StringBuilder attributedResponse = new StringBuilder();
        attributedResponse.append(response);
        attributedResponse.append('\n\n=== SOURCES REFERENCED ===\n');
        
        // Anara-style source attribution
        Integer sourceCount = 1;
        for (DocumentContext doc : documents) {
            if (doc.relevanceScore > 0.5) { // High relevance documents
                attributedResponse.append('[' + sourceCount + '] ' + doc.documentName);
                attributedResponse.append(' (Relevance: ' + doc.relevanceScore.setScale(1) + ')');
                attributedResponse.append(' - ' + doc.summary.substring(0, Math.min(100, doc.summary.length())) + '...\n');
                sourceCount++;
            }
        }
        
        return attributedResponse.toString();
    }
    
    // Enhanced document generation with full context awareness
    @AuraEnabled
    public static String generateContextualDocument(
        String folderId, 
        String templateId, 
        String selectedAIModel, 
        Map<String, Object> generationParameters
    ) {
        try {
            // Get fresh folder context for generation
            FolderContextAnalysis folderContext = analyzeFolderContext(folderId, 'document_generation');
            
            // Get template configuration
            Document_Template__c template = [
                SELECT Id, Name, Template_Content__c, Template_Type__c, AI_Instructions__c
                FROM Document_Template__c 
                WHERE Id = :templateId 
                LIMIT 1
            ];
            
            // Build generation prompt with full context
            String generationPrompt = buildGenerationPrompt(template, folderContext, generationParameters);
            
            // Process with selected AI model
            String generatedContent = AIModelManager.processWithEinstein(selectedAIModel, generationPrompt, '');
            
            // Post-process and enhance content
            String enhancedContent = enhanceGeneratedContent(generatedContent, folderContext);
            
            // Save generated document
            String documentId = saveGeneratedDocument(enhancedContent, template, folderContext, selectedAIModel);
            
            return enhancedContent;
        } catch (Exception e) {
            throw new AuraHandledException('Document generation failed: ' + e.getMessage());
        }
    }
    
    private static String buildGenerationPrompt(
        Document_Template__c template, 
        FolderContextAnalysis folderContext, 
        Map<String, Object> parameters
    ) {
        StringBuilder promptBuilder = new StringBuilder();
        
        // Template instructions
        promptBuilder.append('=== DOCUMENT GENERATION INSTRUCTIONS ===\n');
        promptBuilder.append('Template: ' + template.Name + '\n');
        promptBuilder.append('Type: ' + template.Template_Type__c + '\n');
        promptBuilder.append('AI Instructions: ' + template.AI_Instructions__c + '\n\n');
        
        // Generation parameters
        promptBuilder.append('=== GENERATION PARAMETERS ===\n');
        for (String key : parameters.keySet()) {
            promptBuilder.append(key + ': ' + parameters.get(key) + '\n');
        }
        promptBuilder.append('\n');
        
        // Full folder context (Anara-style comprehensive context)
        promptBuilder.append('=== CONTEXTUAL KNOWLEDGE BASE ===\n');
        promptBuilder.append('Document Collection Analysis:\n');
        promptBuilder.append('- Total Documents: ' + folderContext.documents.size() + '\n');
        promptBuilder.append('- Collection Theme: ' + folderContext.contextualSummary + '\n');
        promptBuilder.append('- Key Concepts: ' + String.join(folderContext.sharedConcepts, ', ') + '\n\n');
        
        // Document-specific knowledge
        promptBuilder.append('Document Knowledge Base:\n');
        for (DocumentContext doc : folderContext.documents) {
            promptBuilder.append('• ' + doc.documentName + ':\n');
            promptBuilder.append('  Summary: ' + doc.summary + '\n');
            promptBuilder.append('  Key Points: ' + String.join(doc.keyEntities, ', ') + '\n');
            promptBuilder.append('  Content: ' + getTruncatedContent(doc.extractedText, 1000) + '\n\n');
        }
        
        // Cross-document insights
        promptBuilder.append('=== CROSS-DOCUMENT INSIGHTS ===\n');
        if (folderContext.crossDocumentInsights != null) {
            for (String insight : folderContext.crossDocumentInsights.keySet()) {
                promptBuilder.append('- ' + insight + ': ' + folderContext.crossDocumentInsights.get(insight) + '\n');
            }
        }
        
        // Template content
        promptBuilder.append('\n=== TEMPLATE STRUCTURE ===\n');
        promptBuilder.append(template.Template_Content__c);
        
        // Generation requirements
        promptBuilder.append('\n\n=== GENERATION REQUIREMENTS ===\n');
        promptBuilder.append('Generate a comprehensive document that:\n');
        promptBuilder.append('1. Leverages insights from ALL documents in the collection\n');
        promptBuilder.append('2. Maintains consistency with the established themes and concepts\n');
        promptBuilder.append('3. Includes proper citations and references to source documents\n');
        promptBuilder.append('4. Follows the template structure while incorporating contextual intelligence\n');
        promptBuilder.append('5. Provides value-added insights through cross-document analysis\n');
        
        return promptBuilder.toString();

    }

    
   
    
    // ==================== INNER CLASSES ====================
    
    
    /**
     * Helper class for sorting entities by frequency
     */
    private class EntityFrequency implements Comparable {
        public String entity;
        public Integer frequency;
        
        public EntityFrequency(String entity, Integer frequency) {
            this.entity = entity;
            this.frequency = frequency;
        }
        
        public Integer compareTo(Object other) {
            EntityFrequency otherEntity = (EntityFrequency) other;
            return otherEntity.frequency - this.frequency; // Descending order
        }
    }
    
  
    
   
   
    // ==================== PRIVATE HELPER METHODS ====================
    
    /**
     * Retrieves all documents in a specified folder
     */
    private static List<ContentDocument> getDocumentsInFolder(String folderId) {
        return [
            SELECT Id, Title, FileExtension, ContentSize
            FROM ContentDocument 
            WHERE Id IN (
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :folderId
            )
        ];
    }
    
    /**
     * Retrieves a document template by ID
     */
    private static DocumentTemplate__c getDocumentTemplate(String templateId) {
        return [
            SELECT Id, Template_Content__c, Template_Variables__c, AI_Prompts__c
            FROM DocumentTemplate__c 
            WHERE Id = :templateId 
            LIMIT 1
        ];
    }

    
    /**
     * Processes Einstein Intent analysis results
     */
    private static DocumentContext processEinsteinIntentAnalysis(
        DocumentContext context, 
        Map<String, Object> parameters
    ) {
        String response = AIModelManager.processWithEinstein('einstein_intent', context.content, parameters);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response);
        
        context.entities = (List<String>) result.get('entities');
        context.themes = (List<String>) result.get('intents');
        
        return context;
    }
    
    /**
     * Processes Einstein Sentiment analysis results
     */
    private static DocumentContext processEinsteinSentimentAnalysis(
        DocumentContext context, 
        Map<String, Object> parameters
    ) {
        String response = AIModelManager.processWithEinstein('einstein_sentiment', context.content, parameters);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response);
        
        context.metadata = new Map<String, Object>{
            'sentiment' => result.get('sentiment'),
            'confidence' => result.get('confidence')
        };
        
        return context;
    }
    
    /**
     * Processes Einstein OCR analysis results
     */
    private static DocumentContext processEinsteinOCRAnalysis(
        DocumentContext context, 
        Map<String, Object> parameters
    ) {
        String response = AIModelManager.processWithEinstein('einstein_ocr', context.content, parameters);
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response);
        
        context.content = (String) result.get('extractedText');
        context.entities = (List<String>) result.get('entities');
        
        return context;
    }
    

    /**
     * Aggregates entity frequencies across documents
     */
    private static void aggregateEntityFrequencies(
        Map<String, Integer> entityFrequency, 
        List<String> entities
    ) {
        if (entities != null) {
            for (String entity : entities) {
                Integer count = entityFrequency.get(entity);
                entityFrequency.put(entity, (count != null ? count : 0) + 1);
            }
        }
    }
    
   
    
    /**
     * Calculates similarity between two documents based on themes
     */
    private static Double calculateSimilarity(DocumentContext doc1, DocumentContext doc2) {
        if (doc1.themes == null || doc2.themes == null) {
            return 0.0;
        }
        
        Set<String> themes1 = new Set<String>(doc1.themes);
        Set<String> themes2 = new Set<String>(doc2.themes);
        
        Set<String> intersection = themes1.clone();
        intersection.retainAll(themes2);
        
        Set<String> union = themes1.clone();
        union.addAll(themes2);
        
        return union.isEmpty() ? 0.0 : (Double) intersection.size() / union.size();
    }
    
    /**
     * Extracts themes that appear across multiple documents
     */
    private static List<String> extractCommonThemes(List<DocumentContext> documents) {
        Map<String, Integer> themeCount = new Map<String, Integer>();
        
        // Count theme occurrences across all documents
        for (DocumentContext doc : documents) {
            if (doc.themes != null) {
                for (String theme : doc.themes) {
                    Integer count = themeCount.get(theme);
                    themeCount.put(theme, (count != null ? count : 0) + 1);
                }
            }
        }
        
        // Extract themes that appear in multiple documents
        List<String> commonThemes = new List<String>();
        Integer threshold = Math.max(1, documents.size() / 2);
        
        for (String theme : themeCount.keySet()) {
            if (themeCount.get(theme) >= threshold) {
                commonThemes.add(theme);
            }
        }
        
        return commonThemes;
    }
    
    
    /**
     * Suggests appropriate templates based on document themes
     */
    private static List<String> generateTemplateSuggestions(FolderContextAnalysis analysis) {
        List<String> suggestions = new List<String>();
        
        // Analyze common themes to suggest templates
        for (String theme : analysis.commonThemes) {
            String lowerTheme = theme.toLowerCase();
            
            if (lowerTheme.contains('contract') || lowerTheme.contains('agreement')) {
                suggestions.add('Legal Contract Template');
            } else if (lowerTheme.contains('proposal') || lowerTheme.contains('business')) {
                suggestions.add('Business Proposal Template');
            } else if (lowerTheme.contains('report') || lowerTheme.contains('analysis')) {
                suggestions.add('Technical Report Template');
            } else if (lowerTheme.contains('policy') || lowerTheme.contains('procedure')) {
                suggestions.add('Policy Document Template');
            } else if (lowerTheme.contains('meeting') || lowerTheme.contains('agenda')) {
                suggestions.add('Meeting Documentation Template');
            }
        }
        
        // Remove duplicates and return
        return new List<String>(new Set<String>(suggestions));
    }
    
    /**
     * Gets the top entities by frequency
     */
    private static List<String> getTopEntities(Map<String, Integer> entityFrequency, Integer limit1) {
        List<EntityFrequency> sortedEntities = new List<EntityFrequency>();
        
        // Convert map to sortable list
        for (String entity : entityFrequency.keySet()) {
            sortedEntities.add(new EntityFrequency(entity, entityFrequency.get(entity)));
        }
        
        // Sort by frequency (descending)
        sortedEntities.sort();
        
        // Extract top entities
        List<String> topEntities = new List<String>();
        for (Integer i = 0; i < Math.min(limit1, sortedEntities.size()); i++) {
            topEntities.add(sortedEntities[i].entity);
        }
        
        return topEntities;
    }
    
    // ==================== CONTENT GENERATION METHODS ====================
    
    /**
     * Generates content using AI with provided context
     */
    private static String generateContentWithContext(
        DocumentTemplate__c template,
        FolderContextAnalysis contextAnalysis,
        String selectedAIModel,
        Map<String, Object> generationParameters
    ) {
        // Prepare AI prompt with context
        Map<String, Object> aiParameters = new Map<String, Object>{
            'template' => template.Template_Content__c,
            'context' => contextAnalysis,
            'parameters' => generationParameters,
            'instruction' => 'Generate a document using the provided template and context. ' +
                            'Incorporate insights from the analyzed documents while maintaining ' +
                            'consistency with the template structure.'
        };
        
        String prompt = buildContextAwarePrompt(template, contextAnalysis, generationParameters);
        
        // Call AI model for generation
        String response = AIModelManager.processWithEinstein(selectedAIModel, prompt, aiParameters);
        
        // Process and clean the response
        return processGeneratedContent(response, template);
    }
    
    /**
     * Builds a comprehensive prompt for context-aware generation
     */
    private static String buildContextAwarePrompt(
        DocumentTemplate__c template,
        FolderContextAnalysis contextAnalysis,
        Map<String, Object> generationParameters
    ) {
        StringBuilder prompt = new StringBuilder();
        
        prompt.append('Context-Aware Document Generation Request:\n\n');
        
        // Add template information
        prompt.append('Template Structure:\n');
        prompt.append(template.Template_Content__c).append('\n\n');
        
        // Add contextual insights
        prompt.append('Contextual Information from Document Analysis:\n');
        prompt.append('- Common Themes: ').append(String.join(contextAnalysis.commonThemes, ', ')).append('\n');
        prompt.append('- Key Entities: ');
        
        List<String> topEntities = getTopEntities(contextAnalysis.entityFrequency, 10);
        prompt.append(String.join(topEntities, ', ')).append('\n');
        
        prompt.append('- Contextual Insights:\n');
        for (String insight : contextAnalysis.contextualInsights) {
            prompt.append('  * ').append(insight).append('\n');
        }
        
        // Add generation parameters
        if (generationParameters != null && !generationParameters.isEmpty()) {
            prompt.append('\nGeneration Parameters:\n');
            for (String key : generationParameters.keySet()) {
                prompt.append('- ').append(key).append(': ').append(generationParameters.get(key)).append('\n');
            }
        }
        
        // Add generation instructions
        prompt.append('\nInstructions:\n');
        prompt.append('Generate a comprehensive document that:\n');
        prompt.append('1. Follows the provided template structure\n');
        prompt.append('2. Incorporates relevant information from the contextual analysis\n');
        prompt.append('3. Maintains consistency with the identified themes and entities\n');
        prompt.append('4. Provides accurate, well-sourced content based on the analyzed documents\n');
        prompt.append('5. Uses professional language appropriate for the document type\n');
        
        return prompt.toString();
    }
    
    /**
     * Builds a prompt for contextual question answering
     */
    private static String buildQuestionPrompt(String question, FolderContextAnalysis contextAnalysis) {
        StringBuilder prompt = new StringBuilder();
        
        prompt.append('Context-Based Question Answering:\n\n');
        prompt.append('Question: ').append(question).append('\n\n');
        
        prompt.append('Available Context:\n');
        prompt.append('Documents analyzed: ').append(contextAnalysis.documents.size()).append('\n');
        
        // Add document summaries
        prompt.append('Document Contents:\n');
        for (DocumentContext doc : contextAnalysis.documents) {
            prompt.append('- ').append(doc.title).append(': ');
            String summary = doc.content.length() > 500 ? 
                doc.content.substring(0, 500) + '...' : doc.content;
            prompt.append(summary).append('\n');
        }
        
        prompt.append('\nKey Themes: ').append(String.join(contextAnalysis.commonThemes, ', ')).append('\n');
        
        List<String> topEntities = getTopEntities(contextAnalysis.entityFrequency, 10);
        prompt.append('Important Entities: ').append(String.join(topEntities, ', ')).append('\n\n');
        
        prompt.append('Instructions:\n');
        prompt.append('Answer the question based ONLY on the provided document context. ');
        prompt.append('If the answer cannot be found in the documents, state that clearly. ');
        prompt.append('Always cite which document(s) your answer comes from. ');
        prompt.append('Provide specific quotes when relevant.\n');
        
        return prompt.toString();
    }
    
    /**
     * Processes AI-generated content and applies template variables
     */
    private static String processGeneratedContent(String response, DocumentTemplate__c template) {
        try {
            // Parse the AI response
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response);
            String generatedContent = (String) responseData.get('generated_content');
            
            if (String.isBlank(generatedContent)) {
                generatedContent = response; // Fallback to raw response
            }
            
            // Apply template variables if needed
            generatedContent = applyTemplateVariables(generatedContent, template);
            
            return generatedContent;
            
        } catch (Exception e) {
            System.debug('Content processing error: ' + e.getMessage());
            return response; // Return raw response as fallback
        }
    }
    
    /**
     * Applies template variables to generated content
     */
    private static String applyTemplateVariables(String content, DocumentTemplate__c template) {
        if (String.isBlank(template.Template_Variables__c)) {
            return content;
        }
        
        try {
            List<Object> variables = (List<Object>) JSON.deserializeUntyped(template.Template_Variables__c);
            
            for (Object varObj : variables) {
                Map<String, Object> variable = (Map<String, Object>) varObj;
                String varName = (String) variable.get('name');
                String defaultValue = (String) variable.get('defaultValue');
                
                if (String.isNotBlank(defaultValue)) {
                    content = content.replace('{{' + varName + '}}', defaultValue);
                }
            }
            
        } catch (Exception e) {
            System.debug('Template variable processing error: ' + e.getMessage());
        }
        
        return content;
    }
    
    /**
     * Creates a new Document__c record for generated content
     */
    private static Document__c createGeneratedDocument(
        String generatedContent,
        String templateId,
        String selectedAIModel,
        FolderContextAnalysis contextAnalysis
    ) {
        return new Document__c(
            Name = 'Context-Aware Generated Document',
            Content__c = generatedContent,
            Template_Used__c = templateId,
            AI_Model__c = selectedAIModel,
            Context_Analysis__c = JSON.serialize(contextAnalysis),
            Generated_Date__c = DateTime.now()
        );
    }
}


