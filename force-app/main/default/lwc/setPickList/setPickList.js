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

    nullValue = '__null';
    labels = {
        none: NonePicklistValueLabel
    };

    connectedCallback() {
        this._selectionType = this.selectionType;
        this._value = (this.value === null ? this.nullValue : this.value);
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
            {label: this.valueAboveRadioLabel, value: '__PicklistPrevious'},
            {label: this.valueBelowRadioLabel, value: '__PicklistNext'},
            {label: this.specificValueRadioLabel, value: this.nullValue}];
    }

    get isSpecificValue() {
        return this._selectionType === this.nullValue;
    }

    handleOptionChange(event) {
        this._selectionType = event.detail.value;
        this.handlePicklistValueChange(event);
    }

    handlePicklistValueChange(event) {
        const memberRefreshedEvt = new CustomEvent('picklistselected', {
            bubbles: true, detail: {
                value: (event.detail.value === this.nullValue ? null : event.detail.value),
                selectionType: this._selectionType
            }
        });
        this.dispatchEvent(memberRefreshedEvt);
    }

}