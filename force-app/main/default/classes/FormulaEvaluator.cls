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

        RegExps.ParserContext parserContext = evaluate(formula, resultType, scale);
        return String.valueOf(parserContext.result);
    }

    public static RegExps.ParserContext evaluate(String formula, String outputType, Integer scale){

        RegExps.ParserContext context = new RegExps.ParserContext(formula, outputType, scale);

        try{

            String outputFormula = null;
            Boolean parenthesisAdded = false;
            Integer iteration = 0;
            
            replaceExpressionValues(context);

            while (true) {
                if (outputFormula == context.outputString) {
                    if (parenthesisAdded) {
                        break; 
                    } else {
                        parenthesisAdded = true;
                        RegExps.wrapParentesis(context, 'NUMBER');
                    }
                }
                
                outputFormula = context.outputString;
                
                RegExps.evaluateMathExpressions(context);
                if (outputFormula != context.outputString) {
                    RegExps.clearParentesis(context, 'NUMBER');
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateMathFunctions(context);
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateStringOperations(context);
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateStringFunctions(context);
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateCompareExpressions(context);   
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateBooleanExpressions(context);
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                
                RegExps.evaluateFlowExpressions(context);
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateFlowExpressionsCASE(context);
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateTypeConversionFunctions(context);
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.evaluateDateTimeFunctions(context);
                if (outputFormula != context.outputString) {
                    parenthesisAdded = false;
                    continue;
                }
                
                RegExps.clearParentesis(context,'ALL');
            }

            context.result = RegExps.evaluateResult(context);

        } catch (Exception e) {
            context.isError = true;
            context.stackTrace = e.getStackTraceString() + ' ' + e.getMEssage();
            context.errorMessage = e.getMessage();
        }
        return context;
    }

    public static void replaceExpressionValues(RegExps.ParserContext context){
        
        context.outputString = ' ' + context.outputString + ' ';
        context.outputString = context.outputString.replaceAll(RegExps.EXP_MULTILINE_COMMENT, '');
        
        Pattern myPattern = pattern.compile(RegExps.EXP_STRING);
        Matcher m = myPattern.matcher(context.outputString); 
        Set<String> stringList = new Set<String>();

        while (m.find()) {
            stringList.add(m.group(0));
        }

        for (String str : stringList) {
            context.outputString = context.outputString.replace(str, ' _S'+context.referencesString.size() + 'S_ ');
            context.referencesString.put('_S' + context.referencesString.size() + 'S_', str.substring(1,str.length() - 1));
        }

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

        for (String op : RegExps.COMPARE_OPERATORS.keyset()) {
            context.outputString = context.outputString.replaceAll('\\s*' + op + '\\s*', ' ' + RegExps.COMPARE_OPERATORS.get(op) + ' ');
        }

        List<String> vList = new List<String>();
        myPattern = pattern.compile(RegExps.EXP_DATETIME);
        m = myPattern.matcher(context.outputString); 
        
        while (m.find()) {
            vList.add(m.group(0));
        }

        for (String str : vList) {

            DateTime vdt = null;
            
            if (!Pattern.matches(RegExps.EXP_DATETIME, str)) {
                throw new ExpressionParsingException('Invalid date/time value "' + str + '". Expected: YYYY-MM-DDTHH:MM:SS');
            }

            List<String> datePart = str.split('T')[0].split('\\-');
            List<String> timePart= new List<String>{'0','0','0'};

            if (str.split('T').size()>1) {
                timePart = str.split('T')[1].split(':');
            }

            vdt = DateTime.newInstanceGmt(Integer.valueOf(datePart[0]), Integer.valueOf(datePart[1]), Integer.valueOf(datePart[2]), 
                                          Integer.valueOf(timePart[0]), Integer.valueOf(timePart[1]), Integer.valueOf(timePart[2]));
            
            context.replace(str, vdt);
        }
        
        context.outputString = context.outputString.replaceAll('\\s*\\+\\s*', ' + ');
        context.outputString = context.outputString.replaceAll('\\s*\\-\\s*', ' - ');
        context.outputString = context.outputString.replaceAll('\\s*\\+\\s*', ' + ');
        context.outputString = context.outputString.replaceAll('\\s*\\-\\s*', ' - ');
        context.outputString = context.outputString.toUpperCase();

        Map<Integer,List<String>> fieldNamesByLength = new Map<Integer,List<String>>();

        for (String k : context.fieldValues.keyset()) {
            List<String> fls = fieldNamesByLength.get(k.length());

            if (fls == null) {
                fls = new List<String>();
                fieldNamesByLength.put(k.length(), fls);
            }

            fls.add(k);
        }

        List<List<String>> sortedKeys = fieldNamesByLength.values();
        
        for (Integer i = sortedKeys.size()-1; i >=0; i--) {
            List<String> fls = sortedKeys[i];

            for (String k : fls) {

                Object vObj = context.fieldValues.get(k);
                String fieldType = context.fieldTypes.get(k);

                if (fieldType == 'BOOLEAN') {
                    if(vObj == null) {
                        vObj = false;
                    } 
                    context.replace(k, (Boolean)vObj);
                } else if (fieldType == 'INTEGER' || fieldType == 'DOUBLE') {
                    if(vObj == null) {
                        vObj = 0;
                    }
                    context.replace(k, (Decimal)vObj);
                } else if (fieldType == 'STRING' || fieldType == 'ID') {
                    if(vObj == null) {
                        vObj = '';
                    }
                    context.replace(k, (String)vObj);
                } else if (fieldType == 'DATE' || fieldType == 'DATETIME') {
                    context.replace(k, (DateTime)vObj);
                }
            }
        }

        String EXP_VALUES_NO_STRING = '(' + RegExps.EXP_NULL + '|' + RegExps.EXP_NUMBER + '|' + RegExps.EXP_BOOLEAN + ')';

        vList = new List<String>();
        myPattern = pattern.compile(EXP_VALUES_NO_STRING);
        m = myPattern.matcher(context.outputString); 
        
        while (m.find()) {
            vList.add(m.group(0));
        }

        for (String str : vList) {
            if (Pattern.matches(RegExps.EXP_NULL, str)) {
                context.replace(str);
            } else if (Pattern.matches(RegExps.EXP_NUMBER, str)) {
                context.replace(str, Decimal.valueOf(str));
            } else if (Pattern.matches(RegExps.EXP_BOOLEAN, str)) {
                context.replace(str, Boolean.valueOf(str));
            }   
        }        

        myPattern = pattern.compile('(\\$PI|\\$E|\\$TODAY|\\$NOW|\\$RANDOM)');
        m = myPattern.matcher(context.outputString); 

        while (m.find()) {
            if (m.group(0) == '$PI') {
                Decimal pi = Math.PI;
                context.replace(m.group(0), pi);
            } else if (m.group(0) == '$E') {
                Decimal e = Math.E;
                context.replace(m.group(0), e);
            } else if (m.group(0) == '$RANDOM') {
                Decimal rnd = Math.random();
                rnd *= rnd;
                context.replace(m.group(0), rnd);
            } else if (m.group(0) == '$TODAY') {
                DateTime today = System.today();
                context.replace(m.group(0), today);
            } else if (m.group(0) == '$NOW') {
                DateTime now = System.now();
                context.replace(m.group(0), now);
            }
        }        

        context.outputString = context.outputString.replaceAll('\\s+',' ');
    }

    public class ExpressionParsingException extends Exception{}
}
