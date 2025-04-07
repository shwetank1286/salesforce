import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getUserRentals from '@salesforce/apex/RentalCancellationController.getUserRentals';
import cancelRental from '@salesforce/apex/RentalCancellationController.cancelRental';
import updateRentalDates from '@salesforce/apex/RentalCancellationController.updateRentalDates';
import processPayment from '@salesforce/apex/RentalCancellationController.processPayment';
import getRentalCancellationInfo from '@salesforce/apex/RentalCancellationController.getRentalCancellationInfo';
import getRentalPayment from '@salesforce/apex/RentalCancellationController.getRentalPayment';
import QR_CODE_URL from '@salesforce/resourceUrl/QRcode';

export default class CarManagerRentalHistory extends LightningElement {
    @track rentals = [];
    @track isLoading = false;
    @track showModal = false;
    @track showDateModal = false;
    @track showPaymentModal = false;
    @track selectedRentalId;
    @track redeemableCash = 0;
    @track totalAmount = 0;
    @track selectedStartDate;
    @track selectedEndDate;
    @track originalAmount = 0;
    @track adjustedAmountToPay = 0;
    @track amountToPay = 0;
    @track useRedeemableCash = false;
    @track selectedPaymentMode = '';
    @track paymentModeOptions = [
        { label: 'Card', value: 'Card' },
        { label: 'UPI', value: 'UPI' },
        { label: 'Cash', value: 'Cash' }
    ];
    @track cardNumber = '';
    @track cardOwnerName = '';
    @track cardExpiryDate = '';
    @track cvv = '';
    @track upiId = '';
    @track cashAcknowledged = false;
    @track qrCodeUrl = QR_CODE_URL;
    wiredRentalsResult;

    columns = [
        { label: 'Rental Agreement ID', fieldName: 'Name', type: 'text' },
        { label: 'Car Name', fieldName: 'Car_Name__c', type: 'text' },
        { label: 'Start Date', fieldName: 'Start_Date__c', type: 'date' },
        { label: 'End Date', fieldName: 'End_Date__c', type: 'date' },
        { label: 'Actual End Date', fieldName: 'Actual_End_Date__c', type: 'date' },
        { label: 'Status', fieldName: 'Rental_Status__c', type: 'text' },
        {
            label: 'Action',
            type: 'button',
            typeAttributes: {
                label: 'Cancel',
                name: 'cancel_rental',
                variant: 'destructive',
                disabled: { fieldName: 'disableCancel' }
            }
        },
        {
            label: 'Update Dates',
            type: 'button',
            typeAttributes: {
                label: 'Update Dates',
                name: 'update_dates',
                variant: 'brand',
                disabled: { fieldName: 'disableUpdate' }
            }
        },
        {
            label: 'Pay',
            type: 'button',
            typeAttributes: {
                label: 'Pay',
                name: 'process_payment',
                variant: 'success',
                disabled: { fieldName: 'isFinalPending' }
            }
        }
    ];

