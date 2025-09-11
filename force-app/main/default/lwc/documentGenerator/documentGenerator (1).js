
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
import validateCompliance from '@salesforce/apex/ComplianceChecker.validateClause';
import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

export default class DocumentGenerator extends LightningElement {
    @track currentStep = 'step1';
    @track selectedRegion = '';
    @track selectedRole = '';
    @track selectedContractType = '';
    @track additionalClauses = '';
    @track selectedOutputFormat = 'PDF';
    @track includeSignature = false;
    @track signerEmail = '';
    @track generatedClause = '';
    @track complianceStatus = false;
    @track isGenerating = false;
    @track documentGenerated = false;
    @track signatureRequestId = '';

    // Options for dropdowns
    regionOptions = [
        { label: 'United States', value: 'US' },
        { label: 'European Union', value: 'EU' },
        { label: 'India', value: 'IN' }
    ];

    roleOptions = [
        { label: 'Manager', value: 'Manager' },
        { label: 'Employee', value: 'Employee' },
        { label: 'Developer', value: 'Developer' },
        { label: 'Admin', value: 'Admin' }
    ];

    contractTypeOptions = [
        { label: 'Employment Contract', value: 'Employment' },
        { label: 'Non-Disclosure Agreement', value: 'NDA' },
        { label: 'Service Level Agreement', value: 'SLA' }
    ];

    outputFormatOptions = [
        { label: 'PDF', value: 'PDF' },
        { label: 'Word Document', value: 'DOCX' },
        { label: 'HTML', value: 'HTML' }
    ];

    // Step navigation computed properties
    get isStep1() { return this.currentStep === 'step1'; }
    get isStep2() { return this.currentStep === 'step2'; }
    get isStep3() { return this.currentStep === 'step3'; }
    get isStep4() { return this.currentStep === 'step4'; }
    get isFirstStep() { return this.currentStep === 'step1'; }
    get isLastStep() { return this.currentStep === 'step4'; }

    // Compliance status computed properties
    get complianceStatusLabel() {
        return this.complianceStatus ? 'Compliant' : 'Non-Compliant';
    }
    get complianceVariant() {
        return this.complianceStatus ? 'success' : 'error';
    }

    // Event handlers for form inputs
    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
    }

    handleRoleChange(event) {
        this.selectedRole = event.detail.value;
    }

    handleContractTypeChange(event) {
        this.selectedContractType = event.detail.value;
    }

    handleAdditionalClausesChange(event) {
        this.additionalClauses = event.detail.value;
    }

    handleOutputFormatChange(event) {
        this.selectedOutputFormat = event.detail.value;
    }

    handleSignatureToggle(event) {
        this.includeSignature = event.detail.checked;
    }

    handleSignerEmailChange(event) {
        this.signerEmail = event.detail.value;
    }

    // Navigation handlers
    handleNext() {
        if (this.validateCurrentStep()) {
            const steps = ['step1', 'step2', 'step3', 'step4'];
            const currentIndex = steps.indexOf(this.currentStep);
            if (currentIndex < steps.length - 1) {
                this.currentStep = steps[currentIndex + 1];
            }
        }
    }

    handlePrevious() {
        const steps = ['step1', 'step2', 'step3', 'step4'];
        const currentIndex = steps.indexOf(this.currentStep);
        if (currentIndex > 0) {
            this.currentStep = steps[currentIndex - 1];
        }
    }

    // Document generation
    handleGenerateDocument() {
        this.isGenerating = true;
        
        generateClause({ 
            region: this.selectedRegion, 
            role: this.selectedRole, 
            contractType: this.selectedContractType 
        })
        .then(result => {
            this.generatedClause = result;
            if (this.additionalClauses) {
                this.generatedClause += '\n\nAdditional Terms:\n' + this.additionalClauses;
            }
            return this.validateDocumentCompliance();
        })
        .then(() => {
            this.documentGenerated = true;
            this.currentStep = 'step4';
            this.showToast('Success', 'Document generated successfully!', 'success');
        })
        .catch(error => {
            this.showToast('Error', 'Failed to generate document: ' + error.body?.message, 'error');
        })
        .finally(() => {
            this.isGenerating = false;
        });
    }

    // Compliance validation
    validateDocumentCompliance() {
        return validateCompliance({
            clauseText: this.generatedClause,
            region: this.selectedRegion,
            documentType: this.selectedContractType
        })
        .then(result => {
            this.complianceStatus = result;
        })
        .catch(error => {
            console.error('Compliance validation error:', error);
            this.complianceStatus = false;
        });
    }

    // Actions
    handleDownload() {
        // Create downloadable content
        const element = document.createElement('a');
        const file = new Blob([this.generatedClause], { type: 'text/plain' });
        element.href = URL.createObjectURL(file);
        element.download = `${this.selectedContractType}_${this.selectedRegion}_${Date.now()}.txt`;
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
        
        this.showToast('Success', 'Document downloaded successfully!', 'success');
    }

    handleSendForSignature() {
        if (!this.signerEmail) {
            this.showToast('Error', 'Please enter signer email address', 'error');
            return;
        }

        // Create a temporary document record for signature
        const documentContent = this.generatedClause;
        
        initiateSignatureRequest({
            documentId: 'temp_' + Date.now(), // Temporary ID for demo
            signerEmail: this.signerEmail,
            signerName: 'Document Signer'
        })
        .then(result => {
            this.signatureRequestId = result;
            this.showToast('Success', 'Signature request sent successfully!', 'success');
        })
        .catch(error => {
            this.showToast('Error', 'Failed to send signature request: ' + error.body?.message, 'error');
        });
    }

    handleReset() {
        // Reset all values
        this.currentStep = 'step1';
        this.selectedRegion = '';
        this.selectedRole = '';
        this.selectedContractType = '';
        this.additionalClauses = '';
        this.selectedOutputFormat = 'PDF';
        this.includeSignature = false;
        this.signerEmail = '';
        this.generatedClause = '';
        this.complianceStatus = false;
        this.documentGenerated = false;
        this.signatureRequestId = '';
        
        this.showToast('Info', 'Form reset successfully', 'info');
    }

    // Validation
    validateCurrentStep() {
        switch (this.currentStep) {
            case 'step1':
                if (!this.selectedRegion || !this.selectedRole || !this.selectedContractType) {
                    this.showToast('Error', 'Please fill all required fields', 'error');
                    return false;
                }
                break;
            case 'step2':
                if (this.includeSignature && !this.signerEmail) {
                    this.showToast('Error', 'Please enter signer email address', 'error');
                    return false;
                }
                break;
        }
        return true;
    }

    // Utility methods
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}




