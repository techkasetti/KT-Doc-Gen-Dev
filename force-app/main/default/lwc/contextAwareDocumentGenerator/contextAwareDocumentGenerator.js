// version v1
//import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getAvailableAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
// import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';
// import generateContextualDocument from '@salesforce/apex/ContextAwareDocumentGenerator.generateDocument';
// import askContextualQuestion from '@salesforce/apex/ContextAwareDocumentEngine.askContextualQuestion';

// export default class ContextAwareDocumentGenerator extends LightningElement {
//     // ===================================================================
//     // API and Tracked Properties
//     // ===================================================================
//     @api recordId;
    
//     @track selectedAIModel;
//     @track availableModels = [];
//     @track folderContext;
//     @track generatedContent = '';
    
//     // Loading states
//     @track isAnalyzing = false;
//     @track isGenerating = false;
    
//     // Chat interface
//     @track showChatInterface = false;
//     @track chatMessages = [];
//     @track currentQuestion = '';
    
//     // Anara-style interface states
//     @track showModelSelector = true;
//     @track showContextAnalysis = false;
//     @track showDocumentGeneration = false;
//     @track contextInsights = [];
//     @track suggestedQuestions = [];

//     // ===================================================================
//     // Lifecycle Hooks
//     // ===================================================================
//     connectedCallback() {
//         this.loadAIModels();
//         this.initializeFolderContext();
//     }

//     // ===================================================================
//     // Wire Methods
//     // ===================================================================
//     @wire(getAvailableAIModels)
//     wiredModels({ error, data }) {
//         if (data) {
//             this.availableModels = data.map(model => ({
//                 label: `${model.Label} (${model.Model_Provider__c})`,
//                 value: model.DeveloperName,
//                 capabilities: model.Capabilities__c,
//                 contextWindow: model.Context_Window_Size__c
//             }));
//         } else if (error) {
//             this.showToast('Error', 'Failed to load AI models', 'error');
//         }
//     }

//     // ===================================================================
//     // Initialization Methods
//     // ===================================================================
//     async initializeFolderContext() {
//         this.isAnalyzing = true;
        
//         try {
//             this.folderContext = await analyzeFolderContext({ 
//                 folderId: this.recordId,
//                 queryContext: 'document_generation'
//             });
            
//             this.contextInsights = this.folderContext.crossDocumentInsights;
//             this.suggestedQuestions = this.folderContext.suggestedQuestions;
//             this.showContextAnalysis = true;
            
//         } catch (error) {
//             this.showToast('Error', 'Failed to analyze folder context', 'error');
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     // ===================================================================
//     // Event Handlers
//     // ===================================================================
//     handleModelSelection(event) {
//         this.selectedAIModel = event.detail.value;
//         const selectedModel = this.availableModels.find(
//             model => model.value === this.selectedAIModel
//         );
        
//         if (selectedModel) {
//             this.showToast(
//                 'Success', 
//                 `Selected ${selectedModel.label} with ${selectedModel.contextWindow} context window`, 
//                 'success'
//             );
//         }
//     }

//     handleSuggestedQuestion(event) {
//         this.currentQuestion = event.target.dataset.question;
//     }

//     // ===================================================================
//     // Question & Answer Methods (Anara-style contextual questioning)
//     // ===================================================================
//     async handleAskQuestion() {
//         // Validation
//         if (!this.currentQuestion.trim()) {
//             this.showToast('Warning', 'Please enter a question', 'warning');
//             return;
//         }

//         if (!this.selectedAIModel) {
//             this.showToast('Warning', 'Please select an AI model first', 'warning');
//             return;
//         }

//         try {
//             this.isAnalyzing = true;
            
//             const response = await askContextualQuestion({
//                 folderId: this.recordId,
//                 question: this.currentQuestion,
//                 selectedModel: this.selectedAIModel,
//                 folderContext: JSON.stringify(this.folderContext)
//             });

//             // Add question and answer to chat history
//             this.addChatMessage('question', this.currentQuestion);
//             this.addChatMessage('answer', response, this.selectedAIModel);

//             // Reset and show chat interface
//             this.currentQuestion = '';
//             this.showChatInterface = true;

//         } catch (error) {
//             const errorMessage = error.body?.message || 'Unknown error occurred';
//             this.showToast('Error', `Question processing failed: ${errorMessage}`, 'error');
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     // ===================================================================
//     // Document Generation Methods
//     // ===================================================================
//     async handleGenerateDocument() {
//         if (!this.selectedAIModel) {
//             this.showToast('Warning', 'Please select an AI model first', 'warning');
//             return;
//         }

//         try {
//             this.isGenerating = true;
            
//             const result = await generateContextualDocument({
//                 folderId: this.recordId,
//                 templateId: this.selectedTemplate,
//                 selectedAIModel: this.selectedAIModel,
//                 generationParameters: this.generationParameters
//             });
            
//             this.generatedContent = result;
//             this.showToast(
//                 'Success', 
//                 'Document generated successfully with contextual AI intelligence', 
//                 'success'
//             );
                
//         } catch (error) {
//             this.showToast('Error', 'Document generation failed', 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     // ===================================================================
//     // Helper Methods
//     // ===================================================================
//     addChatMessage(type, content, model = null) {
//         const message = {
//             id: Date.now() + Math.random(), // Ensure unique ID
//             type,
//             content,
//             timestamp: new Date().toLocaleTimeString()
//         };
        
//         if (model) {
//             message.model = model;
//         }
        
//         this.chatMessages = [...this.chatMessages, message];
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ 
//             title, 
//             message, 
//             variant 
//         }));
//     }

//     // ===================================================================
//     // Computed Properties (Getters)
//     // ===================================================================
//     get modelOptions() {
//         return this.availableModels;
//     }

//     get hasContextData() {
//         return this.folderContext && 
//                this.folderContext.documents && 
//                this.folderContext.documents.length > 0;
//     }

//     get contextSummary() {
//         return this.folderContext?.contextualSummary || '';
//     }

//     get documentCount() {
//         return this.folderContext?.documents?.length || 0;
//     }

//     get isProcessing() {
//         return this.isAnalyzing || this.isGenerating;
//     }

//     get hasMessages() {
//         return this.chatMessages.length > 0;
//     }
// }


// import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { NavigationMixin } from 'lightning/navigation';

// // Apex imports
// import getAvailableAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
// import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';
// import askContextualQuestion from '@salesforce/apex/ContextAwareDocumentEngine.askContextualQuestion';
// import generateContextualDocument from '@salesforce/apex/ContextAwareTemplateEngine.generateContextualDocument';
// import getDocumentTemplates from '@salesforce/apex/TemplateController.getDocumentTemplates';
// import saveGeneratedDocument from '@salesforce/apex/DocumentManager.saveGeneratedDocument';

// export default class ContextAwareDocumentGenerator extends NavigationMixin(LightningElement) {
//     // =============================================================================
//     // PUBLIC PROPERTIES
//     // =============================================================================
//     @api recordId; // Folder ID

//     // =============================================================================
//     // TRACKED PROPERTIES
//     // =============================================================================
    
//     // AI Model Configuration
//     @track selectedAIModel = '';
//     @track availableModels = [];
    
//     // Context Analysis
//     @track folderContext = null;
//     @track contextInsights = [];
//     @track suggestedQuestions = [];
    
//     // Loading States
//     @track isAnalyzing = false;
//     @track isGenerating = false;
    
//     // Chat Interface
//     @track showChatInterface = false;
//     @track chatMessages = [];
//     @track currentQuestion = '';
    
//     // Document Generation
//     @track generatedContent = '';
//     @track selectedTemplate = '';
//     @track templateOptions = [];
    
//     // UI State Management
//     @track showModelSelector = true;
//     @track showContextAnalysis = false;
//     @track showDocumentGeneration = false;
//     @track showPreview = false;
    
//     // Generation Parameters
//     @track creativityLevel = 0.7;
//     @track maxLength = 2000;
//     @track includeCrossReferences = true;
//     @track includeEntityConsolidation = true;
//     @track includeSourceCitations = true;
//     @track includeContextualInsights = true;

//     // =============================================================================
//     // LIFECYCLE HOOKS
//     // =============================================================================
    
//     connectedCallback() {
//         this.loadAIModels();
//         this.loadTemplates();
//         this.initializeFolderContext();
//     }

//     // =============================================================================
//     // WIRE SERVICES
//     // =============================================================================
    
//     @wire(getAvailableAIModels)
//     wiredModels({ error, data }) {
//         if (data) {
//             this.availableModels = data.map(model => ({
//                 label: `${model.Label} (${model.Model_Provider__c})`,
//                 value: model.DeveloperName,
//                 capabilities: model.Capabilities__c,
//                 contextWindow: model.Context_Window_Size__c,
//                 description: model.Description__c
//             }));
//         } else if (error) {
//             this.showToast('Error', 'Failed to load AI models', 'error');
//         }
//     }

//     // =============================================================================
//     // INITIALIZATION METHODS
//     // =============================================================================
    
//     async loadTemplates() {
//         try {
//             const templates = await getDocumentTemplates();
//             this.templateOptions = templates.map(template => ({
//                 label: template.Name,
//                 value: template.Id,
//                 description: template.Description__c
//             }));
//         } catch (error) {
//             this.showToast('Error', 'Failed to load document templates', 'error');
//         }
//     }

//     async initializeFolderContext() {
//         if (!this.recordId) return;
        
//         this.isAnalyzing = true;
//         try {
//             this.folderContext = await analyzeFolderContext({
//                 folderId: this.recordId,
//                 queryContext: 'document_generation'
//             });
            
