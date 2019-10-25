import {LightningElement, track, api} from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
//import conditionLogicHelpText from '@salesforce/label/c.ConditionLogicHelpText';
import assembleFormulaString from '@salesforce/apex/ExpressionBuilder.assembleFormulaString';
import disassemblyFormulaString from '@salesforce/apex/ExpressionBuilder.disassemblyFormulaString';


export default class expressionBuilder extends LightningElement {

    @api expressions;
    @api addButtonLabel = 'Add Condition';
    @api localVariables;
    @api contextRecordObjectName = 'Account';
    @api systemVariables;
    @api availableRHSMergeFields;

    @track expressionLines = [];
    @track customLogic = '';
    @track logicType = 'AND';
    @track convertedExpression;

    @api
    get value() {
        return this.convertedExpression;
    }

    set value(value) {
        this.convertedExpression = value;
    }

    lastExpressionIndex = 0;
    logicTypes = [
        {value: 'AND', label: 'All Conditions Are Met'},
        {value: 'OR', label: 'Any Condition Is Met'},
        {value: 'CUSTOM', label: 'Custom Condition Logic Is Met'}
    ];
    conditionLogicHelpText = 'placeholder for conditionLogicHelpTest' //conditionLogicHelpText;

    connectedCallback() {
        let expressionsToDisassemble = this.convertedExpression ? this.convertedExpression : this.expressions;
        disassemblyFormulaString({expression: expressionsToDisassemble}).then(result => {
            if (result.logicType !== undefined) {
                this.logicType = result.logicType;
            }
            if (result.customLogic !== undefined) {
                this.customLogic = result.customLogic;
            }
            if (result.expressionLines !== undefined) {
                let expressionLines = [];
                result.expressionLines.forEach((line, index) => {
                    expressionLines.push({
                        ...this.generateNewExpression(), ...{
                        fieldName: line.fieldName,
                        id: index,
                        objectType: line.objectType,
                        operator: line.operator,
                        parameter: line.parameter
                        }
                    });
                    this.lastExpressionIndex = index + 1
                });
                this.expressionLines = expressionLines;
            }
        })
    }

    generateNewExpression() {
        return {
            id: this.lastExpressionIndex++, 
            objectType: this.contextRecordObjectName,
            localVariables: this.localVariables !== undefined ? JSON.parse(this.localVariables) : [],
            systemVariables: this.systemVariables !== undefined ? JSON.parse(this.systemVariables) : [],
            availableRHSMergeFields: this.availableRHSMergeFields !== undefined ? JSON.parse(this.availableRHSMergeFields) : [],
            parameter: ''
        };
    }

    handleAddExpression() {
        this.expressionLines.push(this.generateNewExpression());
    }

    get showCustomLogicInput() {
        return this.logicType === 'CUSTOM';
    }

    handleCustomLogicChange(event) {
        this.customLogic = event.detail.value;
        this.assembleFormula();
    }

    handleWhenToExecuteChange(event) {
        this.logicType = event.detail.value;
        this.assembleFormula();
    }

    handleExpressionChange(event) {
        let expressionToModify = this.expressionLines.find(curExp => curExp.id === event.detail.id);

        for (let detailKey in event.detail) {
            if (Object.prototype.hasOwnProperty.call(event.detail, detailKey)) {
                expressionToModify[detailKey] = event.detail[detailKey];
            }
        }
        if (event.detail.isInit !== true) {
        this.assembleFormula();
    }
    }

    handleRemoveExpression(event) {
        this.expressionLines = this.expressionLines.filter(curExp => curExp.id !== event.detail);
        this.assembleFormula();
    }

    assembleFormula() {
        if ((this.logicType === 'CUSTOM' && this.customLogic.length > 0) || this.logicType !== 'CUSTOM') {
            assembleFormulaString({
                customLogic: this.customLogic.toUpperCase(), 
                logicType: this.logicType, 
                expressionLines: JSON.stringify(this.expressionLines)
            }).then(result => {
                this.convertedExpression = result
            })
        } else {
            this.convertedExpression = ''
        }

        const valueChangeEvent = new FlowAttributeChangeEvent('value', this.convertedExpression);
        this.dispatchEvent(valueChangeEvent);

    }

    get disabledAddButton() {
        return this.expressionLines.length > 9;
    }
}