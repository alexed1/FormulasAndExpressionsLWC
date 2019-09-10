export {
    generateCapabilityColumns,
    splitValues
};

const generateCapabilityColumns = (labels, hideLabels) => {
    let labelsArray = labels.replace(/ /g, '').split(',');
    return labelsArray.map(curLabel => {
        return getColumnDescriptor(curLabel, hideLabels);
    });
};

const getColumnDescriptor = (curButtonLabel, hideLabels) => {
    return {
        type: 'button',
        label: hideLabels ? '' : curButtonLabel,
        typeAttributes: {
            label: curButtonLabel,
            name: curButtonLabel, //this is used to determine an apex method to call
            variant: 'neutral',
            disabled: {fieldName: curButtonLabel.replace(/ /g, '') + 'buttonDisabled'}
        },
        initialWidth: 120 //TODO: Calculate based on content
    }
};

const splitValues = (originalString) => {
    if (originalString) {
        return originalString.replace(/ /g, '').split(',');
    } else {
        return [];
    }
};


