    public with sharing class ComplianceChecker {
        
        @AuraEnabled
        public static Boolean validateClause(String clauseText, String region) {
            try {
                List<ComplianceRule__mdt> rules = getComplianceRules(region);
                
                for (ComplianceRule__mdt rule : rules) {
                    if (rule.IsActive__c && String.isNotBlank(rule.RequiredKeyword__c)) {
                        if (!clauseText.toLowerCase().contains(rule.RequiredKeyword__c.toLowerCase())) {
                            logComplianceViolation(clauseText, region, rule.Label);
                            return false;
                        }
                    }
                }
                
                logComplianceSuccess(clauseText, region);
                return true;
                
            } catch (Exception e) {
                System.debug('Error in validateClause: ' + e.getMessage());
                throw new AuraHandledException('Compliance validation failed: ' + e.getMessage());
            }
        }
        
        public static Boolean validateClause(String clauseText, String region, String documentType) {
            
                    try {
            List<ComplianceRule__c> rules = getComplianceRules(region, documentType);
            
            for (ComplianceRule__c rule : rules) {
                if (!clauseText.contains(rule.RequiredKeyword__c)) {
                    logComplianceViolation(clauseText, rule);
                    return false;
                }
            }
            
            logComplianceSuccess(clauseText, region, documentType);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Compliance validation failed: ' + e.getMessage());
        }

            
            // try {
            //     List<ComplianceRule__c> rules = getComplianceRules(region, documentType);
                
            //     for (ComplianceRule__c rule : rules) {
            //         List<String> requiredKeywords = rule.RequiredKeywords__c.split(';');
                    
            //         Boolean allKeywordsFound = true;
            //         for (String keyword : requiredKeywords) {
            //             if (!clauseText.toLowerCase().contains(keyword.toLowerCase().trim())) {
            //                 allKeywordsFound = false;
            //                 logComplianceViolation(rule, keyword, clauseText);
            //                 break;
            //             }
            //         }
                    
            //         if (!allKeywordsFound) {
            //             return false;
            //         }
            //     }
                
            //     logComplianceSuccess(region, documentType, clauseText);
            //     return true;
                
            // } catch (Exception e) {
            //     System.debug('❌ Compliance validation failed: ' + e.getMessage());
            //     return false;
            // }
            
            // try {
            //         List<ComplianceRule__c> rules = getComplianceRules(region, documentType);
                
            //         for (ComplianceRule__c rule : rules) {
            //                 if (!clauseText.toLowerCase().contains(rule.RequiredKeyword__c.toLowerCase())) {
            //                         logComplianceViolation(clauseText, rule);
            //                         return false;
            //                 }
            //         }
                
            //         logComplianceSuccess(clauseText, region);
            //         return true;
            // } catch (Exception e) {
            //         System.debug('Compliance check failed: ' + e.getMessage());
            //         return false;
            // }
        }
        
        
        private static List<ComplianceRule__mdt> getComplianceRules(String region) {
            return [
            SELECT Label, Region__c, RequiredKeyword__c, ClauseType__c, IsActive__c
            FROM ComplianceRule__mdt 
            WHERE Region__c = :region AND IsActive__c = true
            LIMIT 100
        ];
        }

        
        
        private static List<ComplianceRule__c> getComplianceRules(String region, String documentType) {
            return [SELECT RequiredKeyword__c, RuleName__c 
                FROM ComplianceRule__c 
                WHERE Region__c = :region 
                AND DocumentType__c = :documentType 
                AND IsActive__c = true];
        }
        
        private static void logComplianceViolation(String clauseText, String region, String violatedRule) {
            ContractAudit__c audit = new ContractAudit__c(
                Timestamp__c = System.now(),
            ClauseText__c = clauseText,
            UserId__c = UserInfo.getUserId(),
            ComplianceStatus__c = 'Violation',
            Action__c = 'Compliance Check Failed',
            Region__c = region,
            Notes__c = 'Violated Rule: ' + violatedRule
                );
            insert audit;
        }
         private static void logComplianceViolation(ComplianceRule__c rule, String missingKeyword, String clauseText) {
        AuditTrail__c audit = new AuditTrail__c(
            EventType__c = 'Compliance Violation',
            Description__c = 'Missing required keyword: ' + missingKeyword + ' for rule: ' + rule.RuleName__c,
            Timestamp__c = System.now(),
            UserId__c = UserInfo.getUserId()
        );
        insert audit;
    }
        
        private static void logComplianceViolation(String clauseText, ComplianceRule__c violatedRule) {
            
            
            AuditTrail__c audit = new AuditTrail__c(
                Action__c = 'Compliance Validated',
            Details__c = 'All rules passed for region: ' + region,
            Timestamp__c = System.now(),
            UserId__c = UserInfo.getUserId()
                );
            insert audit;
        }
        
        private static void logComplianceViolation(String clauseText, String region, String missingKeyword) {
            AuditTrail__c audit = new AuditTrail__c(
                Action__c = 'Compliance Violation',
            Details__c = 'Missing required keyword: ' + missingKeyword + ' in region: ' + region,
            Timestamp__c = System.now(),
            Status__c = 'Failed'
                );
            insert audit;
        }
        
        // version 1
        
        // AuditTrail__c audit = new AuditTrail__c(
        //     Action__c = 'Compliance Violation',
        //     Details__c = 'Rule violated: ' + violatedRule.RuleName__c,
        //     Timestamp__c = System.now(),
        //     UserId__c = UserInfo.getUserId()
        // );
        // insert audit;
    //}
    
    private static void logComplianceSuccess(String clauseText, String region) {
        ContractAudit__c audit = new ContractAudit__c(
            Timestamp__c = System.now(),
        ClauseText__c = clauseText,
        UserId__c = UserInfo.getUserId(),
        ComplianceStatus__c = 'Compliant',
        Action__c = 'Compliance Check Passed',
        Region__c = region
            );
        insert audit;
    }
    
    private static void logComplianceSuccess(String clauseText, String region, String documentType) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Compliance Check Passed',
        Details__c = 'Document type: ' + documentType + ' compliant in region: ' + region,
        Timestamp__c = System.now(),
        Status__c = 'Success'
            );
        insert audit;
    }

    private static void logComplianceSuccess(String region, String documentType, String clauseText) {
        AuditTrail__c audit = new AuditTrail__c(
            EventType__c = 'Compliance Success',
            Description__c = 'Clause passed compliance validation for ' + region + '/' + documentType,
            Timestamp__c = System.now(),
            UserId__c = UserInfo.getUserId()
        );
        insert audit;
    }
    
}