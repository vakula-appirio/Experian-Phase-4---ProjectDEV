/**************************************************************************************
 This triggerHandler called from AriaBillingAccntTrigger is used to
 update the Used_on_Aria_Billing_Account__c  on the Address object
 when an Address is used on a Aria Billing Account.
 
 Created Date: March 3th, 2013
 Created By: Sadar Yacob( Experian)
  
 Date Modified                Modified By                  Description of the update
 Mar 31st, 2014                Naresh kr Ojha (Appirio)     T-264687:  update SendBillingAccntToAria when the Aria Billing account is updated
 Apr 07th, 2014               Arpita Bose(Appirio)         T-269372: Added addError()in place of try-catch block
 May 01st, 2014               Arpita Bose                  Updated catch(Exception) to catch(DMLException)
 Aug 05th, 2014               Arpita Bose                  T-286337: Refactoring of ARIA classes
 Aug 27th, 2014               Sadar Yacob                  Added 'Postcode__c' in Address__c query in SetAccntAddress()
**************************************************************************************/

public without sharing class BillingAccntTriggerHandler {

  //==========================================================================
  // Before Insert call
  //==========================================================================
  public static void beforeInsert (Map<ID, ARIA_Billing_Account__c> newMap) {
  
  }
    
  //==========================================================================
  // Before Update call
  //==========================================================================
  public static void beforeUpdate (Map<ID, ARIA_Billing_Account__c> newMap, 
                                   Map<ID, ARIA_Billing_Account__c> oldMap) {
    //T-264687:  update SendBillingAccntToAria when the Aria Billing account is updated
    setSendBillingAccntToAria(newMap, oldMap);
  }

  //==========================================================================
  // After Insert call
  //==========================================================================
  public static void afterInsert (Map<ID, ARIA_Billing_Account__c> newMap) {
    // Set the Account address fields based on the Account tied to the Billing account
    SetAccntAddress(newMap);
  }

  //==========================================================================
  // After Update call
  //==========================================================================
  public static void afterUpdate (Map<ID, ARIA_Billing_Account__c> newMap, 
                                  Map<ID, ARIA_Billing_Account__c> oldMap) {
    // Set the Account address fields based on the Account tied to the Billing account
    SetAccntAddress(newMap);
  }
  
  //==========================================================================
  // T-264687: Update SendBillingAccntToAria when the Aria Billing account is updated
  //==========================================================================
  private static void setSendBillingAccntToAria (Map<ID, ARIA_Billing_Account__c> newMap, 
                                                 Map<ID, ARIA_Billing_Account__c> oldMap) {
    Boolean fieldUpdated;
    System.debug('[AriaBillingAccntTrigger:beforeUpdate][newMap.values()]'+newMap.values());
    try {
      for (ARIA_Billing_Account__c ariaBillAcc : newMap.values()) {
        fieldUpdated = false;
        fieldUpdated  = (isFieldUpdated('Billing_Contact_Email__c', ariaBillAcc, oldMap.get(ariaBillAcc.ID))) ? true : false;
        if (!fieldUpdated) {
          fieldUpdated  = (isFieldUpdated('Billing_Contact_First_Name__c', ariaBillAcc, oldMap.get(ariaBillAcc.ID))) ? true : false; 
        }
         if (!fieldUpdated) {
           fieldUpdated  = (isFieldUpdated('Billing_Contact_Last_Name__c', ariaBillAcc, oldMap.get(ariaBillAcc.ID)))  ? true : false;
         }
         if (!fieldUpdated) {
           fieldUpdated  = (isFieldUpdated('Billing_Contact_Mobile_Phone__c', ariaBillAcc, oldMap.get(ariaBillAcc.ID)))  ? true : false;
         }
         if (!fieldUpdated) {
           fieldUpdated  = (isFieldUpdated('Billing_Contact_Work_Phone__c', ariaBillAcc, oldMap.get(ariaBillAcc.ID)))  ? true : false;
         }
         
         //Setting field true if above fields get updated.
         if (fieldUpdated && ariaBillAcc.Push_To_Aria__c == Constants.PICKLISTVAL_YES) {
           ariaBillAcc.SendBillingAccntToAria__c = true;
         }
        System.debug('[AriaBillingAccntTrigger:beforeUpdate][****ariaBillAcc.SendBillingAccntToAria__c***]'+ariaBillAcc.SendBillingAccntToAria__c);
      }
    } catch(Exception e){
      System.debug('\n[BillingAccntTriggerHandler: setSendBillingAccntToAria]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('BillingAccntTriggerHandler','setSendBillingAccntToAria', e.getStackTraceString(), e);
      newMap.values().get(0).addError(e.getMessage());
    }

    System.debug('[AriaBillingAccntTrigger:beforeUpdate][****Finishing before Update call***]'+newMap);
  }
  
  //==========================================================================
  // Method to returns true if field has updated value in new record.
  //==========================================================================
  private static Boolean isFieldUpdated (String fieldName, ARIA_Billing_Account__c newRec, 
                                         ARIA_Billing_Account__c oldRec) {
    if (newRec.get(fieldName) != oldRec.get(fieldName)) {
      return true;
    }
    return false;
  }
  
  //=========================================================================
  // Method for set Accnt Address on Billing Account
  //=========================================================================
  public static void SetAccntAddress(Map<Id, ARIA_Billing_Account__c> newMap) {
    Set<Id> BillAccntIds = new Set<Id>();
    for (ARIA_Billing_Account__c  newBillAccnts: newMap.values()) {    
      BillAccntIds.add(newBillAccnts.Id);
    }
    
    List <ARIA_Billing_Account__c> UpdateAddrOnBillAccntList= new List  <ARIA_Billing_Account__c>();
    List <Address__c>   UpdateAddressforUseList = new List <Address__c>();
    Set <Id> AccntAddrIds = new Set<Id>();
    Set<Id> AccntIds= new Set<Id>();

    //Get the List of Billing Accounts that are in the trigger.new and get the Account Address for each
    for (ARIA_Billing_Account__c nBillAccnts : [Select Id, Account__c,Billing_Address__c 
                                               from ARIA_Billing_Account__c 
                                               where Id IN :BillAccntIds]) {
      AccntIds.add(nBillAccnts.Account__c);
      UpdateAddrOnBillAccntList.add(nBillAccnts);
      AccntAddrIds.add(nBillAccnts.Billing_Address__c ); //Account Address Ids 
    }

    Set <Id> AddrIds = new Set<Id>();

    //fetch the Address Ids from the Account Address object
    for (Account_Address__c lAccntAddrs : [Select Account__c, Address_Type__c, Name, Id, Address__c 
                                          from Account_Address__c 
                                          where Account__c IN :AccntIds AND ID IN :AccntAddrIds]) {  
      AddrIds.add(lAccntAddrs.Address__c);
    }

    for (Address__c lAddrUpdate : [Select Name, Id, Address_1__c, Address_2__c, Address_3__c, City__c,
                                         State__c, Zip__c, Used_on_Aria_Billing_Account__c, Postcode__c 
                                  FROM Address__c 
                                  WHERE Id IN :AddrIds]) {
      
      //Update the Used_on_Aria_Billing_Account__c flag to true
      lAddrUpdate.Used_on_Aria_Billing_Account__c = true;
      UpdateAddressforUseList.add(lAddrUpdate);
    }
    
    try {
      if (!UpdateAddressforUseList.isEmpty()) {
        update UpdateAddressforUseList; 
      }
    } catch ( DMLException e) {
     System.debug('The following exception has occurred while updating the Address object for Used_on_Aria_Billing_Account__c: ' + e.getMessage());
     for (Integer i=0; i < e.getNumDml(); i++) {
       UpdateAddressforUseList[0].addError(e.getDMLMessage(i));
     }
    }
  }
}