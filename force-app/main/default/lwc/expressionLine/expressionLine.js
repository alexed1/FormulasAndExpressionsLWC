import {LightningElement, api, track} from 'lwc';

export default class expressionLine extends LightningElement {
    @api fieldName;
    @api objectType;
    @api operator;
    @api value;
    @api expressionId;
    @api expressionIndex;
    @api localVariables;
    @api systemVariables;
    @api availableMergeFields = [];

    @track disabledFilter = true;
    @track availableOperators = [];
    @track filterValue = '';

    initialized = false;
 
    renderedCallback() {
        if (this.initialized) {
            return;
        }
        this.initialized = true;
        let listId = this.template.querySelector('datalist').id;
        this.template.querySelector("input").setAttribute("list", listId);
    }

    handleFieldChange(event) {
        if (event.detail.dataType !== undefined) {
            let dataType = event.detail.dataType;
            
            if (dataType === 'Boolean') {
                this.availableOperators = [
                    {value: 'equals', label: 'Equals'},
                    {value: 'not_equal_to', label: 'Not Equal To'},
                ];
            } else if (
                dataType === 'Integer' || dataType === 'Currency' || 
                dataType === 'Percent' || dataType === 'Double' || 
                dataType === 'Date' || dataType === 'DateTime' || dataType === 'Time') {
                this.availableOperators = [
                    {value: 'equals', label: 'Equals'},
                    {value: 'not_equal_to', label: 'Not Equal To'},
                    {value: 'greater_then', label: 'Greater than'},
                    {value: 'greater_or_equal', label: 'Greater Or Equal'},
                    {value: 'less_then', label: 'Less Than'},
                    {value: 'less_or_equal', label: 'Less Or Equal'}
                ];
            } else if (
                dataType === 'String' || dataType === 'Email' || 
                dataType === 'Phone' || dataType === 'TextArea' || dataType === 'Url') {
                this.availableOperators = [
                    {value: 'equals', label: 'Equals'},
                    {value: 'not_equal_to', label: 'Not Equal To'},
                    {value: 'contains', label: 'Contains'},
                    {value: 'starts_with', label: 'Starts with'},
                    {value: 'end_with', label: 'End with'}
                ];
            } else {
                this.availableOperators = [
                    {value: 'equals', label: 'Equals'},
                    {value: 'not_equal_to', label: 'Not Equal To'},
                    {value: 'greater_then', label: 'Greater than'},
                    {value: 'greater_or_equal', label: 'Greater Or Equal'},
                    {value: 'less_then', label: 'Less Than'},
                    {value: 'less_or_equal', label: 'Less Or Equal'},
                    {value: 'contains', label: 'Contains'},
                    {value: 'starts_with', label: 'Starts with'},
                    {value: 'end_with', label: 'End with'}
                ];
            }

            this.disabledFilter = false;
        }
        this.dispatchChangeEvent({
            ...event.detail, ...{
                id: this.expressionId
            }
        });
    }

    handleOperatorChange(event) {
        this.dispatchChangeEvent({
            id: this.expressionId,
            operator: event.detail.value
        });
    }

    handleValueChange(event) {
        this.dispatchChangeEvent({
            id: this.expressionId,
            parameter: event.target.value
        });
    }

    dispatchChangeEvent(customParams) {
        const memberRefreshedEvt = new CustomEvent('fieldselected', {
            bubbles: true,
            detail: customParams
        });
        this.dispatchEvent(memberRefreshedEvt);
    }

    handleExpressionRemove() {
        const expressionRemovedEvent = new CustomEvent('expressionremoved', {
            bubbles: true, detail: this.expressionId
        });
        this.dispatchEvent(expressionRemovedEvent);
    }

    get position() {
        return this.expressionIndex + 1;
    }

}