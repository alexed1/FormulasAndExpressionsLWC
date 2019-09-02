import {LightningElement, api, track, wire} from 'lwc';

import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import getObjects from '@salesforce/apex/FieldPickerController.getObjects';

import NonePicklistValueLabel from '@salesforce/label/c.NonePicklistValueLabel';
import FieldIsNotSupportedMessage from '@salesforce/label/c.FieldIsNotSupportedMessage';

export default class fieldPicker extends LightningElement {
    @api masterLabel;
    @api objectLabel = 'Object';
    @api fieldLabel = 'Field';
    @api objectType;
    @api field;

    @track _objectType;
    @track _field;
    @track objectTypes;
    @track fields;
    @track errors = [];
    @track isLoadFinished = false;

    labels = {
        none: NonePicklistValueLabel,
        fieldNotSupported: FieldIsNotSupportedMessage
    };

    connectedCallback() {
        if (this.objectType)
            this._objectType = this.objectType;

        if (this.objectType && this.field)
            this._field = this.field;
    }

    @wire(getObjects, {})
    _getObjects({error, data}) {
        if (error) {
            this.errors.push(error.body.message);
        } else if (data) {
            this.isLoadFinished = true;
            this.objectTypes = data;
        }
    }

    @wire(getObjectInfo, {objectApiName: '$_objectType'})
    _getObjectInfo({error, data}) {
        if (error) {
            this.errors.push(error.body[0].message);
        } else if (data) {
            let fields = data.fields;
            let fieldResults = [];
            for (let field in this.fields = fields) {
                if (Object.prototype.hasOwnProperty.call(fields, field)) {
                    fieldResults.push({label: fields[field].label, value: fields[field].apiName});
                }
                if (this._field && !Object.prototype.hasOwnProperty.call(fields, this._field)) {
                    this.errors.push(this.labels.fieldNotSupported + this._field);
                    this._field = null;
                }
            }
            this.fields = fieldResults;
        }
    }

    get isError() {
        return this.errors.length > 0;
    }

    get errorMessage() {
        return this.errors.join('; ');
    }

    get isFieldDisabled() {
        return this._objectType == null || this.isError;
    }

    handleObjectChange(event) {
        this._objectType = event.detail.value;
        this._field = null;
        this.errors = [];
    }

    handleFieldChange(event) {
        this._field = event.detail.value;
        const memberRefreshedEvt = new CustomEvent('fieldselected', {
            bubbles: true, detail: {
                objectType: this._objectType,
                fieldName: this._field,
            }
        });
        dispatchEvent(memberRefreshedEvt);
    }
}