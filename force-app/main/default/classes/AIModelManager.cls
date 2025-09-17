// Custom Metadata Type: AI_Model_Configuration__mdt
public class AIModelManager {
    
    /**
     * Data transfer object representing AI model configuration.
     */
    public class AIModelConfig {
       
    @AuraEnabled public String modelId { get; set; }
    @AuraEnabled public String modelName { get; set; }
    @AuraEnabled public String provider { get; set; }
    @AuraEnabled public String capabilities { get; set; }
    @AuraEnabled public Boolean isActive { get; set; }
    @AuraEnabled public String endpoint { get; set; }
    @AuraEnabled public Map<String, Object> parameters { get; set; }
    @AuraEnabled public String description { get; set; }
    @AuraEnabled public Integer maxTokens { get; set; }
    @AuraEnabled public Decimal costPerToken { get; set; }


    }
    
    /**
     * Retrieves all available AI models, combining custom metadata configurations
     * with Salesforce Einstein built-in models.
     */
    @AuraEnabled(cacheable=true)
    public static List<AIModelConfig> getAvailableAIModels() {
        List<AIModelConfig> models = new List<AIModelConfig>();
        
        // Query custom metadata model configurations
        List<AI_Model_Configuration__mdt> customModels = [
            SELECT MasterLabel, ModelName__c, Provider__c, Capabilities__c, 
                   IsActive__c, APIEndpoint__c, Description__c, 
                   MaxTokens__c, CostPerToken__c
            FROM AI_Model_Configuration__mdt 
            WHERE IsActive__c = true 
            ORDER BY MasterLabel
        ];
        
        // Map metadata to config DTOs
        for (AI_Model_Configuration__mdt model : customModels) {
            AIModelConfig config = new AIModelConfig();
            config.modelId      = model.MasterLabel;
            config.modelName    = model.ModelName__c;
            config.provider     = model.Provider__c;
            config.capabilities = model.Capabilities__c;
            config.isActive     = model.IsActive__c;
            config.endpoint     = model.APIEndpoint__c;
            config.description  = model.Description__c;
            config.maxTokens    = Integer.valueOf(model.MaxTokens__c);
            config.costPerToken = model.CostPerToken__c;
            models.add(config);
        }
        
        // Append Salesforce Einstein models
        models.addAll(getEinsteinModels());
        
        return models;
    }
    
    // @AuraEnabled(cacheable=true)
    //     public static List<AIModelConfig> getAvailableAIModels() {
    //         List<AIModelConfig> models = new List<AIModelConfig>();

    //         try {
    //             // Retrieve models from Custom Metadata
    //             List<AI_Model_Configuration__mdt> modelConfigs = [
    //                 SELECT Model_Id__c, Model_Name__c, Provider__c, 
    //                        Capabilities__c, Is_Active__c, Endpoint__c, 
    //                        Parameters__c
    //                 FROM AI_Model_Configuration__mdt 
    //                 WHERE Is_Active__c = true 
    //                 ORDER BY Model_Name__c
    //             ];

    //             for (AI_Model_Configuration__mdt config : modelConfigs) {
    //                 AIModelConfig model = new AIModelConfig();
    //                 model.modelId      = config.Model_Id__c;
    //                 model.modelName    = config.Model_Name__c;
    //                 model.provider     = config.Provider__c;
    //                 model.capabilities = config.Capabilities__c;
    //                 model.isActive     = config.Is_Active__c;
    //                 model.endpoint     = config.Endpoint__c;

    //                 // Parse parameters from JSON if available
    //                 if (String.isNotBlank(config.Parameters__c)) {
    //                     model.parameters = (Map<String, Object>) JSON.deserializeUntyped(config.Parameters__c);
    //                 }

    //                 models.add(model);
    //             }

    //             // Add predefined Einstein models
    //             models.addAll(getEinsteinModels());

    //         } catch (Exception e) {
    //             System.debug('Error retrieving AI models: ' + e.getMessage());
    //         }

    //         return models;
    //     }




    //     @AuraEnabled(cacheable=true)
        // public static List<AI_Model_Configuration__mdt> getAvailableAIModels() {
        //     return [
        //         SELECT Id, Label, DeveloperName, Model_Provider__c, API_Endpoint__c, 
        //                Model_Type__c, Context_Window_Size__c, Max_Tokens__c, 
        //                Temperature__c, Is_Active__c, Capabilities__c
        //         FROM AI_Model_Configuration__mdt 
        //         WHERE Is_Active__c = true 
        //         ORDER BY Sort_Order__c
        //     ];
        // }

