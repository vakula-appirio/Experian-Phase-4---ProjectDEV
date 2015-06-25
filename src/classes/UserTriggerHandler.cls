/**=====================================================================
 * Appirio, Inc
 * Name: UserTriggerHandler
 * Description: T-264687: To update ARIABillingAccount
 * Created Date: Apr 2nd, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 9th, 2014                Arpita Bose(Appirio)         T-269989: Added method validateCurrencyFieldsOnUser() to
 *                                                           keep User's standard and custom Currency field in sync.
 * Aug 30th, 2014               Richard Joseph               Modified to created CPQ user and Update the CPQ User.
 *                                                           Call SFDCToCPQUserServiceClass.
 * Oct 06th, 2014               Naresh kr Ojha               T-322915: User validation for EDQ user to populate Office location,
 *                                                           added method validateEDQUserFields()
 * Oct 07th, 2014               Naresh Kr Ojha               Removed soql from validateEDQUserFields method.
 
 * Feb 2nd, 2015                Tyaga Pati                   Added Code to make track Loggined In User and Date when Activation and Deactivation occur.
 * Mar 27th, 2015               Arpita Bose                  T-373930: Added method recalculateSegmentFieldValues() and isChangedAnyField()
 * Apr 01st, 2015               Arpita Bose                  T-373930: Updated method recalculateSegmentFieldValues() to call AccountSegmentationUtility.updateOpportunitySegments()
 * Apr 08th, 2015               Arpita Bose                  T-373930: Added method createAccSegmentForNewAccount_User()
 * April 10th 2015              Richard Joseph               Added validation to skip null/empty CPQ User Type during deactivation of user.
 * April 10th 2015              Richard Joseph               Added condition to verify if Bill Plan field is changed or not.
 * April 28th, 2015             James Weatherall             Case #528796 Created two new methods createExperianContact(), updateExperianContactManager()
 *                                                           to create Contacts on the Experian BU Account and to update the Manager when changed on the User
 =====================================================================*/
