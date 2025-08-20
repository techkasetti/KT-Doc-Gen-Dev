import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';

export default class SignaturePad extends LightningElement {
    @api requestId;
    
    @track selectedMethod = 'draw';
    @track typedSignature = '';
    @track uploadedSignatureUrl = '';
    @track signerName = '';
    @track signerEmail = '';
    @track signingDate = '';
    @track additionalNotes = '';
    @track signatureCompleted = false;
    @track signatureReferenceId = '';
    
    // Canvas drawing properties
    @track hasDrawnSignature = false;
    isDrawing = false;
    canvasContext;
    signatureData = '';

    signatureMethodOptions = [
        { label: 'Draw Signature', value: 'draw' },
        { label: 'Type Signature', value: 'type' },
        { label: 'Upload Image', value: 'upload' }
    ];

    connectedCallback() {
        // Set default signing date to today
        this.signingDate = new Date().toISOString().split('T')[0];
    }

    renderedCallback() {
        if (this.selectedMethod === 'draw' && !this.canvasContext) {
            this.initializeCanvas();
        }
    }

    // Computed properties
    get isDrawMethod() {
        return this.selectedMethod === 'draw';
    }

    get isTypeMethod() {
        return this.selectedMethod === 'type';
    }

    get isUploadMethod() {
        return this.selectedMethod === 'upload';
    }

    get isSignatureComplete() {
        return this.hasSignatureData() && this.signerName && this.signerEmail && this.signingDate;
    }

    // Event handlers
    handleMethodChange(event) {
        this.selectedMethod = event.detail.value;
        this.clearAllSignatures();
    }

    handleTypedSignatureChange(event) {
        this.typedSignature = event.detail.value;
    }

    handleSignerNameChange(event) {
        this.signerName = event.detail.value;
    }

    handleSignerEmailChange(event) {
        this.signerEmail = event.detail.value;
    }

    handleSigningDateChange(event) {
        this.signingDate = event.detail.value;
    }

    handleAdditionalNotesChange(event) {
        this.additionalNotes = event.detail.value;
    }

    // Canvas methods
    initializeCanvas() {
        const canvas = this.template.querySelector('canvas[lwc\\:ref="signatureCanvas"]');
        if (canvas) {
            this.canvasContext = canvas.getContext('2d');
            this.canvasContext.strokeStyle = '#000000';
            this.canvasContext.lineWidth = 2;
            this.canvasContext.lineCap = 'round';
            
            // Set canvas background
            this.canvasContext.fillStyle = '#ffffff';
            this.canvasContext.fillRect(0, 0, canvas.width, canvas.height);
        }
    }

    startDrawing(event) {
        if (this.selectedMethod !== 'draw') return;
        
        this.isDrawing = true;
        const rect = event.target.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        
        this.canvasContext.beginPath();
        this.canvasContext.moveTo(x, y);
    }

    draw(event) {
        if (!this.isDrawing || this.selectedMethod !== 'draw') return;
        
        const rect = event.target.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        
        this.canvasContext.lineTo(x, y);
        this.canvasContext.stroke();
        this.hasDrawnSignature = true;
    }

    stopDrawing() {
        this.isDrawing = false;
    }

    clearCanvas() {
        const canvas = this.template.querySelector('canvas[lwc\\:ref="signatureCanvas"]');
        if (canvas && this.canvasContext) {
            this.canvasContext.clearRect(0, 0, canvas.width, canvas.height);
            this.canvasContext.fillStyle = '#ffffff';
            this.canvasContext.fillRect(0, 0, canvas.width, canvas.height);
            this.hasDrawnSignature = false;
        }
    }

    saveDrawnSignature() {
        const canvas = this.template.querySelector('canvas[lwc\\:ref="signatureCanvas"]');
        if (canvas) {
            this.signatureData = canvas.toDataURL('image/png');
            this.showToast('Success', 'Drawn signature saved', 'success');
        }
    }

    saveTypedSignature() {
        this.signatureData = `TYPED_SIGNATURE:${this.typedSignature}`;
        this.showToast('Success', 'Typed signature saved', 'success');
    }

    handleFileUpload(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                this.uploadedSignatureUrl = e.target.result;
            };
            reader.readAsDataURL(file);
        }
    }

    saveUploadedSignature() {
        this.signatureData = this.uploadedSignatureUrl;
        this.showToast('Success', 'Uploaded signature saved', 'success');
    }

    // Final signature submission
    handleCompleteSignature() {
        if (!this.isSignatureComplete) {
            this.showToast('Error', 'Please complete all required fields', 'error');
            return;
        }

        const signerInfo = JSON.stringify({
            name: this.signerName,
            email: this.signerEmail,
            date: this.signingDate,
            notes: this.additionalNotes,
            method: this.selectedMethod,
            timestamp: new Date().toISOString(),
            ipAddress: 'CLIENT_IP' // Would be captured server-side
        });

        submitSignature({
            requestId: this.requestId,
            signatureData: this.signatureData,
            signerInfo: signerInfo
        }).then(result => {
            if (result) {
                this.signatureCompleted = true;
                this.signatureReferenceId = this.requestId;
                this.showToast('Success', 'Signature submitted successfully!', 'success');
                
                // Fire custom event to parent component
                this.dispatchEvent(new CustomEvent('signaturecomplete', {
                    detail: { requestId: this.requestId, success: true }
                }));
            }
        }).catch(error => {
            this.showToast('Error', 'Failed to submit signature: ' + error.body?.message, 'error');
        });
    }

    handleCancel() {
        // Fire cancel event to parent component
        this.dispatchEvent(new CustomEvent('signaturecancel'));
    }

    // Utility methods
    hasSignatureData() {
        return this.signatureData && this.signatureData.length > 0;
    }

clearAllSignatures() {
    this.typedSignature = '';
    this.uploadedSignatureUrl = '';
    this.signatureData = '';
    this.hasDrawnSignature = false;
    this.signatureCompleted = false;
    this.signatureReferenceId = '';
    
    // Clear canvas if it exists
    if (this.canvasContext) {
        this.clearCanvas();
    }
    
    // Reset file input
    const fileInput = this.template.querySelector('lightning-input[type="file"]');
    if (fileInput) {
        fileInput.value = '';
    }
}

showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
    }));
}
}
