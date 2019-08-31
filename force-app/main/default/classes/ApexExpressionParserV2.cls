/*
* Author: Enrico Murru (http://enree.co)
*/
public without sharing class ApexExpressionParserV2 { 
    
    public static List<RegExps.ParserContext> evaluateBulk(List<RegExps.ParserRequest> requests){
        Date expirationDate = PackageSettings__c.getOrgDefaults().Expiration__c;
        if(expirationDate!= null && expirationDate <= System.today()){
            throw new ExpressionParsingException('Apex Formula package evaluation expired on '
                                                 +expirationDate+'. Contact support.');
        }
        
        Map<Id, RegExps.ParserContext> responses = new Map<Id, RegExps.ParserContext>();
        
        //get all fields
        Map<String, Set<String>> allFieldsByObjectType = new Map<String,Set<String>>();
        Map<String, Set<ID>> allObjectIdsByType = new Map<String, Set<ID>>();
        
        for(RegExps.ParserRequest req : requests){
            RegExps.ParserContext context = new RegExps.ParserContext(req.formula, req.objectType, req.objectId, req.outputType, req.scale);
            if(String.isBlank(context.objectId)){
                throw new ExpressionParsingException('Invalid ID for formula "'+req.formula+'"');
            }
            responses.put(context.objectId, context);

            try{
                
                Set<String> fields = new Set<String>();
                Set<ID> objectIds = new Set<Id>();
                ApexExpressionParserV2.getAllFields(context);
                
                if(String.isNotBlank(context.objectType)
                   && allFieldsByObjectType.get(context.objectType) == null){
                       allFieldsByObjectType.put(context.objectType, fields);
                       allObjectIdsByType.put(context.objectType, objectIds);
                   }else{
                       fields = allFieldsByObjectType.get(context.objectType);
                       objectIds = allObjectIdsByType.get(context.objectType);
                   }
                objectIds.add(context.objectId);
                fields.addAll(context.fields);
                
                //ApexExpressionParserV2.getAllValues(context); 
            }catch(Exception e){
                context.isError = true;
                context.stackTrace = e.getStackTraceString()+' '+e.getMEssage();
                context.errorMessage = e.getMessage();
            }
        }
        
        //bluk query (by object type)
        for(String objType : allFieldsByObjectType.keyset()){
            Map<ID,Map<String,Object>> results = 
                ApexExpressionParserV2.getAllValuesBulk(allFieldsByObjectType.get(objType), objType, allObjectIdsByType.get(objType)); 
            for(ID objId : results.keySet()){
                responses.get(objId).fieldValues = results.get(objId);
            }
        }
        
        for(RegExps.ParserContext context : responses.values()){
            if(context.isError) continue;
            try{
                String outputFormula = null;
                ApexExpressionParserV2.replaceExpressionValues(context);
                ApexExpressionParserV2.replaceCustomSettings(context);
                
                //this boolean is used to be aware that a modification has been 
                //done in the "current while iteration": if it becomes true, we
                //add parenthesis to all numeric tokens and do an iteration once again.
                //This will trigger possibile new functions (math expressions need to normalize parentesis,
                //and doing this, can create a situazione in which the algorithm 
                //removes all parentesis, as per ROUND(exp) => ROUND exp)
                Boolean parenthesisAdded = false;
                
                Integer iteration = 0;
                while(true){
                    if(outputFormula == context.outputString){
                        if(parenthesisAdded) break;
                        else{
                            parenthesisAdded = true;
                            RegExps.wrapParentesis(context, 'NUMBER');
                        }
                    }
                    outputFormula = context.outputString;
                    
                    RegExps.evaluateMathExpressions(context);
                    if(outputFormula != context.outputString){
                        RegExps.clearParentesis(context,'NUMBER');
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.evaluateMathFunctions(context);
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.evaluateStringOperations(context);
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.evaluateStringFunctions(context);
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.evaluateCompareExpressions(context);   
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.evaluateBooleanExpressions(context);
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    
                    RegExps.evaluateFlowExpressions(context);
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.evaluateFlowExpressionsCASE(context);
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.evaluateTypeConversionFunctions(context);
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.evaluateDateTimeFunctions(context);
                    if(outputFormula != context.outputString){
                        parenthesisAdded = false;
                        continue;
                    }
                    
                    RegExps.clearParentesis(context,'ALL');
                }
                context.result = RegExps.evaluateResult(context);
            }catch(Exception e){
                context.isError = true;
                context.stackTrace = e.getStackTraceString()+' '+e.getMEssage();
                context.errorMessage = e.getMessage();
            }
        }
        
        return responses.values();
    }
    
    public static Map<ID,Map<String,Object>> getAllValuesBulk(Set<String> fields, String objectType, Set<ID> objectIds){
        fields.add('ID');
        Map<ID,Map<String,Object>> results = new Map<ID,Map<String,Object>>();
        String query = 'Select ';
        query += String.join(new List<String>(fields), ',');
        query+=' From '+objectType+' Where Id IN :objectIds';
        System.debug('## Query: '+query);
        try{
            Map<ID,SObject> oList = new Map<ID,SObject>(Database.query(query));
            /*
            if(oList.size()==0){
            for(String field : fields){
            result.put(field, null);
            }
            //return;// result; 
            }*/
                        /*
            if(objectIds.size() != oList.size()){
            throw new ExpressionParsingException('Query didn\' find all the objects in list '+objectIds);
            }*/
            
            for(ID key : oList.keySet()){
                Map<String,Object> result = new Map<String,Object>();
                results.put(key, result);
                for(String field : fields){
                    SObject tmpObj = oList.get(key);
                    String[] dotSplit = field.split('\\.');
                    for(integer i = 0; i < dotSplit.size(); i++){
                        if(i == dotSplit.size()-1){
                            if(tmpObj == null){
                                result.put(field, null);
                                break;
                            }
                            Object v = tmpObj.get(dotSplit[i]);
                            result.put(field, v);
                            break;
                        }
                        if(tmpObj == null){
                            result.put(field, null);
                            break;
                        }
                        tmpObj = tmpObj.getSObject(dotSplit[i]);
                    }
                }
            }
        }catch(QueryException ex){
            throw new ExpressionParsingException('Invalid expression: '+ex.getMessage()+' ['+query+']');
        }catch(Exception e){
            throw new ExpressionParsingException('Unexpected error: '+e.getMessage()+' ['+query+']');
        }
        return results;
    }

    public static RegExps.ParserContext evaluate(String formula, String outputType, Integer scale){
        return evaluate(formula, null, null, outputType, scale);
    }
    
    public static RegExps.ParserContext evaluate(String formula, ID objectId, String objectType, String outputType, Integer scale){
        Date expirationDate = PackageSettings__c.getOrgDefaults().Expiration__c;
        if(expirationDate!= null && expirationDate <= System.today()){
            throw new ExpressionParsingException('Apex Formula package evaluation expired on '
                                                 +expirationDate+'. Contact support.');
        }
        RegExps.ParserContext context = new RegExps.ParserContext(formula, objectType, objectId, outputType, scale);
        try{
            System.debug('before processing, context is: ' + context);
            String outputFormula = null;

            if (!String.isEmpty(objectType)) {
                ApexExpressionParserV2.getAllFields(context);
                System.debug('after getallfields, context is: ' + context);
                ApexExpressionParserV2.getAllValues(context); 
                System.debug('after getallValues, context is: ' + context);
            }
            
            ApexExpressionParserV2.replaceExpressionValues(context);
            System.debug('after replaceExpressionValues, context is: ' + context);
            ApexExpressionParserV2.replaceCustomSettings(context);
            System.debug('after replaceCustomSettings, context is: ' + context);
            
            //this boolean is used to be aware that a modification has been 
            //done in the "current while iteration": if it becomes true, we
            //add parenthesis to all numeric tokens and do an iteration once again.
            //This will trigger possibile new functions (math expressions need to normalize parentesis,
            //and doing this, can create a situazione in which the algorithm 
            //removes all parentesis, as per ROUND(exp) => ROUND exp)
            Boolean parenthesisAdded = false;
            
            Integer iteration = 0;
            while(true){
                if(outputFormula == context.outputString){
                    if(parenthesisAdded) break;
                    else{
                        parenthesisAdded = true;
                        RegExps.wrapParentesis(context, 'NUMBER');
                    }
                }
                outputFormula = context.outputString;
                
                RegExps.evaluateMathExpressions(context);
                if(outputFormula != context.outputString){
                    RegExps.clearParentesis(context,'NUMBER');
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateMathFunctions(context);
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateStringOperations(context);
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateStringFunctions(context);
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateCompareExpressions(context);   
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateBooleanExpressions(context);
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                
                RegExps.evaluateFlowExpressions(context);
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateFlowExpressionsCASE(context);
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateTypeConversionFunctions(context);
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateDateTimeFunctions(context);
                if(outputFormula != context.outputString){
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.clearParentesis(context,'ALL');
            }
            System.debug('after evaluate prelim calls, context is: ' + context);
            context.result = RegExps.evaluateResult(context);
            System.debug('after final evaluation , context is: ' + context);
        }catch(Exception e){
            context.isError = true;
            context.stackTrace = e.getStackTraceString()+' '+e.getMEssage();
            context.errorMessage = e.getMessage();
        }
        return context;
    }
    
    
    
    /*
* Returns all the fields used in the expression
*/ 
    public static void getAllFields(RegExps.ParserContext context){
        
        String input = context.formula;
        
        input = ' '+input.toUpperCase()+' ';
        input = input.replaceAll(RegExps.EXP_CUSTOM_SETTING_POLISH,' _ ');
        //removes all strings
        input = input.replaceAll(RegExps.EXP_STRING,' _ ');
        
        //removes all comments
        input = input.replaceAll(RegExps.EXP_MULTILINE_COMMENT,'');
        
        input = input.replaceAll(RegExps.EXP_DATETIME,' _ ');
        for(String rc : RegExps.RESERVED_CONSTANTS){
            input = input.replaceAll(rc,' _ ');
        }
        for(String rw : RegExps.RESERVED_WORDS){
            input = input.replaceAll('$'+rw+'[\\s|\\(|,]',' _ ');
        }
        for(String rw : RegExps.RESERVED_WORDS){
            input = input.replaceAll('[\\+|\\-|\\*|/|\\s|\\)|,|\\(]'+rw+'[\\s|\\(|,]',' _ ');
        }
        
        input = input.replaceAll('&&',' _ ');
        input = input.replaceAll('\\|\\|',' _ ');
        input = input.replaceAll('\\^\\^',' _ ');
        input = input.replaceAll('!',' _ ');
        
        
        
        //all other functions
        //throw new ExpressionParsingException(input);
        Pattern myPattern = pattern.compile('('+RegExps.EXP_FIELD+')');
        Matcher m = myPattern.matcher(input.toUpperCase()); 
        Set<String> fields = context.fields;
        Map<String,String> expressionsTmp = new Map<String,String>();
        while(m.find()){
            if(String.isNotBlank(m.group(2)) && m.group(2) != 'NULL' && !Pattern.matches('^'+RegExps.EXP_VALUE+'$', m.group(2))){
                fields.add(m.group(2));
            }
        }
        
        //throw new ExpressionParsingException(input+' '+fields);        
        //removes all other values
        //input = input.replaceAll(RegExps.EXP_VALUE,' _ ');
        
        //removes all comments
        //input = input.replaceAll('/\\*.+?(?=\\*/)\\*/','');
        
        
        //describes to check all fields       
        Map<String,String> fieldTypes = context.fieldTypes; 
        Schema.DescribeSObjectResult sobjDescribe = Schema.getGlobalDescribe().get(context.objectType).getDescribe();
        
        for(String fName : fields){
            String[] dotSplit = fName.split('\\.');
            Schema.DescribeSObjectResult tmpSobjectDescribe = sobjDescribe;
            for(integer i = 0; i < dotSplit.size(); i++){
                //this is the field
                if(i==dotSplit.size()-1){ 
                    Schema.SObjectField sobjF = tmpSobjectDescribe.fields.getMap().get(dotSplit[i]);
                    if(sobjF == null){
                        throw new ExpressionParsingException('Invalid field '+dotSplit[i]+' on field '+fName);
                    }
                    Schema.DescribeFieldResult fieldDescribe = sobjF.getDescribe();
                    fieldTypes.put(fName, String.valueOf(fieldDescribe.getSOAPType()));
                    if(!RegExps.AllowedFieldTypes.contains(fieldTypes.get(fName))){
                        throw new ExpressionParsingException('Invalid field type '+fieldTypes.get(fName)+' for field '+fName);
                    }
                }
                //this is a relation
                else{
                    //search for the lookup field
                    Schema.DescribeFieldResult fieldDescribe = null;
                    Map<String,Schema.SObjectField> soFields = tmpSobjectDescribe.fields.getMap();
                    for(Schema.SObjectField sotype : soFields.values()){
                        Schema.DescribeFieldResult tmp = sotype.getDescribe();
                        if(tmp.getRelationshipName() != dotSplit[i]) continue;
                        fieldDescribe = tmp;
                    }
                    if(fieldDescribe == null){
                        throw new ExpressionParsingException('Invalid relation '+dotSplit[i]+' on field '+fName);
                    }
                    //gets its referring sobject
                    List<Schema.sObjectType> pointing = fieldDescribe.getReferenceTo();
                    if(pointing.size()>1){
                        throw new ExpressionParsingException('Cannot use multi SObject relation on field '+fName);
                    }
                    tmpSobjectDescribe = pointing[0].getDescribe();
                }
                
            }
        }
    }
    
    public static void getAllValues(RegExps.ParserContext context /*Set<String> fields, String objectType, ID objectId*/){
        Set<String> fields = context.fields; 
        String objectType = context.objectType;
        ID objectId = context.objectId;
        System.debug('objectId is' + objectId);
        fields.add('ID');
        Map<String,Object> result = context.fieldValues;
        String query = 'Select ';
        query += String.join(new List<String>(fields), ',');
        query+=' From '+objectType+' Where Id = :objectId';
        System.debug('## Query: '+query);
        try{
            List<SObject> oList = Database.query(query);
            if(oList.size()==0){
                for(String field : fields){
                    result.put(field, null);
                }
                return;// result; 
            }
            for(String field : fields){
                SObject tmpObj = oList[0];
                String[] dotSplit = field.split('\\.');
                for(integer i = 0; i < dotSplit.size(); i++){
                    if(i == dotSplit.size()-1){
                        if(tmpObj == null){
                            result.put(field, null);
                            break;
                        }
                        Object v = tmpObj.get(dotSplit[i]);
                        result.put(field, v);
                        break;
                    }
                    if(tmpObj == null){
                        result.put(field, null);
                        break;
                    }
                    tmpObj = tmpObj.getSObject(dotSplit[i]);
                }
            }
        }catch(QueryException ex){
            throw new ExpressionParsingException('Invalid expression: '+ex.getMessage()+' ['+query+']');
        }catch(Exception e){
            throw new ExpressionParsingException('Unexpected error: '+e.getMessage()+' ['+query+']');
        }
    }
    
    /*
* Replaces all custom settings values
*/ 
    public static void replaceCustomSettings(RegExps.ParserContext context){
        String CONCATENATION_TOKEN = '#@_/_@##';
        ID userId = Userinfo.getUserID();
        ID profileId = UserInfo.getProfileId();
        ID orgId = UserInfo.getOrganizationId();
        Pattern myPattern = pattern.compile(RegExps.EXP_CUSTOM_SETTING_TOKEN);
        Matcher m = myPattern.matcher(context.outputString); 
        //this is the map CS_OBJECT_TYPE+@_/_@+NAME => SET OF FIELDS
        Map<String,Set<String>> customSettings = new Map<String,Set<String>>();
        //this is the map CS_OBJECT_TYPE+@_/_@+NAME+@_/_@+FIELD => regex group (for replacements)
        Map<String,Set<String>> customSettingsTokens = new Map<String,Set<String>>();
        //this is the map of CS_OBJECT_TYPE+@_/_@+NAME+@_/_@+FIELD => SOAP TYPE
        Map<String,String> customSettingsFieldsTypes = new Map<String,String>();
        while(m.find()){
            String customSettingType = m.group(2);
            String customSettingName = m.group(4);
            String customSettingField = m.group(5);
            SObjectType csType = Schema.getGlobalDescribe().get(customSettingType);
            if(csType == null){
                throw new ExpressionParsingException('Invalid custom setting '+customSettingType);
            }
            Schema.DescribeSObjectResult csDescr = csType.getDescribe();
            if(!csDescr.isCustomSetting()){
                throw new ExpressionParsingException(customSettingType+' is not a valid custom setting');
            }
            Schema.SObjectField csField = csDescr.fields.getMap().get(customSettingField);
            
            if(csField == null){
                throw new ExpressionParsingException('Invalid field '+customSettingField+' for custom setting '+customSettingType);
            }
            Schema.DescribeFieldResult csFieldDescr = csField.getDescribe();
            String fieldType = String.valueOf(csFieldDescr.getSOAPType());
            context.fieldTypes.put(m.group(0), fieldType);
            
            String tmpType = customSettingType+((customSettingName==null)?'':CONCATENATION_TOKEN+customSettingName);
            Set<String> fields = customSettings.get(tmpType);
            Set<String> tokens = customSettingsTokens.get(tmpType+CONCATENATION_TOKEN+customSettingField);
            if(fields == null){
                fields = new Set<String>();
                customSettings.put(tmpType, fields);
            }
            if(tokens == null){
                tokens = new Set<String>();
                customSettingsTokens.put(tmpType+CONCATENATION_TOKEN+customSettingField, tokens);
            }
            fields.add(customSettingField);
            tokens.add(m.group(0));
            customSettingsFieldsTypes.put(tmpType+CONCATENATION_TOKEN+customSettingField, fieldType);
        }
        
        //query all custom settings found
        Map<String, List<SObject>> customSettingsRecords = new Map<String,List<SObject>>();
        for(String key : customSettings.keySet()){
            String[] tSplit = key.split(CONCATENATION_TOKEN);
            String type = tSplit[0];
            String name = (tSplit.size()>1)?tSplit[1]:null;
            //actual "name" value (could be void)
            String customSettingNameValue = context.referencesString.get(name);
            name = (!String.isBlank(customSettingNameValue))?customSettingNameValue:null;
            Set<String> fields = customSettings.get(key).clone();
            fields.add('Name');
            fields.add('Id');
            fields.add('SetupOwnerId');
            String query = 'Select '+String.join(new List<String>(fields),',')+' From ' +type+' Where ';
            if(!String.isBlank(name)){
                query += ' Name = \''+String.escapeSingleQuotes(name)+'\' and';
            }
            query += ' SetupOwnerId IN (:userId,:profileId,:orgId)';
            customSettingsRecords.put(key, Database.query(query));
        }
        
        for(String key : customSettings.keyset()){
            String[] tSplit = key.split(CONCATENATION_TOKEN);
            String customSettingType = tSplit[0];
            String customSettingName = (tSplit.size()>1)?tSplit[1]:null;
            String customSettingNameValue = context.referencesString.get(customSettingName);
            List<SObject> csList = customSettingsRecords.get(key);
            
            //gets if it is a list or hierachy CS
            Boolean isHierarchic = false;
            //the SetupOwnerId for the Hierarchy CS has the Name == its ID (15 chars)
            for(SObject cs : csList){
                if((ID)cs.get('SetupOwnerId') == orgId && (String)cs.get('Name') == ((String)cs.get('Id')).substring(0,15)){
                    isHierarchic = true;
                }
            }
            
            //iterate through the fields of the current custom setting
            for(String field : customSettings.get(key)){
                String customSettingField = field;
                String fieldType = customSettingsFieldsTypes.get(key+CONCATENATION_TOKEN+customSettingField);
                Object vObj = null;
                try{
                    if(csList.size()!=0){
                        
                        if(isHierarchic || !String.isBlank(customSettingNameValue)){
                            for(SObject cs : csList){
                                if((ID)cs.get('SetupOwnerId') == userId){
                                    vObj = cs.get(customSettingField);
                                    break;
                                }
                                if((ID)cs.get('SetupOwnerId') == profileId){
                                    vObj = cs.get(customSettingField);
                                }
                                if((ID)cs.get('SetupOwnerId') == orgId && vObj == null){
                                    vObj = cs.get(customSettingField);
                                }
                            }
                        }
                    }
                    
                }catch(Exception e){
                    vObj = null;
                    throw new ExpressionParsingException(e.getMessage());
                }
                
                Set<String> tokenGroups = customSettingsTokens.get(key+CONCATENATION_TOKEN+field);
                for(String k : tokenGroups){
                    if(fieldType == 'BOOLEAN'){
                        if(vObj == null) vObj = false;
                        context.outputString = context.outputString.replace(' '+k+' ',' _B'+context.referencesBoolean.size()+'B_ ');
                        context.fieldsPlaceholders.put('_B'+context.referencesBoolean.size()+'B_', k);
                        context.referencesBoolean.put('_B'+context.referencesBoolean.size()+'B_', (Boolean)vObj);
                    }else if(fieldType == 'INTEGER' || fieldType == 'DOUBLE'){
                        if(vObj == null) vObj = 0;
                        context.outputString = context.outputString.replace(' '+k+' ',' _D'+context.referencesDecimal.size()+'D_ ');
                        context.fieldsPlaceholders.put('_D'+context.referencesDecimal.size()+'D_', k);
                        context.referencesDecimal.put('_D'+context.referencesDecimal.size()+'D_', (Decimal)vObj);
                    }else if(fieldType == 'STRING' || fieldType == 'ID'){
                        if(vObj == null) vObj = '';
                        context.outputString = context.outputString.replace(' '+k+' ',' _S'+context.referencesString.size()+'S_ ');
                        context.fieldsPlaceholders.put('_S'+context.referencesString.size()+'S_', k);
                        context.referencesString.put('_S'+context.referencesString.size()+'S_', (String)vObj);
                    }else if(fieldType == 'DATE' || fieldType == 'DATETIME'){
                        context.outputString = context.outputString.replace(' '+k+' ',' _T'+context.referencesDateTime.size()+'T_ ');
                        context.fieldsPlaceholders.put('_T'+context.referencesDateTime.size()+'T_', k);
                        context.referencesDateTime.put('_T'+context.referencesDateTime.size()+'T_', (DateTime)vObj);
                    }
                }
            }
        }
    }
    
    
    /*
* Replaces expressions with corresponding Boolean values (e.g. 'test'='notest' ==> false, 6>2 ==> true)
*/
    
    public static void replaceExpressionValues(RegExps.ParserContext context /*String input, Map<String,Object> values*/){
        
        context.outputString = ' '+context.outputString+' ';
        
        //removes all comments
        context.outputString = context.outputString.replaceAll(RegExps.EXP_MULTILINE_COMMENT,'');
        
        //## STEP1 ## : replace all strings / datetime with placeholders
        //replaces strings with references
        Pattern myPattern = pattern.compile(RegExps.EXP_STRING);
        Matcher m = myPattern.matcher(context.outputString); 
        Set<String> stringList = new Set<String>();
        while(m.find()){
            stringList.add(m.group(0));
        }
        for(String str : stringList){
            context.outputString = context.outputString.replace(str, ' _S'+context.referencesString.size()+'S_ ');
            context.referencesString.put('_S'+context.referencesString.size()+'S_', str.substring(1,str.length()-1));
        }
        
        //## STEP2 ## : replace all "(" ")" "," with space-normalized versions. replace compare operators with space-normalized versions placeholders
        //normalize all spaces
        context.outputString = context.outputString.replaceAll('\\s*\\(\\s*',' ( ');
        context.outputString = context.outputString.replaceAll('\\s*\\)\\s*',' ) ');
        context.outputString = context.outputString.replaceAll('\\s*,\\s*',' , ');
        context.outputString = context.outputString.replaceAll('\\s*\\*\\s*',' * ');
        context.outputString = context.outputString.replaceAll('\\s*/\\s*',' / ');
        context.outputString = context.outputString.replaceAll('\\s*!=\\s*',' <> ');
        context.outputString = context.outputString.replaceAll('\\s*!',' ! ');
        context.outputString = context.outputString.replaceAll('\\s*&&\\s*',' && ');
        context.outputString = context.outputString.replaceAll('\\s*\\|\\|\\s*',' || ');
        context.outputString = context.outputString.replaceAll('\\s*\\^\\^\\s*',' ^^ ');
        for(String op : RegExps.COMPARE_OPERATORS.keyset()){
            context.outputString = context.outputString.replaceAll('\\s*'+op+'\\s*',' '+RegExps.COMPARE_OPERATORS.get(op)+' ');
        }
        
        //replaces date/datetime values
        myPattern = pattern.compile(RegExps.EXP_DATETIME);
        m = myPattern.matcher(context.outputString); 
        List<String> vList = new List<String>();
        while(m.find()){
            vList.add(m.group(0));
        }
        for(String str : vList){
            DateTime vdt = null;
            
            if(!Pattern.matches(RegExps.EXP_DATETIME, str)){
                throw new ExpressionParsingException('Invalid date/time value "'+str+'". Expected: YYYY-MM-DDTHH:MM:SS');
            }
            List<String> datePart = str.split('T')[0].split('\\-');
            List<String> timePart= new List<String>{'0','0','0'};
                if(str.split('T').size()>1){
                    timePart= str.split('T')[1].split(':');
                }
            vdt = DateTime.newInstanceGmt(Integer.valueOf(datePart[0]), Integer.valueOf(datePart[1]), Integer.valueOf(datePart[2]), 
                                          Integer.valueOf(timePart[0]), Integer.valueOf(timePart[1]), Integer.valueOf(timePart[2]));
            
            /*
context.outputString = context.outputString.replace(' '+str+' ',' _T'+context.referencesDateTime.size()+'T_ ');
context.referencesDateTime.put('_T'+context.referencesDateTime.size()+'T_', vdt);*/
            context.replace(str, vdt);
        }
        
        // nromalize spaces for +,-
        context.outputString = context.outputString.replaceAll('\\s*\\+\\s*',' + ');
        context.outputString = context.outputString.replaceAll('\\s*\\-\\s*',' - ');
        
        
        
        
        //## replace all + and - with space-normalized versions.
        //normalize all spaces
        context.outputString = context.outputString.replaceAll('\\s*\\+\\s*',' + ');
        context.outputString = context.outputString.replaceAll('\\s*\\-\\s*',' - ');
        
        //## STEP4 ## : replace field values with space-normalized versions placeholders
        
        //replaces field values with references
        context.outputString = context.outputString.toUpperCase();
        //sorts fields by lentght, so the replacement is done at first for the longer ones
        Map<Integer,List<String>> fieldNamesByLength = new Map<Integer,List<String>>();
        for(String k : context.fieldValues.keyset()){
            List<String> fls = fieldNamesByLength.get(k.length());
            if(fls == null){
                fls = new List<String>();
                fieldNamesByLength.put(k.length(), fls);
            }
            fls.add(k);
        }
        List<List<String>> sortedKeys = fieldNamesByLength.values();
        
        for(Integer i = sortedKeys.size()-1; i >=0; i--){
            List<String> fls = sortedKeys[i];
            for(String k : fls){
                Object vObj = context.fieldValues.get(k);
                
                //gets the field type
                String fieldType = context.fieldTypes.get(k);
                if(fieldType == 'BOOLEAN'){
                    if(vObj == null) vObj = false;
                    /*
context.outputString = context.outputString.replace(' '+k+' ',' _B'+context.referencesBoolean.size()+'B_ ');
context.fieldsPlaceholders.put('_B'+context.referencesBoolean.size()+'B_', k);
context.referencesBoolean.put('_B'+context.referencesBoolean.size()+'B_', (Boolean)vObj);*/
                    context.replace(k, (Boolean)vObj);
                }else if(fieldType == 'INTEGER' || fieldType == 'DOUBLE'){
                    if(vObj == null) vObj = 0;
                    /*
context.outputString = context.outputString.replace(' '+k+' ',' _D'+context.referencesDecimal.size()+'D_ ');
context.fieldsPlaceholders.put('_D'+context.referencesDecimal.size()+'D_', k);
context.referencesDecimal.put('_D'+context.referencesDecimal.size()+'D_', (Decimal)vObj);*/
                    context.replace(k, (Decimal)vObj);
                }else if(fieldType == 'STRING' || fieldType == 'ID'){
                    if(vObj == null) vObj = '';
                    /*
context.outputString = context.outputString.replace(' '+k+' ',' _S'+context.referencesString.size()+'S_ ');
context.fieldsPlaceholders.put('_S'+context.referencesString.size()+'S_', k);
context.referencesString.put('_S'+context.referencesString.size()+'S_', (String)vObj);*/
                    context.replace(k, (String)vObj);
                }else if(fieldType == 'DATE' || fieldType == 'DATETIME'){
                    /*
context.outputString = context.outputString.replace(' '+k+' ',' _T'+context.referencesDateTime.size()+'T_ ');
context.fieldsPlaceholders.put('_T'+context.referencesDateTime.size()+'T_', k);
context.referencesDateTime.put('_T'+context.referencesDateTime.size()+'T_', (DateTime)vObj);*/
                    context.replace(k, (DateTime)vObj);
                }
            }
        }
        
        //## STEP3 ## : replace static values with space-normalized versions placeholders
        
        //replaces values with references
        String EXP_VALUES_NO_STRING = '('+RegExps.EXP_NULL+'|'+RegExps.EXP_NUMBER+'|'+RegExps.EXP_BOOLEAN+')';
        myPattern = pattern.compile(EXP_VALUES_NO_STRING/*RegExps.EXP_VALUE*/);
        m = myPattern.matcher(context.outputString); 
        vList = new List<String>();
        while(m.find()){
            vList.add(m.group(0));
        }
        for(String str : vList){
            if(Pattern.matches(RegExps.EXP_NULL, str)){
                /*
context.outputString = context.outputString.replace(' '+str+' ',' _N'+context.referencesNULL.size()+'N_ ');
context.referencesNULL.add('_N'+context.referencesNULL.size()+'N_');*/
                context.replace(str);
            }else if(Pattern.matches(RegExps.EXP_NUMBER, str)){
                /*
context.outputString = context.outputString.replace(' '+str+' ',' _D'+context.referencesDecimal.size()+'D_ ');
context.referencesDecimal.put('_D'+context.referencesDecimal.size()+'D_', Decimal.valueOf(str));*/
                context.replace(str, Decimal.valueOf(str));
            }else if(Pattern.matches(RegExps.EXP_BOOLEAN, str)){
                /*
context.outputString = context.outputString.replace(' '+str+' ',' _B'+context.referencesBoolean.size()+'B_ ');
context.referencesBoolean.put('_B'+context.referencesBoolean.size()+'B_', Boolean.valueOf(str));*/
                context.replace(str, Boolean.valueOf(str));
            }
            
        }        
        
        //constants values
        myPattern = pattern.compile('(\\$PI|\\$E|\\$TODAY|\\$NOW|\\$RANDOM)');
        m = myPattern.matcher(context.outputString); 
        while(m.find()){
            if(m.group(0) == '$PI'){
                Decimal pi = Math.PI;
                /*
context.outputString = context.outputString.replace(' '+m.group(0)+' ',' _D'+context.referencesDecimal.size()+'D_ ');
context.fieldsPlaceholders.put('_D'+context.referencesDecimal.size()+'D_', m.group(0));
context.referencesDecimal.put('_D'+context.referencesDecimal.size()+'D_', pi);*/
                context.replace(m.group(0), pi);
            }else if(m.group(0) == '$E'){
                Decimal e = Math.E;
                /*
context.outputString = context.outputString.replace(' '+m.group(0)+' ',' _D'+context.referencesDecimal.size()+'D_ ');
context.fieldsPlaceholders.put('_D'+context.referencesDecimal.size()+'D_', m.group(0));
context.referencesDecimal.put('_D'+context.referencesDecimal.size()+'D_', e);*/
                context.replace(m.group(0), e);
            }else if(m.group(0) == '$RANDOM'){
                Decimal rnd = Math.random();
                rnd *= rnd;
                /*
context.outputString = context.outputString.replace(' '+m.group(0)+' ',' _D'+context.referencesDecimal.size()+'D_ ');
context.fieldsPlaceholders.put('_D'+context.referencesDecimal.size()+'D_', m.group(0));
context.referencesDecimal.put('_D'+context.referencesDecimal.size()+'D_', rnd);*/
                context.replace(m.group(0), rnd);
            }else if(m.group(0) == '$TODAY'){
                DateTime today = System.today();
                /*
context.outputString = context.outputString.replace(' '+m.group(0)+' ',' _T'+context.referencesDateTime.size()+'T_ ');
context.fieldsPlaceholders.put('_T'+context.referencesDateTime.size()+'T_', m.group(0));
context.referencesDateTime.put('_T'+context.referencesDateTime.size()+'T_', today);*/
                context.replace(m.group(0), today);
            }else if(m.group(0) == '$NOW'){
                DateTime now = System.now();
                /*
context.outputString = context.outputString.replace(' '+m.group(0)+' ',' _T'+context.referencesDateTime.size()+'T_ ');
context.fieldsPlaceholders.put('_T'+context.referencesDateTime.size()+'T_', m.group(0));
context.referencesDateTime.put('_T'+context.referencesDateTime.size()+'T_', now);*/
                context.replace(m.group(0), now);
            }
        }        
        
        
        
        //## STEP5 ## : normalize spaces 
        context.outputString = context.outputString.replaceAll('\\s+',' ');
    }
    
    public class ExpressionParsingException extends Exception{}
    
}