public with sharing class UserTriggerHandler {
  
  //===========================================================================
  //After update
  //===========================================================================
  public static void afterUpdate(List<User> newList, Map<ID, User> oldMap) {
    updateARIABillingAccounts(newList, oldMap);
    //[RJ]Changes by Richard Starts
    if (newList.size() == 1) { //Size is 1 since CPQ webservice can't handle bulk updates
      cpqUserUpdate(newList, oldMap); 
    }
    updateExperianContactManager(newList, oldMap); // JW #528796
    createAccSegmentForNewAccount_User(newList, oldMap);
    // T-373930
    recalculateSegmentFieldValues(newList, oldMap);

  }
  
  //===========================================================================
  //Before Insert
  //===========================================================================
  public static void beforeInsert(List<User> newList){
    validateEDQUserFields(newList, null);
  }
  
  //===========================================================================
  //After Insert
  //===========================================================================
  public static void afterInsert(List<User> newList){
    validateCurrencyFieldsOnUser(newList);
    //[RJ]Changes by Richard Starts
    if (newList.size() == 1) {//Size is 1 since CPQ webservice can't handle bulk updates
      cpqUserCreate(newList);
    }
    // Case #528796 : James Weatherall 28th April, 2015
    // Commented out until logic is clear and Phase 3 release is complete
    // createExperianContact(newList);
  }
  
  //===========================================================================
  //Before Update
  //===========================================================================
  public static void beforeUpdate(Map<ID, User> newMap, Map<ID, User> oldMap){
    validateCurrencyFieldsOnUser(newMap, oldMap);
    validateEDQUserFields(newMap.values(), oldMap);
    
    updtUsrActivtDeactivtInfo(newMap.Values(), oldMap); // TP Feb 2nd, 2015
  }


  //[RJ]Changes by Richard
  //===========================================================================
  //To Create user record in CPQ
  //===========================================================================
  private static void cpqUserCreate(List<User> newList) {
    for (User userRec : newList) {
      if ( userRec.CPQ_User__c && userRec.CPQ_User_Type__c !=null && userRec.isActive ) {
        SFDCToCPQUserServiceClass.callCPQUserAdminSerivceAsync(userRec.Id);
      }
    }
  }

//=====================Tyaga Pati==================================================
//This Function will update the User Record with Details of the User Name 
//and Time when perticular user is being Activated or Deactivated.
//=======================================================================
  private static void updtUsrActivtDeactivtInfo(List<User> newList, Map<ID, User> oldMap)
    {
    List<User> newActvtdUsr= new List<User>();
    for (User usr:newList) {
      if (oldMap != null && oldMap.get(Usr.Id).IsActive == Usr.IsActive) {
        continue;
      }
      else {
        newActvtdUsr.add(usr);
            }
    }
    
    if (newActvtdUsr.size() > 0) {
      for (User usrNew: newActvtdUsr) {
        if (usrNew.IsActive) {
          usrNew.Date_Reactivated__c = date.today();
          usrNew.Reactivate_by__c = UserInfo.getUserId();
                    }
        else if (!usrNew.IsActive) {
          usrNew.Date_Deactivated__c= date.today();
          usrNew.Deactivated_by__c = UserInfo.getUserId();
                    }   
    
            }

        }
        
    } 
// End Of Function to Update User Record during Activation and DeActivation 

  //===========================================================================
  //To update user record in CPQ
  //===========================================================================
  private static void cpqUserUpdate(List<User> newList, Map<ID, User> oldMap) {
    for (User userRec : newList) {
      if ( userRec.CPQ_User__c <> oldMap.get(userRec.ID).CPQ_User__c || 
              (userRec.CPQ_User__c && (
              userRec.CPQ_User_Type__c <> oldMap.get(userRec.ID).CPQ_User_Type__c ||
              userRec.isActive <> oldMap.get(userRec.ID).IsActive ||
              userRec.Country__c <> oldMap.get(userRec.ID).Country__c ||
              userRec.LastName <> oldMap.get(userRec.ID).LastName ||
              userRec.FirstName <> oldMap.get(userRec.ID).FirstName|| 
              userRec.email <> oldMap.get(userRec.ID).email ||
              userRec.Street<> oldMap.get(userRec.ID).Street ||
              userRec.city <> oldMap.get(userRec.ID).city ||
              userRec.state <> oldMap.get(userRec.ID).state ||
              userRec.phone <> oldMap.get(userRec.ID).phone ||
              userRec.Region__c <> oldMap.get(userRec.ID).Region__c ||
              userRec.CSDA_Bill_Plan_User__c <> oldMap.get(userRec.ID).CSDA_Bill_Plan_User__c || //  RJ - Added CSDA Bill Plan field.
              userRec.CSDA_Create_Quote_User__c <> oldMap.get(userRec.ID).CSDA_Create_Quote_User__c || //  RJ - Added CSDA Create Quote user field.
              userRec.PostalCode <> oldMap.get(userRec.ID).PostalCode))){
        SFDCToCPQUserServiceClass.callCPQUserAdminSerivceAsync(userRec.Id);
      }
    }
  }
  //[RJ]Changes ends  
  
  
  //===========================================================================
  //T-264687: To Update ARIA billingAccounts 
  //===========================================================================
  private static void updateARIABillingAccounts (List<User> newList, 
                                                        Map<ID, User> oldMap) {
    Set<ID> userIDs = new Set<ID>();
    Set<String> businessUnitSet = new Set<String>();
    Map<ID, ARIA_Billing_Account__c> ARIABillingAccountMap = new Map<ID, ARIA_Billing_Account__c>();
    
    //check weather User updated for Business_Unit__c
    for (User u : newList) {
      if (u.Business_Unit__c <> null && u.Business_Unit__c <> oldMap.get(u.ID).Business_Unit__c) {
        userIDs.add(u.ID);
      }
    }
    if (userIDs.size() > 0) {
      for (ARIA_Billing_Account__c billingAccount : [SELECT ID, Push_To_Aria__c, SendBillingAccntToAria__c 
                                                     FROM ARIA_Billing_Account__c 
                                                     WHERE Owner__c IN :userIDs 
                                                           AND Push_To_Aria__c =: Constants.PICKLISTVAL_YES]) {
        billingAccount.SendBillingAccntToAria__c = true;
        ARIABillingAccountMap.put(billingAccount.ID, billingAccount);
      }
      if (ARIABillingAccountMap.values().size() > 0) {
        update ARIABillingAccountMap.values();
      }

    }
  }
  //===========================================================================
  //T-269989: Validation to keep User's standard and custom Currency field in sync
  //===========================================================================
  private static void validateCurrencyFieldsOnUser(List<User> newList) {
    
    for(User u : newList) {
       if (String.isNotBlank(u.Currency__c) && !u.Currency__c.equalsIgnoreCase(u.DefaultCurrencyIsoCode.substringBefore('-'))) {
        u.addError(Label.USER_CURRENCY_FIELDS_MUST_MATCH); 
       }
    }
  }
  //===========================================================================
  //T-269989: Validation to keep User's standard and custom Currency field in sync
  //===========================================================================
  private static void validateCurrencyFieldsOnUser(Map<ID, User> newMap, Map<ID, User> oldMap) {
    
    for(User u : newMap.values()) {
       if (String.isNotBlank(u.Currency__c) && !u.Currency__c.equalsIgnoreCase(u.DefaultCurrencyIsoCode.substringBefore('-'))) {
        u.addError(Label.USER_CURRENCY_FIELDS_MUST_MATCH); 
       }
    }
    
  }
  
  //===========================================================================
  //T-322915: Validate users to have Office location if user is EDQ user
  //===========================================================================
  private static void validateEDQUserFields(List<User> newList, Map<Id, User> oldMap) {

    Map<String, String> bu_GroupMap = new Map<String, String>();
    Set<String> businessUnitSet = new Set<String>();
    Map<String, User> userMap = new Map<String, User>();

    //if (oldMap != null) {
    for (User u : newList) {
      if (u.Business_Unit__c != null) {
        businessUnitSet.add(u.Business_Unit__c);
      }
      if (oldMap != null) {
        userMap.put(u.ID, u);
      }
    }

    //If no business unit filled return
    if (businessUnitSet.size() < 1) {
      return;
    }

    bu_GroupMap = BusinessUnitUtility.getGroupNameForBusinessUnits(businessUnitSet);

    for (User u : newList) {
      if (oldMap != null && userMap.containsKey(u.ID) && userMap.get(u.ID).Business_Unit__c != null && 
                  bu_GroupMap.containsKey(userMap.get(u.ID).Business_Unit__c)) {
        String groupName = bu_GroupMap.get(userMap.get(u.ID).Business_Unit__c);

        if (groupName.equalsIgnoreCase(Constants.EDQ) && (String.isBlank(u.Office_Location__c))) {
          u.addError(Label.EDQ_USER_REQD_FIELDS);
        }
      } else if (u.Business_Unit__c != null && 
                 bu_GroupMap.containsKey(u.Business_Unit__c) &&
                 String.isBlank(u.Office_Location__c)) {
        String groupName = bu_GroupMap.get(u.Business_Unit__c);
        if (groupName.equalsIgnoreCase(Constants.EDQ)/* && String.isBlank(u.Office_Location__c)*/) {
          u.addError(Label.EDQ_USER_REQD_FIELDS);
        }
      }
    }
  }
  
  // Case #528796 : James Weatherall 28th April, 2015
  // Method creates new Experian Employee contact records when a Standard User is created
  // TODO: Need to consider whether this runs on insert and update e.g. User created as Inactive then activated
  // TODO: What to do with Dummy Users?
  /*
   * private static void createExperianContact(List<User> newList) {
      
    Id experianBUAccId = Global_Settings__c.getValues(Constants.GLOBAL_SETTING).Experian_Cross_BU_Acc_Id__c;
    List<Contact> usersToInsert = new List<Contact>();
    Set<String> existingEmailAdds = new Set<String>();
    
    for (Contact contacts : [SELECT Id, Email FROM Contact WHERE AccountId =: experianBUAccId and Email <> ''])
    {
      existingEmailAdds.add(contacts.Email);  
    }

    for(User u : newList)
    {
	  // Create users where no matching Email Address is found
      if(!existingEmailAdds.contains(u.Email) && u.IsActive && u.UserType == 'Standard') {
        usersToInsert.add(new Contact(AccountId = experianBUAccId, FirstName = u.FirstName, LastName = u.LastName, Title = u.Title, Department = u.Department, Phone = u.Phone, 
                                      MobilePhone = u.MobilePhone, Email = u.Email, Employee_Number__c = u.EmployeeNumber, Current_Manager__c = u.ManagerId, 
                                      SFDC_User__c = u.Id));
      }
    }
    
    try {
      if(usersToInsert.size() > 0) {
        insert usersToInsert;
      }
    } catch(DMLException e) {
        System.debug('UserTriggerHandler : createExperianContact : e = ' + e);          
    }
  } */
  
  // Case #528796 : James Weatherall 28th April, 2015
  // Updates the Current Manager of the Experian Employee Contact records 
  private static void updateExperianContactManager(List<User> newList, Map<ID, User> oldMap) {
    Map<Id, Id> userMap = new Map<Id, Id>();
    List<Contact> updateContacts = new List<Contact>();
      
    for(User u : newList)
    {
      if(u.ManagerId != oldMap.get(u.Id).ManagerId) {
        userMap.put(u.Id, u.ManagerId);      
      }
    }
    
    for (Contact c : [SELECT Id, SFDC_User__c, Current_Manager__c FROM Contact WHERE SFDC_User__c IN: userMap.keySet()])
    {
      if(userMap.get(c.SFDC_User__c) != c.Current_Manager__c)
      {
        c.Current_Manager__c = userMap.get(c.SFDC_User__c);
        updateContacts.add(c);
      }
    }
 
    try {
      if(updateContacts.size() > 0) {
        update updateContacts;
      }
    } catch(DMLException e) {
        System.debug('UserTriggerHandler : updateExperianContactManager : e = ' + e);          
    }
  }


  //===========================ACCOUNT SEGMENTS=================================
  // T-373930 : Method to create Account_Segment__c records for new Account
  //============================================================================
  private static void createAccSegmentForNewAccount_User(List<User> newList, Map<ID, User> oldMap) {
    system.debug('======createAccSegmentForNewAccount_User>>>');
    Set<String> updatedFieldValues = new Set<String>();
    Set<String> userFieldNameSet = new Set<String>{'Business_Line__c', 'Business_Unit__c',
                                                   'Global_Business_Line__c','Region__c', 'Country__c'};
    Map<Id, User> newUserMap = new Map<Id, User>();

    for (User userRec : newList) {
      if (oldMap != null) {
        newUserMap.put(userRec.Id, userRec);
        updatedFieldValues.addAll(isChangedAnyField(userFieldNameSet, userRec, oldMap.get(userRec.ID))) ;
      }
    }
    //If there is no field changed in the user list, return
    if (updatedFieldValues.size() == 0) {
      return;
    }
    system.debug('updatedFieldValues.size()>>>' +updatedFieldValues.size());

    //call method to create Account_Segment__c records
    AccountSegmentationUtility.createAccountSegmentRecordforUser(updatedFieldValues, newUserMap, userFieldNameSet);

  }

  //============================================================================
  // T-373930 : Method to recalculate Segment values
  //============================================================================
  private static void recalculateSegmentFieldValues(List<User> newList, Map<ID, User> oldMap) {
    Set<String> updatedFieldValues = new Set<String>();
    Set<String> userFieldNameSet = new Set<String>{'Business_Line__c', 'Business_Unit__c',
                                                     'Global_Business_Line__c','Region__c', 'Country__c'};
    Map<Id, User> newQualifyingUsers = new Map<Id, User>();
    Map<Id, User> oldQualifyingUsers = new Map<Id, User>();

    for (User userRec : newList) {
      if (oldMap != null) {
        //add new and old user records in Map
        newQualifyingUsers.put(userRec.Id, userRec);
        updatedFieldValues.addAll(isChangedAnyField(userFieldNameSet, userRec, oldMap.get(userRec.ID))) ;
      }
    }

    //If there is no field changed in the user list, return
    if (updatedFieldValues.size() == 0) {
      return;
    }
    system.debug('updatedFieldValues.size()>>>' +updatedFieldValues.size());

    // if there is change in values, call the method from AccountSegmentationUtility
    // When a user's BU/BL/GBL/Region/Country is updated, we will recalculate
    // the old and new segments representing those values

    /*AccountSegmentationUtility.updateOpportunitySegments(newQualifyingUsers, oldMap);
    AccountSegmentationUtility.updateOrderSegments(newQualifyingUsers, oldMap);*/

    AccountSegmentationUtility.segmentationMaintenance(updatedFieldValues, null);

  }

  //============================================================================
  // T-373930 : Method to check any field got changed
  //============================================================================
  private static Set<String> isChangedAnyField (Set<String> fieldNameSet, User newRecord, User oldRecord) {
    Set<String> updatedFieldValues = new Set<String>();

    for (String fieldName : fieldNameSet) {
      if (newRecord.get(fieldName) != oldRecord.get(fieldName)) {
        updatedFieldValues.add(String.valueOf(newRecord.get(fieldName)));
      }
    }
    return updatedFieldValues;
  }


}