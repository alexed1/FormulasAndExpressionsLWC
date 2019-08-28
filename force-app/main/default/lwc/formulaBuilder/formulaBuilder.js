import { LightningElement, track } from 'lwc';
import parseFormula from '@salesforce/apex/FormulaBuilderController.parseFormula';

export default class FormulaBuilder extends LightningElement {

    connectedCallback() {
        let fields = [];
        let functions = [];
        let operators = [];

        this.contextVariables.forEach(variable => {
            if (variable.Fields.length > 0) {
                let objectName = variable.Name;
                variable.Fields.forEach(field => {
                    let fieldValue = '$' + objectName + '.' + field;
                    fields.push({ label: field, value: fieldValue });
                })
            } else {
                let fieldValue = '$' + variable.Name;
                fields.push({ label: variable.Name, value: fieldValue });
            }
        })

        this.fields = fields;

        this.supportedFunctions.forEach(func => {
            functions.push({ label: func, value: func });
        })

        this.functions = functions;
        
        this.supportedOperators.forEach(operator => {
            operators.push({ label: operator, value: operator });
        })

        this.operators = operators;
    }

    
    @track fields;
    @track functions;
    @track operators;

    @track formula = '';
    @track parsedFormula = '';

    @track supportedOperators = ['+', '-', '/', '*', '==', '!=', '>', '<', '>=', '<='];
    @track supportedFunctions = ['COS', 'SIN'];
    @track contextVariables = [
        {"Name" : "foo", "Value" : "555", "Fields" : []}, 
        {"Name" : "bar", "Value" : "34", "Fields" : []}, 
        {"Name" : "Opportunity", "Value" : "0062v00001Fd64cAAB", "Fields" : ["Id", "Name", "CreatedDate", "LastModifiedDate"]},
        {"Name" : "User", "Value" : "", "Fields" : ["Country", "IsActive"]},
        {"Name" : "Organization", "Value" : "", "Fields" : ["Name", "Country"]},
        {"Name" : "Profile", "Value" : "", "Fields" : ["CreatedDate", "Name"]},
        {"Name" : "Setup", "Value" : "", "Fields" : ["PackageSettings__c.Expiration__c", "HierarchyCS__c.Value__c", "HierarchyCS__c.ValueNumber__c"]}
    ];

    selectOperator(event) {
        if (event.detail.value !== '') {
            this.formula = this.formula + ' ' + event.detail.value + ' ';
            event.target.value = '';
        }
    }

    changeFormula(event) {
        this.formula = event.target.value;
    }

    selectField(event) {
        if (event.detail.value !== '') {
            this.formula = this.formula + event.detail.value + ' ';
            event.target.value = '';
        }
    }

    parsedQuery() {
        parseFormula({ formula: this.formula, context: JSON.stringify(this.contextVariables) })
            .then(result => {
                this.parsedFormula = result;
            })
    }
}