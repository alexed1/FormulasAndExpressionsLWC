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
    @api localVariables;
    @api systemVariables;

    @api supportedObjectTypes;
    @api hideObjectTypeSelect = false;
    @api showFieldType = false;
    @api supportedFieldRelationTypes;

    @track _objectType;
    @track _field;
    @track objectTypes;
    @track fields;
    @track userFields;
    @track errors = [];

    labels = {
        none: NonePicklistValueLabel,
        fieldNotSupported: FieldIsNotSupportedMessage
    };

    connectedCallback() {
        if (this.objectType) {
            this._objectType = this.objectType;
        }

        if (this.objectType && this.field) {
            this._field = this.field;
        }

        let fields = [];

        if (this.localVariables) {
            this.localVariables.forEach(item => {
                fields.push({
                    label: item.Label,
                    dataType: item.Type,
                    value: item.APIName,
                    objectType: ''
                });
            });
        }


        this.fields = fields;
    }

    @wire(getObjects, {supportedObjectTypes: '$supportedObjectTypesList'})
    _getObjects({error, data}) {
        if (error) {
            this.errors.push(error.body.message);
        } else if (data) {
            this.objectTypes = data;
        }
    }

    @wire(getObjectInfo, {objectApiName: '$_objectType'})
    _getObjectInfo({error, data}) {
        if (error) {
            this.errors.push(error.body[0].message);
        } else if (data) {
            let fields = Object.values(data.fields);
            let fieldResults = [];

            fields.forEach(field => {
                if (this.isTypeSupported(field)) {
                    fieldResults.push({
                        label: field.label,
                        value: field.apiName,
                        dataType: field.dataType,
                        required: field.required,
                        updateable: field.updateable,
                        objectType: this._objectType,
                        referenceTo: (field.referenceToInfos.length > 0 ? field.referenceToInfos.map(curRef => {
                            return curRef.apiName
                        }) : [])
                    });
                }
                // if (this._field && !Object.prototype.hasOwnProperty.call(fields, this._field)) {
                //     this.errors.push(this.labels.fieldNotSupported + this._field);
                //     this._field = null;
                // }
            });

            if (fieldResults) {
                this.fields = this.fields.concat(fieldResults);
            }
            if (this.userFields) {
                this.fields = this.fields.concat(this.userFields);
            }

            if (this.fields) {
                this.dispatchDataChangedEvent({...this.fields.find(curField => curField.value === this._field), ...{isInit: true}});
            }
        }
    }

    @wire(getObjectInfo, {objectApiName: 'User'})
    _getUserInfo({error, data}) {
        if (error) {
            this.errors.push(error.body[0].message);
        } else if (data) {
            let fields = Object.values(data.fields);
            let fieldResults = [];

            fields.forEach(field => {
                if (this.isTypeSupported(field)) {
                    fieldResults.push({
                        label: field.label,
                        value: field.apiName,
                        dataType: field.dataType,
                        required: field.required,
                        updateable: field.updateable,
                        objectType: 'User',
                        referenceTo: (field.referenceToInfos.length > 0 ? field.referenceToInfos.map(curRef => {
                            return curRef.apiName
                        }) : [])
                    });
                }
                // if (this._field && !Object.prototype.hasOwnProperty.call(fields, this._field)) {
                //     this.errors.push(this.labels.fieldNotSupported + this._field);
                //     this._field = null;
                // }
            });

            this.userFields = fieldResults;
        }
    }

    get isFieldTypeVisible() {
        return (this.fieldType && this.showFieldType);
    }

    isTypeSupported(field) {
        let result = false;
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
        return this.supportedObjectTypes ? this.splitValues(this.supportedObjectTypes.toLowerCase()) : [this.objectType];
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

    get fieldType() {
        if (this.fields.find(e => e.value === this._field)) {
            return this._field ? this.fields.find(e => e.value === this._field).dataType : null;
        } else {
            return null;
        }

    }

    handleObjectChange(event) {
        this._objectType = event.detail.value;
        this._field = null;
        this.dispatchDataChangedEvent({});
        this.errors = [];
    }

    handleFieldChange(event) {
        this._field = event.detail.value;
        this.dispatchDataChangedEvent(this.fields.find(curField => curField.value === this._field));
    }

    dispatchDataChangedEvent(detail) {
        const memberRefreshedEvt = new CustomEvent('fieldselected', {
            bubbles: false,
            detail: {
                ...detail, ...{
                    fieldName: this._field
                }
            }
        });
        this.dispatchEvent(memberRefreshedEvt);
    }

    splitValues(originalString) {
        return originalString ? originalString.replace(/ /g, '').split(',') : [];
    }
}