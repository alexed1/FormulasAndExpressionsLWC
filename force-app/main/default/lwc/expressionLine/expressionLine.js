import {LightningElement, track, api} from 'lwc';

export default class expressionLine extends LightningElement {
    @api fieldName;
    @api objectType;
    @api operator;
    @api value;
    @api expressionId;
    @api expressionIndex;

    handleSearchKeyUp(event) {

    }

    handleFieldChange(event) {
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
            value: event.detail.value
        });
    }

    dispatchChangeEvent(customParams) {
        const memberRefreshedEvt = new CustomEvent('fieldselected', {
            bubbles: true,
            detail: customParams
        });
        this.dispatchEvent(memberRefreshedEvt);
    }

    handleExpressionRemove(event) {
        const expressionRemovedEvent = new CustomEvent('expressionremoved', {
            bubbles: true, detail: this.expressionId
        });
        this.dispatchEvent(expressionRemovedEvent);
    }

    get availableOperators() {
        return [
            {value: 'equals', label: 'Equals'},
            {value: 'not_equal_to', label: 'Not Equal To'},
            {value: 'starts_with', label: 'Starts with'},
            {value: 'contains', label: 'Contains'},
            {value: 'does_not_contain', label: 'Does Not Contain'},
            {value: 'less_then', label: 'Less Then'},
            {value: 'greater_or_equal', label: 'Greater Or Equal'},
            {value: 'includes', label: 'Includes'},
            {value: 'excludes', label: 'Excludes'}
            ];
    }

    get position() {
        return this.expressionIndex + 1;
    }
}