import { LightningElement, wire, api, track } from 'lwc';
import getAttributes from '@salesforce/apex/DynacatCatalogFiltersController.getActiveAttributes';

// Import message service features required for publishing and the message channel
import { publish, MessageContext } from 'lightning/messageService';
import FILTER_CHANGED_CHANNEL from '@salesforce/messageChannel/DynacatFilterChanged__c';

export default class DynacatCatalogFilters extends LightningElement {

    // Inputs
    @api expandedLevels;

    @track attributeList;

    // TODO: Implement Row Toggling
    expandedRows = [];
    dataRetrieved = false;

    @wire(getAttributes)
    attributes({ error, data }) {
        if (data) {
            let parsedData = JSON.parse(data);
            this.attributeList = parsedData.attributeList;
            // TODO: Implement preset filters
            if (parsedData.hasOwnProperty('savedAttributes') && parsedData.savedAttributes.length > 0) {
                this.selectedRows = parsedData.savedAttributes;
                parsedData.savedAttributes.forEach((sa) => {
                    this.selectedRowStore.push({ id: sa });
                    this.selectedFilters.push(sa);
                });
            }
            this.levels = parsedData.levels;
            if (this.expandedLevels != null) {
                let _expandedLevels = this.expandedLevels.split(",");
                _expandedLevels.forEach(level => {
                    this.expandedRows = this.expandedRows.concat(this.expandedRows, this.levels[level]);
                });
            }
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

    handleCheckboxClick(event) {
        console.log('Checkbox clicked.');
        let dataPath = event.currentTarget.attributes.getNamedItem('data-path').value;
        let dataLevel = event.currentTarget.attributes.getNamedItem('data-level').value;
        let checked = event.currentTarget.checked;

        // if a checkbox is clicked, any child checkboxes should also be checked/cleared
        let branchCheckboxes = this.template.querySelectorAll("input[data-path^=" + dataPath + "]");
        branchCheckboxes.forEach((checkbox) => {
            checkbox.checked = checked;
            checkbox.indeterminate = false;
        });

        // if a checkbox is clicked, its ancestors need to be assessed to see if their state should change
        // from checked (all descendents checked), unchecked (no descendents checked) or indeterminate.
        const path = dataPath.split('x').filter(element => element);
        let nodeLevel = dataLevel;
        let assessSiblings = true;

        // Walk backwards up the path, ignore the current element
        for (let i = path.length - 2; i > 0; i--) {
            try {
                let parentCheckbox = this.template.querySelector("input[data-id=" + path[i] + "]");
                if (assessSiblings) {
                    let siblingCheckboxes = this.template.querySelectorAll("ul[data-ul=" + path[i] + "] input[data-level='" + nodeLevel + "']");
                    let allchecked = true;
                    let allunchecked = true;
                    siblingCheckboxes.forEach((cb) => {
                        if (cb.checked) allunchecked = false;
                        else allchecked = false;
                    });
                    if (allchecked) {
                        parentCheckbox.checked = true;
                        parentCheckbox.indeterminate = false;
                    } else if (allunchecked) {
                        parentCheckbox.checked = false;
                        parentCheckbox.indeterminate = false;
                    } else {
                        parentCheckbox.checked = true;
                        parentCheckbox.indeterminate = true;
                        assessSiblings = false;
                    }
                } else {
                    parentCheckbox.checked = true;
                    parentCheckbox.indeterminate = true;
                }
            } catch (error) {
                console.log(error);
            }
            nodeLevel--;
        }

        // Send current filters for this tree
        let rootNode = dataPath.substring(0, dataPath.indexOf('x'));
        let treeCheckboxes = this.template.querySelectorAll("input[data-path^='" + rootNode + "x'][type='checkbox']:checked");
        let appliedFilters = {};
        appliedFilters.rootNode = rootNode;
        appliedFilters.filters = [];
        treeCheckboxes.forEach((el) => {
            appliedFilters.filters.push(el.getAttribute("data-id"));
        });

        const payload = { appliedFilters };
        publish(this.messageContext, FILTER_CHANGED_CHANNEL, payload);
    }

    handleBranchClick(event) {
        console.log('Branch clicked!');
        let dataId = event.currentTarget.attributes.getNamedItem('data-id').value;

        let eL = this.template.querySelector("li[data-id='" + dataId + "']");
        let expand = (eL.getAttribute("aria-expanded") == "true") ? "false" : "true";
        eL.setAttribute("aria-expanded", expand);
    }

}