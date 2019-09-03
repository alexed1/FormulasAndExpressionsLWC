public with sharing class FormulaBuilderController {

    @AuraEnabled
    public static String parseFormula(String formula, String context) {
        List<ContextWraper> contextResult = (List<ContextWraper>)JSON.deserialize(context, List<ContextWraper>.class);
        Map<String, String> mapParameters = new Map<String, String>();

        for (ContextWraper cont : contextResult) {
            if (!String.isEmpty(cont.value) && cont.fields.size() > 0) {
                String keyPrefix = cont.value.substring(0,3);
                for (Schema.SObjectType obj : Schema.getGlobalDescribe().Values()){
                    String prefix = obj.getDescribe().getKeyPrefix();
                    if (prefix == keyPrefix && prefix.indexOf(keyPrefix) != -1){
                        String objectAPIName = obj.getDescribe().getName();
                        formula = formula.replaceAll('[$]Record', '\\$' + objectAPIName);
                        formula = formula.replaceAll('[!]Record', '\\!' + objectAPIName);
                        cont.name = objectAPIName;
                        break;
                    }
                }
            }
            if (!String.isEmpty(cont.value) && cont.fields.size() == 0) {
                formula = formula.replaceAll(cont.name, cont.value);
            }
            if (!String.isEmpty(cont.value) && cont.fields.size() > 0) {
                mapParameters.put(cont.name, cont.value);
            }
        }

        Pattern mPattern = pattern.compile('[$!{]{1,2}[A-z_.]*[}]{0,}');
        Matcher mMatcher = mPattern.matcher(formula);
        List<String> variables = new List<String>();

        while(mMatcher.find()){
            variables.add(mMatcher.group(0));
        }

        Map<String, Set<String>> objectWithFields = new Map<String, Set<String>>();

        for(String variable : variables) {
            List<String> splitedValue = variable.replace('$', '').replace('{!', '').replace('}', '').split('[.]', 2);
            String contectVariableName = splitedValue[0];

            if (splitedValue.size() > 1) {
                if (objectWithFields.containsKey(contectVariableName)) {
                    Set<String> fields = objectWithFields.get(contectVariableName);
                    fields.add(splitedValue[1]);
                    objectWithFields.put(contectVariableName, fields);
                } else {
                    Set<String> fields = new Set<String>();
                    fields.add(splitedValue[1]);
                    objectWithFields.put(contectVariableName, fields);
                }
            } else if (mapParameters.containsKey(contectVariableName)) {
                String replaceValue = '[$!{]{1,2}' + contectVariableName + '[}]{0,}';
                formula = formula.replaceAll(replaceValue, mapParameters.get(contectVariableName));
            }
        }

        if (objectWithFields.containsKey('User')) {
            formula = updateFormulaFields('User', UserInfo.getUserId(), formula, objectWithFields.get('User'));
        }

        if (objectWithFields.containsKey('Organization')) {
            formula = updateFormulaFields('Organization', UserInfo.getOrganizationId(), formula, objectWithFields.get('Organization'));
        }

        if (objectWithFields.containsKey('Profile')) {
            formula = updateFormulaFields('Profile', UserInfo.getProfileId(), formula, objectWithFields.get('Profile'));
        }

        if (objectWithFields.containsKey('Setup')) {
            Set<String> dataSet = objectWithFields.get('Setup');
            Map<String, Set<String>> objectAndField = new Map<String, Set<String>>();
            for (String variable : dataSet) {
                List<String> data = variable.split('[.]', 2);
                String objectName = data[0];
                if (objectAndField.containsKey(objectName)) {
                    Set<String> fields = objectAndField.get(objectName);
                    fields.add(data[1]);
                    objectAndField.put(objectName, fields);
                } else {
                    Set<String> fields = new Set<String>();
                    fields.add(data[1]);
                    objectAndField.put(objectName, fields);
                }
            }

            for (String objectName : objectAndField.keySet()) {
                formula = updateFormulaFields(objectName, '', formula, objectAndField.get(objectName));
            }
        }

        for (String contextVariableName : mapParameters.keySet()) {
            if (objectWithFields.containsKey(contextVariableName)) {
                formula = updateFormulaFields(contextVariableName, mapParameters.get(contextVariableName), formula, objectWithFields.get(contextVariableName));
            }
        }

        Set<String> resultTypes = new Set<String>{'BOOLEAN', 'NUMBER', 'DATE', 'DATETIME', 'STRING'};

        for (String resultType : resultTypes) {
            String result = FormulaEvaluator.evaluateFormula(formula, resultType);
            if (!String.isEmpty(result)) {
                return result;
            }
        }
        
        formula = formula.replaceAll('["]', '');
        mPattern = pattern.compile('[A-z0-9 ]{1,}');
        mMatcher = mPattern.matcher(formula);

        while (mMatcher.find()) {
            String item = '"' + mMatcher.group(0).trim() + '"';
            formula = formula.replaceFirst(mMatcher.group(0), item);
        }

        return FormulaEvaluator.evaluateFormula(formula, 'STRING');

    }

    public static String updateFormulaFields (String objectName, String objectId, String formula, Set<String> fields) {

        String queryString = 'SELECT ';

        for (String field : fields) {
            queryString = queryString + field + ', ';
        }

        queryString = queryString.removeEnd(', ');

        if (String.isEmpty(objectId)) {
            queryString = queryString + ' FROM ' + objectName + ' LIMIT 1';
        } else {
            queryString = queryString + ' FROM ' + objectName + ' WHERE Id =\'' + objectId + '\' LIMIT 1';
        }

        List<sObject> objectInfo = Database.query(queryString);

        if (objectInfo.size() > 0) {
            for (String field : fields) {
                String replaceValue = '[$!{]{1,2}';
                if (String.isEmpty(objectId)) {
                    replaceValue = replaceValue + 'Setup.' + objectName + '.' + field + '[}]{0,}';
                } else {
                    replaceValue = replaceValue + objectName + '.' + field + '[}]{0,}';
                }
                formula = formula.replaceAll(replaceValue, String.valueOf(objectInfo[0].get(field)));
            }
        }
        

        return formula;
    }

    public class ContextWraper {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public List<String> fields;
    }
}
