/**=====================================================================
 * Appirio, Inc
 * Name: BatchAssignmentTeam
 * Description: T-355035
 * Created Date:
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * 4th Feb, 2015                Noopur                       Modified the batch 
 * 5th Feb, 2015                Noopur                       Added the code to reset the 
 *                                                           starting value fields with 
 *                                                           the main field values.
 * 10th Feb, 2015               Noopur                       Modified the code to resolve the issue
 *                                                           when we modify the inactive assignment team member
 * 14th Mar, 2015               Nathalie Le Guay             Adding ATM being created since last batch run
 * 17th Mar & 23rd Mar, 2015    Arpita Bose                  T-370563: Added utility methods for code refactoring and updated execute method to reduce size
 * Apr 15th, 2015               Rohit B                      T-375000: Updated finish method to send mail to GCS team for error.
 * May 11th, 2015               Naresh Kumar Ojha            I-162122: Modified batch class to have Stageful interface.
 * June 2nd, 2015               Noopur                       I-163492: Modified to reduce the queries to Account Assignment Team to resolve too many rows error.
 * June 3rd, 2015               Nathalie                     Update Global_Settings__c.Assignment_Team_Member_Job_Last_Run__c regardless of failures
 * June 4th, 2015               Noopur                       I-166366 - Added code to add account share when creating new Account Team Member.
 * June 8th, 2015               Noopur                       I-166965 - commented the code to resolve issue
 * Jun 10th, 2015               Paul Kissick                 Case #970440 - Database.rollback in wrong location.
 =====================================================================*/
