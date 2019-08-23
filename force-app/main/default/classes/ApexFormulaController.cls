public without sharing class ApexFormulaController {
    public String oldFormula{get;Set;}
    public String oldComment{get;Set;}
    public String userID{get;set;}
    public String siteSuggestions{get;set;}
    public List<ListCS__c> listCustomSettings {get;set;}
    public List<HierarchyCS__c> hierarchyCustomSettings {get;set;}
    public List<TestObject__c>testObjects{get;Set;}
	public String formula{get;set;}
    //public Contact cnt{get;set;}
    public String result{get;set;}
    public String fieldsMap{get;Set;}
    public String stateV2{get;set;}
    public String outputType{get;set;}
    public String objectType{get;Set;}
    public ID loadFormulaId{get;set;}
    public List<SelectOption> formulaList{get;set;}
    public Map<String,String> limitsValues = new Map<String,String>();
    public Integer scale{get;set;}
    public ID testObjectId{get;set;}
    public List<SelectOption> sobjectsList{get;set;}
    public String limitsJSON{
        get{
            return JSON.serializePretty(this.limitsValues);
        }
    }
    public ApexFormulaController(){
        this.userID = ('ExtUser_'+Math.random()).replace('.','');
        this.formula = null;
        this.result = null; 
        this.outputType = 'BOOLEAN';
        this.formulaList = new List<SelectOption>();
        this.formulaList.add(new SelectOption('','--'));
        for(Formula__c f : [Select Id, Name__c, SObjectType__c, ReturnType__c, Scale__c 
                            From Formula__c Where Origin__c != 'ExtUser' 
                            Order By SObjectType__c, Name__c]){
            this.formulaList.add(new SelectOption(f.Id, f.Name__c+' ['+f.SObjectType__c+' - '+f.ReturnType__c+']'));
        }
		this.objectType = String.valueOf(TestObject__c.SObjectType);
        this.testObjects = [Select Id, Name, CreatedDate From TestObject__c Order By CreatedDate limit 1000];
        this.listCustomSettings=[Select Name, Value__c, ValueNumber__c From ListCS__c Order By CreatedDate];
        this.hierarchyCustomSettings = [Select Name, Value__c, ValueNumber__c From HierarchyCS__c limit 1];
        //selects the first test object
        this.testObjectId = this.testObjects[0].Id;
        //load formula from "fid" parameter
        String fid = ApexPages.currentPage().getParameters().get('fid');
        if(String.isNotBlank(fid)){
            try{
            	this.loadFormulaId = ID.valueOf(fid);
                loadFormula();
            }catcH(Exception e){
                system.debug('## EXCEPTION:'+e.getMessage());
            }
        }
	}
    
    public void selectTestObject(){}
    
    public void loadFormula(){
        if(this.loadFormulaId == null){
            return;
        }
        
        Formula__c f = [Select Id, Name__c, Body__c, ReturnType__c,Scale__c,SobjectType__c From Formula__c Where Id = :this.loadFormulaId];
        this.outputType = f.ReturnType__c;
        this.formula = f.Body__c;
        this.scale = (Integer)f.Scale__c;
        this.objectType = f.SobjectType__c;
    }
      
    public void evaluateExpression(){
        this.result = null;
        RegExps.ParserContext formulaResult = ApexExpressionParserV2.evaluate(this.formula, this.testObjectId, this.objectType, this.outputType, this.scale);
        if(formulaResult.isError != true){
        	this.result = String.valueOf(formulaResult.result);
        }else{
            this.result = null;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, formulaResult.stackTrace));
        }
        
        formulaResult.formula = null;
        formulaResult.stackTrace = null;
        this.stateV2 = JSON.serializePretty(formulaResult);
        this.limitsValues = new Map<String,String>();
        this.limitsValues.put('DML Statements', Limits.getDMLStatements()+'/'+Limits.getLimitDMLStatements());
		this.limitsValues.put('DML Rows', Limits.getDMLRows()+'/'+Limits.getLimitDMLRows());
		this.limitsValues.put('Callouts', Limits.getCallouts()+'/'+Limits.getLimitCallouts());
		this.limitsValues.put('Future Calls', Limits.getFutureCalls()+'/'+Limits.getLimitFutureCalls());
		this.limitsValues.put('SOQL Queries', Limits.getQueries()+'/'+Limits.getLimitQueries());
		this.limitsValues.put('Query Rows',Limits.getQueryRows()+'/'+Limits.getLimitQueryRows());
        this.limitsValues.put('Aggregate Queries Rows',Limits.getAggregateQueries() +'/'+Limits.getLimitAggregateQueries());
        this.limitsValues.put('CPU Time',Limits.getCpuTime() +'/'+Limits.getLimitCpuTime());
        this.limitsValues.put('Heap Size',Limits.getHeapSize() +'/'+Limits.getLimitHeapSize());
        
        if(oldFormula != this.formula || this.oldComment != this.SiteSuggestions){
            Formula__c f = new Formula__c(Origin__c = 'ExtUser');
            f.ReturnType__c = this.outputType;
            f.Body__c = this.formula;
            f.Scale__c = this.scale;
            f.SobjectType__c = this.objectType;
            if(SiteSuggestions != null && SiteSuggestions.length() > 5000) SiteSuggestions = SiteSuggestions.left(5000);
            f.SiteSuggestions__c = this.SiteSuggestions;
            String debug = 'Record Id: '+this.testObjectId
                + '\n\n'
                + 'Limits: \n'+JSON.serializePretty(this.limitsValues)
                + '\n\n'
                + 'Result: '+JSON.serialize(this.result)
                + '\n\n'
                + 'Stack Trace: '+formulaResult.stackTrace
                + '\n\n'
                + 'State: \n'+ JSON.serializePretty(formulaResult);
            if(debug.length() > 100000) debug = debug.left(100000);
            f.Debug__c = debug;
            f.ElaborationError__c  =formulaResult.isError;
            if(this.userID == null) this.userID = ('ExtUser_'+Math.random()).replace('.','');
            f.Name__c = this.userID;
            insert f;
            this.oldFormula= formula;
            this.oldComment = this.SiteSuggestions;
        }
    }
}