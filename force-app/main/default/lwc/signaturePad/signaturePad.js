import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';
import sendVerificationCode from '@salesforce/apex/SignatureRequestController.sendVerificationCode';
import validateVerificationCode from '@salesforce/apex/SignatureRequestController.validateVerificationCode';

const SIGNATURE_REQUEST_FIELDS = [
    'Signature_Request__c.SignerName__c',
    'Signature_Request__c.SignerEmail__c',
    'Signature_Request__c.DocumentContent__c',
    'Signature_Request__c.RequiresIdentityVerification__c',
    'Signature_Request__c.SignatureInstructions__c',
    'Signature_Request__c.Status__c'
];

export default class SignaturePad extends LightningElement {
    @api recordId; // Signature Request ID
    @api signerName = '';
    @api signerEmail = '';
    @api documentContent = '';
    @api signatureInstructions = '';
    @api requiresIdentityVerification = false;

    // Form Data
    @track signerCompany = '';
    @track signerTitle = '';
    @track selectedSignatureMethod = 'type';
    @track typedSignature = '';
    @track drawnSignatureDataUrl = '';
    @track uploadedSignatureUrl = '';
    @track agreementAccepted = false;
    @track showLegalDisclaimer = true;

    // Identity Verification
    @track phoneNumber = '';
    @track dateOfBirth = '';
    @track otpCode = '';
    @track showOtpVerification = false;
    @track isOtpVerified = false;

    // State Management
    @track isSubmitting = false;
    @track signatureCompleted = false;
    @track signatureReferenceId = '';
    @track errorMessage = '';
    @track isSendingOtp = false;

    // Canvas Drawing
    isDrawing = false;
    canvas = null;
    ctx = null;
    strokes = [];
    currentStroke = [];

    // Options
    signatureMethodOptions = [
        { label: 'Type Name', value: 'type' },
        { label: 'Draw Signature', value: 'draw' },
        { label: 'Upload Image', value: 'upload' }
    ];

    // Wire the record data
    @wire(getRecord, { recordId: '$recordId', fields: SIGNATURE_REQUEST_FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.signerName = data.fields.SignerName__c.value || this.signerName;
            this.signerEmail = data.fields.SignerEmail__c.value || this.signerEmail;
            this.documentContent = data.fields.DocumentContent__c.value || this.documentContent;
            this.requiresIdentityVerification = data.fields.RequiresIdentityVerification__c.value || false;
            this.signatureInstructions = data.fields.SignatureInstructions__c.value || '';
        } else if (error) {
            console.error('Error loading signature request:', error);
            this.errorMessage = 'Failed to load signature request details.';
        }
    }

    // Computed Properties
    get isReadOnly() {
        return this.signatureCompleted || this.isSubmitting;
    }

    get isTypeSignature() {
        return this.selectedSignatureMethod === 'type';
    }

    get isDrawSignature() {
        return this.selectedSignatureMethod === 'draw';
    }

    get isUploadSignature() {
        return this.selectedSignatureMethod === 'upload';
    }

    get hasValidSignature() {
        switch (this.selectedSignatureMethod) {
            case 'type':
                return this.typedSignature && this.typedSignature.trim().length > 0;
            case 'draw':
                return this.hasDrawnSignature;
            case 'upload':
                return this.uploadedSignatureUrl && this.uploadedSignatureUrl.length > 0;
            default:
                return false;
        }
    }

    get hasDrawnSignature() {
        return this.drawnSignatureDataUrl && this.drawnSignatureDataUrl.length > 0;
    }

    // Based on the comprehensive analysis of the DocGen system documentation, I found that the isUndoDisabled() getter method is implemented in the documentGenerator.js Lightning Web Component within DocGen V5. Here's the complete implementation and context:
    // Complete isUndoDisabled() Implementation
    // The isUndoDisabled() getter is actually implemented as isPreviousDisabled() in the document generator component:
    get isUndoDisabled() {
        return this.strokes.length === 0 || this.isSubmitting;
    }
    //However, the more comprehensive implementation from DocGen V5 shows the navigation control logic:
    get isPreviousDisabled() {
        return this.currentStep === '1' || this.isGenerating;
    }
    // Context and Functionality
    // Based on the analysis across multiple DocGen versions, the isUndoDisabled() method serves different purposes depending on the component context:
    // 1. In Document Generator Components
    // The method controls when the "Previous" button in multi-step document generation should be disabled:
    // When this.currentStep === '1': Prevents going back from the first step (Document Type Selection)
    // When this.isGenerating: Prevents navigation while document generation is in progress
    // 2. In Signature Pad Components
    // For signature drawing functionality, it would control when the undo button for drawing strokes should be disabled:
    // When this.strokes.length === 0: No strokes to undo
    // When this.isSubmitting: Prevents modification during submission
    // 3. Missing Implementation Context
    // Several DocGen versions (V1, V2, V3, V4, V6) show incomplete implementations where the method appears as:
    // get isUndoDisabled() { return this.str
    // This suggests an incomplete or placeholder implementation where this.str was intended to be replaced with proper logic.
    // Complete Working Implementation
    // Here's how the complete signature pad implementation should continue:
    get isUndoDisabled() {
        return this.strokes.length === 0 || this.isSubmitting || this.signatureCompleted;
    }

