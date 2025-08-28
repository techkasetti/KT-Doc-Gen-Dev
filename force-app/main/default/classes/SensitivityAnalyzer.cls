// Additional utility classes for workflow components 

public class SensitivityAnalyzer { 
    
    public static String analyzeSensitivity(String documentId) { 
        try { 
            DocumentAnalysisRecord__c analysis = [ 
                SELECT Key_Topics__c, Content_Analysis__c 
                FROM DocumentAnalysisRecord__c 
                WHERE Document__c = :documentId 
                ORDER BY CreatedDate DESC 
                LIMIT 1 
            ]; 
            
            Integer sensitivityScore = 0; 
            List<String> topics = analysis.Key_Topics__c != null 
                ? analysis.Key_Topics__c.split(';') 
                : new List<String>(); 
            
            // Score based on content type 
            // for (String topic : topics) { 
            //     switch (topic) { 
            //         case 'PERSONAL_DATA': 
            //             sensitivityScore += 30; 
            //             break; 
            //         case 'FINANCIAL': 
            //             sensitivityScore += 25; 
            //             break; 
            //         case 'MEDICAL': 
            //             sensitivityScore += 35; 
            //             break; 
            //         case 'CONFIDENTIAL': 
            //             sensitivityScore += 40; 
            //             break; 
            //         case 'CONTRACT': 
            //             sensitivityScore += 20; 
            //             break; 
            //         case 'LEGAL': 
            //             sensitivityScore += 25; 
            //             break; 
            //         case 'BIOMETRIC': 
            //             sensitivityScore += 45; 
            //             break; 
            //         case 'INTELLECTUAL_PROPERTY': 
            //             sensitivityScore += 35; 
            //             break; 
            //         default: 
            //             sensitivityScore += 5; 
            //             break; 
            //     } 
            // } 
            for (String topic : topics) {
                switch on topic {
                    when 'PERSONAL_DATA' {
                        sensitivityScore += 30;
                    }
                    when 'FINANCIAL' {
                        sensitivityScore += 25;
                    }
                    when 'MEDICAL' {
                        sensitivityScore += 35;
                    }
                    when 'CONFIDENTIAL' {
                        sensitivityScore += 40;
                    }
                    when 'CONTRACT' {
                        sensitivityScore += 20;
                    }
                    when 'LEGAL' {
                        sensitivityScore += 25;
                    }
                    when 'BIOMETRIC' {
                        sensitivityScore += 45;
                    }
                    when 'INTELLECTUAL_PROPERTY' {
                        sensitivityScore += 35;
                    }
                    when else {
                        sensitivityScore += 5;
                    }
                }
            }


            // Additional scoring based on document content analysis 
            if (analysis.Content_Analysis__c != null) { 
                Map<String, Object> contentAnalysis = 
                    (Map<String, Object>) JSON.deserializeUntyped(analysis.Content_Analysis__c); 
                List<String> entities = (List<String>) contentAnalysis.get('extractedEntities'); 
                
                if (entities != null) { 
                    for (String entity : entities) { 
                        if (entity.startsWith('EMAIL:') || entity.startsWith('SSN:') || entity.startsWith('PHONE:')) { 
                            sensitivityScore += 15; 
                        } 
                    } 
                } 
            } 

            // Classify sensitivity level 
            if (sensitivityScore >= 80) { 
                return 'CRITICAL'; 
            } else if (sensitivityScore >= 60) { 
                return 'HIGH'; 
            } else if (sensitivityScore >= 30) { 
                return 'MEDIUM'; 
            } else { 
                return 'LOW'; 
            } 
            
        } catch (Exception e) { 
            return 'UNKNOWN'; 
        } 
    } 
}
