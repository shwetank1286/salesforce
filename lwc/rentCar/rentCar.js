import { LightningElement, track, wire } from 'lwc';
import rent from '@salesforce/apex/RentCarController.rent';
import getValidCars from '@salesforce/apex/RentCarHelper.getValidCars';
import getStates from '@salesforce/apex/RentCarController.getStates';
import getCities from '@salesforce/apex/RentCarController.getCities';


export default class RentCar extends LightningElement {
    @track startTime;
    @track endTime;
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
    @track customerId='003NS00000RaVH3YAN';
    @track rentalBook = false;
    

    @track rentalTypeOptions = [
        { label: 'Hourly', value: 'Hourly' },
        { label: 'Daily', value: 'Daily' }
    ];

    // Fetch available states
    @wire(getStates)
    wireStates({ error, data }) {
        if (data) {
            this.stateOptions = data.map(state => ({ label: state, value: state }));
        } else if (error) {
            this.message = 'Error loading states';
        }
    }

    handleRentalTypeChange(event) {
        this.rentalType = event.target.value;
        this.carOptions = []; // Reset car options when rental type changes
        this.message = '';
    }

    handleStateChange(event) {
        this.selectedState = event.target.value;
        this.selectedCity = null; // Reset city selection
        this.carOptions = []; // Clear car list when state changes

        getCities({ selectedState: this.selectedState })
            .then(data => {
                this.cityOptions = data.map(city => ({ label: city, value: city }));
            })
            .catch(() => {
                this.cityOptions = [];
                this.message = 'Error loading cities';
            });
    }

    handleCityChange(event) {
        this.selectedCity = event.target.value;
        this.fetchAvailableCars();
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
        this.fetchAvailableCars();
    }
    //handling the end date 
    handleEndDateChange(event) {
        this.endDate = event.target.value;
        this.fetchAvailableCars();
    }
    //handling the time
    handleTimeChange(event) {
        this.startTime = event.target.value;
        this.calculateEndTime();
        this.fetchAvailableCars();
    }
    //handling hours
    handleNumberOfHoursChange(event) {
        this.numberOfHours = event.target.value;
        this.calculateEndTime();
        this.fetchAvailableCars();
    }

    

handleLicenseChange(event) {
    this.licenseNumber = event.target.value.trim(); 

    if (!this.licenseNumber) {
        this.message = 'License number is required.';
        return;
    }

    if (!this.validateLicenseNumber(this.licenseNumber)) {
        return;
    }

    // requireLicense({ licenseNumber: this.licenseNumber }) 
    //     .then(isRequired => {
    //         if (!isRequired) {
    //             this.message = 'License number is already stored!';
    //         } else {
    //             this.message = ''; 
    //         }
    //     })
    //     .catch(error => {
    //         console.error('Error checking license number:', error);
    //         this.message = 'Error validating license number.';
    //     });

    // console.log('License Number Entered:', this.licenseNumber);
}

validateLicenseNumber(licenseNumber) {
    const licenseRegex = /^[A-Za-z0-9]{6,15}$/; // 6-15 alphanumeric characters
    if (!licenseRegex.test(licenseNumber)) {
        this.message = 'Please enter a valid license number (6-15 alphanumeric characters).';
        return false;
    }
    this.message = ''; // Clear error if valid
    return true;
}


    
    
    calculateEndTime() {
        if (!this.startTime || !this.numberOfHours) {
            this.endTime = null;
            return;
        }

        let [time, period] = this.startTime.split(' '); // Extract time and AM/PM
        let [hours, minutes] = time.split(':').map(Number); // Extract hours and minutes

        // Convert to 24-hour format
        if (period === 'PM' && hours !== 12) {
            hours += 12;
        } else if (period === 'AM' && hours === 12) {
            hours = 0;
        }

        // Add the given hours
        let totalMinutes = hours * 60 + minutes + Number(this.numberOfHours) * 60;

        // Calculate the new date if totalMinutes exceed 24 hours
        let daysToAdd = Math.floor(totalMinutes / (24 * 60));
        totalMinutes = totalMinutes % (24 * 60);

        // Convert back to 12-hour format
        let newHours = Math.floor(totalMinutes / 60);
        let newMinutes = totalMinutes % 60;

        let newPeriod = newHours >= 12 ? 'PM' : 'AM';
        newHours = newHours % 12 || 12; // Convert 0 to 12

        this.endTime = `${newHours}:${newMinutes.toString().padStart(2, '0')} ${newPeriod}`;
        console.log(`Calculated End Time: ${this.endTime}`);

        if (daysToAdd > 0) {
            let endDate = new Date(this.startDate);
            endDate.setDate(endDate.getDate() + daysToAdd);
            this.endDate = endDate.toISOString().split('T')[0];
            console.log(`Adjusted End Date: ${this.endDate}`);
        } else {
            this.endDate = this.startDate;
        }
    }

    fetchAvailableCars() {
    
        if (this.rentalType === 'Hourly') {
            if (!this.selectedState || !this.selectedCity || !this.numberOfHours || this.numberOfHours <= 0) {
                this.carOptions = [];
                return;
            }
        }

        if (this.rentalType === 'Daily') {
            if (!this.selectedState || !this.selectedCity || !this.startDate || !this.endDate) {
                this.carOptions = [];
                return;
            }
        }

        getValidCars({ 
            startDate: this.startDate, 
            endDate: this.endDate, 
            state: this.selectedState, 
            city: this.selectedCity
        })
        .then(data => {
            this.carOptions = data.map(car => ({ label: car.Name, value: car.Id }));
        })
        .catch(error => {
            this.carOptions = [];
            this.message = 'Error loading cars';
        });
    }

    handleCarChange(event) {
        this.selectedCarId = event.target.value;
    }

    handleBookCar() {
        if (this.rentalType === 'Hourly' && (!this.selectedCarId || !this.numberOfHours)) {
            this.message = 'Please select a car and enter the number of hours.';
            return;
        }

        if (this.rentalType === 'Daily' && (!this.selectedCarId || !this.startDate || !this.endDate)) {
            this.message = 'Please select a car and enter valid dates.';
            return;
        }

        this.rentalBook = !this.rentalBook;
        
        rent({

            carId: this.selectedCarId,
            startDate: this.startDate,
            endDate: this.endDate,
            licenseNumber: this.licenseNumber 
        })
        .then(result => {
           this.rentalId = result;
            this.message = 'Rental was successful. The Id is: ' + this.rentalId;
            console.log('cid'+ this.customerId);
        console.log('carid'+ this.selectedCarId);
            
        })
        .catch(() => {
            this.message = 'Error: booking failed';
            

        });
    }
     
    get isHourly() {
        return this.rentalType === 'Hourly';
    }
 
    get isDaily() {
        return this.rentalType === 'Daily';
    }
}