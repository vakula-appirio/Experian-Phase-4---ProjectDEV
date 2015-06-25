/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTeamMemberTriggerHandler
 * Description: T-266946: Synching OpportunityTeamMembers & Confidential Information Share
 *                        Handler Class for OpportunityTeamMembersTrigger
 * Created Date: Mar 28th, 2014  
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified          Modified By                  Description of the update
 * Mar 31, 2014           Nathalie Le Guay (Appirio)   Removed tabs, updated reference to ConfidentialInformationTriggerHandler (name change)
 * Apr 28, 2014           Rahul Jain                   Added addTeamMembersToOpportunityPlans, deleteTeamMembersFromOpportunityPlans (T-273696)  
 =====================================================================*/
public with sharing class OpportunityTeamMemberTriggerHandler {

  // After Insert call
  public static void afterInsert (List<OpportunityTeamMember> newList) {
    synchOTMsWithConfInfo(newList);
    addTeamMembersToOpportunityPlans(newList);
  }

  // After Update call
  public static void afterUpdate (Map<ID, OpportunityTeamMember> newMap,
                                  Map<ID, OpportunityTeamMember> oldMap) {
    synchOTMsWithConfInfo(newMap.values());
  }

  // After Delete call
  public static void afterDelete (Map<ID, OpportunityTeamMember> oldMap) {
    synchOTMsWithConfInfo(oldMap.values());
    deleteTeamMembersFromOpportunityPlans(oldMap.values());
  }
  
  //================================================================================================
  // EXPERIAN - SALES - Utility method to add opportunity plan share records for plans associated inserted team members
  //================================================================================================
  public static void addTeamMembersToOpportunityPlans(List<OpportunityTeamMember> newOppTeamMember){
    Set<Id> opportunityIds = new Set<Id>();
    Map<Id, List<Opportunity_Plan__c>> oppIdToOpportunityPlanMap = new Map<Id, List<Opportunity_Plan__c>>();
    List<Opportunity_Plan__Share> tobeAddedToOpportunityPlans = new List<Opportunity_Plan__Share>();
    // iterate new opp team member list and populate set of oppids
    for(OpportunityTeamMember oppTeamMember : newOppTeamMember){    
      opportunityIds.add(oppTeamMember.OpportunityId);
    }
    if(!opportunityIds.isEmpty()){
      //retrieve related opportunity plans based on the opportunity ids and populate map of oppids to opp plans list
      for(Opportunity_Plan__c oppPlan :[SELECT OwnerId, Opportunity_Name__c, Id 
                                        FROM Opportunity_Plan__c 
                                        WHERE Opportunity_Name__c in : opportunityIds]){
        if(!oppIdToOpportunityPlanMap.containsKey(oppPlan.Opportunity_Name__c)){
          oppIdToOpportunityPlanMap.put(oppPlan.Opportunity_Name__c, new List<Opportunity_Plan__c>());            
        }
        oppIdToOpportunityPlanMap.get(oppPlan.Opportunity_Name__c).add(oppPlan);                                    
      }
      // re-iterate new opp Team Members and populate new opp plan share records list to be inserted
      for(OpportunityTeamMember oppTeamMember : newOppTeamMember){
        if(oppTeamMember.Opportunityid <> NULL && oppIdToOpportunityPlanMap.containsKey(oppTeamMember.Opportunityid)){
          for(Opportunity_Plan__c oppPlan : oppIdToOpportunityPlanMap.get(oppTeamMember.Opportunityid)){
            // we cannot restrict the access of the owner of the record to read/write from full access
            // therefore leave owner sharing to be inserted
            if(oppPlan.OwnerId <> oppTeamMember.UserId){
              tobeAddedToOpportunityPlans.add(getOpportunityPlanShare(oppTeamMember.UserId, oppPlan.Id, Constants.ACCESS_LEVEL_EDIT));
            }
          } 
        }
      }
      // validte if insert oppty plans list is not empty
      if(!tobeAddedToOpportunityPlans.isEmpty()){
        try{
          insert tobeAddedToOpportunityPlans;
        }catch(DMLException ex){  
          apexLogHandler.createLogAndSave('OpportunityTeamMemberTriggerHandler','addTeamMembersToOpportunityPlans', ex.getStackTraceString(), ex);
          for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
            newOppTeamMember.get(0).addError(ex.getDMLMessage(indx));
          } 
        } 
      }
    } 
  }
  //==================================================================================================
  // Utility method to delete opportunity plan share records for plans associated deleted team members
  //===================================================================================================
  public static void deleteTeamMembersFromOpportunityPlans(List<OpportunityTeamMember> oldOppTeamMember){
  	Set<Id> opportunityIds = new Set<Id>();    
    List<Opportunity_Plan__Share> tobeDeletedFromOpportunityPlans = new List<Opportunity_Plan__Share>();
    Set<String> userIdAndOppIds = new Set<String>();
    Set<Id> userIds = new Set<Id>();
    Map<Id, Id> oppPlanToOppIdMap = new Map<Id, Id>();
    string SEPARATOR = ':';
    // iterate new opp team member list and populate set of oppids
    for(OpportunityTeamMember oppTeamMember : oldOppTeamMember){    
      opportunityIds.add(oppTeamMember.OpportunityId);
      userIds.add(oppTeamMember.UserId);
      userIdAndOppIds.add(oppTeamMember.UserId + SEPARATOR + oppTeamMember.OpportunityId);
    }
    // check opp id is not null
    if(!opportunityIds.isEmpty()){
    	  // retrieve opp plan records associated to opportunities
        for(Opportunity opp : [Select Id, (Select Id From Opportunity_Plans__r) 
                              From Opportunity where id in : opportunityIds]){
          for(Opportunity_Plan__c oppPlan : opp.Opportunity_Plans__r){
          	oppPlanToOppIdMap.put(oppPlan.id, opp.id);
          }                      	
        }
        // check if opp plans exists in the system or not.
        if(!oppPlanToOppIdMap.keySet().isEmpty()){
          for(Opportunity_Plan__Share oppPlanShare : [Select UserOrGroupId, ParentId 
                                             From Opportunity_Plan__Share 
                                             WHERE UserOrGroupId in : userIds
                                             AND ParentId in: oppPlanToOppIdMap.keySet()
                                             AND RowCause =: Schema.Opportunity_Plan__Share.RowCause.Manual]){
            string userIdAndOppId = oppPlanShare.UserOrGroupId + SEPARATOR + oppPlanToOppIdMap.get(oppPlanShare.parentId);
            if(userIdAndOppIds.contains(userIdAndOppId)){
              tobeDeletedFromOpportunityPlans.add(oppPlanShare);
            }                             	
          }
          if(!tobeDeletedFromOpportunityPlans.isEmpty()){
          	try{
		          delete tobeDeletedFromOpportunityPlans;
		        }catch(DMLException ex){  
		          apexLogHandler.createLogAndSave('OpportunityTeamMemberTriggerHandler','deleteTeamMembersFromOpportunityPlans', ex.getStackTraceString(), ex);
		          for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
		            oldOppTeamMember.get(0).addError(ex.getDMLMessage(indx));
		          }
		        }
          }                                   
        }                                  
    }
  }
 
  //========================================================================================
  // Utility method to get opportunity plan share record
  //========================================================================================
  private static Opportunity_Plan__Share getOpportunityPlanShare(String userId, string parentId, string accessLevel){
    return new Opportunity_Plan__Share(
      UserOrGroupId = userId,
      ParentId = parentId,
      AccessLevel = accessLevel,
      RowCause = Schema.Opportunity_Plan__Share.RowCause.Manual
    );
  }  
  

  // Call Synch on given Opp's Team Members' list
  private static void synchOTMsWithConfInfo (List<OpportunityTeamMember> teamList) {
    Set<ID> opptyIDs = new Set<ID>();

    for (OpportunityTeamMember otm : teamList) {
      opptyIDs.add(otm.OpportunityId);
    }
    synchOpptyWithConfidentialInformation(opptyIDs);
  }

  // Call synchronize with passing OpportunityIDs and ConfiInfo list
  //@future
  private static void synchOpptyWithConfidentialInformation (Set<Id> opptyIDs) {
    Set<Id> confInfoToDelShares = new Set<Id>();
    List<Confidential_Information__c> confInfoList = new List<Confidential_Information__c>();
    List<Confidential_Information__Share> confShares = new List<Confidential_Information__Share>();

    for (Confidential_Information__c confidential : [SELECT Id, Opportunity__c,
                                                            (SELECT Id
                                                             FROM Shares
                                                             WHERE RowCause =: Constants.ROWCAUSE_OPPTY_TEAM)
                                                     FROM Confidential_Information__c
                                                     WHERE Opportunity__c IN: opptyIDs 
                                                           AND Synch_Opportunity_Team_Members__c = true]) {
      confInfoList.add(confidential);
      confInfoToDelShares.add(confidential.ID);
      if (confidential.Shares.size() > 0) {
        confShares.addAll(confidential.Shares);
      }
    }

    if (confShares.size() > 0) {
      delete confShares;
    }

    ConfidentialInformationTriggerHandler.createConfidentialInfoShare (opptyIDs, confInfoList);
  }
}