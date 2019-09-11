import {LightningElement, track, api} from 'lwc';
import useFormulaSyntaxPartOne from '@salesforce/label/c.UseFormulaSyntaxPartOne';
import useFormulaSyntaxPartTwo from '@salesforce/label/c.UseFormulaSyntaxPartTwo';
import useFormulaSyntaxPartThree from '@salesforce/label/c.UseFormulaSyntaxPartThree';
import useFormulaSyntaxPartFour from '@salesforce/label/c.UseFormulaSyntaxPartFour';
import getFieldList from '@salesforce/apex/FormulaBuilderController.getFieldList';

export default class FormulaBuilder extends LightningElement {

    @track fields;
    @track operators;
    @track formula = '';
    @track name;
    @track functions = [
        { label: 'AND', value: 'AND(logical1,logical2,...)' },
        { label: 'OR', value: 'OR(logical1,logical2,...)' },
        { label: 'NOT', value: 'NOT(logical)' },
        { label: 'IF', value: 'IF(logical_test, value_if_true, value_if_false)' },
        { label: 'CASE', value: 'CASE(expression, value1, result1, value2, result2,...,else_result)' },
        { label: 'LEN', value: 'LEN(text)' },
        { label: 'LEFT', value: 'LEFT(text, num_chars)' },
        { label: 'RIGHT', value: 'RIGHT(text, num_chars)' },
        { label: 'ISBLANK', value: 'ISBLANK(expression)' },
        { label: 'ISPICKVAL', value: 'ISPICKVAL(picklist_field, text_literal)' },
        { label: 'ABS', value: 'ABS(number)' },
        { label: 'ROUND', value: 'ROUND(number,num_digits)' },
        { label: 'CEIL', value: 'CEIL(number)' },
        { label: 'FLOOR', value: 'FLOOR(number)' },
        { label: 'SQRT', value: 'SQRT(number)' },
        { label: 'EXP', value: 'EXP(number)' },
        { label: 'LOG', value: 'LOG(number)' },
        { label: 'MAX', value: 'MAX(number,number,...)' },
        { label: 'MIN', value: 'MIN(number,number,...)' },
        { label: 'MOD', value: 'MOD(number,divisor)' },
        { label: 'TEXT', value: 'TEXT(value)' },
        { label: 'DATETIME', value: 'DATETIME(year,month,day,hours,minutes,seconds)' },
        { label: 'DATE', value: 'DATE(year-month-day)' },
        { label: 'DAY', value: 'DAY(date)' },
        { label: 'MONTH', value: 'MONTH(date)' },
        { label: 'YEAR', value: 'YEAR(date)' },
        { label: 'HOURS', value: 'HOURS(expression)' },
        { label: 'MINUTES', value: 'MINUTES(expression)' },
        { label: 'SECONDS', value: 'SECONDS(expression)' },
        { label: 'ADDDAYS', value: 'ADDDAYS(date,num)' },
        { label: 'ADDMONTHS', value: 'ADDMONTHS(date,num)' },
        { label: 'ADDYEARS', value: 'ADDYEARS(date,num)' },
        { label: 'ADDHOURS', value: 'ADDHOURS(date,num)' },
        { label: 'ADDMINUTES', value: 'ADDMINUTES(date,num)' },
        { label: 'ADDSECONDS', value: 'ADDSECONDS(date,num)' }
    ];
    @track label = {
        useFormulaSyntaxPartOne,
        useFormulaSyntaxPartTwo,
        useFormulaSyntaxPartThree,
        useFormulaSyntaxPartFour
    };

    @api supportedOperators = ['+', '-', '/', '*', '==', '!=', '>', '<', '>=', '<=', '<>'];

    @api
    get objectName() {
        return this.name
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
                this.fields = fields
            })
    }

    formulaChanged() {
        const memberRefreshedEvt = new CustomEvent('formulachanged', {
            bubbles: true, detail: {
                value: this.formula
            }
        });
        this.dispatchEvent(memberRefreshedEvt);
    }

    connectedCallback() {

        let operators = [];

        this.supportedOperators.forEach(operator => {
            operators.push({label: operator, value: operator});
        });

        this.operators = operators;

    }

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
}