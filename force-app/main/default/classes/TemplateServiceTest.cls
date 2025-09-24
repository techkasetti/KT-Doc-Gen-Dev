@IsTest
private class TemplateServiceTest {
  @TestSetup static void setup() {
    DocumentTemplate__c t = new DocumentTemplate__c(Name='UT Template', Template_Content__c='Hello <<name>>', Default_Output_Format__c='PDF', Region__c='US');
    insert t;
  }

  @IsTest static void testGetTemplate() {
    DocumentTemplate__c t = [SELECT Id FROM DocumentTemplate__c LIMIT 1];
    Test.startTest();
    DocumentTemplate__c res = TemplateService.getTemplate(t.Id);
    Test.stopTest();
    System.assertNotEquals(null, res);
  }
}
