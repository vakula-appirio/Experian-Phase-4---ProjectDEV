/**=====================================================================
 * Appirio, Inc
 * Name: ConfidentialInformationTriggerHandler
 * Description: T-266931: Synching Confidential Information Share & OpportunityTeamMembers
 *                        Handler Class for ConfidentialInformationTrigger
 * Created Date: Mar 28th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified          Modified By                  Description of the update
 * Mar 31, 2014           Nathalie Le Guay (Appirio)   rename to ConfidentialInformationTriggerHandler
 *                                                     Add brackets to one line if-statements, set tabs to 2 spaces
 * Apr 01, 2014           Naresh Kr Ojha               Getting access level from OpportunityShares bc SFDC OpportunityTeamMember
 *                                                     is buggy (cannot properly read the access level of the OTM record)
 * Apr 07,2014            Nathalie Le Guay             Removing 'with sharing'
 * Apr 08, 2014           Arpita Bose(Appirio)         T-269372: Added addError()in try-catch block
 * May 01, 2014           Arpita Bose                  Updated catch(Exception) to catch(DMLException)
 * Nov 13th, 2014         Nathalie Le Guay             I-138911: made it without sharing - with sharing caused issues with Sharing records creation (rowCause)
 * Feb 10th, 2015         Arpita Bose                  T-360092: Added method afterDelete(), afterUnDelete() and updateConInfoCountOnContract()
 * Feb 11th, 2015         Arpita Bose                  T-360092: Added method afterUpdate()
 * Feb 24th, 2015         Gaurav Kumar Chadha          T-364943: Replicated Synchronize Confidential Information Share for Account(Added syncAccountTeam method)
 * Feb 26th, 2015         Paul Kissick                 Case #570783 - Adding check for Active users only
 * Mar 12th, 2015         Gaurav Kumar Chadha          Added User.IsActive in the Soql query as test class was failing
 * May 15h, 2015          Terri Jiles                  I-165234: Modified Method createConfidentialInfoShare to include in query: WHERE User.IsActive = True 
 =====================================================================*/
