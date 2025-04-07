import { LightningElement, track } from 'lwc';

// Import Static Resources
import CAR1 from '@salesforce/resourceUrl/CAR1';
import CAR2 from '@salesforce/resourceUrl/CAR2';
import CAR3 from '@salesforce/resourceUrl/CAR3';
import CAR4 from '@salesforce/resourceUrl/CAR4';
import CAR5 from '@salesforce/resourceUrl/CAR5';

export default class CarSlideshow extends LightningElement {
  @track cars = [
    { id: 1, name: 'Tesla Model S', imageUrl: CAR1, slideClass: 'slide active' },
    { id: 2, name: 'Ford Mustang', imageUrl: CAR2, slideClass: 'slide' },
    { id: 3, name: 'BMW M3', imageUrl: CAR3, slideClass: 'slide' },
    { id: 4, name: 'Porsche 911', imageUrl: CAR4, slideClass: 'slide' },
    { id: 5, name: 'Audi R8', imageUrl: CAR5, slideClass: 'slide' }
  ];
  currentSlide = 0;
  autoPlayInterval = null;

  connectedCallback() {
    this.startAutoPlay();
  }

  disconnectedCallback() {
    this.stopAutoPlay();
  }

  startAutoPlay() {
    this.stopAutoPlay();
    this.autoPlayInterval = setInterval(() => {
      this.handleNext();
    }, 3000); // 3 seconds
  }

  stopAutoPlay() {
    if (this.autoPlayInterval) {
      clearInterval(this.autoPlayInterval);
    }
  }

  updateSlides() {
    this.cars = this.cars.map((car, index) => ({
      ...car,
      slideClass: index === this.currentSlide ? 'slide active' : 'slide'
    }));
  }

  handleNext() {
    this.currentSlide = (this.currentSlide + 1) % this.cars.length;
    this.updateSlides();
  }

  handlePrev() {
    this.currentSlide = (this.currentSlide - 1 + this.cars.length) % this.cars.length;
    this.updateSlides();
  }
}