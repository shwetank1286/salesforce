import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import VIDEO_URL from '@salesforce/resourceUrl/MyVideo';

export default class VideoWithButton extends NavigationMixin(LightningElement) {
    videoUrl = VIDEO_URL;

    handleRedirect() {
        // Navigate to the Book_a_Car__c page in the Car site
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Rent_Car__c'
            }
        });
    }
}