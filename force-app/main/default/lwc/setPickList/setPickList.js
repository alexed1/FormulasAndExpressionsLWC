import {LightningElement, api, track, wire} from 'lwc';
import getPicklistValues from '@salesforce/apex/FieldPickerController.getPicklistValues';
import NonePicklistValueLabel from '@salesforce/label/c.NonePicklistValueLabel';

export default class setPickList extends LightningElement {
    @api masterLabel = 'Picklist Options';
    @api valueAboveRadioLabel = 'The value above the current one';
    @api valueBelowRadioLabel = 'The value below the current one';
    @api specificValueRadioLabel = 'A Specific Value';
    @api picklistObjectName;
    @api picklistFieldName;
    @api selectionType;
    @api value;

    @track _selectionType;
    @track _value;
    @track availableValues;

    labels = {
        none: NonePicklistValueLabel
    };

    connectedCallback() {
        this._selectionType = this.selectionType;
        this._value = this.value;
    }

    @wire(getPicklistValues, {objectApiName: '$picklistObjectName', fieldName: '$picklistFieldName'})
    _getPicklistValues({error, data}) {
        if (error) {
            this.errors.push(error.body.message);
        } else if (data) {
            this.availableValues = data;
        }
    }

    get picklistOptions() {
        return [
            {label: this.valueAboveRadioLabel, value: 'valueAboveRadioLabel'},
            {label: this.valueBelowRadioLabel, value: 'valueBelowRadioLabel'},
            {label: this.specificValueRadioLabel, value: 'specificValueRadioLabel'}];
    }

    get isSpecificValue() {
        return this._selectionType === 'specificValueRadioLabel';
    }

    handleOptionChange(event) {
        this._selectionType = event.detail.value;
    }

    handlePicklistValueChange(event) {
        const memberRefreshedEvt = new CustomEvent('picklistselected', {
            bubbles: true, detail: {
                value: event.detail.value,
                selectionType: this._selectionType
            }
        });
        this.dispatchEvent(memberRefreshedEvt);
    }

}