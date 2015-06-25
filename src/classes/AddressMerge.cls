/**=====================================================================
 * Appirio, Inc
 * Name: AddressMerge
 * Description: T-249253: Webservice to merge addresses passed in to webservice.
 * Created Date: Feb 13th, 2014
 * Created By: Naresh Kr Ojha(Appirio)
 * 
 * Date Modified                 Modified By                  Description of the update
 * Feb 17th, 2014                Naresh Kr Ojha (Appirio)     T-249253: according Chatter
 * Feb 17th, 2014                Jinesh Goyal (Appirio)       T-250105: added 'mergeAddresses', 'createAddressHistory', 'mergeAddressesInBatch'
 * Feb 21th, 2014                Jinesh Goyal (Appirio)       T-251322: added 'performManualMerge' method
 * Feb 23rd, 2014                Naresh kr Ojha (Appirio)     T-249253: As on chatter of Nathalie.
 * Feb 24th, 2014                Jinesh Goyal (Appirio)       T-249253: As on chatter by Nathalie.
 * Feb 24th, 2014                Nathalie Le Guay (Appirio)   Renaming 'victim' with 'slave' and 'survivor' with 'master' for consistency
 *                                                            Created processMergeRequests()
 * Feb 25th, 2014                Jinesh Goyal (Appirio)       Populate Address_Merge_Request__c.Slave_Address_History__c field
 * Feb 27th & 28th, 2014         Naresh Kr Ojha (Appirio)     T-250104: creation of mergeAddressWebservice as per updated description on the task.
 * Mar 04th, 2014                Jinesh Goyal (Appirio)       updated code to handle AMR with same master and different slaves
 * Apr 07th, 2014                Arpita Bose(Appirio)         T-269372: Added addError()in try-catch block
 * May 1st, 2014                 Arpita Bose                  Updated catch(Exception) to catch(DMLException)
 * Jul 30th, 2014                Nathalie Le Guay             
 * Aug 13th, 2014                Arpita Bose                  T-308907: Updated method mergeAddressWebserviceBis()
 * Aug 26th, 27th & 28th 2014    Arpita Bose                  T-308907: Updated method mergeAddressWebserviceBis() as per the new task description
                                                              and added Labels
 * Sep 03rd, 2014                Arpita Bose                  Updated method mergeAddressWebserviceBis() to get error code and error message
 * Jun 10th, 2015                Paul Kissick                 Case #970440 - Database.rollback in wrong location.
 =====================================================================*/
