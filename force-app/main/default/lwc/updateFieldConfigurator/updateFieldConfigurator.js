import {LightningElement, api, wire, track} from 'lwc';

export default class updateFieldConfigurator extends LightningElement {
    @api objectType = 'Account';
    @api fieldName;
    @api value;

    @track selectedField;
    @track _value;
    @track textOption;
    @track formulaEditorVisible = false;
    @track formulaEditorMessage = 'Show Formula Editor';
    textOptions = [
        {label: 'A blank value (null)', value: 'null'},
        {label: 'Use a formula to set the new value', value: 'formula_builder'}];
    checkboxOptions = [
        {label: 'True', value: 'true'},
        {label: 'False', value: 'false'}];

    connectedCallback() {
        //TODO: selectedField - object; fieldName- String

        // if (this.fieldName) {
        //     this.selectedField = this.fieldName;
        // }
        if (this.value) {
            this._value = this.value;
        }
    }

    handleFieldChange(event) {
        this.selectedField = JSON.parse(JSON.stringify(event.detail));
        this._value = null;
    }

    handleValueChange(event) {
        this._value = event.detail.value;
    }

    handleOwnerChange(event) {
        this._value = event.detail.memberId;
        // event.detail.notifyAssignee;
    }

    handlePickListChange(event) {
        this._value = event.detail.value;
        // event.detail.selectionType;
    }

    handleTextOptionValueChange(event) {
        this.textOption = event.detail.value;
    }

    handleSave(event) {

    }

    toggleFormulaEditor() {
        this.formulaEditorVisible = !this.formulaEditorVisible;
        if (this.formulaEditorVisible) {
            this.formulaEditorMessage = 'Hide Formula Editor';
        } else {
            this.formulaEditorMessage = 'Show Formula Editor'
        }
    }

    get showFormulaBuilderOption() {
        return this.textOption === 'formula_builder';
    }

    get fieldProperties() {
        if (this.selectedField) {
            return {
                ...this.selectedField, ...{
                    isTextField: this.selectedField.dataType === 'String',
                    isOwnerField: this.selectedField.fieldName === 'OwnerId',
                    isBoolean: this.selectedField.dataType === 'Boolean',
                    isPicklist: this.selectedField.dataType === 'Picklist',
                    isDateTime: this.selectedField.dataType === 'DateTime',
                    isDate: this.selectedField.dataType === 'Date'
                }
            }
        }
        return null;
    }
}