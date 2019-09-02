global with sharing class FieldPickerController {

    @AuraEnabled(cacheable=true)
    public static List<Member> getObjects() {
        List<Member> result = new List<Member>();
//        //User Interface API implementation, requires whitelisting the org.
//        Http h = new Http();
//        HttpRequest httpReq = new HttpRequest();
//        httpReq.setMethod('GET');
//        httpReq.setEndpoint(System.URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v46.0/ui-api/object-info');
//        //Session Id can not be retrieved in lightning context, thus we will have to create named credentials for accessing the data.
//        String sessionId = '***';
//        httpReq.setHeader('Authorization', 'Bearer ' + sessionId);
//        HttpResponse res = h.send(httpReq);
//        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
//        Map<String, Object> allSupportedObjects = (Map<String, Object>) root.get('objects');
//        for (String objectApiName : allSupportedObjects.keySet()) {
//            Map<String, Object> objectInfo = (Map<String, Object>) allSupportedObjects.get(objectApiName);
//            result.add(new Member(objectApiName, (String) objectInfo.get('label')));
//        }
//
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        for (Schema.SObjectType thisObj : gd.values()) {
            result.add(new Member(thisObj.getDescribe().getName(), thisObj.getDescribe().getLabel()));
        }

        return result;
    }

    global class Member {
        @AuraEnabled global String label;
        @AuraEnabled global String value;
        public Member(String value, String label) {
            this.label = label;
            this.value = value;
        }
    }
}