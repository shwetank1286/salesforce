import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getRedeemableCash from '@salesforce/apex/GetRedeemableCash.getRedeemableCash';
import { registerRefreshHandler, unregisterRefreshHandler } from 'lightning/refresh';

export default class RedeemableCashDisplay extends LightningElement {
    cashValue = '0.00';
    wiredResult; 

    
    connectedCallback() {
        this.refreshHandlerId = registerRefreshHandler(this, this.refreshData.bind(this));
    }

    disconnectedCallback() {
        unregisterRefreshHandler(this.refreshHandlerId);
    }

    @wire(getRedeemableCash)
    wiredCash(result) {
        this.wiredResult = result; 
        const { error, data } = result;
        if (data) {
            this.cashValue = data.toFixed(2);
        } else if (error) {
            console.error('Error fetching redeemable cash:', error);
            this.cashValue = '0.00';
        }
    }

    
    refreshData() {
        return refreshApex(this.wiredResult);
    }
}