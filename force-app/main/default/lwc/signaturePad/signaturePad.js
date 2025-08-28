
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




// version 5
// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';

// export default class SignaturePad extends LightningElement {
//     // Public API properties
//     @api requestId;
//     @api signerName;
//     @api documentTitle;

//     // Reactive properties
//     @track selectedMethod = 'type';
//     @track typedSignature = '';
//     @track drawnSignatureUrl = '';
//     @track uploadedSignatureUrl = '';
//     @track confirmationChecked = false;
//     @track isLoading = false;
//     @track errorMessage = '';
//     @track signerIP = '';
//     @track currentDate = '';

//     // Canvas drawing state
//     isDrawing = false;
//     isCanvasEmpty = true;
//     canvasContext;

//     // Signature method options
//     signatureMethodOptions = [
//         { label: 'Type Your Name', value: 'type' },
//         { label: 'Draw Signature', value: 'draw' },
//         { label: 'Upload Image', value: 'upload' }
//     ];

//     // Lifecycle hooks
//     connectedCallback() {
//         this.currentDate = new Date().toLocaleDateString();
//         this.getClientIP();
//     }

//     renderedCallback() {
//         if (this.isDrawMethod && !this.canvasContext) {
//             this.initializeCanvas();
//         }
//     }

//     // Computed properties
//     get isTypeMethod() { return this.selectedMethod === 'type'; }
//     get isDrawMethod() { return this.selectedMethod === 'draw'; }
//     get isUploadMethod() { return this.selectedMethod === 'upload'; }

//     get hasSignature() {
//         return (this.isTypeMethod && this.typedSignature) ||
//                (this.isDrawMethod && this.drawnSignatureUrl) ||
//                (this.isUploadMethod && this.uploadedSignatureUrl);
//     }

//     get cannotCreateSignature() {
//         if (this.isTypeMethod) return !this.typedSignature;
//         if (this.isDrawMethod) return this.isCanvasEmpty;
//         if (this.isUploadMethod) return !this.uploadedSignatureUrl;
//         return true;
//     }

//     get cannotSubmit() {
//         return !this.confirmationChecked || this.isLoading;
//     }

//     get selectedMethodLabel() {
//         const option = this.signatureMethodOptions.find(opt => opt.value === this.selectedMethod);
//         return option ? option.label : '';
//     }

//     // Event handlers
//     handleMethodChange(event) {
//         this.selectedMethod = event.detail.value;
//         this.resetSignatureData();
//     }

//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.detail.value;
//     }

//     handleConfirmationChange(event) {
//         this.confirmationChecked = event.detail.checked;
//     }

//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles && uploadedFiles.length > 0) {
//             this.uploadedSignatureUrl = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     // Canvas methods
//     initializeCanvas() {
//         const canvas = this.template.querySelector('canvas');
//         if (canvas) {
//             this.canvasContext = canvas.getContext('2d');
//             this.canvasContext.strokeStyle = '#000000';
//             this.canvasContext.lineWidth = 2;
//             this.canvasContext.lineCap = 'round';
//         }
//     }

//     startDrawing(event) {
//         this.isDrawing = true;
//         const rect = event.target.getBoundingClientRect();
//         const x = event.clientX - rect.left;
//         const y = event.clientY - rect.top;

//         this.canvasContext.beginPath();
//         this.canvasContext.moveTo(x, y);
//         this.isCanvasEmpty = false;
//     }

//     draw(event) {
//         if (!this.isDrawing) return;
//         const rect = event.target.getBoundingClientRect();
//         const x = event.clientX - rect.left;
//         const y = event.clientY - rect.top;

//         this.canvasContext.lineTo(x, y);
//         this.canvasContext.stroke();
//     }

//     stopDrawing() {
//         this.isDrawing = false;
//     }

//     startDrawingTouch(event) {
//         event.preventDefault();
//         const touch = event.touches[0];
//         const rect = event.target.getBoundingClientRect();
//         const x = touch.clientX - rect.left;
//         const y = touch.clientY - rect.top;

//         this.isDrawing = true;
//         this.canvasContext.beginPath();
//         this.canvasContext.moveTo(x, y);
//         this.isCanvasEmpty = false;
//     }

//     drawTouch(event) {
//         if (!this.isDrawing) return;
//         event.preventDefault();
//         const touch = event.touches[0];
//         const rect = event.target.getBoundingClientRect();
//         const x = touch.clientX - rect.left;
//         const y = touch.clientY - rect.top;

//         this.canvasContext.lineTo(x, y);
//         this.canvasContext.stroke();
//     }

//     clearCanvas() {
//         const canvas = this.template.querySelector('canvas');
//         if (canvas) {
//             this.canvasContext.clearRect(0, 0, canvas.width, canvas.height);
//         }
//         this.isCanvasEmpty = true;
//         this.drawnSignatureUrl = '';
//     }

//     finishDrawing() {
//         const canvas = this.template.querySelector('canvas');
//         this.drawnSignatureUrl = canvas.toDataURL();
//     }