    @wire(getUserRentals)
    wiredRentals(result) {
        this.wiredRentalsResult = result;
        const { data, error } = result;
        if (data) {
            const today = new Date().toISOString().split('T')[0];
            this.rentals = data.map(rental => ({
                ...rental,
                Car_Name__c: rental.Car_Relation__r ? rental.Car_Relation__r.Name : 'N/A',
                isFinalPending: rental.Rental_Status__c !== 'Final Pending',
                disableCancel: rental.Start_Date__c <= today || 
                               ['Completed', 'Final Pending', 'Pending','Cancelled'].includes(rental.Rental_Status__c),
                disableUpdate: rental.Start_Date__c <= today || 
                               ['Completed', 'Final Pending', 'Pending','Cancelled'].includes(rental.Rental_Status__c)
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load rentals: ' + error.body.message, 'error');
        }
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        this.selectedRentalId = row.Id;

        if (actionName === 'cancel_rental') {
            this.isLoading = true;
            try {
                const cancellationInfo = await getRentalCancellationInfo({ rentalId: row.Id });
                this.redeemableCash = cancellationInfo.redeemableCash;
                this.totalAmount = cancellationInfo.totalAmount;
                this.showModal = true;
            } catch (error) {
                this.showToast('Error', 'Failed to load cancellation info: ' + error.body.message, 'error');
            } finally {
                this.isLoading = false;
            }
        } else if (actionName === 'update_dates') {
            this.selectedStartDate = row.Start_Date__c;
            this.selectedEndDate = row.End_Date__c;
            this.showDateModal = true;
        } else if (actionName === 'process_payment') {
            this.isLoading = true;
            try {
                const payment = await getRentalPayment({ rentalId: row.Id });
                const cancellationInfo = await getRentalCancellationInfo({ rentalId: row.Id });
                this.originalAmount = payment ? payment.Amount__c : 0;
                this.redeemableCash = cancellationInfo.redeemableCash;
                this.adjustedAmountToPay = this.originalAmount;
                this.amountToPay = this.originalAmount;
                this.showPaymentModal = true;
            } catch (error) {
                this.showToast('Error', 'Failed to load payment info: ' + error.body.message, 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    async handleRefresh() {
        this.isLoading = true;
        await refreshApex(this.wiredRentalsResult);
        this.isLoading = false;
    }

    closeModal() {
        this.showModal = false;
    }

    async confirmCancel() {
        this.isLoading = true;
        try {
            await cancelRental({ rentalId: this.selectedRentalId });
            this.showToast('Success', 'Rental cancelled successfully!', 'success');
            await refreshApex(this.wiredRentalsResult);
        } catch (error) {
            this.showToast('Error', 'Failed to cancel rental: ' + error.body.message, 'error');
        } finally {
            this.showModal = false;
            this.isLoading = false;
        }
    }

    closeDateModal() {
        this.showDateModal = false;
    }

    handleStartDateChange(event) {
        this.selectedStartDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.selectedEndDate = event.target.value;
    }

    async updateDates() {
        this.isLoading = true;
        try {
            await updateRentalDates({
                rentalId: this.selectedRentalId,
                startDate: this.selectedStartDate,
                endDate: this.selectedEndDate
            });
            this.showToast('Success', 'Rental dates updated successfully!', 'success');
            await refreshApex(this.wiredRentalsResult);
        } catch (error) {
            this.showToast('Error', 'Failed to update dates: ' + error.body.message, 'error');
        } finally {
            this.showDateModal = false;
            this.isLoading = false;
        }
    }

    closePaymentModal() {
        this.showPaymentModal = false;
        this.resetPaymentFields();
    }

    handleRedeemableCashChange(event) {
        this.useRedeemableCash = event.target.checked;
        if (this.useRedeemableCash) {
            const cashToUse = Math.min(this.redeemableCash, this.originalAmount);
            this.adjustedAmountToPay = this.originalAmount - cashToUse;
        } else {
            this.adjustedAmountToPay = this.originalAmount;
        }
    }

    handlePaymentModeChange(event) {
        this.selectedPaymentMode = event.target.value;
    }

    handleCardNumberChange(event) {
        this.cardNumber = event.target.value;
    }

    handleCardOwnerNameChange(event) {
        this.cardOwnerName = event.target.value;
    }

    handleCardExpiryDateChange(event) {
        this.cardExpiryDate = event.target.value;
    }

    handleCvvChange(event) {
        this.cvv = event.target.value;
    }

    handleCashAcknowledgementChange(event) {
        this.cashAcknowledged = event.target.checked;
    }

    handleUpiIdChange(event) {
        this.upiId = event.target.value;
    }

    get isCardMode() {
        return this.selectedPaymentMode === 'Card';
    }

    get isCashMode() {
        return this.selectedPaymentMode === 'Cash';
    }

    get isUpiMode() {
        return this.selectedPaymentMode === 'UPI';
    }

    get isPayButtonDisabled() {
        if (this.isCardMode) {
            return !this.cardNumber || !this.cardOwnerName || !this.cardExpiryDate || !this.cvv;
        }
        if (this.isCashMode) return !this.cashAcknowledged;
        if (this.isUpiMode) return !this.upiId;
        return false;
    }

    async processPayment() {
        this.isLoading = true;
        try {
            await processPayment({
                rentalId: this.selectedRentalId,
                paymentMode: this.selectedPaymentMode,
                useRedeemableCash: this.useRedeemableCash,
                cardNumber: this.cardNumber,
                cardOwnerName: this.cardOwnerName,
                cardExpiryDate: this.cardExpiryDate,
                cvv: this.cvv,
                upiId: this.upiId,
                amount: this.amountToPay
            });
            this.showToast('Success', 'Payment processed successfully!', 'success');
            await refreshApex(this.wiredRentalsResult);
        } catch (error) {
            this.showToast('Error', 'Failed to process payment: ' + error.body.message, 'error');
        } finally {
            this.showPaymentModal = false;
            this.isLoading = false;
            this.resetPaymentFields();
        }
    }

    resetPaymentFields() {
        this.selectedPaymentMode = '';
        this.cardNumber = '';
        this.cardOwnerName = '';
        this.cardExpiryDate = '';
        this.cvv = '';
        this.upiId = '';
        this.cashAcknowledged = false;
        this.useRedeemableCash = false;
        this.originalAmount = 0;
        this.adjustedAmountToPay = 0;
        this.amountToPay = 0;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}