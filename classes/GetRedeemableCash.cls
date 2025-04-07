public with sharing class GetRedeemableCash {
    @AuraEnabled(cacheable=true)
    public static Decimal getRedeemableCash() {
        Rental__c recentRental = [SELECT Contact_Relation__c 
                                 FROM Rental__c 
                                 WHERE CreatedById = :UserInfo.getUserId() 
                                 ORDER BY CreatedDate DESC 
                                 LIMIT 1];
        if (recentRental != null && recentRental.Contact_Relation__c != null) {
            Contact con = [SELECT Redeemable_Cash__c 
                          FROM Contact 
                          WHERE Id = :recentRental.Contact_Relation__c 
                          LIMIT 1];
            return con.Redeemable_Cash__c != null ? con.Redeemable_Cash__c : 0;
        }
        return 0;
    }
}