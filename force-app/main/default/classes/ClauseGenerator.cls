public with sharing class ClauseGenerator {
    
    @AuraEnabled
    public static String generateClause(String region, String role, String contractType, List<String> clauses) {
        try {
            // Build dynamic clause based on parameters
            String generatedClause = buildClauseContent(region, role, contractType, clauses);
            
            // Log the generation activity
            logClauseGeneration(region, role, contractType, generatedClause);
            
            return generatedClause;
            
        } catch (Exception e) {
            System.debug('Error in generateClause: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate clause: ' + e.getMessage());
        }
    }
    public static String generateClause(String region, String role, String contractType) {
        try {
            String generatedClause = buildDynamicClause(region, role, contractType);
            logClauseGeneration(region, role, contractType, generatedClause);
            return generatedClause;
        } catch (Exception e) {
            System.debug('Clause generation failed: ' + e.getMessage());
            return getDefaultClause(contractType);
        }
    }

    private static String buildClauseContent(String region, String role, String contractType, List<String> clauses) {
        StringBuilder clauseBuilder = new StringBuilder();
        
        // Base clause structure
        clauseBuilder.append('This agreement ');
        
        // Add region-specific compliance
        if (region == 'EU') {
            clauseBuilder.append('complies with GDPR requirements for EU-based ');
        } else if (region == 'US') {
            clauseBuilder.append('adheres to US federal and state regulations for ');
        } else if (region == 'IN') {
            clauseBuilder.append('follows Indian legal requirements for ');
        }
        
        // Add role-specific terms
        clauseBuilder.append(role.toLowerCase() + 's. ');
        
        // Add contract type specifics
        switch on contractType {
            when 'Employment' {
                clauseBuilder.append('The employment terms include standard confidentiality and non-compete provisions. ');
            }
            when 'NDA' {
                clauseBuilder.append('Confidential information shall remain protected for a period of 5 years. ');
            }
            when 'SLA' {
                clauseBuilder.append('Service level commitments are guaranteed with 99.9% uptime. ');
            }
        }
        
        // Add specific clauses if provided
        if (clauses != null && !clauses.isEmpty()) {
            for (String clause : clauses) {
                if (String.isNotBlank(clause)) {
                    clauseBuilder.append(clause + '. ');
                }
            }
        }
        
        return clauseBuilder.toString();
    }
    
    private static void logClauseGeneration(String region, String role, String contractType, String generatedClause) {
        ContractAudit__c audit = new ContractAudit__c(
            Timestamp__c = System.now(),
            ClauseText__c = generatedClause,
            UserId__c = UserInfo.getUserId(),
            Action__c = 'Clause Generated',
            Region__c = region,
            Role__c = role,
            ContractType__c = contractType
        );
        insert audit;
    }

       private static String buildDynamicClause(String region, String role, String contractType) {
        String baseClause = 'This agreement is between the parties ';
        
        // Add region-specific compliance
        if (region == 'EU') {
            baseClause += 'and complies with GDPR data protection requirements ';
        } else if (region == 'US') {
            baseClause += 'and follows applicable US employment laws ';
        }
        
        // Add role-specific terms  
        if (role == 'Manager') {
            baseClause += 'with authorized signatory privileges ';
        } else {
            baseClause += 'subject to management approval ';
        }
        
        // Add contract type specifics
        switch on contractType {
            when 'Employment' {
                baseClause += 'governing employment terms and conditions.';
            }
            when 'NDA' {
                baseClause += 'regarding confidential information handling.';
            }
            when else {
                baseClause += 'as per standard service terms.';
            }
        }
        
        return baseClause;
    }

    
           private static void logClauseGeneration(String region, String role, String contractType, String clause) {
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Clause Generated',
            Details__c = 'Region: ' + region + ', Role: ' + role + ', Type: ' + contractType,
            Timestamp__c = System.now(),
            Status__c = 'Success'
        );
        insert audit;
    }

    private static String getDefaultClause(String contractType) {
        return 'Standard ' + contractType + ' clause applies as per company policy.';
    }
}



}
