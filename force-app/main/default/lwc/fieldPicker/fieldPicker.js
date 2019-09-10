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
    @api objectDisabled;
    @api hideReadOnlyFields;
    @api supportedObjectTypes;
    @api hideObjectTypeSelect = false;
    @api showFieldType = false;
    @api supportedFieldRelationTypes;

    @track _field;
    @track objectTypes;
    @track fields;
    @track errors = [];
    @track isObjectLoadFinished = false;
    @track isFieldLoadFinished = false;

    labels = {
        none: NonePicklistValueLabel,
        fieldNotSupported: FieldIsNotSupportedMessage
    };

    connectedCallback() {

        if (this.objectType && this.field) {
            this._field = this.field;
        }
        if (!this.objectType) {
            this.isFieldLoadFinished = true;
        }
    }

    @wire(getObjects, {supportedObjectTypes: '$supportedObjectTypesList'})
    _getObjects({error, data}) {
        this.isObjectLoadFinished = false;
        if (error) {
            this.errors.push(error.body.message);
        } else if (data) {
            this.objectTypes = data;
            this.isObjectLoadFinished = true;
        }
    }

    @wire(getObjectInfo, {objectApiName: '$objectType'})
    _getObjectInfo({error, data}) {
        this.isFieldLoadFinished = false;
        if (error) {
            this.errors.push(error.body[0].message);
        } else if (data) {
            let fields = data.fields;
            let fieldResults = [];
            for (let field in this.fields = fields) {
                if (Object.prototype.hasOwnProperty.call(fields, field)) {
                    if (this.isTypeSupported(fields[field])) {
                        fieldResults.push({
                            label: this.adjustLabel(fields[field].label),
                            value: fields[field].apiName,
                            dataType: fields[field].dataType,
                            required: fields[field].required,
                            updateable: fields[field].updateable,
                            compound: fields[field].compound,
                            referenceTo: (fields[field].referenceToInfos.length > 0 ? fields[field].referenceToInfos.map(curRef => {
                                return curRef.apiName
                            }) : [])
                        });
                    }
                }
                if (this._field && !Object.prototype.hasOwnProperty.call(fields, this._field)) {
                    this.errors.push(this.labels.fieldNotSupported + this._field);
                    this._field = null;
                }
            }
            fieldResults.sort((a, b) => (a.label > b.label) ? 1 : ((b.label > a.label) ? -1 : 0));
            this.fields = fieldResults;
            if (this.fields) {
                this.dispatchDataChangedEvent({
                    ...this.fields.find(curField => curField.value == this._field), ...{
                        objectType: this.objectType,
                        isInit: true
                    }
                });
            }
            this.isFieldLoadFinished = true;
        }

    }

    adjustLabel(label) {
        if (!label) {
            return '';
        } else {
            return label.includes(' ID') ? label.replace(' ID', '') : label;
        }
    }

    get isDataLoaded() {
        return this.isObjectLoadFinished && this.isFieldLoadFinished;
    }

    get isFieldTypeVisible() {
        return (this.fieldType && this.showFieldType);
    }

    isTypeSupported(field) {
        let result = false;

        if (!field.updateable && this.hideReadOnlyFields) {
            return false;
        }
        if (!this.supportedFieldRelationTypes) {
            result = true;
        }
        if (!result && field.referenceToInfos.length > 0) {
            field.referenceToInfos.forEach(curRef => {
                if (this.supportedFieldRelationTypes.toLowerCase().includes(curRef.apiName.toLowerCase())) {
                    result = true;
                }
            });
        }
        return result;
    }

    get supportedObjectTypesList() {
        if (this.supportedObjectTypes) {
            return this.splitValues(this.supportedObjectTypes.toLowerCase());
        } else {
            return [];
        }
    }

    get isError() {
        return this.errors.length > 0;
    }

    get errorMessage() {
        return this.errors.join('; ');
    }

    get isFieldDisabled() {
        return this.objectType == null || this.isError;
    }

    get fieldType() {
        if (this._field && this.fields) {
            let curField = this.fields.find(e => e.value == this._field);
            if (curField) {
                return this.transformTypeLabel(curField.dataType);
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    transformTypeLabel(fieldLabel) {
        return (fieldLabel === 'Reference' ? 'Lookup' : fieldLabel);
    }

    handleObjectChange(event) {

        this._field = null;
        this.dispatchDataChangedEvent({objectType: event.detail.value});
        this.errors = [];
    }

    handleFieldChange(event) {
        this._field = event.detail.value;
        this.dispatchDataChangedEvent({...{objectType: this.objectType}, ...this.fields.find(curField => curField.value == this._field)});
    }

    dispatchDataChangedEvent(detail) {
        const memberRefreshedEvt = new CustomEvent('fieldselected', {
            bubbles: true,
            detail: {
                ...detail, ...{
                    fieldName: this._field
                }
            }
        });
        this.dispatchEvent(memberRefreshedEvt);
    }

    splitValues(originalString) {
        if (originalString) {
            return originalString.replace(/ /g, '').split(',');
        } else {
            return [];
        }
    };
}