import { LightningElement, track, wire } from 'lwc';
import getFieldList from '@salesforce/apex/FormulaBuilderController.getFieldList';
import parseFormula from '@salesforce/apex/FormulaBuilderController.parseFormula';

export default class FormulaBuilder extends LightningElement {
    @track formula = '';
    @track parsedFormeula = '';

    @track supportedOperators = [
        { label: '+', value: '+' },
        { label: '-', value: '-' },
        { label: '/', value: '/' },
        { label: '*', value: '*' },
        { label: '==', value: '==' },
        { label: '>=', value: '>=' },
        { label: '<=', value: '<=' },
        { label: '<', value: '<' },
        { label: '>', value: '>' }
    ];

    @track supportedFunctions = [
        { label: 'COS', value: 'COS' },
        { label: 'SIN', value: 'SIN' }
    ]

    @track contextVariables = [];

    @track objectName = 'Opportunity';
    @track recordId = '0062v00001Fd64sAAB';

    @wire(getFieldList, { objectName: '$objectName' })
    wiredFields({ data }) {
        if (data) {
            let fields = [];
            data.forEach(item => {
                fields.push({ label: item, value: item });
            })
            this.contextVariables = fields;
        }
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
            this.formula = this.formula + '$' + this.objectName + '.' + event.detail.value;
            event.target.value = '';
        }
    }

    parsedQuery() {
        parseFormula({ formula: this.formula, recordId: this.recordId })
            .then(result => {
                this.parsedFormeula = result;
            })
    }
}