// version 5

// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateClause from '@salesforce/apex/ComplianceChecker.validateClause';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// export default class DocumentGenerator extends LightningElement {
//     @track currentStep = '1';
//     @track contractType = '';
//     @track region = '';
//     @track role = '';
//     @track additionalNotes = '';
//     @track outputFormat = 'PDF';
//     @track signerEmail = '';
//     @track signerName = '';
//     @track generatedClause = '';
//     @track complianceStatus = '';
//     @track complianceMessage = '';
//     @track isLoadingPreview = false;
//     @track isGenerating = false;
//     @track generationComplete = false;
//     @track hasError = false;
//     @track errorMessage = '';
//     @track documentId = '';
//     @track signatureRequestId = '';

//     // Picklist options
//     contractTypeOptions = [
//         { label: 'Employment Agreement', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Level Agreement', value: 'SLA' }
//     ];

//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value: 'EU' },
//         { label: 'Global', value: 'Global' }
//     ];

//     roleOptions = [
//         { label: 'Manager', value: 'Manager' },
//         { label: 'Employee', value: 'Employee' },
//         { label: 'Administrator', value: 'Admin' }
//     ];

//     formatOptions = [
//         { label: 'PDF Document', value: 'PDF' },
//         { label: 'HTML Format', value: 'HTML' },
//         { label: 'Word Document', value: 'DOCX' }
//     ];

//     // Step management getters
//     get isStep1() { return this.currentStep === '1'; }
//     get isStep2() { return this.currentStep === '2'; }
//     get isStep3() { return this.currentStep === '3'; }
//     get isStep4() { return this.currentStep === '4'; }

//     get isPreviousDisabled() {
//         return this.currentStep === '1' || this.isGenerating;
//     }

//     get isNextDisabled() {
//         if (this.isGenerating) return true;
        
//         switch(this.currentStep) {
//             case '1':
//                 return !this.contractType || !this.region || !this.role;
//             case '2':
//                 return !this.outputFormat || !this.signerEmail || !this.signerName;
//             case '3':
//                 return false;
//             case '4':
//                 return true;
//             default:
//                 return false;
//         }
//     }

//     get nextButtonLabel() {
//         switch(this.currentStep) {
//             case '1': return 'Next';
//             case '2': return 'Review';
//             case '3': return 'Generate Document';
//             case '4': return 'Complete';
//             default: return 'Next';
//         }
//     }

//     get complianceBadgeVariant() {
//         return this.complianceStatus === 'Compliant' ? 'success' : 'warning';
//     }

//     get showStartOver() {
//         return this.currentStep === '4';
//     }

//     // Event handlers
//     handleContractTypeChange(event) {
//         this.contractType = event.detail.value;
//     }

//     handleRegionChange(event) {
//         this.region = event.detail.value;
//     }

//     handleRoleChange(event) {
//         this.role = event.detail.value;
//     }

//     handleNotesChange(event) {
//         this.additionalNotes = event.detail.value;
//     }

//     handleFormatChange(event) {
//         this.outputFormat = event.detail.value;
//     }

//     handleSignerEmailChange(event) {
//         this.signerEmail = event.detail.value;
//     }

//     handleSignerNameChange(event) {
//         this.signerName = event.detail.value;
//     }

//     handleNext() {
//         if (this.currentStep === '1') {
//             this.currentStep = '2';
//         } else if (this.currentStep === '2') {
//             this.currentStep = '3';
//             this.generatePreview();
//         } else if (this.currentStep === '3') {
//             this.currentStep = '4';
//             this.generateDocument();
//         }
//     }

//     handlePrevious() {
//         if (this.currentStep === '2') {
//             this.currentStep = '1';
//         } else if (this.currentStep === '3') {
//             this.currentStep = '2';
//         } else if (this.currentStep === '4') {
//             this.currentStep = '3';
//         }
//     }

//     handleStartOver() {
//         this.resetComponent();
//     }

//     // Core functionality methods
//     async generatePreview() {
//         this.isLoadingPreview = true;
        
//         try {
//             // Generate clause
//             this.generatedClause = await generateClause({
//                 region: this.region,
//                 role: this.role,
//                 contractType: this.contractType
//             });

//             // Check compliance
//             const isCompliant = await validateClause({
//                 clauseText: this.generatedClause,
//                 region: this.region,
//                 documentType: this.contractType
//             });

//             this.complianceStatus = isCompliant ? 'Compliant' : 'Non-Compliant';
//             this.complianceMessage = isCompliant ? 
//                 'Document meets all compliance requirements' : 
//                 'Document requires review for compliance issues';

