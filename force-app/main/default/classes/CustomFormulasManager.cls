/*
 * Author: Enrico Murru (http://enree.co)
 */
global class CustomFormulasManager {
    global String calculateStringFormula(String formulaBody, ID objectID){
        RegExps.ParserContext formulaResult = ApexExpressionParserV2.evaluate(formulaBody, objectID, 
			objectID.getSobjectType().getDescribe().getName(), 
			'STRING', 0);
        if(!formulaResult.isError){
        	return (String)formulaResult.result;
        }else{
            DebugLog.throwException(formulaResult.errorMessage);
            return null;
        }
    }
    
    global Boolean calculateBooleanFormula(String formulaBody, ID objectID){
        RegExps.ParserContext formulaResult = ApexExpressionParserV2.evaluate(formulaBody, objectID, 
			objectID.getSobjectType().getDescribe().getName(), 
			'BOOLEAN', 0);
        if(!formulaResult.isError){
        	return (Boolean)formulaResult.result;
        }else{
            DebugLog.throwException(formulaResult.errorMessage);
            return null;
        }
    }
    
    global Date calculateDateFormula(String formulaBody, ID objectID){
        RegExps.ParserContext formulaResult = ApexExpressionParserV2.evaluate(formulaBody, objectID, 
			objectID.getSobjectType().getDescribe().getName(), 
			'DATE', 0);
        if(!formulaResult.isError){
        	return (Date)formulaResult.result;
        }else{
            DebugLog.throwException(formulaResult.errorMessage);
            return null;
        }
    }
    global DateTime calculateDateTimeFormula(String formulaBody, ID objectID){
        RegExps.ParserContext formulaResult = ApexExpressionParserV2.evaluate(formulaBody, objectID, 
			objectID.getSobjectType().getDescribe().getName(), 
			'DATETIME', 0);
        if(!formulaResult.isError){
        	return (DateTime)formulaResult.result;
        }else{
            DebugLog.throwException(formulaResult.errorMessage);
            return null;            
        }
    }
    global Decimal calculateNumberFormula(String formulaBody, ID objectID, Integer scale){
        RegExps.ParserContext formulaResult = ApexExpressionParserV2.evaluate(formulaBody, objectID, 
			objectID.getSobjectType().getDescribe().getName(), 
			'NUMBER', scale);
        if(!formulaResult.isError){
        	return (Decimal)formulaResult.result;
        }else{
            DebugLog.throwException(formulaResult.errorMessage);
            return null;
        }
    }
    
    global Decimal calculateIntegerFormula(String formulaBody, ID objectID){
        RegExps.ParserContext formulaResult = ApexExpressionParserV2.evaluate(formulaBody, objectID, 
			objectID.getSobjectType().getDescribe().getName(), 
			'NUMBER', 0);
        if(!formulaResult.isError){
        	return Integer.valueOF(formulaResult.result);
        }else{
            DebugLog.throwException(formulaResult.errorMessage);
            return null;
        }
    }
}