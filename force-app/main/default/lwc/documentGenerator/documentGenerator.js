import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import createDocumentRequest from '@salesforce/apex/DocumentGenerationController.createDocumentRequest';
import generateAndRequestSignature from '@salesforce/apex/DocumentGenerationController.generateAndRequestSignature';

export default class DocumentGenerator extends NavigationMixin(LightningElement) {
    // Step Management
    @track currentStep = 1;
    @track totalSteps = 4;
    
    // Form Data
    @track selectedRegion = '';
    @track selectedRole = '';
    @track selectedContractType = '';
    @track additionalRequirements = '';
    @track aiProcessingEnabled = true;
    @track signerEmail = '';
    @track signerName = '';
    @track signatureInstructions = '';
    @track selectedSignatureOptions = [];
    
    // Generation State
    @track isGenerating = false;
    @track generatedClause = '';
    @track documentId = '';
    @track signatureRequestId = '';
    @track complianceStatus = null;
    @track complianceDetails = null;
    
    // Error Handling
    @track showError = false;
    @track errorMessage = '';
    
    // Email Status
    @track emailSentStatus = false;

    // Options Data
    regionOptions = [
        { label: 'United States', value: 'US' },
        { label: 'European Union', value: 'EU' },
        { label: 'Asia Pacific', value: 'APAC' },
        { label: 'Global', value: 'GLOBAL' }
    ];

    roleOptions = [
        { label: 'Manager', value: 'Manager' },
        { label: 'Employee', value: 'Employee' },
        { label: 'Developer', value: 'Developer' },
        { label: 'Admin', value: 'Admin' },
        { label: 'Contractor', value: 'Contractor' },
        { label: 'Intern', value: 'Intern' }
    ];

    contractTypeOptions = [
        { label: 'Employment Agreement', value: 'Employment' },
        { label: 'Non-Disclosure Agreement', value: 'NDA' },
        { label: 'Service Level Agreement', value: 'SLA' },
        { label: 'Contractor Agreement', value: 'Contractor' },
        { label: 'Consulting Agreement', value: 'Consulting' }
    ];

    signatureOptionsList = [
        { label: 'Require Identity Verification', value: 'identity_verification' },
        { label: 'Send Reminder Emails', value: 'email_reminders' },
        { label: 'Allow Signature Delegation', value: 'signature_delegation' },
        { label: 'Enable Mobile Signing', value: 'mobile_signing' }
    ];

