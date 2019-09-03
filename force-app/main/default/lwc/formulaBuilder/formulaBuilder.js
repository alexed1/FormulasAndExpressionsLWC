import { LightningElement, track, api } from 'lwc';
import parseFormula from '@salesforce/apex/FormulaBuilderController.parseFormula';

export default class FormulaBuilder extends LightningElement {

    @api contextVariables = [];
    @api supportedFunctions = [];
    @api supportedOperators = [];

    connectedCallback() {

        let fields = [];
        let functions = [];
        let operators = [];

        this.contextVariables.forEach(variable => {
            if (variable.Fields.length > 0) {
                let objectName = variable.Name;
                variable.Fields.forEach(field => {
                    let fieldValue = objectName + '.' + field;
                    fields.push({ label: field, value: fieldValue });
                })
            } else {
                let fieldValue = variable.Name;
                fields.push({ label: variable.Name, value: fieldValue });
            }
        })

        this.fields = fields;

        this.supportedFunctions.forEach(func => {
            let funcValue = func + '()';
            functions.push({ label: func, value: funcValue });
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
    @track showSpinner = false;
    @track showError = false;

    @track formula = '';
    @track parsedFormula = '';

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
        this.showSpinner = true;
        parseFormula({ formula: this.formula, context: JSON.stringify(this.contextVariables) })
            .then(result => {
                this.parsedFormula = result;
                this.showSpinner = false;
                this.showError = result === undefined ? true : false;
            })
    }
}