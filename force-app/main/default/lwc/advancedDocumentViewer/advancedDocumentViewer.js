import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { loadScript } from 'lightning/platformResourceLoader';
import ChartJS from '@salesforce/resourceUrl/ChartJS';

// Import Apex methods
import getDocumentDetails from '@salesforce/apex/DocumentViewerController.getDocumentDetails';
import getComplianceData from '@salesforce/apex/DocumentViewerController.getComplianceData';
import getDocumentAnalytics from '@salesforce/apex/DocumentViewerController.getDocumentAnalytics';
import getDocumentComments from '@salesforce/apex/DocumentViewerController.getDocumentComments';
import addDocumentComment from '@salesforce/apex/DocumentViewerController.addDocumentComment';
import shareDocument from '@salesforce/apex/DocumentViewerController.shareDocument';
import getVersionHistory from '@salesforce/apex/DocumentViewerController.getVersionHistory';

export default class AdvancedDocumentViewer extends LightningElement {
    @api recordId;
    @api documentId;
    @api enableCollaboration = true;
    @api showMetadata = true;

    // Document properties
    @track documentDetails = {};
    @track documentTitle = 'Loading...';
    @track documentUrl = '';
    @track fileExtension = '';
    @track formattedFileSize = '';
    @track formattedCreatedDate = '';
    @track formattedModifiedDate = '';
    @track createdBy = '';
    @track textContent = '';

    // UI state
    @track isLoading = true;
    @track showPreview = false;
    @track showShareModal = false;
    @track showVersionModal = false;

    // Compliance data
    @track hasComplianceData = false;
    @track complianceScore = 0;
    @track gdprBadgeLabel = 'GDPR: Unknown';
    @track gdprBadgeVariant = 'neutral';
    @track hipaaBadgeLabel = 'HIPAA: Unknown';
    @track hipaaBadgeVariant = 'neutral';
    @track hasViolations = false;
    @track violations = [];
    @track violationCount = 0;

    // AI Insights
    @track hasAIInsights = false;
    @track aiInsights = [];

    // Analytics
    @track totalViews = 0;
    @track totalDownloads = 0;
    @track lastViewedDate = '';
    @track shareCount = 0;

    // Comments
    @track hasComments = false;
    @track comments = [];
    @track newComment = '';
    @track isCommentEmpty = true;

    // Share functionality
    @track shareUrl = '';
    @track shareEmails = '';
    @track shareMessage = '';
    @track isShareButtonDisabled = true;

