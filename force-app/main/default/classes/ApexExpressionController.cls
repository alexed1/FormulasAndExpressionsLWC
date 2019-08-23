/*
 * Author: Enrico Murru (http://enree.co)
 */
public without sharing class ApexExpressionController {
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
    public IDCarrier idValue{get;set;}
    public List<SelectOption> sobjectsList{get;set;}
    public String limitsJSON{
        get{
            return JSON.serializePretty(this.limitsValues);
        }
    }
    public ApexExpressionController(){
        this.formula = null;//'IF( numberofemployees > 0, name = null, FALSE ) OR Name != null AND (NumberOfEmployees > 0 AND NOT(CreatedBy.Id == null)) OR (Parent.NumberOfEmployees > 0 AND Parent.Contact__r.Name == "TIM")';
        //this.cnt = [Select Id, AccountId From Contact Where AccountId != null Limit 1]; 
        this.result = null; 
        this.outputType = 'BOOLEAN';
        this.formulaList = new List<SelectOption>();
        this.formulaList.add(new SelectOption('','--'));
        for(Formula__c f : [Select Id, Name__c, SObjectType__c, ReturnType__c, Scale__c From Formula__c Order By SObjectType__c, Name__c]){
            this.formulaList.add(new SelectOption(f.Id, f.Name__c+' ['+f.SObjectType__c+' - '+f.ReturnType__c+']'));
        }
        this.objectType = 'TestObject__c';
        this.idValue = new IDCarrier([Select Id From TestObject__c Limit 1].Id);
        this.sobjectsList = new List<SelectOption>();
        for(SObjectType soType : Schema.getGlobalDescribe().values()){
			Schema.DescribeSObjectResult descr = soType.getDescribe();
            if(!descr.isAccessible() || descr.isDeprecatedAndHidden() || !descr.isQueryable()) continue;
            this.sobjectsList.add(new SelectOption(descr.getname(),descr.getname()));
        }
        this.sobjectsList.sort();
    }
    
    public void reloadSObjectType(){
        this.idValue = new IDCarrier();
    }
    
    public void loadFormula(){
        if(this.loadFormulaId == null){
            return;
        }
        
        Formula__c f = [Select Id, Name__c, Body__c, ReturnType__c,Scale__c,SobjectType__c From Formula__c Where Id = :this.loadFormulaId];
        this.outputType = f.ReturnType__c;
        this.formula = f.Body__c;
        this.scale = (Integer)f.Scale__c;
        this.objectType = f.SobjectType__c;
        this.idValue = new IDCarrier();
    }
      
    public void evaluateExpression(){
        this.result = null;
        RegExps.ParserContext formulaResult = ApexFormulaProxy.evaluate(this.formula, this.idValue.value, this.objectType, this.outputType, this.scale);
        if(!formulaResult.isError){
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
    }
}