//     // Signature creation
//     createSignature() {
//         if (this.isTypeMethod && this.typedSignature) {
//             this.createTypedSignatureImage();
//         }
//     }

//     createTypedSignatureImage() {
//         const tempCanvas = document.createElement('canvas');
//         tempCanvas.width = 400;
//         tempCanvas.height = 100;
//         const ctx = tempCanvas.getContext('2d');

//         ctx.font = '30px Brush Script MT, cursive';
//         ctx.fillStyle = '#000000';
//         ctx.textAlign = 'center';
//         ctx.textBaseline = 'middle';
//         ctx.fillText(this.typedSignature, tempCanvas.width / 2, tempCanvas.height / 2);

//         this.drawnSignatureUrl = tempCanvas.toDataURL();
//     }

//     // Signature submission
//     async submitSignature() {
//         this.isLoading = true;
//         this.errorMessage = '';

//         try {
//             const signatureData = this.getSignatureData();
//             const signerInfo = JSON.stringify({
//                 signerName: this.signerName,
//                 signatureMethod: this.selectedMethod,
//                 ipAddress: this.signerIP,
//                 timestamp: new Date().toISOString(),
//                 confirmed: this.confirmationChecked
//             });

//             const result = await submitSignature({
//                 requestId: this.requestId,
//                 signatureData,
//                 signerInfo
//             });

//             if (result) {
//                 this.showToast('Success', 'Signature submitted successfully!', 'success');
//                 this.dispatchEvent(new CustomEvent('signaturecomplete', {
//                     detail: { requestId: this.requestId, signatureData }
//                 }));
//             }

//         } catch (error) {
//             this.errorMessage = 'Failed to submit signature: ' + (error.body?.message || error.message);
//             this.showToast('Error', this.errorMessage, 'error');
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     getSignatureData() {
//         switch (this.selectedMethod) {
//             case 'type': return `data:text/plain;base64,${btoa(this.typedSignature)}`;
//             case 'draw': return this.drawnSignatureUrl;
//             case 'upload': return this.uploadedSignatureUrl;
//             default: return '';
//         }
//     }

//     // Reset methods
//     resetSignature() {
//         this.resetSignatureData();
//         this.confirmationChecked = false;
//     }

//     resetSignatureData() {
//         this.typedSignature = '';
//         this.drawnSignatureUrl = '';
//         this.uploadedSignatureUrl = '';
//         this.isCanvasEmpty = true;

//         if (this.canvasContext) {
//             const canvas = this.template.querySelector('canvas');
//             if (canvas) this.canvasContext.clearRect(0, 0, canvas.width, canvas.height);
//         }
//     }

//     // Utility methods
//     async getClientIP() {
//         this.signerIP = '192.168.1.100';
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }
// }



// version 3

// import { LightningElement, api, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';
// import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';

// export default class SignaturePad extends LightningElement {
//     @api requestId;
//     @api recordId;

//     @track selectedMethod = 'type';
//     @track typedSignature = '';
//     @track signerEmail = '';
//     @track signerName = '';
//     @track signerCompany = '';
//     @track signerTitle = '';
//     @track termsAccepted = false;
//     @track isLoading = false;
//     @track showSignaturePreview = false;
//     @track drawnSignatureData = '';
//     @track uploadedSignature = '';
//     @track documentTitle = '';
//     @track documentPreview = '';
//     @track showDocumentPreview = true;

//     // Canvas drawing variables
//     isDrawing = false;
//     canvas;
//     ctx;
//     lastX = 0;
//     lastY = 0;

//     // Getter: Signature method options
//     get signatureMethodOptions() {
//         return [
//             { label: 'Type Name', value: 'type' },
//             { label: 'Draw Signature', value: 'draw' },
//             { label: 'Upload Image', value: 'upload' }
//         ];
//     }

//     get isTypeMethod() {
//         return this.selectedMethod === 'type';
//     }

//     get isDrawMethod() {
//         return this.selectedMethod === 'draw';
//     }

//     get isUploadMethod() {
//         return this.selectedMethod === 'upload';
//     }

//     get isSubmitDisabled() {
//         return !this.termsAccepted ||
//                !this.signerEmail ||
//                !this.signerName ||
//                !this.hasValidSignature ||
//                this.isLoading;
//     }

//     get hasValidSignature() {
//         switch (this.selectedMethod) {
//             case 'type':
//                 return this.typedSignature.trim().length > 0;
//             case 'draw':
//                 return this.drawnSignatureData.length > 0;
//             case 'upload':
//                 return this.uploadedSignature.length > 0;
//             default:
//                 return false;
//         }
//     }

//     get isCanvasEmpty() {
//         return !this.drawnSignatureData;
//     }

//     get currentDateTime() {
//         return new Date().toLocaleString();
//     }

//     // Lifecycle hooks
//     connectedCallback() {
//         this.loadSignatureRequest();
//     }

