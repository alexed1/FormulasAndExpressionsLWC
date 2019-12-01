import {LightningElement, track, api, wire} from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
import describeSObjects from '@salesforce/apex/SearchUtils.describeSObjects';


export default class FormulaBuilder extends LightningElement {

    @api functions;
    @api operators;
    @api supportedSystemTypes;

    @track formula = '';
    @track _objectName;
    @track contextFields = [];
    @track contextTypes;


    @api get contextObjectType() {
        return this._objectName;
        }

    set contextObjectType(value) {
        this._objectName = value;
        if (value) {
            this.contextTypes = [...[value], ...this.supportedSystemTypes ? this.splitValues(this.supportedSystemTypes) : []];
    }
    }

    @api supportedFunctions = [
        'AND', 'OR', 'NOT', 'XOR', 'IF', 'CASE', 'LEN', 'SUBSTRING', 'LEFT', 'RIGHT',
        'ISBLANK', 'ISPICKVAL', 'CONVERTID', 'ABS', 'ROUND', 'CEIL', 'FLOOR', 'SQRT', 'ACOS',
        'ASIN', 'ATAN', 'COS', 'SIN', 'TAN', 'COSH', 'SINH', 'TANH', 'EXP', 'LOG', 'LOG10', 'RINT',
        'SIGNUM', 'INTEGER', 'POW', 'MAX', 'MIN', 'MOD', 'TEXT', 'DATETIME', 'DECIMAL', 'BOOLEAN',
        'DATE', 'DAY', 'MONTH', 'YEAR', 'HOURS', 'MINUTES', 'SECONDS', 'ADDDAYS', 'ADDMONTHS',
        'ADDYEARS', 'ADDHOURS', 'ADDMINUTES', 'ADDSECONDS', 'CONTAINS', 'FIND', 'LOWER', 'UPPER'
        , 'MID', 'SUBSTITUTE', 'TRIM', 'VALUE', 'CONCATENATE'
    ];

    @api supportedOperators = ['+', '-', '/', '*', '==', '!=', '>', '<', '>=', '<=', '<>'];

    @api
    get formulaString() {
        return this.formula;
    }

    set formulaString(value) {
        this.formula = value;
    }

    @wire(describeSObjects, {types: '$contextTypes'})
    _describeSObjects(result) {
        if (result.error) {
            console.log(result.error.body.message);
            // this.errors.push(error.body[0].message);
        } else if (result.data) {
            this.contextTypes.forEach(objType => {

                let newContextFields = result.data[objType].map(curField => {
                    return {label: objType + ': ' + curField.label, value: '$'+objType + '.' + curField.value}
                });

                if (this.contextFields) {
                    this.contextFields = this.contextFields.concat(newContextFields);
                } else {
                    this.contextFields = newContextFields;
                }

            });
        }
    }

    formulaChangedEvent() {
        const memberRefreshedEvt = new CustomEvent('formulachanged', {
            bubbles: true, detail: {
                value: this.formula
            }
        });
        this.dispatchEvent(memberRefreshedEvt);
    }

    dispatchFormulaChangedEvents() {
        this.formulaChangedFlowEvent();
        this.formulaChangedEvent();
    }

    connectedCallback() {

        let functions = [];
        let operators = [];

        this.supportedFunctions.forEach(func => {
            let funcValue = func + '()';
            functions.push({label: func, value: funcValue});
        });

        this.functions = functions;

        this.supportedOperators.forEach(operator => {
            operators.push({label: operator, value: operator});
        });

        this.operators = operators;

    }

    formulaChangedFlowEvent() {
        const valueChangeEvent = new FlowAttributeChangeEvent('value', this.formula);
        this.dispatchEvent(valueChangeEvent);
    }

    selectOperator(event) {
        if (event.detail.value !== '') {
            this.formula = this.formula + ' ' + event.detail.value + ' ';
            this.dispatchFormulaChangedEvents();
        }
    }

    changeFormula(event) {
        this.formula = event.target.value;
        this.dispatchFormulaChangedEvents();
    }

    selectField(event) {
        if (event.detail.value !== '') {
            this.formula = this.formula + event.detail.value + ' ';
            this.dispatchFormulaChangedEvents();
        }
    }

    splitValues(originalString) {
        return originalString ? originalString.replace(/ /g, '').split(',') : [];
    }
}