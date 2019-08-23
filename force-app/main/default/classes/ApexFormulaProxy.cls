global without sharing class ApexFormulaProxy {
	
    global static RegExps.ParserContext evaluate(String formula, ID objectId, String objectType, String outputType, Integer scale){
        //return ApexExpressionParserV2.evaluate(formula, objectId, objectType, outputType, scale);
        //List<RegExps.ParserContext> responses = new List<RegExps.ParserContext>();
        //responses.add(ApexExpressionParserV2.evaluate(formula, objectId, objectType, outputType, scale));
        //return ApexExpressionParserV2.evaluate(req.formula, req.objectId, req.objectType, req.outputType, req.scale);
        RegExps.ParserRequest req = new RegExps.ParserRequest(formula, objectId, objectType, outputType, scale);
        List<RegExps.ParserContext> cntList = ApexExpressionParserV2.evaluateBulk(new List<RegExps.ParserRequest>{req});
        return cntList[0];
    }
    
    
    global static List<RegExps.ParserContext> evaluateBulk(List<RegExps.ParserRequest> requests){
        return ApexExpressionParserV2.evaluateBulk(requests);
    }
}