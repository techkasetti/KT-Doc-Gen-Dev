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
           @AuraEnabled
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
        return [SELECT Id, RequiredKeyword__c, Region__c, DocumentType__c 
                FROM ComplianceRule__c 
                WHERE Region__c = :region AND DocumentType__c = :documentType];
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
        private static void logComplianceViolation(String clauseText, String region, String missingKeyword) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Compliance Violation',
            Details__c = 'Missing required keyword: ' + missingKeyword + ' in region: ' + region,
            Timestamp__c = System.now(),
            Status__c = 'Failed'
        );
        insert audit;
    }
        
    private static void logComplianceViolation(ComplianceRule__c rule, String missingKeyword, String clauseText) {
        AuditTrail__c audit = new AuditTrail__c(
            EventType__c = &#39;Compliance Violation&#39;,
            Description__c = &#39;Missing required keyword: &#39; + missingKeyword + &#39; for rule: &#39; + rule.RuleName__c,
            Timestamp__c = System.now(),
            UserId__c = UserInfo.getUserId()
        );
        insert audit;
    }


        
    private static void logComplianceSuccess(String clauseText, String region) {
               AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'COMPLIANCE_SUCCESS',
            Timestamp__c = DateTime.now(), 
            UserDetails__c = UserInfo.getUserName(),
            AdditionalInfo__c = 'Compliance validated for region: ' + region
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

    private static void logComplianceSuccess(String clauseText, String region, String documentType) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Compliance Check Passed',
            Details__c = 'Region: ' + region + ', Type: ' + documentType,
            Timestamp__c = System.now(),
            Status__c = 'Success'
        );
        insert audit;
    }
}


        public static Boolean validateClause(String clauseText, String region, String documentType) {
        try {
            List<ComplianceRule__c> rules = getComplianceRules(region, documentType);
            
            for (ComplianceRule__c rule : rules) {
                if (!clauseText.toLowerCase().contains(rule.RequiredKeyword__c.toLowerCase())) {
                    logComplianceViolation(clauseText, rule);
                    return false;
                }
            }
            logComplianceSuccess(clauseText, region);
            return true;
        } catch (Exception e) {
            System.debug('Compliance check failed: ' + e.getMessage());
            return false;
        }
    }
    private static List<ComplianceRule__c> getComplianceRules(String region, String documentType) {
        return [SELECT RequiredKeyword__c, RuleName__c 
                FROM ComplianceRule__c 
                WHERE Region__c = :region 
                AND DocumentType__c = :documentType 
                AND IsActive__c = true];
    }

        private static void logComplianceViolation(String clauseText, ComplianceRule__c violatedRule) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Compliance Violation',
            Details__c = 'Rule violated: ' + violatedRule.RuleName__c,
            Timestamp__c = System.now(),
            UserId__c = UserInfo.getUserId()
        );
        insert audit;
    }


}