//         } catch (error) {
//             this.showToast('Error', 'Failed to generate preview: ' + error.body.message, 'error');
//         } finally {
//             this.isLoadingPreview = false;
//         }
//     }

//     async generateDocument() {
//         this.isGenerating = true;
//         this.hasError = false;
        
//         try {
//             // Create document record
//             this.documentId = await this.createDocumentRecord();
            
//             // Initiate signature request
//             this.signatureRequestId = await initiateSignatureRequest({
//                 documentId: this.documentId,
//                 signerEmail: this.signerEmail,
//                 signerName: this.signerName
//             });

//             this.generationComplete = true;
//             this.showToast('Success', 'Document generated and signature request sent!', 'success');

//         } catch (error) {
//             this.hasError = true;
//             this.errorMessage = error.body.message || 'Unknown error occurred';
//             this.showToast('Error', 'Failed to generate document: ' + this.errorMessage, 'error');
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     async createDocumentRecord() {
//         // This would typically call an Apex method to create the document
//         // For now, returning a mock ID
//         return 'DOC-' + Date.now();
//     }

//     resetComponent() {
//         this.currentStep = '1';
//         this.contractType = '';
//         this.region = '';
//         this.role = '';
//         this.additionalNotes = '';
//         this.outputFormat = 'PDF';
//         this.signerEmail = '';
//         this.signerName = '';
//         this.generatedClause = '';
//         this.complianceStatus = '';
//         this.complianceMessage = '';
//         this.isLoadingPreview = false;
//         this.isGenerating = false;
//         this.generationComplete = false;
//         this.hasError = false;
//         this.errorMessage = '';
//         this.documentId = '';
//         this.signatureRequestId = '';
//     }

//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant,
//         });
//         this.dispatchEvent(evt);
//     }
// }




// version 4

// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateClause from '@salesforce/apex/ComplianceChecker.validateClause';
// import createDocumentRequest from '@salesforce/apex/DocumentGenerationController.createDocumentRequest';

// export default class DocumentGenerator extends LightningElement {
//     @track currentStep = 'step-1';
//     @track contractType = '';
//     @track region = '';
//     @track role = '';
//     @track additionalNotes = '';
//     @track outputFormat = 'PDF';
//     @track generatedClause = '';
//     @track complianceStatus = '';
//     @track isGenerating = false;
//     @track generationComplete = false;

//     // Options for picklists
//     contractTypeOptions = [
//         { label: 'Employment Agreement', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Level Agreement', value: 'SLA' }
//     ];

//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value: 'EU' },
//         { label: 'Global', value: 'Global' }
//     ];

//     roleOptions = [
//         { label: 'Manager', value: 'Manager' },
//         { label: 'Employee', value: 'Employee' },
//         { label: 'Administrator', value: 'Admin' }
//     ];

//     formatOptions = [
//         { label: 'PDF', value: 'PDF' },
//         { label: 'HTML', value: 'HTML' },
//         { label: 'Word Document', value: 'DOCX' }
//     ];

//     // Step management
//     get isStep1() { return this.currentStep === 'step-1'; }
//     get isStep2() { return this.currentStep === 'step-2'; }
//     get isStep3() { return this.currentStep === 'step-3'; }
//     get isStep4() { return this.currentStep === 'step-4'; }

//     get isFirstStep() { return this.currentStep === 'step-1'; }
    
//     get nextButtonLabel() {
//         switch(this.currentStep) {
//             case 'step-1': return 'Next';
//             case 'step-2': return 'Review';
//             case 'step-3': return 'Generate Document';
//             case 'step-4': return 'Complete';
//             default: return 'Next';
//         }
//     }

//     get nextButtonDisabled() {
//         switch(this.currentStep) {
//             case 'step-1': return !this.contractType || !this.region || !this.role;
//             case 'step-2': return !this.outputFormat;
//             case 'step-3': return false;
//             case 'step-4': return false;
//             default: return false;
//         }
//     }

// get complianceBadgeVariant() {
//     return this.complianceStatus === 'Compliant' ? 'success' : 'warning';
// }




// version 3


// import { LightningElement, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { NavigationMixin } from 'lightning/navigation';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateCompliance from '@salesforce/apex/ComplianceChecker.validateClause';
// import createDocumentRequest from '@salesforce/apex/DocumentGenerationController.createDocumentRequest';
// import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

// export default class DocumentGenerator extends NavigationMixin(LightningElement) {
//     @track currentStep = 'step-1';
//     @track selectedDocumentType = '';
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track additionalRequirements = '';
//     @track generatedClause = '';
//     @track documentPreview = '';
//     @track complianceStatus = { isCompliant: true, message: '' };
//     @track isLoading = false;
//     @track isGenerating = false;
//     @track generatedDocumentId = '';

//     get documentTypeOptions() {
//         return [
//             { label: 'Employment Contract', value: 'Employment' },
//             { label: 'Non-Disclosure Agreement', value: 'NDA' },
//             { label: 'Service Agreement', value: 'Service' }
//         ];
//     }

//     get regionOptions() {
//         return [
//             { label: 'United States', value: 'US' },
//             { label: 'European Union', value: 'EU' },
//             { label: 'United Kingdom', value: 'UK' },
//             { label: 'India', value: 'IN' }
//         ];
//     }

//     get roleOptions() {
//         return [
//             { label: 'Manager', value: 'Manager' },
//             { label: 'Employee', value: 'Employee' },
//             { label: 'Contractor', value: 'Contractor' },
//             { label: 'Executive', value: 'Executive' }
//         ];
//     }

//     get isStep1() { return this.currentStep === 'step-1'; }
//     get isStep2() { return this.currentStep === 'step-2'; }
//     get isStep3() { return this.currentStep === 'step-3'; }
//     get isStep4() { return this.currentStep === 'step-4'; }

//     get isFirstStep() { return this.currentStep === 'step-1'; }
//     get isLastStep() { return this.currentStep === 'step-4'; }

//     get nextButtonLabel() {
//         switch (this.currentStep) {
//             case 'step-1': return 'Configure';
//             case 'step-2': return 'Preview';
//             case 'step-3': return 'Generate';
//             case 'step-4': return 'Complete';
//             default: return 'Next';
//         }
//     }

//     get isNextDisabled() {
//         switch (this.currentStep) {
//             case 'step-1': 
//                 return !this.selectedDocumentType || !this.selectedRegion || !this.selectedRole;
//             case 'step-2': 
//                 return !this.generatedClause || !this.complianceStatus.isCompliant;
//             case 'step-3': 
//                 return false;
//             case 'step-4': 
//                 return true;
//             default: 
//                 return false;
//         }
//     }

//     get complianceStatusClass() {
//         return this.complianceStatus.isCompliant ? 
//             'slds-text-color_success slds-m-top_small' : 
//             'slds-text-color_error slds-m-top_small';
//     }

    

            
// get complianceIcon() {
//     return this.complianceStatus.isCompliant ? 'utility:success' : 'utility:error';
// }

// // Event Handlers
// handleDocumentTypeChange(event) {
//     this.selectedDocumentType = event.detail.value;
// }

// handleRegionChange(event) {
//     this.selectedRegion = event.detail.value;
// }

// handleRoleChange(event) {
//     this.selectedRole = event.detail.value;
// }

// handleAdditionalRequirements(event) {
//     this.additionalRequirements = event.target.value;
// }

// async handleGeneratePreview() {
//     this.isGenerating = true;
//     try {
//         // Generate clause
//         const clause = await generateClause({
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             contractType: this.selectedDocumentType
//         });
        
//         this.generatedClause = clause;
        
//         // Validate compliance
//         const isCompliant = await validateCompliance({
//             clauseText: clause,
//             region: this.selectedRegion,
//             documentType: this.selectedDocumentType
//         });
        
//         this.complianceStatus = {
//             isCompliant: isCompliant,
//             message: isCompliant ? 
//                 'Document meets all compliance requirements' : 
//                 'Document has compliance issues that need attention'
//         };
        
//         this.showToast('Success', 'Clause generated and validated', 'success');
        
//     } catch (error) {
//         this.showToast('Error', 'Failed to generate clause: ' + error.body.message, 'error');
//         console.error('Generation error:', error);
//     } finally {
//         this.isGenerating = false;
//     }
// }

// handleNext() {
//     if (this.currentStep === 'step-1') {
//         this.currentStep = 'step-2';
//     } else if (this.currentStep === 'step-2') {
//         this.currentStep = 'step-3';
//         this.generateDocumentPreview();
//     } else if (this.currentStep === 'step-3') {
//         this.generateFinalDocument();
//     }
// }

// handlePrevious() {
//     if (this.currentStep === 'step-2') {
//         this.currentStep = 'step-1';
//     } else if (this.currentStep === 'step-3') {
//         this.currentStep = 'step-2';
//     } else if (this.currentStep === 'step-4') {
//         this.currentStep = 'step-3';
//     }
// }

// generateDocumentPreview() {
//     const preview = `
//         <h2>${this.selectedDocumentType}</h2>
//         <p><strong>Region:</strong> ${this.selectedRegion}</p>
//         <p><strong>Role:</strong> ${this.selectedRole}</p>
//         <div style="border: 1px solid #ccc; padding: 15px; margin: 10px 0;">
//             <h3>Generated Clause:</h3>
//             <p>${this.generatedClause}</p>
//         </div>
//         ${this.additionalRequirements ? 
//             `<div style="background: #f4f6f9; padding: 10px; margin: 10px 0;">
//                 <h4>Additional Requirements:</h4>
//                 <p>${this.additionalRequirements}</p>
//             </div>` : ''
//         }
//         <div style="margin-top: 20px;">
//             <p><strong>Compliance Status:</strong> 
//                 <span style="color: ${this.complianceStatus.isCompliant ? 'green' : 'red'}">
//                     ${this.complianceStatus.message}
//                 </span>
//             </p>
//         </div>
//     `;
//     this.documentPreview = preview;
// }

// async generateFinalDocument() {
//     this.isLoading = true;
//     try {
//         const documentId = await createDocumentRequest({
//             documentType: this.selectedDocumentType,
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             clauseContent: this.generatedClause,
//             additionalRequirements: this.additionalRequirements,
//             complianceStatus: this.complianceStatus.isCompliant ? 'Compliant' : 'Non-Compliant'
//         });
        
//         this.generatedDocumentId = documentId;
//         this.currentStep = 'step-4';
//         this.showToast('Success', 'Document generated successfully!', 'success');
        
//     } catch (error) {
//         this.showToast('Error', 'Failed to generate document: ' + error.body.message, 'error');
//         console.error('Document generation error:', error);
//     } finally {
//         this.isLoading = false;
//     }
// }

// async handleRequestSignature() {
//     try {
//         const signatureRequestId = await initiateSignatureRequest({
//             documentId: this.generatedDocumentId,
//             signerEmail: 'placeholder@example.com', // In real implementation, get from user input
//             documentTitle: `${this.selectedDocumentType} - ${this.selectedRegion}`
//         });
        
//         this.showToast('Success', 'Signature request initiated successfully!', 'success');
        
//         // Navigate to signature request record
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: signatureRequestId,
//                 objectApiName: 'Signature_Request__c',
//                 actionName: 'view'
//             }
//         });
        
//     } catch (error) {
//         this.showToast('Error', 'Failed to initiate signature request: ' + error.body.message, 'error');
//         console.error('Signature request error:', error);
//     }
// }

// handleReset() {
//     this.currentStep = 'step-1';
//     this.selectedDocumentType = '';
//     this.selectedRegion = '';
//     this.selectedRole = '';
//     this.additionalRequirements = '';
//     this.generatedClause = '';
//     this.documentPreview = '';
//     this.complianceStatus = { isCompliant: true, message: '' };
//     this.generatedDocumentId = '';
// }

// showToast(title, message, variant) {
//     this.dispatchEvent(new ShowToastEvent({
//         title: title,
//         message: message,
//         variant: variant
//     }));
// }
// }



// version 2

// import { LightningElement, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateCompliance from '@salesforce/apex/ComplianceChecker.validateClause';
// import createDocumentRequest from '@salesforce/apex/DocumentGenerationController.createDocumentRequest';

// export default class DocumentGenerator extends LightningElement {
//     @track currentStep = 'step-1';
//     @track selectedDocumentType = '';
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedTemplate = {};
//     @track generatedClause = '';
//     @track complianceStatus = { isCompliant: true, message: '' };
//     @track finalDocumentPreview = '';
//     @track availableTemplates = [];
    
//     // Step tracking
//     get isStep1() { return this.currentStep === 'step-1'; }
//     get isStep2() { return this.currentStep === 'step-2'; }
//     get isStep3() { return this.currentStep === 'step-3'; }
//     get isStep4() { return this.currentStep === 'step-4'; }
    
//     get isNextDisabled() {
//         if (this.isStep1) {
//             return !this.selectedDocumentType || !this.selectedRegion || !this.selectedRole;
//         }
//         if (this.isStep2) {
//             return !this.selectedTemplate.id;
//         }
//         if (this.isStep3) {
//             return !this.complianceStatus.isCompliant;
//         }
//         return false;
//     }
    
//     // Options for dropdowns
//     get documentTypeOptions() {
//         return [
//             { label: 'Employment Contract', value: 'Employment' },
//             { label: 'Non-Disclosure Agreement', value: 'NDA' },
//             { label: 'Service Agreement', value: 'Service' },
//             { label: 'Purchase Agreement', value: 'Purchase' }
//         ];
//     }
    
//     get regionOptions() {
//         return [
//             { label: 'United States', value: 'US' },
//             { label: 'European Union', value: 'EU' },
//             { label: 'United Kingdom', value: 'UK' },
//             { label: 'Canada', value: 'CA' }
//         ];
//     }
    
//     get roleOptions() {
//         return [
//             { label: 'Manager', value: 'Manager' },
//             { label: 'Employee', value: 'Employee' },
//             { label: 'Contractor', value: 'Contractor' },
//             { label: 'Executive', value: 'Executive' }
//         ];
//     }
    
//     connectedCallback() {
//         this.loadAvailableTemplates();
//     }
    
//     loadAvailableTemplates() {
//         // Mock templates - in production, load from Salesforce
//         this.availableTemplates = [
//             { id: 'template1', name: 'Standard Employment Contract', description: 'Basic employment terms' },
//             { id: 'template2', name: 'Executive Agreement', description: 'Senior executive terms' },
//             { id: 'template3', name: 'Contractor Agreement', description: 'Independent contractor terms' }
//         ];
//     }
    
//     // Event Handlers
//     handleDocumentTypeChange(event) {
//         this.selectedDocumentType = event.detail.value;
//     }
    
//     handleRegionChange(event) {
//         this.selectedRegion = event.detail.value;
//     }
    
//     handleRoleChange(event) {
//         this.selectedRole = event.detail.value;
//     }
    
//     handleTemplateSelection(event) {
//         const templateId = event.detail.value;
//         this.selectedTemplate = this.availableTemplates.find(t => t.id === templateId);
//     }
    
//     handleClauseChange(event) {
//         this.generatedClause = event.detail.value;
//         this.validateClauseCompliance();
//     }
    
//     handleRegenerateClause() {
//         this.generateClauseContent();
//     }
    
//     // Navigation
//     handleNext() {
//         if (this.currentStep === 'step-1') {
//             this.currentStep = 'step-2';
//         } else if (this.currentStep === 'step-2') {
//             this.currentStep = 'step-3';
//             this.generateClauseContent();
//         } else if (this.currentStep === 'step-3') {
//             this.currentStep = 'step-4';
//             this.generateDocumentPreview();
//         }
//     }
    
//     handlePrevious() {
//         if (this.currentStep === 'step-2') {
//             this.currentStep = 'step-1';
//         } else if (this.currentStep === 'step-3') {
//             this.currentStep = 'step-2';
//         } else if (this.currentStep === 'step-4') {
//             this.currentStep = 'step-3';
//         }
//     }
    
//     // Core functionality
//         generateClauseContent() {
//         generateClause({ 
//             region: this.selectedRegion, 
//             role: this.selectedRole, 
//             contractType: this.selectedDocumentType 
//         })
//         .then(result => {
//             this.generatedClause = result;
//             this.validateClauseCompliance();
//             this.showToast('Success', 'Clause generated successfully', 'success');
//         })
//         .catch(error => {
//             console.error('Error generating clause:', error);
//             this.showToast('Error', 'Failed to generate clause: ' + error.body.message, 'error');
//         });
//     }

//     validateClauseCompliance() {
//         if (this.generatedClause && this.selectedRegion) {
//             validateCompliance({ 
//                 clauseText: this.generatedClause, 
//                 region: this.selectedRegion,
//                 documentType: this.selectedDocumentType
//             })
//             .then(result => {
//                 this.complianceStatus = {
//                     isCompliant: result,
//                     message: result ? 'All compliance requirements met' : 'Compliance requirements not met'
//                 };
//             })
//             .catch(error => {
//                 console.error('Error validating compliance:', error);
//                 this.complianceStatus = {
//                     isCompliant: false,
//                     message: 'Error checking compliance'
//                 };
//             });
//         }
//     }

//     generateDocumentPreview() {
//         this.finalDocumentPreview = `
//             <h2>${this.selectedDocumentType} Agreement</h2>
//             <p><strong>Region:</strong> ${this.selectedRegion}</p>
//             <p><strong>Role:</strong> ${this.selectedRole}</p>
//             <p><strong>Template:</strong> ${this.selectedTemplate.name}</p>
//             <hr/>
//             <div class="clause-content">
//                 <h3>Generated Clauses:</h3>
//                 <p>${this.generatedClause}</p>
//             </div>
//             <hr/>
//             <p><em>This document was generated on ${new Date().toLocaleDateString()}</em></p>
//         `;
//     }

//     handleGenerateDocument() {
//         createDocumentRequest({
//             documentType: this.selectedDocumentType,
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             templateId: this.selectedTemplate.id,
//             clauseContent: this.generatedClause
//         })
//         .then(result => {
//             this.showToast('Success', 'Document generated successfully!', 'success');
//             // Reset wizard
//             this.resetWizard();
//         })
//         .catch(error => {
//             console.error('Error generating document:', error);
//             this.showToast('Error', 'Failed to generate document: ' + error.body.message, 'error');
//         });
//     }

//     resetWizard() {
//         this.currentStep = 'step-1';
//         this.selectedDocumentType = '';
//         this.selectedRegion = '';
//         this.selectedRole = '';
//         this.selectedTemplate = {};
//         this.generatedClause = '';
//         this.complianceStatus = { isCompliant: true, message: '' };
//         this.finalDocumentPreview = '';
//     }

//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant,
//         });
//         this.dispatchEvent(evt);
//     }
// }














// version 1

// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateClause from '@salesforce/apex/ComplianceChecker.validateClause';

// export default class DocumentGenerator extends LightningElement {
//     @track currentStep = 'step-1';
//     @track selectedContractType = '';
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedTemplate = '';
//     @track additionalClauses = '';
//     @track documentTitle = '';
//     @track outputFormat = '';
//     @track selectedCompliance = [];
//     @track signingRequired = false;
//     @track generatedClause = '';
//     @track complianceStatus = false;
//     @track isGenerating = false;
//     @track showSuccess = false;
//     @track errorMessage = '';
//     @track successMessage = '';

//     // Options for picklists
//     contractTypeOptions = [
//         { label: 'Employment Contract', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Level Agreement', value: 'SLA' }
//     ];

//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value:
// 'EU' },
// { label: 'India', value: 'IN' },
// { label: 'Canada', value: 'CA' }
// ];
// templateOptions = [
//     { label: 'Standard Template', value: 'standard' },
//     { label: 'Premium Template', value: 'premium' },
//     { label: 'Custom Template', value: 'custom' }
// ];

// formatOptions = [
//     { label: 'PDF', value: 'PDF' },
//     { label: 'Word Document', value: 'DOCX' },
//     { label: 'HTML', value: 'HTML' }
// ];

// complianceOptions = [
//     { label: 'GDPR', value: 'GDPR' },
//     { label: 'HIPAA', value: 'HIPAA' },
//     { label: 'SOX', value: 'SOX' },
//     { label: 'CCPA', value: 'CCPA' }
// ];

// // Computed properties
// get isStep1() {
//     return this.currentStep === 'step-1';
// }

// get isStep2() {
//     return this.currentStep === 'step-2';
// }

// get isStep3() {
//     return this.currentStep === 'step-3';
// }

// get isStep4() {
//     return this.currentStep === 'step-4';
// }

// get isStep1Invalid() {
//     return !this.selectedContractType || !this.selectedRegion || !this.selectedRole;
// }

// get isStep2Invalid() {
//     return !this.selectedTemplate;
// }

// get isStep3Invalid() {
//     return !this.documentTitle || !this.outputFormat;
// }

// get signingRequiredLabel() {
//     return this.signingRequired ? 'Yes' : 'No';
// }

// get complianceStatusLabel() {
//     return this.complianceStatus ? 'Compliant' : 'Non-Compliant';
// }

// get complianceStatusVariant() {
//     return this.complianceStatus ? 'success' : 'warning';
// }

// // Event handlers
// handleContractTypeChange(event) {
//     this.selectedContractType = event.target.value;
// }

// handleRegionChange(event) {
//     this.selectedRegion = event.target.value;
// }

// handleRoleChange(event) {
//     this.selectedRole = event.target.value;
// }

// handleTemplateChange(event) {
//     this.selectedTemplate = event.target.value;
//     this.generateClausePreview();
// }

// handleClausesChange(event) {
//     this.additionalClauses = event.target.value;
// }

// handleDocumentTitleChange(event) {
//     this.documentTitle = event.target.value;
// }

// handleFormatChange(event) {
//     this.outputFormat = event.target.value;
// }

// handleComplianceChange(event) {
//     this.selectedCompliance = event.target.value;
//     this.validateCompliance();
// }

// handleSigningRequiredChange(event) {
//     this.signingRequired = event.target.checked;
// }

// handleNext() {
//     this.clearMessages();
    
//     switch(this.currentStep) {
//         case 'step-1':
//             this.currentStep = 'step-2';
//             this.loadTemplateOptions();
//             break;
//         case 'step-2':
//             this.currentStep = 'step-3';
//             break;
//         case 'step-3':
//             this.currentStep = 'step-4';
//             this.generateClausePreview();
//             this.validateCompliance();
//             break;
//     }
// }

// handlePrevious() {
//     this.clearMessages();
    
//     switch(this.currentStep) {
//         case 'step-2':
//             this.currentStep = 'step-1';
//             break;
//         case 'step-3':
//             this.currentStep = 'step-2';
//             break;
//         case 'step-4':
//             this.currentStep = 'step-3';
//             break;
//     }
// }

// loadTemplateOptions() {
//     // Filter template options based on contract type and region
//     // This would typically call an Apex method to get relevant templates
//     console.log('Loading templates for:', this.selectedContractType, this.selectedRegion);
// }

// async generateClausePreview() {
//     if (!this.selectedTemplate || !this.selectedContractType) return;

//     try {
//         const clauseData = {
//             contractType: this.selectedContractType,
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             template: this.selectedTemplate,
//             additionalClauses: this.additionalClauses
//         };

//         const result = await generateClause({ 
//             clauseData: JSON.stringify(clauseData) 
//         });
        
//         this.generatedClause = result;
//     } catch (error) {
//         console.error('Error generating clause preview:', error);
//         this.showErrorToast('Failed to generate clause preview');
//     }
// }

// async validateCompliance() {
//     if (this.selectedCompliance.length === 0) {
//         this.complianceStatus = true;
//         return;
//     }

//     try {
//         const complianceData = {
//             clause: this.generatedClause,
//             regulations: this.selectedCompliance,
//             region: this.selectedRegion
//         };

//         const result = await validateClause({ 
//             complianceData: JSON.stringify(complianceData) 
//         });
        
//         this.complianceStatus = result;
//     } catch (error) {
//         console.error('Error validating compliance:', error);
//         this.complianceStatus = false;
//     }
// }

// async handleGenerateDocument() {
//     this.isGenerating = true;
//     this.clearMessages();

//     try {
//         // Prepare document generation data
//         const documentData = {
//             contractType: this.selectedContractType,
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             template: this.selectedTemplate,
//             documentTitle: this.documentTitle,
//             outputFormat: this.outputFormat,
//             compliance: this.selectedCompliance,
//             signingRequired: this.signingRequired,
//             additionalClauses: this.additionalClauses,
//             generatedClause: this.generatedClause
//         };

//         // Call Apex method to generate document
//         // This would be implemented in the next phase
//         console.log('Generating document with data:', documentData);

//         // Simulate document generation
//         await this.simulateDocumentGeneration();

//         this.showSuccess = true;
//         this.successMessage = 'Your document has been generated and is ready for download.';
//         this.showSuccessToast('Document generated successfully!');

//     } catch (error) {
//         console.error('Error generating document:', error);
//         this.errorMessage = 'Failed to generate document. Please try again.';
//         this.showErrorToast('Document generation failed');
//     } finally {
//         this.isGenerating = false;
//     }
// }

// simulateDocumentGeneration() {
//     return new Promise(resolve => {
//         setTimeout(resolve, 3000); // Simulate 3 second generation time
//     });
// }

// clearMessages() {
//     this.errorMessage = '';
//     this.showSuccess = false;
//     this.successMessage = '';
// }

// showSuccessToast(message) {
//     this.dispatchEvent(
//         new ShowToastEvent({
//             title: 'Success',
//             message: message,
//             variant: 'success'
//         })
//     );
// }

// showErrorToast(message) {
//     this.dispatchEvent(
//         new ShowToastEvent({
//             title: 'Error',
//             message: message,
//             variant: 'error'
//         })
//     );
// }
// }





// Version 0

// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateClause from '@salesforce/apex/ComplianceChecker.validateClause';

// export default class DocumentGenerator extends LightningElement {
//     @track currentStep = 'step-1';
//     @track selectedContractType = '';
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedTemplate = '';
//     @track additionalClauses = '';
//     @track documentTitle = '';
//     @track outputFormat = '';
//     @track selectedCompliance = [];
//     @track signingRequired = false;
//     @track generatedClause = '';
//     @track complianceStatus = false;
//     @track isGenerating = false;
//     @track showSuccess = false;
//     @track errorMessage = '';
//     @track successMessage = '';

//     // Options for picklists
//     contractTypeOptions = [
//         { label: 'Employment Contract', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Level Agreement', value: 'SLA' }
//     ];

//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value:
// 'EU' },
// { label: 'India', value: 'IN' },
// { label: 'Canada', value: 'CA' }
// ];
// templateOptions = [
//     { label: 'Standard Template', value: 'standard' },
//     { label: 'Premium Template', value: 'premium' },
//     { label: 'Custom Template', value: 'custom' }
// ];

// formatOptions = [
//     { label: 'PDF', value: 'PDF' },
//     { label: 'Word Document', value: 'DOCX' },
//     { label: 'HTML', value: 'HTML' }
// ];

// complianceOptions = [
//     { label: 'GDPR', value: 'GDPR' },
//     { label: 'HIPAA', value: 'HIPAA' },
//     { label: 'SOX', value: 'SOX' },
//     { label: 'CCPA', value: 'CCPA' }
// ];

// // Computed properties
// get isStep1() {
//     return this.currentStep === 'step-1';
// }

// get isStep2() {
//     return this.currentStep === 'step-2';
// }

// get isStep3() {
//     return this.currentStep === 'step-3';
// }

// get isStep4() {
//     return this.currentStep === 'step-4';
// }

// get isStep1Invalid() {
//     return !this.selectedContractType || !this.selectedRegion || !this.selectedRole;
// }

// get isStep2Invalid() {
//     return !this.selectedTemplate;
// }

// get isStep3Invalid() {
//     return !this.documentTitle || !this.outputFormat;
// }

// get signingRequiredLabel() {
//     return this.signingRequired ? 'Yes' : 'No';
// }

// get complianceStatusLabel() {
//     return this.complianceStatus ? 'Compliant' : 'Non-Compliant';
// }

// get complianceStatusVariant() {
//     return this.complianceStatus ? 'success' : 'warning';
// }

// // Event handlers
// handleContractTypeChange(event) {
//     this.selectedContractType = event.target.value;
// }

// handleRegionChange(event) {
//     this.selectedRegion = event.target.value;
// }

// handleRoleChange(event) {
//     this.selectedRole = event.target.value;
// }

// handleTemplateChange(event) {
//     this.selectedTemplate = event.target.value;
//     this.generateClausePreview();
// }

// handleClausesChange(event) {
//     this.additionalClauses = event.target.value;
// }

// handleDocumentTitleChange(event) {
//     this.documentTitle = event.target.value;
// }

// handleFormatChange(event) {
//     this.outputFormat = event.target.value;
// }

// handleComplianceChange(event) {
//     this.selectedCompliance = event.target.value;
//     this.validateCompliance();
// }

// handleSigningRequiredChange(event) {
//     this.signingRequired = event.target.checked;
// }

// handleNext() {
//     this.clearMessages();
    
//     switch(this.currentStep) {
//         case 'step-1':
//             this.currentStep = 'step-2';
//             this.loadTemplateOptions();
//             break;
//         case 'step-2':
//             this.currentStep = 'step-3';
//             break;
//         case 'step-3':
//             this.currentStep = 'step-4';
//             this.generateClausePreview();
//             this.validateCompliance();
//             break;
//     }
// }

// handlePrevious() {
//     this.clearMessages();
    
//     switch(this.currentStep) {
//         case 'step-2':
//             this.currentStep = 'step-1';
//             break;
//         case 'step-3':
//             this.currentStep = 'step-2';
//             break;
//         case 'step-4':
//             this.currentStep = 'step-3';
//             break;
//     }
// }

// loadTemplateOptions() {
//     // Filter template options based on contract type and region
//     // This would typically call an Apex method to get relevant templates
//     console.log('Loading templates for:', this.selectedContractType, this.selectedRegion);
// }

// async generateClausePreview() {
//     if (!this.selectedTemplate || !this.selectedContractType) return;

//     try {
//         const clauseData = {
//             contractType: this.selectedContractType,
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             template: this.selectedTemplate,
//             additionalClauses: this.additionalClauses
//         };

//         const result = await generateClause({ 
//             clauseData: JSON.stringify(clauseData) 
//         });
        
//         this.generatedClause = result;
//     } catch (error) {
//         console.error('Error generating clause preview:', error);
//         this.showErrorToast('Failed to generate clause preview');
//     }
// }

// async validateCompliance() {
//     if (this.selectedCompliance.length === 0) {
//         this.complianceStatus = true;
//         return;
//     }

//     try {
//         const complianceData = {
//             clause: this.generatedClause,
//             regulations: this.selectedCompliance,
//             region: this.selectedRegion
//         };

//         const result = await validateClause({ 
//             complianceData: JSON.stringify(complianceData) 
//         });
        
//         this.complianceStatus = result;
//     } catch (error) {
//         console.error('Error validating compliance:', error);
//         this.complianceStatus = false;
//     }
// }

// async handleGenerateDocument() {
//     this.isGenerating = true;
//     this.clearMessages();

//     try {
//         // Prepare document generation data
//         const documentData = {
//             contractType: this.selectedContractType,
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             template: this.selectedTemplate,
//             documentTitle: this.documentTitle,
//             outputFormat: this.outputFormat,
//             compliance: this.selectedCompliance,
//             signingRequired: this.signingRequired,
//             additionalClauses: this.additionalClauses,
//             generatedClause: this.generatedClause
//         };

//         // Call Apex method to generate document
//         // This would be implemented in the next phase
//         console.log('Generating document with data:', documentData);

//         // Simulate document generation
//         await this.simulateDocumentGeneration();

//         this.showSuccess = true;
//         this.successMessage = 'Your document has been generated and is ready for download.';
//         this.showSuccessToast('Document generated successfully!');

//     } catch (error) {
//         console.error('Error generating document:', error);
//         this.errorMessage = 'Failed to generate document. Please try again.';
//         this.showErrorToast('Document generation failed');
//     } finally {
//         this.isGenerating = false;
//     }
// }

// simulateDocumentGeneration() {
//     return new Promise(resolve => {
//         setTimeout(resolve, 3000); // Simulate 3 second generation time
//     });
// }

// clearMessages() {
//     this.errorMessage = '';
//     this.showSuccess = false;
//     this.successMessage = '';
// }

// showSuccessToast(message) {
//     this.dispatchEvent(
//         new ShowToastEvent({
//             title: 'Success',
//             message: message,
//             variant: 'success'
//         })
//     );
// }

// showErrorToast(message) {
//     this.dispatchEvent(
//         new ShowToastEvent({
//             title: 'Error',
//             message: message,
//             variant: 'error'
//         })
//     );
// }
// }