//     async loadSignatureRequest() {
//         if (this.requestId) {
//             try {
//                 const requestData = await getSignatureRequest({ requestId: this.requestId });
//                 this.documentTitle = requestData.documentTitle;
//                 this.signerEmail = requestData.signerEmail;
//             } catch (error) {
//                 console.error('Error loading signature request:', error);
//                 this.showToast('Error', 'Failed to load signature request details', 'error');
//             }
//         }
//     }

//     renderedCallback() {
//         if (this.selectedMethod === 'draw' && !this.canvas) {
//             this.initializeCanvas();
//         }
//     }

//     // Canvas initialization
//     initializeCanvas() {
//         this.canvas = this.template.querySelector('.signature-canvas');
//         if (this.canvas) {
//             this.ctx = this.canvas.getContext('2d');
//             this.ctx.strokeStyle = '#001f3f';
//             this.ctx.lineWidth = 2;
//             this.ctx.lineCap = 'round';
//             this.ctx.lineJoin = 'round';
//         }
//     }

//     // Event handlers
//     handleMethodChange(event) {
//         this.selectedMethod = event.detail.value;
//         this.showSignaturePreview = false;
//         this.drawnSignatureData = '';
//         this.uploadedSignature = '';

//         if (this.selectedMethod === 'draw') {
//             setTimeout(() => {
//                 this.initializeCanvas();
//             }, 100);
//         }
//     }

//     handleTypedSignatureChange(event) {
//         this.typedSignature = event.target.value;
//         this.updateSignaturePreview();
//     }

//     handleSignerEmailChange(event) {
//         this.signerEmail = event.target.value;
//     }

//     handleSignerNameChange(event) {
//         this.signerName = event.target.value;
//     }

//     handleSignerCompanyChange(event) {
//         this.signerCompany = event.target.value;
//     }

//     handleSignerTitleChange(event) {
//         this.signerTitle = event.target.value;
//     }

//     handleTermsChange(event) {
//         this.termsAccepted = event.target.checked;
//     }

//     // Canvas drawing methods
//     handleMouseDown(event) {
//         this.startDrawing(event.offsetX, event.offsetY);
//     }

//     handleMouseMove(event) {
//         if (this.isDrawing) {
//             this.draw(event.offsetX, event.offsetY);
//         }
//     }

//     handleMouseUp() {
//         this.stopDrawing();
//     }

//     handleTouchStart(event) {
//         event.preventDefault();
//         const rect = this.canvas.getBoundingClientRect();
//         const touch = event.touches[0];
//         this.startDrawing(touch.clientX - rect.left, touch.clientY - rect.top);
//     }

//     handleTouchMove(event) {
//         if (this.isDrawing) {
//             event.preventDefault();
//             const rect = this.canvas.getBoundingClientRect();
//             const touch = event.touches[0];
//             this.draw(touch.clientX - rect.left, touch.clientY - rect.top);
//         }
//     }

//     handleTouchEnd(event) {
//         event.preventDefault();
//         this.stopDrawing();
//     }

//     startDrawing(x, y) {
//         this.isDrawing = true;
//         this.lastX = x;
//         this.lastY = y;
//         this.ctx.beginPath();
//         this.ctx.moveTo(x, y);
//     }

//     draw(x, y) {
//         if (!this.isDrawing) return;
//         this.ctx.lineTo(x, y);
//         this.ctx.stroke();
//         this.lastX = x;
//         this.lastY = y;
//     }

//     stopDrawing() {
//         if (!this.isDrawing) return;
//         this.isDrawing = false;
//         this.updateCanvasSignature();
//     }

//     clearCanvas() {
//         this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
//         this.drawnSignatureData = '';
//         this.showSignaturePreview = false;
//     }

//     previewSignature() {
//         this.updateCanvasSignature();
//         this.updateSignaturePreview();
//     }

//     // ===== Additional Methods =====
//     updateCanvasSignature() {
//         if (this.canvas) {
//             this.drawnSignatureData = this.canvas.toDataURL('image/png');
//         }
//     }

//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles.length > 0) {
//             // Placeholder URL for uploaded file
//             this.uploadedSignature = '/path/to/uploaded/signature';
//             this.updateSignaturePreview();
//             this.showToast('Success', 'Signature uploaded successfully', 'success');
//         }
//     }

//     updateSignaturePreview() {
//         this.showSignaturePreview = true;
//     }

//     async handleSubmitSignature() {
//         this.isLoading = true;
//         try {
//             const signatureData = this.getSignatureData();
//             const signerInfo = JSON.stringify({
//                 signatureMethod: this.selectedMethod,
//                 signerName: this.signerName,
//                 signerEmail: this.signerEmail,
//                 signerCompany: this.signerCompany,
//                 signerTitle: this.signerTitle,
//                 timestamp: new Date().toISOString(),
//                 termsAccepted: this.termsAccepted
//             });

//             await submitSignature({
//                 requestId: this.requestId,
//                 signatureData: signatureData,
//                 signerInfo: signerInfo
//             });

//             this.showToast('Success', 'Signature submitted successfully!', 'success');