global class BatchAssignmentTeam implements Database.Batchable<sObject>, Database.Stateful {
  public static final String GLOBAL_SETTING = 'Global';
  public Global_Settings__c lastRun = Global_Settings__c.getInstance(GLOBAL_SETTING);
  public static Boolean hasError = false;
  public static Map<Id, List<Account_Assignment_Team__c>> mapAssgnTeamToAccAssgnTeam;
  public static Map<Id,List<Account_Assignment_Team__c>> mapAccountToAccAssgnTeam;
  global Set<String> failedATMRecords;
  //global Set<Database.Saveresult> failedATMInsertRecords, failedAccShareInsertRecords;
  global Set<String> failedATMInsertRecords, failedAccShareInsertRecords;
  
  //=====================================================================================================
  // Start - Will query all Assignment_Team_Member__c that have been updated (check on _Updated__c field)
  //=====================================================================================================
  global Database.Querylocator start ( Database.Batchablecontext bc ) {
    DateTime lastRunTime = lastrun.Assignment_Team_Member_Job_Last_Run__c;
    
    if ( Test.isRunningTest() ) {
      return Database.getQueryLocator ([SELECT Id, User__c, Assignment_Team__c, Assignment_Team_Role__c ,
                                        IsActive__c, User_Starting_Value__c, IsActive_Starting_Value__c,
                                        Assignment_Team_Role_Starting_Value__c, Assignment_Team__r.Account_Executive__c, CreatedDate
                                      FROM Assignment_Team_Member__c
                                      WHERE ((User_Updated__c = true OR Assignment_Team_Role_Updated__c = true
                                      OR IsActive_Updated__c = true OR CreatedDate >=: lastRunTime)
                                      AND CreatedById =: UserInfo.getUserId()) limit 200]);
    }
    //query all Assignment_Team_Member__c records
    return Database.getQueryLocator ([SELECT Id, User__c, Assignment_Team__c, Assignment_Team_Role__c ,
                                        IsActive__c, User_Starting_Value__c, IsActive_Starting_Value__c,
                                        Assignment_Team_Role_Starting_Value__c, Assignment_Team__r.Account_Executive__c, CreatedDate
                                      FROM Assignment_Team_Member__c
                                      WHERE User_Updated__c = true OR Assignment_Team_Role_Updated__c = true
                                      OR IsActive_Updated__c = true OR CreatedDate >=: lastRunTime]);
  }

  //=====================================================================================================
  // Execute - 
  //=====================================================================================================
  global void execute (Database.BatchableContext bc, List<Assignment_Team_Member__c> scope) {
    List<Assignment_Team_Member__c> assgnTeamMemList = (List<Assignment_Team_Member__c>) scope;
    failedATMRecords = new Set<String>();
    failedATMInsertRecords = new Set<String>();
    failedAccShareInsertRecords = new Set<String>();
     
    system.debug('***assgnTeamMemList>>>' +assgnTeamMemList.size()+'==='+assgnTeamMemList);
    Set<Id> assgnTeamIds = new Set<Id>();
    Set<ID> accountIds = new Set<ID>();
    Set<Id> oldUserIds = new Set<Id>();
    Set<Id> newUserIds = new Set<Id>();
    Map<Id, List<AccountTeamMember>> mapAccIdToATM = new Map<Id, List<AccountTeamMember>>();
    Map<Id, List<AccountTeamMember>> teamMembersToInsert = new Map<Id, List<AccountTeamMember>>();
    Map<Id, List<AccountTeamMember>> teamMembersToUpdate = new Map<Id, List<AccountTeamMember>>();
    List<AccountTeamMember> teamMembersToDelete = new List<AccountTeamMember>();
    List<AccountShare> accountShareList = new List<AccountShare>();
    Set<Id> assignmentTeamIdsForDelete = new Set<Id>();
    Set<Id> accAsgnmtTeamIdsForDelete = new Set<Id>();
    set<Id> atmToDeleteSet = new set<Id>();
    Set<Id> newATMids = new Set<Id>();
    Set<Id> query_userIds = new Set<Id>();
    
    // Create a savepoint
    Savepoint sp = Database.setSavepoint();
    
    // ----------------------------------
    // Gathering old/new User record Ids
    //-----------------------------------
    for (Assignment_Team_Member__c atm : assgnTeamMemList) {
      assgnTeamIds.add(atm.Assignment_Team__c);
      if (atm.User__c != atm.User_Starting_Value__c){
        oldUserIds.add(atm.User_Starting_Value__c); // getting old userIds
        newUserIds.add(atm.User__c); // getting new userIds
      }
      if (atm.CreatedDate >= lastrun.Assignment_Team_Member_Job_Last_Run__c) {
        newATMids.add(atm.Id);
      }
      //nojha: May 19th, 2015
      if((atm.User__c != atm.User_Starting_Value__c) 
                || (atm.Assignment_Team_Role__c != atm.Assignment_Team_Role_Starting_Value__c  && atm.isActive__c == true)
                || (atm.IsActive__c != atm.IsActive_Starting_Value__c)){          
          query_userIds.add(atm.User_Starting_Value__c); // getting old userIds
          query_userIds.add(atm.User__c); // getting new userIds        
      }
    }

    // ---------------------------------------------------------------------------------------------
    // Gather all Account_Assignment_Team__c records that points to above Assignment_Team_Member__c
    // and get all Account__c Ids
    // ---------------------------------------------------------------------------------------------
    accountIds = getAccIdOfAccAssgnTeam(assgnTeamIds);
    system.debug('===newATMids==='+newATMids);
    // ------------------------------------------------------------------
    // Query the Account + AccountTeamMember for the above Account__c Id
    // ------------------------------------------------------------------
    for (AccountTeamMember accTeamMem : [SELECT Id, AccountId, UserId, TeamMemberRole
                                         FROM AccountTeamMember
                                         WHERE AccountId IN: accountIds AND UserId IN: query_userIds]) {//nojha: May 19th, 2015, added filter on UserIds

      if (!mapAccIdToATM.containsKey(accTeamMem.AccountId)) {
          mapAccIdToATM.put(accTeamMem.AccountId, new List<AccountTeamMember>());
      }
      mapAccIdToATM.get(accTeamMem.AccountId).add(accTeamMem);
    }
    
    // 2 June'15- Noopur removed query and moved code for map creation to the first query #469 to resolve too many query rows error
    
    //Map<Id, List<Account_Assignment_Team__c>> mapAssgnTeamToAccAssgnTeam = new Map<Id, List<Account_Assignment_Team__c>>();
    /*for (Account_Assignment_Team__c aat : [SELECT Id, Account__c, Assignment_Team__c
                                           FROM Account_Assignment_Team__c
                                           WHERE Account__c IN :accountIds
                                           AND Assignment_Team__c IN :assgnTeamIds]) {
        if ( !mapAssgnTeamToAccAssgnTeam.containsKey(aat.Assignment_Team__c) ) {
          mapAssgnTeamToAccAssgnTeam.put(aat.Assignment_Team__c, new List<Account_Assignment_Team__c>{aat});
        }
        else {
          mapAssgnTeamToAccAssgnTeam.get(aat.Assignment_Team__c).add(aat);
        }      
    }*/

    List<AccountTeamMember> listOfTeamMembers;

    for (Assignment_Team_Member__c atm : assgnTeamMemList){
      if (mapAssgnTeamToAccAssgnTeam.containsKey(atm.Assignment_Team__c)) {

      // ---------------------------------
      // 1) Update to the User__c value
      // ---------------------------------
      if (atm.User__c != atm.User_Starting_Value__c && atm.isActive__c == true) {
        system.debug('***atm.User__c***' +atm.User__c);
        system.debug('***atm.User_Starting_Value__c***' +atm.User_Starting_Value__c);
        for (Account_Assignment_Team__c aat : mapAssgnTeamToAccAssgnTeam.get(atm.Assignment_Team__c)) {
          if (mapAccIdToATM.containsKey(aat.Account__c) && assgnTeamIds.contains(aat.Assignment_Team__c) ) {
            listOfTeamMembers = mapAccIdToATM.get(aat.Account__c);
            //processedAccountIds.add(aat.Account__c);
            for (AccountTeamMember accTM : listOfTeamMembers) {
              //Remove Account Team Member for all Accounts where the OLD user is a team member
              //AND was part of an Assignment Team referenced by an Account Assignment Team junction record
              if (oldUserIds.contains(atm.User_Starting_Value__c) && atm.User_Starting_Value__c == accTM.UserId) {
                teamMembersToDelete.add(accTM);
                assignmentTeamIdsForDelete.add(atm.Assignment_Team__c);
                accAsgnmtTeamIdsForDelete.add(aat.Id);
              }
              //Add Account Team Member for all Accounts where the user is a team member
              //AND is part of an Assignment Team referenced by an Account Assignment Team junction record
              system.debug('***newUserIds.contains(atm.User__c)***' +newUserIds.contains(atm.User__c));
              if (newUserIds.contains(atm.User__c) && accountIds.contains(aat.Account__c)){
                AccountTeamMember newATM = createAccntTeamMember(aat, atm);
                if ( teamMembersToInsert.containsKey(newATM.accountId) ) {
                  teamMembersToInsert.get(newATM.AccountId).add(newATM);
                }
                else {
                  teamMembersToInsert.put(newATM.AccountId, new List<AccountTeamMember>{newATM});
                }
                // I-166366 - Noopur added code to create account share
                AccountShare newShare = createAccShare(newATM, aat);
                accountShareList.add(newShare);
              }
            }
          }
        }
      }

      // ----------------------------------------------
      // 2) Update to the Assignment_Team_Role__c value
      // ----------------------------------------------
      if (atm.Assignment_Team_Role__c != atm.Assignment_Team_Role_Starting_Value__c  && atm.isActive__c == true) {
        system.debug('***atm.Assignment_Team_Role__c***' +atm.Assignment_Team_Role__c);
        system.debug('***atm.Assignment_Team_Role_Starting_Value__c***' +atm.Assignment_Team_Role_Starting_Value__c);
        // Find all the Account_Assignment_Team__c where (Account__c = Assignment_Team_Member__c.Assignment_Team__c.Account__c
        // and Assignment_Team__c = Assignment_Team_Member__c.Assignment_Team__c)
        for (Account_Assignment_Team__c aat : mapAssgnTeamToAccAssgnTeam.get(atm.Assignment_Team__c)) {
             if (mapAccIdToATM.containsKey(aat.Account__c) && assgnTeamIds.contains(aat.Assignment_Team__c)) {
                listOfTeamMembers = mapAccIdToATM.get(aat.Account__c);
               // processedAccountIds.add(aat.Account__c);
                system.debug('***listOfTeamMembers***' +listOfTeamMembers);
               //Update the AccountTeamMember.Role with the new value
               for (AccountTeamMember atMember : listOfTeamMembers ) {
                  if (atMember.UserId == atm.User__c) {
                   atMember.TeamMemberRole = atm.Assignment_Team_Role__c;
                   if ( !teamMembersToUpdate.containsKey(atMember.AccountId) ) {
                     teamMembersToUpdate.put(atMember.AccountId, new List<AccountTeamMember>{atMember});
                   }
                   else {
                     teamMembersToUpdate.get(atMember.AccountId).add(atMember);
                   }
                  }
               }
             }
          }
          system.debug('***teamMembersToUpdate***' +teamMembersToUpdate);
          system.debug('***teamMembersToUpdate.size()***' +teamMembersToUpdate.size());
      }
      // ----------------------------------
      // 3) Update to the IsActive__c value
      // ----------------------------------
      if (atm.IsActive__c != atm.IsActive_Starting_Value__c) {
        if (atm.IsActive__c == true) {
          // Find all the Account_Assignment_Team__c where (Account__c = Assignment_Team_Member__c.Assignment_Team__c.Account__c
          // and Assignment_Team__c = Assignment_Team_Member__c.Assignment_Team__c) ?
          for (Account_Assignment_Team__c aat : mapAssgnTeamToAccAssgnTeam.get(atm.Assignment_Team__c)) {
            // Create new AccountTeamMember and AccountShare records
            // 8-June NS- commented the code to resolve issue I-166965
            if (/*mapAccIdToATM.containsKey(aat.Account__c) && */ assgnTeamIds.contains(atm.Assignment_Team__c)) {
                AccountTeamMember newATM = createAccntTeamMember(aat, atm);              
                if ( teamMembersToInsert.containsKey(newATM.accountId) ) {
                  teamMembersToInsert.get(newATM.AccountId).add(newATM);
                }
                else {
                  teamMembersToInsert.put(newATM.AccountId, new List<AccountTeamMember>{newATM});
                }
                AccountShare newShare = createAccShare(newATM, aat);
                accountShareList.add(newShare);
            }
          }
        }
        else if (atm.IsActive__c == false) {
          //?Remove Account Team Member for all Accounts where the user is a team member
          //AND is part of an Assignment Team referenced by an Account Assignment Team junction record
          for (Account_Assignment_Team__c aat : mapAssgnTeamToAccAssgnTeam.get(atm.Assignment_Team__c)) {
             //Remove Account Team Member for all Accounts where the OLD user is a team member
             //AND was part of an Assignment Team referenced by an Account Assignment Team junction record
             if (mapAccIdToATM.containsKey(aat.Account__c) && assgnTeamIds.contains(atm.Assignment_Team__c)) {
               listOfTeamMembers = mapAccIdToATM.get(aat.Account__c);
               for (AccountTeamMember accTM : listOfTeamMembers) {
                  if (atm.User__c == accTM.UserId){
                   teamMembersToDelete.add(accTM);
                   assignmentTeamIdsForDelete.add(atm.Assignment_Team__c);
                   accAsgnmtTeamIdsForDelete.add(aat.Id);
                 }
               }
             }
           }
         }
        }
        if (newATMids.contains(atm.Id)) {
          for (Account_Assignment_Team__c aat : mapAssgnTeamToAccAssgnTeam.get(atm.Assignment_Team__c)) {
            // Noopur - 1June'15 - removed the check from mapAccIdToATM, as it is not required in case of new members.
            if (/*mapAccIdToATM.containsKey(aat.Account__c) &&*/ assgnTeamIds.contains(atm.Assignment_Team__c)) {
              AccountTeamMember newATM = createAccntTeamMember(aat, atm);
                if ( teamMembersToInsert.containsKey(newATM.accountId) ) {
                  teamMembersToInsert.get(newATM.AccountId).add(newATM);
                }
                else {
                  teamMembersToInsert.put(newATM.AccountId, new List<AccountTeamMember>{newATM});
                }
                // I-166366 - Noopur added code to create account share
                AccountShare newShare = createAccShare(newATM, aat);
                accountShareList.add(newShare);
            }
          }
        }
      }
    }
    system.debug('****teamMembersToDelete====='+teamMembersToDelete);
    // Delete team members
    if (!teamMembersToDelete.isEmpty()) {
      //call the method to delete AccountTeamMember records
      deleteAccTeamMem(teamMembersToDelete, accAsgnmtTeamIdsForDelete, assignmentTeamIdsForDelete, atmToDeleteSet);
    }
    
    
    // Update team members
    if (!teamMembersToUpdate.isEmpty()) {
      try {
        List<AccountTeamMember> atmToUpdate = new List<AccountTeamMember>();
        Set<AccountTeamMember> atmToUpdateSet = new Set<AccountTeamMember>();
         for (List<AccountTeamMember> atmInsert : teamMembersToUpdate.values()) {
           for( AccountTeamMember atmIn : atmInsert) {
             if ( !atmToUpdateSet.contains(atmIn) && !atmToDeleteSet.contains(atmIn.Id) ) {
               atmToUpdate.add(atmIn);
               atmToUpdateSet.add(atmIn);
             }
           }
        }
        //update atmToUpdate;
        List<Database.Saveresult> atmUpdateResults = Database.update(atmToUpdate, false);
        for(Integer i = 0; i < atmUpdateResults.size(); i++){
  
          if (!atmUpdateResults.get(i).isSuccess()){
            failedATMRecords.add(atmUpdateResults.get(i).getId());
          }
        }
        
      } catch (DMLException e) {
        
        Database.rollback(sp);
        ApexLogHandler.createLogAndSave('BatchAssignmentTeam','execute', e.getStackTraceString(), e);
        
        // Rollback to the previous state
        
        hasError = true;
        
        for (Integer i = 0; i < e.getNumDml(); i++) {
          System.debug('\nError when updating Account Team Member #' + i);
        }
      }
    }
    // Insert team members and account share records
    if (!teamMembersToInsert.isEmpty()) {
      try {
        List<AccountTeamMember> atmToInsert = new List<AccountTeamMember>();
        set<AccountTeamMember> atmAdded = new set<AccountTeamMember>();
        for (List<AccountTeamMember> atm : teamMembersToInsert.values()) {
          for( AccountTeamMember atmIn : atm) {
            if ( !atmAdded.contains(atmIn) ) {
              atmToInsert.add(atmIn);
              atmAdded.add(atmIn);
            }
          }
        }
        //insert atmToInsert;
        //insert accountShareList;
        List<Database.Saveresult> atmToInsertResults = Database.Insert(atmToInsert, false);
        List<Database.Saveresult> accShareToInsertResults = Database.Insert(accountShareList, false);
        
        for(Integer i = 0; i < atmToInsertResults.size(); i++){
          if (!atmToInsertResults.get(i).isSuccess()){
            // DML operation failed
            Database.Error error = atmToInsertResults.get(i).getErrors().get(0);
            String failedDML = error.getMessage();
            String errorStr = '<tr><td>' + atmToInsert.get(i).AccountId + '</td><td>' + atmToInsert.get(i).UserId + '</td>';
            errorStr += '<td>' + atmToInsert.get(i).TeamMemberRole + '</td><td>' + failedDML + '</td></tr>';
            failedATMInsertRecords.add(errorStr);
          }
        }
        
        for(Integer i = 0; i < accShareToInsertResults.size(); i++){
          if (!accShareToInsertResults.get(i).isSuccess()){
            // DML operation failed
            Database.Error error = accShareToInsertResults.get(i).getErrors().get(0);
            String failedDML = error.getMessage();
            String errorStr = '<tr><td>' + accountShareList.get(i).AccountId + '</td><td>' + accountShareList.get(i).UserOrGroupId + '</td>';
            errorStr += '<td>' + failedDML + '</td></tr>';
            failedAccShareInsertRecords.add(errorStr);

          }
        }

      } catch (DMLException e) {
        // Rollback to the previous state
        Database.rollback(sp);
        
        ApexLogHandler.createLogAndSave('BatchAssignmentTeam','execute', e.getStackTraceString(), e);
        hasError = true;
        
        for (Integer i = 0; i < e.getNumDml(); i++) {
          System.debug('\nError when inserting Account Team Member #' + i);
        }
      }
    }
    
    // if the batch is processed successfully, then reset the values of starting 
    // value fields with the values in their corresponding main fields.
    if ( !hasError ) {
       updateAssgnTeamMemList(assgnTeamMemList );
    }
    
  }

  //=====================================================================================================
  // Finish - Send email with error log if any exception
  //=====================================================================================================
  global void finish (Database.BatchableContext bc) {
      //Added by Rohit B on 15/Apr/2015 for T-375000        --START--
      List<String> toAddresses = new List<String>();
      toAddresses.add(lastrun.Batch_Failures_Email__c);
      //Added by Rohit B on 15/Apr/2015 for T-375000        --END--

      if ( BC.getJobId() != null ) {
        for (AsyncApexJob a : [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                                 TotalJobItems, CreatedBy.Email
                          FROM AsyncApexJob WHERE Id =: BC.getJobId()]) {
        
          Integer numberOfError ;
          if( a != null && failedATMRecords != null && failedATMInsertRecords != null && failedAccShareInsertRecords != null) {
            numberOfError = a.NumberOfErrors + failedATMRecords.size() + failedATMInsertRecords.size() + failedAccShareInsertRecords.size();
          }
          System.debug('\n[BatchAssignTeam: finish]: [The batch Apex job processed ' + a.TotalJobItems +' batches with '+ numberOfError + ' failures.]]');
    
          String emailBody = 'The Batch Assignment Team Members Update job completed successful processing of ' + a.JobItemsProcessed + ' out of ' + a.TotalJobItems
                           + ' and generated ' + a.NumberOfErrors;
          if ( failedATMRecords != null && failedATMRecords.size() > 0) {
            emailBody += '<br /> AccountTeamMember records update failed: '+failedATMRecords;
          }
          
          if ( failedATMInsertRecords != null && failedATMInsertRecords.size() > 0) {
            emailBody += '<br /> AccountTeamMember records insert failed: '; 
            emailBody += '<table><tr ><td width="15%">Account Id</td><td width="15%">User Id</td><td width="20%">TeamMemberRole</td><td width="*">Exception</td></tr>';
            for (String currentRow : failedATMInsertRecords) {
              emailBody += currentRow;
            }
            emailBody += '</table>';
          }
    
          if ( failedAccShareInsertRecords != null && failedAccShareInsertRecords.size() > 0) {
            emailBody += '<br /> Account Share records insert failed: '; 
            emailBody += '<table><tr ><td width="15%">Account Id</td><td width="15%">User Or Group Id</td><td width="*">Exception</td></tr>';
            for (String currentRow : failedATMInsertRecords) {
              emailBody += currentRow;
            }
            emailBody += '</table>';
          }      
           
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          mail.setSaveAsActivity(false);
          mail.setTargetObjectId(UserInfo.getUserId());
          mail.setSubject('Force.com Batch: BatchAssignTeam Error(s)');
          mail.setToAddresses(toAddresses);                       //Added by Rohit B on 15/Apr/2015 for T-375000
          mail.setBccSender(false);
          mail.setUseSignature(false);
          mail.setHtmlBody(emailBody);
          mail.setPlainTextBody(emailBody);
          
          if (numberOfError > 0) {
            if (!Test.isRunningTest()) {
              Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
          }
          //else if (a.NumberOfErrors <= 0) {
            lastRun.Assignment_Team_Member_Job_Last_Run__c = system.now();
            update lastRun; //only needs to have its value reset if there were errors
          //}
        }
      }
  }
  
  //============================================================================
  // T-370563: Utility method to create Account Team Member records
  //============================================================================
  private static AccountTeamMember createAccntTeamMember(Account_Assignment_Team__c aat, Assignment_Team_Member__c atm) {    
    AccountTeamMember newATM = new AccountTeamMember();
    newATM.AccountId = aat.Account__c;
    newATM.UserId = atm.User__c;
    newATM.TeamMemberRole = atm.Assignment_Team_Role__c; 
    
    return newATM;   
  }
  
  //============================================================================
  // T-370563: Utility method to create AccountShare records
  //============================================================================
  private static AccountShare createAccShare(AccountTeamMember newATM, Account_Assignment_Team__c aat) {
    AccountShare newShare = new AccountShare();
    newShare.UserOrGroupId = newATM.UserId;
    newShare.AccountId = aat.Account__c;
    newShare.AccountAccessLevel = 'Edit';// Constants.ACCESS_LEVEL_EDIT;
    newShare.OpportunityAccessLevel = 'Edit'; // Constants.ACCESS_LEVEL_EDIT;
    newShare.CaseAccessLevel = 'None'; //Constants.ACCESS_LEVEL_READ;
    return newShare;
  }
  
  //============================================================================
  // T-370563: Utility method to get Account__c Ids of Account_Assignment_Team__c
  //============================================================================
  private static Set<Id> getAccIdOfAccAssgnTeam(Set<Id> assgnTeamIds) {
    Set<ID> accountIds = new Set<ID>();
    // 2June'15- Noopur created maps to store the queried data once to resolve too many query rows error
    mapAssgnTeamToAccAssgnTeam = new Map<Id, List<Account_Assignment_Team__c>>();
    mapAccountToAccAssgnTeam = new Map<Id,List<Account_Assignment_Team__c>>();
    for (Account_Assignment_Team__c aat : [SELECT Id, Account__c, Assignment_Team__c,
                                                  Assignment_Team__r.Account_Executive__c
                                           FROM Account_Assignment_Team__c
                                           WHERE Assignment_Team__c IN :assgnTeamIds]){
      if ( !mapAssgnTeamToAccAssgnTeam.containsKey(aat.Assignment_Team__c) ) {
          mapAssgnTeamToAccAssgnTeam.put(aat.Assignment_Team__c, new List<Account_Assignment_Team__c>{aat});
        }
        else {
          mapAssgnTeamToAccAssgnTeam.get(aat.Assignment_Team__c).add(aat);
        }
        // map of Account and Account Assignment Team
        if ( !mapAccountToAccAssgnTeam.containsKey(aat.Account__c) ) {
        mapAccountToAccAssgnTeam.put(aat.Account__c, new List<Account_Assignment_Team__c>{aat});
      }
      else {
        mapAccountToAccAssgnTeam.get(aat.Account__c).add(aat);
      }
      accountIds.add(aat.Account__c);
    }
    return accountIds;
  }
  
  //============================================================================
  // T-370563: Method to update Assignment_Team_Member record
  //============================================================================
  private static void updateAssgnTeamMemList(List<Assignment_Team_Member__c> assgnTeamMemList ) {
    
    Savepoint sp = Database.setSavepoint();
    try {
        for ( Assignment_Team_Member__c atm : assgnTeamMemList ) {
          atm.IsActive_Starting_Value__c = atm.IsActive__c;
          atm.Assignment_Team_Role_Starting_Value__c = atm.Assignment_Team_Role__c;
          atm.User_Starting_Value__c = atm.User__c;
          atm.User_Updated__c = false;
          atm.Assignment_Team_Role_Updated__c = false;
          atm.IsActive_Updated__c = false;
        }
        update assgnTeamMemList;
      }
      catch (DMLException e) {
        // Rollback to the previous state
        Database.rollback(sp);
        ApexLogHandler.createLogAndSave('BatchAssignmentTeam','execute: updateAssgnTeamMemList()', e.getStackTraceString(), e);
      }
  }
  
  //============================================================================
  // T-370563 : Method to delete Account Team Member
  //============================================================================
  private static void deleteAccTeamMem(List<AccountTeamMember> teamMembersToDelete, Set<Id> accAsgnmtTeamIdsForDelete,
                                         Set<Id> assignmentTeamIdsForDelete, set<Id> atmToDeleteSet) {
    List<AccountTeamMember> atmToDelete = new List<AccountTeamMember>();
      map<Id,set<Id>> existingAATMap = new map<Id,set<Id>>();
      map<Id,set<Id>> existingAssignmentTeamIds = new map<Id,set<Id>>();
      
      Set<Id> accountForDelIds = new Set<Id>();
      set<Id> userIdsFromATMToDelete = new set<Id>();
      set<Id> userForDelIds = new Set<Id>();
    
      //fetch the account Ids and the Assignment Teams
      for (AccountTeamMember AAT : teamMembersToDelete) {
        accountForDelIds.add(AAT.AccountId);
        userIdsFromATMToDelete.add(AAT.UserId);
      }
    
    // fetch the account assignment teams for the accounts gathered above
    // 2June'15- Noopur removed query and added map to resolve too many query rows error
    for(Id accId : accountForDelIds) {
        for (Account_Assignment_Team__c AAT : mapAccountToAccAssgnTeam.get(accId)) {
            if ( accAsgnmtTeamIdsForDelete.contains(AAT.Id) ) {
                continue;
            }
          if (!existingAssignmentTeamIds.containsKey(AAT.Assignment_Team__c)) {
            existingAssignmentTeamIds.put(AAT.Assignment_Team__c,new set<Id>{AAT.Account__c});
          }
          else {
            existingAssignmentTeamIds.get(AAT.Assignment_Team__c).add(AAT.Account__c);
          }
        }
    }
    
    system.debug('---existingAssignmentTeamIds----'+existingAssignmentTeamIds);
    // fetch the assignment team members 
    for (Assignment_Team_Member__c assgnTeamMembr : [SELECT Id, User__c, Assignment_Team__c, Assignment_Team_Role__c,
                                                            Assignment_Team__r.Account_Executive__c, Assignment_Team__r.Id 
                                                     FROM Assignment_Team_Member__c 
                                                     WHERE 
                                                     Assignment_Team__c IN :assignmentTeamIdsForDelete
                                                     OR 
                                                     (IsActive__c =: true AND Assignment_Team__c IN :existingAssignmentTeamIds.keyset())]){
      // gather the users for the assignment team in the deleted records
      if (assignmentTeamIdsForDelete.contains(assgnTeamMembr.Assignment_Team__c) && userIdsFromATMToDelete.contains(assgnTeamMembr.User__c)) {
        userForDelIds.add(assgnTeamMembr.User__c);
      }
      else if(existingAssignmentTeamIds != null && existingAssignmentTeamIds.containsKey(assgnTeamMembr.Assignment_Team__c)) {
        // fetch the existing assignment team members related to the account gathered above
        // this is to check if there are any other junction record for the account and the user
        for (Id accId : existingAssignmentTeamIds.get(assgnTeamMembr.Assignment_Team__c)) {
          if (!existingAATMap.containsKey(accId)) {
            existingAATMap.put(accId, new set<Id>());
          }
          existingAATMap.get(accId).add(assgnTeamMembr.User__c);
          if (assgnTeamMembr.Assignment_Team__r.Account_Executive__c != null) {
            existingAATMap.get(accId).add(assgnTeamMembr.Assignment_Team__r.Account_Executive__c);
          }
        }
      }
    }
    
    system.debug('===userForDelIds==='+userForDelIds);
    
    // fetch the account team members for the gathered userIds and accountIds
    for ( AccountTeamMember atm : [SELECT Id,AccountId,UserId 
                                   FROM AccountTeamMember 
                                   WHERE (UserId IN :userForDelIds 
                                   AND AccountId IN :accountForDelIds)
                                   OR Id IN : teamMembersToDelete]) {
      
      // Check if there is no other junction record for the user and account
      // If not then add to delete list
      if (!existingAATMap.containsKey(atm.AccountId)) {
        atmToDelete.add(atm);
        atmToDeleteSet.add(atm.Id);
      }
      else if (existingAATMap.containsKey(atm.AccountId) && !existingAATMap.get(atm.AccountId).contains(atm.UserId)) {
        atmToDelete.add(atm);
        atmToDeleteSet.add(atm.Id);
      }      
    }
    Savepoint sp = Database.setSavepoint();
    try {
      // delete the account team member records.
      if (!atmToDelete.isEmpty()) {
        delete atmToDelete;
      } 
    } catch (DMLException e) {
        // Rollback to the previous state
        Database.rollback(sp);
        ApexLogHandler.createLogAndSave('BatchAssignmentTeam','deleteAccTeamMem', e.getStackTraceString(), e);
        
        
        
        hasError = true;
        
        for (Integer i = 0; i < e.getNumDml(); i++) {
          System.debug('\nError when deleting Account Team Member #' + i);
        }
      }
  }
}