public with sharing class ComplianceChecker {
    
    // Compliance rules for different regions and document types
    private static final Map<String, Map<String, List<String>>> COMPLIANCE_RULES = new Map<String, Map<String, List<String>>>{
        'US' => new Map<String, List<String>>{
            'Employment' => new List<String>{'authorized signatory', 'at-will employment', 'binding arbitration'},
            'NDA' => new List<String>{'confidential information', 'injunctive relief', 'monetary damages'},
            'SLA' => new List<String>{'service level', 'uptime', 'performance standards'}
        },
        'EU' => new Map<String, List<String>>{
            'Employment' => new List<String>{'GDPR', 'data portability', 'right to erasure'},
            'NDA' => new List<String>{'GDPR-compliant', 'data subject rights', 'legitimate business interests'},
            'SLA' => new List<String>{'Digital Services Act', 'Standard Contractual Clauses', 'data residency'}
        },
        'APAC' => new Map<String, List<String>>{
            'Employment' => new List<String>{'local labor laws', 'data protection laws', 'local arbitration'},
            'NDA' => new List<String>{'local privacy laws', 'cross-border transfer', 'data localization'},
            'SLA' => new List<String>{'regional technology', 'data residency', 'local regulatory standards'}
        }
    };
    
    // Risk levels for compliance violations
    public enum RiskLevel { LOW, MEDIUM, HIGH, CRITICAL }
    
    /**
     * Validate clause against compliance rules
     * @param clauseText The clause text to validate
     * @param region Geographic region
     * @param contractType Type of contract
     * @return Boolean indicating compliance status
     */
    @AuraEnabled
    public static Boolean validateClause(String clauseText, String region, String contractType) {
        System.debug('Validating compliance for: Region=' + region + ', Type=' + contractType);
        
        try {
            // Input validation
            if (String.isBlank(clauseText) || String.isBlank(region) || String.isBlank(contractType)) {
                throw new IllegalArgumentException('All parameters are required for compliance validation');
            }
            
            // Get compliance rules for region and contract type
            List<String> requiredTerms = getComplianceRules(region, contractType);
            if (requiredTerms == null || requiredTerms.isEmpty()) {
                System.debug('⚠ No compliance rules found for ' + region + ' ' + contractType);
                logComplianceCheck(region, contractType, 'WARNING', 'No rules found');
                return true; // Default to compliant if no rules
            }
            
            // Check for required terms
            List<String> missingTerms = new List<String>();
            String clauseLower = clauseText.toLowerCase();
            
            for (String term : requiredTerms) {
                if (!clauseLower.contains(term.toLowerCase())) {
                    missingTerms.add(term);
                }
            }
            
            Boolean isCompliant = missingTerms.isEmpty();
            String status = isCompliant ? 'SUCCESS' : 'VIOLATION';
            String details = isCompliant ? 'All required terms present' : 'Missing terms: ' + String.join(missingTerms, ', ');
            
            // Log compliance check
            logComplianceCheck(region, contractType, status, details);
            
            // Create compliance record for tracking
            createComplianceRecord(clauseText, region, contractType, isCompliant, missingTerms);
            
            System.debug(isCompliant ? '✓ Clause is compliant' : '✗ Clause has violations: ' + details);
            return isCompliant;
            
        } catch (Exception e) {
            System.debug('✗ Compliance validation failed: ' + e.getMessage());
            logComplianceCheck(region, contractType, 'ERROR', e.getMessage());
            throw new AuraHandledException('Compliance validation failed: ' + e.getMessage());
        }
    }
    
    /**
     * Get detailed compliance analysis
     * @param clauseText The clause text to analyze
     * @param region Geographic region
     * @param contractType Type of contract
     * @return Detailed compliance analysis
     */
    @AuraEnabled
    public static Map<String, Object> getDetailedComplianceAnalysis(String clauseText, String region, String contractType) {
        Map<String, Object> analysis = new Map<String, Object>();
        
        try {
            List<String> requiredTerms = getComplianceRules(region, contractType);
            List<String> presentTerms = new List<String>();
            List<String> missingTerms = new List<String>();
            
            String clauseLower = clauseText.toLowerCase();
            
            for (String term : requiredTerms) {
                if (clauseLower.contains(term.toLowerCase())) {
                    presentTerms.add(term);
                } else {
                    missingTerms.add(term);
                }
            }
            
            // Calculate compliance score
            Decimal complianceScore = requiredTerms.isEmpty() ? 100 : 
                (Decimal.valueOf(presentTerms.size()) / Decimal.valueOf(requiredTerms.size())) * 100;
            
            // Determine risk level
            RiskLevel risk = calculateRiskLevel(missingTerms.size(), requiredTerms.size());
            
            analysis.put('isCompliant', missingTerms.isEmpty());
            analysis.put('complianceScore', complianceScore);
            analysis.put('riskLevel', risk.name());
            analysis.put('presentTerms', presentTerms);
            analysis.put('missingTerms', missingTerms);
            analysis.put('totalRequiredTerms', requiredTerms.size());
            analysis.put('region', region);
            analysis.put('contractType', contractType);
            analysis.put('analysisDate', DateTime.now());
            
            // Add recommendations
            analysis.put('recommendations', generateRecommendations(missingTerms, region, contractType));
            
            System.debug('✓ Detailed compliance analysis completed: ' + complianceScore + '% compliant');
            
        } catch (Exception e) {
            System.debug('✗ Detailed compliance analysis failed: ' + e.getMessage());
            analysis.put('error', e.getMessage());
        }
        
        return analysis;
    }
    
    /**
     * Get compliance rules for region and contract type
     */
    @TestVisible
    private static List<String> getComplianceRules(String region, String contractType) {
        if (COMPLIANCE_RULES.containsKey(region)) {
            Map<String, List<String>> regionRules = COMPLIANCE_RULES.get(region);
            return regionRules.get(contractType);
        }
        return new List<String>();
    }
    
    /**
     * Calculate risk level based on missing compliance terms
     */
    @TestVisible
    private static RiskLevel calculateRiskLevel(Integer missingCount, Integer totalCount) {
        if (missingCount == 0) return RiskLevel.LOW;
        
        Decimal missingPercentage = (Decimal.valueOf(missingCount) / Decimal.valueOf(totalCount)) * 100;
        
        if (missingPercentage >= 75) return RiskLevel.CRITICAL;
        if (missingPercentage >= 50) return RiskLevel.HIGH;
        if (missingPercentage >= 25) return RiskLevel.MEDIUM;
        return RiskLevel.LOW;
    }
    
    /**
     * Generate recommendations for compliance improvements
     */
    @TestVisible
    private static List<String> generateRecommendations(List<String> missingTerms, String region, String contractType) {
        List<String> recommendations = new List<String>();
        
        if (missingTerms.isEmpty()) {
            recommendations.add('Document meets all compliance requirements for ' + region + ' ' + contractType);
            return recommendations;
        }
        
        for (String missingTerm : missingTerms) {
            switch on missingTerm.toLowerCase() {
                when 'gdpr' {
                    recommendations.add('Add GDPR compliance clause including data subject rights and lawful basis for processing');
                }
                when 'authorized signatory' {
                    recommendations.add('Include authorized signatory clause to establish legal authority for agreement execution');
                }
                when 'data residency' {
                    recommendations.add('Add data residency clause specifying geographic boundaries for data processing and storage');
                }
                when 'binding arbitration' {
                    recommendations.add('Include binding arbitration clause for dispute resolution to avoid costly litigation');
                }
                when else {
                    recommendations.add('Include "' + missingTerm + '" clause to meet ' + region + ' regulatory requirements');
                }
            }
        }
        
        return recommendations;
    }
    
    /**
     * Create compliance record for audit tracking
     */
    @TestVisible
    private static void createComplianceRecord(String clauseText, String region, String contractType, Boolean isCompliant, List<String> missingTerms) {
        try {
            // For now, we'll use custom objects. In a full implementation, you might want a dedicated ComplianceRecord__c object
            AuditTrail__c complianceRecord = new AuditTrail__c(
                Action__c = 'COMPLIANCE_CHECK',
                Status__c = isCompliant ? 'SUCCESS' : 'VIOLATION',
                Timestamp__c = DateTime.now(),
                UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
                SystemInfo__c = 'Compliance validation for ' + region + ' ' + contractType,
                AdditionalData__c = JSON.serialize(new Map<String, Object>{
                    'region' => region,
                    'contractType' => contractType,
                    'isCompliant' => isCompliant,
                    'missingTerms' => missingTerms,
                    'clauseLength' => clauseText.length(),
                    'complianceScore' => missingTerms.isEmpty() ? 100 : 0 // Simplified for this example
                })
            );
            
            insert complianceRecord;
        } catch (Exception e) {
            System.debug('⚠ Could not create compliance record: ' + e.getMessage());
        }
    }
    
    /**
     * Get compliance reports for management
     * @param region Optional region filter
     * @return Compliance statistics and trends
     */
    @AuraEnabled
    public static Map<String, Object> getComplianceReport(String region) {
        Map<String, Object> report = new Map<String, Object>();
        
        try {
            String regionFilter = String.isNotBlank(region) ? 'AND AdditionalData__c LIKE \'%"region":"' + region + '"%\'' : '';
            
            // Get compliance statistics from last 30 days
            String query = 'SELECT Status__c, COUNT(Id) count FROM AuditTrail__c ' +
                          'WHERE Action__c = \'COMPLIANCE_CHECK\' AND CreatedDate = LAST_N_DAYS:30 ' +
                          regionFilter + ' GROUP BY Status__c';
            
            List<AggregateResult> results = Database.query(query);
            
            Integer totalChecks = 0;
            Integer successfulChecks = 0;
            Integer violations = 0;
            
            for (AggregateResult result : results) {
                Integer count = (Integer)result.get('count');
                String status = (String)result.get('Status__c');
                
                totalChecks += count;
                
                if ('SUCCESS'.equals(status)) {
                    successfulChecks += count;
                } else if ('VIOLATION'.equals(status)) {
                    violations += count;
                }
            }
            
            Decimal complianceRate = totalChecks > 0 ? 
                (Decimal.valueOf(successfulChecks) / Decimal.valueOf(totalChecks)) * 100 : 0;
            
            report.put('totalChecks', totalChecks);
            report.put('successfulChecks', successfulChecks);
            report.put('violations', violations);
            report.put('complianceRate', complianceRate);
            report.put('region', region);
                    report.put('reportDate', Date.today());
        report.put('period', 'Last 30 Days');
        
        // Get trending data for compliance over time
        List<AggregateResult> trendingData = [
            SELECT DAY_ONLY(CreatedDate) day, Status__c, COUNT(Id) count
            FROM AuditTrail__c 
            WHERE Action__c = 'COMPLIANCE_CHECK' 
            AND CreatedDate = LAST_N_DAYS:7
            GROUP BY DAY_ONLY(CreatedDate), Status__c
            ORDER BY DAY_ONLY(CreatedDate)
        ];
        
        Map<String, Map<String, Integer>> dailyTrends = new Map<String, Map<String, Integer>>();
        for (AggregateResult trend : trendingData) {
            Date dayOnly = (Date)trend.get('day');
            String dayStr = dayOnly.format();
            String status = (String)trend.get('Status__c');
            Integer count = (Integer)trend.get('count');
            
            if (!dailyTrends.containsKey(dayStr)) {
                dailyTrends.put(dayStr, new Map<String, Integer>{'SUCCESS' => 0, 'VIOLATION' => 0});
            }
            dailyTrends.get(dayStr).put(status, count);
        }
        
        report.put('dailyTrends', dailyTrends);
        
        // Get top violation patterns
        List<String> topViolations = getTopViolationPatterns(region);
        report.put('topViolations', topViolations);
        
        System.debug('✓ Compliance report generated for ' + (String.isBlank(region) ? 'all regions' : region));
        
    } catch (Exception e) {
        System.debug('✗ Compliance report generation failed: ' + e.getMessage());
        report.put('error', e.getMessage());
    }
    
    return report;
}

/**
 * Get top violation patterns for analysis
 */
@TestVisible
private static List<String> getTopViolationPatterns(String region) {
    List<String> patterns = new List<String>();
    try {
        String regionFilter = String.isNotBlank(region) ? 
            'AND AdditionalData__c LIKE \'%"region":"' + region + '"%\'' : '';
        
        String query = 'SELECT AdditionalData__c FROM AuditTrail__c ' +
                      'WHERE Action__c = \'COMPLIANCE_CHECK\' ' +
                      'AND Status__c = \'VIOLATION\' ' +
                      'AND CreatedDate = LAST_N_DAYS:30 ' +
                      regionFilter + ' LIMIT 50';
        
        List<AuditTrail__c> violations = Database.query(query);
        Map<String, Integer> termCounts = new Map<String, Integer>();
        
        for (AuditTrail__c violation : violations) {
            try {
                Map<String, Object> data = (Map<String, Object>)JSON.deserializeUntyped(violation.AdditionalData__c);
                List<Object> missingTerms = (List<Object>)data.get('missingTerms');
                
                if (missingTerms != null) {
                    for (Object term : missingTerms) {
                        String termStr = (String)term;
                        termCounts.put(termStr, termCounts.containsKey(termStr) ? 
                                      termCounts.get(termStr) + 1 : 1);
                    }
                }
            } catch (Exception e) {
                System.debug('⚠ Could not parse violation data: ' + e.getMessage());
            }
        }
        
        // Sort and get top 5 violations
        List<Map<String, Object>> sortedViolations = new List<Map<String, Object>>();
        for (String term : termCounts.keySet()) {
            sortedViolations.add(new Map<String, Object>{
                'term' => term,
                'count' => termCounts.get(term)
            });
        }
        
        // Simple sorting - in production, consider using a proper sort implementation
        for (Integer i = 0; i < Math.min(5, sortedViolations.size()); i++) {
            Map<String, Object> maxViolation = null;
            Integer maxIndex = -1;
            Integer maxCount = -1;
            
            for (Integer j = i; j < sortedViolations.size(); j++) {
                Integer count = (Integer)sortedViolations[j].get('count');
                if (count > maxCount) {
                    maxCount = count;
                    maxViolation = sortedViolations[j];
                    maxIndex = j;
                }
            }
            
            if (maxViolation != null) {
                // Swap elements
                sortedViolations.set(maxIndex, sortedViolations[i]);
                sortedViolations.set(i, maxViolation);
                patterns.add((String)maxViolation.get('term') + ' (' + maxCount + ' violations)');
            }
        }
        
    } catch (Exception e) {
        System.debug('⚠ Could not analyze violation patterns: ' + e.getMessage());
        patterns.add('Analysis unavailable');
    }
    
    return patterns;
}

/**
 * Log compliance check activity
 */
@TestVisible
private static void logComplianceCheck(String region, String contractType, String status, String details) {
    try {
        AuditTrail__c auditLog = new AuditTrail__c(
            Action__c = 'COMPLIANCE_CHECK',
            Status__c = status,
            Timestamp__c = DateTime.now(),
            UserDetails__c = UserInfo.getName() + ' (' + UserInfo.getUsername() + ')',
            SystemInfo__c = 'Compliance check for ' + region + ' ' + contractType + ': ' + details,
            AdditionalData__c = JSON.serialize(new Map<String, Object>{
                'region' => region,
                'contractType' => contractType,
                'details' => details,
                'timestamp' => DateTime.now().format(),
                'userId' => UserInfo.getUserId()
            })
        );
        
        insert auditLog;
    } catch (Exception e) {
        System.debug('⚠ Could not log compliance check: ' + e.getMessage());
    }
}

/**
 * Batch validate multiple clauses
 * @param clauseRequests List of clause validation requests
 * @return List of validation results
 */
@AuraEnabled
public static List<Map<String, Object>> batchValidateClauses(List<Map<String, String>> clauseRequests) {
    List<Map<String, Object>> results = new List<Map<String, Object>>();
    
    try {
        for (Map<String, String> request : clauseRequests) {
            String clauseText = request.get('clauseText');
            String region = request.get('region');
            String contractType = request.get('contractType');
            
            Map<String, Object> result = getDetailedComplianceAnalysis(clauseText, region, contractType);
            result.put('requestId', request.get('id')); // For tracking
            results.add(result);
        }
        
        System.debug('✓ Batch validation completed for ' + results.size() + ' clauses');
    } catch (Exception e) {
        System.debug('✗ Batch validation failed: ' + e.getMessage());
        throw new AuraHandledException('Batch validation failed: ' + e.getMessage());
    }
    
    return results;
}

/**
 * Get compliance dashboard data
 * @return Dashboard statistics and metrics
 */
@AuraEnabled
public static Map<String, Object> getComplianceDashboard() {
    Map<String, Object> dashboard = new Map<String, Object>();
    
    try {
        // Overall compliance metrics
        List<AggregateResult> overallStats = [
            SELECT Status__c, COUNT(Id) count
            FROM AuditTrail__c 
            WHERE Action__c = 'COMPLIANCE_CHECK' 
            AND CreatedDate = LAST_N_DAYS:30
            GROUP BY Status__c
        ];
        
        Integer totalChecks = 0;
        Integer violations = 0;
        for (AggregateResult stat : overallStats) {
            Integer count = (Integer)stat.get('count');
            totalChecks += count;
            if ('VIOLATION'.equals(stat.get('Status__c'))) {
                violations += count;
            }
        }
        
        dashboard.put('totalChecks', totalChecks);
        dashboard.put('violations', violations);
        dashboard.put('complianceRate', totalChecks > 0 ? 
                     ((totalChecks - violations) * 100.0 / totalChecks) : 100);
        
        // Regional breakdown
        Map<String, Object> regionalData = new Map<String, Object>();
        for (String region : new List<String>{'US', 'EU', 'APAC'}) {
            Map<String, Object> regionReport = getComplianceReport(region);
            regionalData.put(region, regionReport);
        }
        dashboard.put('regionalBreakdown', regionalData);
        
        // Recent activity
        List<AuditTrail__c> recentActivity = [
            SELECT CreatedDate, Status__c, SystemInfo__c
            FROM AuditTrail__c
            WHERE Action__c = 'COMPLIANCE_CHECK'
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        
        List<Map<String, Object>> activityList = new List<Map<String, Object>>();
        for (AuditTrail__c activity : recentActivity) {
            activityList.add(new Map<String, Object>{
                'date' => activity.CreatedDate,
                'status' => activity.Status__c,
                'description' => activity.SystemInfo__c
            });
        }
        dashboard.put('recentActivity', activityList);
        
        dashboard.put('lastUpdated', DateTime.now());
        
        System.debug('✓ Compliance dashboard data compiled');
        
    } catch (Exception e) {
        System.debug('✗ Dashboard compilation failed: ' + e.getMessage());
        dashboard.put('error', e.getMessage());
    }
    
    return dashboard;
}
}
