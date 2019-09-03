global with sharing class FieldPickerController {

    @AuraEnabled(cacheable=true)
    public static List<Member> getObjects(List<String> supportedObjectTypes) {

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
            String objectType = thisObj.getDescribe().getName();
            String objectLabel = thisObj.getDescribe().getLabel();
            if (allowedStandardObjects.containsKey(objectType) && (supportedObjectTypes != null && (supportedObjectTypes.contains(objectType.toLowerCase())) || supportedObjectTypes.size() == 0) || supportedObjectTypes == null) {
                result.add(new Member(objectType, objectLabel));
            }
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

    private static Map<String, String> allowedStandardObjects = new Map<String, String>{
            'WorkType' => 'Work Type',
            'WorkOrderLineItem' => 'Work Order Line Item',
            'WorkOrder' => 'Work Order',
            'User' => 'User',
            'TimeSlot' => 'Time Slot',
            'TimeSheetEntry' => 'Time Sheet Entry',
            'TimeSheet' => 'Time Sheet',
            'SkillRequirement' => 'Skill Requirement',
            'Shipment' => 'Shipment',
            'Shift' => 'Shift',
            'ServiceTerritoryMember' => 'Service Territory Member',
            'ServiceTerritoryLocation' => 'Service Territory Location',
            'ServiceTerritory' => 'Service Territory',
            'ServiceResourceSkill' => 'Service Resource Skill',
            'ServiceResourceCapacity' => 'Resource Capacity',
            'ServiceResource' => 'Service Resource',
            'ServiceCrewMember' => 'Service Crew Member',
            'ServiceCrew' => 'Service Crew',
            'ServiceAppointment' => 'Service Appointment',
            'ReturnOrderLineItem' => 'Return Order Line Item',
            'ReturnOrder' => 'Return Order',
            'ResourcePreference' => 'Resource Preference',
            'ResourceAbsence' => 'Resource Absence',
            'RecordType' => 'Record Type',
            'Product2' => 'Product',
            'PricebookEntry' => 'Price Book Entry',
            'Pricebook2' => 'Price Book',
            'Partner' => 'Partner',
            'OrderItem' => 'Order Product',
            'Order' => 'Order',
            'OpportunityPartner' => 'Opportunity Partner',
            'OpportunityLineItem' => 'Opportunity Product',
            'Opportunity' => 'Opportunity',
            'OperatingHours' => 'Operating Hours',
            'Note' => 'Note',
            'MaintenancePlan' => 'Maintenance Plan',
            'MaintenanceAsset' => 'Maintenance Asset',
            'Lead' => 'Lead',
            'Individual' => 'Individual',
            'Image' => 'Image',
            'ContractContactRole' => 'Contract Contact Role',
            'Contract' => 'Contract',
            'ContentWorkspace' => 'Library',
            'ContentVersion' => 'File',
            'ContentDocument' => 'File',
            'ContactRequest' => 'Contact Request',
            'Contact' => 'Contact',
            'Case' => 'Case',
            'CampaignMember' => 'Campaign Member',
            'Campaign' => 'Campaign',
            'AssignedResource' => 'Assigned Resource',
            'AssetRelationship' => 'Asset Relationship',
            'Asset' => 'Asset',
            'AccountPartner' => 'Account Partner',
            'Account' => 'Account'
    };
}