    /**
     * Returns a predefined set of Salesforce Einstein AI models.
     */
    private static List<AIModelConfig> getEinsteinModels() {
        List<AIModelConfig> einsteinModels = new List<AIModelConfig>();
        
        // Einstein Intent Detection
        AIModelConfig intentModel = new AIModelConfig();
        intentModel.modelId      = 'einstein_intent';
        intentModel.modelName    = 'Einstein Intent Detection';
        intentModel.provider     = 'Salesforce Einstein';
        intentModel.capabilities = 'Intent Analysis, Classification';
        intentModel.isActive     = true;
        intentModel.description  = 'Analyzes user intent and classifies content';
        einsteinModels.add(intentModel);
        
        // Einstein Sentiment Analysis
        AIModelConfig sentimentModel = new AIModelConfig();
        sentimentModel.modelId      = 'einstein_sentiment';
        sentimentModel.modelName    = 'Einstein Sentiment Analysis';
        sentimentModel.provider     = 'Salesforce Einstein';
        sentimentModel.capabilities = 'Sentiment Analysis, Emotion Detection';
        sentimentModel.isActive     = true;
        sentimentModel.description  = 'Analyzes sentiment and emotional tone';
        einsteinModels.add(sentimentModel);
        
        // Einstein OCR
        AIModelConfig ocrModel = new AIModelConfig();
        ocrModel.modelId      = 'einstein_ocr';
        ocrModel.modelName    = 'Einstein OCR';
        ocrModel.provider     = 'Salesforce Einstein';
        ocrModel.capabilities = 'Text Recognition, Document Processing';
        ocrModel.isActive     = true;
        ocrModel.description  = 'Extracts text from images and documents';
        einsteinModels.add(ocrModel);
        
        return einsteinModels;
    }
    
    /**
     * Retrieves a single AI model configuration by its ID.
     */
    @AuraEnabled
    public static AIModelConfig getModelConfiguration(String modelId) {
        List<AIModelConfig> models = getAvailableAIModels();
        
        for (AIModelConfig model : models) {
            if (model.modelId == modelId) {
                return model;
            }
        }
        return null;
    }

   

    
    
    @AuraEnabled
    public static String processWithEinstein(String modelId, String prompt, String context) {
        try {
            AI_Model_Configuration__mdt modelConfig = getModelConfiguration(modelId);
            
            if (modelConfig.Model_Provider__c == 'Einstein') {
                return processWithEinsteinNative(prompt, context, modelConfig);
            } else if (modelConfig.Model_Provider__c == 'OpenAI') {
                return processWithOpenAI(prompt, context, modelConfig);
            } else if (modelConfig.Model_Provider__c == 'Anthropic') {
                return processWithAnthropic(prompt, context, modelConfig);
            }
            
            throw new AIProcessingException(
                'Unsupported model provider: ' + modelConfig.Model_Provider__c
            );
            
        } catch (Exception e) {
            throw new AuraHandledException('AI processing failed: ' + e.getMessage());
        }
    }


    
    
