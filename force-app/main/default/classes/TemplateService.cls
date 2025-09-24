public with sharing class TemplateService {
  // Create template
  public static Id createTemplate(DocumentTemplate__c dto) {
    // TODO: validate, sanitize, persist
    insert dto;
    return dto.Id;
  }

  // Update template
  public static void updateTemplate(DocumentTemplate__c dto) {
    // TODO: merge logic, versioning
    update dto;
  }

  // Get template by Id
  @AuraEnabled(cacheable=true)
  public static DocumentTemplate__c getTemplate(Id templateId) {
    return [SELECT Id, Name, Template_Content__c, Default_Output_Format__c FROM DocumentTemplate__c WHERE Id = :templateId LIMIT 1];
  }

  // Render/merge: returns generated document metadata (store in Document__c)
  public static Document__c renderTemplate(Id templateId, Map<String, Object> mergeData) {
    // TODO: implement merge engine integration
    Document__c doc = new Document__c();
    doc.Name = 'Generated - ' + String.valueOf(templateId);
    // set other fields
    insert doc;
    return doc;
  }
}
