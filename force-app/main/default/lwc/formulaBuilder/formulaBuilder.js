import {LightningElement, track, api, wire} from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import describeSObjects from '@salesforce/apex/SearchUtils.describeSObjects';
import getFieldList from '@salesforce/apex/FormulaBuilderController.getFieldList';

export default class FormulaBuilder extends LightningElement {

    @track _fields;
    @track contextFields = [];
    @api functions;
    @api operators;
    @track formula = '';
    @api name;
    @api contextTypes = ['Organization', 'Profile'];

    @api
    get fields() {
        if (this._fields && this.contextFields) {
            return [...this._fields, ...this.contextFields];
        }
        return this._fields;
    }

    set fields(value) {
        this._fields = value.split(',');
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
    get objectName() {
        return this.name
    }

    @api
    get formulaValue() {
        return this.formula;
    }

    set formulaValue(value) {
        this.formula = value;
    }

    set objectName(name) {
        this.name = name;
        getFieldList({objectName: name})
            .then(result => {
                let fields = [];
                result.forEach(fieldName => {
                    let fieldValue = name + '.' + fieldName;
                    fields.push({label: fieldName, value: fieldValue});
                });
                this._fields = fields
            })
    }

    @wire(describeSObjects, {types: '$contextTypes'})
    _describeSObjects(result) {
        if (result.error) {
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

    @wire(getObjectInfo, {objectApiName: 'User'})
    _getUserInfo({error, data}) {
        if (error) {
            // this.errors.push(error.body[0].message);
        } else if (data) {
            let fields = Object.values(data.fields);
            fields.forEach(field => {
                this.contextFields.push({
                    label: 'Current User: ' + field.label,
                    value: '$User.' + field.apiName
                });
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
}