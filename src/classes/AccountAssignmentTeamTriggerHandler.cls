/**=====================================================================
 * Appirio, Inc
 * Name: AccountAssignmentTeamTriggerHandler
 * Description: Handler class for the Account_Assignment_Team__c object
 * Created Date: Jan 21st, 2015
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 21st, 2015               Arpita Bose                  Created. T-354803: Logic for after insert to create the AccountTeamMembers
 * Jan 21st, 2015               Noopur                       Added logic for After Delete to delete the AccountTeamMembers
 * Feb 3rd, 2015                Nathalie Le Guay             T-358842: Added Assignment_Team__c.Account_Executive__c to the list of ATM to remove (on delete)
 * Apr 3rd, 2015                Nathalie Le Guay             I-154256: Fix deleteRelatedAccountTeamMembers() so that Account Executive 
 *                                                           will be removed from the Account Team if they were part of an Assignment Team
 *                                                           with no Team member
 =====================================================================*/
public with sharing class AccountAssignmentTeamTriggerHandler {
  //=================================================
  // After Insert Call
  //=================================================
  public static void afterInsert (List<Account_Assignment_Team__c> newList) {
    addAccAssigTeamMemberToAccTeam(newList);
  }

  //=================================================
  // After Delete Call
  //=================================================
  public static void afterDelete (Map<Id,Account_Assignment_Team__c> oldMap) {
    deleteRelatedAccountTeamMembers(oldMap);
  }

  //===============================================================================================
  // Create the AccountTeamMembers when a junction record (Account_Assignment_Team__c) is created
  //===============================================================================================
  public static void addAccAssigTeamMemberToAccTeam(List<Account_Assignment_Team__c> newAccAssigTeam) {
    Set<Id> assignmentTeamIds = new Set<Id>(); // To help with query
    Map<Id, Assignment_Team__c> assignTeamMap = new Map<Id, Assignment_Team__c>(); // to store the result of the query
    List<AccountTeamMember> lstATMsToInsert = new List<AccountTeamMember>(); // New records to insert
    List<AccountShare> lstAccShare = new List<AccountShare>(); // New records to insert


    // ----------
    // Gather Ids
    //-----------
    for (Account_Assignment_Team__c accAssgnmentTeam : newAccAssigTeam) {
      assignmentTeamIds.add(accAssgnmentTeam.Assignment_Team__c);
    }

    // ------------------------------
    // DB Queries and records storing
    // Ordering Members by
    //-------------------------------
    assignTeamMap = new Map<Id, Assignment_Team__c>([SELECT Id, Account_Executive__c,
                                                            (SELECT Id, User__c, Assignment_Team__c, Assignment_Team_Role__c, Assignment_Team__r.Id
                                                             FROM Assignment_Team_Members__r
                                                             WHERE IsActive__c =: true)
                                                     FROM Assignment_Team__c 
                                                     WHERE Id IN :assignmentTeamIds]);

    // ---------------------------
    // Creating the access records
    //----------------------------
    Assignment_Team__c team;
    for (Account_Assignment_Team__c aat: newAccAssigTeam) {
      if (!assignTeamMap.containsKey(aat.Assignment_Team__c)) {
        continue;
      }

      // Retrieve the Team header record 
      team = assignTeamMap.get(aat.Assignment_Team__c);

      if (team.Account_Executive__c != null) {
        // Create access (AccountTeamMember and AccountShare) for the Account Executive, specified on the Assignment Team record
        lstATMsToInsert.add(createAccountTeam(aat.Account__c, team.Account_Executive__c, Constants.TEAM_ROLE_ACCOUNT_MANAGER));
        lstAccShare.add(createAccountShare(aat.Account__c, team.Account_Executive__c));
      }

      // Create access (AccountTeamMember and AccountShare) for each of the members of the Assignment_Team__c
      for (Assignment_Team_Member__c member: team.Assignment_Team_Members__r) {
        lstATMsToInsert.add(createAccountTeam(aat.Account__c, member.User__c, member.Assignment_Team_Role__c));
        lstAccShare.add(createAccountShare(aat.Account__c, member.User__c));
      }
    }

    // ---------------------------
    // Inserting records in the DB
    //----------------------------
    if (lstATMsToInsert.size() > 0) {
      try {
        insert lstATMsToInsert;
        insert lstAccShare;
      } catch  (DMLException ex) {
        ApexLogHandler.createLogAndSave('AccountAssignmentTeamTriggerHandler','addAccAssigTeamMemberToAccTeam', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newAccAssigTeam.get(0).addError(ex.getDmlMessage(i)); 
        }
      }
    }
  }

  //=================================================
  // Instantiates AccountTeamMember given details
  //=================================================
  private static AccountTeamMember createAccountTeam(String accId, String userId, String memRole){
    return new AccountTeamMember(
      AccountId = accId,
      UserId = userId,
      TeamMemberRole = memRole );
  }

  //=================================================
  // Instantiates AccountShare given details
  //=================================================
  private static AccountShare createAccountShare(String accId, String userId){
    return new AccountShare(
      AccountAccessLevel = Constants.ACCESS_LEVEL_EDIT,
      AccountId = accId,
      OpportunityAccessLevel = Constants.ACCESS_LEVEL_EDIT,
      CaseAccessLevel = Constants.ACCESS_LEVEL_NONE,
      UserOrGroupId = userId);
  }

  //===============================================================================================
  // Delete the AccountTeamMembers when a junction record (Account_Assignment_Team__c) is deleted
  // Will not delete if the User is getting access through another Account_Assignment_Team__c record
  //===============================================================================================
  private static void deleteRelatedAccountTeamMembers(map<Id,Account_Assignment_Team__c> oldMap){
    List<AccountTeamMember> atmToDelete = new List<AccountTeamMember>();
    map<Id,set<Id>> existingAATMap = new map<Id,set<Id>>();
    map<Id,set<Id>> existingAssignmentTeamIds = new map<Id,set<Id>>();
    
    Set<Id> accountIds = new Set<Id>();
    Set<Id> assignmentTeamIds = new Set<Id>();
    set<Id> userIds = new Set<Id>();
    
    //fetch the account Ids and the Assignment Teams
    for (Account_Assignment_Team__c AAT : oldMap.values()) {
      accountIds.add(AAT.Account__c);
      assignmentTeamIds.add(AAT.Assignment_Team__c); 
    }
    
    // fetch the account assignment teams for the accounts gathered above
    for (Account_Assignment_Team__c AAT : [SELECT Id,Assignment_Team__c,Account__c ,Assignment_Team__r.Account_Executive__c
                                           FROM Account_Assignment_Team__c 
                                           WHERE Id NOT IN :oldMap.values() 
                                           AND Account__c IN : accountIds]) {
      if (!existingAssignmentTeamIds.containsKey(AAT.Assignment_Team__c)) {
        existingAssignmentTeamIds.put(AAT.Assignment_Team__c,new set<Id>{AAT.Account__c});
      }
      else {
        existingAssignmentTeamIds.get(AAT.Assignment_Team__c).add(AAT.Account__c);
      }
    }
    
    // fetch the assignment team members 
    for (Assignment_Team__c assgnTeam: [SELECT Id, Account_Executive__c, 
                                               (SELECT Id, User__c, Assignment_Team__c, Assignment_Team_Role__c,
                                                       Assignment_Team__r.Account_Executive__c, Assignment_Team__r.Id 
                                                  FROM Assignment_Team_Members__r)
                                        FROM Assignment_Team__c
                                        WHERE (Id in: assignmentTeamIds 
                                           OR Id in: existingAssignmentTeamIds.keySet())]) {
      if (assgnTeam.Account_Executive__c != null) {
        userIds.add(assgnTeam.Account_Executive__c);
      }
      for (Assignment_Team_Member__c assgnTeamMembr : assgnTeam.Assignment_Team_Members__r/*[SELECT Id, User__c, Assignment_Team__c, Assignment_Team_Role__c,
                                                            Assignment_Team__r.Account_Executive__c, Assignment_Team__r.Id 
                                                     FROM Assignment_Team_Member__c 
                                                     WHERE IsActive__c =: true AND 
                                                     (Assignment_Team__c IN :assignmentTeamIds
                                                     OR 
                                                     Assignment_Team__c IN :existingAssignmentTeamIds.keyset())]*/){
      // gather the users for the assignment team in the deleted records
      if (assignmentTeamIds.contains(assgnTeamMembr.Assignment_Team__c)) {
        userIds.add(assgnTeamMembr.User__c);
        /*if (assgnTeamMembr.Assignment_Team__r.Account_Executive__c != null) {
          userIds.add(assgnTeamMembr.Assignment_Team__r.Account_Executive__c);
        }*/
      }
      else {
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
    }
    // fetch the account team members for the gathered userIds and accountIds
    for ( AccountTeamMember atm : [SELECT Id,AccountId,UserId, User.FirstName
                                   FROM AccountTeamMember 
                                   WHERE UserId IN :userIds 
                                   AND AccountId IN :accountIds ]) {
      
      // Check if there is no other junction record for the user and account
      // If not then add to delete list
      if (!existingAATMap.containsKey(atm.AccountId)) {
        atmToDelete.add(atm);
      }
      else if (existingAATMap.containsKey(atm.AccountId) && !existingAATMap.get(atm.AccountId).contains(atm.UserId)) {
        atmToDelete.add(atm);
      }
      system.debug('\nUser is: '+ atm.UserId + ' '+ atm.User.FirstName + ' \nand map has: ' + existingAATMap.get(atm.AccountId));
      
    }
    
    // NLG - Mar 14th, 2015
    // fetch the Confidential_Information__Share records to be deleted.
        List<Confidential_Information__Share> confidentialInfoShares = new List<Confidential_Information__Share>();
        for (Confidential_Information__Share CI_Share : [SELECT c.UserOrGroupId, c.RowCause, c.Parent.Account__c, c.ParentId 
                                                         FROM Confidential_Information__Share c
                                                         WHERE Parent.Account__c in : accountIds 
                                                         AND UserOrGroupId in : userIds
                                                         AND RowCause = :Constants.ROWCAUSE_ACCOUNT_TEAM]) {
          confidentialInfoShares.add(CI_Share);
        }
        
        if (!confidentialInfoShares.isEmpty() ) {
          delete confidentialInfoShares;
        }
    // END of NLG
    
    //delete the account team member records.
    if (!atmToDelete.isEmpty()) {
      try {
        delete atmToDelete;
      }
      catch (DMLException ex) {
        ApexLogHandler.createLogAndSave('AccountAssignmentTeamTriggerHandler','deleteRelatedAccountTeamMembers', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          atmToDelete.get(0).addError(ex.getDmlMessage(i)); 
        }
      }
    }
  }

}