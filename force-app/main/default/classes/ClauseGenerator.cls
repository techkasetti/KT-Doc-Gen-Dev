public with sharing class ClauseGenerator {
    
    // Static clause templates for different scenarios
    private static final Map<String, Map<String, String>> CLAUSE_TEMPLATES = new Map<String, Map<String, String>>{
        'US' => new Map<String, String>{
            'Employment' => 'This employment agreement is governed by the laws of the United States. The employee acknowledges that they are an at-will employee and that employment may be terminated by either party with or without cause. The employee agrees to maintain confidentiality of all proprietary information and agrees that any disputes will be resolved through binding arbitration.',
            'NDA' => 'This Non-Disclosure Agreement is governed by United States federal and state laws. The receiving party agrees to maintain strict confidentiality of all disclosed information for a period of five (5) years from the date of disclosure. Violation of this agreement may result in injunctive relief and monetary damages.',
            'SLA' => 'This Service Level Agreement establishes performance standards and remedies under United States commercial law. Service provider guarantees 99.9% uptime with penalties for non-compliance. All disputes shall be resolved in United States courts.'
        },
        'EU' => new Map<String, String>{
            'Employment' => 'This employment contract complies with European Union employment directives and GDPR data protection requirements. The employee has the right to data portability and erasure as defined under GDPR Article 17. This agreement is subject to the employment laws of the European Union member state where services are performed.',
            'NDA' => 'This Non-Disclosure Agreement is GDPR-compliant and respects the data subject rights under European Union law. Personal data processing is limited to legitimate business interests. Data retention is limited to three (3) years unless legal obligations require longer retention.',
            'SLA' => 'This Service Level Agreement complies with EU Digital Services Act and GDPR requirements. Data processing activities are documented and data subjects retain full rights under GDPR. Cross-border data transfers comply with Standard Contractual Clauses (SCCs).'
        },
        'APAC' => new Map<String, String>{
            'Employment' => 'This employment agreement is subject to local labor laws and regulations in the Asia-Pacific region. The employee acknowledges compliance with local data protection laws and agrees to dispute resolution through local arbitration procedures.',
            'NDA' => 'This Non-Disclosure Agreement respects local privacy and data protection laws in the Asia-Pacific region. Confidential information is protected according to local standards with appropriate cross-border transfer safeguards.',
            'SLA' => 'This Service Level Agreement complies with regional technology and data localization requirements. Service delivery meets local regulatory standards with appropriate data residency controls.'
        }
    };
    
    private static final Map<String, String> ROLE_SPECIFIC_CLAUSES = new Map<String, String>{
        'Manager' => 'As a management-level employee, you acknowledge additional fiduciary responsibilities and agree to act in the best interests of the company. You are authorized to make decisions within your scope of authority and are responsible for team performance and compliance.',
        'Employee' => 'As an employee, you agree to perform your duties diligently and in accordance with company policies. You acknowledge receipt of the employee handbook and agree to comply with all applicable procedures and standards.',
        'Developer' => 'As a technical team member, you acknowledge access to proprietary code, technical documentation, and system architecture. You agree to follow secure coding practices and protect intellectual property rights in all software development activities.',
        'Admin' => 'As an administrative user, you acknowledge access to sensitive system configurations and data. You agree to maintain system security, follow change management procedures, and protect confidential administrative information.'
    };
    
    /**
     * Generate AI-powered clause based on context
     * @param region Geographic region (US, EU, APAC)
     * @param role User role (Manager, Employee, Developer, Admin)
     * @param contractType Type of contract (Employment, NDA, SLA)
     * @return Generated clause text
     */
    @AuraEnabled
    public static String generateClause(String region, String role, String contractType) {
        System.debug('Generating clause for: Region=' + region + ', Role=' + role + ', Type=' + contractType);
        
        try {
            // Input validation
            if (String.isBlank(region) || String.isBlank(role) || String.isBlank(contractType)) {
                throw new IllegalArgumentException('All parameters (region, role, contractType) are required');
            }
            
            // Get base clause template
            String baseClause = getBaseClause(region, contractType);
            if (String.isBlank(baseClause)) {
                throw new ClauseGenerationException('No template found for region: ' + region + ', contract type: ' + contractType);
            }
            
            // Add role-specific clause
            String roleClause = ROLE_SPECIFIC_CLAUSES.get(role);
            if (String.isBlank(roleClause)) {
                throw new ClauseGenerationException('No role-specific clause found for role: ' + role);
            }
            
            // Combine clauses
            String generatedClause = baseClause + '\n\n' + roleClause;
            
            // Add AI enhancements if enabled
            generatedClause = enhanceWithAI(generatedClause, region, role, contractType);
            
            // Log successful generation
            logClauseGeneration(region, role, contractType, 'SUCCESS', generatedClause.length());
            
            System.debug('✓ Clause generated successfully, length: ' + generatedClause.length());
            return generatedClause;
            
        } catch (Exception e) {
            System.debug('✗ Clause generation failed: ' + e.getMessage());
            logClauseGeneration(region, role, contractType, 'ERROR', 0);
            throw new AuraHandledException('Clause generation failed: ' + e.getMessage());
        }
    }
    
    /**
     * Get base clause template for region and contract type
     */
    @TestVisible
    private static String getBaseClause(String region, String contractType) {
        if (CLAUSE_TEMPLATES.containsKey(region)) {
            Map<String, String> regionTemplates = CLAUSE_TEMPLATES.get(region);
            return regionTemplates.get(contractType);
        }
        return null;
    }
    
    /**
     * Enhance clause with AI-powered improvements
     */
    @TestVisible
    private static String enhanceWithAI(String baseClause, String region, String role, String contractType) {
        try {
            // Check if AI processing is enabled for this configuration
            List<DocumentLifecycleConfiguration__c> configs = [
                SELECT AIProcessingEnabled__c 
                FROM DocumentLifecycleConfiguration__c 
                WHERE Region__c = :region AND Role__c = :role AND ContractType__c = :contractType 
                LIMIT 1
            ];
            
            if (configs.isEmpty() || !configs[0].AIProcessingEnabled__c) {
                System.debug('AI processing disabled, returning base clause');
                return baseClause;
            }
            
            // AI enhancement logic
            String enhancedClause = baseClause;
            
            // Add contextual improvements based on current date and regulations
            enhancedClause += '\n\nThis agreement incorporates the latest regulatory requirements as of ' + 
                            Date.today().format() + ' and will be updated to reflect any changes in applicable law.';
            
            // Add role-specific security clauses for sensitive roles
            if (role == 'Admin' || role == 'Developer') {
                enhancedClause += '\n\nAdditional Security Requirements: You acknowledge that your role requires ' +
                                'enhanced security measures including multi-factor authentication, regular security ' +
                                'training, and compliance with data classification policies.';
            }
            
            // Add region-specific data residency clauses
            if (region == 'EU') {
                enhancedClause += '\n\nData Residency: All personal data will be processed and stored within ' +
                                'European Union boundaries unless explicit consent is provided for cross-border transfers ' +
                                'under approved mechanisms (SCCs, Adequacy Decisions, or Binding Corporate Rules).';
            }
            
            System.debug('✓ Clause enhanced with AI improvements');
            return enhancedClause;
            
        } catch (Exception e) {
            System.debug('⚠ AI enhancement failed, returning base clause: ' + e.getMessage());
            return baseClause;
        }
    }
    
    /**
     * Generate multiple clause variations for A/B testing
     */
    @AuraEnabled
    public static List<String> generateClauseVariations(String region, String role, String contractType, Integer variationCount) {
        List<String> variations = new List<String>();
        
        try {
            if (variationCount == null || variationCount <= 0) {
                variationCount = 3; // Default to 3 variations
            }
            
            // Generate base clause
            String baseClause = generateClause(region, role, contractType);
            variations.add(baseClause);
            
            // Generate variations with different tones and structures
            for (Integer i = 1; i < variationCount; i++) {
                String variation = generateClauseVariation(baseClause, i);
                variations.add(variation);
            }
            
            System.debug('✓ Generated ' + variations.size() + ' clause variations');
            
        } catch (Exception e) {
            System.debug('✗ Clause variation generation failed: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate clause variations: ' + e.getMessage());
        }
        
        return variations;
    }
    
    /**
     * Generate a single variation of the base clause
     */
    @TestVisible
    private static String generateClauseVariation(String baseClause, Integer variationType) {
        String variation = baseClause;
        
        switch on variationType {
            when 1 {
                // Formal variation
                variation = variation.replace('you acknowledge', 'the party acknowledges');
                variation = variation.replace('You agree', 'The party agrees');
                variation += '\n\nFormal Addendum: This agreement constitutes the entire understanding between the parties.';
            }
            when 2 {
                // Detailed variation
                variation += '\n\nDetailed Provisions: This clause includes specific performance metrics, ' +
                           'compliance checkpoints, and regular review procedures to ensure ongoing adherence ' +
                           'to all stated obligations and requirements.';
            }
            when else {
                // Standard variation with additional context
                variation += '\n\nImplementation Note: All provisions of this clause take effect immediately ' +
                           'upon signature and remain binding throughout the duration of the agreement.';
            }
        }
        
        return variation;
    }
    
    /**
     * Get clause generation statistics
     */
    @AuraEnabled
    public static Map<String, Object> getGenerationStatistics() {
        Map<String, Object> stats = new Map<String, Object>();
        
            try {
                // Get audit trail statistics
                List<AggregateResult> auditStats = [
                    SELECT 
                        COUNT(Id) totalGenerations,
                        COUNT_DISTINCT(UserDetails__c) uniqueUsers
                    FROM AuditTrail__c 
                    WHERE Action__c = 'CLAUSE_GENERATED'
                    AND CreatedDate = LAST_N_DAYS:30
                ];
                
                if (!auditStats.isEmpty()) {
                    stats.put('totalGenerations', auditStats[0].get('totalGenerations'));
                    stats.put('uniqueUsers', auditStats[0].get('uniqueUsers'));
                }
                
                // Get success rate
                List<AggregateResult> successStats = [
                    SELECT 
                        Status__c,
                        COUNT(Id) count
                    FROM AuditTrail__c 
                    WHERE Action__c = 'CLAUSE_GENERATED'
                    AND CreatedDate = LAST_N_DAYS:30
                    GROUP BY Status__c
                ];
                
                Integer totalAttempts = 0;
                Integer successfulAttempts = 0;
                
                for (AggregateResult result : successStats) {
                    Integer count = (Integer)result.get('count');
                    totalAttempts += count;
                    
                    if ('SUCCESS'.equals(result.get('Status__c'))) {
                        successfulAttempts += count;
                    }
                }
                
                Decimal successRate = totalAttempts > 0 ? 
                    (Decimal.valueOf(successfulAttempts) / Decimal.valueOf(totalAttempts)) * 100 : 0;
                
                stats.put('successRate', successRate);
                stats.put('totalAttempts', totalAttempts);
                stats.put('lastUpdated', DateTime.now());
                
                System.debug('✓ Generation statistics calculated: ' + stats);
                
            } catch (Exception e) {
                System.debug('✗ Statistics calculation failed: ' + e.getMessage());
                stats.put('error', e.getMessage());
            }
            
            return stats;
        }
        
        /**
         * Log clause generation activity
         */
        @TestVisible
        private static void logClauseGeneration(String region, String role, String contractType, String status, Integer clauseLength) {
            try {
                AuditTrail__c auditLog = new AuditTrail__c(
                    Action__c = 'CLAUSE_GENERATED',
                    Status__c = status,
                    Timestamp__c = DateTime.now(),
                    UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                    SystemInfo__c = 'Generated clause for ' + region + ' ' + role + ' ' + contractType,
                    AdditionalData__c = JSON.serialize(new Map<String, Object>{
                        'region' => region,
                        'role' => role,
                        'contractType' => contractType,
                        'clauseLength' => clauseLength,
                        'timestamp' => DateTime.now().format(),
                        'userId' => UserInfo.getUserId()
                    })
                );
                
                insert auditLog;
            } catch (Exception e) {
                System.debug('⚠ Could not log clause generation: ' + e.getMessage());
            }
        }
        
        /**
         * Custom exception for clause generation errors
         */
        public class ClauseGenerationException extends Exception {}
    }
