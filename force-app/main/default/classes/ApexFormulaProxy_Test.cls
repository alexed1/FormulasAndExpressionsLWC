/*
 * Author: Enrico Murru (http://enree.co)
 */
@isTest
private class ApexFormulaProxy_Test {
    @testsetup static void testSetup(){
        Account acc = new Account(Name = 'TestAccount', NumberOfEmployees = 12);
        insert acc;
        Contact cnt = new Contact(LastName = 'TestContact', AccountId = acc.Id);
        insert cnt;
        
        SObject cs = Schema.getGlobalDescribe().get('ListCS__c').newSObject();
        cs.put('Name','default');
        cs.put('Value__c', 'ListValue');
        insert cs;
        SObject csh = Schema.getGlobalDescribe().get('HierarchyCS__c').newSObject();
        csh.put('Value__c','HierarchicValue');
        insert csh;
        
    }
    
    private static void testResult(RegExps.ParserContext formulaResult, Decimal expectedValue){
        System.assert(formulaResult.isError == false, 'Error occurred: '+formulaResult.stackTrace);
        System.assert(formulaResult.result instanceof decimal, 'Expected type decimal, found: '+formulaResult.result);
        System.assert(((decimal)formulaResult.result == expectedValue), 'Expected '+expectedValue+', found '+formulaResult.result);
    }
    
    private static void testResult(RegExps.ParserContext formulaResult, String expectedValue){
        System.assert(formulaResult.isError == false, 'Error occurred: '+formulaResult.stackTrace);
        System.assert(formulaResult.result instanceof String, 'Expected type String, found: '+formulaResult.result);
        System.assert(((string)formulaResult.result == expectedValue), 'Expected '+expectedValue+', found '+formulaResult.result);
    }
 	private static void testResult(RegExps.ParserContext formulaResult, Boolean expectedValue){
        System.assert(formulaResult.isError == false, 'Error occurred: '+formulaResult.stackTrace);
        System.assert(formulaResult.result instanceof Boolean, 'Expected type Boolean, found: '+formulaResult.result);
        System.assert(((Boolean)formulaResult.result == expectedValue), 'Expected '+expectedValue+', found '+formulaResult.result);
    }
    private static void testResult(RegExps.ParserContext formulaResult, DateTime expectedValue){
        System.assert(formulaResult.isError == false, 'Error occurred: '+formulaResult.stackTrace);
        System.assert(formulaResult.result instanceof DateTime, 'Expected type DateTime, found: '+formulaResult.result);
        System.assert(((DateTime)formulaResult.result == expectedValue), 'Expected '+expectedValue+', found '+formulaResult.result);
    }
    private static void testResult(RegExps.ParserContext formulaResult, Date expectedValue){
        System.assert(formulaResult.isError == false, 'Error occurred: '+formulaResult.stackTrace);
        System.assert(formulaResult.result instanceof Date, 'Expected type Date, found: '+formulaResult.result);
        System.assert(((Date)formulaResult.result == expectedValue), 'Expected '+expectedValue+', found '+formulaResult.result);
    }
    
    static testmethod void unit_test_objects_access(){
        Test.startTest();
        Contact cnt = [Select Id From Contact Limit 1];
        String objType = SObjectType.Contact.name;
        Integer scale = 0;
        String exp = '((Account.Name == "TestAccount") && (Name == "TestContact"))';
        Boolean boolVal = true;
        RegExps.ParserContext formulaResult = ApexFormulaProxy.evaluate(exp, cnt.Id,  objType,  'BOOLEAN', scale);
        testResult(formulaResult, boolVal);
        
        exp = '/*unnecessary comment */ $Setup.ListCS__c["default"].Value__c == "ListValue"';
        boolVal = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,cnt.Id,objType,'BOOLEAN',scale);
        testResult(formulaResult, boolVal);
        