    /**
     * Handle Einstein Platform Services API call
     */
    private static String processWithEinsteinNative(
        String prompt,
        String context,
        AI_Model_Configuration__mdt config
    ) {
        // Build request payload
        Map<String, Object> requestBody = new Map<String, Object>{
            'prompt'      => buildContextualPrompt(prompt, context),
            'model'       => config.DeveloperName,
            'max_tokens'  => Integer.valueOf(config.Max_Tokens__c),
            'temperature' => config.Temperature__c
        };
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(config.API_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + getEinsteinAccessToken());
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(requestBody));
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> responseData =
                (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            return (String) responseData.get('generated_text');
        } else {
            throw new AIProcessingException(
                'Einstein API call failed: ' + response.getBody()
            );
        }
    }
    
    // 🔹 To-Do: Implement the following helper methods
    // private static AI_Model_Configuration__mdt getModelConfiguration(String modelId) { ... }
    // private static String processWithOpenAI(String prompt, String context, AI_Model_Configuration__mdt config) { ... }
    // private static String processWithAnthropic(String prompt, String context, AI_Model_Configuration__mdt config) { ... }
    // private static String buildContextualPrompt(String prompt, String context) { ... }
    // private static String getEinsteinAccessToken() { ... }
    
    // Custom Exception for AI processing failures
    public class AIProcessingException extends Exception {}


    /**
     * Retrieve available AI models (Einstein + configured external providers)
     * 
     * @return List<AIModelConfig> - Available AI model configurations
     */
    @AuraEnabled
    public static List<AIModelConfig> getAvailableAIModels() {
        // Fetch configured external models from custom metadata
        List<AI_Model_Configuration__mdt> modelConfigs = [
            SELECT Id, Model_Name__c, Provider__c, Endpoint__c, 
                   Capabilities__c, Active__c, Display_Order__c
            FROM AI_Model_Configuration__mdt 
            WHERE Active__c = true 
            ORDER BY Display_Order__c
        ];
        
        List<AIModelConfig> availableModels = new List<AIModelConfig>();

        // --- Predefined Salesforce Einstein Models ---
        availableModels.add(new AIModelConfig(
            'einstein_intent',
            'Einstein Intent Detection',
            'Salesforce',
            'Intent Analysis',
            true
        ));

        availableModels.add(new AIModelConfig(
            'einstein_sentiment',
            'Einstein Sentiment Analysis',
            'Salesforce',
            'Sentiment Analysis',
            true
        ));

        availableModels.add(new AIModelConfig(
            'einstein_ocr',
            'Einstein OCR',
            'Salesforce',
            'Document OCR',
            true
        ));
        
        // --- External Models from Metadata Configuration ---
        for (AI_Model_Configuration__mdt config : modelConfigs) {
            availableModels.add(new AIModelConfig(
                config.Id,
                config.Model_Name__c,
                config.Provider__c,
                config.Capabilities__c,
                config.Active__c
            ));
        }
        
        return availableModels;
    }

    
    // ------------------------------------------------------------------------
    // Get all available AI models (from Custom Metadata + Salesforce Einstein)
    // ------------------------------------------------------------------------
    @AuraEnabled(cacheable=true)
    public static List<AIModelConfig> getAvailableAIModels() {
        List<AIModelConfig> models = new List<AIModelConfig>();
        
        // Retrieve custom AI model configurations
        for (AI_Model_Configuration__mdt config : [
            SELECT ModelName__c, ModelIdentifier__c, Provider__c, 
                   Capabilities__c, IsActive__c, Endpoint__c, Parameters__c
            FROM AI_Model_Configuration__mdt 
            WHERE IsActive__c = true 
            ORDER BY ModelName__c
        ]) {
            models.add(new AIModelConfig(config));
        }
        
        // Add default Einstein Platform Services models
        models.add(new AIModelConfig(
            'Einstein Intent Detection', 'einstein_intent', 'Salesforce', 
            'Intent Analysis, Classification'
        ));
        models.add(new AIModelConfig(
            'Einstein Sentiment Analysis', 'einstein_sentiment', 'Salesforce', 
            'Sentiment Analysis, Emotion Detection'
        ));
        models.add(new AIModelConfig(
            'Einstein OCR', 'einstein_ocr', 'Salesforce', 
            'Text Extraction, Document Parsing'
        ));
        
        return models;
    }
    
    // ------------------------------------------------------------------------
    // Entry point: Process data using Einstein or external AI
    // ------------------------------------------------------------------------
    @AuraEnabled
    public static String processWithEinstein(
        String modelIdentifier, 
        String inputData, 
        Map<String, Object> parameters
    ) {
        switch on modelIdentifier {
            when 'einstein_intent' {
                return processWithEinsteinNative('intent', inputData, parameters);
            }
            when 'einstein_sentiment' {
                return processWithEinsteinNative('sentiment', inputData, parameters);
            }
            when 'einstein_ocr' {
                return processWithEinsteinNative('ocr', inputData, parameters);
            }
            when else {
                return processWithExternalAI(modelIdentifier, inputData, parameters);
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Native Einstein Platform Services integration
    // ------------------------------------------------------------------------
    private static String processWithEinsteinNative(
        String service, 
        String inputData, 
        Map<String, Object> parameters
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Einstein_Platform_Services');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'service'    => service,
            'data'       => inputData,
            'parameters' => parameters
        };
        
        req.setBody(JSON.serialize(requestBody));
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() == 200) {
            return response.getBody();
        } else {
            throw new AuraHandledException(
                'Einstein API call failed: ' + response.getBody()
            );
        }
    }
    
    // ------------------------------------------------------------------------
    // External AI Model integration (via Custom Metadata)
    // ------------------------------------------------------------------------
    private static String processWithExternalAI(
        String modelIdentifier, 
        String inputData, 
        Map<String, Object> parameters
    ) {
        // Retrieve model configuration from Custom Metadata
        AI_Model_Configuration__mdt config = [
            SELECT Endpoint__c, Parameters__c 
            FROM AI_Model_Configuration__mdt 
            WHERE ModelIdentifier__c = :modelIdentifier 
            LIMIT 1
        ];
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(config.Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'model' => modelIdentifier,
            'input' => inputData
        };
        
        // Merge custom parameters (from metadata)
        if (String.isNotBlank(config.Parameters__c)) {
            Map<String, Object> configParams = 
                (Map<String, Object>) JSON.deserializeUntyped(config.Parameters__c);
            requestBody.putAll(configParams);
        }
        
        req.setBody(JSON.serialize(requestBody));
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        return response.getBody();
    }
}

