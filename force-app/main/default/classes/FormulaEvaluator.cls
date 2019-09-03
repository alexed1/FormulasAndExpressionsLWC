public  with sharing class FormulaEvaluator {
    public static String evaluateFormula (String formula, String resultType) {
        Pattern mPattern = pattern.compile('[0-9.]{3,}');
        Matcher mMatcher = mPattern.matcher(formula);
        Integer scale = 0;

        while(mMatcher.find()){
            List<String> items = mMatcher.group(0).split('[.]');
            if (items.size() > 1 && items[1].length() > scale) {
                scale = items[1].length();
            }
        }

        RegExps.ParserContext parserContext = ApexExpressionParserV2.evaluate(formula, resultType, scale);
        return String.valueOf(parserContext.result);
    }
}
