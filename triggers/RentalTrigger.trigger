trigger RentalTrigger on Rental__c (after insert) {
    Map<Id, Decimal> contactCashMap = new Map<Id, Decimal>();

    for (Rental__c rental : Trigger.new) {
        if (rental.Contact_Relation__c != null) {
            Decimal cashToAdd = Math.floor(Math.random() * 25) + 1;
            if (contactCashMap.containsKey(rental.Contact_Relation__c)) {
                contactCashMap.put(rental.Contact_Relation__c, 
                    contactCashMap.get(rental.Contact_Relation__c) + cashToAdd);
            } else {
                contactCashMap.put(rental.Contact_Relation__c, cashToAdd);
            }
        }
    }

    if (!contactCashMap.isEmpty()) {
        List<Contact> contactsToUpdate = [SELECT Id, Redeemable_Cash__c 
                                         FROM Contact 
                                         WHERE Id IN :contactCashMap.keySet()];

        for (Contact con : contactsToUpdate) {
            Decimal existingCash = con.Redeemable_Cash__c != null ? con.Redeemable_Cash__c : 0;
            con.Redeemable_Cash__c = existingCash + contactCashMap.get(con.Id);
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }
    }
}