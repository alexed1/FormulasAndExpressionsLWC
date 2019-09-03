import {LightningElement, track, api, wire} from 'lwc';

export default class expressionBuilder extends LightningElement {
    @api objectType = 'Account'; 
    @api expressions = [];
    @api customCondition;

    @track  _expressions;
    @track _customCondition;
    @track whenToExecute = 'all';

    lastExpressionIndex = 0;
    whenToExecuteOptions = [
        {value: 'all', label: 'All Conditions Are Met'},
        {value: 'any', label: 'Any Condition Is Met'},
        {value: 'custom', label: 'Custom Condition Logic Is Met'}
    ];

    connectedCallback() {
        this._expressions = this.expressions.map(curExp => {
            return {...curExp, ...{id: this.lastExpressionIndex++}};
        });
        this._customCondition = this.customCondition;
        if (this.customCondition) {
            this.whenToExecute = 'custom';
        }
    }

    handleAddExpression(event) {
        if (!this._expressions) {
            this._expressions = [];
        } else {
            this._expressions.push({id: this.lastExpressionIndex++, objectType: this.objectType});
        }
    }

    get showCustomLogicInput() {
        return this.whenToExecute === 'custom';
    }

    handleCustomLogicChange(event) {
        this.customCondition = event.detail.value;
    }

    handleWhenToExecuteChange(event) {
        this.whenToExecute = event.detail.value;
    }

    handleExpressionChange(event) {
        let expressionToModify = this._expressions.find(curExp => curExp.id == event.detail.id);

        for (var detailKey in event.detail) {
            if (Object.prototype.hasOwnProperty.call(event.detail, detailKey)) {
                expressionToModify[detailKey] = event.detail[detailKey];
            }
        }
    }

    handleRemoveExpression(event) {
        this._expressions = this._expressions.filter(curExp => curExp.id != event.detail);
    }
}