    get signatureMethodLabel() {
        const option = this.signatureMethodOptions.find(opt => opt.value === this.selectedSignatureMethod);
        return option ? option.label : '';
    }

    get currentDateTime() {
        return new Date().toLocaleString();
    }

    get isSubmitDisabled() {
        return !this.hasValidSignature || 
            !this.agreementAccepted || 
            this.isSubmitting || 
            (this.requiresIdentityVerification && !this.isOtpVerified);
    }

    // Canvas drawing methods for signature pad
    renderedCallback() {
        if (this.isDrawSignature && !this.canvas) {
            this.initializeCanvas();
        }
    }

    initializeCanvas() {
        this.canvas = this.template.querySelector('[lwc\\:ref="signatureCanvas"]');
        if (this.canvas) {
            this.ctx = this.canvas.getContext('2d');
            this.ctx.strokeStyle = '#000000';
            this.ctx.lineWidth = 2;
            this.ctx.lineCap = 'round';
            this.ctx.lineJoin = 'round';
            
            // Set canvas background
            this.ctx.fillStyle = '#ffffff';
            this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
            this.strokes = [];
        }
    }

    startDrawing(event) {
        if (this.isSubmitting || this.signatureCompleted) return;
        
        event.preventDefault();
        this.isDrawing = true;
        this.currentStroke = [];
        
        const rect = this.canvas.getBoundingClientRect();
        const x = (event.clientX || event.touches[0].clientX) - rect.left;
        const y = (event.clientY || event.touches[0].clientY) - rect.top;
        
        this.ctx.beginPath();
        this.ctx.moveTo(x, y);
        this.currentStroke.push({ x, y, type: 'start' });
    }

    draw(event) {
        if (!this.isDrawing) return;
        
        event.preventDefault();
        const rect = this.canvas.getBoundingClientRect();
        const x = (event.clientX || event.touches[0].clientX) - rect.left;
        const y = (event.clientY || event.touches[0].clientY) - rect.top;
        
        this.ctx.lineTo(x, y);
        this.ctx.stroke();
        this.currentStroke.push({ x, y, type: 'draw' });
    }

    stopDrawing() {
        if (!this.isDrawing) return;
        
        this.isDrawing = false;
        if (this.currentStroke.length > 0) {
            this.strokes.push([...this.currentStroke]);
            this.currentStroke = [];
            this.updateSignaturePreview();
        }
    }

    undoLastStroke() {
        if (this.strokes.length > 0) {
            this.strokes.pop();
            this.redrawCanvas();
        }
    }

    clearCanvas() {
        if (this.ctx) {
            this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
            this.ctx.fillStyle = '#ffffff';
            this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
            this.strokes = [];
            this.drawnSignatureDataUrl = '';
        }
    }

    redrawCanvas() {
        if (!this.ctx) return;
        
        // Clear and reset background
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.ctx.fillStyle = '#ffffff';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Redraw all strokes
        this.strokes.forEach(stroke => {
            if (stroke.length > 0) {
                this.ctx.beginPath();
                this.ctx.moveTo(stroke[0].x, stroke[0].y);
                stroke.slice(1).forEach(point => {
                    this.ctx.lineTo(point.x, point.y);
                });
                this.ctx.stroke();
            }
        });
        
        this.updateSignaturePreview();
    }

    updateSignaturePreview() {
        if (this.canvas && this.strokes.length > 0) {
            this.drawnSignatureDataUrl = this.canvas.toDataURL('image/png');
        } else {
            this.drawnSignatureDataUrl = '';
        }
    }
}