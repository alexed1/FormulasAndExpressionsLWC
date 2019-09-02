global with sharing class SearchUtils {

    static final Map<String, String> TYPE_TO_SOBJECT = new Map<String, String>{
            'User' => 'User',
            'Role_subordinates' => 'UserRole',
            'Role' => 'UserRole',
            'Group' => 'Group',
            'Queue' => 'Group'
    };

    static final Map<String, String> TYPE_TO_QUERY_CRITERIA = new Map<String, String>{
            'User' => 'WHERE IsActive = true AND Name LIKE (searchString)',
            'Role_subordinates' => 'WHERE Name LIKE (searchString)',
            'Role' => 'WHERE Name LIKE (searchString)',
            'Group' => 'WHERE (Type = \'Public\' OR Type = \'Regular\') AND Name LIKE (searchString)',
            'Queue' => 'WHERE Type = \'Queue\' AND Name LIKE (searchString)'
    };


    @AuraEnabled(cacheable=true)
    public static Map<String, List<Member>> searchMemberByType(List<String> memberTypes, String searchString) {
        Map<String, List<Member>> resultMap = new Map<String, List<Member>>();

        for (String curType : TYPE_TO_SOBJECT.keySet()) {

            if (!memberTypes.contains(curType)) {
                continue;
            }
            String queryString = 'SELECT Id, Name FROM ' + TYPE_TO_SOBJECT.get(curType) + ' ' + TYPE_TO_QUERY_CRITERIA.get(curType).replace('(searchString)', '\'%' + String.escapeSingleQuotes(searchString) + '%\'');

            List<SObject> types = Database.query(queryString);
            List<Member> members = new List<Member>();
            for (SObject t : types) {
                members.add(new Member((String) t.get('Name'), (String) t.get('Id')));
            }
            resultMap.put(curType, members);
        }

        return resultMap;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Member>> searchMemberByObjectFieldType(Id recordId, String fieldType, List<String> allowedFieldApiNames) {
        List<Member> result = new List<Member>();
        if (recordId == null) {
            return new Map<String, List<Member>>{
                    fieldType => result
            };
        }
        Schema.SObjectType token = recordId.getSObjectType();
        Map<String, Schema.SObjectField> mfields = token.getDescribe().fields.getMap();

        for (String fieldName : mfields.keySet()) {
            //TODO:handle mixed case field names
            if (allowedFieldApiNames != null && allowedFieldApiNames.size()>0 && !allowedFieldApiNames.contains(fieldName)) {
                continue;
            }

            Schema.DescribeFieldResult obj = mfields.get(fieldName).getDescribe();
            String fieldLabel = obj.getLabel();
            List<SObjectType> refs = obj.getReferenceTo();
            if (refs != null && refs.size() > 0) {
                for (Schema.sObjectType ref : refs) {
                    String curFieldType = ref.getDescribe().getLabel();
                    if (fieldType != null && fieldType != curFieldType) {
                        continue;
                    }
                    result.add(new Member(fieldLabel, fieldName));
                }

            }
        }

        return new Map<String, List<Member>>{
                fieldType => result
        };
    }
    public static Map<String, String> getMembersByTypeAndId(Map<String, Set<String>> typeToIds) {

        Map<String, String> results = new Map<String, String>();
        for (String sObjectTypeName : typeToIds.keySet()) {
            Set<String> objectIds = typeToIds.get(sObjectTypeName);
            String queryString = 'SELECT Id, Name FROM ' + TYPE_TO_SOBJECT.get(sObjectTypeName) + ' WHERE Id IN: objectIds';

            List<SObject> members = Database.query(queryString);
            for (SObject curMember : members) {
                results.put((String) curMember.get('Id'), (String) curMember.get('Name'));
            }
        }
        return results;
    }

    global class Member {
        @AuraEnabled global String label;
        @AuraEnabled global String value;
        public Member(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}