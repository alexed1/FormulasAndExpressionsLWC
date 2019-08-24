global with sharing class EvaluateFormula {
    
    @InvocableMethod
    global static List<Results> evaluateFormula(List<Requests> requests) {
        String formulaString = requests[0].formulaString;
        //String recordId = requests[0].recordId;
        
        String objectType = requests[0].objectType;
        String outputType = requests[0].outputType;
        Integer scale = requests[0].scale;
        
        //Note: the original formula evaluator expected a recordId, but we want to be unchained to a specific recordId, so passing in null
        RegExps.ParserContext parserContext = ApexExpressionParserV2.evaluate( formulaString, null ,  objectType,  outputType,  scale);
        System.debug('formula result is: ' + parserContext);

        Results curResult = new Results();
        curResult.formulaResult = String.valueOf(parserContext.result);
        List<Results> resultsList = new List<results>();
        resultsList.add(curResult);
        return resultsList;
    }

    global class Requests {
    
        @InvocableVariable
        global String formulaString;


        @InvocableVariable
        global String objectType;

        @InvocableVariable
        global String outputType;

        @InvocableVariable
        global Integer scale;
        
    }
    
    global class Results {

        @InvocableVariable
        global String formulaResult;

        

    }

}
