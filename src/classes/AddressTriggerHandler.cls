/**=================================================================================================================
 * Appirio, Inc
 * Name: AddressTriggerHandler
 * Description: Handles Address Trigger related handler methods
 * Created Date: Apr 1st, 2014
 * Created By: Naresh Kr Ojha (Appirio) for T-264687: To update ARIA's field = true
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 07th, 2014               Arpita Bose(Appirio)         T-269372: Added addError() in try-catch block
 * Apr 10th, 2014               Sadar Yacob (Experian)       Update Account Address if the Account is tied to an Aria BillingAccnt
 * May 1st, 2014                Arpita Bose                  Updated catch(Exception) to catch(DMLException) to use getDMLException Line#88 
 * Aug 22nd,2014                Sadar Yacob                  Include Postcode__c for list of fields that would trigger OBM to Aria ( SendBillingAccntToAria ) 
 * Oct 15th,2014                Pallavi Sharma               T-325153(Send to On-Demand: Address Trigger)
 ====================================================================================================================*/
public with sharing class AddressTriggerHandler {
    //=========================================================================
    //After Insert Call
    //=========================================================================
    public static void afterInsert (List<Address__c> newList) {
        QAS_NA.CAAddressCorrection.ExecuteCAAsyncForTriggerConfigurationsOnly(newList);
    }
    //=========================================================================
    //After Update Call
    //=========================================================================
    public static void afterUpdate (List<Address__c> newList, Map<ID, Address__c> oldMap) {
        QAS_NA.CAAddressCorrection.ExecuteCAAsyncForTriggerConfigurationsOnly(newList);
        setSendBillingAccntToAria(newList, oldMap);
        syncContactOnDemand(newList, oldMap);
    }
    
    //=========================================================================
    //T-264687: To update SendBillingAccntToAria when the Aria Billing account is updated
    //=========================================================================
    private static void setSendBillingAccntToAria (List<Address__c> newList, Map<ID, Address__c> oldMap) {
        Set<ID> billingAddressIDs = new Set<ID>();
        Set<ID> addressIDs = new Set<ID>();
         Set<ID> accntAddrIDs = new Set<ID>();
        Set<String> addressFieldNameSet = new Set<String>{'Address_1__c', 'Address_2__c', 'City__c', 'Country__c', 'State__c', 'Zip__c','Postcode__c'};
        Map<ID, ARIA_Billing_Account__c> ARIABillingAccountMap = new Map<ID, ARIA_Billing_Account__c>();
        Map<ID, Account_Address__c> AccountAddressMap = new Map<ID, Account_Address__c>();

        try 
        {
            //checking fields has been updated
            for (Address__c address : newList) {
                if (isChangedAnyField(addressFieldNameSet, address, oldMap.get(address.ID))) {
                    addressIDs.add(address.ID);
                }
            }

            //--Start of code added by Sadar 04/10/14  
            // Need to do an update on the Accnt Address if the Registered Address was modified
            List <Account_Address__c> acctAddress = [SELECT Address__c, Id,Address_Type__c,Boomi__c FROM Account_Address__c
                                                     WHERE Address__c IN :addressIDs AND Address_Type__c ='Registered'];
            // accntAddrIDs.add(acctAddress.Id);
            
            for (Account_Address__c acctAddr : acctAddress ) 
            {
                    acctAddr.Boomi__c = acctAddr.ID ; //Update
                    AccountAddressMap.put(acctAddr.ID, acctAddr);
            }
            //--> Till here code added by Sadar
            
            //Fetching related Aria billing accounts
            for (Account_Address__c accAddress : [SELECT Address__c, Id, 
                                                                  (SELECT Id, Push_To_Aria__c, SendBillingAccntToAria__c 
                                                                  FROM ARIA_Billing_Accounts__r 
                                                                  WHERE Push_To_Aria__c =: Constants.PICKLISTVAL_YES) 
                                                                  FROM Account_Address__c
                                                                  WHERE Address__c IN :addressIDs]) 
            {
                for (ARIA_Billing_Account__c ARIABillAcc : accAddress.ARIA_Billing_Accounts__r) 
                {
                    ARIABillAcc.SendBillingAccntToAria__c = true;
                    ARIABillingAccountMap.put(ARIABillAcc.ID, ARIABillAcc);
                }
            }
            //Updating Aria Billing Accounts
            if (ARIABillingAccountMap.values().size() > 0) 
            {
                update ARIABillingAccountMap.values();
            }
            
            //Updating Account Addresses
            if (AccountAddressMap.values().size() > 0) 
            {
                update AccountAddressMap.values();
            }
            
            
    } catch(DMLException e){
        System.debug('\n[AddressTriggerHandler: setSendBillingAccntToAria]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AddressTriggerHandler','setSendBillingAccntToAria', e.getStackTraceString(), e);
        for (Integer i=0; i < e.getNumDml(); i++) {
          newList.get(0).addError(e.getDMLMessage(i));
        }  
    }
    }
    
    
    //=========================================================================
    // To check weather set of fields has the field change in the new record.
    //=========================================================================
  private static Boolean isChangedAnyField (Set<String> fieldNameSet,  
                                                                Address__c newRecord, Address__c oldRecord) {
    for (String fieldName : fieldNameSet) {
        if (newRecord.get(fieldName) != oldRecord.get(fieldName)) {
            return true;
        }
    }
    return false;
  }
  
  //===========================================================================
  //T-325153: Method to set Contact on Demand on the updation of Address
  //===========================================================================
  private static void syncContactOnDemand(List<Address__c> newList, Map<ID, Address__c> oldMap) {
    set<Id> setAddressIds = new set<Id>();
    //Get Address Id of of updated addresses 
    for (Address__c addr : newList) {
      if (addr.Address_1__c  != oldMap.get(addr.Id).Address_1__c ||
          addr.Address_2__c != oldMap.get(addr.Id).Address_2__c ||
          addr.City__c      != oldMap.get(addr.Id).City__c      ||
          addr.State__c     != oldMap.get(addr.Id).State__c     ||
          addr.Country__c   != oldMap.get(addr.Id).Country__c   ||
          addr.Postcode__c  != oldMap.get(addr.Id).Postcode__c  ||
          addr.County__c    != oldMap.get(addr.Id).County__c){
          setAddressIds.add(addr.Id);  
      }
    }
    if (setAddressIds.isEmpty()) {
      return;
    }

    set<Id> setAccountIds = new set<Id>();
    //Get related Account Addresses
    for (Account_Address__c accountAddress : [ SELECT Account__c 
                                              FROM Account_Address__c
                                              WHERE Address__c IN : setAddressIds]) {
      setAccountIds.add(accountAddress.Account__c);
    }
    if (setAccountIds.isEmpty()) {
      return;
    }

    //Get related contact addresses
    List<Contact> lstContactToUpdate = new List<Contact>();
    for(Contact contact : [ SELECT Id , EDQ_Send_to_On_Demand__c
                            FROM Contact
                            WHERE AccountId =: setAccountIds
                            AND EDQ_On_Demand__c = true]){
      if (!contact.EDQ_Send_to_On_Demand__c) {
        contact.EDQ_Send_to_On_Demand__c = true;
        lstContactToUpdate.add(contact);
      }
    }
    

    //Update Contact
    if (!lstContactToUpdate.isEmpty()) {
      try {
        update lstContactToUpdate;
      } catch(DMLException ex) {
        //Save log for exception
        apexLogHandler.createLogAndSave('AddressTriggerHandler','syncContactOnDemand', ex.getStackTraceString(), ex);
        //Adding error to record
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newList.get(0).addError(ex.getDmlMessage(i)); 
        }
      }
    }
  }
}