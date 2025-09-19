public with sharing class SignatureRequestController {
    // Creates a signature request by calling a Named Credential 'DOCSIGN_NC'
    @AuraEnabled
    public static Id createSignatureRequest(String documentId, String recipientEmail) {
        // Build request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DOCSIGN_NC/v1/envelopes');
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json');
        req.setBody(JSON.serialize(new Map<String,Object>{
            'documentId' => documentId,
            'recipient' => recipientEmail
        }));
        Http http = new Http();
        HTTPResponse resp = http.send(req);
        // Record integration call
        Integration_Call__c ic = new Integration_Call__c(Endpoint__c = 'DOCSIGN_CREATE', StatusCode__c = Integer.valueOf(resp.getStatusCode()), Response__c = resp.getBody());
        insert ic;
        // Return a synthetic id (in production map to Envelope id)
        return ic.Id;
    }
}
