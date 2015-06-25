/**=====================================================================
 * Appirio, Inc
 * Name: AccountTriggerHandler
 * Description: T-194935
 * Created Date: Oct 31st, 2013,On insert of an account if billing address is not blank
                then create address record and associate that address with
                the account by creating the AccountAddress record.
 * Created By: Manish Soni ( Appirio )
 *
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 13th, 2014               Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Mar 03rd, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Mar 10th, 2014               Naresh kr Ojha (Appirio)     T-257200: Creating account team on insert and update as parent account
 * Mar 11th, 2014               Naresh kr Ojha (Appirio)     T-257200: Not to remove users from child account who are not on parent
 * Mar 28th, 2014               Sadar Yacob                  Contact Sharing setting is set as 'Controlled by Parent', commenting ContactAccessLevel
 * Apr 07th, 2014               Arpita Bose                  T-269372: Added addError() in try-catch block
 * May 01st, 2014               Naresh kr Ojha (Appirio)     Updated catch(Exception) to catch(DMLException) to use getDMLMessage Line # 430
 * May 15th, 2014               Nathalie Le Guay             getUserMap() - Get user isActive flag prior to creating an ATM record for them
 * Aug 13th, 2014               James Weatherall             setVBMCode() - Sets the field VBM_Code__c. Required for Aria migration.
 * Aug 22nd, 2014               Sadar Yacob                  Merge Zipcode/PostCode field - use PostCode__c from now on
 * Oct 06th, 2014               Naresh Kr Ojha               T-323669: update send to on demand field on contacts with account name changed
 *                                                           Added method sendToOnDemand();
 * Oct 14th, 2014               James Weatherall             Uncommented setVBMCode() method and calls from beforeInsert, beforeUpdate
 * Jan 26th, 2015               James Weatherall             Case #29764: Added afterDelete method
 * Feb 9th, 2015                Paul Kissick                 Case #542921: Added fix for missing parents (checkForOriginalParent,fixParentAccountPostMerge) post merge.
 * Feb 19th, 2015               Paul Kissick                 Case #29764: Expanded createMergeHistory() method to add an entry for Account merges into MergeHistory.
 * Mar 4th, 2015                Gaurav Kumar Chadha          T-366810 : Added method checkSaasAccntDeactivated()
 * May 18th, 2015               Paul Kissick                 Case #582156: Added fix for nulls on parentids causing query exception
 * 
 =====================================================================*/