//             this.dispatchEvent(
//                 new CustomEvent('signaturecomplete', { detail: { requestId: this.requestId } })
//             );

//         } catch (error) {
//             this.showToast('Error', 'Failed to submit signature: ' + error.body.message, 'error');
//             console.error('Signature submission error:', error);
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     getSignatureData() {
//         switch (this.selectedMethod) {
//             case 'type':
//                 return `data:text/plain;base64,${btoa(this.typedSignature)}`;
//             case 'draw':
//                 return this.drawnSignatureData;
//             case 'upload':
//                 return this.uploadedSignature;
//             default:
//                 return '';
//         }
//     }

//     handleCancel() {
//         this.dispatchEvent(new CustomEvent('cancel'));
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(
//             new ShowToastEvent({ title: title, message: message, variant: variant })
//         );
//     }
// }











// version 2


// import { LightningElement, api, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';
// import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';

// export default class SignaturePad extends LightningElement {
//     @api recordId; // Signature Request ID
//     @track documentTitle = '';
//     @track documentType = '';
//     @track documentContent = '';
//     @track selectedMethod = 'type';
//     @track typedSignature = '';
//     @track uploadedSignature = '';
//     @track signerEmail = '';
//     @track signatureDate = '';
//     @track hasConsent = false;
//     @track isLoading = false;

//     // Canvas drawing properties
//     canvas;
//     context;
//     isDrawing = false;
//     lastX = 0;
//     lastY = 0;

//     get signatureMethodOptions() {
//         return [
//             { label: 'Type Signature', value: 'type' },
//             { label: 'Draw Signature', value: 'draw' },
//             { label: 'Upload Image', value: 'upload' }
//         ];
//     }

//         get isTypeMethod() {
//         return this.selectedMethod === 'type';
//     }

//     get isDrawMethod() {
//         return this.selectedMethod === 'draw';
//     }

//     get isUploadMethod() {
//         return this.selectedMethod === 'upload';
//     }

//     get selectedMethodLabel() {
//         const method = this.signatureMethodOptions.find(opt => opt.value === this.selectedMethod);
//         return method ? method.label : '';
//     }

//     get isSignDisabled() {
//         return !this.hasValidSignature() || !this.signerEmail || !this.signatureDate || !this.hasConsent || this.isLoading;
//     }

//     connectedCallback() {
//         this.signatureDate = new Date().toISOString().split('T')[0];
//         this.loadSignatureRequest();
//     }

//     renderedCallback() {
//         if (this.isDrawMethod && !this.canvas) {
//             this.initializeCanvas();
//         }
//     }

//     loadSignatureRequest() {
//         if (this.recordId) {
//             getSignatureRequest({ requestId: this.recordId })
//                 .then(result => {
//                     this.documentTitle = result.DocumentTitle__c;
//                     this.documentType = result.DocumentType__c || 'Document';
//                     this.signerEmail = result.SignerEmail__c;
//                     this.documentContent = `<p>Please review and sign this ${this.documentType}.</p>`;
//                 })
//                 .catch(error => {
//                     console.error('Error loading signature request:', error);
//                     this.showToast('Error', 'Failed to load document details', 'error');
//                 });
//         }
//     }

//     initializeCanvas() {
//         this.canvas = this.template.querySelector('.signature-canvas');
//         if (this.canvas) {
//             this.context = this.canvas.getContext('2d');
//             this.context.strokeStyle = '#000000';
//             this.context.lineWidth = 2;
//             this.context.lineCap = 'round';
//         }
//     }

//     hasValidSignature() {
//         switch (this.selectedMethod) {
//             case 'type':
//                 return this.typedSignature && this.typedSignature.trim().length > 0;
//             case 'draw':
//                 return this.canvas && !this.isCanvasEmpty();
//             case 'upload':
//                 return this.uploadedSignature && this.uploadedSignature.length > 0;
//             default:
//                 return false;
//         }
//     }

//     isCanvasEmpty() {
//         if (!this.canvas || !this.context) return true;
        
//         const canvasData = this.context.getImageData(0, 0, this.canvas.width, this.canvas.height);
//         const pixelData = canvasData.data;
        
//         for (let i = 0; i < pixelData.length; i += 4) {
//             if (pixelData[i + 3] !== 0) { // Check alpha channel
//                 return false;
//             }
//         }
//         return true;
//     }

//     // Event Handlers
//     handleMethodChange(event) {
//         this.selectedMethod = event.detail.value;
        
//         // Clear previous signatures when method changes
//         this.typedSignature = '';
//         this.uploadedSignature = '';
//         if (this.canvas && this.context) {
//             this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
//         }
//     }

//     handleTypedSignature(event) {
//         this.typedSignature = event.detail.value;
//     }

//     handleUploadFinished(event) {
//         const uploadedFiles = event.detail.files;
//         if (uploadedFiles.length > 0) {
//             // In production, you'd get the actual file URL
//             this.uploadedSignature = '/sfc/servlet.shepherd/document/download/' + uploadedFiles[0].documentId;
//             this.showToast('Success', 'Signature image uploaded successfully', 'success');
//         }
//     }

//     handleSignerInfoChange(event) {
//         const fieldName = event.target.name || event.target.label.toLowerCase().replace(' ', '');
//         if (fieldName.includes('email')) {
//             this.signerEmail = event.detail.value;
//         } else if (fieldName.includes('date')) {
//             this.signatureDate = event.detail.value;
//         }
//     }

//     handleConsentChange(event) {
//         this.hasConsent = event.detail.checked;
//     }

//     // Canvas Drawing Handlers
//     handleMouseDown(event) {
//         this.isDrawing = true;
//         const rect = this.canvas.getBoundingClientRect();
//         this.lastX = event.clientX - rect.left;
//         this.lastY = event.clientY - rect.top;
//         this.context.beginPath();
//         this.context.moveTo(this.lastX, this.lastY);
//     }

//     handleMouseMove(event) {
//         if (!this.isDrawing) return;
        
//         const rect = this.canvas.getBoundingClientRect();
//         const currentX = event.clientX - rect.left;
//         const currentY = event.clientY - rect.top;
        
//         this.context.lineTo(currentX, currentY);
//         this.context.stroke();
        
//         this.lastX = currentX;
//         this.lastY = currentY;
//     }

//     handleMouseUp() {
//         this.isDrawing = false;
//         this.context.closePath();
//     }

//     // Touch Handlers for Mobile
//     handleTouchStart(event) {
//         event.preventDefault();
//         const touch = event.touches[0];
//         const mouseEvent = new MouseEvent('mousedown', {
//             clientX: touch.clientX,
//             clientY: touch.clientY
//         });
//         this.canvas.dispatchEvent(mouseEvent);
//     }

//     handleTouchMove(event) {
//         event.preventDefault();
//         const touch = event.touches[0];
//         const mouseEvent = new MouseEvent('mousemove', {
//             clientX: touch.clientX,
//             clientY: touch.clientY
//         });
//         this.canvas.dispatchEvent(mouseEvent);
//     }

//     handleTouchEnd(event) {
//         event.preventDefault();
//         const mouseEvent = new MouseEvent('mouseup', {});
//         this.canvas.dispatchEvent(mouseEvent);
//     }

//     handleClearCanvas() {
//         if (this.canvas && this.context) {
//             this.context.clearRect(0, 0, this.canvas.width, this.canvas.height);
//         }
//     }

//     // Main Actions
//     handleSignDocument() {
//         this.isLoading = true;
        
//         const signatureData = this.getSignatureData();
//         const signerInfo = this.getSignerInfo();
        
//         submitSignature({
//             requestId: this.recordId,
//             signatureData: signatureData,
//             signerInfo: signerInfo
//         })
//         .then(result => {
//             this.showToast('Success', 'Document signed successfully!', 'success');
//             this.handleCancel(); // Close the component
//         })
//         .catch(error => {
//             console.error('Error submitting signature:', error);
//             this.showToast('Error', 'Failed to submit signature: ' + error.body.message, 'error');
//         })
//         .finally(() => {
//             this.isLoading = false;
//         });
//     }

//     handleCancel() {
//         // Fire event to close modal or navigate away
//         this.dispatchEvent(new CustomEvent('cancel'));
//     }

//     getSignatureData() {
//         switch (this.selectedMethod) {
//             case 'type':
//                 return this.createTypedSignatureImage();
//             case 'draw':
//                 return this.canvas.toDataURL('image/png');
//             case 'upload':
//                 return this.uploadedSignature;
//             default:
//                 return '';
//         }
//     }

//     createTypedSignatureImage() {
//         // Create a temporary canvas to generate typed signature image
//         const tempCanvas = document.createElement('canvas');
//         tempCanvas.width = 400;
//         tempCanvas.height = 100;
//         const tempContext = tempCanvas.getContext('2d');
        
//         tempContext.fillStyle = '#ffffff';
//         tempContext.fillRect(0, 0, tempCanvas.width, tempCanvas.height);
        
//         tempContext.fillStyle = '#000000';
//         tempContext.font = '24px cursive';
//         tempContext.textAlign = 'center';
//         tempContext.textBaseline = 'middle';
//         tempContext.fillText(this.typedSignature, tempCanvas.width / 2, tempCanvas.height / 2);
        
//         return tempCanvas.toDataURL('image/png');
//     }

//     getSignerInfo() {
//         return JSON.stringify({
//             signerEmail: this.signerEmail,
//             signatureDate: this.signatureDate,
//             signatureMethod: this.selectedMethod,
//             ipAddress: this.getClientIP(),
//             userAgent: navigator.userAgent,
//             timestamp: new Date().toISOString()
//         });
//     }

//     getClientIP() {
//         // In production, you'd implement proper IP detection
//         return 'IP_ADDRESS_PLACEHOLDER';
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




//version 1

// import { LightningElement, track, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import submitSignatureApex from '@salesforce/apex/SignatureRequestController.submitSignature';
// export default class SignaturePad extends LightningElement {
// @api requestId;
// @api signerName = '';
// @api documentTitle = '';
// @track selectedMethod = 'type';
// @track typedSignature = '';
// @track drawnSignatureUrl = '';
// @track uploadedSignatureUrl = '';
// @track hasSignature = false;
// @track isConfirmed = false;
// @track isLoading = false;
// @track errorMessage = '';
// @track currentDate = new Date().toLocaleDateString();

// // Canvas drawing properties
// @track isDrawing = false;
// @track isCanvasEmpty = true;
// canvasContext;

// signatureMethodOptions = [
//     { label: 'Type Signature', value: 'type' },
//     { label: 'Draw Signature', value: 'draw' },
//     { label: 'Upload Image', value: 'upload' }
// ];

// // Computed properties
// get isTypeMethod() {
//     return this.selectedMethod === 'type';
// }

// get isDrawMethod() {
//     return this.selectedMethod === 'draw';
// }

// get isUploadMethod() {
//     return this.selectedMethod === 'upload';
// }

// get selectedMethodLabel() {
//     const method = this.signatureMethodOptions.find(opt => opt.value === this.selectedMethod);
//     return method ? method.label : '';
// }

// get canCreateSignature() {
//     switch(this.selectedMethod) {
//         case 'type':
//             return this.typedSignature.trim().length > 0;
//         case 'draw':
//             return !this.isCanvasEmpty;
//         case 'upload':
//             return this.uploadedSignatureUrl !== '';
//         default:
//             return false;
//     }
// }

// // Event handlers
// handleMethodChange(event) {
//     this.selectedMethod = event.target.value;
//     this.resetSignatureData();
// }

// handleTypedSignatureChange(event) {
//     this.typedSignature = event.target.value;
// }

// handleConfirmationChange(event) {
//     this.isConfirmed = event.target.checked;
// }

// handleUploadFinished(event) {
//     const uploadedFiles = event.detail.files;
//     if (uploadedFiles.length > 0) {
//         // In a real implementation, you'd process the uploaded file
//         // For demo purposes, we'll simulate a successful upload
//         this.uploadedSignatureUrl = '/servlet/servlet.FileDownload?file=' + uploadedFiles[0].documentId;
//     }
// }

// // Canvas drawing methods
// renderedCallback() {
//     if (this.isDrawMethod && !this.canvasContext) {
//         this.initializeCanvas();
//     }
// }

// initializeCanvas() {
//     const canvas = this.refs.signatureCanvas;
//     if (canvas) {
//         this.canvasContext = canvas.getContext('2d');
//         this.canvasContext.strokeStyle = '#000000';
//         this.canvasContext.lineWidth = 2;
//         this.canvasContext.lineCap = 'round';
//         this.canvasContext.lineJoin = 'round';
//     }
// }

// startDrawing(event) {
//     this.isDrawing = true;
//     const rect = event.target.getBoundingClientRect();
//     this.canvasContext.beginPath();
//     this.canvasContext.moveTo(
//         event.clientX - rect.left,
//         event.clientY - rect.top
//     );
// }

// draw(event) {
//     if (!this.isDrawing) return;
    
//     const rect = event.target.getBoundingClientRect();
//     this.canvasContext.lineTo(
//         event.clientX - rect.left,
//         event.clientY - rect.top
//     );
//     this.canvasContext.stroke();
//     this.isCanvasEmpty = false;
// }

// stopDrawing() {
//     this.isDrawing = false;
//     this.canvasContext.beginPath();
// }

// // Touch events for mobile
// startDrawingTouch(event) {
//     event.preventDefault();
//     const touch = event.touches[0];
//     const rect = event.target.getBoundingClientRect();
//     this.isDrawing = true;
//     this.canvasContext.beginPath();
//     this.canvasContext.moveTo(
//         touch.clientX - rect.left,
//         touch.clientY - rect.top
//     );
// }

// drawTouch(event) {
//     if (!this.isDrawing) return;
//     event.preventDefault();
    
//     const touch = event.touches[0];
//     const rect = event.target.getBoundingClientRect();
//     this.canvasContext.lineTo(
//         touch.clientX - rect.left,
//         touch.clientY - rect.top
//     );
//     this.canvasContext.stroke();
//     this.isCanvasEmpty = false;
// }

// clearCanvas() {
//     const canvas = this.refs.signatureCanvas;
//     this.canvasContext.clearRect(0, 0, canvas.width, canvas.height);
//     this.isCanvasEmpty = true;
//     this.drawnSignatureUrl = '';
// }

// finishDrawing() {
//     const canvas = this.refs.signatureCanvas;
//     this.drawnSignatureUrl = canvas.toDataURL('image/png');
// }

// // Signature creation and submission
// createSignature() {
//     switch(this.selectedMethod) {
//         case 'type':
//             // Convert typed signature to styled image
//             this.createTypedSignatureImage();
//             break;
//         case 'draw':
//             // Canvas signature already captured
//             break;
//         case 'upload':
//             // Uploaded signature already set
//             break;
//     }
//     this.hasSignature = true;
// }

// createTypedSignatureImage() {
//     // Create a temporary canvas to render the typed signature
//     const tempCanvas = document.createElement('canvas');
//     tempCanvas.width = 400;
//     tempCanvas.height = 100;
//     const ctx = tempCanvas.getContext('2d');
    
//     // Style the typed signature
//     ctx.font = '32px cursive';
//     ctx.fillStyle = '#000000';
//     ctx.textAlign = 'center';
//     ctx.fillText(this.typedSignature, 200, 60);
    
//     this.drawnSignatureUrl = tempCanvas.toDataURL('image/png');
// }

// resetSignature() {
//     this.hasSignature = false;
//     this.isConfirmed = false;
//     this.resetSignatureData();
// }

// resetSignatureData() {
//     this.typedSignature = '';
//     this.drawnSignatureUrl = '';
//     this.uploadedSignatureUrl = '';
//     this.isCanvasEmpty = true;
//     this.errorMessage = '';
    
//     if (this.canvasContext) {
//         this.clearCanvas();
//     }
// }

// async submitSignature() {
//     this.isLoading = true;
//     this.errorMessage = '';
    
//     try {
//         // Get the signature data based on method
//         let signatureData = '';
//         switch(this.selectedMethod) {
//             case 'type':
//             case 'draw':
//                 signatureData = this.drawnSignatureUrl;
//                 break;
//             case 'upload':
//                 signatureData = this.uploadedSignatureUrl;
//                 break;
//         }
        
//         // Submit to Salesforce
//         const result = await submitSignatureApex({
//             requestId: this.requestId,
//             signatureData: signatureData,
//             signatureMethod: this.selectedMethodLabel
//         });
        
//         if (result) {
//             this.showSuccessToast('Signature submitted successfully!');
            
//             // Fire custom event to notify parent
//             this.dispatchEvent(new CustomEvent('signaturesubmitted', {
//                 detail: {
//                     requestId: this.requestId,
//                     signatureMethod: this.selectedMethodLabel,
//                     signerName: this.signerName
//                 }
//             }));
//         } else {
//             throw new Error('Failed to submit signature');
//         }
        
//     } catch (error) {
//         console.error('Error submitting signature:', error);
//         this.errorMessage = 'Failed to submit signature. Please try again.';
//         this.showErrorToast('Signature submission failed');
//     } finally {
//         this.isLoading = false;
//     }
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
// import submitSignatureApex from '@salesforce/apex/SignatureRequestController.submitSignature';
// export default class SignaturePad extends LightningElement {
// @api requestId;
// @api signerName = '';
// @api documentTitle = '';
// @track selectedMethod = 'type';
// @track typedSignature = '';
// @track drawnSignatureUrl = '';
// @track uploadedSignatureUrl = '';
// @track hasSignature = false;
// @track isConfirmed = false;
// @track isLoading = false;
// @track errorMessage = '';
// @track currentDate = new Date().toLocaleDateString();

// // Canvas drawing properties
// @track isDrawing = false;
// @track isCanvasEmpty = true;
// canvasContext;

// signatureMethodOptions = [
//     { label: 'Type Signature', value: 'type' },
//     { label: 'Draw Signature', value: 'draw' },
//     { label: 'Upload Image', value: 'upload' }
// ];

// // Computed properties
// get isTypeMethod() {
//     return this.selectedMethod === 'type';
// }

// get isDrawMethod() {
//     return this.selectedMethod === 'draw';
// }

// get isUploadMethod() {
//     return this.selectedMethod === 'upload';
// }

// get selectedMethodLabel() {
//     const method = this.signatureMethodOptions.find(opt => opt.value === this.selectedMethod);
//     return method ? method.label : '';
// }

// get canCreateSignature() {
//     switch(this.selectedMethod) {
//         case 'type':
//             return this.typedSignature.trim().length > 0;
//         case 'draw':
//             return !this.isCanvasEmpty;
//         case 'upload':
//             return this.uploadedSignatureUrl !== '';
//         default:
//             return false;
//     }
// }

// // Event handlers
// handleMethodChange(event) {
//     this.selectedMethod = event.target.value;
//     this.resetSignatureData();
// }

// handleTypedSignatureChange(event) {
//     this.typedSignature = event.target.value;
// }

// handleConfirmationChange(event) {
//     this.isConfirmed = event.target.checked;
// }

// handleUploadFinished(event) {
//     const uploadedFiles = event.detail.files;
//     if (uploadedFiles.length > 0) {
//         // In a real implementation, you'd process the uploaded file
//         // For demo purposes, we'll simulate a successful upload
//         this.uploadedSignatureUrl = '/servlet/servlet.FileDownload?file=' + uploadedFiles[0].documentId;
//     }
// }

// // Canvas drawing methods
// renderedCallback() {
//     if (this.isDrawMethod && !this.canvasContext) {
//         this.initializeCanvas();
//     }
// }

// initializeCanvas() {
//     const canvas = this.refs.signatureCanvas;
//     if (canvas) {
//         this.canvasContext = canvas.getContext('2d');
//         this.canvasContext.strokeStyle = '#000000';
//         this.canvasContext.lineWidth = 2;
//         this.canvasContext.lineCap = 'round';
//         this.canvasContext.lineJoin = 'round';
//     }
// }

// startDrawing(event) {
//     this.isDrawing = true;
//     const rect = event.target.getBoundingClientRect();
//     this.canvasContext.beginPath();
//     this.canvasContext.moveTo(
//         event.clientX - rect.left,
//         event.clientY - rect.top
//     );
// }

// draw(event) {
//     if (!this.isDrawing) return;
    
//     const rect = event.target.getBoundingClientRect();
//     this.canvasContext.lineTo(
//         event.clientX - rect.left,
//         event.clientY - rect.top
//     );
//     this.canvasContext.stroke();
//     this.isCanvasEmpty = false;
// }

// stopDrawing() {
//     this.isDrawing = false;
//     this.canvasContext.beginPath();
// }

// // Touch events for mobile
// startDrawingTouch(event) {
//     event.preventDefault();
//     const touch = event.touches[0];
//     const rect = event.target.getBoundingClientRect();
//     this.isDrawing = true;
//     this.canvasContext.beginPath();
//     this.canvasContext.moveTo(
//         touch.clientX - rect.left,
//         touch.clientY - rect.top
//     );
// }

// drawTouch(event) {
//     if (!this.isDrawing) return;
//     event.preventDefault();
    
//     const touch = event.touches[0];
//     const rect = event.target.getBoundingClientRect();
//     this.canvasContext.lineTo(
//         touch.clientX - rect.left,
//         touch.clientY - rect.top
//     );
//     this.canvasContext.stroke();
//     this.isCanvasEmpty = false;
// }

// clearCanvas() {
//     const canvas = this.refs.signatureCanvas;
//     this.canvasContext.clearRect(0, 0, canvas.width, canvas.height);
//     this.isCanvasEmpty = true;
//     this.drawnSignatureUrl = '';
// }

// finishDrawing() {
//     const canvas = this.refs.signatureCanvas;
//     this.drawnSignatureUrl = canvas.toDataURL('image/png');
// }

// // Signature creation and submission
// createSignature() {
//     switch(this.selectedMethod) {
//         case 'type':
//             // Convert typed signature to styled image
//             this.createTypedSignatureImage();
//             break;
//         case 'draw':
//             // Canvas signature already captured
//             break;
//         case 'upload':
//             // Uploaded signature already set
//             break;
//     }
//     this.hasSignature = true;
// }

// createTypedSignatureImage() {
//     // Create a temporary canvas to render the typed signature
//     const tempCanvas = document.createElement('canvas');
//     tempCanvas.width = 400;
//     tempCanvas.height = 100;
//     const ctx = tempCanvas.getContext('2d');
    
//     // Style the typed signature
//     ctx.font = '32px cursive';
//     ctx.fillStyle = '#000000';
//     ctx.textAlign = 'center';
//     ctx.fillText(this.typedSignature, 200, 60);
    
//     this.drawnSignatureUrl = tempCanvas.toDataURL('image/png');
// }

// resetSignature() {
//     this.hasSignature = false;
//     this.isConfirmed = false;
//     this.resetSignatureData();
// }

// resetSignatureData() {
//     this.typedSignature = '';
//     this.drawnSignatureUrl = '';
//     this.uploadedSignatureUrl = '';
//     this.isCanvasEmpty = true;
//     this.errorMessage = '';
    
//     if (this.canvasContext) {
//         this.clearCanvas();
//     }
// }

// async submitSignature() {
//     this.isLoading = true;
//     this.errorMessage = '';
    
//     try {
//         // Get the signature data based on method
//         let signatureData = '';
//         switch(this.selectedMethod) {
//             case 'type':
//             case 'draw':
//                 signatureData = this.drawnSignatureUrl;
//                 break;
//             case 'upload':
//                 signatureData = this.uploadedSignatureUrl;
//                 break;
//         }
        
//         // Submit to Salesforce
//         const result = await submitSignatureApex({
//             requestId: this.requestId,
//             signatureData: signatureData,
//             signatureMethod: this.selectedMethodLabel
//         });
        
//         if (result) {
//             this.showSuccessToast('Signature submitted successfully!');
            
//             // Fire custom event to notify parent
//             this.dispatchEvent(new CustomEvent('signaturesubmitted', {
//                 detail: {
//                     requestId: this.requestId,
//                     signatureMethod: this.selectedMethodLabel,
//                     signerName: this.signerName
//                 }
//             }));
//         } else {
//             throw new Error('Failed to submit signature');
//         }
        
//     } catch (error) {
//         console.error('Error submitting signature:', error);
//         this.errorMessage = 'Failed to submit signature. Please try again.';
//         this.showErrorToast('Signature submission failed');
//     } finally {
//         this.isLoading = false;
//     }
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
