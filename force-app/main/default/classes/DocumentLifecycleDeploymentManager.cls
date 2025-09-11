public class DocumentLifecycleDeploymentManager {
    
    /**
     * Main system initialization method
     * Creates configurations, policies, schedules, and audit logs
     */
    public static String initializeCompleteSystem() {
        try {
            System.debug('Starting DocGen system initialization...');
            
            createSystemConfigurations();
            createDefaultPolicies();
            setupMonitoringSchedules();
            logInitialization();
            
            System.debug('✓ DocGen system initialization completed successfully');
            return 'System initialized successfully';
            
        } catch (Exception e) {
            System.debug('✗ System initialization failed: ' + e.getMessage());
            logInitializationError(e.getMessage());
            throw new AuraHandledException('System initialization failed: ' + e.getMessage());
        }
    }
    
    /**
     * Create default system configurations for different regions and roles
     */
    @TestVisible
    private static void createSystemConfigurations() {
        List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
        
        // US Manager Configuration
        configs.add(new DocumentLifecycleConfiguration__c(
            Region__c = 'US',
            Role__c = 'Manager', 
            ContractType__c = 'Employment',
            ComplianceStatus__c = 'Compliant',
            OutputFormat__c = 'PDF',
            RetentionPeriod__c = 2555, // 7 years
            AIProcessingEnabled__c = true
        ));
        
        // EU Employee Configuration  
        configs.add(new DocumentLifecycleConfiguration__c(
            Region__c = 'EU',
            Role__c = 'Employee',
            ContractType__c = 'Employment', 
            ComplianceStatus__c = 'Compliant',
            OutputFormat__c = 'PDF',
            RetentionPeriod__c = 2555,
            AIProcessingEnabled__c = true
        ));
        
        // APAC NDA Configuration
        configs.add(new DocumentLifecycleConfiguration__c(
            Region__c = 'APAC',
            Role__c = 'Developer',
            ContractType__c = 'NDA',
            ComplianceStatus__c = 'Under Review',
            OutputFormat__c = 'DOCX',
            RetentionPeriod__c = 1825, // 5 years
            AIProcessingEnabled__c = true
        ));
        
        insert configs;
        System.debug('✓ Created ' + configs.size() + ' system configurations');
    }
    
    /**
     * Create default retention policies for different document types
     */
    @TestVisible
    private static void createDefaultPolicies() {
        List<RetentionPolicy__c> policies = new List<RetentionPolicy__c>();
        
        // Standard Employment Documents Policy
        policies.add(new RetentionPolicy__c(
            Name = 'Standard Employment Policy',
            RetentionPeriod__c = 2555, // 7 years in days
            AutoDelete__c = false,
            Region__c = 'US',
            DocumentType__c = 'Employment'
        ));
        
        // GDPR Personal Data Policy  
        policies.add(new RetentionPolicy__c(
            Name = 'GDPR Personal Data Policy',
            RetentionPeriod__c = 1095, // 3 years
            AutoDelete__c = true,
            Region__c = 'EU', 
            DocumentType__c = 'Personal Data'
        ));
        
        // Financial Records Policy
        policies.add(new RetentionPolicy__c(
            Name = 'Financial Records Policy',
            RetentionPeriod__c = 2555, // 7 years
            AutoDelete__c = false,
            Region__c = 'Global',
            DocumentType__c = 'Financial'
        ));
        
        insert policies;
        System.debug('✓ Created ' + policies.size() + ' retention policies');
    }
    
    /**
     * Setup monitoring and scheduled jobs
     */
    @TestVisible  
    private static void setupMonitoringSchedules() {
        try {
            // Schedule document expiration monitoring (daily at 2 AM)
            String cronExp = '0 0 2 * * ?';
            String jobName = 'DocGen_Daily_Monitoring';
                    // Check if job already exists
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name 
            FROM CronTrigger 
            WHERE CronJobDetail.Name LIKE 'DocGen_Daily_Monitoring%'
            AND State != 'DELETED'
        ];
        
        if (existingJobs.isEmpty()) {
            System.schedule(jobName, cronExp, new DocumentExpirationMonitor());
            System.debug('✓ Scheduled document expiration monitoring job');
        } else {
            System.debug('⚠ Monitoring job already exists, skipping schedule');
        }
        
        // Initialize cache warmup
        DocumentCacheManager.warmupCache();
        
    } catch (Exception e) {
        System.debug('⚠ Warning: Could not setup monitoring schedules: ' + e.getMessage());
        // Don't fail initialization for monitoring setup issues
    }
}

