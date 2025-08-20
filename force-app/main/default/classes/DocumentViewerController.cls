public with sharing class DocumentViewerController {
    
    @AuraEnabled(cacheable=false)
    public static DocumentDetails getDocumentDetails(Id documentId) {
        try {
            ContentDocument doc = [
                SELECT Id, Title, FileExtension, ContentSize, CreatedDate, 
                       LastModifiedDate, CreatedBy.Name, Description
                FROM ContentDocument 
                WHERE Id = :documentId 
                LIMIT 1
            ];
            
            DocumentDetails details = new DocumentDetails();
            details.id = doc.Id;
            details.title = doc.Title;
            details.fileExtension = doc.FileExtension?.toLowerCase();
            details.contentSize = doc.ContentSize;
            details.createdDate = doc.CreatedDate;
            details.lastModifiedDate = doc.LastModifiedDate;
            details.createdBy = doc.CreatedBy.Name;
            details.description = doc.Description;
            
            // Get download URL
            details.downloadUrl = '/sfc/servlet.shepherd/version/download/' + getLatestVersionId(documentId);
            
            // Get text content for supported file types
            if (isTextFile(doc.FileExtension)) {
                details.textContent = getTextContent(documentId);
            }
            
            return details;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to get document details: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static ComplianceData getComplianceData(Id documentId) {
        try {
            // Query compliance tracking record
            List<DocumentComplianceTracking__c> complianceRecords = [
                SELECT Id, Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c,
                       Compliance_Violations__c, AI_Classification__c, Risk_Score__c
                FROM DocumentComplianceTracking__c 
                WHERE Document_ID__c = :documentId 
                ORDER BY Analysis_Date__c DESC 
                LIMIT 1
            ];
            
            if (complianceRecords.isEmpty()) {
                return null;
            }
            
            DocumentComplianceTracking__c compliance = complianceRecords[0];
            ComplianceData data = new ComplianceData();
            data.complianceScore = compliance.Compliance_Score__c?.intValue() ?? 0;
            data.gdprCompliant = compliance.GDPR_Compliant__c ?? false;
            data.hipaaCompliant = compliance.HIPAA_Compliant__c ?? false;
            data.riskScore = compliance.Risk_Score__c ?? 0;
            
            // Parse violations
            if (String.isNotBlank(compliance.Compliance_Violations__c)) {
                data.violations = compliance.Compliance_Violations__c.split(';');
            }
            
            // Generate AI insights
            data.aiInsights = generateAIInsights(documentId, compliance);
            
            return data;
            
        } catch (Exception e) {
            System.debug('Error getting compliance data: ' + e.getMessage());
            return null;
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static AnalyticsData getDocumentAnalytics(Id documentId) {
        try {
            AnalyticsData analytics = new AnalyticsData();
            
            // Query view tracking
            List<AggregateResult> viewStats = [
                SELECT COUNT(Id) totalViews, MAX(View_Date__c) lastViewed
                FROM DocumentViewTracking__c 
                WHERE Document_ID__c = :documentId
            ];
            
            if (!viewStats.isEmpty()) {
                analytics.totalViews = (Integer) viewStats[0].get('totalViews') ?? 0;
                analytics.lastViewedDate = (DateTime) viewStats[0].get('lastViewed');
            }
            
            // Query download tracking
            List<AggregateResult> downloadStats = [
                SELECT COUNT(Id) totalDownloads
                FROM DocumentDownloadTracking__c 
                WHERE Document_ID__c = :documentId
            ];
            
            if (!downloadStats.isEmpty()) {
                analytics.totalDownloads = (Integer) downloadStats[0].get('totalDownloads') ?? 0;
            }
            
            // Query share tracking
            List<AggregateResult> shareStats = [
                SELECT COUNT(Id) shareCount
                FROM DocumentShareTracking__c 
                WHERE Document_ID__c = :documentId
            ];
            
            if (!shareStats.isEmpty()) {
                analytics.shareCount = (Integer) shareStats[0].get('shareCount') ?? 0;
            }
            
            return analytics;
            
        } catch (Exception e) {
            System.debug('Error getting analytics data: ' + e.getMessage());
            return new AnalyticsData();
        }
    }
    
    @AuraEnabled(cacheable=false)
    public static List<DocumentComment> getDocumentComments(Id documentId) {
        try {
            List<DocumentComment> comments = new List<DocumentComment>();
            
            // Query comments
            List<DocumentComment__c> commentRecords = [
                SELECT Id, Comment_Text__c, Created_By__r.Name, Created_By__r.SmallPhotoUrl,
                       CreatedDate, Parent_Comment__c, Like_Count__c
                FROM DocumentComment__c 
                WHERE Document_ID__c = :documentId 
                ORDER BY CreatedDate DESC
            ];
            
            // Build comment hierarchy
            Map<Id, List<DocumentComment__c>> repliesMap = new Map<Id, List<DocumentComment__c>>();
            List<DocumentComment__c> topLevelComments = new List<DocumentComment__c>();
            
            for (DocumentComment__c comment : commentRecords) {
                if (comment.Parent_Comment__c == null) {
                    topLevelComments.add(comment);
                } else {
                    if (!repliesMap.containsKey(comment.Parent_Comment__c)) {
                        repliesMap.put(comment.Parent_Comment__c, new List<DocumentComment__c>());
                    }
                    repliesMap.get(comment.Parent_Comment__c).add(comment);
                }
            }
            
            // Convert to wrapper objects
            for (DocumentComment__c comment : topLevelComments) {
                DocumentComment commentObj = new DocumentComment();
                commentObj.id = comment.Id;
                commentObj.content = comment.Comment_Text__c;
                commentObj.authorName = comment.Created_By__r.Name;
                commentObj.authorPhoto = comment.Created_By__r.SmallPhotoUrl;
                commentObj.createdDate = comment.CreatedDate.format('MMM dd, yyyy H
//Above line needs to be completed, this is a AI bug when data format is there.
commentObj.createdDate = comment.CreatedDate.format();
commentObj.likeCount = Integer.valueOf(comment.Like_Count__c ?? 0);

// Add replies if they exist
if (repliesMap.containsKey(comment.Id)) {
    commentObj.replies = new List&lt;DocumentCommentReply&gt;();
    for (DocumentComment__c reply : repliesMap.get(comment.Id)) {
        DocumentCommentReply replyObj = new DocumentCommentReply();
        replyObj.id = reply.Id;
        replyObj.content = reply.Comment_Text__c;
        replyObj.authorName = reply.Created_By__r.Name;
        replyObj.authorPhoto = reply.Created_By__r.SmallPhotoUrl;
        replyObj.createdDate = reply.CreatedDate.format();
        commentObj.replies.add(replyObj);
    }
}

comments.add(commentObj);
}

return comments;

} catch (Exception e) {
System.debug(&#39;Error getting comments: &#39; + e.getMessage());
return new List&lt;DocumentComment&gt;();
}
}

@AuraEnabled
public static void addDocumentComment(Id documentId, String comment) {
try {
    DocumentComment__c newComment = new DocumentComment__c();
    newComment.Document_ID__c = documentId;
    newComment.Comment_Text__c = comment;
    newComment.Created_By__c = UserInfo.getUserId();
    
    insert newComment;
    
    // Track comment activity
    trackCommentActivity(documentId, &#39;ADD_COMMENT&#39;);
    
} catch (Exception e) {
    throw new AuraHandledException(&#39;Failed to add comment: &#39; + e.getMessage());
}
}

@AuraEnabled
public static void shareDocument(Id documentId, String emails, String message) {
try {
    List&lt;String&gt; emailList = emails.split(&#39;,&#39;);
    
    for (String email : emailList) {
        email = email.trim();
        if (String.isNotBlank(email)) {
            // Create share tracking record
            DocumentShareTracking__c shareRecord = new DocumentShareTracking__c();
            shareRecord.Document_ID__c = documentId;
            shareRecord.Shared_With_Email__c = email;
            shareRecord.Share_Message__c = message;
            shareRecord.Shared_By__c = UserInfo.getUserId();
            shareRecord.Share_Date__c = System.now();
            
            insert shareRecord;
            
            // Send email notification
            sendShareNotification(documentId, email, message);
        }
    }
    
} catch (Exception e) {
    throw new AuraHandledException(&#39;Failed to share document: &#39; + e.getMessage());
}
}

@AuraEnabled(cacheable=false)
public static List&lt;DocumentVersion&gt; getVersionHistory(Id documentId) {
try {
    List&lt;DocumentVersion&gt; versions = new List&lt;DocumentVersion&gt;();
    
    List&lt;ContentVersion&gt; contentVersions = [
        SELECT Id, Title, VersionNumber, ContentSize, CreatedDate, 
               CreatedBy.Name, Description, ReasonForChange
        FROM ContentVersion 
        WHERE ContentDocumentId = :documentId 
        ORDER BY CreatedDate DESC
    ];
    
    for (ContentVersion cv : contentVersions) {
        DocumentVersion version = new DocumentVersion();
        version.id = cv.Id;
        version.versionNumber = &#39;v&#39; + cv.VersionNumber;
        version.modifiedDate = cv.CreatedDate;
        version.modifiedBy = cv.CreatedBy.Name;
        version.contentSize = cv.ContentSize;
        version.comments = cv.ReasonForChange;
        version.downloadUrl = &#39;/sfc/servlet.shepherd/version/download/&#39; + cv.Id;
        
        versions.add(version);
    }
    
    return versions;
    
} catch (Exception e) {
    throw new AuraHandledException(&#39;Failed to get version history: &#39; + e.getMessage());
}
}

@AuraEnabled
public static void analyzeDocumentCompliance(Id documentId) {
try {
    // Trigger AI compliance analysis
    DocumentComplianceProcessor processor = new DocumentComplianceProcessor();
    processor.analyzeDocument(documentId);
    
} catch (Exception e) {
    throw new AuraHandledException(&#39;Failed to analyze document: &#39; + e.getMessage());
}
}

@AuraEnabled
public static void updateSignatureStatus(Id documentId, String signatureData) {
try {
    // Update e-signature status
    ESignatureTracking__c sigTracking = new ESignatureTracking__c();
    sigTracking.Document_ID__c = documentId;
    sigTracking.Signature_Data__c = signatureData;
    sigTracking.Signed_Date__c = System.now();
    sigTracking.Signer_ID__c = UserInfo.getUserId();
    
    insert sigTracking;
    
    // Generate document hash for integrity
    generateDocumentHash(documentId);
    
} catch (Exception e) {
    throw new AuraHandledException(&#39;Failed to update signature: &#39; + e.getMessage());
}
}

@AuraEnabled
public static String generateDocumentHash(Id documentId) {
try {
    ContentVersion cv = [
        SELECT Id, VersionData 
        FROM ContentVersion 
        WHERE ContentDocumentId = :documentId 
        AND IsLatest = true 
        LIMIT 1
    ];
    
    // Generate SHA-256 hash
    Blob documentData = cv.VersionData;
    Blob hash = Crypto.generateDigest(&#39;SHA-256&#39;, documentData);
    String hashString = EncodingUtil.base64Encode(hash);
    
    // Store hash for integrity verification
    DocumentIntegrity__c integrity = new DocumentIntegrity__c();
    integrity.Document_ID__c = documentId;
    integrity.Content_Hash__c = hashString;
    integrity.Hash_Algorithm__c = &#39;SHA-256&#39;;
    integrity.Generated_Date__c = System.now();
    
    upsert integrity Document_ID__c;
    
    return hashString;
    
} catch (Exception e) {
    throw new AuraHandledException(&#39;Failed to generate hash: &#39; + e.getMessage());
}
}

@AuraEnabled
public static void trackDocumentView(Id documentId) {
try {
    DocumentViewTracking__c viewRecord = new DocumentViewTracking__c();
    viewRecord.Document_ID__c = documentId;
    viewRecord.Viewed_By__c = UserInfo.getUserId();
    viewRecord.View_Date__c = System.now();
    viewRecord.Session_ID__c = UserInfo.getSessionId();
    
    insert viewRecord;
    
} catch (Exception e) {
    System.debug(&#39;Error tracking view: &#39; + e.getMessage());
    // Don&#39;t throw exception for tracking failures
}
}

// Private helper methods
private static Id getLatestVersionId(Id documentId) {
    try {
        ContentVersion cv = [
            SELECT Id 
            FROM ContentVersion 
            WHERE ContentDocumentId = :documentId 
            AND IsLatest = true 
            LIMIT 1
        ];
        return cv.Id;
    } catch (Exception e) {
        return null;
    }
}

private static Boolean isTextFile(String fileExtension) {
    Set&lt;String&gt; textExtensions = new Set&lt;String&gt;{
        &#39;txt&#39;, &#39;csv&#39;, &#39;log&#39;, &#39;xml&#39;, &#39;json&#39;, &#39;html&#39;, &#39;css&#39;, &#39;js&#39;
    };
    return textExtensions.contains(fileExtension?.toLowerCase());
}

private static String getTextContent(Id documentId) {
    try {
        ContentVersion cv = [
            SELECT VersionData 
            FROM ContentVersion 
            WHERE ContentDocumentId = :documentId 
            AND IsLatest = true 
            LIMIT 1
        ];
        
        return cv.VersionData.toString();
    } catch (Exception e) {
        return &#39;&#39;;
    }
}

private static List&lt;AIInsight&gt; generateAIInsights(Id documentId, DocumentComplianceTracking__c compliance) {
    List&lt;AIInsight&gt; insights = new List&lt;AIInsight&gt;();
    
    try {
        // Classification insight
        if (String.isNotBlank(compliance.AI_Classification__c)) {
            AIInsight classificationInsight = new AIInsight();
            classificationInsight.type = &#39;classification&#39;;
            classificationInsight.text = &#39;Document classified as: &#39; + compliance.AI_Classification__c;
            classificationInsight.confidence = 95;
            insights.add(classificationInsight);
        }
        
        // Risk assessment insight
        if (compliance.Risk_Score__c != null &amp;&amp; compliance.Risk_Score__c &gt; 70) {
            AIInsight riskInsight = new AIInsight();
            riskInsight.type = &#39;security&#39;;
            riskInsight.text = &#39;High risk document detected. Review recommended.&#39;;
            riskInsight.confidence = Integer.valueOf(compliance.Risk_Score__c);
            insights.add(riskInsight);
        }
        
        // Compliance recommendation
        if (compliance.Compliance_Score__c &lt; 80) {
            AIInsight complianceInsight = new AIInsight();
            complianceInsight.type = &#39;compliance&#39;;
            complianceInsight.text = &#39;Document compliance can be improved. Consider adding required clauses.&#39;;
            complianceInsight.confidence = 88;
            insights.add(complianceInsight);
        }
        
        // Privacy insight
        if (!compliance.GDPR_Compliant__c) {
            AIInsight privacyInsight = new AIInsight();
            privacyInsight.type = &#39;privacy&#39;;
            privacyInsight.text = &#39;GDPR compliance issues detected. Privacy review required.&#39;;
            privacyInsight.confidence = 92;
            insights.add(privacyInsight);
        }
        
    } catch (Exception e) {
        System.debug(&#39;Error generating AI insights: &#39; + e.getMessage());
    }
    
    return insights;
}

private static void trackCommentActivity(Id documentId, String activityType) {
    try {
        DocumentActivityLog__c activity = new DocumentActivityLog__c();
        activity.Document_ID__c = documentId;
        activity.Activity_Type__c = activityType;
        activity.User_ID__c = UserInfo.getUserId();
        activity.Activity_Date__c = System.now();
        
        insert activity;
    } catch (Exception e) {
        System.debug(&#39;Error tracking activity: &#39; + e.getMessage());
    }
}

private static void sendShareNotification(Id documentId, String email, String message) {
    try {
        // Get document details
        ContentDocument doc = [
            SELECT Title 
            FROM ContentDocument 
            WHERE Id = :documentId 
            LIMIT 1
        ];
        
        // Create email
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        emailMsg.setToAddresses(new String[]{email});
        emailMsg.setSubject(&#39;Document Shared: &#39; + doc.Title);
        
        String emailBody = &#39;A document has been shared with you.\n\n&#39;;
        emailBody += &#39;Document: &#39; + doc.Title + &#39;\n&#39;;
        emailBody += &#39;Shared by: &#39; + UserInfo.getName() + &#39;\n\n&#39;;
        
        if (String.isNotBlank(message)) {
            emailBody += &#39;Message: &#39; + message + &#39;\n\n&#39;;
        }
        
        emailBody += &#39;Click here to view: &#39; + URL.getSalesforceBaseUrl().toExternalForm() + 
                    &#39;/lightning/r/ContentDocument/&#39; + documentId + &#39;/view&#39;;
        
        emailMsg.setPlainTextBody(emailBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailMsg});
        
    } catch (Exception e) {
        System.debug(&#39;Error sending share notification: &#39; + e.getMessage());
    }
}

// Wrapper classes
public class DocumentDetails {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public String title { get; set; }
    @AuraEnabled public String fileExtension { get; set; }
    @AuraEnabled public Integer contentSize { get; set; }
    @AuraEnabled public DateTime createdDate { get; set; }
    @AuraEnabled public DateTime lastModifiedDate { get; set; }
    @AuraEnabled public String createdBy { get; set; }
    @AuraEnabled public String description { get; set; }
    @AuraEnabled public String downloadUrl { get; set; }
    @AuraEnabled public String textContent { get; set; }
}

public class ComplianceData {
    @AuraEnabled public Integer complianceScore { get; set; }
    @AuraEnabled public Boolean gdprCompliant { get; set; }
    @AuraEnabled public Boolean hipaaCompliant { get; set; }
    @AuraEnabled public Decimal riskScore { get; set; }
    @AuraEnabled public List&lt;String&gt; violations { get; set; }
    @AuraEnabled public List&lt;AIInsight&gt; aiInsights { get; set; }
    
    public ComplianceData() {
        this.violations = new List&lt;String&gt;();
        this.aiInsights = new List&lt;AIInsight&gt;();
    }
}

public class AnalyticsData {
    @AuraEnabled public Integer totalViews { get; set; }
    @AuraEnabled public Integer totalDownloads { get; set; }
    @AuraEnabled public Integer shareCount { get; set; }
    @AuraEnabled public DateTime lastViewedDate { get; set; }
    
    public AnalyticsData() {
        this.totalViews = 0;
        this.totalDownloads = 0;
        this.shareCount = 0;
    }
}

public class DocumentComment {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public String content { get; set; }
    @AuraEnabled public String authorName { get; set; }
    @AuraEnabled public String authorPhoto { get; set; }
    @AuraEnabled public String createdDate { get; set; }
    @AuraEnabled public Integer likeCount { get; set; }
    @AuraEnabled public List&lt;DocumentCommentReply&gt; replies { get; set; }
    
    public DocumentComment() {
        this.replies = new List&lt;DocumentCommentReply&gt;();
    }
}

public class DocumentCommentReply {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public String content { get; set; }
    @AuraEnabled public String authorName { get; set; }
    @AuraEnabled public String authorPhoto { get; set; }
    @AuraEnabled public String createdDate { get; set; }
}

public class DocumentVersion {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public String versionNumber { get; set; }
    @AuraEnabled public DateTime modifiedDate { get; set; }
    @AuraEnabled public String modifiedBy { get; set; }
    @AuraEnabled public Integer contentSize { get; set; }
    @AuraEnabled public String comments { get; set; }
    @AuraEnabled public String downloadUrl { get; set; }
}

public class AIInsight {
    @AuraEnabled public String type { get; set; }
    @AuraEnabled public String text { get; set; }
    @AuraEnabled public Integer confidence { get; set; }
}
}
