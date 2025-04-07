import { LightningElement, api, track } from 'lwc';
import processPayment from '@salesforce/apex/PaymentProcessingController.processPayment';
import calculateCarCost from '@salesforce/apex/PaymentProcessingController.calculateCarCost';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import QR_CODE from '@salesforce/resourceUrl/QRcode';

export default class CarPaymentProcessing extends LightningElement {
    @api carId;
    @api rentalId;
    @api startDate;
    @api endDate;
    @api pickUpTime;
    @api dropTime;
    @api licenseNumber;
    @api rentalType; // This is a UI parameter, not a field
    @api contactId;

    @track paymentMethod = '';
    @track cashAcknowledged = false;
    @track upiId = '';
    @track cardNumber = '';
    @track cardholderName = '';
    @track expiryMonth = '';
    @track expiryYear = '';
    @track cvv = '';
    @track amount;
    @track advanceAmount;

    qrCodeUrl = QR_CODE;

    get paymentMethodOptions() {
        return [
            { label: 'Cash', value: 'Cash' },
            { label: 'Card', value: 'Card' },
            { label: 'UPI', value: 'UPI' }
        ];
    }

    get isCashSelected() {
        return this.paymentMethod === 'Cash';
    }

    get isCardSelected() {
        return this.paymentMethod === 'Card';
    }

    get isUpiSelected() {
        return this.paymentMethod === 'UPI';
    }

    get isPaymentInvalid() {
        if (this.paymentMethod === 'Cash') {
            return !this.cashAcknowledged;
        } else if (this.paymentMethod === 'Card') {
            return !this.cardNumber || this.cardNumber.length < 16 || 
                   !this.cardholderName || 
                   !this.expiryMonth || this.expiryMonth < 1 || this.expiryMonth > 12 || 
                   !this.expiryYear || this.expiryYear < new Date().getFullYear() || 
                   !this.cvv || this.cvv.length !== 3;
        } else if (this.paymentMethod === 'UPI') {
            return !this.upiId;
        }
        return true;
    }

    connectedCallback() {
        this.displayCost();
    }

    displayCost() {
        calculateCarCost({
            carId: this.carId,
            startDate: this.startDate,
            endDate: this.endDate,
            rentalType: this.rentalType,
            pickUpTime: this.pickUpTime,
            dropTime: this.dropTime
        })
        .then(result => {
            this.amount = result;
            this.advanceAmount = this.amount * 0.2;
        })
        .catch(error => {
            this.showToast('Error', 'Error fetching amount: ' + this.extractErrorMessage(error), 'error');
        });
    }

    resetForm() {
        this.paymentMethod = '';
        this.cashAcknowledged = false;
        this.upiId = '';
        this.cardNumber = '';
        this.cardholderName = '';
        this.expiryMonth = '';
        this.expiryYear = '';
        this.cvv = '';
    }

    updatePaymentMethod(event) {
        this.paymentMethod = event.detail.value;
    }

    updateCashAcknowledgment(event) {
        this.cashAcknowledged = event.target.checked;
    }

    updateUpiId(event) {
        this.upiId = event.target.value;
    }

    updateCardNumber(event) {
        this.cardNumber = event.target.value;
    }

    updateCardholderName(event) {
        this.cardholderName = event.target.value;
    }

    updateExpiryMonth(event) {
        this.expiryMonth = event.target.value;
    }

    updateExpiryYear(event) {
        this.expiryYear = event.target.value;
    }

    updateCvv(event) {
        this.cvv = event.target.value;
    }

    submitPayment() {
        if (this.isPaymentInvalid) {
            this.showToast('Error', 'Please complete all required payment fields correctly.', 'error');
            return;
        }

        const paymentDetails = JSON.stringify(this.getPaymentDetails());
        processPayment({
            contactId: this.contactId,
            carId: this.carId,
            rentalId: this.rentalId,
            startDate: this.startDate,
            endDate: this.endDate,
            licenseNumber: this.licenseNumber,
            paymentMethod: this.paymentMethod,
            rentalType: this.rentalType, // Pass as parameter
            paymentDetails: paymentDetails
        })
        .then(result => {
            if (result === 'success') {
                this.showToast('Success', 'Payment submitted successfully', 'success');
                this.dispatchEvent(new CustomEvent('paymentcompleted'));
                this.resetForm();
            } else {
                this.showToast('Error', result, 'error');
            }
        })
        .catch(error => {
            this.showToast('Error', 'Error submitting payment: ' + this.extractErrorMessage(error), 'error');
        });
    }

    getPaymentDetails() {
        if (this.paymentMethod === 'Cash') {
            return { cashAcknowledged: this.cashAcknowledged };
        } else if (this.paymentMethod === 'UPI') {
            return { upiId: this.upiId };
        } else if (this.paymentMethod === 'Card') {
            return {
                cardNumber: this.cardNumber,
                cardholderName: this.cardholderName,
                expiryMonth: this.expiryMonth,
                expiryYear: this.expiryYear,
                cvv: this.cvv
            };
        }
        return {};
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    extractErrorMessage(error) {
        let message = 'Unknown error';
        if (typeof error === 'string') {
            message = error;
        } else if (error.body && typeof error.body.message === 'string') {
            message = error.body.message;
        } else if (error.message && typeof error.message === 'string') {
            message = error.message;
        }
        return message;
    }
}