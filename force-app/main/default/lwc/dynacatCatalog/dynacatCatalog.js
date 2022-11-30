/*
 *  NB: This code is provided as sample code only
 *  It should not be used as-is in Production, and
 *  is not supported or warranted in any way by Salesforce.
 */

import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getActiveRecords from '@salesforce/apex/DynacatCatalogController.getActiveRecords';

// Import message service features required for subscribing and the message channel
import { subscribe, MessageContext } from 'lightning/messageService';
import FILTER_CHANGED_CHANNEL from '@salesforce/messageChannel/dynacatFilterChanged__c';

export default class DynacatCatalog extends NavigationMixin(LightningElement) {

    // Inputs
    @api objectApiName;
    @api uniqueFieldName;
    @api isActiveFieldName;
    @api defaultResults;

    @track filteredRecords;
    @track records;
    @track recAttr;

    @track filters = {};

    dataRetrieved = false;

    @wire(getActiveRecords, {
        objectApiName: '$objectApiName',
        uniqueFieldName: '$uniqueFieldName',
        isActiveFieldName: '$isActiveFieldName'
    })
    attributes({ error, data }) {
        if (data) {
            let parsedData = JSON.parse(data);
            this.records = parsedData.records;
            this.filteredRecords = this.records;
            this.recAttr = parsedData.recAttr;
            console.log(JSON.stringify(this.recAttr));
            console.log(JSON.stringify(this.records));
            this.dataRetrieved = true;
        } else if (error) {
            console.log(error);
        }
    };

    get dataReady() {
        return (this.dataRetrieved) ? true : false;
    }

    @wire(MessageContext)
    messageContext;

    // Encapsulate logic for LMS subscribe.
    subscribeToMessageChannel() {
        this.subscription = subscribe(
            this.messageContext,
            FILTER_CHANGED_CHANNEL,
            (message) => this.handleMessage(message)
        );
    }

    // Handler for message received by component
    handleMessage(message) {
        let node = message.appliedFilters;
        this.filters[node.rootNode] = node.filters;

        let _filteredRecords = this.records;

        for (var tree in this.filters) {
            if (this.filters.hasOwnProperty(tree) && this.filters[tree].length > 0) {
                console.log('filter found');
                let _matchingRecordIds = [];
                this.filters[tree].forEach((f) => {
                    if (this.recAttr.hasOwnProperty(f)) {
                        console.log('Matched Filter: ' + f);
                        _matchingRecordIds = _matchingRecordIds.concat(this.recAttr[f]);
                    }
                });
                _matchingRecordIds = [...new Set(_matchingRecordIds)];
                _filteredRecords = _filteredRecords.filter(rec => _matchingRecordIds.includes(rec["id"]));

            } else {
                // do nothing, leave _filteredRecords as is
            }
        }
        this.filteredRecords = _filteredRecords;
        console.log(this.filteredRecords);
    }

    handleRecordClick(event) {
        // Stop the event's default behavior.
        // Stop the event from bubbling up in the DOM.
        event.preventDefault();
        event.stopPropagation();


        let recordId = event.currentTarget.attributes.getNamedItem('data-uid').value;
        this[NavigationMixin.Navigate]({ 
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: this.objectApiName,
                actionName: 'view'
            }
        });
    }

    // Standard lifecycle hooks used to sub/unsub to message channel
    connectedCallback() {
        this.subscribeToMessageChannel();
    }


}