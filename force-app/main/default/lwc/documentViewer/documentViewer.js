import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSignatureRequests from '@salesforce/apex/SignatureRequestController.getSignatureRequests';
import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

export default class DocumentViewer extends LightningElement {
    @api recordId; // Document record ID
    @api documentTitle = 'Document Preview';
    @api documentContent = '';
    @api documentStatus = 'Draft';
    @api showAIAnalysis = true;
    @api allowSignatureRequest = true;

    @track isLoading = false;
    @track errorMessage = '';
    @track createdDate = '';
    @track aiAnalysisLoading = false;
    
    // AI Analysis Data
    @track complianceScore = 85;
    @track riskLevel = 'Low';
    @track issuesFound = 2;
    @track keyInsights = [];
    @track recommendations = [];

    // Signature data
    @track signatureRequests = [];
    wiredSignatureRequests;

    connectedCallback() {
        this.initializeComponent();
        this.loadAIAnalysis();
    }

    renderedCallback() {
        this.renderDocumentContent();
    }

    @wire(getSignatureRequests, { documentId: '$recordId' })
    wiredGetSignatureRequests(result) {
        this.wiredSignatureRequests = result;
        if (result.data) {
            this.signatureRequests = result.data.map(request => ({
                ...request,
                StatusVariant: this.getStatusVariant(request.Status__c),
                RequestDate__c: this.formatDate(request.RequestDate__c),
                CompletedDate__c: request.CompletedDate__c ? this.formatDate(request.CompletedDate__c) : null
            }));
        } else if (result.error) {
            this.errorMessage = 'Failed to load signature requests: ' + result.error.body?.message;
        }
    }

    // Computed Properties
    get statusVariant() {
        switch(this.documentStatus) {
            case 'Draft': return 'warning';
            case 'Pending Signature': return 'info';
            case 'Signed': return 'success';
            case 'Expired': return 'error';
            default: return 'info';
        }
    }

    // Initialization Methods
    initializeComponent() {
        this.createdDate = new Date().toLocaleDateString();
        this.setupMockData(); // In real implementation, load from Salesforce
    }

    setupMockData() {
        // Mock document content - in real implementation, load from ContentVersion or custom object
        if (!this.documentContent) {
            this.documentContent = `
                <div class="document-content">
                    <h2>Employment Agreement</h2>
                    <p><strong>Employee:</strong> John Doe</p>
                    <p><strong>Position:</strong> Senior Developer</p>
                    <p><strong>Start Date:</strong> January 1, 2024</p>
                    
                    <h3>Terms and Conditions</h3>
                    <p>This agreement establishes US employment law compliant terms. The authorized signatory agrees to employment terms and conditions including:</p>
                    
                    <ul>
                        <li>Compensation and benefits as outlined in Schedule A</li>
                        <li>Confidentiality obligations during and after employment</li>
                        <li>Intellectual property assignments</li>
                        <li>At-will employment provisions</li>
                    </ul>
                    
                    <p>This document complies with applicable federal and state employment laws.</p>
                </div>
            `;
        }
    }

    async loadAIAnalysis() {
        if (!this.showAIAnalysis) return;

        this.aiAnalysisLoading = true;
        try {
            // Simulate AI analysis call
            await this.delay(2000);
            
            this.keyInsights = [
                {
                    id: '1',
                    message: 'Document contains all required employment law clauses',
                    icon: 'utility:success',
                    variant: 'success'
                },
                {
                    id: '2',
                    message: 'GDPR compliance clauses detected for EU operations',
                    icon: 'utility:info',
                    variant: 'info'
                },
                {
                    id: '3',
                    message: 'At-will employment clause properly structured',
                    icon: 'utility:check',
                    variant: 'success'
                }
            ];

            this.recommendations = [
                {
                    id: '1',
                    priority: 'High',
                    priorityVariant: 'error',
                    text: 'Consider adding specific termination notice period clause',
                    action: true,
                    actionLabel: 'Add Clause',
                    actionHandler: this.handleAddClause
                },
                {
                    id: '2',
                    priority: 'Medium',
                    priorityVariant: 'warning',
                    text: 'Review compensation structure for market competitiveness',
                    action: false
                }
            ];

        } catch (error) {
            console.error('AI Analysis failed:', error);
        } finally {
            this.aiAnalysisLoading = false;
        }
    }

    renderDocumentContent() {
        const documentDiv = this.template.querySelector('.document-text');
        if (documentDiv && this.documentContent) {
            documentDiv.innerHTML = this.documentContent;
        }
    }

    // Event Handlers
    async handleDownload() {
        this.isLoading = true;
        try {
            // In real implementation, generate and download PDF
            await this.delay(1000);
            this.showToast('Success', 'Document download started', 'success');
        } catch (error) {
            this.showToast('Error', 'Download failed: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleSignatureRequest() {
        try {
            const signerEmail = await this.promptForSignerEmail();
            const signerName = await this.promptForSignerName();

            if (signerEmail && signerName) {
                this.isLoading = true;
                
                const requestId = await initiateSignatureRequest({
                    documentId: this.recordId,
                    signerEmail: signerEmail,
                    signerName: signerName
                });

                this.showToast('Success', `Signature request sent to ${signerEmail}`, 'success');
                
                // Refresh signature requests
                refreshApex(this.wiredSignatureRequests);
            }
        } catch (error) {
            this.showToast('Error', 'Failed to send signature request: ' + error.body?.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleResendSignature(event) {
        const requestId = event.target.dataset.requestId;
        // In real implementation, call Apex method to resend signature request
        this.showToast('Info', 'Signature request resent', 'info');
    }

    handleAddClause(event) {
        // In real implementation, open clause addition modal/component
        this.showToast('Info', 'Clause addition feature - to be implemented', 'info');
    }

    // Utility Methods
    getStatusVariant(status) {
        switch(status) {
            case 'Draft': return 'warning';
            case 'Sent': return 'info';
            case 'Signed': return 'success';
            case 'Expired': return 'error';
            default: return 'info';
        }
    }

    formatDate(dateString) {
        if (!dateString) return '';
        return new Date(dateString).toLocaleDateString();
    }

    async promptForSignerEmail() {
        // In real implementation, use a modal or input dialog
        // For demo, using browser prompt
        return prompt('Enter signer email:');
    }

    async promptForSignerName() {
        // In real implementation, use a modal or input dialog
        // For demo, using browser prompt
        return prompt('Enter signer name:');
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}
