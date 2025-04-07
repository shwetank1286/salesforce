// import { LightningElement, api, track, wire } from 'lwc';
// export default class RentalPayment extends LightningElement {
//     // Properties from parent component
//     @api carId;
//     @api rentalId;
//     @api startDate;
//     @api endDate;
//     @api startTime;
//     @api endTime;
//     @api licenseNumber;
//     @api rentalType;
//     // Payment related properties
//     @track paymentMethod = ''; //holds option selected payment method
//     @track isLoading = false;
//     @track cashAcknowledged = false; // holds cash checkbox value
//     @track upiId = '';
//     @track showQrCode = false;
//     // Card details
//     @track cardNumber = '';
//     @track cardholderName = '';
//     @track expiryMonth = '';
//     @track expiryYear = '';
//     @track cvv = '';
//     // Payment method options
//     get paymentMethodOptions() {
//         return [
//             { label: 'Cash', value: 'cash' },
//             { label: 'Card', value: 'card' },
//             { label: 'UPI', value: 'upi' }
//         ];
//     }
//     // Computed properties for conditional rendering
//     get isCashSelected() {
//         return this.paymentMethod === 'cash';
//     }
//     get isCardSelected() {
//         return this.paymentMethod === 'card';
//     }
//     get isUpiSelected() {
//         return this.paymentMethod === 'upi';
//     }
//     get isPaymentValid() {
//         if (this.paymentMethod === 'cash') {
//             return this.cashAcknowledged; //checks cash checkbox value
//         } else if (this.paymentMethod === 'card') {
//             return this.cardNumber && this.cardholderName && this.expiryMonth && 
//                    this.expiryYear && this.cvv;
//         } else if (this.paymentMethod === 'upi') {
//             return this.upiId;
//         }
//         return false;
//     }
//     // Handles payment method change
//     handlePaymentMethodChange(event) {
//         this.paymentMethod = event.detail.value;
//         if (this.paymentMethod === 'upi') {
//             this.showQrCode = true;
//         } else {
//             this.showQrCode = false;
//         }
//     }
//     // Handles cash acknowledgment checkbox
//     handleCashAcknowledgment(event) {
//         this.cashAcknowledged = event.target.checked; // assigns cash checkbox box to variable
//     }
//     // Handles UPI ID input
//     handleUpiIdChange(event) {
//         this.upiId = event.target.value;
//     }
//     // Handles card detail changes
//     handleCardNumberChange(event) {
//         this.cardNumber = event.target.value;
//     }
//     handleCardholderNameChange(event) {
//         this.cardholderName = event.target.value;
//     }
//     handleExpiryMonthChange(event) {
//         this.expiryMonth = event.target.value;
//     }
//     handleExpiryYearChange(event) {
//         this.expiryYear = event.target.value;
//     }
//     handleCvvChange(event) {
//         this.cvv = event.target.value;
//     }

//     // Processes payment
//     handlePayment() {
//         // Validate payment method specific requirements
//         if (!this.paymentMethod) {
//             this.showToast('Error', 'Please select a payment method', 'error');
//             return;
//         }
//         if (this.paymentMethod === 'cash' && !this.cashAcknowledged) {
//             this.showToast('Error', 'Please acknowledge the cash payment', 'error');
//             return;
//         }
//         if (this.paymentMethod === 'upi' && !this.upiId) {
//             this.showToast('Error', 'Please enter UPI ID', 'error');
//             return;
//         }
//         if (this.paymentMethod === 'card') {
//             if (!this.cardNumber || !this.cardholderName || !this.expiryMonth || 
//                 !this.expiryYear || !this.cvv) {
//                 this.showToast('Error', 'Please enter all card details', 'error');
//                 return;
//             }
//         }
//         // Prepare payment data
//         const paymentData = {
//             rentalId: this.rentalId,
//             carId: this.carId,
//             startDate: this.startDate,
//             endDate: this.endDate,
//             startTime: this.startTime,
//             endTime: this.endTime,
//             license_num: this.licenseNumber,
//             paymentMethod: this.paymentMethod,
//             rentalType: this.rentalType,
//             paymentDetails: this.getPaymentDetails()
//         };

        
//         // this.isLoading = true;
//         // // Submit payment for approval
//         // submitPaymentForApproval({ paymentData: JSON.stringify(paymentData) })
//         //     .then(result => {
//         //         this.isLoading = false;
//         //         if (result.success) {
//         //             this.showToast('Success', 'Payment submitted for approval', 'success');
//         //             // Dispatch event to notify parent component
//         //             this.dispatchEvent(new CustomEvent('paymentsubmitted', {
//         //                 detail: { paymentId: result.paymentId }
//         //             }));
//         //         } else {
//         //             this.showToast('Error', result.message || 'Payment submission failed', 'error');
//         //         }
//         //     })
//         //     .catch(error => {
//         //         this.isLoading = false;
//         //         this.showToast('Error', 'Error submitting payment: ' + this.extractErrorMessage(error), 'error');
//         //     });
//     }
//     // Helper method to get payment details based on payment method
//     getPaymentDetails() {
//         if (this.paymentMethod === 'cash') {
//             return { cashAcknowledged: this.cashAcknowledged };
//         } else if (this.paymentMethod === 'upi') {
//             return { upiId: this.upiId };
//         } else if (this.paymentMethod === 'card') {
//             // In a real implementation, you would want to encrypt this data
//             return {
//                 cardNumber: this.cardNumber,
//                 cardholderName: this.cardholderName,
//                 expiryMonth: this.expiryMonth,
//                 expiryYear: this.expiryYear,
//                 cvv: this.cvv
//             };
//         }
//         return {};
//     }
//     // Helper method to show toast notifications
//     showToast(title, message, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         });
//         this.dispatchEvent(evt);
//     }
//     // Helper method to extract error message
//     extractErrorMessage(error) {
//         let message = 'Unknown error';
//         if (typeof error === 'string') {
//             message = error;
//         } else if (error.body && typeof error.body.message === 'string') {
//             message = error.body.message;
//         } else if (error.message && typeof error.message === 'string') {
//             message = error.message;
//         }
//         return message;
//     }

