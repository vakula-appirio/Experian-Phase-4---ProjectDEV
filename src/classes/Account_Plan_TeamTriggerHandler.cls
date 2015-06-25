/**=====================================================================
 * Appirio, Inc
 * Name: Account_Plan_TeamTriggerHandler
 * Description: Handler class for Account_Plan_TeamTrigger trigger(for T-275542)
 * Created Date: May 1st, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified      Modified By                Description of the update 
 * May 02nd, 2014     Arpita Bose(Appirio)       Updated catch(Exception) to catch(DMLException) to use getDMLException
 * Jul 14th, 2014     Arpita Bose(Appirio)       I-120524: Added method synchCurrencyISOCodes() in beforeInsert and beforeUpdate
 =====================================================================*/
public without sharing class Account_Plan_TeamTriggerHandler {
    public final static string SEPARATOR = ':';
    public final static string USER_NOT_IN_RELATED_ACCOUNT_TEAM = 'Insufficient Privileges: Selected user is not in related account team.'; 
    //========================================================================================
  // Before Insert Call
  //========================================================================================
  public static void beforeInsert(List<Account_Plan_Team__c> newAccountPlanTeams){
    createAccountPlanShares(newAccountPlanTeams);
    synchCurrencyISOCodes(newAccountPlanTeams, null);
  }
  //========================================================================================
  // Before Update Call
  //========================================================================================
  public static void beforeUpdate(List<Account_Plan_Team__c> newAccountPlanTeams, Map<Id, Account_Plan_Team__c> oldIdToAccountPlanTeamMap){
    updateAccountPlanShares(newAccountPlanTeams, oldIdToAccountPlanTeamMap);
    synchCurrencyISOCodes(newAccountPlanTeams, oldIdToAccountPlanTeamMap);
  } 
  //========================================================================================
  // Before Delete Call
  //========================================================================================
  public static void beforeDelete(List<Account_Plan_Team__c> oldAccountPlanTeams){
    deleteAccountPlanShares(oldAccountPlanTeams);
  }
  //========================================================================================
  // After Undelete Call
  //========================================================================================
  public static void afterUnDelete(List<Account_Plan_Team__c> newAccountPlanTeams){
    createAccountPlanShares(newAccountPlanTeams);
  }
  //========================================================================================
  // Utility method to update account plan share records
  //========================================================================================
  public static void deleteAccountPlanShares(List<Account_Plan_Team__c> oldAccountPlanTeams){
    Set<Id> userIdstoRemove = new Set<Id>();
    Set<Id> accountPlanIds = new Set<Id>();
    Map<String, Account_Plan__Share> uniqueKeyToAccountPlanShareMap = new Map<String, Account_Plan__Share>();
    List<Account_Plan__Share> tobeDeletedAccountPlanShares = new List<Account_Plan__Share>();
    // iterate trigger.old records and create a set of userid and related account plan ids
    for(Account_Plan_Team__c accountPlanTeam : oldAccountPlanTeams){
        if(accountPlanTeam.User__c <> NULL){
          userIdstoRemove.add(accountPlanTeam.User__c);
        }
        accountPlanIds.add(accountPlanTeam.Account_Plan__c);
    }
    // users being defined in the user lookup on the deleted records
    if(!userIdstoRemove.isEmpty()){   
        // retreive account plan share records associated with removed account plans
      uniqueKeyToAccountPlanShareMap = getUniqueKeyToAccountPlanShareMap(userIdstoRemove, accountPlanIds);
      // re-iterate trigger.old records (records going to be deleted)   
      for(Account_Plan_Team__c accountPlanTeam : oldAccountPlanTeams){
          if(accountPlanTeam.User__c <> NULL){
            string uniquePlanShareKey = accountPlanTeam.User__c + SEPARATOR + accountPlanTeam.Account_Plan__c;
            // add to tobedeleted list on if there are any account plan share record exists in the database
            if(uniqueKeyToAccountPlanShareMap.containsKey(uniquePlanShareKey)){
              tobeDeletedAccountPlanShares.add(uniqueKeyToAccountPlanShareMap.get(uniquePlanShareKey));
            }
          }
        }
        // execute delete dml operation only when there are items to be deleted.
          if(!tobeDeletedAccountPlanShares.isEmpty()){
          try{
            delete tobeDeletedAccountPlanShares;
          }catch(DMLException ex){
            apexLogHandler.createLogAndSave('Account_Plan_TeamTriggerHandler','deleteAccountPlanShares', ex.getStackTraceString(), ex);
            for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
               oldAccountPlanTeams.get(0).addError(ex.getDMLMessage(indx));
            }
          }
        }  
    } 
  }
  
  
  //========================================================================================
  // Utility method to update account plan share records
  //========================================================================================
  public static void updateAccountPlanShares(List<Account_Plan_Team__c> newAccountPlanTeams, Map<Id, Account_Plan_Team__c> oldIdToAccountPlanTeamMap){
    Set<Id> userIdstoAdd = new Set<Id>(); 
    Set<Id> userIdstoRemove = new Set<Id>();
    Set<Id> accountPlanIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();
    Map<String, Account_Plan__Share> uniqueKeyToAccountPlanShareMap = new Map<String, Account_Plan__Share>();
    Set<String> userAccountUniqueKeys = new Set<String>();
    List<Account_Plan__Share> tobeInsertedAccountPlanShares = new List<Account_Plan__Share>();
    List<Account_Plan__Share> tobeDeletedAccountPlanShares = new List<Account_Plan__Share>();
    Map<Id, Account_Plan__c> accountPlanMap = new Map<Id, Account_Plan__c>();
    // iterate Trigger.new records of account plan team. 
    for(Account_Plan_Team__c accountPlanTeam : newAccountPlanTeams){
        // verify if this is an insert/updelete or update operation
        // oldIdToAccountPlanTeamMap will always be null in case of insert and undelete
      if(oldIdToAccountPlanTeamMap == null || (oldIdToAccountPlanTeamMap <> NULL && 
                                               accountPlanTeam.User__c <> oldIdToAccountPlanTeamMap.get(accountPlanTeam.id).User__c)){
        if(accountPlanTeam.User__c <> NULL){
          userIdstoAdd.add(accountPlanTeam.User__c);
        }
        if(oldIdToAccountPlanTeamMap <> NULL && oldIdToAccountPlanTeamMap.get(accountPlanTeam.id).User__c <> NULL){
          userIdstoRemove.add(oldIdToAccountPlanTeamMap.get(accountPlanTeam.id).User__c);       
        }
      }
      accountPlanIds.add(accountPlanTeam.Account_Plan__c);
    }
    // get map of related account plan records 
    accountPlanMap = getAccountPlanMap(accountPlanIds); 
    // On Update Call; get map of unique key of userid+planid base account plan share map
    if(oldIdToAccountPlanTeamMap <> NULL){   
      uniqueKeyToAccountPlanShareMap = getUniqueKeyToAccountPlanShareMap(userIdstoRemove, accountPlanIds);  
    }
    // iterate unique account share plan map to populate unique account ids 
    // account ids will be used to retreive the list of related account team members.
    for(Account_Plan__c accountPlan : accountPlanMap.values()){
      if(accountPlan.Account__c <> NULL){
        accountIds.add(accountPlan.Account__c);
      }
    }
    // query and iterate account team members for the associated accounts and user ids. 
    // create a mechanism to identify member association as account team member.
    for(AccountTeamMember accTeamMember : [Select UserId, AccountId 
                         FROM AccountTeamMember 
                         WHERE UserId in : userIdstoAdd AND AccountId in : accountIds]){
      string uniqueKey = accTeamMember.UserId + SEPARATOR + accTeamMember.AccountId;                    
      userAccountUniqueKeys.add(uniqueKey);                       
    }
    // re-iterate Trigger.new records
    for(Account_Plan_Team__c accountPlanTeam : newAccountPlanTeams){
        
       if(oldIdToAccountPlanTeamMap == null || (oldIdToAccountPlanTeamMap <> NULL && 
                                               accountPlanTeam.User__c <> oldIdToAccountPlanTeamMap.get(accountPlanTeam.id).User__c)){
            // get the associated account plan for OwnerId and Account__c fields
            Account_Plan__c accountPlan =  accountPlanMap.containsKey(accountPlanTeam.Account_Plan__c) ? accountPlanMap.get(accountPlanTeam.Account_Plan__c) : new Account_Plan__c(); 
           String accountId = accountPlan.Account__c;
           // check if account plan is associated with some account
           if(accountPlanTeam.User__c <> NULL && accountId <> NULL){
            string uniqueKey = accountPlanTeam.User__c + SEPARATOR + accountId;
            // verify that if user is part of account team member; if no then add error with that record
            if(!userAccountUniqueKeys.contains(uniqueKey)){
              accountPlanTeam.addError(USER_NOT_IN_RELATED_ACCOUNT_TEAM);
            }else{
                // plan team member should not be the owner of account plan record; owner has full prevlige already
              if(accountPlan.OwnerId <> accountPlanTeam.User__c){
                tobeInsertedAccountPlanShares.add(getAccountPlanShare(accountPlanTeam.User__c, accountPlanTeam.Account_Plan__c, Constants.ACCESS_LEVEL_EDIT));
              }
              // On Update Call: if new user is associated with the record; we need to make sure that old user's association is removed in the
              // account plan share as we are also removing the member from the account plan team. 
              if(oldIdToAccountPlanTeamMap <> NULL && oldIdToAccountPlanTeamMap.get(accountPlanTeam.id).User__c <> NULL 
                                                   && accountPlanTeam.User__c <> oldIdToAccountPlanTeamMap.get(accountPlanTeam.id).User__c){
                string uniqueShareKey = oldIdToAccountPlanTeamMap.get(accountPlanTeam.id).User__c + SEPARATOR + accountPlanTeam.Account_Plan__c;
                // if there, share record exists only then populate that record in the tobedeleted list..
                if(uniqueKeyToAccountPlanShareMap.containsKey(uniqueShareKey)){
                    tobeDeletedAccountPlanShares.add(uniqueKeyToAccountPlanShareMap.get(uniqueShareKey));
                }
              }
            }     
          }      
        }
    }    
    try{
        // Update: only in case of update we need to remove previous sharings
        if(oldIdToAccountPlanTeamMap <> NULL && !tobeDeletedAccountPlanShares.isEmpty()){
            delete tobeDeletedAccountPlanShares;
        }       
        // in case of insert/update/undelete, we need to create the new sharings
        if(!tobeInsertedAccountPlanShares.isEmpty()){
          insert tobeInsertedAccountPlanShares;
        }
    }catch(DMLException ex){
        apexLogHandler.createLogAndSave('Account_Plan_TeamTriggerHandler','updateAccountPlanShares', ex.getStackTraceString(), ex);
        for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          newAccountPlanTeams.get(0).addError(ex.getDMLMessage(indx));
        }
      }
  }  
  //========================================================================================
  // Utility method to create account plan share records
  //========================================================================================
  public static void createAccountPlanShares(List<Account_Plan_Team__c> newAccountPlanTeams){
    updateAccountPlanShares(newAccountPlanTeams, null);
  }
  
  //========================================================================================
  // Utility method to get existing account plan share records Map
  //========================================================================================
  private static Map<String, Account_Plan__Share> getUniqueKeyToAccountPlanShareMap(Set<Id> userIds, Set<Id> accountPlanIds){
    Map<String, Account_Plan__Share> uniqueIdToAccountPlanShareMap = new Map<String, Account_Plan__Share>();
    for(Account_Plan__Share apShare : [Select UserOrGroupId, ParentId 
                                       From Account_Plan__Share 
                                       WHERE UserOrGroupId IN : userIds 
                                       AND ParentId IN: accountPlanIds
                                       AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual]){
       uniqueIdToAccountPlanShareMap.put(apShare.UserOrGroupId + SEPARATOR + apShare.ParentId, apShare);                                    
    }
    return uniqueIdToAccountPlanShareMap;
  } 
  
  //========================================================================================
  // Utility method to get account plan share record
  //========================================================================================
  private static Account_Plan__Share getAccountPlanShare(String userId, string parentId, string accessLevel){
    return new Account_Plan__Share(
      UserOrGroupId = userId,
      ParentId = parentId,
      AccessLevel = accessLevel,
      RowCause = Schema.Account_Plan__Share.RowCause.Manual
    );
  }  
  //========================================================================================
  // Utility method to retreive account plan map
  //========================================================================================
  private static Map<Id, Account_Plan__c> getAccountPlanMap(Set<Id> accountPlanIds){
    return new Map<Id, Account_Plan__c> ([SELECT Id, Account__c, OwnerId
                                       FROM Account_Plan__c 
                                       WHERE Id in : accountPlanIds]);
  }
  
  //============================================================================
  // Method to update Currency Codes on Account Plan Team
  //============================================================================
  private static void synchCurrencyISOCodes(List<Account_Plan_Team__c> newAccountPlanTeams, 
                                            Map<ID, Account_Plan_Team__c> oldIdToAccountPlanTeamMap){
    Set<String> aPlanIDs = new Set<String>();
    List<Account_Plan_Team__c> lstAPlanTeam = new List<Account_Plan_Team__c>();
    Map<String, Account_Plan__c> mapAPlanId_APlan = new Map<String, Account_Plan__c>();
    
    //Find acc plan Ids related to Acc Plan Team
    for(Account_Plan_Team__c apTeam : newAccountPlanTeams){
        if(oldIdToAccountPlanTeamMap == null || (oldIdToAccountPlanTeamMap.get(apTeam.Id).Account_Plan__c  != apTeam.Account_Plan__c )){
            lstAPlanTeam.add(apTeam);
            aPlanIDs.add(apTeam.Account_Plan__c);
        }
    }
    
    if(!aPlanIDs.isEmpty()){
        for(Account_Plan__c aPlan : [SELECT Id, CurrencyIsoCode, 
                                    (SELECT Id, CurrencyIsoCode From Account_Plan_Teams__r)
                                     From Account_Plan__c 
                                     WHERE ID IN: aPlanIDs]){
            mapAPlanId_APlan.put(aPlan.Id, aPlan);
        }
        // Update Currency Iso code for Account Plan Team
        for(Account_Plan_Team__c apTeam : lstAPlanTeam){
            apTeam.CurrencyISOCode = mapAPlanId_APlan.get(apTeam.Account_Plan__c).CurrencyISOCode;
        }
    }                                           
    
  }
  
}