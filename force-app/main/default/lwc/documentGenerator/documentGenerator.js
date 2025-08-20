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
