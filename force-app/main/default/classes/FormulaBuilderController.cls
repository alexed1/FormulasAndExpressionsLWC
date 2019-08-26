public with sharing class FormulaBuilderController {
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldList(String objectName) {
        List<String> result = new List<String>();

        Schema.DescribeSObjectResult describeObject = Schema.getGlobalDescribe().get(objectName).getDescribe(); 
        Map<String, Schema.SObjectField> fields = describeObject.fields.getMap();

        for(Schema.sObjectField field : fields.values()) { 
            result.add(field.getDescribe().getName());
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static String parseFormula(String formula, String recordId) {
        Pattern mPattern = pattern.compile('[$!{]{1,2}[A-z_.]*[}]{0,}');
        Matcher mMatcher = mPattern.matcher(formula);
        List<String> variables = new List<String>();

        while(mMatcher.find()){
            variables.add(mMatcher.group(0));
        }

        Map<String, Set<String>> objectWithFields = new Map<String, Set<String>>();

        for(String variable : variables) {
            List<String> splitedValue = variable
            .replace('$', '')
            .replace('{!', '')
            .replace('}', '')
            .split('[.]', 2);

            if (splitedValue.size() > 1) {
                if (objectWithFields.containsKey(splitedValue[0])) {
                    Set<String> fields = objectWithFields.get(splitedValue[0]);
                    fields.add(splitedValue[1]);
                    objectWithFields.put(splitedValue[0], fields);
                } else {
                    Set<String> fields = new Set<String>();
                    fields.add(splitedValue[1]);
                    objectWithFields.put(splitedValue[0], fields);
                }
            } 
        }
        
        String preparedResult = formula;

        for (String objectName : objectWithFields.keySet()) {
            String queryString = 'SELECT ';
            for (String field : objectWithFields.get(objectName)) {
                queryString = queryString + field + ', ';
            }
            queryString = queryString.removeEnd(', ');
            queryString = queryString + ' FROM ' + objectName + ' WHERE Id =\'' + recordId + '\' LIMIT 1';
            sObject sobjList = Database.query(queryString);

            for (String field : objectWithFields.get(objectName) ) {
                String replaceValue = '[$!{]{1,2}' + objectName + '.' + field + '[}]{0,}';
                preparedResult = preparedResult.replaceAll(replaceValue, String.valueOf(sobjList.get(field)));
            }
        }

        RegExps.ParserContext parserContext = ApexExpressionParserV2.evaluate(preparedResult, null ,  'Account',  'Number',  2);
        System.debug('formula result is: ' + parserContext);

        EvaluateFormula.Results curResult = new EvaluateFormula.Results();
        curResult.formulaResult = String.valueOf(parserContext.result);
        List<EvaluateFormula.Results> resultsList = new List<EvaluateFormula.Results>();
        resultsList.add(curResult);

        return JSON.serialize(resultsList);
    }
}