global class AddressMerge {

  private static String errorCode = '';
  private static String errorMsg = '';  
  private static final DateTime batchStartTime;
  private static DateTime batchEndTime;
  private static String errMsg = '';
  private Database.SaveResult[] lstSaveResult;
  private static Map<Id, Id> mergeRequestIdToAddressHistoryIdMap = new Map<Id, Id>();
  private static Map<String, String> mpMSKeyToAMRId = new Map<String, String>();
  public static Set<ID> processedSlaves = new Set<ID>();
  static {
    batchStartTime = datetime.now();
  }
  //Define an object in apex that is exposed in apex web service
 
  //===============================================================================
  // Method to process Address_Merge_Request__c and
  // create a full Address copy by creating an entry in the Address_History__c table
  // T-250105
  //===============================================================================
  public static Map<String, String> mergeAddresses (Map <String, String> mpIdsMasterToSlaves) { 
    Set<String> stIdsAddressesToBeProcessed = new Set<String>();
    Map<String, String> mpIdsMasterToSlavesToBeProcessed = new Map<String, String>();
    Boolean success = false;

    //Create savepoint
    Savepoint sp = Database.setSavepoint();
    //create Address_History__c instance for the Slave1
    stIdsAddressesToBeProcessed = createAddressHistory(mpIdsMasterToSlaves);
    //creating map for Master and Slaves to be actually processed
    //after successful creation to Address History for the Slave Address
    if (!mpIdsMasterToSlaves.isEmpty()) {
      for (String masterId : mpIdsMasterToSlaves.keySet()) {
        for (String slaveId : mpIdsMasterToSlaves.get(masterId).split(':')) {
          if (stIdsAddressesToBeProcessed.contains (slaveId)) {
            if (!mpIdsMasterToSlavesToBeProcessed.containsKey(masterId)) mpIdsMasterToSlavesToBeProcessed.put (masterId, slaveId);
            else mpIdsMasterToSlavesToBeProcessed.put (masterId, mpIdsMasterToSlavesToBeProcessed.get(masterId)+':'+slaveId);
          }
        }
      }
    }
    
    //merge and then delete Slave1
    if (!mpIdsMasterToSlavesToBeProcessed.isEmpty()) {
       success = mergeAddressesInBatch(mpIdsMasterToSlavesToBeProcessed);
    }
    //rollback to undo the creation of Address_History__c if the merge did not go well
    if (!success) {
      Database.rollback(sp);
      return null; //if the process was not successful
    }
    return (mpIdsMasterToSlavesToBeProcessed); //if the process completed successfully
  }//END OF METHOD 'mergeAddresses'
  

  //===============================================================================
  // Method to create entry in the Address_History__c table
  //===============================================================================
  private static Set<String> createAddressHistory (Map <String, String> mpIdsMasterToSlaves) {
    Set<String> setIdsSlaveAddressesToBeDeleted = new Set<String>();
    Address_History__c tempAH;
    Map<ID, Address_History__c> addressHistoryMap = new Map<ID, Address_History__c>();
    Integer index = 0;
    Set<String> stAddressIds = new Set<String>();
    Map <String, String> mpIdsSlaveToMaster = new Map <String, String>(); 
    String ATMmasterId = '';
    String ATMslave1 = '';
    for(String s : mpIdsMasterToSlaves.keySet()) {
      if (s !=  null && mpIdsMasterToSlaves.containsKey(s) && mpIdsMasterToSlaves.get(s) != null) {
        for (String slaveId : mpIdsMasterToSlaves.get(s).split(':')) {
          mpIdsSlaveToMaster.put(slaveId, s);
        }
      }
      ATMmasterId = (s == null) ? null : s; 
      ATMslave1 = (s == null && mpIdsMasterToSlaves.get(s) == null) ? null : mpIdsMasterToSlaves.get(s);

      if (ATMmasterId <> null && ATMslave1 <> null) {
        for (String eachSlaveId : ATMslave1.split(':')) {
          stAddressIds.add(eachSlaveId);
        }
      }
    }
    for (Address__c address: [SELECT Zip__c, Validation_Status__c, Suite__c,  
                                     State__c, SortingCode__c, Province__c, 
                                     Prefecture__c, Postcode__c, Partofterritory__c, 
                                     POBox__c,  Name, Last_Validated__c, Id, 
                                     Floor__c, Emirate__c, District__c,  
                                     County__c, Country__c, Codiga_Postal__c, 
                                     City__c, CRMOD_ID__c, CEDEX__c, Authenticated_Address__c, 
                                     Address_id__c, Address__c, Address_4__c, Address_3__c, 
                                     Address_2__c, Address_1__c, CurrencyIsoCode
                              FROM Address__c 
                              WHERE ID IN : stAddressIds])   {
      tempAH = new Address_History__c();
      tempAH.Address_1__c  = address.Address_1__c;
      tempAH.Address_2__c  = address.Address_2__c;
      tempAH.Address_3__c  = address.Address_3__c;
      tempAH.Address_4__c  = address.Address_4__c;
      tempAH.Address_id__c = address.Address_id__c;
      tempAH.Authenticated_Address__c = address.Authenticated_Address__c;
      tempAH.CEDEX__c = address.CEDEX__c;
      tempAH.City__c = address.City__c;
      tempAH.Codiga_Postal__c = address.Codiga_Postal__c;
      tempAH.Country__c = address.Country__c;
      tempAH.County__c = address.County__c;
      tempAH.CRMOD_ID__c = address.CRMOD_ID__c;
      tempAH.CurrencyIsoCode = address.CurrencyIsoCode;
      tempAH.District__c = address.District__c;
      tempAH.Emirate__c = address.Emirate__c;
      tempAH.Floor__c = address.Floor__c;
      tempAH.Last_Validated__c = address.Last_Validated__c;
      tempAH.Part_of_territory__c = address.Partofterritory__c;
      tempAH.PO_Box__c = address.POBox__c;
      tempAH.Postcode__c = address.Postcode__c;
      tempAH.Prefecture__c = address.Prefecture__c;
      tempAH.Province__c = address.Province__c;
      tempAH.Sorting_Code__c = address.SortingCode__c;
      tempAH.State__c = address.State__c;
      tempAH.Suite__c = address.Suite__c;
      tempAH.Validation_Status__c = address.Validation_Status__c;
      tempAH.Zip__c = address.Zip__c;   
      tempAH.Original_Id__c = address.Id; 
      //lstAddressHistory.add(tempAH);
      addressHistoryMap.put(address.ID, tempAH);
    }
    if(addressHistoryMap != null && !addressHistoryMap.isEmpty() && addressHistoryMap.values().size() > 0){
      try{
        //'false' second parameter to allow partial processing of records on failure
        Database.SaveResult[] lstSaveResult = Database.insert(addressHistoryMap.values(), false);
        //checking successes and failures
        for (ID idAddress : addressHistoryMap.keySet()) {
          if (addressHistoryMap.get(idAddress).ID <> null) {
            setIdsSlaveAddressesToBeDeleted.add(idAddress);
            mergeRequestIdToAddressHistoryIdMap.put(mpMSKeyToAMRId.get(mpIdsSlaveToMaster.get(idAddress)+'-'+idAddress), addressHistoryMap.get(idAddress).Id);
          }
        }
        //capture the error message
        for (Database.SaveResult sr : lstSaveResult) {
          if (!sr.isSuccess()) {
            errMsg = String.valueOf (sr.getErrors()[0]);
            break;
          }
        }
      } catch(DMLException e){
        errMsg = e.getMessage();  //capture error message in case of exception
        System.debug('\n[AddressMerge: createAddressHistory]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AddressMerge','createAddressHistory', e.getStackTraceString(), e);
        for (Integer i = 0; i < e.getNumDml(); i++) {
            addressHistoryMap.values().get(0).addError(e.getDMLMessage(i)); 
        }
        
      } 
    }
    return setIdsSlaveAddressesToBeDeleted;
  }//END OF METHOD 'createAddressHistory'


  //===============================================================================
  // Method called by the BatchProcessAddressMergeRequest
  //===============================================================================
  private static Boolean mergeAddressesInBatch (Map <String, String> mpIdsMasterToSlaves) {
    Map<Id, Address__c> masters = new Map<Id, Address__c>();
    Map<Id, Address__c> slaves = new Map<Id, Address__c>();
    Map<Id, Account_Address__c> slaveChildAccounts = new Map<Id, Account_Address__c>();
    Map<Id, Contact_Address__c> slaveChildContacts = new Map<Id, Contact_Address__c>();
    Map<String, String> mpIdsSlavesToMaster = new Map<String, String>();
    Set<String> addressIDs = new Set<String>();
    Set<String> slaveIDs = new Set<String>();
    
    for(String masterId : mpIdsMasterToSlaves.keySet()) {
      addressIDs.add(masterId);
      for (String temp : mpIdsMasterToSlaves.get(masterId).split(':')) {
        addressIDs.add(temp);
        slaveIDs.add(temp);
      }
      for(String s : mpIdsMasterToSlaves.keySet()) {
        if (s !=  null && mpIdsMasterToSlaves.containsKey(s) && mpIdsMasterToSlaves.get(s) != null) {
          for (String slaveId : mpIdsMasterToSlaves.get(s).split(':')) {
            mpIdsSlavesToMaster.put(slaveId, s);
          }
        }
      }
      
      //mpIdsSlavesToMaster.put(mpIdsMasterToSlaves.get(masterId), masterId);
    }
    for (Address__c address: [SELECT Zip__c, Validation_Status__c, Suite__c,  
                                     State__c, SortingCode__c, Province__c, 
                                     Prefecture__c, Postcode__c, Partofterritory__c, 
                                     POBox__c,  Name, Last_Validated__c, Id, 
                                     Floor__c, Emirate__c, District__c,  
                                     County__c, Country__c, Codiga_Postal__c, 
                                     City__c, CRMOD_ID__c, CEDEX__c, Authenticated_Address__c, 
                                     Address_id__c, Address__c, Address_4__c, Address_3__c, 
                                     Address_2__c, Address_1__c, CurrencyIsoCode,
                                     (Select Id, Address__c From Contact_Addresses__r), 
                                     (Select Id, Address__c From Account_Address__r) 
                              FROM Address__c 
                              WHERE ID IN : addressIDs]) {
      //Assigning master
      if (mpIdsMasterToSlaves.containsKey(address.Id)) {
        masters.put(address.Id, address);
      }
      //Adding slaves
      if (slaveIDs.contains(address.ID)) {
        slaves.put(address.Id, address);
      }
    }
    
    
    // If master or slave are not found on the records returns false
    if (slaves.isEmpty() || masters.isEmpty()) {
      return false;
    }
    try {
      for (Address__c slave : slaves.values()) {
        // To reparent to master
        for (Account_Address__c accAdd : slave.Account_Address__r) {
          accAdd.Address__c = mpIdsSlavesToMaster.get(slave.Id);
          slaveChildAccounts.put(accAdd.Id, accAdd);
        }
        for (Contact_Address__c contAdd : slave.Contact_Addresses__r) {
          contAdd.Address__c = mpIdsSlavesToMaster.get(slave.Id);
          slaveChildContacts.put(contAdd.Id, contAdd);
        }
        processedSlaves.add(slave.ID);
      }
      if (!slaveChildAccounts.isEmpty() && slaveChildAccounts.values().size() > 0) update slaveChildAccounts.values();
      if (!slaveChildContacts.isEmpty() && slaveChildContacts.values().size() > 0) update slaveChildContacts.values();
      if (!slaves.isEmpty() && slaves.values().size() > 0) delete slaves.values();
    } catch (DMLException ex) {
      System.debug('\n[AddressMerge: mergeAddressesInBatch]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('AddressMerge','mergeAddressesInBatch', ex.getStackTraceString(), ex);
      
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        slaves.values().get(0).addError(ex.getDMLMessage(i));
      }
      return false;
    }
    return true;
  }//END OF METHOD 'mergeAddressesInBatch'

  //===============================================================================
  // Webservice to create process Address Merge Requests manually, called by custom
  // button
  // T-251322
  //===============================================================================
  webservice static void performManualMerge (List<String> lstAMRIDs) {
    system.debug('\n[AddressMerge: performManualMerge]:  +++++++++++++++++lstAMRIDs: '+lstAMRIDs);
    List<Address_Merge_Request__c> mergeRequests = [SELECT Id, 
                                               Master_Address__c,
                                               Slave_Address__c,
                                               Merge_Process_Status__c,
                                               Perform_Auto_Merge__c
                                        FROM  Address_Merge_Request__c
                                        WHERE Id IN :lstAMRIDs];
    processMergeRequests(mergeRequests);
  }//END OF METHOD 'performManualMerge'
  
  
  //===============================================================================
  // Method to be reused, and that will process a list of Address_Merge_Request__c
  //===============================================================================
  public static void processMergeRequests(List<Address_Merge_Request__c> mergeRequests) {
    Map<Id, Address_Merge_Request__c> mpIDsToAMR = new Map<Id, Address_Merge_Request__c>();
    Map<String, String> mpMasterToSlaveIDs = new Map<String, String>();
    Map<String, String> mpMasterToSlaveIDsProcessedActually = new Map<String, String>();
    Map<String, Address_Merge_Request__c> mpIDsToAMRUpdateStatusToFailed = new Map<String, Address_Merge_Request__c>();
    Set<String> stIDsAMR = new Set<String>();
    Boolean exceptionOccured = false;
    String tempKey = '';
    for (Address_Merge_Request__c amr : mergeRequests) {
      //check if the record has been already processed or not
      if (amr.Merge_Process_Status__c.equalsIgnoreCase(Constants.MERGE_PROCESS_STATUS_PENDING) ) {
        if (amr.Master_Address__c != null && amr.Slave_Address__c != null) {
          if (!mpMasterToSlaveIDs.containsKey(amr.Master_Address__c)) {
            mpMasterToSlaveIDs.put (amr.Master_Address__c, amr.Slave_Address__c);
          }
          else {
            mpMasterToSlaveIDs.put (amr.Master_Address__c, mpMasterToSlaveIDs.get (amr.Master_Address__c)+':'+amr.Slave_Address__c);
          }
          mpMSKeyToAMRId.put (amr.Master_Address__c+'-'+amr.Slave_Address__c, amr.Id);
          mpIDsToAMR.put (amr.Id, amr);
        }
      }
    }
      //database savepoint
      Savepoint spoint = Database.setSavepoint();
      //process the records
      if (!mpMasterToSlaveIDs.isEmpty()) {
        mpMasterToSlaveIDsProcessedActually = mergeAddresses(mpMasterToSlaveIDs);
        batchEndTime = datetime.now();
      }
      //update the Address_Merge_Request which were processed successfully
      //T-249253
      if (mpMasterToSlaveIDsProcessedActually != null && !mpMasterToSlaveIDsProcessedActually.isEmpty()) {
        for (String masterId : mpMasterToSlaveIDsProcessedActually.keySet()) {
          for (String slaveId : mpMasterToSlaveIDsProcessedActually.get(masterId).split(':')) {
            if (mpMSKeyToAMRId.containsKey (masterId+'-'+slaveId)) {
              stIDsAMR.add(mpMSKeyToAMRId.get(masterId+'-'+slaveId));
            }
          }
        }
        for (String amrId : stIDsAMR) {
          if (mpIDsToAMR.containsKey(amrId) && mpIDsToAMR.get(amrId) != null){
            // mpIDsToAMR.get(amrId).Merge_Type__c = mergeType; NLG Removing Feb 28th 2014
            //T-249253
            mpIDsToAMR.get(amrId).Merge_Process_Status__c = Constants.MERGE_PROCESS_STATUS_SUCCESS;
            mpIDsToAMR.get(amrId).Start_Processing_Time__c = batchStartTime;
            mpIDsToAMR.get(amrId).End_Processing_Time__c = batchEndTime;
            mpIDsToAMR.get(amrId).Slave_Address_History__c = mergeRequestIdToAddressHistoryIdMap.get(amrId);
            //set slave to null as it has been deleted
            mpIDsToAMR.get(amrId).Slave_Address__c = null;
          }
        }

        for (Address_Merge_Request__c amr : mpIDsToAMR.values()) {
          String amrId = amr.ID;
          if (processedSlaves.contains(mpIDsToAMR.get(amrId).Slave_Address__c)) {
            mpIDsToAMR.get(amrId).Merge_Process_Status__c = Constants.MERGE_PROCESS_STATUS_SUCCESS;
            mpIDsToAMR.get(amrId).Start_Processing_Time__c = batchStartTime;
            mpIDsToAMR.get(amrId).End_Processing_Time__c = batchEndTime;
            mpIDsToAMR.get(amrId).Slave_Address_History__c = mergeRequestIdToAddressHistoryIdMap.get(amrId);
            //set slave to null as it has been deleted
            mpIDsToAMR.get(amrId).Slave_Address__c = null;
          }
        }

        //update Address Merge Request
        if (!mpIDsToAMR.isEmpty()) {
          try {
            update (mpIDsToAMR.values());
          }catch (DMLException e) {
            exceptionOccured = true;
            Database.rollback(spoint);
            System.debug('\n[AddressMerge: performManualMerge]: ['+e.getMessage()+']]');
            apexLogHandler.createLogAndSave('AddressMerge','performManualMerge', e.getStackTraceString(), e);
            for (Integer i=0; i < e.getNumDml(); i++) {
                mpIDsToAMR.values().get(0).addError(e.getDMLMessage(i));
            }
            
          }
        }
      }
      //update the Address_Merge_Request__c records which were not processed successfully
      //set the Merge_Process_Status__c to "Failure"
      //fill up the Failure_Reason__c with the error message
      for (String masterId : mpMasterToSlaveIDs.keySet()) {
        for (String slaveId : mpMasterToSlaveIDs.get(masterId).split(':')) {
          if ((mpMasterToSlaveIDsProcessedActually == null
                          ||  !mpMasterToSlaveIDsProcessedActually.containsKey(masterId)
                          ||  !mpMasterToSlaveIDsProcessedActually.get(masterId).contains(slaveId))
              || exceptionOccured) {
            if (mpMSKeyToAMRId.containsKey(masterId+'-'+slaveId)
                 && mpIDsToAMR.containsKey(mpMSKeyToAMRId.get(masterId+'-'+slaveId))) {
              tempKey = mpMSKeyToAMRId.get(masterId+'-'+slaveId);
              mpIDsToAMR.get(tempKey).Merge_Process_Status__c = Constants.MERGE_PROCESS_STATUS_FAILURE;
              mpIDsToAMR.get(tempKey).Failure_Reason__c = errMsg;
              mpIDsToAMR.get(tempKey).Start_Processing_Time__c = batchStartTime;
              mpIDsToAMR.get(tempKey).End_Processing_Time__c = batchEndTime;
              mpIDsToAMRUpdateStatusToFailed.put (tempKey, mpIDsToAMR.get(tempKey));
            }
          }
        }
      } 
      //update Address Merge Request records in case of failure
      if (!mpIDsToAMRUpdateStatusToFailed.isEmpty()) {
        try {
          update (mpIDsToAMRUpdateStatusToFailed.values());
        }catch (DMLException e) {
          System.debug('\n[AddressMerge: performManualMerge]: ['+e.getMessage()+']]');
          apexLogHandler.createLogAndSave('AddressMerge','performManualMerge', e.getStackTraceString(), e);
          for (Integer i=0; i < e.getNumDml(); i++) {
            mpIDsToAMRUpdateStatusToFailed.values().get(0).addError(e.getDMLMessage(i));
          }
        }
      }
  }
  
  //===============================================================================
  // Webservice to merge directly
  //===============================================================================
  webservice static String mergeAddressWebservice(String masterId, List<String> slaveIDs, String mergeType) {
    Set<ID> addrsIDSet = new Set<ID>();
    Map<ID, Address__c> addressMap = new Map<ID, Address__c>();
    List<Account_Address__c> accAddressList = new List<Account_Address__c>();
    List<Contact_Address__c> conAddressList = new List<Contact_Address__c>();
    Map<Id, Address__c> slaves = new Map<Id, Address__c>();
    Boolean isError = false;

    String responseString ;
    system.debug('>>>>>Master: '+ masterId);
    system.debug('>>>>>Slaves: '+ slaveIDs);
    system.debug('>>>>>MergeType: '+ mergeType);

    // Checking MASTER 
    if (String.isBlank(masterId)) {
      // error message
      errorCode = 'INVALID_ID_FIELD';
      errorMsg = Label.Address_Merge_Missing_MasterId;
      isError = true;
    }

    // Checking SLAVES 
    System.debug('slaveIDs.size() ' +slaveIDs.size() );
    // slaveIDS must not be null or blank, and must not have more than 2 entries. 
    // If blank or 3+ entries in slaveIDS, return false.
    if (slaveIDs.isEmpty() || slaveIDs.size() > 2) {
      // error message
      errorCode = 'INVALID_ID_FIELD';
      errorMsg = Label.Address_Merge_Invalid_Id_Field;
      isError = true;  
    }

    //Invalid SlaveID scenario - returns errorCode = 'MALFORMED_ID' errorMsg = Label.Address_Merge_Bad_Id_In_Record_Merge
    if (checkIdFormatInvalid(masterId) || (slaveIDs.size() > 0 && checkSlavesIDFormat(slaveIDs))) {
      isError = true;
    }

    //If slaveId is null and mergeType not null
    if (slaveIds.size() == 0 || slaveIds.get(0).equalsIgnoreCase('Boomi')) {
        // error message
        errorCode = 'INVALID_ID_FIELD';
        errorMsg = Label.Address_Merge_Missing_Id;
        isError = true;
    }
    /*  //If slaveId is null and mergeType not null
      if (mergeType != null &&  (slaveIds.size() == 0 || slaveIds.get(0).equalsIgnoreCase('Boomi'))) {
        // error message
        errorCode = 'MISSING_ID';
        errorMsg = Label.Address_Merge_Missing_Id;
        isError = true;
      }   */

    // At this point we will return false if there was any error
    if (isError) {
      responseString = getErrorResponseString(masterId, slaveIds);
      system.debug('responseString>>' +responseString);
      return responseString;
    }


    Savepoint sp = Database.setSavepoint();
    try {
      addrsIDSet.add(masterId);
      for (String slaveId : slaveIDs) {
        addrsIDSet.add((ID)slaveId);
      }
      addressMap = getAddresses(addrsIDSet);

      //Fetch child records for slaves
      for (Address__c address : [SELECT ID,
                                  (Select Id, Address__c From Contact_Addresses__r), 
                                  (Select Id, Address__c From Account_Address__r) 
                                 FROM Address__c 
                                 WHERE ID IN : addressMap.keySet() AND ID != :masterId]){
         
        //Updating parent for Account Address from slave to master.
        for (Account_Address__c accAdd : address.Account_Address__r) {
          accAdd.Address__c = masterId;
          accAddressList.add(accAdd);
        }
        //Updating parent for Contact Address from slave to master.
        for (Contact_Address__c conAdd : address.Contact_Addresses__r) {
          conAdd.Address__c = masterId;
          conAddressList.add(conAdd);
        }
        //Adding slaves
        for (String slaveId : slaveIDs) {
          String addressId = (String) address.Id;
          system.debug('\n>>>slaves Id:' + slaveId.substring(0, 15) + '  and addressId: '+ addressId.substring(0, 15));
          if (slaveId.substring(0, 15).equalsIgnoreCase(addressId.substring(0, 15))) {
            slaves.put((ID)slaveId, address);
          }
        }
        system.debug('\n>>>slaves Map:' + slaves);
    }

    System.debug('slaves.size()>>>' +slaves.size() + ' & slaveIDs.size()>>> ' + slaveIDs.size());
    // if queried slaves are missing (ie deleted) we error out immediately - prior to the merge
    if (slaves.size() != slaveIDs.size()) {
      errorCode = 'ENTITY_DELETED';
      errorMsg = Label.Address_Merge_Entity_is_Deleted;
      isError = true;
      responseString = getErrorResponseString(masterId, slaveIds);
      system.debug('responseString>>' +responseString);
      return responseString;
    }
    try {
      //Updating account addresses to link to new Master
      if (accAddressList.size() > 0) {
        update accAddressList;
      }
      //Update contact addresses to link to new Master
      if (conAddressList.size() > 0) {
        update conAddressList;
      }
    } catch(Exception ex) {
      // error message
      errorCode = 'CANNOT_REPARENT_RECORD';
      errorMsg = Label.Address_Merge_Cannot_Reparent_Record;
      isError = true;
      responseString = getErrorResponseString(masterId, slaveIds);
      system.debug('responseString>>' +responseString);
      return responseString;
    } 

    //Delete slave records if the merge is successful
    try { 
      if (!slaves.isEmpty() && slaves.values().size() > 0) {
        delete slaves.values();
      }
    } catch(Exception e) {
        // error message if there is no merge
        errorCode = 'DELETE_FAILED';
        errorMsg = Label.Address_Merge_Delete_Failed;
        isError = true;
        responseString = getErrorResponseString(masterId, slaveIds);
        system.debug('responseString>>' +responseString);
        return responseString;
    }
  } catch(Exception e) {
        Database.rollback(sp);
        System.debug('\n[AddressMerge: mergeAddressWebserviceBis]: ['+e.getMessage()+']]');
        apexLogHandler.createLogAndSave('AddressMerge','mergeAddressWebserviceBis', e.getStackTraceString(), e);
        for (Integer i=0; i < e.getNumDml(); i++) {
          addressMap.values().get(0).addError(e.getDMLMessage(i));
        }
        
        // error message
        errorCode = 'MERGE_FAILED';
        errorMsg = Label.Address_Merge_Failed;
        isError = true;
        responseString = getErrorResponseString(masterId, slaveIds);
        system.debug('responseString>>' +responseString);
        return responseString;
    }
    if (isError) {
      responseString = getErrorResponseString(masterId, slaveIds);
      system.debug('responseString>>' +responseString);
      return responseString;
    }  

    // success message
    responseString = '<?xml version="1.0" encoding="UTF-8"?>'+
             '<mergeRequest>'+
             '<id>'+masterId+'</id>'+
             '<success>true</success>'+
             '<mergedRecordIds>'+slaveIDs+'</mergedRecordIds>'+
             '</mergeRequest>';

    // return response 
    return responseString;
  }
  
  private static Boolean checkIdFormatInvalid(String recordId) {
    if (!String.isBlank(recordId) && recordId.length() != 15 && recordId.length() != 18) {
      errorCode = 'MALFORMED_ID';
      errorMsg = Label.Address_Merge_Malformed_Id;
      return true;
    }
    return false;
  }

  private static Boolean checkSlavesIDFormat(List<String> slaveIds) {
    Boolean chkSlave1, chkSlave2 = false;
    if (slaveIDs.size() == 1) {
      chkSlave1 = checkIdFormatInvalid(slaveIDs.get(0));
    }
    if (SlaveIDs.size() > 1){
      chkSlave1 = checkIdFormatInvalid(slaveIDs.get(0));
      chkSlave2 = checkIdFormatInvalid(slaveIDs.get(1));
    }
    if (chkSlave1 == true) {
      // error message for slave1
      errorMsg = Label.Address_Merge_Bad_Id_In_Record_Merge + slaveIDs.get(0) ;
      return true; 
    }
    else if (chkSlave2 == true) {
      // error message for slave2
      errorMsg = Label.Address_Merge_Bad_Id_In_Record_Merge + slaveIDs.get(1);
      return true;
    }
    return false;
  }

  private static String getErrorResponseString(String masterId, List<String> slaveIds) {
    return '<?xml version="1.0" encoding="UTF-8"?>' + 
                            '<mergeRequest>'+ 
                            '<id>'+ masterId + '</id>' +
                            '<success>false</success>' +
                            '<errors>'+
                            '<error><statusCode>'+errorCode+'</statusCode>'+
                            '<message>'+errorMsg+'</message>'+
                            '</error>' +
                            '</errors>'+
                            '<mergedRecordIds>'+slaveIDs+'</mergedRecordIds>'+
                            '</mergeRequest>' ;
  }
  //===============================================================================
  // Webservice to create buld address merge requests
  //===============================================================================
  webservice static boolean mergeAddressWebserviceManual (String masterId, List<String> slaveIDs, String mergeType) {
    List<Address_Merge_Request__c> addressMergeRequestList = new List<Address_Merge_Request__c> ();
    Address_Merge_Request__c addressMergeReq;

    Map<ID, Address__c> addressMap = new Map<ID, Address__c>();
    Set<ID> addrsIDSet = new Set<ID>();
    
    if (String.isBlank(masterId) || slaveIDs.isEmpty()) {
      System.debug('\n[AddressMerge: addressMergeRequest]: [To create Address Merge Request, both master and slave IDs are required.]]');
      return null;
    }
    
    masterId = (ID)masterId;
    addrsIDSet.add(masterId);
    for (String slaveId : slaveIDs) {
      addrsIDSet.add((ID)slaveId);
    }
    
    try {
      addressMap = getAddresses(addrsIDSet);

      if (addressMap.keySet().size() < 2) {
        System.debug('\n[AddressMerge: addressMergeRequest]: [There is no record found for master or slave ID provided.]]');
        return null;
      }
      
      if (!String.isEmpty(masterId) && !slaveIDs.isEmpty()) {
        for (String slaveId : slaveIDs) {
          addressMergeReq = new Address_Merge_Request__c();
          addressMergeReq = addressMergeRequest (masterId, (ID)slaveId, mergeType, addressMap);
          addressMergeRequestList.add(addressMergeReq);
        }
      }
      
      if (!addressMergeRequestList.isEmpty()) {
        insert addressMergeRequestList; 
      }
    } catch (DMLException ex) {
      System.debug('\n[AddressMerge: mergeAddressWebservice]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('AddressMerge','mergeAddressWebservice', ex.getStackTraceString(), ex);
      for (Integer i=0; i < ex.getNumDml(); i++) {  
        addressMergeRequestList.get(0).addError(ex.getDMLMessage(i)); 
      }  
      return false; 
    }
    return true;
  }
  
  
  //===============================================================================
  // Method to create Address merge requests, called by webservice
  //===============================================================================
  public static Address_Merge_Request__c addressMergeRequest (ID masterId, ID slaveId, String origin, Map<ID, Address__c> addressMap) {
    Address_Merge_Request__c addMergeReqObj = new Address_Merge_Request__c();

    try {

      addMergeReqObj.Master_Address_SFDC_Id__c = masterId;
      addMergeReqObj.Slave_Address_SFDC_Id__c = slaveId;
      addMergeReqObj.Merge_Process_Status__c = Constants.MERGE_PROCESS_STATUS_PENDING;
      
      // Will vary depending on who called the webservice
      if (origin.equalsIgnoreCase(Constants.BOOMI)) {
        addMergeReqObj.Merge_Type__c = Constants.MERGE_TYPE_BOOMI;
        addMergeReqObj.Perform_Auto_Merge__c = true;
      } else if (origin.equalsIgnoreCase(Constants.MANUAL)) {
        addMergeReqObj.Merge_Type__c = Constants.MERGE_TYPE_MANUAL;
      }

      // Assigning master ID
      if (addressMap.containsKey(masterId)) {
        System.debug('--addressMap.get(masterId)-->'+addressMap.get(masterId));
        addMergeReqObj.Master_Address__c = addressMap.get(masterId).ID;
        addMergeReqObj.Master_Address_String__c = addressMap.get(masterId).Address_id__c;
      }
      // Assigning slave ID
      if (addressMap.containsKey(slaveId)) {
        addMergeReqObj.Slave_Address__c = addressMap.get(slaveId).ID;
        addMergeReqObj.Slave_Address_String__c = addressMap.get(slaveId).Address_id__c;
      }

      return addMergeReqObj;
    } catch (Exception ex) {
      System.debug('\n[AddressMerge: addressMergeRequest]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('AddressMerge','addressMergeRequest', ex.getStackTraceString(), ex);
      addressMap.values().get(0).addError(ex.getMessage()); 
      return null;
      
    }
  }//END OF METHOD 'addressMergeRequest'
  
  //Returns map of address.
  private static Map<ID, Address__c> getAddresses (Set<ID> addIDSet) {
    Map<ID, Address__c> adrsMap = new Map<ID, Address__c>();
    for (Address__c addrs : [SELECT ID, Address_id__c FROM Address__c WHERE ID IN : addIDSet]) {
      if (!adrsMap.containsKey(addrs.ID)) {
        adrsMap.put(addrs.ID, addrs);
      }
    }
    return adrsMap;
  }
}