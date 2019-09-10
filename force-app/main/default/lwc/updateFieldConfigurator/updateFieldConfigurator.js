import {LightningElement, api, wire, track} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';

export default class updateFieldConfigurator extends LightningElement {
    @api recordId;
    @api objectType;
    @api fieldName;
    @api value;

    @track _value;
    @track _objectType;
    @track _fieldName;

    @track selectedField;

    @track textOption;
    @track formulaEditorVisible = false;
    @track formulaEditorMessage = 'Show Formula Editor';
    @track currentRecord;
    labels = {
        fieldTypeNotSupported: 'Selected field type is not supported',
        fieldValueLabel: 'Set Field Value',
        fieldNotUpdatable: 'Select field can not be updated',
        fieldIsCompoundMessage: 'This is a compound field that can’t be updated directly. Update the individual field components that make up this field'
    };

    customReferenceTypes = ['User'];

    @wire(getRecord, {recordId: '$recordId', layoutTypes: 'Compact'})
    wiredRecord({error, data}) {
        if (error) {
            this.toastTheError(error, this.source);
        } else if (data) {
            this.currentRecord = data;
            if (!this.objectType) {
                this._objectType = data.apiName;
            }
        }
    }

    connectedCallback() {
        if (this.fieldName) {
            this._fieldName = this.fieldName;
        }
        if (this.objectType) {
            this._objectType = this.objectType;
        }
        if (this.value) {
            this._value = this.value;
        }
    }

    get textOptions() {
        let resultTextOptions = [];
        if (this.fieldProperties && !this.fieldProperties.isRequired) {
            resultTextOptions.push({label: 'A blank value (null)', value: 'null'});
        }
        resultTextOptions.push({label: 'Use a formula to set the new value', value: 'formula_builder'});
        return resultTextOptions;
    }

    get checkboxOptions() {
        return [
            {label: 'True', value: 'true'},
            {label: 'False', value: 'false'}];
    }

    handleFieldChange(event) {
        this.selectedField = JSON.parse(JSON.stringify(event.detail));
        if (this._objectType != this.selectedField.objectType) {
            this._objectType = this.selectedField.objectType;
        }
        if (!this.selectedField.isInit) {
            this._value = null;
        }
        this.setDefaultPicklistValues();
    }

    setDefaultPicklistValues() {
        if (this.textOptions && this.textOptions.length == 1) {
            this.textOption = this.textOptions[0].value;
        } else {
            this.textOption = null;
        }
    }

    handleValueChange(event) {
        this._value = event.detail.value;
    }

    handleOwnerChange(event) {
        this._value = event.detail.memberId;
        // event.detail.notifyAssignee;
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
        if (this.selectedField && this.selectedField.fieldName) {
            return {
                ...this.selectedField, ...{
                    isTextField: this.isTextType(this.selectedField),
                    isUserReferenceField: this.selectedField.referenceTo && this.selectedField.referenceTo.includes('User'),
                    isBoolean: this.selectedField.dataType === 'Boolean',
                    isPicklist: this.selectedField.dataType === 'Picklist',
                    isDateTime: this.selectedField.dataType === 'DateTime',
                    isDate: this.selectedField.dataType === 'Date',
                    isDisabled: this.selectedField.updateable !== true,
                    isRequired: this.selectedField.required === true,
                    isCompoundField: this.selectedField.compound === true && this.selectedField.value !== 'Name',
                }
            }
        }
        return null;
    }

    isTextType(dataType) {
        return this.selectedField.dataType === 'String' ||
            this.selectedField.dataType === 'Currency' ||
            this.selectedField.dataType === 'Double' ||
            this.selectedField.dataType === 'Int' ||
            this.selectedField.dataType === 'Phone' ||
            this.selectedField.dataType === 'Url' ||
            this.selectedField.dataType === 'TextArea' ||
            (this.selectedField.referenceTo && this.selectedField.dataType === 'Reference' && !this.customReferenceTypes.some(refType => this.selectedField.referenceTo.includes(refType)));
    }
}