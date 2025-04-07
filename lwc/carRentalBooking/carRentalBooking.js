import { LightningElement, track, wire } from 'lwc';
import createBooking from '@salesforce/apex/CarBookingController.createBooking';
import fetchAvailableCars from '@salesforce/apex/CarAvailabilityHelper.fetchAvailableCars';
import fetchStates from '@salesforce/apex/CarBookingController.fetchStates';
import fetchCities from '@salesforce/apex/CarBookingController.fetchCities';

export default class CarRentalBooking extends LightningElement {
    @track pickUpTime;
    @track dropTime;
    @track selectedState;
    @track rentalType;
    @track selectedCity;
    @track cityOptions = [];
    @track stateOptions = [];
    @track carOptions = [];
    @track selectedCarId;
    @track startDate;
    @track endDate;
    @track numberOfHours;
    @track licenseNumber = '';
    @track message;
    @track rentalId;
    @track customerId = '003NS00000RaVH3YAN'; // Consider fetching dynamically if possible
    @track showPaymentForm = false;

    @track rentalTypeOptions = [
        { label: 'Hourly', value: 'Hourly' },
        { label: 'Daily', value: 'Daily' }
    ];

    // Generate time options from 9:30 to 20:30 with 30-minute intervals
    get timeOptions() {
        const options = [];
        for (let hour = 9; hour <= 20; hour++) {
            options.push({ label: `${hour.toString().padStart(2, '0')}:00`, value: `${hour.toString().padStart(2, '0')}:00` });
            if (hour < 20 || (hour === 20 && options.length === 1)) {
                options.push({ label: `${hour.toString().padStart(2, '0')}:30`, value: `${hour.toString().padStart(2, '0')}:30` });
            }
        }
        return options;
    }

    @wire(fetchStates)
    wiredStates({ error, data }) {
        if (data) {
            this.stateOptions = data.map(state => ({ label: state, value: state }));
        } else if (error) {
            this.showError('Error loading states');
        }
    }

    updateRentalType(event) {
        this.rentalType = event.target.value;
        this.resetCarSelection();
    }

    updateState(event) {
        this.selectedState = event.target.value;
        this.selectedCity = null;
        this.carOptions = [];
        fetchCities({ selectedState: this.selectedState })
            .then(data => {
                this.cityOptions = data.map(city => ({ label: city, value: city }));
            })
            .catch(() => {
                this.cityOptions = [];
                this.showError('Error loading cities');
            });
    }

    updateCity(event) {
        this.selectedCity = event.target.value;
        this.loadAvailableCars();
    }

    updateStartDate(event) {
        this.startDate = event.target.value;
        this.loadAvailableCars();
    }

    updateEndDate(event) {
        this.endDate = event.target.value;
        this.loadAvailableCars();
    }

    updatePickUpTime(event) {
        this.pickUpTime = event.target.value;
        this.calculateDropTime();
        this.loadAvailableCars();
    }

    updateHours(event) {
        this.numberOfHours = parseInt(event.target.value, 10);
        this.calculateDropTime();
        this.loadAvailableCars();
    }

    updateLicenseNumber(event) {
        this.licenseNumber = event.target.value.trim();
        if (!this.checkLicenseNumber()) {
            return;
        }
        this.message = '';
    }

    checkLicenseNumber() {
        if (!this.licenseNumber) {
            this.showError('License number is required.');
            return false;
        }
        const licenseRegex = /^[A-Za-z0-9]{6,15}$/;
        if (!licenseRegex.test(this.licenseNumber)) {
            this.showError('Please enter a valid license number (6-15 alphanumeric characters).');
            return false;
        }
        return true;
    }

    calculateDropTime() {
        if (!this.pickUpTime || !this.numberOfHours || !this.startDate) {
            this.dropTime = null;
            return;
        }
        const [hours, minutes] = this.pickUpTime.split(':').map(Number);
        let totalMinutes = hours * 60 + minutes + this.numberOfHours * 60;
        const daysToAdd = Math.floor(totalMinutes / (24 * 60));
        totalMinutes %= (24 * 60);
        const newHours = Math.floor(totalMinutes / 60);
        const newMinutes = totalMinutes % 60;
        this.dropTime = `${newHours.toString().padStart(2, '0')}:${newMinutes.toString().padStart(2, '0')}`;
        this.endDate = daysToAdd > 0 
            ? new Date(new Date(this.startDate).setDate(new Date(this.startDate).getDate() + daysToAdd)).toISOString().split('T')[0]
            : this.startDate;
    }

    loadAvailableCars() {
        const isHourlyValid = this.rentalType === 'Hourly' && this.selectedState && this.selectedCity && this.numberOfHours > 0 && this.startDate && this.pickUpTime;
        const isDailyValid = this.rentalType === 'Daily' && this.selectedState && this.selectedCity && this.startDate && this.endDate;
        if (!isHourlyValid && !isDailyValid) {
            this.carOptions = [];
            return;
        }
        fetchAvailableCars({ 
            startDate: this.startDate, 
            endDate: this.endDate, 
            state: this.selectedState, 
            city: this.selectedCity,
            numberOfHours: this.numberOfHours,
            pickUpTime: this.pickUpTime,
            dropTime: this.dropTime
        })
        .then(data => {
            this.carOptions = data.map(car => ({ label: car.Name, value: car.Id }));
        })
        .catch(error => {
            this.carOptions = [];
            this.showError('Error loading cars: ' + error.body.message);
        });
    }

    updateCarSelection(event) {
        this.selectedCarId = event.target.value;
    }

    processBooking() {
        if (!this.selectedCarId || !this.checkLicenseNumber()) {
            this.showError('Please select a car and enter a valid license number.');
            return;
        }
        createBooking({
            carId: this.selectedCarId,
            startDate: this.startDate,
            endDate: this.endDate,
            pickUpTime: this.pickUpTime,
            dropTime: this.dropTime,
            licenseNumber: this.licenseNumber,
            rentalType: this.rentalType
        })
        .then(result => {
            if (result.startsWith('Error')) {
                this.showError(result);
            } else {
                this.rentalId = result;
                this.message = 'Rental booked successfully. Proceed to payment.';
                this.showPaymentForm = true;
            }
        })
        .catch(error => {
            this.showError('Error: Booking failed - ' + error.body.message);
        });
    }

    handlePaymentSuccess() {
        this.showPaymentForm = false;
        this.message = 'Payment completed successfully!';
        this.clearForm();
    }

    clearForm() {
        this.rentalType = null;
        this.selectedState = null;
        this.selectedCity = null;
        this.carOptions = [];
        this.selectedCarId = null;
        this.startDate = null;
        this.endDate = null;
        this.numberOfHours = null;
        this.pickUpTime = null;
        this.dropTime = null;
        this.licenseNumber = '';
        this.rentalId = null;
        this.message = '';
    }

    resetCarSelection() {
        this.carOptions = [];
        this.selectedCarId = null;
        this.message = '';
        this.showPaymentForm = false;
    }

    showError(msg) {
        this.message = msg;
    }

    get isHourly() {
        return this.rentalType === 'Hourly';
    }

    get isDaily() {
        return this.rentalType === 'Daily';
    }
}