// }



import { LightningElement, api, track } from 'lwc';
import submitPaymentForApproval from '@salesforce/apex/rentalPaymentController.createRentalPayment';
import getCarAmount from '@salesforce/apex/rentalPaymentController.getCarAmount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
 
export default class RentalPayment extends LightningElement {
    @api carId;
    @api rentalId;
    @api startDate;
    @api endDate;
    @api startTime;
    @api endTime;
    @api licenseNumber;
    @api rentalType;
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
 
    get paymentMethodOptions() {
        return [
            { label: 'Cash', value: 'Cash' },
            { label: 'Card', value: 'Card' },
            { label: 'UPI', value: 'UPI' }
        ];
    }

    connectedCallback() {
        this.showAmount();
    }
    
    showAmount(){
        getCarAmount({carId: this.carId,
        startDate: this.startDate,
        endDate: this.endDate})
        .then(result=>{
            this.amount=result;
            this.advanceAmount = this.amount*0.2;
        }).catch(error => {
            this.showToast('Error', 'Error submitting payment: ' + this.extractErrorMessage(error), 'error');
        });
    }

    resetFunction(){
        this.paymentMethod = '';
    this.cashAcknowledged = false;
    this.upiId = '';
    this.cardNumber = '';
    this.cardholderName = '';
    this.expiryMonth = '';
    this.expiryYear = '';
    this.cvv = '';
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
    get isPaymentValid() {
        if (this.paymentMethod === 'Cash') {
            return this.cashAcknowledged;
        } else if (this.paymentMethod === 'Card') {
            return this.cardNumber && this.cardholderName && this.expiryMonth && 
                   this.expiryYear && this.cvv;
        } else if (this.paymentMethod === 'UPI') {
            return this.upiId;
        }
        return false;
    }
 
    handlePaymentMethodChange(event) {
        this.paymentMethod = event.detail.value;
    }
 
    handleCashAcknowledgment(event) {
        this.cashAcknowledged = event.target.checked;
        console.log(this.cashAcknowledged);
    }
 
    handleUpiIdChange(event) {
        this.upiId = event.target.value;
    }
 
    handleCardNumberChange(event) {
        this.cardNumber = event.target.value;
    }
    handleCardholderNameChange(event) {
        this.cardholderName = event.target.value;
    }
    handleExpiryMonthChange(event) {
        this.expiryMonth = event.target.value;
    }
    handleExpiryYearChange(event) {
        this.expiryYear = event.target.value;
    }
    handleCvvChange(event) {
        this.cvv = event.target.value;
    }
 
    handlePayment() {
        if (!this.paymentMethod) {
            this.showToast('Error', 'Please select a payment method', 'error');
            return;
        }
        if (this.paymentMethod === 'Cash' && !this.cashAcknowledged) {
            this.showToast('Error', 'Please acknowledge the cash payment', 'error');
            return;
        }
        if (this.paymentMethod === 'UPI' && !this.upiId) {
            this.showToast('Error', 'Please enter UPI ID', 'error');
            return;
        }
        if (this.paymentMethod === 'Card') {
            if (!this.cardNumber || !this.cardholderName || !this.expiryMonth || 
                !this.expiryYear || !this.cvv) {
                this.showToast('Error', 'Please enter all card details', 'error');
                return;
            }
        }

        console.log(this.carId,this.rentalId, this.startDate, this.endDate, this.endTime, this.endDate, this.contactId, 
        this.rentalId, this.licenseNumber,this.paymentMethod);

        const paymentDetails = JSON.stringify(this.getPaymentDetails());
        console.log(paymentDetails);
        submitPaymentForApproval({
            contactId: this.contactId,
            carId: this.carId,
            rentalId: this.rentalId,
            startDate: this.startDate,
            endDate: this.endDate,
            licenseNumber: this.licenseNumber,
            paymentMethod: this.paymentMethod,
            rentalType: this.rentalType,
            paymentDetails: paymentDetails
        })
        .then(result => {
                this.showToast('Success', 'Payment submitted for approval', 'success');
                this.resetFunction();

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