public without sharing /*with sharing*/ class ConfidentialInformationTriggerHandler {
  //============================================================================
  // After Insert call
  //============================================================================
  public static void afterInsert (Map<ID, Confidential_Information__c> newMap) {
    system.debug('*********newMap-------'+newMap);
    synchOpportunityTeam(newMap, null);
    //T-364943
    syncAccountTeam(newMap, null);
    //T-360092
    updateConInfoCountOnContract(newMap.values(), null);
    updateCICount(newMap, null);
  }

  //============================================================================
  // After Update call
  //============================================================================
  public static void afterUpdate(Map<ID, Confidential_Information__c> newMap,
                                 Map<ID, Confidential_Information__c> oldMap) {
    synchOpportunityTeam(newMap, oldMap);
    system.debug('*********newMap-------'+newMap);
    //T-364943
    syncAccountTeam(newMap, oldMap);
    //T-360092
    updateConInfoCountOnContract(newMap.values(), oldMap);
  }

  //============================================================================
  // T-360092: After Delete call
  //============================================================================
  public static void afterDelete(Map<ID, Confidential_Information__c> newMap, Map<ID, Confidential_Information__c> oldMap) {
    updateConInfoCountOnContract(null, oldMap);
    updateCICount(newMap, oldMap);
  }

  //============================================================================
  // T-360092: After UnDelete call
  //============================================================================
  public static void afterUnDelete(List<Confidential_Information__c> newList) {
    updateConInfoCountOnContract(newList, null);
  }

  //============================================================================
  // Synching Account team members
  //============================================================================
  public static void syncAccountTeam(Map<ID, Confidential_Information__c> newMap,
                                       Map<ID, Confidential_Information__c> oldMap){
    Set<ID> syncAccountIDs = new Set<ID>();
    Set<ID> unSyncConfInfos = new Set<ID>();
    List<Confidential_Information__c> filteredConfInfos = new List<Confidential_Information__c>();

    // Filtering synch enabled records to process
    for (Confidential_Information__c confInfo : newMap.values()) {
      if (confINfo.Account__c!= null && confINfo.Synch_Account_Team_Members__c == true
          && (oldMap != null ? confInfo.Synch_Account_Team_Members__c != oldMap.get(confInfo.ID).Synch_Account_Team_Members__c : true)) {
        // Account ID adding to set to synch Team
        syncAccountIDs.add(confInfo.Account__c);
        filteredConfInfos.add(confInfo);
      }
      // Remove shares if Synch is false
      if (oldMap != null && confInfo.Synch_Account_Team_Members__c == false
                         && oldMap.get(confInfo.ID).Synch_Account_Team_Members__c == true) {
        unSyncConfInfos.add(confInfo.ID);
      }
    }

    // Create confidential information shares
    if (syncAccountIDs.size() > 0 && filteredConfInfos.size() > 0) {
      createConfidentialInfoShareAcc(syncAccountIDs, filteredConfInfos);
    }
    // Remove confidential information shares
    if (unSyncConfInfos.size() > 0) {
      removeConfidentialInfoShareAcc(unSyncConfInfos);
    }
  }

  //============================================================================
  // Remove confidential information shares
  //============================================================================
  public static void removeConfidentialInfoShareAcc(Set<ID> unSyncConfInfos) {
    List<Confidential_Information__Share> confInfoShares = new List<Confidential_Information__Share>();
    try {
      for (Confidential_Information__Share share : [SELECT Id
                                                    FROM Confidential_Information__Share
                                                    WHERE ParentId IN : unSyncConfInfos
                                                    AND RowCause =: Constants.ROWCAUSE_ACCOUNT_TEAM]) {
        confInfoShares.add(share);
      }
      // delete confidential information shares
      if (confInfoShares.size() > 0) {
        delete confInfoShares;
      }
    } catch (DMLException ex) {
      System.debug('\n[ConfidentialsInformationTriggerHandler: removeConfidentialInfoShareAcc]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('ConfidentialsInformationTriggerHandler','removeConfidentialInfoShareAcc', ex.getStackTraceString(), ex);
      for (Integer i=0; i < ex.getNumDml(); i++) {
        confInfoShares.get(0).addError(ex.getDMLMessage(i));
      }
    }
  }

  //============================================================================
  // Create Confidential Information shares
  //============================================================================
  public static void createConfidentialInfoShareAcc(Set<ID> syncAccountIDs, List<Confidential_Information__c> filteredConfInfos) {

    Map<String, Account> accID_accMap = new Map<String, Account>();
    Map<String, AccountShare> accIdUid_AccShareMap = new Map<String, AccountShare>();

    try {
      // Getting Account share record
      // May 28th, 2015 - TTK - I-164234 added  WHERE User.IsActive = True to query
      for (Account acc : [SELECT Id, (Select AccountId, UserOrGroupId, AccountAccessLevel, RowCause From Shares),
                                       (SELECT Id, AccountId, UserId, User.Name, AccountAccessLevel
                                        FROM AccountTeamMembers WHERE User.IsActive = True)
                                FROM Account
                                WHERE Id IN: syncAccountIDs]) {
        accID_accMap.put(acc.ID, acc);
        for (accountShare accs : acc.Shares) {
          if (!accIdUid_AccShareMap.containsKey(acc.ID + '~~' + accs.UserOrGroupId)) {
            accIdUid_AccShareMap.put(acc.ID + '~~' + accs.UserOrGroupId, accs);
          }
        }
      }

      // Creating the Confidential_Information__Share according to the AccountShare
      List<Confidential_Information__Share> confInfoShares = new List<Confidential_Information__Share>();
      Confidential_Information__Share newConfInfoShare;
      for (Confidential_Information__c confInfo : filteredConfInfos) {
        for (AccountTeamMember teamMember : accID_accMap.get(confInfo.Account__c).AccountTeamMembers) {
          String accessLevel = Constants.ACCESS_LEVEL_READ; //Default to be set.

          if (accIdUid_AccShareMap.containsKey(teamMember.AccountID + '~~' + teamMember.UserId)) {
            accessLevel = accIdUid_AccShareMap.get(teamMember.AccountID + '~~' + teamMember.UserId).AccountAccessLevel;
          }
          // All access level is not on the ConfInfoShare picklist so it will have edit.
          if (accessLevel == Constants.ACCESS_LEVEL_ALL) {
            accessLevel = Constants.ACCESS_LEVEL_EDIT;
          }

          System.debug('[ConfidentialInformationTriggerHandler:CreateShares][~~~~teamMember.UserId~~~]:'+teamMember.UserId+'--[~~~accessLevel~~~]:'+accessLevel);

          newConfInfoShare = new Confidential_Information__Share();

          newConfInfoShare.AccessLevel    = accessLevel;
          newConfInfoShare.ParentId       = confInfo.Id;
          newConfInfoShare.RowCause       = Constants.ROWCAUSE_ACCOUNT_TEAM;
          newConfInfoShare.UserOrGroupId  = teamMember.UserId;
          confInfoShares.add(newConfInfoShare);
          System.debug('\n[ConfidentialInformationTriggerHandler:CreateShares]Creating new Share: '+ newConfInfoShare);
        }
      }
      // Insert confidentials information share records
      if (!confInfoShares.isEmpty()) {
        insert confInfoShares;
      }
    } catch (DMLException ex) {
       System.debug('\n[ConfidentialsInformationTriggerHandler: createConfidentialInfoShareAcc]: ['+ex.getMessage()+']]');
       apexLogHandler.createLogAndSave('ConfidentialsInformationTriggerHandler','createConfidentialInfoShareAcc', ex.getStackTraceString(), ex);
       for (Integer i=0; i < ex.getNumDml(); i++) {
        filteredConfInfos.get(0).addError(ex.getDMLMessage(i));
      }
     }
   }

  //============================================================================
  // Synching opportunity team members
  //============================================================================
  public static void synchOpportunityTeam(Map<ID, Confidential_Information__c> newMap,
                                           Map<ID, Confidential_Information__c> oldMap) {
    Set<ID> syncOpptyIDs = new Set<ID>();
    Set<ID> unSyncConfInfos = new Set<ID>();
    List<Confidential_Information__c> filteredConfInfos = new List<Confidential_Information__c>();

    // Filtering synch enabled records to process
    for (Confidential_Information__c confInfo : newMap.values()) {
      if (confINfo.Opportunity__c != null && confINfo.Synch_Opportunity_Team_Members__c == true
          && (oldMap != null ? confInfo.Synch_Opportunity_Team_Members__c != oldMap.get(confInfo.ID).Synch_Opportunity_Team_Members__c : true)) {
        // Oppty ID adding to set to synch Team
        syncOpptyIDs.add(confInfo.Opportunity__c);
        filteredConfInfos.add(confInfo);
      }
      // Remove shares if Synch is false
      if (oldMap != null && confINfo.Synch_Opportunity_Team_Members__c == false
                         && oldMap.get(confInfo.ID).Synch_Opportunity_Team_Members__c == true) {
        unSyncConfInfos.add(confInfo.ID);
      }
    }

    // Create confidential information shares
    if (syncOpptyIDs.size() > 0 && filteredConfInfos.size() > 0) {
      createConfidentialInfoShare(syncOpptyIDs, filteredConfInfos);
    }
    // Remove confidential information shares
    if (unSyncConfInfos.size() > 0) {
      removeConfidentialInfoShare(unSyncConfInfos);
    }
  }

  //============================================================================
  // Remove confidential information shares
  //============================================================================
  public static void removeConfidentialInfoShare(Set<ID> unSyncConfInfos) {
    List<Confidential_Information__Share> confInfoShares = new List<Confidential_Information__Share>();
    try {
      for (Confidential_Information__Share share : [SELECT Id
                                                    FROM Confidential_Information__Share
                                                    WHERE ParentId IN : unSyncConfInfos
                                                    AND RowCause =: Constants.ROWCAUSE_OPPTY_TEAM]) {
        confInfoShares.add(share);
      }
      // delete confidentials information shares
      if (confInfoShares.size() > 0) {
        delete confInfoShares;
      }
    } catch (DMLException ex) {
      System.debug('\n[ConfidentialsInformationTriggerHandler: removeConfidentialInfoShare]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('ConfidentialsInformationTriggerHandler','removeConfidentialInfoShare', ex.getStackTraceString(), ex);
      for (Integer i=0; i < ex.getNumDml(); i++) {
        confInfoShares.get(0).addError(ex.getDMLMessage(i));
      }
    }
  }

  //============================================================================
  // Create Confidentials Information shares
  //============================================================================
  public static void createConfidentialInfoShare(Set<ID> syncOpptyIDs, List<Confidential_Information__c> filteredConfInfos) {

    Map<String, Opportunity> opptyID_opptyMap = new Map<String, Opportunity>();
    Map<String, OpportunityShare> oppIdUid_oppShareMap = new Map<String, OpportunityShare>();

    // String confInfoOpptyRT_Id = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CONFIDENTIAL_INFO, Constants.RECORDTYPE_CONF_INFO_OPPTY);

    try {
      // Getting opportunity share record
      for (Opportunity oppty : [SELECT Id, (Select OpportunityId, UserOrGroupId, OpportunityAccessLevel, RowCause From Shares),
                                       (SELECT Id, OpportunityId, UserId, User.IsActive ,  User.Name, OpportunityAccessLevel
                                        FROM OpportunityTeamMembers)
                                FROM Opportunity
                                WHERE Id IN: syncOpptyIDs]) {
        opptyID_opptyMap.put(oppty.ID, oppty);
        for (OpportunityShare os : oppty.Shares) {
          if (!oppIdUid_oppShareMap.containsKey(oppty.ID + '~~' + os.UserOrGroupId)) {
            oppIdUid_oppShareMap.put(oppty.ID + '~~' + os.UserOrGroupId, os);
          }
        }
      }

      // Creating the Confidential_Information__Share according to the OpportunityShare
      List<Confidential_Information__Share> confInfoShares = new List<Confidential_Information__Share>();
      Confidential_Information__Share newConfInfoShare;
      for (Confidential_Information__c confInfo : filteredConfInfos) {
        for (OpportunityTeamMember teamMember : opptyID_opptyMap.get(confInfo.Opportunity__c).OpportunityTeamMembers) {
          String accessLevel = Constants.ACCESS_LEVEL_READ; //Default to be set.
          // PK: Case #570783 - Adding check for Active users only
          if (!teamMember.User.IsActive) {
            System.debug('[ConfidentialInformationTriggerHandler:CreateShares][~~~~teamMember.UserId~~~]:'+teamMember.UserId+'-- IS NOT ACTIVE');
            continue;
          }
          if (oppIdUid_oppShareMap.containsKey(teamMember.OpportunityID + '~~' + teamMember.UserId)) {
            accessLevel = oppIdUid_oppShareMap.get(teamMember.OpportunityID + '~~' + teamMember.UserId).OpportunityAccessLevel;
          }
          // All access level is not on the ConfInfoShare picklist so it will have edit.
          if (accessLevel == Constants.ACCESS_LEVEL_ALL) {
            accessLevel = Constants.ACCESS_LEVEL_EDIT;
          }

          System.debug('[ConfidentialInformationTriggerHandler:CreateShares][~~~~teamMember.UserId~~~]:'+teamMember.UserId+'--[~~~accessLevel~~~]:'+accessLevel);

          newConfInfoShare = new Confidential_Information__Share();

          newConfInfoShare.AccessLevel    = accessLevel;
          newConfInfoShare.ParentId       = confInfo.Id;
          newConfInfoShare.RowCause       = Constants.ROWCAUSE_OPPTY_TEAM;
          newConfInfoShare.UserOrGroupId  = teamMember.UserId;
          confInfoShares.add(newConfInfoShare);
          System.debug('\n[ConfidentialInformationTriggerHandler:CreateShares]Creating new Share: '+ newConfInfoShare);
        }
      }
      // Insert confidentials information share records
      if (!confInfoShares.isEmpty()) {
        insert confInfoShares;
      }
    } catch (DMLException ex) {
       System.debug('\n[ConfidentialsInformationTriggerHandler: createConfidentialInfoShare]: ['+ex.getMessage()+']]');
       apexLogHandler.createLogAndSave('ConfidentialsInformationTriggerHandler','createConfidentialInfoShare', ex.getStackTraceString(), ex);
       for (Integer i=0; i < ex.getNumDml(); i++) {
        filteredConfInfos.get(0).addError(ex.getDMLMessage(i));
      }
     }
   }

   //===========================================================================
   // T-360092 : Method to count Confidential_Information records on Contract__c
   //===========================================================================
   public static void updateConInfoCountOnContract(List<Confidential_Information__c> newList,
                                                     Map<ID, Confidential_Information__c> oldMap){
     Set<Id> contractIds = new Set<Id>();
     Map<Id, Contract__c> mapContractRecToUpdate = new Map<Id, Contract__c>();
     List<Confidential_Information__c> lstConInfoRec = new List<Confidential_Information__c>();
     List<Confidential_Information__c> conInfoList;
     Boolean isInsert = Trigger.isInsert;
     Boolean isUpdate = Trigger.isUpdate;
     Boolean isDelete = Trigger.isDelete;
     Boolean isUnDelete = Trigger.isUnDelete;

     // If we are inserting, updating, or undeleting, use the new ID values
     //gather all the Contract__c Ids from Confidential_Information__c and store in Set
     if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete){
       for (Confidential_Information__c conInfo : newList){
         if (conInfo.Contract__c <> null ||
               (oldMap != null && conInfo.Contract__c <> oldMap.get(conInfo.ID).Contract__c)) {
           contractIds.add(conInfo.Contract__c);
         }
       }
     }
     // If we are updating, Contract__c might change, so include that as well as deletes
     if (Trigger.isUpdate || Trigger.isDelete) {
       for (Confidential_Information__c conInfo : oldMap.values()){
         if (conInfo.Contract__c != null) {
           contractIds.add(conInfo.Contract__c);
         }
       }
     }
     if (contractIds == null || contractIds.size() == 0) {
       return;
     }
     for (Id cntrctId : contractIds) {
       mapContractRecToUpdate.put(cntrctId, new Contract__c(Id = cntrctId, Attachment_Count__c = 0));
     }

     //Query all Confidential_Information__c for all contractIds and update Attachment_Count__c
     for (Confidential_Information__c ci : [SELECT Id, Contract__c
                                            FROM Confidential_Information__c
                                            WHERE Contract__c IN :contractIds]) {
         mapContractRecToUpdate.get(ci.Contract__c).Attachment_Count__c++;
     }

     //update count on Contract__c object
     try {
       if (mapContractRecToUpdate.values().size() > 0) {
         Database.update(mapContractRecToUpdate.values());
       }
     } catch (DMLException e){
          system.debug('[ConfidentialInformationTriggerHandler: updateConInfoCountOnContract] Exception: ' + e.getMessage());
          ApexLogHandler.createLogAndSave('ConfidentialInformationTriggerHandler','updateConInfoCountOnContract', e.getStackTraceString(), e);
          for (Integer i=0; i < e.getNumDml(); i++) {
            newList.get(0).addError(e.getDMLMessage(i));
          }
     }
  }

  // SHOULD BE MERGED WITH updateConInfoCountOnContract()
  //============================================================================
  // Update Opportunity field 
  //============================================================================
  public static void updateCICount(Map<ID, Confidential_Information__c> newMap,
                                           Map<ID, Confidential_Information__c> oldMap) {
    
    Set<ID> confInfoOpptyIDs = new Set<ID>();
    List<Opportunity> opptList = new List<Opportunity>();
    
    // If newMap is null then use oldMap
  if (newMap == null) {
    newMap = oldMap;    
  }
    for (Confidential_Information__c confInfo : newMap.values()) {
      if (confInfo.Opportunity__c != null) {
        confInfoOpptyIDs.add(confInfo.Opportunity__c);
      }
    }

    System.debug('confInfoOpptyIDs = ' + confInfoOpptyIDs);
    if (confInfoOpptyIDs.size() > 0) {

      for(Opportunity oppsWithCI :  [SELECT id, Confidential_Information_Count__c, (SELECT Id FROM Confidential_Informations__r WHERE IsDeleted = False) FROM Opportunity WHERE id =: confInfoOpptyIDs])
      {
        System.debug('oppsWithCI.Confidential_Informations__r.size() = ' + oppsWithCI.Confidential_Informations__r.size());
        oppsWithCI.Confidential_Information_Count__c = oppsWithCI.Confidential_Informations__r.size();
        opptList.add(oppsWithCI);
      }
    }
    System.debug('opptList = ' + opptList);
    for (Opportunity Opt : OpptList)
      {
        update OpptList;
      }
  }


}