import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAllRentals from '@salesforce/apex/CarManagerRentalController.getAllRentals';
import submitRental from '@salesforce/apex/CarManagerRentalController.submitRental';

export default class CarManagerRentalHistory extends LightningElement {
    @track rentals = [];
    @track isLoading = false;
    wiredRentalsResult;

    columns = [
        { label: 'Rental Agreement ID', fieldName: 'Name', type: 'text' },
        { label: 'Contact Name', fieldName: 'Contact_Name__c', type: 'text' },
        { label: 'Car Name', fieldName: 'Car_Name__c', type: 'text' },
        { label: 'Start Date', fieldName: 'Start_Date__c', type: 'date' },
        { label: 'End Date', fieldName: 'End_Date__c', type: 'date' },
        { label: 'Actual End Date', fieldName: 'Actual_End_Date__c', type: 'date' },
        { label: 'Status', fieldName: 'Rental_Status__c', type: 'text' },
        {
            label: 'Action',
            type: 'button',
            typeAttributes: {
                label: 'Submit',
                name: 'submit_rental',
                variant: 'brand',
                disabled: { fieldName: 'isFinalPending' }
            }
        }
    ];

    @wire(getAllRentals)
    wiredRentals(result) {
        this.wiredRentalsResult = result;
        const { data, error } = result;
        if (data) {
            this.rentals = data.map(rental => ({
                ...rental,
                Contact_Name__c: rental.Contact_Relation__r ? rental.Contact_Relation__r.Name : 'N/A',
                Car_Name__c: rental.Car_Relation__r ? rental.Car_Relation__r.Name : 'N/A',
                isFinalPending: rental.Rental_Status__c === 'Final Pending'
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load rentals: ' + error.body.message, 'error');
        }
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'submit_rental') {
            this.isLoading = true;
            try {
                await submitRental({ rentalId: row.Id });
                this.showToast('Success', 'Rental submitted successfully!', 'success');
                await refreshApex(this.wiredRentalsResult);
            } catch (error) {
                this.showToast('Error', 'Failed to submit rental: ' + error.body.message, 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}