    // Version history
    @track versionHistory = [];
    @track versionColumns = [
        { label: 'Version', fieldName: 'versionNumber', type: 'text' },
        { label: 'Modified Date', fieldName: 'modifiedDate', type: 'date' },
        { label: 'Modified By', fieldName: 'modifiedBy', type: 'text' },
        { label: 'Size', fieldName: 'fileSize', type: 'text' },
        { label: 'Comments', fieldName: 'comments', type: 'text' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Download', name: 'download' },
                    { label: 'Restore', name: 'restore' }
                ]
            }
        }
    ];

    // Chart instance
    chartInitialized = false;

    connectedCallback() {
        this.initializeComponent();
    }

    async initializeComponent() {
        try {
            // Use provided documentId or recordId
            const docId = this.documentId || this.recordId;
            if (!docId) {
                this.showToast('Error', 'No document ID provided', 'error');
                return;
            }

            // Load document details
            await this.loadDocumentDetails(docId);
            await this.loadComplianceData(docId);
            await this.loadAnalytics(docId);

            if (this.enableCollaboration) {
                await this.loadComments(docId);
            }

            // Initialize chart after data is loaded
            this.initializeChart();
        } catch (error) {
            console.error('Error initializing component:', error);
            this.showToast('Error', 'Failed to load document: ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadDocumentDetails(documentId) {
        try {
            const result = await getDocumentDetails({ documentId: documentId });
            this.documentDetails = result;
            this.documentTitle = result.title;
            this.fileExtension = result.fileExtension;
            this.formattedFileSize = this.formatFileSize(result.contentSize);
            this.formattedCreatedDate = this.formatDate(result.createdDate);
            this.formattedModifiedDate = this.formatDate(result.lastModifiedDate);
            this.createdBy = result.createdBy;
            this.documentUrl = result.downloadUrl;

            // Determine if preview is supported
            this.showPreview = this.isPreviewSupported(result.fileExtension);

            if (result.fileExtension === 'txt' || result.fileExtension === 'csv') {
                this.textContent = result.textContent;
            }
        } catch (error) {
            console.error('Error loading document details:', error);
            throw error;
        }
    }

    async loadComplianceData(documentId) {
        try {
            const compliance = await getComplianceData({ documentId: documentId });
            if (compliance) {
                this.hasComplianceData = true;
                this.complianceScore = compliance.complianceScore || 0;

                // Set GDPR badge
                this.gdprBadgeLabel = `GDPR: ${compliance.gdprCompliant ? 'Compliant' : 'Non-Compliant'}`;
                this.gdprBadgeVariant = compliance.gdprCompliant ? 'success' : 'error';

                // Set HIPAA badge
                this.hipaaBadgeLabel = `HIPAA: ${compliance.hipaaCompliant ? 'Compliant' : 'Non-Compliant'}`;
                this.hipaaBadgeVariant = compliance.hipaaCompliant ? 'success' : 'error';

                // Load violations
                if (compliance.violations && compliance.violations.length > 0) {
                    this.hasViolations = true;
                    this.violations = compliance.violations.map((violation, index) => ({
                        id: index,
                        message: violation
                    }));
                    this.violationCount = compliance.violations.length;
                }

                // Load AI insights
                if (compliance.aiInsights && compliance.aiInsights.length > 0) {
                    this.hasAIInsights = true;
                    this.aiInsights = compliance.aiInsights.map((insight, index) => ({
                        id: index,
                        text: insight.text,
                        iconName: this.getInsightIconName(insight.type),
                        hasConfidence: insight.confidence !== undefined,
                        confidence: insight.confidence
                    }));
                }
            }
        } catch (error) {
            console.error('Error loading compliance data:', error);
            // Continue without compliance data
        }
    }

    async loadAnalytics(documentId) {
        try {
            const analytics = await getDocumentAnalytics({ documentId: documentId });
            if (analytics) {
                this.totalViews = analytics.totalViews || 0;
                this.totalDownloads = analytics.totalDownloads || 0;
                this.shareCount = analytics.shareCount || 0;
                this.lastViewedDate = this.formatDate(analytics.lastViewedDate);
            }
        } catch (error) {
            console.error('Error loading analytics:', error);
            // Continue without analytics data
        }
    }

    async loadComments(documentId) {
        try {
            const comments = await getDocumentComments({ documentId: documentId });
            if (comments && comments.length > 0) {
                this.hasComments = true;
                this.comments = comments.map(comment => ({
                    ...comment,
                    hasReplies: comment.replies && comment.replies.length > 0,
                    likeCount: comment.likeCount || 0
                }));
            }
        } catch (error) {
            console.error('Error loading comments:', error);
            // Continue without comments
        }
    }

    initializeChart() {
        if (this.chartInitialized) return;

        loadScript(this, ChartJS)
            .then(() => {
                this.renderViewTrendChart();
                this.chartInitialized = true;
            })
            .catch(error => {
                console.error('Error loading ChartJS:', error);
            });
    }

    renderViewTrendChart() {
        const canvas = this.template.querySelector('#viewTrendChart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        // Sample data - in production, this would come from analytics
        const data = {
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            datasets: [{
                label: 'Views',
                data: [12, 19, 3, 5, 2, 3],
                borderColor: 'rgb(1, 118, 211)',
                backgroundColor: 'rgba(1, 118, 211, 0.1)',
                tension: 0.1
            }]
        };

        new Chart(ctx, {
            type: 'line',
            data: data,
            options: {
                responsive: true,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            precision: 0
                        }
                    }
                }
            }
        });
    }

    // File type detection and preview support
    get isPDF() {
        return this.fileExtension === 'pdf';
    }

    get isImage() {
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg'].includes(this.fileExtension?.toLowerCase());
    }

    get isText() {
        return ['txt', 'csv', 'log'].includes(this.fileExtension?.toLowerCase());
    }

    isPreviewSupported(fileExtension) {
        const supportedTypes = ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'svg', 'txt', 'csv', 'log'];
        return supportedTypes.includes(fileExtension?.toLowerCase());
    }

    // Utility methods
    formatFileSize(bytes) {
        if (!bytes) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
    }

    getInsightIconName(insightType) {
        const iconMap = {
            'compliance': 'utility:shield',
            'privacy': 'utility:privacy',
            'security': 'utility:lock',
            'classification': 'utility:tags',
            'recommendation': 'utility:info'
        };
        return iconMap[insightType] || 'utility:info';
    }

    // Event handlers
    handleDownload() {
        if (this.documentUrl) {
            window.open(this.documentUrl, '_blank');
            this.recordDownload();
        }
    }

    handleExportPDF() {
        // Implementation would depend on your PDF conversion service
        this.showToast('Info', 'PDF export functionality coming soon', 'info');
    }

    handleShare() {
        this.shareUrl = window.location.origin + '/lightning/r/ContentDocument/' + this.documentId + '/view';
        this.showShareModal = true;
    }

    handleAnalyze() {
        // Trigger compliance analysis
        this.showToast('Info', 'Initiating compliance analysis...', 'info');
        // Implementation would call analysis service
    }

    handleViewVersions() {
        this.loadVersionHistory();
        this.showVersionModal = true;
    }

    handleViewAudit() {
        // Navigate to audit trail or show modal
        this.showToast('Info', 'Audit trail functionality coming soon', 'info');
    }

    async loadVersionHistory() {
        try {
            const versions = await getVersionHistory({ documentId: this.documentId });
            this.versionHistory = versions.map(version => ({
                ...version,
                fileSize: this.formatFileSize(version.contentSize)
            }));
        } catch (error) {
            console.error('Error loading version history:', error);
            this.showToast('Error', 'Failed to load version history', 'error');
        }
    }

    handleVersionAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'view':
                this.handleViewVersion(row);
                break;
            case 'download':
                this.handleDownloadVersion(row);
                break;
            case 'restore':
                this.handleRestoreVersion(row);
                break;
        }
    }

    handleViewVersion(version) {
        // Open version in new tab or modal
        window.open(version.downloadUrl, '_blank');
    }

    handleDownloadVersion(version) {
        window.open(version.downloadUrl, '_blank');
    }

    handleRestoreVersion(version) {
        // Implementation would restore the selected version
        this.showToast('Info', 'Version restore functionality coming soon', 'info');
    }

    // Quick Actions
    handleDuplicate() {
        this.showToast('Info', 'Document duplication functionality coming soon', 'info');
    }

    handleConvert() {
        this.showToast('Info', 'Document conversion functionality coming soon', 'info');
    }

    handleArchive() {
        this.showToast('Info', 'Document archiving functionality coming soon', 'info');
    }

    handleDelete() {
        if (confirm('Are you sure you want to delete this document? This action cannot be undone.')) {
            this.showToast('Info', 'Document deletion functionality coming soon', 'info');
        }
    }

    // Comment functionality
    handleCommentChange(event) {
        this.newComment = event.target.value;
        this.isCommentEmpty = !this.newComment.trim();
    }

    async handlePostComment() {
        if (!this.newComment.trim()) return;

        try {
            await addDocumentComment({
                documentId: this.documentId,
                comment: this.newComment
            });

            this.newComment = '';
            this.isCommentEmpty = true;
            await this.loadComments(this.documentId);
            this.showToast('Success', 'Comment added successfully', 'success');
        } catch (error) {
            console.error('Error posting comment:', error);
            this.showToast('Error', 'Failed to post comment', 'error');
        }
    }

    handleEditComment(event) {
        const commentId = event.target.value;
        // Implementation for editing comments
        this.showToast('Info', 'Comment editing functionality coming soon', 'info');
    }

    handleDeleteComment(event) {
        const commentId = event.target.value;
        if (confirm('Are you sure you want to delete this comment?')) {
            // Implementation for deleting comments
            this.showToast('Info', 'Comment deletion functionality coming soon', 'info');
        }
    }

    handleLikeComment(event) {
        const commentId = event.target.dataset.commentId;
        // Implementation for liking comments
        this.showToast('Info', 'Comment reactions coming soon', 'info');
    }

    handleReplyComment(event) {
        const commentId = event.target.dataset.commentId;
        // Implementation for replying to comments
        this.showToast('Info', 'Comment replies coming soon', 'info');
    }

    // Share modal handlers
    handleCloseShareModal() {
        this.showShareModal = false;
        this.shareEmails = '';
        this.shareMessage = '';
    }

    handleShareEmailChange(event) {
        this.shareEmails = event.target.value;
        this.isShareButtonDisabled = !this.shareEmails.trim();
    }

    handleShareMessageChange(event) {
        this.shareMessage = event.target.value;
    }

    handleCopyUrl() {
        navigator.clipboard.writeText(this.shareUrl).then(() => {
            this.showToast('Success', 'URL copied to clipboard', 'success');
        }).catch(() => {
            this.showToast('Error', 'Failed to copy URL', 'error');
        });
    }

    async handleSendShare() {
        if (!this.shareEmails.trim()) return;

        try {
            await shareDocument({
                documentId: this.documentId,
                emails: this.shareEmails,
                message: this.shareMessage
            });

            this.showToast('Success', 'Document shared successfully', 'success');
            this.handleCloseShareModal();
        } catch (error) {
            console.error('Error sharing document:', error);
            this.showToast('Error', 'Failed to share document', 'error');
        }
    }

    // Version modal handlers
    handleCloseVersionModal() {
        this.showVersionModal = false;
    }

    // Analytics tracking
    recordDownload() {
        // Track download event
        // Implementation would call analytics service
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}