public without sharing class AccountTriggerHandler {
    /*
    // Method for create Address and AddressAccount on insert of an Account
    public static void createAddress(List<Account> newAccounts){

      // Map of Address and accountid
      Map<String, Address__c> addressToBeInsert = new Map<String,Address__c>();

      // Looping over new account list
      for(Account account : newAccounts){
        // If account have billing address then process further
        if(account.BillingStreet != null || account.BillingState != null || account.BillingPostalCode != null
          || account.BillingCountry != null || account.BillingCity != null){
            // Adding address in map with associated account id.
            addressToBeInsert.put(account.id, getAddress(account));
          }
      }

      // If map is not empty then insert the list of address.
      if(!addressToBeInsert.isEmpty()){
        insert addressToBeInsert.values();
        // Create account address
        createAccountAddress(addressToBeInsert);
      }
    }

    // Method for create Address object instance with the account fields values
    private static Address__c getAddress(Account account){

      Address__c address = new Address__c(
        Address_1__c = account.BillingStreet,
        City__c = account.BillingCity,
        State__c = account.BillingState,
        //Zip__c = account.BillingPostalCode,
        PostCode__c = account.BillingPostalCode,
        Country__c = account.BillingCountry,
        Authenticated_Address__c = false
      );
      return address;
    }

    // Method for create AccountAddress
    private static void createAccountAddress(Map<String, Address__c> mapAddressWithAccountId){

      // AccountAddress List
      List<Account_Address__c> accountAddressToBeInsert = new List<Account_Address__c>();

      // Looping over map of Addresses
      for(String accountId : mapAddressWithAccountId.keySet()){

        // Geting address for the assoicated account
        Address__c address = mapAddressWithAccountId.get(accountId);

        // Creating AccountAddress instance
        Account_Address__c accountAddress = new Account_Address__c(
          Account__c = accountId,
          Address__c = address.id,
          Primary_Shipping__c = false,
          Primary_Billing__c = false,
          Address_Type__c = 'Registered',
          Address_Purpose__c = 'Legal'
        );
        accountAddressToBeInsert.add(accountAddress);
      }

      // Inserting list of AccountAddress
      insert accountAddressToBeInsert;
    }*/
  public static Map<Id, User> userMap = new Map<Id, User>();

  //Before Insert Call
  public static void beforeInsert (List<Account> newList) {
    populateUltimateAccount(newList);
    setVBMCode(newList, null);
  }
  //After Insert Call
  public static void afterInsert (List<Account> newList) {
    //MIrfan@201113, S-154585
    addUserToAccountTeam(newList);
  }
  //Before Update Call
  public static void beforeUpdate (List<Account> newList, Map<Id,Account> oldMap) {
    updateUltimateAccount(newList, oldMap);
    setVBMCode(newList, oldMap);
    system.debug('******* Before Update ::::');
    checkSaasAccntDeactivated(newList, oldMap); // T-366810 GC
  }

  //After Update Call
  public static void afterUpdate (List<Account> newList, Map<Id,Account> oldMap) {
    //MIrfan@201113, S-154585
    addUserToAccountTeam (newList);
    setSendBillingAccountToAria(newList, oldMap);
    sendToOnDemand(newList, oldMap);//As per T-323669.
    //integrityCheck(newList, oldMap);
  }
  //Before Delete Call
  public static void beforeDelete (Map<Id,Account> oldMap) {
    /* Uncomment the code below if reparenting issue not resolved by Paul's @future method change */
    // Fetch API User Id and assign to variable to ensure Id is 18 chars
    // Id apiUserId = Global_Settings__c.getValues('Global').API_User_Id__c;
    // Skip if API User
    //if(UserInfo.getUserId() != apiUserId) {  
      checkIfParentAccountIsDeleted(oldMap.values());
    //}
  }

  //After Delete Call
  public static void afterDelete (List<Account> newList, Map<Id, Account> oldMap) {
    createMergeHistory(oldMap);
    checkForOriginalParent(oldMap); // PK: Case #542921
  }

  //==========================================================================================
  // T-366810 : check if saas account is deactivated
  //==========================================================================================
  public static void checkSaasAccntDeactivated (List<Account> newList,
                                               Map<ID , Account> oldMap){
    List<Account> lstDeactivatedAccounts = new list<Account>();
    for (Account account : newList ) {
      if (account.Saas__c != null &&
          account.Saas__c != oldMap.get(account.ID).Saas__c &&
          account.Saas__c == false) {
        lstDeactivatedAccounts.add(account);
      }
    }
    if (!lstDeactivatedAccounts.isEmpty()){
      preventDeactivationOfSaasAccount(lstDeactivatedAccounts);
    }
  }

  //==========================================================================================
  // T-366810 : prevent deactivation of saas account if there is a related active deployment
  //==========================================================================================
  public static void preventDeactivationOfSaasAccount (List<Account> lstDeactivatedAccounts) {
    Map<ID, boolean> mapAccIdWithActiveDeployment = new Map<ID, boolean>();
    for (Deployment__c deployment : [SELECT ID, Active__c, Account__c
                                     FROM  Deployment__c
                                     WHERE Account__c in :lstDeactivatedAccounts
                                       AND Active__c = true]) {

      if (mapAccIdWithActiveDeployment.containsKey(deployment.Account__c) == false) {
        mapAccIdWithActiveDeployment.put(deployment.Account__c, true);
      }
    }

    for (Account account : lstDeactivatedAccounts) {
      if (mapAccIdWithActiveDeployment.containsKey(account.ID) &&
           mapAccIdWithActiveDeployment.get(account.ID) == true) {
        account.addError(system.label.SaaS_ERR_ACCOUNT_ACTIVE_DEPLOYMENT);
      }
    }
  }

  //populate Account's Ultimate_Parent_Account__c field when account is inserted
  public static void populateUltimateAccount(List<Account> lstAccount) {
    Map<Id,Id> parentsUltimateAcc = new Map<Id,Id>();
    for(Account account : lstAccount) {
      if(account.ParentId == NULL) {
        continue;
      }
      parentsUltimateAcc.put(account.ParentId,NULL);
    }
    for(Account parent : [SELECT Ultimate_Parent_Account__c
                          FROM Account
                          WHERE Id in : parentsUltimateAcc.keySet()]) {
      parentsUltimateAcc.put(parent.Id,parent.Ultimate_Parent_Account__c);
    }
    for(Account account : lstAccount) {
      if(account.ParentId != NULL) {
        if(parentsUltimateAcc.containsKey(account.ParentId) && parentsUltimateAcc.get(account.ParentId) != NULL) {
          account.Ultimate_Parent_Account__c = parentsUltimateAcc.get(account.ParentId);
        } else {
          account.Ultimate_Parent_Account__c = account.ParentId;
        }
      }
    }
  }

  //Restrict Parent account to be deleted
  public static void checkIfParentAccountIsDeleted(List<Account> lstAccount) {

    Set<Id> parentAccounts = new Set<Id>();
    // Retrieve all childs
    for(Account account : [SELECT Id,ParentId
                           FROM Account
                           WHERE ParentId in :lstAccount]) {
      parentAccounts.add(account.ParentId);
    }
    /*
    Set<Id> ultimateAccounts = new Set<Id>();
    for(Account account : [SELECT Id
                           FROM Account
                           WHERE Ultimate_Parent_Account__c in :lstAccount]) {
      if(account.Ultimate_Parent_Account__c == NULL) {
        continue;
      }
        ultimateAccounts.add(account.Ultimate_Parent_Account__c);
    }
    */
    if(parentAccounts.size() == 0) {
      return;
    }
    for(Account account : lstAccount) {
      if(parentAccounts.contains(account.Id)) {
        account.addError('Please re-parent child Accounts before deleting this Account :'+account.Name);
      }
    }
  }

  //Filter Account's where Parent is changed
  public static void updateUltimateAccount(List<Account> lstAccount, Map<Id,Account> oldMap) {

    List<Account> lstAccountToUpdate = new List<Account>();
    Map<Id,Account> mapUltimateAccountNowChild = new Map<Id,Account>();
    Map<Id,Id> mapAccAndUltimateParent = new Map<Id,Id>();
    for(Account account : lstAccount) {
      if(account.ParentId != NULL && account.ParentId != oldMap.get(account.Id).ParentId) {
        lstAccountToUpdate.add(account);
      }
      //MIrfan. 10Dec13. I-84301
      if(account.ParentId == NULL) {
        account.Ultimate_Parent_Account__c=null;
      }

      //MIrfan. 10Dec13. I-84300. This is to align Child Records with correct Ultimate parent when Parent is not added.
      if(account.ParentId != NULL && oldMap.get(account.Id).ParentId==null) {
        mapUltimateAccountNowChild.put(account.id,account);
      }//END: IF


      //MIrfan. 17Dec13. I-84300. If Parent is blanked reparent children correctly.
      if(account.ParentId==null && oldMap.get(account.Id).ParentId!=null) {
        mapAccAndUltimateParent.put(account.id,oldMap.get(account.Id).Ultimate_Parent_Account__c);
        //mapUltimateAccountNowChild.put(oldMap.get(account.Id).Ultimate_Parent_Account__c,account);
      }//END: IF
    }

    if(lstAccount.size() > 0) {
      updateUltimateAccount(lstAccountToUpdate);
    }

    //MIrfan. 17Dec13. I-84300.
     if(mapUltimateAccountNowChild.size()>0) {
      ultimateAccountUpdatedAlignChildren(mapUltimateAccountNowChild);
     }
    //MIrfan. 10Dec13. I-84300.
    if(mapAccAndUltimateParent.size()>0) {
      parentAccountRemovedAlignChildren(mapAccAndUltimateParent);
    }
   }//END: method updateUltimateAccount

  //===========================================================================
  //MIrfan. 10Dec13. I-84300. If Parent Account is not Looking to another,
  //then all its Child records should reflect corrent Ultimate Parent.
  //===========================================================================
  public static void parentAccountRemovedAlignChildren(Map<Id,Id> mapAccAndUltimateParent) {
    List<Account> lstChildAccountsToUpdate = new List<Account>();
    
    // Retrieve all Children where Ultimate Parent matches removed Parent A/cs.
    /*
    Map<Id,Account> mapChildAccs = new Map<Id,Account>([SELECT Id,Ultimate_Parent_Account__c,ParentId FROM Account WHERE
                                                               Ultimate_Parent_Account__c in : mapAccAndUltimateParent.values() and
                                                               Id !=: mapAccAndUltimateParent.keyset() order by CreatedDate asc]);
    */
    // PK Case #582156 - Fix to avoid nulls in query below...
    List<Id> ultiParents = new List<Id>();
    for(Id ultiParentId : mapAccAndUltimateParent.values()) {
      if (ultiParentId != null) ultiParents.add(ultiParentId);
    }
    List<Id> accIds = new List<Id>();
    for(Id accId : mapAccAndUltimateParent.keyset()) {
      if (accId != null) accIds.add(accId);
    }

     // Retrieve all Children where Ultimate Parent matches removed Parent A/cs.
    Map<Id,Account> mapChildAccs = new Map<Id,Account>([SELECT Id,Ultimate_Parent_Account__c,ParentId FROM Account WHERE 
                                                               Ultimate_Parent_Account__c in :ultiParents and 
                                                               Id != :accIds order by CreatedDate asc]);

    //Iterate through all Children records to align/correct hierarchy.
    for(Account accRec: mapChildAccs.values()) {
      //If this Child.Parent was one updated, meaning this is immediate child.
      //In this case Parent and Ultimate parent should be same A/c
      if(mapAccAndUltimateParent.containsKey(accRec.ParentId)) {
        //Add to list to update
        lstChildAccountsToUpdate.add(new Account(Id=accRec.Id,Ultimate_Parent_Account__c=accRec.ParentId));

        //Also update the A/c in Map to reflect correct Ultimate Parent.
        mapChildAccs.get(accRec.Id).Ultimate_Parent_Account__c=accRec.ParentId;
      }//END: IF
      else //This to Iterate through Grand or Great Grand children records :-)
      {
        //Pull the Current A/cs Parent A/c instace from Map.
        Account parentAccount = mapChildAccs.get(accRec.ParentId);
        system.debug('##########mapChildAccs##########'+mapChildAccs);
        system.debug('##########accRec##########'+accRec);

        //Iterate until Top level Parent A/c is reached.
        while(true)  {
          system.debug('##########parentAccount##########'+parentAccount);

          //If Parent is not known then move out of loop
          if(parentAccount==null)
            break;

          //If Parent A/c's Parent was the one updated the add to list, then break the loop.
          if(mapAccAndUltimateParent.containsKey(parentAccount.ParentId))  {
            system.debug('##########Found Parent in Removed##########');
            //Stamp Grand or Great Grand child with Ultimate Parent A/c
            lstChildAccountsToUpdate.add(new Account(Id=accRec.Id,Ultimate_Parent_Account__c=parentAccount.ParentId));
            break;
          }//END: if

          //Get Parent A/c instance from Map for current Parent A/c.
          parentAccount = mapChildAccs.get(parentAccount.ParentId);
        }//END: while
      }//END: else Master
    }//END: for accRec

    system.debug('##########lstChildAccountsToUpdate############'+lstChildAccountsToUpdate);

    if(lstChildAccountsToUpdate.size()>0) {
      update lstChildAccountsToUpdate;
    }
  }//END: method parentAccountRemovedAlignChildren

  //===========================================================================
  // MIrfan. 10Dec13. I-84300. If Ultimate Parent Account is not Looking upto another Parent,
  //                       then all its Child records should reflect corrent Ultimate Parent.
  //===========================================================================
  public static void ultimateAccountUpdatedAlignChildren(Map<Id,Account> mapUltimateAccountNowChild) {

    List<Account> lstChildAccountsToUpdate = new List<Account>();
    // Accounts where Ultimate account is same as Account's Ultimate whose parent is changed
    for(Account rec: [SELECT Id,Ultimate_Parent_Account__c,ParentId FROM Account WHERE
                            Ultimate_Parent_Account__c in : mapUltimateAccountNowChild.keySet() and
                            Id !=:mapUltimateAccountNowChild.values()]) {
      lstChildAccountsToUpdate.add(new Account(Id=rec.Id,
       Ultimate_Parent_Account__c = mapUltimateAccountNowChild.get(rec.Ultimate_Parent_Account__c).Ultimate_Parent_Account__c));
    }

    system.debug('##########lstChildAccountsToUpdate############'+lstChildAccountsToUpdate);

    if(lstChildAccountsToUpdate.size()>0) {
      update lstChildAccountsToUpdate;
    }
  }//END: method ultimateAccountUpdatedAlignChildren

  //===========================================================================
  // Update Account's Ultimate_Parent_Account__c field when account is udpated
  // and its parent is changed
  //===========================================================================
  public static void updateUltimateAccount(List<Account> lstAccount) {

    Set<Id> newParentIds = new Set<Id>();
    Set<Id> setUltimateIds = new Set<Id>();
    for(Account acc : lstAccount) {
      if(acc.Ultimate_Parent_Account__c != NULL) {
        setUltimateIds.add(acc.Ultimate_Parent_Account__c);
      }
      if(acc.ParentId != NULL) {
        newParentIds.add(acc.ParentId);
      }
    }
    // Accounts where Ultimate account is same as Account's Ultimate whose parent is changed
    List<Account> accountToCheck = [SELECT Id,Ultimate_Parent_Account__c,ParentId
                                    FROM Account
                                    WHERE Ultimate_Parent_Account__c in : setUltimateIds
                                          AND Id not in :lstAccount];
    // Parent Id To ultimate account Map
    Map<Id,Id> parentsUltimateAcc = new Map<Id,Id>();
    for(Account account : [SELECT Id,Ultimate_Parent_Account__c,ParentId
                           FROM Account WHERE Id in : newParentIds] ) {
      Id utlimateParent;
      if(account.Ultimate_Parent_Account__c != NULL) {
        utlimateParent = account.Ultimate_Parent_Account__c;
      } else {
        utlimateParent = account.Id;
      }
      parentsUltimateAcc.put(account.Id,utlimateParent);
    }
    // account Id To ultimate account Map
    Map<Id,Id> mpUltimateAcc = new Map<Id,Id>();
    // Update accounts where parent Id changed
    for(Account acc : lstAccount) {
      acc.Ultimate_Parent_Account__c = parentsUltimateAcc.get(acc.ParentId);
      mpUltimateAcc.put(acc.Id,parentsUltimateAcc.get(acc.ParentId));
    }
    boolean iterateAgain = true;
    List<Account> lstAccountToUpdate = new List<Account>();
    while(iterateAgain) {
      iterateAgain = false;
      for(Account accToCheck : accountToCheck) {
        if(mpUltimateAcc.containsKey(accToCheck.ParentId) && accToCheck.Ultimate_Parent_Account__c  !=
          mpUltimateAcc.get(accToCheck.ParentId)) {
          accToCheck.Ultimate_Parent_Account__c = mpUltimateAcc.get(accToCheck.ParentId);
          mpUltimateAcc.put(accToCheck.Id,accToCheck.Ultimate_Parent_Account__c);
          iterateAgain = true;
        }
      }
    }
    // Udpate account where parent account is not checked but Ultimate account is
    // updated indirectly
    update accountToCheck;
  }

  //MIrfan@20113
  public static void addUserToAccountTeam(List<Account> lstAccount) {
    List<AccountTeamMember> lstATMs = new List<AccountTeamMember>();
     List<AccountShare> lstAccShare = new List<AccountShare>();
    //From Custom setting.
     Global_Settings__c custSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);
     system.debug('###########custSettings#########'+custSettings);

    userMap = getUserMap(lstAccount);
    for(Account accRec:lstAccount) {
      system.debug('########accRec############'+accRec);
      // NLG - 2014-05-15 - do not create ATM if user is inactive
      if (userMap.get(accRec.CreatedById) != null && userMap.get(accRec.CreatedById).isActive == false) {
        continue;
      }
      //If creator and Owner is different then share the Add to Team and Share record with Edit
      if(accRec.CreatedById != accRec.OwnerId) {
        lstATMs.add( new AccountTeamMember(AccountId=accRec.id,
        UserId=accRec.CreatedById,
        TeamMemberRole=custSettings.Account_Team_Member_Default_Role__c));

        //As Edit Access cannot be set via API for AccountTeamMember, has to create share record to give Edit access on Record.
        lstAccShare.add( new AccountShare(AccountAccessLevel = Constants.ACCESS_LEVEL_EDIT,
        AccountId = accRec.id,OpportunityAccessLevel = Constants.ACCESS_LEVEL_READ,
        // ContactAccessLevel = Constants.ACCESS_LEVEL_EDIT, // Sadar Mar 27 2014 - Sharing setting is set as 'Controlled by Parent'
        CaseAccessLevel = Constants.ACCESS_LEVEL_READ,
         UserOrGroupId = accRec.CreatedById));
       }
    }

    system.debug('##########lstATMs##########'+lstATMs);

    if(lstATMs.size()>0) {
      try {
        insert lstATMs;
        insert lstAccShare;
      }  catch  (DMLException ex) {
         system.debug('##########ex##########'+ex);
         ApexLogHandler.createLogAndSave('AccountTriggerHandler','addUserToAccountTeam', ex.getStackTraceString(), ex);
         for (Integer i = 0; i < ex.getNumDml(); i++) {
          lstAccount.get(0).addError(ex.getDmlMessage(i));
      }
     }
    }
  }


  //=========================================================================
  // I-115460 - Get user isActive flag prior to creating an ATM record for them
  //=========================================================================
  private static Map<Id, User> getUserMap(List<Account> accounts) {
    userMap = new Map<Id, User>();
    Set<Id> createdByIds = new Set<Id>();

    for (Account acct: accounts) {
      createdByIds.add(acct.CreatedById);
    }
    return new Map<Id, User>([SELECT Id, isActive
                              FROM User
                              WHERE Id in: createdByIds]);
  }

  // James Weatherall 10142014 - Uncommented code for migration to PROD
  //Start: Update VBM Code on the Account. Used mainly for Aria migration.
  private static void setVBMCode (List<Account> newList, Map<Id,Account> oldMap) {
    Set<ID> accIDs = new Set<ID>();
    Map<Id, String> industrySectorMap = new Map<Id, String>();
    Map<String, String> vbmDescriptionCodes = new Map<String, String>();
    String vbmDescription, industrySector;

    // Get the list of Industries and Sectors
    // Set to lowercase due to case sensitivity in Map keySet
    for (Account acc : newList) {
        if (acc.Industry != '' && acc.Sector__c != '')
        {
          accIDs.add(acc.Id);
          industrySector = acc.Industry + '-' + acc.Sector__c;
          industrySectorMap.put(acc.Id, industrySector.toLowerCase());
          system.debug('###########industrySector#########'+industrySector);
        }
    }
    system.debug('###########industrySectorMap.values()#########'+industrySectorMap.values());
    // Create a map of Descriptions and VBM Codes
    if (industrySectorMap.size() > 0)
    {
      for (Oracle_VBM_Codes__c ovc : [SELECT Name, Description__c FROM Oracle_VBM_Codes__c WHERE Description__c IN: industrySectorMap.values()])
      {
        vbmDescription = ovc.Description__c;
        vbmDescription = vbmDescription.toLowerCase();
        system.debug('###########vbmDescription#########'+vbmDescription);

        if(!vbmDescriptionCodes.containsKey(vbmDescription))
        {
          vbmDescriptionCodes.put(vbmDescription, ovc.Name);
        }
      }
    }
    system.debug('###########vbmDescriptionCodes#########'+vbmDescriptionCodes);
    // Set the VBM Code on the Account
    try {
      for(Account acc : newList)
      {
        if(accIDs.contains(acc.Id))
        {
          acc.VBM_Code__c = vbmDescriptionCodes.get(industrySectorMap.get(acc.Id));
        }
      }
    } catch(DMLException e) {

      System.debug('\n[AccountTriggerHandler: setVBMCode]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountTriggerHandler','setVBMCode', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        newList.get(0).addError(e.getDmlMessage(i));
      }
    }
  }
  // :End

  /**************************************************************************
  *                           ARIA CODE BELOW                               *
  **************************************************************************/
  //=========================================================================
  //T-264687; to Update ARIA_BillingACC.SendBillingAccToAria = true
  //=========================================================================
  private static void setSendBillingAccountToAria (List<Account> newList, Map<ID, Account> oldMap) {
    Set<ID> accIDs = new Set<ID>();
    Set<String> accFieldNameSet = new Set<String>{'Website', 'Ultimate_Parent_Account__c',
                      'Status__c', 'Sector__c', 'Phone', 'ParentId', 'Name', 'Industry',
                      'BillingStreet', 'BillingState', 'BillingPostalCode', 'BillingCountry',
                                                                            'BillingCity'};
    Map<String, ARIA_Billing_Account__c> ARIABilAcc_Map =
                              new Map<String, ARIA_Billing_Account__c> ();
    //check whether above set of fields updated
    for (Account acc : newList) {
      if (isChangedAnyField(accFieldNameSet, acc, oldMap.get(acc.ID))) {
        accIDs.add(acc.ID);
      }
    }
    //If there is no field changed in the account list, return
    if (accIDs.size() < 0) {
      return;
    }
    try {
      for (Account acc : [SELECT ID, (SELECT Id, Push_To_Aria__c, SendBillingAccntToAria__c , Billing_Account_Country__c, Direct_Debit__c
                                      From ARIA_Billing_Accounts__r
                                      WHERE Push_To_Aria__c =:Constants.PICKLISTVAL_YES)
                          From Account WHERE ID IN : accIDs]) {
        for (ARIA_Billing_Account__c abAcc : acc.ARIA_Billing_Accounts__r) {
          if (!ARIABilAcc_Map.containsKey(abAcc.ID)) {
            abAcc.SendBillingAccntToAria__c = true;
            ARIABilAcc_Map.put(abAcc.ID, abAcc);
      System.debug('\ncountry: '+ abacc.Billing_Account_Country__c + '\nDirectDebit: '+ abacc.Direct_Debit__c);
          }
        }
      }//End of For Loop

      if (ARIABilAcc_Map.values().size() > 0) {
        update ARIABilAcc_Map.values();
      }
    }catch(DMLException e){

      System.debug('\n[AccountTriggerHandler: setSendBillingAccountToAria]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountTriggerHandler','setSendBillingAccountToAria', e.getStackTraceString(), e);
      for (Integer i = 0; i < e.getNumDml(); i++) {
        newList.get(0).addError(e.getDmlMessage(i));
      }
    }

  }//End of setSendBillingAccountToAria

  //=========================================================================
  //T-264687; to check any field got changed.
  //=========================================================================
  private static Boolean isChangedAnyField (Set<String> fieldNameSet, Account newRecord, Account oldRecord) {
    for (String fieldName : fieldNameSet) {
      if (newRecord.get(fieldName) != oldRecord.get(fieldName)) {
        return true;
      }
    }
    return false;
  }

  //===========================================================================
  // T-332669: Send to On-Demand
  //===========================================================================
  private static void sendToOnDemand (List<Account> newList, Map<ID, Account> oldMap) {

    Set<ID> accountIDs = new Set<ID>();
    Map<String, Contact> accID_contactsToSendOnDemand = new Map<String, Contact>();

    //Checking name changed of accounts
    for (Account acc : newList) {
      if (acc.Name != oldMap.get(acc.ID).Name) {
        accountIDs.add(acc.ID);
      }
    }

    //Setting send to on demand = true
    for (Contact c : [SELECT Id, EDQ_Send_to_On_Demand__c, EDQ_On_Demand__c, AccountId
                      FROM Contact
                      WHERE AccountID IN: accountIDs AND EDQ_On_Demand__c = true]) {
      c.EDQ_Send_to_On_Demand__c = true;
      if (!accID_contactsToSendOnDemand.containsKey(c.AccountID)) {
        accID_contactsToSendOnDemand.put(c.AccountID, c);
      }
    }

    //Update contacts
    if (accID_contactsToSendOnDemand.size() > 0) {
      try {
        update accID_contactsToSendOnDemand.values();
      } catch(DMLException e){
        newList.get(0).addError(Label.ACCOUNT_ERROR_NAME_CHANGE_On_Demand_Flag);
        System.debug('\n[AccountTriggerHandler: sendToOnDemand]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AccountTriggerHandler','sendToOnDemand', e.getStackTraceString(), e);
        for (Integer i = 0; i < e.getNumDml(); i++) {
          newList.get(0).addError(e.getDmlMessage(i));
        }
      }
    }
  }

  //===========================================================================
  // Case #29746: Merge History
  //===========================================================================
  private static void createMergeHistory(Map<Id, Account> oldMap) {
    // S-284433
    Map<Id,Id> loserToWinnerIds = new Map<Id,Id>();
    Set<Id> winningIds = new Set<Id>();
    for(Account deletedAccount : oldMap.values()) {
      if (deletedAccount.MasterRecordId != null) {
        // master is winning record.
        loserToWinnerIds.put(deletedAccount.Id,deletedAccount.MasterRecordId);
        // Set to hold which accounts won in the merge (normally only 1 record here, as merges don't get bulked.)
        winningIds.add(deletedAccount.MasterRecordId);
        // also adding the ultimate parent Id (if on the deleted records...) for use below
        if (deletedAccount.Ultimate_Parent_Account__c != null) {
          winningIds.add(deletedAccount.Ultimate_Parent_Account__c);
        }
      }
    }
    if (loserToWinnerIds.size() > 0) {
      // From these we need to get the CSDA_Integration_Id__c and EDQ_Integration_Id__c from both winner and loser (loser will be in the trigger, winner won't)
      List<MergeHistory__c> newHistory = new List<MergeHistory__c>(); 
      try {
        Map<Id,Account> winners = new Map<Id,Account>([
          SELECT EDQ_Integration_Id__c, 
            CSDA_Integration_Id__c, 
            Global_Unique_ID__c,
            Experian_ID__c,
            Saas__c,
            Ultimate_Parent_Account__c, 
            Ultimate_Parent_Account__r.CSDA_Integration_Id__c 
          FROM Account 
          WHERE Id IN :winningIds
        ]);
        for(Id loserId : loserToWinnerIds.keySet()) {
          Account loserAcc = oldMap.get(loserId);
          Account winnerAcc = winners.get(loserToWinnerIds.get(loserId));
          // Calls new utility class to build the MergeHistory
          MergeHistory__c mh = MergeHistoryUtility.createMergeHistoryRecord(loserAcc,winnerAcc); 
          // Since this only applies to Accounts, add a check and set the top parent here.
          if (loserAcc.Ultimate_Parent_Account__c != null) {
            try {
              mh.Loser_Top_Parent_CSDA_Integration_ID__c = winners.get(loserAcc.Ultimate_Parent_Account__c).CSDA_Integration_Id__c;
            }
            catch (Exception e) {
              system.debug('\n[AccountTriggerHandler: createMergeHistory]: ['+e.getMessage()+']]');
              apexLogHandler.createLogAndSave('AccountTriggerHandler','createMergeHistory', e.getStackTraceString(), e);
            }
          }
          newHistory.add(mh);
        }
        insert newHistory;
        
      } catch(DMLException e){
        System.debug('\n[AccountTriggerHandler: createMergeHistory]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AccountTriggerHandler','createMergeHistory', e.getStackTraceString(), e);
      }
    }

  }

  // Case #542921 : Check and replace the parent on a merged record, if it's there on the 'deleted' account.
  private static void checkForOriginalParent (Map<Id, Account> oldMap) {
    Map<Id,Id> winningToParent = new Map<Id,Id>();
    for(Account deletedAccount : oldMap.values()) {
      if (deletedAccount.MasterRecordId != null) {
        // find the parentid on the deleted record, and set this on the new masterrecordid record...
        if (deletedAccount.ParentId != null) {
          winningToParent.put(deletedAccount.MasterRecordId,deletedAccount.ParentId);
        }
      }
    }
    if (winningToParent.size() > 0) {
      // Due to a SELF_REFERENCE_FROM_TRIGGER DML exception, the update of the winning records must be in a future method.
      AccountTriggerHandler.fixParentAccountPostMerge(winningToParent);
    }
  }

  // Case #542921 : After the merge has completed, find the winning records, and reparent them if there is no original parent record.
  // This doesn't happen immediately though, so the parent will eventually be fixed!
  @future
  public static void fixParentAccountPostMerge (Map<Id,Id> winningToParent) {
    List<Account> updateWinningWithParent = [SELECT ParentId,Id FROM Account WHERE Id IN : winningToParent.keySet() AND ParentId = null];
    if (updateWinningWithParent.size() > 0) {
      // For each account, get the new 'parent' and save.
      for(Account a : updateWinningWithParent) {
        if (a.ParentId == null) {
          a.ParentId = winningToParent.get(a.Id);
        }
      }
      update updateWinningWithParent;
    }
  }
  
  //===========================================================================
  // Case #525537: For Account Integrity check setup If "Integrity Check Not Approved" checkbox is 
  //  checked trigger child open Opptys will be edited to fire a workflow
  //===========================================================================
  /* 
  // PK: Commenting out for June 9th Deployment
  public static void integrityCheck(List<Account> newList, Map<Id, Account> oldMap) {
    Map<Id, Account> changed = new Map<Id, Account>();
    
    // Values passed into the method as parameters   
    // Changed Trigger.new to newList
    for (Account accCheck : newList) {
      // Changed Trigger.oldMap to oldMap  
      Account old = oldMap.get(accCheck.Id);
      if (accCheck.Integrity_Check_Not_Approved__c != old.Integrity_Check_Not_Approved__c) {
        changed.put(accCheck.Id, accCheck);
      }
    }
      
    if (changed.size() > 0) {
      // Only update when the field has the wrong value
      List<Opportunity> updates = new List<Opportunity>();
      // Changed Account to AccountId on lines 714 and 715
      for (Opportunity detail : [SELECT Id, AccountId, Account_Integrity_Check_Not_Approved__c FROM Opportunity WHERE AccountId IN :changed.keySet()]) {
        Account accCheck = changed.get(detail.AccountId);
        Boolean requiredFlag = accCheck.Integrity_Check_Not_Approved__c != null;
        if (detail.Account_Integrity_Check_Not_Approved__c != requiredFlag) {
          detail.Account_Integrity_Check_Not_Approved__c = requiredFlag;
          updates.add(detail);
        }
      }
      try {  
        update updates;            
      } catch(DMLException e){
        System.debug('\n[AccountTriggerHandler: integrityCheck]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AccountTriggerHandler','integrityCheck', e.getStackTraceString(), e);
      }    
    }
  }
  */
}