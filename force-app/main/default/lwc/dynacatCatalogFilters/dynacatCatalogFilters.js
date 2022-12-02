import { LightningElement, wire, api, track } from 'lwc';
import getAttributes from '@salesforce/apex/DynacatCatalogFiltersController.getActiveAttributes';

// Import message service features required for publishing and the message channel
import { publish, MessageContext } from 'lightning/messageService';
import FILTER_CHANGED_CHANNEL from '@salesforce/messageChannel/dynacatFilterChanged__c';

export default class DynacatCatalogFilters extends LightningElement {

    // Inputs
    @api expandedLevels;

    @track attributeList;

    selectedAttributes = {};

    dataRetrieved = false;

    @wire(getAttributes)
    attributes({ error, data }) {
        if (data) {
            let parsedData = JSON.parse(data);
            this.attributeList = parsedData.attributeList;
            this.levels = parsedData.levels;
            this.dataRetrieved = true;
            console.log(JSON.stringify(this.attributeList));
            console.log(JSON.stringify(this.levels));
        } else if (error) {
            console.log(error);
        }
    };

    get dataReady() {
        return (this.dataRetrieved) ? true : false;
    }

    @wire(MessageContext)
    messageContext;

    handleCheckboxClick(event) {
        console.log('Child click at parent: '+JSON.stringify(event.detail));

        let rootFilters = (typeof this.selectedAttributes[event.detail.root] != "undefined") ? this.selectedAttributes[event.detail.root] : [];

        const currentIndex = rootFilters.findIndex(sel => sel==event.detail.xid);
        if(currentIndex >= 0 && !event.detail.checked) {
            rootFilters.splice(currentIndex, 1);
        } else if(currentIndex == -1 && event.detail.checked) {
            rootFilters.push(event.detail.xid);
        }
        this.selectedAttributes[event.detail.root] = rootFilters;

        // Send current filters for this tree
        const appliedFilters = { rootnode : event.detail.root, filters:rootFilters};
        const payload = { appliedFilters };
        publish(this.messageContext, FILTER_CHANGED_CHANNEL, payload);
    }

}