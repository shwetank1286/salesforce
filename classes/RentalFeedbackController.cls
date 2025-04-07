public with sharing class RentalFeedbackController {
    @AuraEnabled(cacheable=true)
    public static List<Rental__c> getUserRentals() {
        try {
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
            if (currentUser.ContactId == null) {
                return new List<Rental__c>();
            }
            Id contactId = currentUser.ContactId;

            List<Rental__c> rentals = [
                SELECT Id, Name, Car_Name__c, Start_Date__c, End_Date__c, 
                       Rental_Status__c, Contact_Relation__c
                FROM Rental__c 
                WHERE Contact_Relation__c = :contactId
                AND Rental_Status__c = 'Completed'
                ORDER BY End_Date__c DESC
                LIMIT 50
            ];
            return rentals;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching rentals: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void submitBookingSupport(String rentalId, String supportType, String comments, String rating) {
        try {
            System.debug('Starting submitBookingSupport with rentalId: ' + rentalId + ', supportType: ' + supportType + ', comments: ' + comments + ', rating: ' + rating);

            // Validate required fields
            if (String.isBlank(rentalId) || String.isBlank(supportType)) {
                throw new AuraHandledException('Rental ID and Support Type are required.');
            }
            System.debug('Input validation passed');

            // Check for existing Feedback or Query for this rental
            System.debug('Querying existing Booking_Support__c for rentalId: ' + rentalId + ' and supportType: ' + supportType);
            List<Booking_Support__c> existingSupports = [
                SELECT Id, Support_Type__c 
                FROM Booking_Support__c 
                WHERE Rented_Car__c = :rentalId 
                AND Support_Type__c = :supportType 
                LIMIT 1
            ];
            System.debug('Found ' + existingSupports.size() + ' existing supports');
            if (!existingSupports.isEmpty()) {
                throw new AuraHandledException(
                    'You have already submitted a ' + 
                    (supportType == 'Feedback' ? 'feedback' : 'query') + 
                    ' for this rental.'
                );
            }

            // Create Booking_Support__c record
            System.debug('Creating Booking_Support__c record');
            Booking_Support__c support = new Booking_Support__c(
                Rented_Car__c = rentalId,
                Support_Type__c = supportType,
                Comments__c = comments,
                Rating__c = supportType == 'Feedback' && String.isNotBlank(rating) ? rating : null
            );
            insert support;
            System.debug('Booking_Support__c record inserted with Id: ' + support.Id);

            // Get current user's email
            System.debug('Querying current user');
            User currentUser = [SELECT Email, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            String userEmail = currentUser.Email;
            String userName = currentUser.Name;
            System.debug('User email: ' + userEmail + ', name: ' + userName);

            // Get rental name safely
            System.debug('Querying Rental__c for rentalId: ' + rentalId);
            String rentalName = 'Unknown Rental';
            List<Rental__c> rentals = [SELECT Name FROM Rental__c WHERE Id = :rentalId LIMIT 1];
            if (!rentals.isEmpty()) {
                rentalName = rentals[0].Name;
            }
            System.debug('Rental name: ' + rentalName);

            // Send email to the user
            System.debug('Preparing email');
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { userEmail });
            email.setSubject(supportType == 'Query' ? 'Your Query Has Been Submitted' : 'Your Feedback Has Been Submitted');
            email.setPlainTextBody(
                'Dear ' + userName + ',\n\n' +
                (supportType == 'Query' ? 
                    'Your query has been successfully submitted:\n' : 
                    'Your feedback has been successfully submitted:\n') +
                'Rental: ' + rentalName + '\n' +
                'Comments: ' + (comments != null ? comments : 'N/A') + '\n' +
                (supportType == 'Feedback' ? 'Rating: ' + rating + '/5\n' : '') +
                '\nThank you,\nCar Rental Team'
            );
            System.debug('Sending email');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            System.debug('Email sent successfully');

        } catch (Exception e) {
            System.debug('Error submitting ' + (supportType == 'Feedback' ? 'feedback' : 'query') + ': ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
            throw new AuraHandledException(
                'Error submitting ' + 
                (supportType == 'Feedback' ? 'feedback' : 'query') + 
                ': ' + e.getMessage()
            );
        }
    }
}