    // Computed Properties
    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }
    get isStep4() { return this.currentStep === 4; }
    
    get isFirstStep() { return this.currentStep === 1; }
    get isLastStep() { return this.currentStep === this.totalSteps; }
    
    get currentStepNumber() { return this.currentStep; }
    
    get progressText() {
        switch(this.currentStep) {
            case 1: return 'Configuration';
            case 2: return 'Generation';
            case 3: return 'Signature';
            case 4: return 'Complete';
            default: return 'Processing';
        }
    }
    
    get progressStyle() {
        const percentage = (this.currentStep / this.totalSteps) * 100;
        return `width: ${percentage}%`;
    }
    
    get nextButtonLabel() {
        switch(this.currentStep) {
            case 1: return 'Configure';
            case 2: return 'Generate';
            case 3: return 'Request Signature';
            case 4: return 'Finish';
            default: return 'Next';
        }
    }
    
    get isNextDisabled() {
        switch(this.currentStep) {
            case 1:
                return !this.selectedRegion || !this.selectedRole || !this.selectedContractType;
            case 2:
                return !this.generatedClause || this.isGenerating;
            case 3:
                return !this.signerEmail || !this.signerName;
            case 4:
                return false;
            default:
                return false;
        }
    }
    
    get complianceStatusClass() {
        if (!this.complianceStatus) return '';
        return this.complianceStatus.isCompliant ? 
            'slds-box slds-theme_success slds-text-align_center slds-p-around_small' :
            'slds-box slds-theme_warning slds-text-align_center slds-p-around_small';
    }
    
    get complianceIcon() {
        if (!this.complianceStatus) return 'utility:info';
        return this.complianceStatus.isCompliant ? 'utility:success' : 'utility:warning';
    }
    
    get complianceVariant() {
        if (!this.complianceStatus) return 'neutral';
        return this.complianceStatus.isCompliant ? 'success' : 'warning';
    }
    
    get complianceStatusText() {
        if (!this.complianceStatus) return 'Compliance check pending';
        return this.complianceStatus.isCompliant ? 
            'Document is compliant with all regulations' : 
            'Document requires compliance review';
    }
    
    get complianceScore() {
        return this.complianceDetails?.complianceScore ? 
            `${this.complianceDetails.complianceScore}%` : 'N/A';
    }
    
    get complianceAnalysis() {
        return this.complianceDetails?.analysis || 'No detailed analysis available';
    }
    
    get complianceViolations() {
        return this.complianceDetails?.violations || [];
    }

    // Event Handlers - Step 1
    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
        this.resetGenerationData();
    }
    
    handleRoleChange(event) {
        this.selectedRole = event.detail.value;
        this.resetGenerationData();
    }
    
    handleContractTypeChange(event) {
        this.selectedContractType = event.detail.value;
        this.resetGenerationData();
    }
    
    handleAdditionalRequirementsChange(event) {
        this.additionalRequirements = event.detail.value;
    }
    
    handleAIProcessingChange(event) {
        this.aiProcessingEnabled = event.detail.checked;
    }

    // Event Handlers - Step 3
    handleSignerEmailChange(event) {
        this.signerEmail = event.detail.value;
    }
    
    handleSignerNameChange(event) {
        this.signerName = event.detail.value;
    }
    
    handleSignatureInstructionsChange(event) {
        this.signatureInstructions = event.detail.value;
    }
    
    handleSignatureOptionsChange(event) {
        this.selectedSignatureOptions = event.detail.value;
    }

    // Navigation Handlers
    handleNext() {
        if (this.currentStep < this.totalSteps) {
            if (this.currentStep === 2 && !this.generatedClause) {
                this.handleGenerateDocument();
            } else if (this.currentStep === 3) {
                this.handleRequestSignature();
            } else {
                this.currentStep++;
            }
        }
    }
    
    handlePrevious() {
        if (this.currentStep > 1) {
            this.currentStep--;
        }
    }

    // Document Generation Handler
    async handleGenerateDocument() {
        this.isGenerating = true;
        this.clearError();
        
        try {
            // Create document request
            this.documentId = await createDocumentRequest({
                contractType: this.selectedContractType,
                region: this.selectedRegion,
                role: this.selectedRole,
                templateId: null,
                additionalRequirements: this.additionalRequirements
            });
            
            // Simulate AI processing delay for better UX
            await this.delay(2000);
            
            // Get generated content (this would be returned by the Apex method in real implementation)
            this.generatedClause = await this.getGeneratedClause();
            
            // Validate compliance
            this.complianceStatus = await this.validateCompliance();
            
            // Move to next step automatically
            this.currentStep = 3;
            
            this.showSuccessToast('Document generated successfully!');
            
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isGenerating = false;
        }
    }

    // Signature Request Handler
    async handleRequestSignature() {
        try {
            const result = await generateAndRequestSignature({
                configId: this.documentId,
                signerEmail: this.signerEmail,
                signerName: this.signerName
            });
            
            this.signatureRequestId = result.signatureRequestId;
            this.emailSentStatus = true;
            this.currentStep = 4;
            
            this.showSuccessToast('Signature request sent successfully!');
            
        } catch (error) {
            this.handleError(error);
        }
    }

    // Action Handlers
    handleDownloadDocument() {
        // Create downloadable content
        const element = document.createElement('a');
        const file = new Blob([this.generateDocumentContent()], { type: 'text/plain' });
        element.href = URL.createObjectURL(file);
        element.download = `${this.selectedContractType}_${new Date().toISOString().split('T')[0]}.txt`;
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
        
        this.showSuccessToast('Document downloaded successfully!');
    }
    
    handleViewDocument() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.documentId,
                objectApiName: 'DocumentLifecycleConfiguration__c',
                actionName: 'view'
            }
        });
    }
    
    handleGenerateNew() {
        // Reset all form data
        this.resetComponent();
        this.showSuccessToast('Ready for new document generation!');
    }

    // Error Handling
    handleError(error) {
        console.error('Error:', error);
        this.errorMessage = error.body ? error.body.message : error.message || 'An unexpected error occurred';
        this.showError = true;
        this.showErrorToast(this.errorMessage);
    }
    
    handleCloseError() {
        this.showError = false;
        this.errorMessage = '';
    }
    
    clearError() {
        this.showError = false;
        this.errorMessage = '';
    }

    // Helper Methods
    async getGeneratedClause() {
        // This would typically come from the Apex response
        // For now, simulating generated content
        const templates = {
            'Employment': `EMPLOYMENT AGREEMENT
generateClause() {
    const templates = {
        'Employment': `EMPLOYMENT AGREEMENT
This Employment Agreement is entered into between the Company and ${this.signerName || '[Employee Name]'}, effective as of the date of execution.

TERMS AND CONDITIONS:
1. Position and Responsibilities: The Employee will serve in the capacity of ${this.selectedRole} and will perform duties as assigned by the Company.
2. Compensation: The Employee will receive compensation as detailed in the attached compensation schedule, subject to applicable deductions and withholdings.
3. Employment Period: This agreement shall commence on the effective date and continue until terminated in accordance with the provisions herein.
4. Confidentiality: The Employee agrees to maintain confidentiality of all proprietary information and trade secrets of the Company.
5. Compliance: This agreement is governed by ${
            this.selectedRegion === 'US'
                ? 'United States federal and state laws'
                : this.selectedRegion === 'EU'
                ? 'European Union employment regulations and GDPR'
                : 'applicable local employment laws'
        }.`,

        'NDA': `NON-DISCLOSURE AGREEMENT
This Non-Disclosure Agreement is entered into between the Company and ${this.signerName || '[Party Name]'} for the purpose of protecting confidential information.`,

        'SLA': `SERVICE LEVEL AGREEMENT
This Service Level Agreement is entered into between the Company and ${this.signerName || '[Service Provider]'} to define service expectations and performance metrics.`,

        'Contractor': `CONTRACTOR AGREEMENT
This Contractor Agreement is entered into between the Company and ${this.signerName || '[Contractor Name]'} for the provision of professional services.`,

        'Consulting': `CONSULTING AGREEMENT
This Consulting Agreement is entered into between the Company and ${this.signerName || '[Consultant Name]'} for specialized consulting services.`
    };

    let baseClause = templates[this.selectedContractType] || templates['Employment'];

    // Add additional requirements if provided
    if (this.additionalRequirements) {
        baseClause += `\n\nADDITIONAL REQUIREMENTS:\n${this.additionalRequirements}`;
    }

    // Add AI-enhanced clauses if enabled
    if (this.aiProcessingEnabled) {
        baseClause += this.getAIEnhancedClauses();
    }

    return baseClause;
}

getAIEnhancedClauses() {
    const aiClauses = {
        'Employment': {
            'Manager': `\n\nMANAGEMENT RESPONSIBILITIES:
- Authorized signatory privileges for company documents
- Team leadership and performance management duties
- Budget oversight and resource allocation authority`,

            'Employee': `\n\nEMPLOYEE OBLIGATIONS:
- Adherence to company policies and procedures
- Professional development and training participation
- Collaborative teamwork and communication`,

            'Developer': `\n\nTECHNICAL RESPONSIBILITIES:
- Code quality standards and best practices
- Intellectual property assignment for developed software
- Security protocols and data protection compliance`,

            'Contractor': `\n\nCONTRACTOR PROVISIONS:
- Independent contractor status clarification
- Deliverable specifications and timeline requirements
- Liability limitations and indemnification clauses`
        },
        'NDA': {
            'Manager': `\n\nMANAGEMENT NDA TERMS:
- Executive-level confidentiality obligations
- Strategic information protection requirements`,

            'Employee': `\n\nEMPLOYEE NDA TERMS:
- Standard confidentiality and non-disclosure provisions
- Return of confidential materials upon termination`
        }
    };

    const roleSpecific = aiClauses[this.selectedContractType]?.[this.selectedRole] || '';
    const regionSpecific = this.getRegionSpecificClauses();

    return roleSpecific + regionSpecific;
}

getRegionSpecificClauses() {
    const regionClauses = {
        'US': `\n\nUS COMPLIANCE PROVISIONS:
- At-will employment terms (where applicable)
- Equal Employment Opportunity compliance
- Americans with Disabilities Act adherence`,

        'EU': `\n\nEU COMPLIANCE PROVISIONS:
- GDPR data protection requirements
- European Working Time Directive compliance
- Cross-border data transfer provisions`,

        'APAC': `\n\nAPAC COMPLIANCE PROVISIONS:
- Local labor law compliance requirements
- Cultural sensitivity and diversity provisions`,

        'GLOBAL': `\n\nGLOBAL COMPLIANCE PROVISIONS:
- Multi-jurisdictional legal framework adherence
- International data transfer compliance
- Global HR policy alignment`
    };

    return regionClauses[this.selectedRegion] || '';
}

async validateCompliance() {
    // Simulated compliance validation rules
    const complianceRules = {
        'Employment': {
            'US': { requiredTerms: ['at-will', 'equal opportunity', 'confidentiality'], score: 95 },
            'EU': { requiredTerms: ['GDPR', 'working time', 'data protection'], score: 92 }
        },
        'NDA': {
            'US': { requiredTerms: ['confidentiality', 'return of materials'], score: 98 },
            'EU': { requiredTerms: ['GDPR', 'data protection'], score: 96 }
        }
    };

    const rules = complianceRules[this.selectedContractType]?.[this.selectedRegion];
    if (!rules) {
        return {
            isCompliant: true,
            score: 85,
            analysis: 'Basic compliance validation completed',
            violations: []
        };
    }

    // Check required terms
    const clauseText = this.generatedClause.toLowerCase();
    const missingTerms = rules.requiredTerms.filter(
        term => !clauseText.includes(term.toLowerCase())
    );
    const isCompliant = missingTerms.length === 0;

    this.complianceDetails = {
        complianceScore: rules.score - (missingTerms.length * 10),
        analysis: isCompliant
            ? `Document meets all ${this.selectedRegion} regulatory requirements for ${this.selectedContractType} agreements.`
            : `Document requires review for ${this.selectedRegion} compliance standards.`,
        violations: missingTerms.map(term => `Missing required term: "${term}"`)
    };

    return {
        isCompliant,
        score: this.complianceDetails.complianceScore,
        analysis: this.complianceDetails.analysis,
        violations: this.complianceDetails.violations
    };
}

generateDocumentContent() {
    return `
GENERATED DOCUMENT
===================
Document ID: ${this.documentId}
Contract Type: ${this.selectedContractType}
Region: ${this.selectedRegion}
Role: ${this.selectedRole}
Generated Date: ${new Date().toLocaleDateString()}
AI Processing: ${this.aiProcessingEnabled ? 'Enabled' : 'Disabled'}

DOCUMENT CONTENT:
==================
${this.generatedClause}

SIGNATURE INFORMATION:
=======================
Signer Name: ${this.signerName}
Signer Email: ${this.signerEmail}
Signature Request ID: ${this.signatureRequestId}
Status: ${this.signatureRequestId ? 'Pending Signature' : 'Draft'}
${this.signatureInstructions ? `Instructions: ${this.signatureInstructions}` : ''}

COMPLIANCE STATUS:
==================
Status: ${this.complianceStatus?.isCompliant ? 'Compliant' : 'Requires Review'}
Score: ${this.complianceDetails?.complianceScore || 'N/A'}%
Analysis: ${this.complianceDetails?.analysis || 'No analysis available'}
${this.complianceDetails?.violations?.length > 0 
    ? `Violations: ${this.complianceDetails.violations.join(', ')}` 
    : ''} 
`;
}

resetGenerationData() {
    this.generatedClause = '';
    this.complianceStatus = null;
    this.complianceDetails = null;
    this.documentId = '';
    this.signatureRequestId = '';
    this.emailSentStatus = false;
}

resetComponent() {
    // Reset all form data
    this.currentStep = 1;
    this.selectedRegion = '';
    this.selectedRole = '';
    this.selectedContractType = '';
    this.additionalRequirements = '';
    this.aiProcessingEnabled = true;
    this.signerEmail = '';
    this.signerName = '';
    this.signatureInstructions = '';
    this.selectedSignatureOptions = [];

    this.resetGenerationData();
    this.clearError();
}

// Utility Methods
delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

showSuccessToast(message) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        })
    );
}

showErrorToast(message) {
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        })
    );
}