        exp = '($Setup.HierarchyCS__c.Value__c )==( "HierarchicValue")  ';
        boolVal = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,cnt.Id,objType,'BOOLEAN',scale);
        testResult(formulaResult, boolVal);
   
        Test.stopTest();
    }
    
    static testmethod void unit_test_string_operations(){
        Test.startTest();
        Contact cnt = [Select Id,Name,Account.Name  From Contact Limit 1];
        String objType = SObjectType.Contact.name;
        Integer scale = 0;
        String exp = 'Account.Name+Name';
        String strVal = cnt.Account.Name+cnt.Name;
        RegExps.ParserContext formulaResult = ApexFormulaProxy.evaluate(exp, cnt.Id,  objType,  'STRING', scale);
        testResult(formulaResult, strVal);
        
        Test.stopTest();
    }
    
    static testmethod void unit_test_basevalues(){
        Test.startTest();
        Account obj = [Select Id, Name, NumberOfEmployees From Account Limit 1];
        String objType = SObjectType.Account.name;
        Integer scale = 10;
        String exp = '(1.2345)';
        Decimal decimalValue = 1.2345;
        RegExps.ParserContext formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                                              obj.Id, 
                                                                              objType, 
                                                                              'NUMBER', 
                                                                              scale);
        testResult(formulaResult, decimalValue);
            
        exp = '-1.2345';
        decimalValue = -1.2345;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'NUMBER', 
                                                        scale);
        testResult(formulaResult, decimalValue);
        
        exp = '"A STRING"';
        String stringValue = 'A STRING';
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'STRING', 
                                                        null);
        testResult(formulaResult, stringValue);
        
        exp = '2000-01-01';
		Date dateValue = Date.newInstance(2000, 1, 1);
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'DATE', 
                                                        null);
        testResult(formulaResult, dateValue);
        
        exp = '2000-01-01T01:02:03';
		DateTime dateTimeValue = DateTime.newInstanceGMT(2000, 1, 1, 1, 2, 3);
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'DATETIME', 
                                                        null);
        testResult(formulaResult, dateTimeValue);
        
        exp = 'null';
		stringValue = '';
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'STRING', 
                                                        null);
        testResult(formulaResult, stringValue);
        
        exp = 'null';
		decimalValue = 0;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'NUMBER', 
                                                        null);
        testResult(formulaResult, decimalValue);
        
        exp = 'false';
		Boolean booleanValue = false;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'BOOLEAN', 
                                                        null);
        testResult(formulaResult, booleanValue);
        Test.stopTest();
    }
    
    static testmethod void unit_test_constants(){
        Test.startTest();
        Account obj = [Select Id, Name, NumberOfEmployees From Account Limit 1];
        String objType = SObjectType.Account.name;
        Integer scale = 10;
        
        String exp = '$PI';
        Decimal decimalValue = Math.PI;
        decimalValue = decimalValue.setScale(scale);
        RegExps.ParserContext formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                                              obj.Id, 
                                                                              objType, 
                                                                              'NUMBER', 
                                                                              scale);
        testResult(formulaResult, decimalValue);
        
        
        exp = '$E';
        decimalValue = Math.E;
        decimalValue = decimalValue.setScale(scale);
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'NUMBER', 
                                                        scale);
        testResult(formulaResult, decimalValue);
        
        exp = '$TODAY';
        Date dateValue = System.today();
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'DATE', 
                                                        scale);
        testResult(formulaResult, dateValue);
        
        exp = '$NOW';
        DateTime dateTimeValue = System.now();
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'DATETIME', 
                                                        scale);
        System.assert(formulaResult.isError == false, 'Error occurred: '+formulaResult.stackTrace);
        System.assert(formulaResult.result instanceof DateTime, 'Expected type DateTime, found: '+formulaResult.result);
        //results may differ in milliseconds
        DateTime result = (DateTime)formulaResult.result;
        result = DateTime.newInstance(result.year(), result.month(), result.day(), result.hour(), result.minute(), result.second());
        dateTimeValue = DateTime.newInstance(dateTimeValue.year(), dateTimeValue.month(), dateTimeValue.day(), dateTimeValue.hour(), dateTimeValue.minute(), dateTimeValue.second());
        System.assert(((DateTime)result == dateTimeValue), 'Expected '+dateTimeValue+', found '+result);
		
        exp = '$RANDOM';
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        'NUMBER', 
                                                        scale);
        System.assert(formulaResult.isError == false, 'Error occurred: '+formulaResult.stackTrace);
        System.assert(formulaResult.result instanceof decimal, 'Expected type decimal, found: '+formulaResult.result);

        Test.stopTest();   
    }
    
    static testmethod void unit_test_comparison_operators(){
        Test.startTest();
        
        Account obj = [Select Id, Name, NumberOfEmployees From Account Limit 1];
        String objType = SObjectType.Account.name;
        Integer scale = 10;
        String returnType = 'BOOLEAN';
        
        String exp = '1 > 0';
        Boolean expectedBoolean = true;
        RegExps.ParserContext formulaResult = null;
        
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '1 < 0';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '1 >= 1';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '5 >= 1';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '1 <= 1';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '1 <= 2';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '1 == 2';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '2==2';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '2=2';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '2!=2';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '2 != 3';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp, 
                                                        obj.Id, 
                                                        objType, 
                                                        returnType,
                                                        scale);
		testResult(formulaResult, expectedBoolean);
    }
    
    static testmethod void unit_test_logical_operators(){
        Test.startTest();
        
        Account obj = [Select Id, Name, NumberOfEmployees From Account Limit 1];
        String objType = SObjectType.Account.name;
        Integer scale = 10;
        String returnType = 'BOOLEAN';
        
        String exp = 'true && false';
        Boolean expectedBoolean = false;
        RegExps.ParserContext formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'true && true';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'AND(true,true,true,true,false)';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'AND(true,true,true,true,true,true)';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'true || false';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'false || false';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'OR(false,false,false,false,false,true)';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'OR(false,false,false,false,false,false)';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '!true';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = '!false';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'NOT(false)';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'NOT(true)';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'true ^^ true';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'true ^^ false';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'XOR(true,true)';
        expectedBoolean = false;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        exp = 'XOR(false,true)';
        expectedBoolean = true;
        formulaResult = ApexFormulaProxy.evaluate(exp,obj.Id,objType,returnType,scale);
		testResult(formulaResult, expectedBoolean);
        
        
        Test.stopTest();
    }
    
    static testmethod void unit_test_arithmetic(){
        Test.startTest();
        
        Account obj = [Select Id, Name, NumberOfEmployees From Account Limit 1];
        String objType = SObjectType.Account.name;
        Integer scale = 10;
        
        RegExps.ParserContext formulaResult = ApexFormulaProxy.evaluate('NumberOfEmployees', obj.Id, objType, 'NUMBER', scale);
		testResult(formulaResult, obj.NumberOfEmployees);
        
        formulaResult = ApexFormulaProxy.evaluate('NumberOfEmployees+1', obj.Id, objType, 'NUMBER', scale);
        testResult(formulaResult, (obj.NumberOfEmployees+1));
        
        decimal expectedValue = ((decimal)((((9+1)*(2+8))+1))).setscale(scale);
        formulaResult = ApexFormulaProxy.evaluate('((9+1)*(2+8))+1', obj.Id, objType, 'NUMBER', scale);
        testResult(formulaResult, expectedValue);
        
        expectedValue = ((decimal)((1+1+2+2+3+3+4+5+6)-(1+1+2+2+3+3+4+5+6))).setscale(scale);//0
        formulaResult = ApexFormulaProxy.evaluate('(1+1+2+2+3+3+4+5+6)-(1+1+2+2+3+3+4+5+6)', obj.Id, objType, 'NUMBER', scale);
        testResult(formulaResult, expectedValue);
        
        expectedValue = (((9.0+1)*(2.0+8))+1.0/5.0*(3.0+2.0*5.0/1.0+2.0)+((3.0*2.0)+10000.0)+0.5).setscale(scale);//10109.5
        //system.assert(false,''+expectedValue);
        formulaResult = ApexFormulaProxy.evaluate('((9+1)*(2+8))+1/5*(3+2*5/1+2)+((3*2)+10000)+0.5', obj.Id, objType, 'NUMBER', scale);
        testResult(formulaResult, expectedValue);
        
        expectedValue = (((11.0/5.0)*6.0*12.0+2.3)*5.0-(2.0/(1.0-45.0)*((25.0+6.0)/(2.0+6.0)))+0.2).setscale(scale);//803.876136364
        //system.assert(false,''+expectedValue);
        formulaResult = ApexFormulaProxy.evaluate('((11.0/5.0)*6.0*12.0+2.3)*5.0-(2.0/(1.0-45.0)*((25.0+6.0)/(2.0+6.0)))+0.2', obj.Id, objType, 'NUMBER', scale);
        testResult(formulaResult, expectedValue);
        
        expectedValue = (-1.0+2.5/-2.3).setscale(scale);//-2.08695652174
        //system.assert(false,''+expectedValue);
        formulaResult = ApexFormulaProxy.evaluate('-1.0+2.5/-2.3', obj.Id, objType, 'NUMBER', scale);
        testResult(formulaResult, expectedValue);
        
        Test.stopTest();
    }

}