//             this.processContextAnalysis();
//             this.showContextAnalysis = true;
//         } catch (error) {
//             console.error('Context analysis failed:', error);
//             this.showToast('Error', 'Failed to analyze folder context: ' + error.body?.message, 'error');
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     processContextAnalysis() {
//         if (!this.folderContext) return;
        
//         // Process cross-document insights
//         this.contextInsights = [];
//         if (this.folderContext.crossDocumentInsights) {
//             for (const [key, value] of Object.entries(this.folderContext.crossDocumentInsights)) {
//                 this.contextInsights.push({ key, value, id: key });
//             }
//         }
        
//         // Process suggested questions
//         this.suggestedQuestions = this.folderContext.suggestedQuestions || [];
        
//         // Enhance document data for display
//         if (this.folderContext.documents) {
//             this.folderContext.documents = this.folderContext.documents.map(doc => ({
//                 ...doc,
//                 keyEntitiesString: doc.keyEntities ? doc.keyEntities.join(', ') : '',
//                 relevancePercentage: Math.round(doc.relevanceScore * 100)
//             }));
//         }
//     }

//     // =============================================================================
//     // EVENT HANDLERS
//     // =============================================================================
    
//     handleModelSelection(event) {
//         this.selectedAIModel = event.detail.value;
//         const selectedModel = this.availableModels.find(model => model.value === this.selectedAIModel);
        
//         if (selectedModel) {
//             this.showToast(
//                 'AI Model Selected', 
//                 `${selectedModel.label} - Context Window: ${selectedModel.contextWindow} tokens`, 
//                 'success'
//             );
//         }
//     }

//     handleTemplateSelection(event) {
//         this.selectedTemplate = event.detail.value;
//     }

//     handleQuestionInput(event) {
//         this.currentQuestion = event.target.value;
//     }

//     handleQuestionKeyPress(event) {
//         if (event.keyCode === 13 && !event.shiftKey) { // Enter key
//             event.preventDefault();
//             this.handleAskQuestion();
//         }
//     }

//     handleSuggestedQuestion(event) {
//         this.currentQuestion = event.target.dataset.question;
//         this.handleAskQuestion();
//     }

//     // Parameter Change Handlers
//     handleCreativityChange(event) {
//         this.creativityLevel = parseFloat(event.target.value);
//     }

//     handleMaxLengthChange(event) {
//         this.maxLength = parseInt(event.target.value, 10);
//     }

//     handleCrossReferencesChange(event) {
//         this.includeCrossReferences = event.target.checked;
//     }

//     handleEntityConsolidationChange(event) {
//         this.includeEntityConsolidation = event.target.checked;
//     }

//     handleSourceCitationsChange(event) {
//         this.includeSourceCitations = event.target.checked;
//     }

//     handleContextualInsightsChange(event) {
//         this.includeContextualInsights = event.target.checked;
//     }

//     // =============================================================================
//     // CHAT FUNCTIONALITY
//     // =============================================================================
    
//     async handleAskQuestion() {
//         if (!this.currentQuestion.trim()) {
//             this.showToast('Warning', 'Please enter a question', 'warning');
//             return;
//         }

//         if (!this.selectedAIModel) {
//             this.showToast('Warning', 'Please select an AI model first', 'warning');
//             return;
//         }

//         const question = this.currentQuestion.trim();
//         this.currentQuestion = '';
        
//         // Add question to chat immediately
//         this.addChatMessage(question, 'question');
//         this.showChatInterface = true;

//         this.isAnalyzing = true;
//         try {
//             const response = await askContextualQuestion({
//                 folderId: this.recordId,
//                 question: question,
//                 selectedModel: this.selectedAIModel,
//                 folderContext: JSON.stringify(this.folderContext)
//             });

//             // Add response to chat
//             this.addChatMessage(response, 'answer', this.selectedAIModel);

//         } catch (error) {
//             console.error('Question processing failed:', error);
//             this.addChatMessage(
//                 'Sorry, I encountered an error processing your question: ' + error.body?.message,
//                 'error'
//             );
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     addChatMessage(content, type, model = '') {
//         const message = {
//             id: Date.now() + Math.random(),
//             content: content,
//             type: type,
//             timestamp: new Date().toLocaleTimeString(),
//             isQuestion: type === 'question',
//             model: model
//         };

//         this.chatMessages = [...this.chatMessages, message];
        
//         // Scroll to bottom after message is added
//         setTimeout(() => {
//             const chatContainer = this.template.querySelector('.chat-container');
//             if (chatContainer) {
//                 chatContainer.scrollTop = chatContainer.scrollHeight;
//             }
//         }, 100);
//     }

//     // =============================================================================
//     // DOCUMENT GENERATION
//     // =============================================================================
    
//     async handleGenerateDocument() {
//         if (!this.selectedAIModel) {
//             this.showToast('Warning', 'Please select an AI model first', 'warning');
//             return;
//         }

//         if (!this.selectedTemplate) {
//             this.showToast('Warning', 'Please select a document template', 'warning');
//             return;
//         }

//         this.isGenerating = true;
//         try {
//             const generationParameters = this.getGenerationParameters();

//             this.generatedContent = await generateContextualDocument({
//                 templateId: this.selectedTemplate,
//                 folderContext: this.folderContext,
//                 generationParameters: generationParameters
//             });

//             this.showPreview = true;
//             this.showToast('Success', 'Context-aware document generated successfully!', 'success');

//         } catch (error) {
//             console.error('Document generation failed:', error);
//             this.showToast('Error', 'Document generation failed: ' + error.body?.message, 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     // =============================================================================
//     // DOCUMENT ACTIONS
//     // =============================================================================
    
//     handleEditDocument() {
//         // Navigate to edit mode or open editor
//         this.showToast('Info', 'Opening document editor...', 'info');
//     }

//     async handleRegenerateDocument() {
//         this.showToast('Info', 'Regenerating document with same parameters...', 'info');
//         await this.handleGenerateDocument();
//     }

//     handleSaveDocument() {
//         this.saveDocumentToSalesforce();
//     }

//     async saveDocumentToSalesforce() {
//         try {
//             const saveResult = await saveGeneratedDocument({
//                 content: this.generatedContent,
//                 templateId: this.selectedTemplate,
//                 folderId: this.recordId,
//                 modelUsed: this.selectedAIModel,
//                 parameters: JSON.stringify(this.getGenerationParameters())
//             });
            
//             this.showToast('Success', 'Document saved successfully', 'success');
            
//             // Navigate to the saved document
//             this[NavigationMixin.Navigate]({
//                 type: 'standard__recordPage',
//                 attributes: {
//                     recordId: saveResult.documentId,
//                     objectApiName: 'ContentDocument',
//                     actionName: 'view'
//                 }
//             });
//         } catch (error) {
//             this.showToast('Error', 'Failed to save document: ' + error.body?.message, 'error');
//         }
//     }

//     // =============================================================================
//     // COMPUTED PROPERTIES
//     // =============================================================================
    
//     get modelOptions() {
//         return this.availableModels;
//     }

//     get hasContextData() {
//         return this.folderContext && 
//                this.folderContext.documents && 
//                this.folderContext.documents.length > 0;
//     }

//     get contextSummary() {
//         return this.folderContext ? this.folderContext.contextualSummary : '';
//     }

//     get documentCount() {
//         return this.folderContext ? this.folderContext.documents.length : 0;
//     }

//     get generateButtonDisabled() {
//         return !this.selectedAIModel || 
//                !this.selectedTemplate || 
//                this.isGenerating || 
//                this.isAnalyzing;
//     }

//     get creativityLevelLabel() {
//         return `Creativity Level: ${this.creativityLevel}`;
//     }

//     get maxLengthLabel() {
//         return `Max Length: ${this.maxLength} words`;
//     }

//     // =============================================================================
//     // UTILITY METHODS
//     // =============================================================================
    
//     getGenerationParameters() {
//         return {
//             selectedAIModel: this.selectedAIModel,
//             creativityLevel: this.creativityLevel,
//             maxLength: this.maxLength,
//             includeCrossReferences: this.includeCrossReferences,
//             includeEntityConsolidation: this.includeEntityConsolidation,
//             includeSourceCitations: this.includeSourceCitations,
//             includeContextualInsights: this.includeContextualInsights
//         };
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({
//             title,
//             message,
//             variant
//         }));
//     }
// }








// import { LightningElement, api, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// import getAvailableAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
// import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';
// import generateContextualDocument from '@salesforce/apex/ContextAwareDocumentGenerator.generateDocument';
// import askContextualQuestion from '@salesforce/apex/ContextAwareDocumentEngine.askContextualQuestion';

// export default class ContextAwareDocumentGenerator extends LightningElement {
//     @api recordId;

//     @track selectedAIModel;
//     @track availableModels = [];
//     @track folderContext;
//     @track isAnalyzing = false;
//     @track isGenerating = false;
//     @track showChatInterface = false;
//     @track chatMessages = [];
//     @track currentQuestion = '';
//     @track generatedContent = '';

//     // UI state flags (Anara-style interface)
//     @track showModelSelector = true;
//     @track showContextAnalysis = false;
//     @track showDocumentGeneration = false;
//     @track contextInsights = [];
//     @track suggestedQuestions = [];

//     // Lifecycle hook
//     connectedCallback() {
//         this.loadAIModels();
//         this.initializeFolderContext();
//     }

//     // Wire service to fetch available models
//     @wire(getAvailableAIModels)
//     wiredModels({ error, data }) {
//         if (data) {
//             this.availableModels = data.map(model => ({
//                 label: `${model.Label} (${model.Model_Provider__c})`,
//                 value: model.DeveloperName,
//                 capabilities: model.Capabilities__c,
//                 contextWindow: model.Context_Window_Size__c
//             }));
//         } else if (error) {
//             this.showToast('Error', 'Failed to load AI models', 'error');
//         }
//     }

//     // Analyze folder context
//     async initializeFolderContext() {
//         this.isAnalyzing = true;
//         try {
//             this.folderContext = await analyzeFolderContext({
//                 folderId: this.recordId,
//                 queryContext: 'document_generation'
//             });

//             this.contextInsights = this.folderContext.crossDocumentInsights;
//             this.suggestedQuestions = this.folderContext.suggestedQuestions;
//             this.showContextAnalysis = true;
//         } catch (error) {
//             this.showToast('Error', 'Failed to analyze folder context', 'error');
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     // Handle model selection
//     handleModelSelection(event) {
//         this.selectedAIModel = event.detail.value;
//         const selectedModel = this.availableModels.find(model => model.value === this.selectedAIModel);

//         if (selectedModel) {
//             this.showToast(
//                 'Success',
//                 `Selected ${selectedModel.label} with ${selectedModel.contextWindow} context window`,
//                 'success'
//             );
//         }
//     }

//     // Ask contextual question
//     async handleAskQuestion() {
//         if (!this.currentQuestion.trim()) {
//             this.showToast('Warning', 'Please enter a question', 'warning');
//             return;
//         }

//         if (!this.selectedAIModel) {
//             this.showToast('Warning', 'Please select an AI model first', 'warning');
//             return;
//         }

//         this.isAnalyzing = true;
//         try {
//             const response = await askContextualQuestion({
//                 folderId: this.recordId,
//                 question: this.currentQuestion,
//                 selectedModel: this.selectedAIModel,
//                 folderContext: JSON.stringify(this.folderContext)
//             });

//             this.chatMessages = [
//                 ...this.chatMessages,
//                 {
//                     id: Date.now(),
//                     type: 'question',
//                     content: this.currentQuestion,
//                     timestamp: new Date().toLocaleTimeString()
//                 },
//                 {
//                     id: Date.now() + 1,
//                     type: 'answer',
//                     content: response,
//                     timestamp: new Date().toLocaleTimeString(),
//                     model: this.selectedAIModel
//                 }
//             ];

//             this.currentQuestion = '';
//             this.showChatInterface = true;
//         } catch (error) {
//             this.showToast('Error', 'Question processing failed: ' + error.body.message, 'error');
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     // Handle suggested question click
//     handleSuggestedQuestion(event) {
//         this.currentQuestion = event.target.dataset.question;
//     }

//     // Generate document
//     async handleGenerateDocument() {
//         if (!this.selectedAIModel) {
//             this.showToast('Warning', 'Please select an AI model first', 'warning');
//             return;
//         }

//         this.isGenerating = true;
//         try {
//             const result = await generateContextualDocument({
//                 folderId: this.recordId,
//                 templateId: this.selectedTemplate,
//                 selectedAIModel: this.selectedAIModel,
//                 generationParameters: this.generationParameters
//             });

//             this.generatedContent = result;
//             this.showToast(
//                 'Success',
//                 'Document generated successfully with contextual AI intelligence',
//                 'success'
//             );
//         } catch (error) {
//             this.showToast('Error', 'Document generation failed', 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     // Computed properties
//     get modelOptions() {
//         return this.availableModels;
//     }

//     get hasContextData() {
//         return this.folderContext?.documents?.length > 0;
//     }

//     get contextSummary() {
//         return this.folderContext?.contextualSummary || '';
//     }

//     get documentCount() {
//         return this.folderContext?.documents?.length || 0;
//     }

//     // Toast utility
//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }
// }




// // contextAwareDocumentGenerator.js
// import { LightningElement, track, wire, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { getRecord } from 'lightning/uiRecordApi';
// import getAvailableAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
// import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';
// import generateContextAwareDocument from '@salesforce/apex/ContextAwareDocumentEngine.generateContextAwareDocument';
// import askContextualQuestion from '@salesforce/apex/ContextAwareDocumentEngine.askContextualQuestion';

// export default class ContextAwareDocumentGenerator extends LightningElement {
//     @api recordId;
//     @api folderId;
    
//     // AI Model Selection
//     @track availableAIModels = [];
//     @track selectedAIModel = '';
//     @track showAdvancedOptions = false;
    
//     // Context Analysis
//     @track folderAnalysis = null;
//     @track isAnalyzing = false;
//     @track analysisComplete = false;
    
//     // Document Generation
//     @track isGenerating = false;
//     @track generationComplete = false;
//     @track generatedDocument = null;
//     @track selectedTemplate = '';
//     @track customPrompt = '';
    
//     // Q&A Feature
//     @track showQASection = false;
//     @track questionText = '';
//     @track qaHistory = [];
//     @track isProcessingQuestion = false;
    
//     // UI State
//     @track currentStep = 1;
//     @track maxSteps = 5;
//     @track showContextDetails = false;
//     @track showDocumentPreview = false;
    
//     // Progress Tracking
//     @track progressSteps = [
//         { number: 1, label: 'Select AI Model', status: 'current', description: 'Choose your preferred AI model' },
//         { number: 2, label: 'Analyze Context', status: 'pending', description: 'Analyze folder documents for context' },
//         { number: 3, label: 'Review Insights', status: 'pending', description: 'Review contextual insights and themes' },
//         { number: 4, label: 'Generate Document', status: 'pending', description: 'Generate context-aware document' },
//         { number: 5, label: 'Review & Export', status: 'pending', description: 'Review and export final document' }
//     ];

//     connectedCallback() {
//         this.loadAIModels();
//         if (this.folderId) {
//             this.updateProgressStep(1, 'completed');
//             this.currentStep = 2;
//         }
//     }

//     @wire(getAvailableAIModels)
//     wiredAIModels({ error, data }) {
//         if (data) {
//             this.availableAIModels = data.map(model => ({
//                 label: `${model.modelName} (${model.provider})`,
//                 value: model.modelId,
//                 description: model.description,
//                 capabilities: model.capabilities,
//                 provider: model.provider
//             }));
            
//             // Auto-select first Einstein model if available
//             const einsteinModel = this.availableAIModels.find(m => m.value.startsWith('einstein_'));
//             if (einsteinModel && !this.selectedAIModel) {
//                 this.selectedAIModel = einsteinModel.value;
//             }
//         } else if (error) {
//             this.showToast('Error', 'Failed to load AI models: ' + error.body.message, 'error');
//         }
//     }

//     // Event Handlers
//     handleAIModelChange(event) {
//         this.selectedAIModel = event.detail.value;
//         this.showAdvancedOptions = !!this.selectedAIModel;
        
//         // Reset analysis if model changes
//         if (this.folderAnalysis) {
//             this.folderAnalysis = null;
//             this.analysisComplete = false;
//             this.updateProgressStep(2, 'pending');
//         }
//     }

//     async handleAnalyzeContext() {
//         if (!this.selectedAIModel) {
//             this.showToast('Warning', 'Please select an AI model first', 'warning');
//             return;
//         }

//         if (!this.folderId) {
//             this.showToast('Warning', 'No folder selected for analysis', 'warning');
//             return;
//         }

//         this.isAnalyzing = true;
//         this.updateProgressStep(2, 'active');

//         try {
//             const result = await analyzeFolderContext({
//                 folderId: this.folderId,
//                 selectedAIModel: this.selectedAIModel
//             });

//             this.folderAnalysis = result;
//             this.analysisComplete = true;
//             this.updateProgressStep(2, 'completed');
//             this.updateProgressStep(3, 'current');
//             this.currentStep = 3;
//             this.showContextDetails = true;

//             this.showToast('Success', 'Context analysis completed successfully', 'success');
//         } catch (error) {
//             this.updateProgressStep(2, 'error');
//             this.showToast('Error', 'Context analysis failed: ' + error.body.message, 'error');
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     handleTemplateSelection(event) {
//         this.selectedTemplate = event.target.dataset.template;
//     }

//     handleCustomPromptChange(event) {
//         this.customPrompt = event.target.value;
//     }

//     async handleGenerateDocument() {
//         if (!this.folderAnalysis) {
//             this.showToast('Warning', 'Please analyze context first', 'warning');
//             return;
//         }

//         if (!this.selectedTemplate && !this.customPrompt) {
//             this.showToast('Warning', 'Please select a template or provide custom prompt', 'warning');
//             return;
//         }

//         this.isGenerating = true;
//         this.updateProgressStep(4, 'active');

//         try {
//             const result = await generateContextAwareDocument({
//                 folderAnalysis: this.folderAnalysis,
//                 selectedTemplate: this.selectedTemplate,
//                 customPrompt: this.customPrompt,
//                 selectedAIModel: this.selectedAIModel
//             });

//             this.generatedDocument = result;
//             this.generationComplete = true;
//             this.updateProgressStep(4, 'completed');
//             this.updateProgressStep(5, 'current');
//             this.currentStep = 5;
//             this.showDocumentPreview = true;

//             this.showToast('Success', 'Document generated successfully', 'success');
//         } catch (error) {
//             this.updateProgressStep(4, 'error');
//             this.showToast('Error', 'Document generation failed: ' + error.body.message, 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     // Q&A Functionality
//     handleShowQA() {
//         this.showQASection = !this.showQASection;
//     }

//     handleQuestionChange(event) {
//         this.questionText = event.target.value;
//     }

//     async handleAskQuestion() {
//         if (!this.questionText.trim()) {
//             this.showToast('Warning', 'Please enter a question', 'warning');
//             return;
//         }

//         if (!this.folderAnalysis) {
//             this.showToast('Warning', 'Please analyze context first', 'warning');
//             return;
//         }

//         this.isProcessingQuestion = true;

//         try {
//             const result = await askContextualQuestion({
//                 question: this.questionText,
//                 folderAnalysis: this.folderAnalysis,
//                 selectedAIModel: this.selectedAIModel
//             });

//             // Add to Q&A history
//             this.qaHistory = [
//                 ...this.qaHistory,
//                 {
//                     id: Date.now(),
//                     question: this.questionText,
//                     answer: result.answer,
//                     sources: result.sources,
//                     confidence: result.confidence,
//                     timestamp: new Date().toLocaleString()
//                 }
//             ];

//             this.questionText = '';
//             this.showToast('Success', 'Question answered successfully', 'success');
//         } catch (error) {
//             this.showToast('Error', 'Failed to process question: ' + error.body.message, 'error');
//         } finally {
//             this.isProcessingQuestion = false;
//         }
//     }

//     // Navigation
//     handlePrevious() {
//         if (this.currentStep > 1) {
//             this.currentStep--;
//             this.updateProgressStep(this.currentStep, 'current');
//         }
//     }

//     handleNext() {
//         if (this.currentStep < this.maxSteps) {
//             this.currentStep++;
//             this.updateProgressStep(this.currentStep, 'current');
//         }
//     }

//     // Utility Methods
//     updateProgressStep(stepNumber, status) {
//         this.progressSteps = this.progressSteps.map(step => {
//             if (step.number === stepNumber) {
//                 return { ...step, status };
//             } else if (step.number < stepNumber && status === 'current') {
//                 return { ...step, status: 'completed' };
//             }
//             return step;
//         });
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }

//     // Getters for UI logic
//     get isStep1() { return this.currentStep === 1; }
//     get isStep2() { return this.currentStep === 2; }
//     get isStep3() { return this.currentStep === 3; }
//     get isStep4() { return this.currentStep === 4; }
//     get isStep5() { return this.currentStep === 5; }

//     get showPreviousButton() { return this.currentStep > 1; }
//     get showNextButton() { return this.currentStep < this.maxSteps && this.canProceedToNext; }

//     get canProceedToNext() {
//         switch (this.currentStep) {
//             case 1: return !!this.selectedAIModel;
//             case 2: return this.analysisComplete;
//             case 3: return this.analysisComplete;
//             case 4: return this.generationComplete;
//             default: return false;
//         }
//     }

//     get selectedModelInfo() {
//         return this.availableAIModels.find(model => model.value === this.selectedAIModel);
//     }

//     get contextQualityClass() {
//         if (!this.folderAnalysis) return '';
        
//         const score = this.folderAnalysis.qualityScore;
//         if (score >= 80) return 'context-quality-excellent';
//         if (score >= 60) return 'context-quality-good';
//         if (score >= 40) return 'context-quality-fair';
//         return 'context-quality-limited';
//     }

//     get contextQualityLabel() {
//         if (!this.folderAnalysis) return 'Not Analyzed';
        
//         const score = this.folderAnalysis.qualityScore;
//         if (score >= 80) return 'Excellent Context';
//         if (score >= 60) return 'Good Context';
//         if (score >= 40) return 'Fair Context';
//         return 'Limited Context';
//     }

//     get templateSuggestions() {
//         return this.folderAnalysis?.templateSuggestions || [];
//     }

//     get documentMetrics() {
//         if (!this.folderAnalysis) return [];

//         return [
//             {
//                 label: 'Documents Analyzed',
//                 value: this.folderAnalysis.documents.length,
//                 icon: 'utility:file'
//             },
//             {
//                 label: 'Common Themes',
//                 value: this.folderAnalysis.commonThemes.length,
//                 icon: 'utility:topic'
//             },
//             {
//                 label: 'Entities Extracted',
//                 value: Object.keys(this.folderAnalysis.entityFrequency).length,
//                 icon: 'utility:knowledge_base'
//             },
//             {
//                 label: 'Document Relationships',
//                 value: Object.values(this.folderAnalysis.documentRelationships).flat().length,
//                 icon: 'utility:connected_apps'
//             },
//             {
//                 label: 'Quality Score',
//                 value: this.folderAnalysis.qualityScore + '/100',
//                 icon: 'utility:rating'
//             }
//         ];
//     }

//     get entityFrequency() {
//         if (!this.folderAnalysis?.entityFrequency) return [];

//         const totalEntities = Object.values(this.folderAnalysis.entityFrequency)
//             .reduce((sum, count) => sum + count, 0);

//         return Object.entries(this.folderAnalysis.entityFrequency)
//             .sort(([, a], [, b]) => b - a)
//             .slice(0, 10)
//             .map(([name, count]) => ({
//                 name,
//                 count,
//                 percentage: Math.round((count / totalEntities) * 100)
//             }));
//     }

//     get contextualSummary() {
//         return this.folderAnalysis?.contextSummary || 'No context analysis available';
//     }

//     get hasQAHistory() {
//         return this.qaHistory.length > 0;
//     }

//     get documentCount() {
//         return this.folderAnalysis?.documents?.length || 0;
//     }

//     get isContextRich() {
//         return this.folderAnalysis?.qualityScore >= 70;
//     }

//     get aiModelCapabilities() {
//         const model = this.selectedModelInfo;
//         if (!model) return [];
//         return model.capabilities.split(',').map(cap => cap.trim());
//     }
//     // contextAwareDocumentGenerator.js - Step 3.4
// // Additional methods for contextAwareDocumentGenerator LWC

// // Export Format Options
// get exportFormatOptions() {
//     return [
//         { label: 'PDF Document', value: 'pdf', description: 'Portable Document Format' },
//         { label: 'Microsoft Word', value: 'docx', description: 'Word Document' },
//         { label: 'Rich Text Format', value: 'rtf', description: 'Rich Text Format' },
//         { label: 'Plain Text', value: 'txt', description: 'Plain Text File' },
//         { label: 'HTML Document', value: 'html', description: 'Web Document' }
//     ];
// }

// /* -------------------------
//    Step 5 Event Handlers
// --------------------------*/
// handleTogglePreview() {
//     this.showDocumentPreview = !this.showDocumentPreview;
// }

// handleEditDocument() {
//     this.showDocumentEditor = true; // Navigate to document editor
// }

// handleExportFormatChange(event) {
//     this.selectedExportFormat = event.detail.value;
// }

// handleDocumentTitleChange(event) {
//     this.documentTitle = event.target.value;
// }

// async handleExportDocument() {
//     if (!this.selectedExportFormat) {
//         this.showToast('Warning', 'Please select an export format', 'warning');
//         return;
//     }

//     this.isExporting = true;
//     this.showLoadingOverlay = true;
//     this.loadingMessage = `Preparing ${this.selectedExportFormat.toUpperCase()} export...`;

//     try {
//         const exportResult = await exportDocument({
//             documentContent: this.generatedDocument.content,
//             format: this.selectedExportFormat,
//             title: this.documentTitle || 'Generated Document',
//             metadata: {
//                 aiModel: this.selectedAIModel,
//                 generatedDate: new Date().toISOString(),
//                 sourcesUsed: this.generatedDocument.sources?.length || 0,
//                 contextQuality: this.folderAnalysis.qualityScore
//             }
//         });

//         // Trigger download
//         const downloadLink = document.createElement('a');
//         downloadLink.href = exportResult.downloadUrl;
//         downloadLink.download = exportResult.filename;
//         downloadLink.click();

//         this.showToast('Success', 'Document exported successfully', 'success');
//     } catch (error) {
//         this.showToast('Error', 'Export failed: ' + error.body.message, 'error');
//     } finally {
//         this.isExporting = false;
//         this.showLoadingOverlay = false;
//     }
// }

// async handleSaveToLibrary() {
//     if (!this.generatedDocument) {
//         this.showToast('Warning', 'No document to save', 'warning');
//         return;
//     }

//     this.isSaving = true;
//     this.showLoadingOverlay = true;
//     this.loadingMessage = 'Saving document to library...';

//     try {
//         const saveResult = await saveDocumentToLibrary({
//             documentContent: this.generatedDocument.content,
//             title: this.documentTitle || 'Generated Document',
//             folderId: this.folderId,
//             metadata: {
//                 aiModel: this.selectedAIModel,
//                 generatedDate: new Date().toISOString(),
//                 sourcesUsed: this.generatedDocument.sources?.length || 0,
//                 contextQuality: this.folderAnalysis.qualityScore,
//                 wordCount: this.generatedDocument.wordCount,
//                 confidenceScore: this.generatedDocument.confidenceScore
//             }
//         });

//         this.savedDocumentId = saveResult.documentId;
//         this.showToast('Success', 'Document saved to library successfully', 'success');

//         // Optionally navigate to the saved document
//         this.navigateToSavedDocument(saveResult.documentId);

//     } catch (error) {
//         this.showToast('Error', 'Failed to save document: ' + error.body.message, 'error');
//     } finally {
//         this.isSaving = false;
//         this.showLoadingOverlay = false;
//     }
// }

// handleShareDocument() {
//     if (!this.generatedDocument) {
//         this.showToast('Warning', 'No document to share', 'warning');
//         return;
//     }
//     this.showShareModal = true; // Open share modal
// }

// handleGenerateNew() {
//     if (confirm('Are you sure you want to start over? This will clear your current document.')) {
//         this.resetComponent();
//     }
// }

// handleToggleContextDetails() {
//     this.showContextDetails = !this.showContextDetails;
// }

// /* -------------------------
//    Advanced Methods
// --------------------------*/
// async loadAIModels() {
//     try {
//         // Additional logic for loading AI models if needed
//     } catch (error) {
//         this.showToast('Error', 'Failed to load AI models: ' + error.message, 'error');
//     }
// }

// resetComponent() {
//     this.selectedAIModel = '';
//     this.folderAnalysis = null;
//     this.isAnalyzing = false;
//     this.analysisComplete = false;
//     this.isGenerating = false;
//     this.generationComplete = false;
//     this.generatedDocument = null;
//     this.selectedTemplate = '';
//     this.customPrompt = '';
//     this.showQASection = false;
//     this.questionText = '';
//     this.qaHistory = [];
//     this.isProcessingQuestion = false;
//     this.currentStep = 1;
//     this.showContextDetails = false;
//     this.showDocumentPreview = false;
//     this.selectedExportFormat = '';
//     this.documentTitle = '';
//     this.isExporting = false;
//     this.isSaving = false;
//     this.showLoadingOverlay = false;

//     // Reset progress steps
//     this.progressSteps = this.progressSteps.map((step, index) => ({
//         ...step,
//         status: index === 0 ? 'current' : 'pending'
//     }));

//     this.showToast('Info', 'Component reset successfully', 'info');
// }

// navigateToSavedDocument(documentId) {
//     this[NavigationMixin.Navigate]({
//         type: 'standard__recordPage',
//         attributes: {
//             recordId: documentId,
//             actionName: 'view'
//         }
//     });
// }

// /* -------------------------
//    Utility Helpers
// --------------------------*/
// delay(ms) {
//     return new Promise(resolve => setTimeout(resolve, ms));
// }

// handleError(error, context) {
//     console.error(`Error in ${context}:`, error);

//     let errorMessage = 'An unexpected error occurred';
//     if (error?.body?.message) {
//         errorMessage = error.body.message;
//     } else if (error?.message) {
//         errorMessage = error.message;
//     }

//     this.showToast('Error', `${context}: ${errorMessage}`, 'error');
// }

// trackPerformance(operation, startTime) {
//     const duration = performance.now() - startTime;
//     console.log(`Performance: ${operation} took ${duration.toFixed(2)}ms`);
// }

// /* -------------------------
//    Computed Properties
// --------------------------*/
// get hasContextAnalysis() {
//     return this.folderAnalysis && Object.keys(this.folderAnalysis).length > 0;
// }

// get isNextDisabled() {
//     return !this.canProceedToNext || this.isAnalyzing || this.isGenerating;
// }

// get hasError() {
//     return this.progressSteps.some(step => step.status === 'error');
// }

// get completionPercentage() {
//     const completedSteps = this.progressSteps.filter(step => step.status === 'completed').length;
//     return Math.round((completedSteps / this.maxSteps) * 100);
// }

// get documentStats() {
//     if (!this.generatedDocument) return [];
//     return [
//         { label: 'Generation Time', value: this.generatedDocument.generationTime || 'N/A', icon: 'utility:clock' },
//         { label: 'AI Model', value: this.selectedModelInfo?.modelName || 'Unknown', icon: 'utility:ai_model' },
//         { label: 'Context Score', value: `${this.folderAnalysis?.qualityScore || 0}/100`, icon: 'utility:rating' }
//     ];
// }

// get isHighQualityContext() {
//     return this.folderAnalysis?.qualityScore >= 80;
// }

// get contextQualityMessage() {
//     if (!this.folderAnalysis) return '';
//     const score = this.folderAnalysis.qualityScore;
//     if (score >= 80) return 'Excellent context quality - documents are highly related and comprehensive';
//     if (score >= 60) return 'Good context quality - sufficient information for accurate generation';
//     if (score >= 40) return 'Fair context quality - some gaps in information may affect accuracy';
//     return 'Limited context quality - consider adding more relevant documents';
// }

// get suggestedActions() {
//     const actions = [];
//     if (!this.isContextRich) {
//         actions.push({ label: 'Add More Documents', action: 'addDocuments', description: 'Upload additional documents to improve context quality' });
//     }
//     if (this.generatedDocument && this.generatedDocument.confidenceScore < 70) {
//         actions.push({ label: 'Refine Prompt', action: 'refinePrompt', description: 'Adjust the generation prompt for better results' });
//     }
//     if (this.qaHistory.length === 0 && this.analysisComplete) {
//         actions.push({ label: 'Ask Questions', action: 'askQuestions', description: 'Use the Q&A feature to better understand your documents' });
//     }
//     return actions;
// }

// /* -------------------------
//    Suggested Actions
// --------------------------*/
// handleSuggestedAction(event) {
//     const action = event.target.dataset.action;
//     switch (action) {
//         case 'addDocuments':
//             this.navigateToDocumentUpload();
//             break;
//         case 'refinePrompt':
//             this.currentStep = 4;
//             this.updateProgressStep(4, 'current');
//             break;
//         case 'askQuestions':
//             this.showQASection = true;
//             break;
//         default:
//             console.warn('Unknown suggested action:', action);
//     }
// }

// navigateToDocumentUpload() {
//     this[NavigationMixin.Navigate]({
//         type: 'standard__webPage',
//         attributes: {
//             url: `/lightning/o/ContentDocument/home?folderId=${this.folderId}`
//         }
//     });
// }

// /* -------------------------
//    Keyboard Shortcuts
// --------------------------*/
// handleKeyboardShortcuts(event) {
//     if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
//         if (this.showNextButton && !this.isNextDisabled) {
//             this.handleNext();
//         }
//     }
//     if (event.key === 'Escape') {
//         if (this.showPreviousButton) {
//             this.handlePrevious();
//         }
//     }
// }

// /* -------------------------
//    Lifecycle
// --------------------------*/
// connectedCallback() {
//     super.connectedCallback();
//     document.addEventListener('keydown', this.handleKeyboardShortcuts.bind(this));
//     this.initializeComponent();
// }

// disconnectedCallback() {
//     document.removeEventListener('keydown', this.handleKeyboardShortcuts.bind(this));
// }

// async initializeComponent() {
//     try {
//         this.loadingMessage = 'Initializing component...';
//         this.showLoadingOverlay = true;
//         await this.loadAIModels();

//         if (this.folderId) {
//             this.updateProgressStep(1, 'completed');
//             this.currentStep = 2;
//         }

//         this.showToast('Success', 'Component initialized successfully', 'success');
//     } catch (error) {
//         this.handleError(error, 'Component Initialization');
//     } finally {
//         this.showLoadingOverlay = false;
//     }
// }

// /* -------------------------
//    Validation
// --------------------------*/
// validateStep(stepNumber) {
//     switch (stepNumber) {
//         case 1: return this.selectedAIModel?.length > 0;
//         case 2: return this.analysisComplete && this.folderAnalysis;
//         case 3: return this.analysisComplete;
//         case 4: return this.selectedTemplate || (this.customPrompt?.trim().length > 0);
//         case 5: return this.generationComplete && this.generatedDocument;
//         default: return false;
//     }
// }

// validateAllSteps() {
//     const errors = [];
//     for (let i = 1; i <= this.maxSteps; i++) {
//         if (!this.validateStep(i)) {
//             errors.push(`Step ${i} validation failed`);
//         }
//     }

//     if (errors.length > 0) {
//         this.showToast('Validation Error', errors.join(', '), 'error');
//         return false;
//     }
//     return true;
// }

// /* -------------------------
//    Analytics + Refresh
// --------------------------*/
// trackUserAction(action, metadata = {}) {
//     const trackingData = {
//         action,
//         timestamp: new Date().toISOString(),
//         step: this.currentStep,
//         aiModel: this.selectedAIModel,
//         folderId: this.folderId,
//         ...metadata
//     };
//     console.log('User Action:', trackingData);
// }

// async handleRefresh() {
//     this.trackUserAction('component_refresh');
//     try {
//         this.showLoadingOverlay = true;
//         this.loadingMessage = 'Refreshing component...';

//         await refreshApex(this.wiredAIModelsResult);
//         if (this.analysisComplete) {
//             await this.handleAnalyzeContext();
//         }

//         this.showToast('Success', 'Component refreshed successfully', 'success');
//     } catch (error) {
//         this.handleError(error, 'Component Refresh');
//     } finally {
//         this.showLoadingOverlay = false;
//     }
// }

    
// }




// // contextAwareDocumentGenerator.js
// import { LightningElement, api, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { NavigationMixin } from 'lightning/navigation';

// // Import Apex methods
// import getAvailableAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
// import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';
// import askContextualQuestion from '@salesforce/apex/ContextAwareDocumentEngine.askContextualQuestion';
// import generateContextualDocument from '@salesforce/apex/ContextAwareDocumentGenerator.generateDocument';
// import getDocumentTemplates from '@salesforce/apex/DocumentTemplateManager.getAvailableTemplates';
// import getSuggestedQuestions from '@salesforce/apex/ContextAwareDocumentEngine.getSuggestedQuestions';

// export default class ContextAwareDocumentGenerator extends NavigationMixin(LightningElement) {
//     @api recordId; // Folder ID

//     // AI Model Management
//     @track selectedAIModel = '';
//     @track qaSelectedAIModel = '';
//     @track availableAIModels = [];
//     @track qaSelectedAIModelInfo = null;

//     // Context Analysis
//     @track contextAnalysis = null;
//     @track contextQuery = '';
//     @track isProcessing = false;
//     @track processingStatus = '';

//     // Q&A Interface
//     @track currentQuestion = '';
//     @track conversationHistory = [];
//     @track isProcessingQuestion = false;
//     @track showChatInterface = false;
//     @track suggestedQuestions = [];
//     @track selectedAnalysisOptions = [];

//     // Document Generation
//     @track selectedTemplate = '';
//     @track availableTemplates = [];
//     @track documentTitle = '';
//     @track customInstructions = '';
//     @track selectedGenerationOptions = [];
//     @track aiSuggestions = [];
//     @track showDocumentGeneration = false;
//     @track isGeneratingDocument = false;
//     @track generationProgress = 0;
//     @track generationStatus = '';
//     @track generatedDocument = null;

//     // UI States
//     @track generateDisabled = true;
//     @track askQuestionDisabled = true;
//     @track generateDocumentDisabled = true;

//     // Options for checkboxes
//     analysisOptions = [
//         { label: 'Include semantic analysis', value: 'semantic' },
//         { label: 'Cross-document references', value: 'cross_reference' },
//         { label: 'Entity relationship mapping', value: 'entity_mapping' },
//         { label: 'Sentiment analysis', value: 'sentiment' }
//     ];

//     generationOptions = [
//         { label: 'Include executive summary', value: 'executive_summary' },
//         { label: 'Add compliance checks', value: 'compliance_checks' },
//         { label: 'Include citations', value: 'citations' },
//         { label: 'Generate table of contents', value: 'toc' },
//         { label: 'Add recommendations', value: 'recommendations' }
//     ];

//     connectedCallback() {
//         this.loadInitialData();
//     }

//     // ------------------------------
//     // Initialization
//     // ------------------------------
//     async loadInitialData() {
//         try {
//             await Promise.all([
//                 this.loadAIModels(),
//                 this.loadDocumentTemplates()
//             ]);
//         } catch (error) {
//             this.handleError(error, 'Loading initial data');
//         }
//     }

//     async loadAIModels() {
//         try {
//             const models = await getAvailableAIModels();
//             this.availableAIModels = models.map(model => ({
//                 label: `${model.modelName} (${model.provider}) - ${model.capabilities}`,
//                 value: model.modelId,
//                 modelInfo: model
//             }));

//             if (this.availableAIModels.length > 0) {
//                 this.selectedAIModel = this.availableAIModels[0].value;
//                 this.qaSelectedAIModel = this.availableAIModels[0].value;
//                 this.updateQAModelInfo();
//             }
//         } catch (error) {
//             this.handleError(error, 'Loading AI models');
//         }
//     }

//     async loadDocumentTemplates() {
//         try {
//             const templates = await getDocumentTemplates();
//             this.availableTemplates = templates.map(template => ({
//                 label: template.templateName,
//                 value: template.templateId
//             }));
//         } catch (error) {
//             this.handleError(error, 'Loading document templates');
//         }
//     }

//     // ------------------------------
//     // AI Model Selection
//     // ------------------------------
//     handleAIModelChange(event) {
//         this.selectedAIModel = event.detail.value;
//         this.updateUIStates();
//     }

//     handleQAAIModelChange(event) {
//         this.qaSelectedAIModel = event.detail.value;
//         this.updateQAModelInfo();
//         this.updateUIStates();
//     }

//     updateQAModelInfo() {
//         const selectedModel = this.availableAIModels.find(
//             model => model.value === this.qaSelectedAIModel
//         );
//         this.qaSelectedAIModelInfo = selectedModel ? selectedModel.modelInfo : null;
//     }

//     // ------------------------------
//     // Context Analysis
//     // ------------------------------
//     handleContextQueryChange(event) {
//         this.contextQuery = event.detail.value;
//     }

//     async handleAnalyzeContext() {
//         if (!this.selectedAIModel) {
//             this.showToast('Error', 'Please select an AI model first', 'error');
//             return;
//         }

//         this.isProcessing = true;
//         this.processingStatus = 'Analyzing folder context...';

//         try {
//             this.contextAnalysis = await analyzeFolderContext({
//                 folderId: this.recordId,
//                 selectedAIModel: this.selectedAIModel,
//                 contextQuery: this.contextQuery
//             });

//             if (this.contextAnalysis.error) {
//                 throw new Error(this.contextAnalysis.error);
//             }

//             await this.loadSuggestedQuestions();
//             this.showChatInterface = true;
//             this.showDocumentGeneration = true;
//             this.updateUIStates();

//             this.showToast('Success', 'Folder context analyzed successfully', 'success');
//         } catch (error) {
//             this.handleError(error, 'Context Analysis');
//         } finally {
//             this.isProcessing = false;
//             this.processingStatus = '';
//         }
//     }

//     async loadSuggestedQuestions() {
//         try {
//             this.suggestedQuestions = await getSuggestedQuestions({
//                 contextAnalysis: this.contextAnalysis,
//                 aiModel: this.qaSelectedAIModel
//             });
//         } catch (error) {
//             console.error('Error loading suggested questions:', error);
//         }
//     }

//     // ------------------------------
//     // Q&A Interface
//     // ------------------------------
//     handleQuestionChange(event) {
//         this.currentQuestion = event.detail.value;
//         this.updateUIStates();
//     }

//     handleAnalysisOptionsChange(event) {
//         this.selectedAnalysisOptions = event.detail.value;
//     }

//     handleSuggestedQuestionClick(event) {
//         this.currentQuestion = event.target.dataset.question;
//         this.handleAskQuestion();
//     }

//     async handleAskQuestion() {
//         if (!this.currentQuestion.trim()) {
//             this.showToast('Error', 'Please enter a question', 'error');
//             return;
//         }

//         this.isProcessingQuestion = true;

//         const userMessage = {
//             id: Date.now().toString(),
//             isUser: true,
//             isAI: false,
//             content: this.currentQuestion,
//             timestamp: new Date().toLocaleTimeString(),
//             cssClass: 'message user-message'
//         };
//         this.conversationHistory = [...this.conversationHistory, userMessage];

//         try {
//             const response = await askContextualQuestion({
//                 question: this.currentQuestion,
//                 contextAnalysis: this.contextAnalysis,
//                 selectedAIModel: this.qaSelectedAIModel,
//                 analysisOptions: this.selectedAnalysisOptions
//             });

//             const aiMessage = {
//                 id: (Date.now() + 1).toString(),
//                 isUser: false,
//                 isAI: true,
//                 content: response.answer,
//                 aiModelName: this.qaSelectedAIModelName,
//                 timestamp: new Date().toLocaleTimeString(),
//                 sources: response.sources || [],
//                 followUpQuestions: response.followUpQuestions || [],
//                 cssClass: 'message ai-message'
//             };
//             this.conversationHistory = [...this.conversationHistory, aiMessage];

//             this.currentQuestion = '';

//             if (response.documentSuggestions) {
//                 this.aiSuggestions = response.documentSuggestions;
//             }
//         } catch (error) {
//             this.handleError(error, 'Processing Question');
//         } finally {
//             this.isProcessingQuestion = false;
//         }
//     }

//     handleFollowUpClick(event) {
//         this.currentQuestion = event.target.dataset.question;
//         this.handleAskQuestion();
//     }

//     handleSourceClick(event) {
//         const sourceId = event.target.dataset.sourceId;
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: sourceId,
//                 objectApiName: 'ContentDocument',
//                 actionName: 'view'
//             }
//         });
//     }

//     // ------------------------------
//     // Document Generation
//     // ------------------------------
//     handleTemplateChange(event) {
//         this.selectedTemplate = event.detail.value;
//         this.updateUIStates();
//     }

//     handleDocumentTitleChange(event) {
//         this.documentTitle = event.detail.value;
//         this.updateUIStates();
//     }

//     handleGenerationOptionsChange(event) {
//         this.selectedGenerationOptions = event.detail.value;
//     }

//     handleCustomInstructionsChange(event) {
//         this.customInstructions = event.detail.value;
//     }

//     async handleGenerateContextAwareDocument() {
//         if (!this.selectedTemplate || !this.documentTitle) {
//             this.showToast('Error', 'Please select a template and enter a document title', 'error');
//             return;
//         }

//         this.isGeneratingDocument = true;
//         this.generationProgress = 0;
//         this.generationStatus = 'Initializing document generation...';

//         try {
//             const progressInterval = setInterval(() => {
//                 if (this.generationProgress < 90) {
//                     this.generationProgress += 10;
//                     this.updateGenerationStatus();
//                 }
//             }, 500);

//             const result = await generateContextualDocument({
//                 contextAnalysis: this.contextAnalysis,
//                 templateId: this.selectedTemplate,
//                 documentTitle: this.documentTitle,
//                 customInstructions: this.customInstructions,
//                 generationOptions: this.selectedGenerationOptions,
//                 selectedAIModel: this.selectedAIModel,
//                 conversationHistory: this.conversationHistory
//             });

//             clearInterval(progressInterval);
//             this.generationProgress = 100;
//             this.generationStatus = 'Document generated successfully!';

//             this.generatedDocument = {
//                 title: result.title,
//                 content: result.content,
//                 templateName: result.templateName,
//                 aiModelUsed: this.selectedAIModelName,
//                 timestamp: new Date().toLocaleString(),
//                 documentId: result.documentId
//             };

//             this.showToast('Success', 'Document generated successfully', 'success');
//         } catch (error) {
//             this.handleError(error, 'Document Generation');
//         } finally {
//             this.isGeneratingDocument = false;
//         }
//     }

//     // ------------------------------
//     // UI & Utility
//     // ------------------------------
//     updateUIStates() {
//         this.generateDisabled = !this.selectedAIModel;
//         this.askQuestionDisabled = !this.qaSelectedAIModel || !this.currentQuestion.trim();
//         this.generateDocumentDisabled = !this.selectedTemplate || !this.documentTitle.trim() || !this.contextAnalysis;
//     }

//     get selectedAIModelName() {
//         const model = this.availableAIModels.find(m => m.value === this.selectedAIModel);
//         return model ? model.label : '';
//     }

//     get qaSelectedAIModelName() {
//         const model = this.availableAIModels.find(m => m.value === this.qaSelectedAIModel);
//         return model ? model.label : '';
//     }

//     // ------------------------------
//     // Error Handling & Cleanup
//     // ------------------------------
//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }

//     handleError(error, context) {
//         console.error(`Error in ${context}:`, error);
//         let errorMessage = error?.body?.message || error.message || 'Unexpected error';
//         this.showToast('Error', `${context}: ${errorMessage}`, 'error');
//     }

//     disconnectedCallback() {
//         if (this.progressInterval) {
//             clearInterval(this.progressInterval);
//         }
//     }

//     // Advanced Analytics and Reporting Methods
// @api
// async generateAnalyticsReport() {
//     try {
//         this.isProcessing = true;
//         this.processingStatus = 'Generating comprehensive analytics report...';

//         const analyticsData = await generateSystemAnalytics({
//             sessionId: this.sessionId,
//             timeRange: '30days',
//             includePerformance: true,
//             includeUsage: true,
//             includeCompliance: true
//         });

//         this.analyticsReport = analyticsData;
//         this.showAnalyticsModal = true;

//         this.showToast('Success', 'Analytics report generated successfully', 'success');

//     } catch (error) {
//         console.error('Analytics generation error:', error);
//         this.errorMessage = 'Failed to generate analytics report: ' + error.body?.message;
//         this.showToast('Error', this.errorMessage, 'error');
//     } finally {
//         this.isProcessing = false;
//         this.processingStatus = '';
//     }
// }

// // Export and Integration Methods
// handleExportDocument() {
//     if (!this.generatedDocument) {
//         this.showToast('Warning', 'No document available to export', 'warning');
//         return;
//     }

//     this.exportOptions = [
//         { label: 'PDF', value: 'pdf' },
//         { label: 'Word Document', value: 'docx' },
//         { label: 'HTML', value: 'html' },
//         { label: 'Plain Text', value: 'txt' }
//     ];

//     this.showExportModal = true;
// }

// async handleConfirmExport(event) {
//     const exportFormat = event.detail.format;

//     try {
//         this.isExporting = true;

//         const exportResult = await exportDocument({
//             documentId: this.generatedDocument.id,
//             format: exportFormat,
//             includeMetadata: true,
//             watermark: this.generatedDocument.watermark
//         });

//         if (exportResult.success) {
//             const link = document.createElement('a');
//             link.href = exportResult.downloadUrl;
//             link.download = exportResult.filename;
//             link.click();

//             this.showToast('Success', 'Document exported successfully', 'success');
//         }
//     } catch (error) {
//         console.error('Export error:', error);
//         this.showToast('Error', 'Export failed: ' + error.body?.message, 'error');
//     } finally {
//         this.isExporting = false;
//         this.showExportModal = false;
//     }
// }

// // Advanced Security and Compliance Methods
// async validateDocumentCompliance() {
//     if (!this.generatedDocument) return;

//     try {
//         this.isValidatingCompliance = true;

//         const complianceResult = await validateCompliance({
//             documentContent: this.generatedDocument.content,
//             documentType: this.generatedDocument.type,
//             jurisdiction: this.selectedJurisdiction || 'US',
//             industry: this.selectedIndustry || 'General'
//         });

//         this.complianceResults = complianceResult;
//         this.complianceScore = complianceResult.overallScore;

//         if (complianceResult.issues?.length > 0) {
//             this.complianceIssues = complianceResult.issues;
//             this.showComplianceWarning = true;
//         }

//         this.showToast(
//             'Compliance Check Complete',
//             `Compliance score: ${this.complianceScore}%`,
//             complianceResult.overallScore >= 85 ? 'success' : 'warning'
//         );

//     } catch (error) {
//         console.error('Compliance validation error:', error);
//         this.errorMessage = 'Compliance validation failed: ' + error.body?.message;
//         this.showToast('Error', this.errorMessage, 'error');
//     } finally {
//         this.isValidatingCompliance = false;
//     }
// }

// // Real-time Collaboration Methods
// handleEnableCollaboration() {
//     try {
//         this.collaborationEnabled = true;
//         this.initializeWebSocket();
//         this.showToast('Success', 'Real-time collaboration enabled', 'success');
//     } catch (error) {
//         console.error('Collaboration setup error:', error);
//         this.showToast('Error', 'Failed to enable collaboration', 'error');
//     }
// }

// initializeWebSocket() {
//     if (this.websocket) {
//         this.websocket.close();
//     }

//     const wsUrl = `wss://your-domain.com/collaboration/${this.sessionId}`;
//     this.websocket = new WebSocket(wsUrl);

//     this.websocket.onopen = () => {
//         console.log('WebSocket connection established');
//         this.collaborationStatus = 'connected';
//     };

//     this.websocket.onmessage = (event) => {
//         const message = JSON.parse(event.data);
//         this.handleCollaborationMessage(message);
//     };

//     this.websocket.onerror = (error) => {
//         console.error('WebSocket error:', error);
//         this.collaborationStatus = 'error';
//     };

//     this.websocket.onclose = () => {
//         this.collaborationStatus = 'disconnected';
//         if (this.collaborationEnabled) {
//             setTimeout(() => this.initializeWebSocket(), 5000);
//         }
//     };
// }

// handleCollaborationMessage(message) {
//     switch (message.type) {
//         case 'user_joined':
//             this.collaborators.push(message.user);
//             break;
//         case 'user_left':
//             this.collaborators = this.collaborators.filter(c => c.id !== message.user.id);
//             break;
//         case 'document_updated':
//             this.handleRemoteDocumentUpdate(message.data);
//             break;
//         case 'cursor_position':
//             this.updateRemoteCursor(message.user, message.position);
//             break;
//     }
// }

// // Advanced AI Model Management
// async handleAIModelChange(event) {
//     const selectedModel = event.detail.value;
//     this.selectedAIModel = selectedModel;

//     try {
//         const modelConfig = await getAIModelConfiguration({
//             modelId: selectedModel,
//             organizationId: this.organizationId
//         });

//         this.currentModelConfig = modelConfig;
//         this.updateModelCapabilities(modelConfig);
//         this.updateAvailableFeatures(modelConfig.features);

//         this.showToast('Success', `AI Model changed to ${modelConfig.displayName}`, 'success');

//     } catch (error) {
//         console.error('Model configuration error:', error);
//         this.showToast('Error', 'Failed to load model configuration', 'error');
//         this.selectedAIModel = this.previousAIModel;
//     }
// }

// updateModelCapabilities(config) {
//     this.modelCapabilities = {
//         maxTokens: config.maxTokens || 4000,
//         supportedLanguages: config.supportedLanguages || ['en'],
//         features: config.features || [],
//         customPrompting: config.customPrompting || false,
//         finetuningAvailable: config.finetuningAvailable || false,
//         realTimeProcessing: config.realTimeProcessing || false
//     };

//     this.generationOptions = this.generationOptions.map(option => ({
//         ...option,
//         disabled: !this.modelCapabilities.features.includes(option.feature)
//     }));
// }

// // Performance Monitoring and Optimization
// @wire(getSystemPerformanceMetrics)
// wiredPerformanceMetrics({ error, data }) {
//     if (data) {
//         this.performanceMetrics = data.map(metric => ({
//             ...metric,
//             statusVariant: this.getMetricStatusVariant(metric.currentValue, metric.target),
//             formattedValue: this.formatMetricValue(metric.currentValue, metric.unit)
//         }));
//         this.updatePerformanceDashboard();
//     } else if (error) {
//         console.error('Performance metrics error:', error);
//     }
// }

// getMetricStatusVariant(current, target) {
//     const percentage = (current / target) * 100;
//     if (percentage >= 90) return 'success';
//     if (percentage >= 70) return 'warning';
//     return 'error';
// }

// formatMetricValue(value, unit) {
//     switch (unit) {
//         case 'ms': return `${value}ms`;
//         case 'seconds': return `${value}s`;
//         case 'percentage': return `${value}%`;
//         case 'mb': return `${value}MB`;
//         default: return value;
//     }
// }

// updatePerformanceDashboard() {
//     const healthScore = this.performanceMetrics.reduce((acc, metric) => {
//         const score = (metric.currentValue / metric.target) * 100;
//         return acc + Math.min(score, 100);
//     }, 0) / this.performanceMetrics.length;

//     this.systemHealthScore = Math.round(healthScore);
//     this.systemHealthStatus = this.getSystemHealthStatus(healthScore);
//     this.updatePerformanceCharts();
// }

// getSystemHealthStatus(score) {
//     if (score >= 90) return 'Excellent';
//     if (score >= 75) return 'Good';
//     if (score >= 60) return 'Fair';
//     return 'Poor';
// }

// // Advanced Search and Filtering
// handleAdvancedSearch(event) {
//     const searchQuery = event.detail.value;
//     this.currentSearchQuery = searchQuery;

//     if (searchQuery.length >= 3) {
//         this.debounceSearch(searchQuery);
//     } else {
//         this.searchResults = [];
//         this.showSearchResults = false;
//     }
// }

// debounceSearch = this.debounce((query) => {
//     this.performAdvancedSearch(query);
// }, 500);

// async performAdvancedSearch(query) {
//     try {
//         this.isSearching = true;

//         const searchResults = await performSemanticSearch({
//             query: query,
//             documentIds: this.documentList.map(doc => doc.id),
//             searchType: 'semantic',
//             includeContext: true,
//             maxResults: 20
//         });

//         this.searchResults = searchResults.map(result => ({
//             ...result,
//             highlightedText: this.highlightSearchTerms(result.content, query),
//             relevanceScore: Math.round(result.score * 100)
//         }));

//         this.showSearchResults = true;

//     } catch (error) {
//         console.error('Search error:', error);
//         this.showToast('Error', 'Search failed: ' + error.body?.message, 'error');
//     } finally {
//         this.isSearching = false;
//     }
// }

// highlightSearchTerms(text, query) {
//     const terms = query.split(' ').filter(term => term.length > 2);
//     let highlightedText = text;

//     terms.forEach(term => {
//         const regex = new RegExp(`(${term})`, 'gi');
//         highlightedText = highlightedText.replace(regex, '<mark>$1</mark>');
//     });

//     return highlightedText;
// }

// // Document Version Control and History
// async handleCreateVersion() {
//     if (!this.generatedDocument) {
//         this.showToast('Warning', 'No document to version', 'warning');
//         return;
//     }

//     try {
//         this.isCreatingVersion = true;

//         const versionResult = await createDocumentVersion({
//             documentId: this.generatedDocument.id,
//             comment: this.versionComment || 'Auto-generated version',
//             majorVersion: this.isMajorVersion
//         });

//         this.documentVersions.unshift(versionResult);
//         this.currentVersion = versionResult;

//         this.showToast('Success', `Version ${versionResult.versionNumber} created successfully`, 'success');

//         this.versionComment = '';
//         this.showVersionModal = false;

//     } catch (error) {
//         console.error('Version creation error:', error);
//         this.showToast('Error', 'Failed to create version: ' + error.body?.message, 'error');
//     } finally {
//         this.isCreatingVersion = false;
//     }
// }

// async handleRestoreVersion(event) {
//     const versionId = event.target.dataset.versionId;

//     try {
//         this.isRestoringVersion = true;

//         const restoredDocument = await restoreDocumentVersion({
//             documentId: this.generatedDocument.id,
//             versionId: versionId
//         });

//         this.generatedDocument = restoredDocument;
//         this.showToast('Success', 'Document restored to selected version', 'success');

//     } catch (error) {
//         console.error('Version restore error:', error);
//         this.showToast('Error', 'Failed to restore version: ' + error.body?.message, 'error');
//     } finally {
//         this.isRestoringVersion = false;
//     }
// }

// // Advanced Template Management
// async handleCreateCustomTemplate() {
//     if (!this.generatedDocument) {
//         this.showToast('Warning', 'Generate a document first to create template', 'warning');
//         return;
//     }

//     try {
//         this.isCreatingTemplate = true;

//         const templateData = {
//             name: this.templateName,
//             description: this.templateDescription,
//             category: this.templateCategory,
//             content: this.generatedDocument.content,
//             variables: this.extractTemplateVariables(this.generatedDocument.content),
//             aiPrompts: this.generatedDocument.aiPrompts,
//             complianceRules: this.generatedDocument.complianceRules
//         };

//         const newTemplate = await createDocumentTemplate(templateData);

//         this.availableTemplates.push({
//             label: newTemplate.name,
//             value: newTemplate.id,
//             description: newTemplate.description
//         });

//         this.showToast('Success', 'Custom template created successfully', 'success');
//         this.showCreateTemplateModal = false;

//     } catch (error) {
//         console.error('Template creation error:', error);
//         this.showToast('Error', 'Failed to create template: ' + error.body?.message, 'error');
//     } finally {
//         this.isCreatingTemplate = false;
//     }
// }

// extractTemplateVariables(content) {
//     const variableRegex = /\{\{([^}]+)\}\}/g;
//     const variables = [];
//     let match;

//     while ((match = variableRegex.exec(content)) !== null) {
//         const variableName = match[1].trim();
//         if (!variables.some(v => v.name === variableName)) {
//             variables.push({
//                 name: variableName,
//                 type: this.inferVariableType(variableName),
//                 required: true,
//                 defaultValue: ''
//             });
//         }
//     }

//     return variables;
// }

// inferVariableType(variableName) {
//     const name = variableName.toLowerCase();
//     if (name.includes('date')) return 'date';
//     if (name.includes('email')) return 'email';
//     if (name.includes('phone')) return 'phone';
//     if (name.includes('number') || name.includes('amount')) return 'number';
//     return 'text';
// }

// // Cleanup and Resource Management
// disconnectedCallback() {
//     if (this.websocket) {
//         this.websocket.close();
//         this.websocket = null;
//     }

//     if (this.performanceUpdateInterval) {
//         clearInterval(this.performanceUpdateInterval);
//     }

//     if (this.autoSaveInterval) {
//         clearInterval(this.autoSaveInterval);
//     }

//     this.removeEventListeners();
// }

// removeEventListeners() {
//     if (this.keyboardHandler) {
//         document.removeEventListener('keydown', this.keyboardHandler);
//     }
//     if (this.resizeHandler) {
//         window.removeEventListener('resize', this.resizeHandler);
//     }
// }

// // Utility Methods
// debounce(func, wait) {
//     let timeout;
//     return function executedFunction(...args) {
//         const later = () => {
//             clearTimeout(timeout);
//             func(...args);
//         };
//         clearTimeout(timeout);
//         timeout = setTimeout(later, wait);
//     };
// }

// formatBytes(bytes, decimals = 2) {
//     if (bytes === 0) return '0 Bytes';
//     const k = 1024;
//     const dm = decimals < 0 ? 0 : decimals;
//     const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
//     const i = Math.floor(Math.log(bytes) / Math.log(k));
//     return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
// }

// formatDuration(seconds) {
//     const hours = Math.floor(seconds / 3600);
//     const minutes = Math.floor((seconds % 3600) / 60);
//     const secs = seconds % 60;

//     if (hours > 0) return `${hours}h ${minutes}m ${secs}s`;
//     if (minutes > 0) return `${minutes}m ${secs}s`;
//     return `${secs}s`;
// }

// showToast(title, message, variant) {
//     const evt = new ShowToastEvent({
//         title: title,
//         message: message,
//         variant: variant,
//         mode: variant === 'error' ? 'sticky' : 'dismissable'
//     });
//     this.dispatchEvent(evt);
// }

//}





//version4
// import { LightningElement, track, wire, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getAvailableAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
// import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';
// import generateContextAwareDocument from '@salesforce/apex/ContextAwareDocumentEngine.generateContextAwareDocument';
// import askContextualQuestion from '@salesforce/apex/ContextAwareDocumentEngine.askContextualQuestion';
// import getAvailableFolders from '@salesforce/apex/DocumentFolderManager.getAvailableFolders';
// import getDocumentTemplates from '@salesforce/apex/DocumentTemplateManager.getDocumentTemplates';

// export default class ContextAwareDocumentGenerator extends LightningElement {
    
//     // AI Model Management
//     @track aiModels = [];
//     @track selectedAIModel;
//     @track selectedAIModelInfo;

//     // Folder and Context Analysis
//     @track availableFolders = [];
//     @track selectedFolder;
//     @track folderAnalysis;
//     @track isAnalyzing = false;
//     @track analysisStatus = '';
//     @track analysisProgress = 0;
//     @track analysisSteps = [];
//     @track currentAnalysisStep = '';
//     @track showAnalysisProgressModal = false;

//     // Template and Generation
//     @track availableTemplates = [];
//     @track selectedTemplate;
//     @track selectedGenerationType = 'context-aware';
//     @track contextIntegrationLevel = 8;
//     @track creativityLevel = 5;
//     @track selectedOutputFormat = 'html';

//     // Document Generation
//     @track isGenerating = false;
//     @track generationStatus = '';
//     @track generationProgress = 0;
//     @track showGenerationProgress = false;
//     @track generatedDocument;

//     // Context Q&A (Anara-style)
//     @track contextualQuestion = '';
//     @track contextualAnswer = '';
//     @track isProcessingQuestion = false;

//     // UI State Management
//     @track showTemplateSelection = false;
//     @track showDocumentEditor = false;
//     @track showAIModelConfigModal = false;
//     @track modelParametersJSON = '';

//     // Computed Properties
//     get analyzeButtonDisabled() {
//         return !this.selectedAIModel || !this.selectedFolder || this.isAnalyzing;
//     }

//     get generateButtonDisabled() {
//         return !this.folderAnalysis || !this.selectedTemplate || this.isGenerating;
//     }

//     get entityCount() {
//         return this.folderAnalysis?.entityFrequency ? Object.keys(this.folderAnalysis.entityFrequency).length : 0;
//     }

//     get hasDocumentRelationships() {
//         return this.folderAnalysis?.documentRelationships && 
//                Object.keys(this.folderAnalysis.documentRelationships).length > 0;
//     }

//     get documentRelationshipsList() {
//         if (!this.hasDocumentRelationships) return [];
        
//         return Object.keys(this.folderAnalysis.documentRelationships).map(sourceId => {
//             const sourceDoc = this.folderAnalysis.documents.find(doc => doc.documentId === sourceId);
//             return {
//                 sourceId: sourceId,
//                 sourceName: sourceDoc?.title || 'Unknown Document',
//                 relatedDocs: this.folderAnalysis.documentRelationships[sourceId]
//             };
//         });
//     }

//     get topEntities() {
//         if (!this.folderAnalysis?.entityFrequency) return [];
        
//         return Object.keys(this.folderAnalysis.entityFrequency)
//             .map(entity => ({
//                 name: entity,
//                 frequency: this.folderAnalysis.entityFrequency[entity]
//             }))
//             .sort((a, b) => b.frequency - a.frequency)
//             .slice(0, 10);
//     }

//     get formattedThemes() {
//         return this.folderAnalysis?.commonThemes?.join(', ') || '';
//     }

//     get contextQuality() {
//         if (!this.folderAnalysis) return '';
        
//         const docCount = this.folderAnalysis.documents.length;
//         const themeCount = this.folderAnalysis.commonThemes.length;
        
//         if (docCount >= 5 && themeCount >= 3) return 'Excellent';
//         if (docCount >= 3 && themeCount >= 2) return 'Good';
//         if (docCount >= 1 && themeCount >= 1) return 'Fair';
//         return 'Limited';
//     }

//     get formattedGenerationTime() {
//         return this.generatedDocument?.generatedDate ? 
//             new Date(this.generatedDocument.generatedDate).toLocaleString() : '';
//     }

//     get usedSourceDocuments() {
//         return this.generatedDocument?.sourceDocuments || [];
//     }

//     // Initialization
//     connectedCallback() {
//         this.initializeComponent();
//         this.setupAnalysisSteps();
//         this.loadGenerationTypes();
//         this.loadOutputFormats();
//     }

//     async initializeComponent() {
//         try {
//             await Promise.all([
//                 this.loadAIModels(),
//                 this.loadAvailableFolders(),
//                 this.loadDocumentTemplates()
//             ]);
//         } catch (error) {
//             this.showErrorToast('Initialization failed: ' + error.message);
//         }
//     }

//     setupAnalysisSteps() {
//         this.analysisSteps = [
//             {
//                 id: 'step1',
//                 label: 'Retrieving documents from folder',
//                 iconName: 'utility:file',
//                 cssClass: 'step-pending'
//             },
//             {
//                 id: 'step2',
//                 label: 'Analyzing document content with AI',
//                 iconName: 'utility:AI',
//                 cssClass: 'step-pending'
//             },
//             {
//                 id: 'step3',
//                 label: 'Extracting entities and themes',
//                 iconName: 'utility:flow',
//                 cssClass: 'step-pending'
//             },
//             {
//                 id: 'step4',
//                 label: 'Building document relationships',
//                 iconName: 'utility:connected_apps',
//                 cssClass: 'step-pending'
//             },
//             {
//                 id: 'step5',
//                 label: 'Generating contextual insights',
//                 iconName: 'utility:insights',
//                 cssClass: 'step-pending'
//             }
//         ];
//     }

//     loadGenerationTypes() {
//         this.generationTypes = [
//             { label: 'Context-Aware Generation (Anara-style)', value: 'context-aware' },
//             { label: 'Template-Based with Context', value: 'template-context' },
//             { label: 'AI-Driven Creative', value: 'ai-creative' },
//             { label: 'Structured Professional', value: 'structured-professional' },
//             { label: 'Research-Based Synthesis', value: 'research-synthesis' }
//         ];
//     }

//     loadOutputFormats() {
//         this.outputFormats = [
//             { label: 'HTML Document', value: 'html' },
//             { label: 'Microsoft Word', value: 'docx' },
//             { label: 'PDF Document', value: 'pdf' },
//             { label: 'Plain Text', value: 'txt' },
//             { label: 'Markdown', value: 'md' }
//         ];
//     }

//     // Wire Methods
//     @wire(getAvailableAIModels)
//     wiredAIModels({ error, data }) {
//         if (data) {
//             this.aiModels = data.map(model => ({
//                 label: `${model.modelName} (${model.provider})`,
//                 value: model.modelIdentifier,
//                 capabilities: model.capabilities,
//                 provider: model.provider,
//                 modelName: model.modelName
//             }));
//         } else if (error) {
//             this.showErrorToast('Failed to load AI models: ' + error.body.message);
//         }
//     }

//     async loadAIModels() {
//         try {
//             const models = await getAvailableAIModels();
//             this.aiModels = models.map(model => ({
//                 label: `${model.modelName} (${model.provider})`,
//                 value: model.modelIdentifier,
//                 capabilities: model.capabilities,
//                 provider: model.provider,
//                 modelName: model.modelName
//             }));
            
//             // Set default AI model (prefer Einstein models)
//             const einsteinModel = this.aiModels.find(model => model.provider === 'Salesforce');
//             if (einsteinModel) {
//                 this.selectedAIModel = einsteinModel.value;
//                 this.updateSelectedAIModelInfo();
//             }
//         } catch (error) {
//             this.showErrorToast('Failed to load AI models: ' + error.message);
//         }
//     }

//     async loadAvailableFolders() {
//         try {
//             const folders = await getAvailableFolders();
//             this.availableFolders = folders.map(folder => ({
//                 label: folder.name + ` (${folder.documentCount} documents)`,
//                 value: folder.id
//             }));
//         } catch (error) {
//             this.showErrorToast('Failed to load folders: ' + error.message);
//         }
//     }

//     async loadDocumentTemplates() {
//         try {
//             const templates = await getDocumentTemplates();
//             this.availableTemplates = templates.map(template => ({
//                 label: template.name,
//                 value: template.id,
//                 description: template.description
//             }));
//         } catch (error) {
//             this.showErrorToast('Failed to load templates: ' + error.message);
//         }
//     }

//     // Event Handlers
//     handleAIModelChange(event) {
//         this.selectedAIModel = event.detail.value;
//         this.updateSelectedAIModelInfo();
        
//         // Reset context analysis when AI model changes
//         this.resetContextAnalysis();
//     }

//     updateSelectedAIModelInfo() {
//         this.selectedAIModelInfo = this.aiModels.find(model => model.value === this.selectedAIModel);
//     }

//     handleFolderChange(event) {
//         this.selectedFolder = event.detail.value;
//         this.resetContextAnalysis();
//     }

//     handleTemplateChange(event) {
//         this.selectedTemplate = event.detail.value;
//     }

//     handleGenerationTypeChange(event) {
//         this.selectedGenerationType = event.detail.value;
//     }

//     handleContextLevelChange(event) {
//         this.contextIntegrationLevel = event.detail.value;
//     }

//     handleCreativityLevelChange(event) {
//         this.creativityLevel = event.detail.value;
//     }

//     handleOutputFormatChange(event) {
//         this.selectedOutputFormat = event.detail.value;
//     }

//     handleQuestionChange(event) {
//         this.contextualQuestion = event.detail.value;
//     }

//     // Main Action Handlers
//     async handleAnalyzeContext() {
//         if (!this.selectedAIModel || !this.selectedFolder) {
//             this.showErrorToast('Please select both AI model and folder');
//             return;
//         }

//         this.isAnalyzing = true;
//         this.showAnalysisProgressModal = true;
//         this.analysisProgress = 0;
//         this.resetAnalysisSteps();

//         try {
//             // Step 1: Retrieve documents
//             this.updateAnalysisStep(0, 'Retrieving documents from folder...', 20);
//             await this.delay(1000);

//             // Step 2: AI Analysis
//             this.updateAnalysisStep(1, 'Analyzing documents with ' + this.selectedAIModelInfo.modelName + '...', 40);
//             await this.delay(1500);

//             // Step 3: Extract entities and themes
//             this.updateAnalysisStep(2, 'Extracting entities and themes...', 60);
//             await this.delay(1000);

//             // Step 4: Build relationships
//             this.updateAnalysisStep(3, 'Building document relationships...', 80);
//             await this.delay(1000);

//             // Step 5: Generate insights
//             this.updateAnalysisStep(4, 'Generating contextual insights...', 95);
            
//             // Actual API call
//             const analysis = await analyzeFolderContext({
//                 folderId: this.selectedFolder,
//                 selectedAIModel: this.selectedAIModel
//             });

//             this.folderAnalysis = analysis;
//             this.showTemplateSelection = true;
//             this.analysisProgress = 100;
//             this.currentAnalysisStep = 'Analysis complete!';
            
//             await this.delay(1000);
//             this.showAnalysisProgressModal = false;
            
//             this.showSuccessToast(
//                 `Successfully analyzed ${analysis.documents.length} documents with ${analysis.commonThemes.length} common themes identified`
//             );

//         } catch (error) {
//             this.showErrorToast('Context analysis failed: ' + error.message);
//             this.showAnalysisProgressModal = false;
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     async handleAskContextualQuestion() {
//         if (!this.contextualQuestion || !this.folderAnalysis) {
//             this.showErrorToast('Please enter a question and ensure context is analyzed');
//             return;
//         }

//         this.isProcessingQuestion = true;
//         this.contextualAnswer = '';

//         try {
//             const response = await askContextualQuestion({
//                 folderId: this.selectedFolder,
//                 question: this.contextualQuestion,
//                 selectedAIModel: this.selectedAIModel
//             });

//             // Parse the AI response
//             let parsedResponse;
//             try {
//                 parsedResponse = JSON.parse(response);
//                 this.contextualAnswer = parsedResponse.answer || response;
//             } catch (parseError) {
//                 this.contextualAnswer = response; // Use raw response if parsing fails
//             }

//             this.showSuccessToast('Question processed successfully');

//         } catch (error) {
//             this.showErrorToast('Question processing failed: ' + error.message);
//         } finally {
//             this.isProcessingQuestion = false;
//         }
//     }

//     async handleGenerateDocument() {
//         if (!this.folderAnalysis || !this.selectedTemplate) {
//             this.showErrorToast('Please complete context analysis and select a template');
//             return;
//         }

//         this.isGenerating = true;
//         this.showGenerationProgress = true;
//         this.generationProgress = 0;
//         this.generationStatus = 'Initializing document generation...';

//         try {
//             // Simulate generation progress
//             const progressSteps = [
//                 { progress: 20, status: 'Preparing context and template...' },
//                 { progress: 40, status: 'Processing with ' + this.selectedAIModelInfo.modelName + '...' },
//                 { progress: 60, status: 'Generating content sections...' },
//                 { progress: 80, status: 'Applying formatting and structure...' },
//                 { progress: 95, status: 'Finalizing document...' }
//             ];

//             for (const step of progressSteps) {
//                 this.generationProgress = step.progress;
//                 this.generationStatus = step.status;
//                 await this.delay(1500);
//             }

//             // Prepare generation parameters
//             const generationParameters = {
//                 contextIntegrationLevel: this.contextIntegrationLevel,
//                 creativityLevel: this.creativityLevel,
//                 outputFormat: this.selectedOutputFormat,
//                 generationType: this.selectedGenerationType
//             };

//             // Actual API call
//             const documentId = await generateContextAwareDocument({
//                 folderId: this.selectedFolder,
//                 templateId: this.selectedTemplate,
//                 selectedAIModel: this.selectedAIModel,
//                 generationParameters: generationParameters
//             });

//             // Simulate document processing and create display object
//             this.generatedDocument = {
//                 id: documentId,
//                 name: 'Context-Aware Generated Document',
//                 content: await this.loadGeneratedDocumentContent(documentId),
//                 wordCount: 1250, // This would be calculated from actual content
//                 qualityScore: this.calculateQualityScore(),
//                 generatedDate: new Date().toISOString(),
//                 contextRelevance: Math.floor(85 + Math.random() * 10),
//                 coherence: Math.floor(88 + Math.random() * 8),
//                 factualAccuracy: Math.floor(90 + Math.random() * 8),
//                 completeness: Math.floor(82 + Math.random() * 12),
//                 citations: this.generateCitations(),
//                 sourceDocuments: this.generateSourceDocumentsSummary(),
//                 aiInsights: this.generateAIInsights()
//             };

//             this.generationProgress = 100;
//             this.generationStatus = 'Document generated successfully!';
            
//             await this.delay(1000);
//             this.showGenerationProgress = false;
            
//             this.showSuccessToast(
//                 'Document generated successfully with context from ' + this.folderAnalysis.documents.length + ' source documents'
//             );

//         } catch (error) {
//             this.showErrorToast('Document generation failed: ' + error.message);
//             this.showGenerationProgress = false;
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     // Template Suggestion Handler
//     handleTemplateSuggestionClick(event) {
//         const suggestionText = event.target.dataset.suggestion;
        
//         // Find matching template or create suggestion
//         const matchingTemplate = this.availableTemplates.find(template => 
//             template.label.toLowerCase().includes(suggestionText.toLowerCase())
//         );
        
//         if (matchingTemplate) {
//             this.selectedTemplate = matchingTemplate.value;
//             this.showSuccessToast('Template selected: ' + matchingTemplate.label);
//         } else {
//             this.showInfoToast('Template suggestion noted. Consider creating: ' + suggestionText);
//         }
//     }

//     // Document Action Handlers
//     handleDownloadPDF() {
//         // Implement PDF download functionality
//         this.showInfoToast('PDF download functionality will be implemented');
//     }

//     handleDownloadWord() {
//         // Implement Word download functionality
//         this.showInfoToast('Word download functionality will be implemented');
//     }

//     handleEditDocument() {
//         this.showDocumentEditor = !this.showDocumentEditor;
//     }

//     handleRequestSignature() {
//         // Navigate to e-signature component
//         this.showInfoToast('Redirecting to e-signature workflow...');
//     }

//     handleShareDocument() {
//         // Implement sharing functionality
//         this.showInfoToast('Share functionality will be implemented');
//     }

//     handleDocumentEdit(event) {
//         this.generatedDocument.content = event.target.value;
//     }

//     // Citation and Source Handlers
//     handleViewCitationSource(event) {
//         const sourceId = event.target.dataset.sourceId;
//         // Navigate to source document
//         this.showInfoToast('Opening source document: ' + sourceId);
//     }

//     handleCopyCitation(event) {
//         const citationText = event.target.dataset.citationText;
//         navigator.clipboard.writeText(citationText).then(() => {
//             this.showSuccessToast('Citation copied to clipboard');
//         });
//     }

//     // Regeneration Handlers
//     handleRegenerateWithDifferentModel() {
//         // Reset AI model selection and regenerate
//         this.selectedAIModel = '';
//         this.showInfoToast('Please select a different AI model and regenerate');
//     }

//     handleRegenerateWithMoreContext() {
//         // Increase context integration level and regenerate
//         this.contextIntegrationLevel = Math.min(10, this.contextIntegrationLevel + 2);
//         this.handleGenerateDocument();
//     }

//     handleRefineWithInstructions() {
//         // Show custom instructions modal
//         this.showInfoToast('Custom refinement instructions will be implemented');
//     }

//     handleGenerateAlternativeVersion() {
//         // Generate alternative with different creativity level
//         const originalCreativity = this.creativityLevel;
//         this.creativityLevel = originalCreativity > 5 ? 3 : 8;
//         this.handleGenerateDocument();
//         this.creativityLevel = originalCreativity;
//     }

//     // AI Model Configuration (Admin)
//     handleConfigureAIModels() {
//         this.showAIModelConfigModal = true;
//     }

//     closeAIModelConfigModal() {
//         this.showAIModelConfigModal = false;
//         this.modelParametersJSON = '';
//     }

//     handleModelParametersChange(event) {
//         this.modelParametersJSON = event.target.value;
//     }

//     handleAIModelConfigSuccess() {
//         this.showSuccessToast('AI Model configuration saved successfully');
//         this.closeAIModelConfigModal();
//         this.loadAIModels(); // Reload models
//     }

//     saveAIModelConfiguration() {
//         // Validate JSON parameters
//         try {
//             if (this.modelParametersJSON) {
//                 JSON.parse(this.modelParametersJSON);
//             }
//             // Save configuration logic would go here
//             this.showSuccessToast('Configuration saved successfully');
//             this.closeAIModelConfigModal();
//         } catch (error) {
//             this.showErrorToast('Invalid JSON in model parameters');
//         }
//     }

//     // Utility Methods
//     updateAnalysisStep(stepIndex, statusMessage, progress) {
//         this.currentAnalysisStep = statusMessage;
//         this.analysisProgress = progress;
        
//         // Update step status
//         for (let i = 0; i < this.analysisSteps.length; i++) {
//             if (i < stepIndex) {
//                 this.analysisSteps[i].cssClass = 'step-completed slds-text-color_success';
//                 this.analysisSteps[i].iconName = 'utility:success';
//             } else if (i === stepIndex) {
//                 this.analysisSteps[i].cssClass = 'step-active slds-text-color_brand';
//                 this.analysisSteps[i].iconName = 'utility:spinner';
//             } else {
//                 this.analysisSteps[i].cssClass = 'step-pending slds-text-color_weak';
//                 this.analysisSteps[i].iconName = 'utility:clock';
//             }
//         }
        
//         // Force reactivity
//         this.analysisSteps = [...this.analysisSteps];
//     }

//     resetAnalysisSteps() {
//         this.analysisSteps.forEach(step => {
//             step.cssClass = 'step-pending';
//             step.iconName = 'utility:clock';
//         });
//     }

//     resetContextAnalysis() {
//         this.folderAnalysis = null;
//         this.showTemplateSelection = false;
//         this.generatedDocument = null;
//         this.contextualAnswer = '';
//     }

//     delay(ms) {
//         return new Promise(resolve => setTimeout(resolve, ms));
//     }

//     calculateQualityScore() {
//         if (!this.folderAnalysis) return 0;
        
//         // Calculate quality based on various factors
//         const docCount = this.folderAnalysis.documents.length;
//         const themeCount = this.folderAnalysis.commonThemes.length;
//         const entityCount = this.entityCount;
        
//         let score = 60; // Base score
        
//         // Document count factor
//         if (docCount >= 5) score += 15;
//         else if (docCount >= 3) score += 10;
//         else if (docCount >= 1) score += 5;
        
//         // Theme diversity factor
//         if (themeCount >= 5) score += 10;
//         else if (themeCount >= 3) score += 7;
//         else if (themeCount >= 1) score += 3;
        
//         // Entity richness factor
//         if (entityCount >= 20) score += 10;
//         else if (entityCount >= 10) score += 7;
//         else if (entityCount >= 5) score += 3;
        
//         // Context integration level factor
//         score += Math.floor(this.contextIntegrationLevel / 2);
        
//         return Math.min(100, score);
//     }

//     generateCitations() {
//         if (!this.folderAnalysis?.documents) return [];
        
//         return this.folderAnalysis.documents.slice(0, 5).map((doc, index) => ({
//             id: doc.documentId,
//             number: index + 1,
//             sourceDocument: doc.title,
//             excerpt: this.generateExcerpt(doc.content),
//             sourceId: doc.documentId,
//             fullCitation: `${doc.title}. Retrieved from document ${doc.documentId}`
//         }));
//     }

//     generateExcerpt(content) {
//         if (!content) return 'No content available';
        
//         const sentences = content.split('.').filter(s => s.trim().length > 0);
//         if (sentences.length === 0) return content.substring(0, 100) + '...';
        
//         // Return first 2 sentences or up to 150 characters
//         const excerpt = sentences.slice(0, 2).join('. ') + '.';
//         return excerpt.length > 150 ? excerpt.substring(0, 147) + '...' : excerpt;
//     }

//     generateSourceDocumentsSummary() {
//         if (!this.folderAnalysis?.documents) return [];
        
//         return this.folderAnalysis.documents.map(doc => ({
//             id: doc.documentId,
//             name: doc.title,
//             usagePercentage: Math.floor(30 + Math.random() * 50) // Simulate usage percentage
//         }));
//     }

//     generateAIInsights() {
//         const insights = [];
        
//         if (this.folderAnalysis?.commonThemes?.length > 0) {
//             insights.push({
//                 id: 'theme-analysis',
//                 type: 'Theme Analysis',
//                 description: `Identified ${this.folderAnalysis.commonThemes.length} common themes across documents`,
//                 confidence: Math.floor(85 + Math.random() * 10)
//             });
//         }
        
//         if (this.entityCount > 0) {
//             insights.push({
//                 id: 'entity-extraction',
//                 type: 'Entity Recognition',
//                 description: `Extracted ${this.entityCount} key entities with relationship mapping`,
//                 confidence: Math.floor(80 + Math.random() * 15)
//             });
//         }
        
//         if (this.hasDocumentRelationships) {
//             insights.push({
//                 id: 'document-relationships',
//                 type: 'Document Correlation',
//                 description: 'Found strong thematic relationships between multiple documents',
//                 confidence: Math.floor(75 + Math.random() * 20)
//             });
//         }
        
//         insights.push({
//             id: 'context-quality',
//             type: 'Context Quality Assessment',
//             description: `Overall context quality rated as: ${this.contextQuality}`,
//             confidence: Math.floor(90 + Math.random() * 5)
//         });
        
//         return insights;
//     }

//     async loadGeneratedDocumentContent(documentId) {
//         // This would normally load from the server
//         // For now, return sample content based on context
//         const themes = this.folderAnalysis?.commonThemes?.join(', ') || 'general topics';
        
//         return `
//             <h1>Context-Aware Generated Document</h1>
//             <p>This document has been generated using advanced AI analysis of your document collection, 
//             incorporating insights from ${this.folderAnalysis?.documents?.length || 0} source documents.</p>
            
//             <h2>Key Themes Identified</h2>
//             <p>Based on our analysis, the following themes were prominent: ${themes}.</p>
            
//             <h2>AI-Generated Content</h2>
//             <p>The content below has been synthesized from your documents using the 
//             ${this.selectedAIModelInfo?.modelName || 'selected AI model'} with a context integration level 
//             of ${this.contextIntegrationLevel}/10.</p>
            
//             <div class="generated-content">
//                 <p>This is where the actual AI-generated content would appear, incorporating context from 
//                 the analyzed documents while following the selected template structure.</p>
//             </div>
//         `;
//     }

//     // Toast Notification Helpers
//     showSuccessToast(message) {
//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Success',
//             message: message,
//             variant: 'success'
//         }));
//     }

//     showErrorToast(message) {
//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Error',
//             message: message,
//             variant: 'error'
//         }));
//     }

//     showInfoToast(message) {
//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Info',
//             message: message,
//             variant: 'info'
//         }));
//     }

//     showWarningToast(message) {
//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Warning',
//             message: message,
//             variant: 'warning'
//         }));
//     }

//     // Advanced Features (Future Implementation)
//     async handleBulkDocumentGeneration() {
//         this.showInfoToast('Bulk generation feature coming soon');
//     }

//     async handleScheduledGeneration() {
//         this.showInfoToast('Scheduled generation feature coming soon');
//     }

//     async handleAPIIntegration() {
//         this.showInfoToast('API integration setup coming soon');
//     }

//     // Context Analysis Export
//     async exportContextAnalysis() {
//         if (!this.folderAnalysis) {
//             this.showErrorToast('No context analysis available to export');
//             return;
//         }

//         try {
//             const exportData = {
//                 timestamp: new Date().toISOString(),
//                 aiModel: this.selectedAIModelInfo,
//                 folderAnalysis: this.folderAnalysis,
//                 generationSettings: {
//                     contextIntegrationLevel: this.contextIntegrationLevel,
//                     creativityLevel: this.creativityLevel,
//                     outputFormat: this.selectedOutputFormat
//                 }
//             };

//             const blob = new Blob([JSON.stringify(exportData, null, 2)], { 
//                 type: 'application/json' 
//             });
//             const url = window.URL.createObjectURL(blob);
//             const a = document.createElement('a');
//             a.href = url;
//             a.download = `context-analysis-${new Date().toISOString().split('T')[0]}.json`;
//             a.click();
//             window.URL.revokeObjectURL(url);

//             this.showSuccessToast('Context analysis exported successfully');

//         } catch (error) {
//             this.showErrorToast('Export failed: ' + error.message);
//         }
//     }

//     // Performance Analytics
//     trackGenerationMetrics() {
//         const metrics = {
//             documentCount: this.folderAnalysis?.documents?.length || 0,
//             themesIdentified: this.folderAnalysis?.commonThemes?.length || 0,
//             entitiesExtracted: this.entityCount,
//             aiModelUsed: this.selectedAIModelInfo?.modelName,
//             contextIntegrationLevel: this.contextIntegrationLevel,
//             qualityScore: this.generatedDocument?.qualityScore,
//             generationTime: new Date().toISOString()
//         };

//         // Send metrics to analytics service
//         console.log('Generation Metrics:', metrics);
//     }
// }


import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getAvailableAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';
import generateContextAwareDocument from '@salesforce/apex/ContextAwareDocumentEngine.generateContextAwareDocument';
import askContextualQuestion from '@salesforce/apex/ContextAwareDocumentEngine.askContextualQuestion';

export default class ContextAwareDocumentGenerator extends LightningElement {
    @api recordId;
    @api folderId;

    // AI Model Selection
    @track availableAIModels = [];
    @track selectedAIModel = '';
    @track showAdvancedOptions = false;

    // Context Analysis
    @track folderAnalysis = null;
    @track isAnalyzing = false;
    @track analysisComplete = false;

    // Document Generation
    @track isGenerating = false;
    @track generationComplete = false;
    @track generatedDocument = null;
    @track selectedTemplate = '';
    @track customPrompt = '';

    // Q&A Feature
    @track showQASection = false;
    @track questionText = '';
    @track qaHistory = [];
    @track isProcessingQuestion = false;

    // UI State
    @track currentStep = 1;
    @track maxSteps = 5;
    @track showContextDetails = false;
    @track showDocumentPreview = false;

    // Progress Tracking
    @track progressSteps = [
        { number: 1, label: 'Select AI Model', status: 'current', description: 'Choose your preferred AI model' },
        { number: 2, label: 'Analyze Context', status: 'pending', description: 'Analyze folder documents for context' },
        { number: 3, label: 'Review Insights', status: 'pending', description: 'Review contextual insights and themes' },
        { number: 4, label: 'Generate Document', status: 'pending', description: 'Generate context-aware document' },
        { number: 5, label: 'Review & Export', status: 'pending', description: 'Review and export final document' }
    ];

    connectedCallback() {
        this.loadAIModels();
        if (this.folderId) {
            this.updateProgressStep(1, 'completed');
            this.currentStep = 2;
        }
    }

    @wire(getAvailableAIModels)
    wiredAIModels({ error, data }) {
        if (data) {
            this.availableAIModels = data.map(model => ({
                label: `${model.modelName} (${model.provider})`,
                value: model.modelId,
                description: model.description,
                capabilities: model.capabilities,
                provider: model.provider
            }));

            // Auto-select first Einstein model if available
            const einsteinModel = this.availableAIModels.find(model => model.value.startsWith('einstein_'));
            if (einsteinModel && !this.selectedAIModel) {
                this.selectedAIModel = einsteinModel.value;
            }
        } else if (error) {
            this.showToast('Error', 'Failed to load AI models: ' + error.body.message, 'error');
        }
    }

    // Event Handlers
    handleAIModelChange(event) {
        this.selectedAIModel = event.detail.value;
        this.showAdvancedOptions = !!this.selectedAIModel;

        // Reset analysis if model changes
        if (this.folderAnalysis) {
            this.folderAnalysis = null;
            this.analysisComplete = false;
            this.updateProgressStep(2, 'pending');
        }
    }

    async handleAnalyzeContext() {
        if (!this.selectedAIModel) {
            this.showToast('Warning', 'Please select an AI model first', 'warning');
            return;
        }

        if (!this.folderId) {
            this.showToast('Warning', 'No folder selected for analysis', 'warning');
            return;
        }

        this.isAnalyzing = true;
        this.updateProgressStep(2, 'active');

        try {
            const result = await analyzeFolderContext({
                folderId: this.folderId,
                selectedAIModel: this.selectedAIModel
            });

            this.folderAnalysis = result;
            this.analysisComplete = true;
            this.updateProgressStep(2, 'completed');
            this.updateProgressStep(3, 'current');
            this.currentStep = 3;
            this.showContextDetails = true;

            this.showToast('Success', 'Context analysis completed successfully', 'success');
        } catch (error) {
            this.updateProgressStep(2, 'error');
            this.showToast('Error', 'Context analysis failed: ' + error.body.message, 'error');
        } finally {
            this.isAnalyzing = false;
        }
    }

    handleTemplateSelection(event) {
        this.selectedTemplate = event.target.dataset.template;
    }

    handleCustomPromptChange(event) {
        this.customPrompt = event.target.value;
    }

    async handleGenerateDocument() {
        if (!this.folderAnalysis) {
            this.showToast('Warning', 'Please analyze context first', 'warning');
            return;
        }

        if (!this.selectedTemplate && !this.customPrompt) {
            this.showToast('Warning', 'Please select a template or provide custom prompt', 'warning');
            return;
        }

        this.isGenerating = true;
        this.updateProgressStep(4, 'active');

        try {
            const result = await generateContextAwareDocument({
                folderAnalysis: this.folderAnalysis,
                selectedTemplate: this.selectedTemplate,
                customPrompt: this.customPrompt,
                selectedAIModel: this.selectedAIModel
            });

            this.generatedDocument = result;
            this.generationComplete = true;
            this.updateProgressStep(4, 'completed');
            this.updateProgressStep(5, 'current');
            this.currentStep = 5;
            this.showDocumentPreview = true;

            this.showToast('Success', 'Document generated successfully', 'success');
        } catch (error) {
            this.updateProgressStep(4, 'error');
            this.showToast('Error', 'Document generation failed: ' + error.body.message, 'error');
        } finally {
            this.isGenerating = false;
        }
    }

    // Q&A Functionality
    handleShowQA() {
        this.showQASection = !this.showQASection;
    }

    handleQuestionChange(event) {
        this.questionText = event.target.value;
    }

    async handleAskQuestion() {
        if (!this.questionText.trim()) {
            this.showToast('Warning', 'Please enter a question', 'warning');
            return;
        }

        if (!this.folderAnalysis) {
            this.showToast('Warning', 'Please analyze context first', 'warning');
            return;
        }

        this.isProcessingQuestion = true;

        try {
            const result = await askContextualQuestion({
                question: this.questionText,
                folderAnalysis: this.folderAnalysis,
                selectedAIModel: this.selectedAIModel
            });

            // Add to Q&A history
            this.qaHistory = [
                ...this.qaHistory,
                {
                    id: Date.now(),
                    question: this.questionText,
                    answer: result.answer,
                    sources: result.sources,
                    confidence: result.confidence,
                    timestamp: new Date().toLocaleString()
                }
            ];

            this.questionText = '';
            this.showToast('Success', 'Question answered successfully', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to process question: ' + error.body.message, 'error');
        } finally {
            this.isProcessingQuestion = false;
        }
    }

    // Navigation
    handlePrevious() {
        if (this.currentStep > 1) {
            this.currentStep--;
            this.updateProgressStep(this.currentStep, 'current');
        }
    }

    handleNext() {
        if (this.currentStep < this.maxSteps) {
            this.currentStep++;
            this.updateProgressStep(this.currentStep, 'current');
        }
    }

    // Utility Methods
    updateProgressStep(stepNumber, status) {
        this.progressSteps = this.progressSteps.map(step => {
            if (step.number === stepNumber) {
                return { ...step, status };
            } else if (step.number < stepNumber && status === 'current') {
                return { ...step, status: 'completed' };
            }
            return step;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Getters for UI logic
    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }
    get isStep4() { return this.currentStep === 4; }
    get isStep5() { return this.currentStep === 5; }

    get showPreviousButton() { return this.currentStep > 1; }
    get showNextButton() { return this.currentStep < this.maxSteps && this.canProceedToNext; }

    get canProceedToNext() {
        switch (this.currentStep) {
            case 1: return !!this.selectedAIModel;
            case 2: return this.analysisComplete;
            case 3: return this.analysisComplete;
            case 4: return this.generationComplete;
            default: return false;
        }
    }

    get selectedModelInfo() {
        return this.availableAIModels.find(model => model.value === this.selectedAIModel);
    }

    get contextQualityClass() {
        if (!this.folderAnalysis) return '';
        const score = this.folderAnalysis.qualityScore;
        if (score >= 80) return 'context-quality-excellent';
        if (score >= 60) return 'context-quality-good';
        if (score >= 40) return 'context-quality-fair';
        return 'context-quality-limited';
    }

    get contextQualityLabel() {
        if (!this.folderAnalysis) return 'Not Analyzed';
        const score = this.folderAnalysis.qualityScore;
        if (score >= 80) return 'Excellent Context';
        if (score >= 60) return 'Good Context';
        if (score >= 40) return 'Fair Context';
        return 'Limited Context';
    }

    get templateSuggestions() {
        return this.folderAnalysis?.templateSuggestions || [];
    }

    get documentMetrics() {
        if (!this.folderAnalysis) return [];
        return [
            {
                label: 'Documents Analyzed',
                value: this.folderAnalysis.documents.length,
                icon: 'utility:file'
            },
            {
                label: 'Common Themes',
                value: this.folderAnalysis.commonThemes.length,
                icon: 'utility:topic'
            },
            {
                label: 'Entities Extracted',
                value: Object.keys(this.folderAnalysis.entityFrequency).length,
                icon: 'utility:knowledge_base'
            },
            {
                label: 'Document Relationships',
                value: Object.values(this.folderAnalysis.documentRelationships).flat().length,
                icon: 'utility:connected_apps'
            },
            {
                label: 'Quality Score',
                value: this.folderAnalysis.qualityScore + '/100',
                icon: 'utility:rating'
            }
        ];
    }

    get entityFrequency() {
        if (!this.folderAnalysis?.entityFrequency) return [];
        const totalEntities = Object.values(this.folderAnalysis.entityFrequency).reduce(
            (sum, count) => sum + count,
            0
        );
        return Object.entries(this.folderAnalysis.entityFrequency)
            .sort(([, a], [, b]) => b - a)
            .slice(0, 10)
            .map(([name, count]) => ({
                name,
                count,
                percentage: Math.round((count / totalEntities) * 100)
            }));
    }

    get contextualSummary() {
        return this.folderAnalysis?.contextSummary || 'No context analysis available';
    }

    get hasQAHistory() {
        return this.qaHistory.length > 0;
    }

    get documentCount() {
        return this.folderAnalysis?.documents?.length || 0;
    }

    get isContextRich() {
        return this.folderAnalysis?.qualityScore >= 70;
    }

    get aiModelCapabilities() {
        const model = this.selectedModelInfo;
        if (!model) return [];
        return model.capabilities.split(',').map(cap => cap.trim());
    }
    get toggleContextDetailsLabel() {
    return this.showContextDetails ? 'Hide Details' : 'Show Details';
}

get exportFormatOptions() {
    return [
        { label: 'PDF Document', value: 'pdf', description: 'Portable Document Format' },
        { label: 'Microsoft Word', value: 'docx', description: 'Word Document' },
        { label: 'Rich Text Format', value: 'rtf', description: 'Rich Text Format' },
        { label: 'Plain Text', value: 'txt', description: 'Plain Text File' },
        { label: 'HTML Document', value: 'html', description: 'Web Document' }
    ];
}

// ============================
// Event Handlers for Step 5
// ============================
handleTogglePreview() {
    this.showDocumentPreview = !this.showDocumentPreview;
}

handleEditDocument() {
    this.showDocumentEditor = true;
}

handleExportFormatChange(event) {
    this.selectedExportFormat = event.detail.value;
}

handleDocumentTitleChange(event) {
    this.documentTitle = event.target.value;
}

async handleExportDocument() {
    if (!this.selectedExportFormat) {
        this.showToast('Warning', 'Please select an export format', 'warning');
        return;
    }

    this.isExporting = true;
    this.showLoadingOverlay = true;
    this.loadingMessage = `Preparing ${this.selectedExportFormat.toUpperCase()} export...`;

    try {
        const exportResult = await exportDocument({
            documentContent: this.generatedDocument.content,
            format: this.selectedExportFormat,
            title: this.documentTitle || 'Generated Document',
            metadata: {
                aiModel: this.selectedAIModel,
                generatedDate: new Date().toISOString(),
                sourcesUsed: this.generatedDocument.sources?.length || 0,
                contextQuality: this.folderAnalysis.qualityScore
            }
        });

        // Trigger download
        const downloadLink = document.createElement('a');
        downloadLink.href = exportResult.downloadUrl;
        downloadLink.download = exportResult.filename;
        downloadLink.click();

        this.showToast('Success', 'Document exported successfully', 'success');
    } catch (error) {
        this.showToast('Error', 'Export failed: ' + error.body.message, 'error');
    } finally {
        this.isExporting = false;
        this.showLoadingOverlay = false;
    }
}

async handleSaveToLibrary() {
    if (!this.generatedDocument) {
        this.showToast('Warning', 'No document to save', 'warning');
        return;
    }

    this.isSaving = true;
    this.showLoadingOverlay = true;
    this.loadingMessage = 'Saving document to library...';

    try {
        const saveResult = await saveDocumentToLibrary({
            documentContent: this.generatedDocument.content,
            title: this.documentTitle || 'Generated Document',
            folderId: this.folderId,
            metadata: {
                aiModel: this.selectedAIModel,
                generatedDate: new Date().toISOString(),
                sourcesUsed: this.generatedDocument.sources?.length || 0,
                contextQuality: this.folderAnalysis.qualityScore,
                wordCount: this.generatedDocument.wordCount,
                confidenceScore: this.generatedDocument.confidenceScore
            }
        });

        this.savedDocumentId = saveResult.documentId;
        this.showToast('Success', 'Document saved to library successfully', 'success');

        // Optionally navigate to the saved document
        this.navigateToSavedDocument(saveResult.documentId);

    } catch (error) {
        this.showToast('Error', 'Failed to save document: ' + error.body.message, 'error');
    } finally {
        this.isSaving = false;
        this.showLoadingOverlay = false;
    }
}

handleShareDocument() {
    if (!this.generatedDocument) {
        this.showToast('Warning', 'No document to share', 'warning');
        return;
    }
    this.showShareModal = true;
}

handleGenerateNew() {
    if (confirm('Are you sure you want to start over? This will clear your current document.')) {
        this.resetComponent();
    }
}

// ============================
// Context Details Toggle
// ============================
handleToggleContextDetails() {
    this.showContextDetails = !this.showContextDetails;
}

// ============================
// Advanced Methods
// ============================
async loadAIModels() {
    try {
        // Additional logic for loading AI models if needed
    } catch (error) {
        this.showToast('Error', 'Failed to load AI models: ' + error.message, 'error');
    }
}

resetComponent() {
    this.selectedAIModel = '';
    this.folderAnalysis = null;
    this.isAnalyzing = false;
    this.analysisComplete = false;
    this.isGenerating = false;
    this.generationComplete = false;
    this.generatedDocument = null;
    this.selectedTemplate = '';
    this.customPrompt = '';
    this.showQASection = false;
    this.questionText = '';
    this.qaHistory = [];
    this.isProcessingQuestion = false;
    this.currentStep = 1;
    this.showContextDetails = false;
    this.showDocumentPreview = false;
    this.selectedExportFormat = '';
    this.documentTitle = '';
    this.isExporting = false;
    this.isSaving = false;
    this.showLoadingOverlay = false;

    // Reset progress steps
    this.progressSteps = this.progressSteps.map((step, index) => ({
        ...step,
        status: index === 0 ? 'current' : 'pending'
    }));

    this.showToast('Info', 'Component reset successfully', 'info');
}

navigateToSavedDocument(documentId) {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: documentId,
            actionName: 'view'
        }
    });
}

delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

handleError(error, context) {
    console.error(`Error in ${context}:`, error);

    let errorMessage = 'An unexpected error occurred';
    if (error?.body?.message) {
        errorMessage = error.body.message;
    } else if (error?.message) {
        errorMessage = error.message;
    }

    this.showToast('Error', `${context}: ${errorMessage}`, 'error');
}

trackPerformance(operation, startTime) {
    const endTime = performance.now();
    const duration = endTime - startTime;
    console.log(`Performance: ${operation} took ${duration.toFixed(2)}ms`);
}

// ============================
// Advanced Getters
// ============================
get hasContextAnalysis() {
    return this.folderAnalysis && Object.keys(this.folderAnalysis).length > 0;
}

get isNextDisabled() {
    return !this.canProceedToNext || this.isAnalyzing || this.isGenerating;
}

get hasError() {
    return this.progressSteps.some(step => step.status === 'error');
}

get completionPercentage() {
    const completedSteps = this.progressSteps.filter(step => step.status === 'completed').length;
    return Math.round((completedSteps / this.maxSteps) * 100);
}

get documentStats() {
    if (!this.generatedDocument) return [];
    return [
        { label: 'Generation Time', value: this.generatedDocument.generationTime || 'N/A', icon: 'utility:clock' },
        { label: 'AI Model', value: this.selectedModelInfo?.modelName || 'Unknown', icon: 'utility:ai_model' },
        { label: 'Context Score', value: `${this.folderAnalysis?.qualityScore || 0}/100`, icon: 'utility:rating' }
    ];
}

get isHighQualityContext() {
    return this.folderAnalysis?.qualityScore >= 80;
}

get contextQualityMessage() {
    if (!this.folderAnalysis) return '';
    const score = this.folderAnalysis.qualityScore;

    if (score >= 80) return 'Excellent context quality - documents are highly related and comprehensive';
    if (score >= 60) return 'Good context quality - sufficient information for accurate generation';
    if (score >= 40) return 'Fair context quality - some gaps in information may affect accuracy';
    return 'Limited context quality - consider adding more relevant documents';
}

get suggestedActions() {
    const actions = [];
    if (!this.isContextRich) {
        actions.push({
            label: 'Add More Documents',
            action: 'addDocuments',
            description: 'Upload additional documents to improve context quality'
        });
    }
    if (this.generatedDocument && this.generatedDocument.confidenceScore < 70) {
        actions.push({
            label: 'Refine Prompt',
            action: 'refinePrompt',
            description: 'Adjust the generation prompt for better results'
        });
    }
    if (this.qaHistory.length === 0 && this.analysisComplete) {
        actions.push({
            label: 'Ask Questions',
            action: 'askQuestions',
            description: 'Use the Q&A feature to better understand your documents'
        });
    }
    return actions;
}

// ============================
// Suggested Actions
// ============================
handleSuggestedAction(event) {
    const action = event.target.dataset.action;
    switch (action) {
        case 'addDocuments':
            this.navigateToDocumentUpload();
            break;
        case 'refinePrompt':
            this.currentStep = 4;
            this.updateProgressStep(4, 'current');
            break;
        case 'askQuestions':
            this.showQASection = true;
            break;
        default:
            console.warn('Unknown suggested action:', action);
    }
}

navigateToDocumentUpload() {
    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: `/lightning/o/ContentDocument/home?folderId=${this.folderId}`
        }
    });
}

// ============================
// Keyboard Shortcuts
// ============================
handleKeyboardShortcuts(event) {
    if ((event.ctrlKey || event.metaKey) && event.key === 'Enter') {
        if (this.showNextButton && !this.isNextDisabled) {
            this.handleNext();
        }
    }
    if (event.key === 'Escape') {
        if (this.showPreviousButton) {
            this.handlePrevious();
        }
    }
}

// ============================
// Lifecycle Methods
// ============================
connectedCallback() {
    super.connectedCallback();
    document.addEventListener('keydown', this.handleKeyboardShortcuts.bind(this));
    this.initializeComponent();
}

disconnectedCallback() {
    document.removeEventListener('keydown', this.handleKeyboardShortcuts.bind(this));
}

async initializeComponent() {
    try {
        this.loadingMessage = 'Initializing component...';
        this.showLoadingOverlay = true;

        await this.loadAIModels();

        if (this.folderId) {
            this.updateProgressStep(1, 'completed');
            this.currentStep = 2;
        }

        this.showToast('Success', 'Component initialized successfully', 'success');
    } catch (error) {
        this.handleError(error, 'Component Initialization');
    } finally {
        this.showLoadingOverlay = false;
    }
}

// ============================
// Validation
// ============================
validateStep(stepNumber) {
    switch (stepNumber) {
        case 1: return this.selectedAIModel && this.selectedAIModel.length > 0;
        case 2: return this.analysisComplete && this.folderAnalysis;
        case 3: return this.analysisComplete;
        case 4: return this.selectedTemplate || (this.customPrompt && this.customPrompt.trim().length > 0);
        case 5: return this.generationComplete && this.generatedDocument;
        default: return false;
    }
}

validateAllSteps() {
    const errors = [];
    for (let i = 1; i <= this.maxSteps; i++) {
        if (!this.validateStep(i)) {
            errors.push(`Step ${i} validation failed`);
        }
    }

    if (errors.length > 0) {
        this.showToast('Validation Error', errors.join(', '), 'error');
        return false;
    }
    return true;
}

// ============================
// Analytics
// ============================
trackUserAction(action, metadata = {}) {
    const trackingData = {
        action,
        timestamp: new Date().toISOString(),
        step: this.currentStep,
        aiModel: this.selectedAIModel,
        folderId: this.folderId,
        ...metadata
    };
    console.log('User Action:', trackingData);
}

// ============================
// Refresh
// ============================
async handleRefresh() {
    this.trackUserAction('component_refresh');
    try {
        this.showLoadingOverlay = true;
        this.loadingMessage = 'Refreshing component...';

        await refreshApex(this.wiredAIModelsResult);

        if (this.analysisComplete) {
            await this.handleAnalyzeContext();
        }

        this.showToast('Success', 'Component refreshed successfully', 'success');
    } catch (error) {
        this.handleError(error, 'Component Refresh');
    } finally {
        this.showLoadingOverlay = false;
    }
}

}
