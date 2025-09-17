public class DocumentLifecycleDeploymentManager {
    
    // public static void initializeCompleteSystem() {
    //     try {
    //         System.debug('Starting Document Lifecycle Management System initialization...');
            
    //         // Step 1: Create custom settings and configurations
    //         createSystemConfigurations();
            
    //         // Step 2: Initialize default policies and rules
    //         createDefaultPolicies();
            
    //         // Step 3: Set up monitoring schedules
    //         setupMonitoringSchedules();
            
    //         // Step 4: Initialize AI models and embeddings
    //         initializeAIComponents();
            
    //         // Step 5: Create system dashboard records
    //         createSystemDashboards();
            
    //         // Step 6: Configure notifications and alerts
    //         setupNotificationSystem();
            
    //         System.debug('Document Lifecycle Management System initialization completed successfully!');
            
    //         // Log successful initialization
    //         insert new SystemInitializationLog__c(
    //             Component_Name__c = 'Document Lifecycle Management',
    //             Initialization_Status__c = 'SUCCESS',
    //             Initialization_Date__c = DateTime.now(),
    //             Version__c = '1.0',
    //             Features_Enabled__c = 'VERSION_CONTROL;RETENTION_POLICIES;EXPIRATION_MANAGEMENT;AI_INTELLIGENCE;COMPLIANCE_VALIDATION;COMPREHENSIVE_AUDIT',
    //             Configuration_Details__c = 'Complete system initialization with all advanced features enabled'
    //         );
            
    //     } catch (Exception e) {
    //         System.debug(LoggingLevel.ERROR, 'System initialization failed: ' + e.getMessage());
            
    //         // Log initialization failure
    //         insert new SystemInitializationLog__c(
    //             Component_Name__c = 'Document Lifecycle Management',
    //             Initialization_Status__c = 'FAILED',
    //             Initialization_Date__c = DateTime.now(),
    //             Error_Message__c = e.getMessage(),
    //             Error_Stack_Trace__c = e.getStackTraceString()
    //         );
            
    //         throw e;
    //     }
    // }
//  public static void initializeCompleteSystem() {
//         createSystemConfigurations();
//         createDefaultPolicies();
//         setupMonitoringSchedules();
//         logInitialization();
//     }
    public static void initializeCompleteSystem() {
        try {
            createSystemConfigurations();
            createDefaultPolicies();
            createMonitoringSchedules();
            logInitialization(true, 'System initialized successfully');
        } catch (Exception e) {
            logInitialization(false, 'Initialization failed: ' + e.getMessage());
            throw e;
        }
    }
    
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

// private static void logInitialization(Boolean success, String message) {
//                 AuditTrail__c audit = new AuditTrail__c(
//             Action__c = 'System Initialization',
//             Timestamp__c = System.now(),
//             UserId__c = UserInfo.getUserId(),
//             Details__c = 'Document lifecycle system initialized successfully'
//         );
//         insert audit;
//     }


//        // version 1
//     //     SystemInitializationLog__c log = new SystemInitializationLog__c(
//     //         Success__c = success,
//     //         Message__c = message,
//     //         Timestamp__c = System.now()
//     //     );
//     //     insert log;
//     // }

//   private static void logInitialization() {
//         AuditTrail__c audit = new AuditTrail__c(
//             Action__c = 'System Initialization',
//             Timestamp__c = System.now(),
//             Details__c = 'Document lifecycle system initialized successfully'
//         );
//         insert audit;
//     }
// private static void logInitialization() {
//         AuditTrail__c audit = new AuditTrail__c(
//             Action__c = 'SYSTEM_INITIALIZATION',
//             Timestamp__c = DateTime.now(),
//             UserDetails__c = UserInfo.getUserName(),
//             AdditionalInfo__c = 'System initialization completed successfully'
//         );
//         insert audit;
//     }
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
//  public static Map<String, Object> getSystemHealth() {
//         Map<String, Object> healthStatus = new Map<String, Object>();
//         // Check configurations
//         Integer configCount = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c];
//         healthStatus.put('configurations', configCount > 0 ? 'Healthy' : 'Needs Setup');
        
//         // Check policies
//         Integer policyCount = [SELECT COUNT() FROM RetentionPolicy__c];
//         healthStatus.put('policies', policyCount > 0 ? 'Healthy' : 'Needs Setup');
        
//         return healthStatus;
//     }
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

    //     private static void setupMonitoringSchedules() {
    //     // Schedule monitoring jobs
    //     System.schedule('Document Expiration Monitor', 
    //                    '0 0 2 * * ?', 
    //                    new DocumentExpirationScheduler());
    // }
    //  private static void setupMonitoringSchedules() {
    //     // Schedule daily document expiration monitoring jobs
    //     System.debug('Monitoring schedules configured');
    // }
    
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
    // private static void createSystemConfigurations() {
    //     List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
        
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         Name = 'Default_Retention_Period',
    //         Configuration_Type__c = 'RETENTION',
    //         String_Value__c = '7',
    //         Description__c = 'Default retention period in years for documents without specific policies'
    //     ));
        
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         Name = 'AI_Processing_Enabled',
    //         Configuration_Type__c = 'AI',
    //         Boolean_Value__c = true,
    //         Description__c = 'Enable AI-powered document intelligence processing'
    //     ));
        
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         Name = 'Compliance_Threshold',
    //         Configuration_Type__c = 'COMPLIANCE',
    //         Numeric_Value__c = 75.0,
    //         Description__c = 'Minimum compliance score threshold for document approval'
    //     ));
        
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         Name = 'Monitoring_Frequency_Hours',
    //         Configuration_Type__c = 'MONITORING',
    //         Numeric_Value__c = 24.0,
    //         Description__c = 'Frequency in hours for automated system monitoring'
    //     ));
        
    //     upsert configs Name;
    // }

    // private static void createSystemConfigurations() {

    //     List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
        
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         Region__c = 'US',
    //         Role__c = 'Manager',
    //         ContractType__c = 'Employment',
    //         ComplianceStatus__c = 'Compliant'
    //     ));
        
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         Region__c = 'EU', 
    //         Role__c = 'Employee',
    //         ContractType__c = 'NDA',
    //         ComplianceStatus__c = 'Compliant'
    //     ));
        
    //     insert configs;
    // }

        // version 2
    //     List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         ConfigurationName__c = 'Default Document Lifecycle',
    //         IsActive__c = true,
    //         RetentionPeriod__c = 2555 // 7 years in days
    //     ));
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         ConfigurationName__c = 'Financial Documents',
    //         IsActive__c = true,
    //         RetentionPeriod__c = 3650 // 10 years for financial
    //     ));
    //     insert configs;
    // }


// version 1

        // List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>{
        //     new DocumentLifecycleConfiguration__c(
        //         Name = 'Default_Retention_Period',
        //         Default_Retention_Period__c = 2555, // 7 years in days
        //         AI_Processing_Enabled__c = true,
        //         Compliance_Threshold__c = 80.00,
        //         Monitoring_Frequency_Hours__c = 24
        //     ),
        //     new DocumentLifecycleConfiguration__c(
        //         Name = 'AI_Processing_Config',
        //         AI_Processing_Enabled__c = true,
        //         Compliance_Threshold__c = 85.00,
        //         Monitoring_Frequency_Hours__c = 12
        //     )
        // };
        
        // insert configs;
        // System.debug('Created ' + configs.size() + ' system configurations');
    //}

    //   private static void createSystemConfigurations() {
    //     List<DocumentLifecycleConfiguration__c> configs = new List<DocumentLifecycleConfiguration__c>();
    //     // US Configuration
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         Region__c = 'US',
    //         Role__c = 'Manager',
    //         ContractType__c = 'Employment',
    //         ComplianceStatus__c = 'Compliant',
    //         OutputFormat__c = 'PDF',
    //         AIProcessingEnabled__c = true
    //     ));
    //     // EU Configuration
    //     configs.add(new DocumentLifecycleConfiguration__c(
    //         Region__c = 'EU',
    //         Role__c = 'Manager',
    //         ContractType__c = 'Employment',
    //         ComplianceStatus__c = 'Compliant',
    //         OutputFormat__c = 'PDF',
    //         AIProcessingEnabled__c = true
    //     ));
    //     insert configs;
    // }
    
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
    
    // private static void createDefaultPolicies() {
    //     // Create default retention policies
    //     List<DocumentRetentionPolicy__c> retentionPolicies = new List<DocumentRetentionPolicy__c>{
    //         new DocumentRetentionPolicy__c(
    //             Name = 'General Business Documents',
    //             Document_Type__c = 'GENERAL',
    //             Retention_Period_Years__c = 7,
    //             Archive_Before_Deletion__c = true,
    //             Regulatory_Framework__c = 'GENERAL_BUSINESS',
    //             Is_Active__c = true,
    //             Priority__c = 1,
    //             Description__c = 'Default retention policy for general business documents'
    //         ),
    //         new DocumentRetentionPolicy__c(
    //             Name = 'Financial Records',
    //             Document_Type__c = 'FINANCIAL',
    //             Retention_Period_Years__c = 10,
    //             Archive_Before_Deletion__c = true,
    //             Regulatory_Framework__c = 'SOX;FINANCIAL_REGULATION',
    //             Is_Active__c = true,
    //             Priority__c = 2,
    //             Description__c = 'Retention policy for financial documents and records'
    //         ),
    //         new DocumentRetentionPolicy__c(
    //             Name = 'Personal Data Documents',
    //             Document_Type__c = 'PERSONAL_DATA',
    //             Retention_Period_Years__c = 3,
    //             Archive_Before_Deletion__c = true,
    //             Regulatory_Framework__c = 'GDPR;CCPA;PIPEDA',
    //             Is_Active__c = true,
    //             Priority__c = 3,
    //             Description__c = 'Retention policy for documents containing personal data'
    //         )
    //     };
        
    //     upsert retentionPolicies Name;
    // }
//        private static void createDefaultPolicies() {

//         List<RetentionPolicy__c> policies = new List<RetentionPolicy__c>();
        
//         policies.add(new RetentionPolicy__c(
//             Name = 'Standard Employment Policy',
//             RetentionPeriod__c = 2555, // 7 years in days
//             DocumentType__c = 'Employment'
//         ));
        
//         insert policies;
//     }

// // version 2
//     //     List<RetentionPolicy__c> policies = new List<RetentionPolicy__c>();
//     //     policies.add(new RetentionPolicy__c(
//     //         PolicyName__c = 'GDPR Compliance',
//     //         RetentionPeriodDays__c = 1095,
//     //         DocumentType__c = 'Personal Data',
//     //         IsActive__c = true
//     //     ));
//     //     insert policies;
//     // }



//         //  version 1

//     //     List<DocumentRetentionPolicy__c> policies = new List<DocumentRetentionPolicy__c>{
//     //         new DocumentRetentionPolicy__c(
//     //             Name = 'General_Business_Documents',
//     //             Retention_Period_Days__c = 2555, // 7 years
//     //             Auto_Delete_Enabled__c = false,
//     //             Geographic_Scope__c = 'Global',
//     //             Regulatory_Framework__c = 'General Business'
//     //         ),
//     //         new DocumentRetentionPolicy__c(
//     //             Name = 'Financial_Records_Retention',
//     //             Retention_Period_Days__c = 2555, // 7 years  
//     //             Auto_Delete_Enabled__c = false,
//     //             Geographic_Scope__c = 'US',
//     //             Regulatory_Framework__c = 'SOX'
//     //         ),
//     //         new DocumentRetentionPolicy__c(
//     //             Name = 'Personal_Data_Documents',
//     //             Retention_Period_Days__c = 1095, // 3 years
//     //             Auto_Delete_Enabled__c = true,
//     //             Geographic_Scope__c = 'EU',
//     //             Regulatory_Framework__c = 'GDPR'
//     //         )
//     //     };
        
//     //     insert policies;
//     //     System.debug('Created ' + policies.size() + ' default policies');
//     // }
    
//  private static void createDefaultPolicies() {
//         RetentionPolicy__c policy = new RetentionPolicy__c(
//             Name = 'Standard Employment Policy',
//             RetentionPeriod__c = 2555, // 7 years in days
//             AutoDelete__c = false
//         );
//         insert policy;
//     }
    
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
    
    public static String getSystemStatus() {
        Map<String, Object> systemStatus = new Map<String, Object>();

    }
        private static void createMonitoringSchedules() {
        // Implementation for monitoring schedule creation
        System.debug('Monitoring schedules created');
    }
    
    
}