/**
 * Log successful system initialization
 */
@TestVisible
private static void logInitialization() {
    AuditTrail__c auditLog = new AuditTrail__c(
        Action__c = 'SYSTEM_INITIALIZATION',
        Status__c = 'SUCCESS',
        Timestamp__c = DateTime.now(),
        UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
        SystemInfo__c = 'DocGen v1.0 initialized successfully',
        AdditionalData__c = JSON.serialize(new Map<String, Object>{
            'version' => '1.0',
            'timestamp' => DateTime.now().format(),
            'user' => UserInfo.getUserId(),
            'org' => UserInfo.getOrganizationId()
        })
    );
    
    insert auditLog;
    System.debug('✓ System initialization logged successfully');
}

/**
 * Log initialization errors
 */
@TestVisible
private static void logInitializationError(String errorMessage) {
    try {
        AuditTrail__c errorLog = new AuditTrail__c(
            Action__c = 'SYSTEM_INITIALIZATION',
            Status__c = 'ERROR',
            Timestamp__c = DateTime.now(),
            UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
            SystemInfo__c = 'DocGen initialization failed: ' + errorMessage,
            AdditionalData__c = errorMessage
        );
        
        insert errorLog;
    } catch (Exception e) {
        System.debug('✗ Could not log initialization error: ' + e.getMessage());
    }
}

/**
 * Get system health status
 */
public static Map<String, Object> getSystemHealth() {
    Map<String, Object> healthStatus = new Map<String, Object>();
    
    try {
        // Check configurations
        Integer configCount = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c];
        healthStatus.put('configurations_count', configCount);
        healthStatus.put('configurations_healthy', configCount >= 3);
        
        // Check policies
        Integer policyCount = [SELECT COUNT() FROM RetentionPolicy__c];
        healthStatus.put('policies_count', policyCount);
        healthStatus.put('policies_healthy', policyCount >= 2);
        
        // Check audit trail
        Integer auditCount = [SELECT COUNT() FROM AuditTrail__c WHERE CreatedDate = TODAY];
        healthStatus.put('daily_audit_count', auditCount);
        healthStatus.put('audit_healthy', true);
        
        // Overall system health
        Boolean overallHealth = (Boolean)healthStatus.get('configurations_healthy') && 
                               (Boolean)healthStatus.get('policies_healthy') && 
                               (Boolean)healthStatus.get('audit_healthy');
        
        healthStatus.put('overall_health', overallHealth);
        healthStatus.put('last_check', DateTime.now());
        
        System.debug('✓ System health check completed: ' + (overallHealth ? 'HEALTHY' : 'UNHEALTHY'));
        
    } catch (Exception e) {
        healthStatus.put('overall_health', false);
        healthStatus.put('error', e.getMessage());
        System.debug('✗ System health check failed: ' + e.getMessage());
    }
    
    return healthStatus;
}

/**
 * Reset system to defaults (use with caution)
 */
public static void resetSystemToDefaults() {
    System.debug('⚠ RESETTING SYSTEM TO DEFAULTS - THIS WILL DELETE DATA');
    
    try {
        // Delete existing configurations (this will cascade to related records)
        delete [SELECT Id FROM DocumentLifecycleConfiguration__c];
        delete [SELECT Id FROM RetentionPolicy__c];
        delete [SELECT Id FROM AuditTrail__c WHERE Action__c = 'SYSTEM_INITIALIZATION'];
        
        System.debug('✓ Existing data cleared');
        
        // Reinitialize system
        initializeCompleteSystem();
        
        System.debug('✓ System reset to defaults completed');
        
    } catch (Exception e) {
        System.debug('✗ System reset failed: ' + e.getMessage());
        throw new AuraHandledException('System reset failed: ' + e.getMessage());
    }
}
}
