import { LightningElement, api, track } from 'lwc';

export default class DynacatCheckboxFilter extends LightningElement {

    @api xid;
    @api root;
    @api label;
    @api path;
    @api children;
    @api haschildren;
    @api level;
    @api checked=false;
    @api indeterminate=false;
    arialevel;
    @api selectable;

    @api childLevel;
    @api addChild = false;


    @api
    clickCheckbox(checked, clickThis, clickChildren) {

        this.checked = checked;

        console.log('Checkbox clicked: ' + this.label + ' (' + this.xid + ') - ' + checked);

        if (clickThis) {
            let thisCheckbox = this.template.querySelector("input[data-id=" + this.xid + "]");
            thisCheckbox.checked = checked;
            thisCheckbox.indeterminate = false;
        }

        const checkboxClick = this.dispatchEvent(new CustomEvent('checkboxclick', {
            detail: {
                root: this.root, label: this.label, xid: this.xid, checked: checked
            }
        }));

        if (clickChildren && this.haschildren) {
            this.template.querySelectorAll('c-dynacat-checkbox-filter').forEach((child) => {
                console.log(child.label);
                child.clickCheckbox(checked, true, true);
            });
        }
    }

    handleBranchClick(event) {
        console.log('Branch clicked: ' + this.label + ' (' + this.xid + ')');
        let eL = this.template.querySelector("li[data-id='" + this.xid + "']");
        let expand = (eL.getAttribute("aria-expanded") == "true") ? "false" : "true";
        eL.setAttribute("aria-expanded", expand);
    }

    handleCheckboxClick(event) {
        this.clickCheckbox(event.currentTarget.checked, false, this.haschildren);
    }

    handleChildCheckboxClick(event) {
        let assessChildren = true;

        const thisCheckbox = this.template.querySelector("input[data-id=" + this.xid + "]");
        try {
            if (assessChildren) {
                const children = this.template.querySelectorAll('c-dynacat-checkbox-filter');
                let allchecked = true;
                let allunchecked = true;
                children.forEach(child => {
                    if (child.checked) allunchecked = false;
                    else allchecked = false;
                });
                if (allchecked) {
                    this.checked = true;
                    thisCheckbox.checked = true;
                    this.indeterminate = false;
                    thisCheckbox.indeterminate = false;
                } else if (allunchecked) {
                    this.checked = false;
                    thisCheckbox.checked = false;
                    this.indeterminate = false;
                    thisCheckbox.indeterminate = false;
                } else {
                    this.checked = false;
                    thisCheckbox.checked = false;
                    this.indeterminate = false;
                    thisCheckbox.indeterminate = true;
                    assessChildren = false;
                }
            } else {
                this.checkbox = true;
                thisCheckbox.checked = true;
                this.indeterminate = true;
                thisCheckbox.indeterminate = true;
            }
        } catch (error) {
            console.log(error);
        }
        this.clickCheckbox(this.checked, false, false);
        const checkboxClick = this.dispatchEvent(new CustomEvent('checkboxclick', { detail: event.detail }));
    }

    connectedCallback() {
        this.arialevel = this.level + 1;
    }
}