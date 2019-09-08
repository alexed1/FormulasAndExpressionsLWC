public with sharing class UpdateFieldAction {
    @InvocableMethod(label='Update Field')
    public static void updateField(List<UpdateFieldActionRequest> requests) {
        for (UpdateFieldActionRequest request : requests) {
            System.debug(request);
            List<ContextWraper> contextWrapers = new List<ContextWraper>();
            contextWrapers.add(new ContextWraper('$Record', request.objectId));

            String fieldValue = FormulaEvaluator.parseFormula(request.formula, JSON.serialize(contextWrapers));
            System.debug(fieldValue);
            String objectAPIName;
            String keyPrefix = request.objectId.substring(0,3);

            for (Schema.SObjectType obj : Schema.getGlobalDescribe().Values()){
                String prefix = obj.getDescribe().getKeyPrefix();
                if (prefix == keyPrefix && prefix.indexOf(keyPrefix) != -1){
                    objectAPIName = obj.getDescribe().getName();
                    break;
                }
            }

            Schema.DescribeSObjectResult describeObject = Schema.getGlobalDescribe().get(objectAPIName).getDescribe();
            Map<String, Schema.SObjectField> fields = describeObject.fields.getMap();
            String fieldType = String.valueOf(fields.get(request.fieldName).getDescribe().type);

            sObject currentObject = Schema.getGlobalDescribe().get(objectAPIName).newSObject();
            currentObject.put('Id', request.objectId);

            if (fieldType == 'BOOLEAN') {
                currentObject.put(request.fieldName, Boolean.valueOf(fieldValue));
            } else if (fieldType == 'CURRENCY' || fieldType == 'PERCENT' || fieldType == 'DOUBLE') {
                currentObject.put(request.fieldName, Decimal.valueOf(fieldValue));
            } else if (fieldType == 'DATE') {
                currentObject.put(request.fieldName, Date.valueOf(fieldValue));
            } else if (fieldType == 'DATETIME') {
                currentObject.put(request.fieldName, Datetime.valueOf(fieldValue));
            } else if (fieldType == 'INTEGER') {
                currentObject.put(request.fieldName, Integer.valueOf(fieldValue));
            } else {
                currentObject.put(request.fieldName, fieldValue);
            }

            Database.SaveResult result = Database.update(currentObject, true);

            if (!result.isSuccess()) {
                throw new UpdateFieldActionException(result.getErrors()[0].getMessage());
            } 
        }
    }

    public class UpdateFieldActionRequest {
        @InvocableVariable(required=true)
        public String objectId;

        @InvocableVariable(required=true)
        public String fieldName;

        @InvocableVariable(required=true)
        public String formula;
    }

    public class ContextWraper {
        public String name;
        public String value;

        public ContextWraper(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }

    class UpdateFieldActionException extends Exception {}
}
