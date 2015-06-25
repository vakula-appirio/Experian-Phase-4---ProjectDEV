/**=====================================================================
 * Appirio, Inc
 * Name: Opportunity_PlanTriggerHandler
 * Description: Handler class for Opportunity_PlanTrigger.trigger (for T-273695)
 * Created Date: April 25th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified          Modified By                    Description of the update
 * April 30th, 2014       Sonal Shrivastava (Appirio)    T-273788: Update related opportunity records
 * May 01st, 2014         Arpita Bose(Appirio)           Updated catch(Exception) to catch(DMLException) to use getDMLException 
 * Jun 13th, 2014         Arpita Bose (Appirio)          T-278460: Added a method createOppPlanContactAndCompetitor() to create 
 *                                                       Opp Plan Contact Role and Opp Plan Competitor
 * July 3rd, 2014         Anjali K (Appirio)    		 I-119058: Oppty Owner should not change 
 * July  17th, 2014       Arpita Bose(Appirio)           I-120989: Added synchCurrencyISOCodes()method to synch currencies with Opportunity
 * Feb 12th, 2015         Paul Kissick                   Case #530086 : Added 'IsActive = true' to query for opp team members
  =====================================================================*/
public with sharing class Opportunity_PlanTriggerHandler { 
    
  public static Boolean isInsertDone = false;
  //=========================================================================
  // Before Insert Call
  //=========================================================================
  public static void beforeInsert(List<Opportunity_Plan__c>newList){
  	synchCurrencyISOCodes(newList, null);
  }
  
  //=========================================================================
  // Before Update Call
  //=========================================================================
  public static void beforeUpdate(List<Opportunity_Plan__c> newList, 
                                    Map<ID, Opportunity_Plan__c> oldMap){
    synchCurrencyISOCodes(newList, oldMap); 
  }
    
  //=========================================================================
  // After Insert Call
  //=========================================================================
  public static void afterInsert(List<Opportunity_Plan__c> newOpportunityPlans){
  	Set<Id> relatedOpportunityIds = new Set<Id>();
  	// iterate newly inserted opp plans get list of related opportunity ids
  	for(Opportunity_Plan__c newOpportunityPlan : newOpportunityPlans){
  		if(newOpportunityPlan.Opportunity_Name__c <> null){  		
  		  relatedOpportunityIds.add(newOpportunityPlan.Opportunity_Name__c);
  		}
  	}
  	// check if there are any oppotunities associated to opp plans
  	if(!relatedOpportunityIds.isEmpty()){  	
  	  sharePlansWithOppTeamMembers(newOpportunityPlans, relatedOpportunityIds);  	
  	}
  	updateRelatedOpportunities(newOpportunityPlans, null);
  	createOppPlanContactAndCompetitor(newOpportunityPlans);   // T-278460
  	
  	if(!isInsertDone){
  		isInsertDone = true;
  		
  		set<String> newOPId = new set<String>();
  		for(Opportunity_Plan__c objOP : newOpportunityPlans){
  			newOPId.add(objOP.Id);
  		}
  		
  		List<Opportunity_Plan__c> lstNewOP = [Select o.Value_Propositions__c, o.Value_Proposition__c, o.Understand_Roles__c, o.SystemModstamp, 
  		o.Summary_Position_Today__c, o.Strengths__c, o.Strength_5_Rating__c, o.Strength_4_Rating__c, o.Strength_3_Rating__c, o.Strength_2_Rating__c,
  		o.Strength_1_Rating__c, o.Solution_at_a_Glance__c, o.Solution__c, o.Solution_Fulfils_Requirements__c, o.Sales_Process__c, 
  		o.Sales_Objective_5__c, o.Sales_Objective_4__c, o.Sales_Objective_3__c, o.Sales_Objective_2__c, o.Sales_Objective_1__c, o.SO_5_Importance__c, 
  		o.SO_4_Importance__c, o.SO_3_Importance__c, o.SO_2_Importance__c, o.SO_1_Importance__c, o.Risk_5_Rating__c, o.Risk_4_Rating__c, 
  		o.Risk_3_Rating__c, o.Risk_2_Rating__c, o.Risk_1_Rating__c, o.Resources_Available__c, o.Resource_Investment__c, 
  		o.Resource_Investment_Confidence__c, o.Reliable_Coach__c, o.Qualification_Profile__c, o.Project_High_Priority__c, o.Potential__c, o.OwnerId, 
  		o.Overall_Score__c, o.Opportunity_TCV__c, o.Opportunity_Sales_Stage__c, o.Opportunity_Probability__c, o.Opportunity_Owner__c, 
  		o.Opportunity_Name__c, o.Opportunity_Historypercent__c, o.Opportunity_History__c, o.Opportunity_Expected_Close_Date__c, 
  		o.Opportunity_Client_Budget__c, o.Objectives_and_Requirements__c, o.Name, o.LastModifiedDate, o.LastModifiedById, o.LastActivityDate, 
  		o.Known_Project_Budget__c, o.Known_Competition__c, o.Known_Buying_Process__c, o.Justifiable_Investment__c, o.Joint_Action_Plan__c, o.IsDeleted, 
  		o.Id, o.Goals_and_Decision_Criteria__c, o.Exp_Strength_5__c, o.Exp_Strength_4__c, o.Exp_Strength_3__c, o.Exp_Strength_2__c, o.Exp_Strength_1__c, 
  		o.Exp_Risk_5__c, o.Exp_Risk_4__c, o.Exp_Risk_3__c, o.Exp_Risk_2__c, o.Exp_Risk_1__c, o.CurrencyIsoCode, o.CreatedDate, o.CreatedById, 
  		o.Competition__c, o.Coach__c, o.Client_Goal_5__c, o.Client_Goal_4__c, o.Client_Goal_3__c, o.Client_Goal_2__c, o.Client_Goal_1__c, 
  		o.Client_Budget_Confidence__c, o.CG_5_Importance__c, o.CG_4_Importance__c, o.CG_3_Importance__c, o.CG_2_Importance__c, o.CG_1_Importance__c, 
  		o.Buying_Center_Analysis__c, o.Benefits__c, o.Annual_Potential_Growth__c, o.Annual_Potential_Growth_Confidence__c, o.Action_Plan__c, 
  		o.Action_Item_Solution_Deadline__c, o.Action_Item_Solution_Completed__c, o.Action_Item_Needs_Analysis_Deadline__c, 
  		o.Action_Item_Needs_Analysis_Completed__c, o.Action_Item_Initial_Discussions_Deadline__c, o.Action_Item_Initial_Discussions_Complete__c, 
  		o.Action_Item_Fulfillment_Deadline__c, o.Action_Item_Fulfillment_Completed__c, o.Account_Name__c From Opportunity_Plan__c o where o.Id IN : newOPId];
  		
  		captureOpptyPlanScore(lstNewOP);
  		update lstNewOP;
  	}
  }
  
  //=========================================================================
  // After Update Call
  //=========================================================================
  public static void afterUpdate(List<Opportunity_Plan__c> newList, 
                                 Map<Id, Opportunity_Plan__c> oldMap){
	updateRelatedOpportunities(newList, oldMap);
	
	if(!isInsertDone){
  		isInsertDone = true;
  		
  		set<String> newOPId = new set<String>();
  		for(Opportunity_Plan__c objOP : newList){
  			newOPId.add(objOP.Id);
  		}
  		
  		List<Opportunity_Plan__c> lstNewOP = [Select o.Value_Propositions__c, o.Value_Proposition__c, o.Understand_Roles__c, o.SystemModstamp, 
  		o.Summary_Position_Today__c, o.Strengths__c, o.Strength_5_Rating__c, o.Strength_4_Rating__c, o.Strength_3_Rating__c, o.Strength_2_Rating__c,
  		o.Strength_1_Rating__c, o.Solution_at_a_Glance__c, o.Solution__c, o.Solution_Fulfils_Requirements__c, o.Sales_Process__c, 
  		o.Sales_Objective_5__c, o.Sales_Objective_4__c, o.Sales_Objective_3__c, o.Sales_Objective_2__c, o.Sales_Objective_1__c, o.SO_5_Importance__c, 
  		o.SO_4_Importance__c, o.SO_3_Importance__c, o.SO_2_Importance__c, o.SO_1_Importance__c, o.Risk_5_Rating__c, o.Risk_4_Rating__c, 
  		o.Risk_3_Rating__c, o.Risk_2_Rating__c, o.Risk_1_Rating__c, o.Resources_Available__c, o.Resource_Investment__c, 
  		o.Resource_Investment_Confidence__c, o.Reliable_Coach__c, o.Qualification_Profile__c, o.Project_High_Priority__c, o.Potential__c, o.OwnerId, 
  		o.Overall_Score__c, o.Opportunity_TCV__c, o.Opportunity_Sales_Stage__c, o.Opportunity_Probability__c, o.Opportunity_Owner__c, 
  		o.Opportunity_Name__c, o.Opportunity_Historypercent__c, o.Opportunity_History__c, o.Opportunity_Expected_Close_Date__c, 
  		o.Opportunity_Client_Budget__c, o.Objectives_and_Requirements__c, o.Name, o.LastModifiedDate, o.LastModifiedById, o.LastActivityDate, 
  		o.Known_Project_Budget__c, o.Known_Competition__c, o.Known_Buying_Process__c, o.Justifiable_Investment__c, o.Joint_Action_Plan__c, o.IsDeleted, 
  		o.Id, o.Goals_and_Decision_Criteria__c, o.Exp_Strength_5__c, o.Exp_Strength_4__c, o.Exp_Strength_3__c, o.Exp_Strength_2__c, o.Exp_Strength_1__c, 
  		o.Exp_Risk_5__c, o.Exp_Risk_4__c, o.Exp_Risk_3__c, o.Exp_Risk_2__c, o.Exp_Risk_1__c, o.CurrencyIsoCode, o.CreatedDate, o.CreatedById, 
  		o.Competition__c, o.Coach__c, o.Client_Goal_5__c, o.Client_Goal_4__c, o.Client_Goal_3__c, o.Client_Goal_2__c, o.Client_Goal_1__c, 
  		o.Client_Budget_Confidence__c, o.CG_5_Importance__c, o.CG_4_Importance__c, o.CG_3_Importance__c, o.CG_2_Importance__c, o.CG_1_Importance__c, 
  		o.Buying_Center_Analysis__c, o.Benefits__c, o.Annual_Potential_Growth__c, o.Annual_Potential_Growth_Confidence__c, o.Action_Plan__c, 
  		o.Action_Item_Solution_Deadline__c, o.Action_Item_Solution_Completed__c, o.Action_Item_Needs_Analysis_Deadline__c, 
  		o.Action_Item_Needs_Analysis_Completed__c, o.Action_Item_Initial_Discussions_Deadline__c, o.Action_Item_Initial_Discussions_Complete__c, 
  		o.Action_Item_Fulfillment_Deadline__c, o.Action_Item_Fulfillment_Completed__c, o.Account_Name__c From Opportunity_Plan__c o where o.Id IN : newOPId];
  		
  		captureOpptyPlanScore(lstNewOP);
      update lstNewOP;
  	}
  }
  
  //========================================================================================
  // Generic/Utility method to create apex sharing on opp plans with the associated opp team members
  //========================================================================================
  public static void sharePlansWithOppTeamMembers(List<Opportunity_Plan__c> newOpportunityPlans, Set<Id> relatedOpportunityIds){  	
  	List<Opportunity_Plan__Share> toBeInsertedOppPlanShares = new List<Opportunity_Plan__Share>();
  	// get a collection of associated opp teammembers based on opportunity
	  Map<Id, Set<Id>> oppIdToOppTeamMembersIdMap = getOppIdToOppTeamMembersIdMap(relatedOpportunityIds);
	  if(!oppIdToOppTeamMembersIdMap.isEmpty()){
	  	// re-iterate the newly inserted opportunity plans to generate sharing records for each opp team member associated to the opp plan
	    for(Opportunity_Plan__c newOpportunityPlan : newOpportunityPlans){
	    	// check if there are any team member associate with related opportunity
	      if(newOpportunityPlan.Opportunity_Name__c <> null && oppIdToOppTeamMembersIdMap.containsKey(newOpportunityPlan.Opportunity_Name__c)){
	      	// iterate with each team member and generate a sharing record for each with the associated plan     
	        for(Id teamMemberId : oppIdToOppTeamMembersIdMap.get(newOpportunityPlan.Opportunity_Name__c)){
	        	// because owner has full access on the record; we don't need to create a share record for owner
	        	if(teamMemberId <> newOpportunityPlan.ownerId){
	            toBeInsertedOppPlanShares.add(getOpportunityPlanShare(teamMemberId, newOpportunityPlan.id, Constants.ACCESS_LEVEL_EDIT)); 
	        	}    
	        }
	      }
	    }
	  }  
	  // check if there are any sharing records to be inserted  
    if(!toBeInsertedOppPlanShares.isEmpty()){
      try{
        insert toBeInsertedOppPlanShares;
      }catch(DMLException ex){  
        apexLogHandler.createLogAndSave('Opportunity_PlanTriggerHandler','sharePlansWithOppTeamMembers', ex.getStackTraceString(), ex);
        for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          newOpportunityPlans.get(0).addError(ex.getDMLMessage(indx));
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
  //========================================================================================
  // Utility method to get a collection of associated opp teammembers based on opportunity
  //========================================================================================
  private static Map<Id, Set<Id>> getOppIdToOppTeamMembersIdMap(Set<Id> relatedOpportunityIds){
  	Map<Id, Set<Id>> oppIdToOppTeamMembersIdMap = new Map<Id, Set<Id>>();
  	// iterate all the opp team members for list if opportunities
  	// PK: Case #530086 - Added User.IsActive = true to below query.
  	for(OpportunityTeamMember oppTeamMember : [SELECT UserId, OpportunityId
  	                                           FROM OpportunityTeamMember
  	                                           WHERE OpportunityId IN : relatedOpportunityIds
  	                                           AND User.IsActive = true
  	                                           ]){
  	  // populate them in the collection                                         	
  	  if(!oppIdToOppTeamMembersIdMap.containsKey(oppTeamMember.OpportunityId)){  	  	
  	  	oppIdToOppTeamMembersIdMap.put(oppTeamMember.OpportunityId, new Set<Id>());
  	  }  	  
  	  oppIdToOppTeamMembersIdMap.get(oppTeamMember.OpportunityId).add(oppTeamMember.UserId);  	    
  	}
  	return oppIdToOppTeamMembersIdMap;
  }
  
  //========================================================================================
  // Utility method to update related Opportunities
  //========================================================================================
  private static void updateRelatedOpportunities(List<Opportunity_Plan__c> newOpportunityPlans, 
                                                 Map<Id, Opportunity_Plan__c> oldOppPlanIdToOppPlanMap){
    
    Boolean isInsert = Trigger.isInsert;
    Map<Id,Opportunity> mapModifiedOpportunities = new Map<Id,Opportunity>();
    for(Opportunity_Plan__c oppPlan : newOpportunityPlans ){
      if(oppPlan.Opportunity_Name__c <> null){
        //Check if it is insert case OR the OwnerId/ClientBudget fields on Opportunity Plan have been updated
        if(isInsert || ((oppPlan.OwnerId <> oldOppPlanIdToOppPlanMap.get(oppPlan.Id).OwnerId) || 
                    (oppPlan.Opportunity_Client_Budget__c <> oldOppPlanIdToOppPlanMap.get(oppPlan.Id).Opportunity_Client_Budget__c ) || 
                    (oppPlan.Opportunity_Expected_Close_Date__c <> oldOppPlanIdToOppPlanMap.get(oppPlan.Id).Opportunity_Expected_Close_Date__c ))){
          mapModifiedOpportunities.put(oppPlan.Opportunity_Name__c,new Opportunity( 
                                                                              Id        = oppPlan.Opportunity_Name__c,
                                                                              //OwnerId   = oppPlan.OwnerId, //Commented as per I-119058 (Anjali K on 3rd July 2014)
                                                                              Budget__c = oppPlan.Opportunity_Client_Budget__c,
                                                                              CloseDate = oppPlan.Opportunity_Expected_Close_Date__c));
        }
      }
    }
    // check if there are any Opportunity records to be updated 
    if(!mapModifiedOpportunities.isEmpty()){
      try{
        update mapModifiedOpportunities.values();
      }catch(DMLException ex){  
        apexLogHandler.createLogAndSave('Opportunity_PlanTriggerHandler','updateRelatedOpportunities', ex.getStackTraceString(), ex);
        for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          newOpportunityPlans.get(0).addError(ex.getDMLMessage(indx));
        }
      } 
    }   
  }
  //==============================================================================================
  //T-278460: Creates Opp Plan Contact records for all Opp Contact Role on the related Oppty and
  //Opp Plan Competitor records for all Competitor on the related Oppty
  //==============================================================================================
  
  public static void createOppPlanContactAndCompetitor(List<Opportunity_Plan__c> newOpportunityPlans) {
  	Set<Id> relatedOpportunityIds = new Set<Id>();
    Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
    List<Opportunity_Plan_Contact__c> listOppPlanConToInsert = new List<Opportunity_Plan_Contact__c>();
    List<Opportunity_Plan_Competitor__c> listOppPlanCompeToInsert = new List<Opportunity_Plan_Competitor__c>();
    
    try {
      for(Opportunity_Plan__c newOpportunityPlan : newOpportunityPlans) {
        if(newOpportunityPlan.Opportunity_Name__c <> null) {
          relatedOpportunityIds.add(newOpportunityPlan.Opportunity_Name__c);
        }
      }
      for (Opportunity opp : [SELECT Id,
                             (SELECT Id, Role, ContactId, OpportunityId FROM OpportunityContactRoles),
                             (SELECT Id, Name FROM Competitors__r)
                              FROM Opportunity WHERE ID IN :relatedOpportunityIds]) {
        newOppMap.put(opp.Id, opp);                      	
      }
      for (Opportunity_Plan__c oppPlan : newOpportunityPlans) {
    	  //If Opportunity plan do not exits in queried Opptortunities, will continue for next plan.
    	  if (!newOppMap.containsKey(oppPlan.Opportunity_Name__c)) {
    	  	continue;
    	  }
    	  
    	  if (newOppMap.get(oppPlan.Opportunity_Name__c).OpportunityContactRoles.size() > 0 ) {
    		  for (OpportunityContactRole opp_ContRole : newOppMap.get(oppPlan.Opportunity_Name__c).OpportunityContactRoles) {
    	      //Create Opp plan contact for all Oppty Contact role on the related oppty
    	      Opportunity_Plan_Contact__c oppContact = new Opportunity_Plan_Contact__c();
    	      oppContact.Opportunity_Plan__c = oppPlan.Id;
    	      oppContact.Contact__c = opp_ContRole.ContactId;
    	      listOppPlanConToInsert.add(oppContact);
    	    }
        }
        if (newOppMap.get(oppPlan.Opportunity_Name__c).Competitors__r.size() > 0 ) {
          for (Competitor__c  competitor : newOppMap.get(oppPlan.Opportunity_Name__c).Competitors__r) {
            //Create Opp plan competitor for all Competitor on related oppty
            Opportunity_Plan_Competitor__c oppCompetitor = new Opportunity_Plan_Competitor__c();
            oppCompetitor.Opportunity_Plan__c =  oppPlan.Id;
            oppCompetitor.Competitor__c =  competitor.Id;
            listOppPlanCompeToInsert.add(oppCompetitor);
          }
        }
      }
      try {
        if (!listOppPlanConToInsert.isEmpty()) {
          insert listOppPlanConToInsert;
        }
        if (!listOppPlanCompeToInsert.isEmpty()) {
          insert listOppPlanCompeToInsert;
        }
      } catch (DMLException ex) {
        System.debug('\n[Opportunity_PlanTriggerHandler: createOppPlanContactAndCompetitor]: [' + ex.getMessage() + ']]');
        apexLogHandler.createLogAndSave('Opportunity_PlanTriggerHandler','createOppPlanContactAndCompetitor', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newOpportunityPlans.get(0).addError(ex.getDmlMessage(i));
        }
      }  	
    } catch (Exception ex) {
      System.debug('\n[Opportunity_PlanTriggerHandler: createOppPlanContactAndCompetitor]: ['+ex.getMessage()+']]');
      apexLogHandler.createLogAndSave('Opportunity_PlanTriggerHandler','createOppPlanContactAndCompetitor', ex.getStackTraceString(), ex); 
      newOpportunityPlans.get(0).addError(ex.getMessage());
      }
    }


  //==========================================================================
  // T-289204: Capture info from VF page
  //==========================================================================
  public static void captureOpptyPlanScore(List<Opportunity_Plan__c> newList) {
  	if(mapScoreCalcMaster.size() == 0){
  		return;
  	}
    Map<Id, List<Opp_Plan_Score_Sub_Calc__c>> scoreCalculationObjectMap = new Map<Id, List<Opp_Plan_Score_Sub_Calc__c>>();
    Set<String> objectNamesSet = new Set<String>();
    Map<String, Set<String>> methodObjectNamesMap = new Map<String, Set<String>>();

    Set<Id> opIds = new Set<Id>();
    for(Opportunity_Plan__c op : newList) {
      opIds.add(op.Id);
    }

    Set<Id> opptyIds = new Set<Id>();
    Map<Id, Id> opptyPlanOpptyIdsMap = new Map<Id, Id>();

    for(Opportunity_Plan__c op : newList) {
      opptyIds.add(op.Opportunity_Name__c);
      opptyPlanOpptyIdsMap.put(op.Id, op.Opportunity_Name__c);
    }

    Map<Id, List<OpportunityTeamMember>> opptyTeamMembersMap = new Map<Id, List<OpportunityTeamMember>>();
    for(OpportunityTeamMember otm : [SELECT TeamMemberRole, OpportunityAccessLevel ,OpportunityId
                                             FROM OpportunityTeamMember 
                                             WHERE OpportunityId IN : opptyIds]) {
      if(!opptyTeamMembersMap.containsKey(otm.OpportunityId)) {
        opptyTeamMembersMap.put(otm.OpportunityId, new List<OpportunityTeamMember>());
      }
      opptyTeamMembersMap.get(otm.OpportunityId).add(otm);
    }

    Set<Id> opscIds = new Set<Id>();
    for(Opp_Plan_Score_Calc__c opsc : mapScoreCalcMaster.values()) {
      opscIds.add(opsc.Id);
    }

    for(Opp_Plan_Score_Sub_Calc__c opssc : [SELECT Id, Name, Calculation_Field__c, Controlling_Field__c, Controlling_Field_2__c,
                                            Object_API_Name__c, Opp_Plan_Score_Calc__c, Score__c 
                                            FROM Opp_Plan_Score_Sub_Calc__c
                                            WHERE Opp_Plan_Score_Calc__c IN : opscIds]) {
      if(!scoreCalculationObjectMap.containsKey(opssc.Opp_Plan_Score_Calc__c)) {
        scoreCalculationObjectMap.put(opssc.Opp_Plan_Score_Calc__c, new List<Opp_Plan_Score_Sub_Calc__c>());
      }
      scoreCalculationObjectMap.get(opssc.Opp_Plan_Score_Calc__c).add(opssc);

      if(!methodObjectNamesMap.containsKey(opssc.Opp_Plan_Score_Calc__c)) {
        methodObjectNamesMap.put(opssc.Opp_Plan_Score_Calc__c, new Set<String>());
      }
      methodObjectNamesMap.get(opssc.Opp_Plan_Score_Calc__c).add(opssc.Object_API_Name__c);

      objectNamesSet.add(opssc.Object_API_Name__c);
    }

    system.debug('methodObjectNamesMap ::::::: ' + methodObjectNamesMap);

    Map<String, Map<String, List<SObject>>> objNameRecordsMap = new Map<String, Map<String, List<SObject>>>();
    for(String objName : objectNamesSet) {
      Map<String, List<SObject>> recordsMap = getSObjectRecords(objName, opIds,false);
      objNameRecordsMap.put(objName, recordsMap);
      Set<Id> opcIds = new Set<Id>();
      if(objName == 'Opportunity_Plan_Contact__c') {
        for(List<SObject> objList : recordsMap.values()) {
          for(SObject obj : objList) {
            if(obj.get('Reports_to__c') != null) {
              opcIds.add(((Opportunity_Plan_Contact__c)obj).Reports_to__c);
            }
          }
        }
        if(opcIds.size() > 0) {
          objNameRecordsMap.get(objName).putAll(getSObjectRecords('Opportunity_Plan_Contact__c', opcIds,true));
        }
      }
    }

    for(Opportunity_Plan__c op : newList) {
		Map<String, Map<String, List<SObject>>> objNameRecordsMapTmp = new Map<String, Map<String, List<SObject>>>();
		Map<String, List<SObject>> recordsMapTmp;
		
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Information Scoring').Id)){
		System.debug('Information Scoring :::::: ' + methodName);
		  objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}
		op.Opportunity_Historypercent__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod(mapScoreCalcMaster.get('Information Scoring'),
		scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Information Scoring').Id),objNameRecordsMapTmp,op.id), opptyTeamMembersMap.get(op.Opportunity_Name__c), mapScoreCalcMaster.get('Information Scoring'));
		
		objNameRecordsMapTmp.clear();
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Qualification Scoring').Id)){
			System.debug('Qualification Scoring :::::: ' + methodName);
			objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}
		op.Qualification_Profile__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod(mapScoreCalcMaster.get('Qualification Scoring'),
		scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Qualification Scoring').Id),objNameRecordsMapTmp,op.id), null, mapScoreCalcMaster.get('Qualification Scoring'));
		
		objNameRecordsMapTmp.clear();
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Buying Centre').Id)){
			System.debug('Buying Centre :::::: ' + methodName);
			objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}
		op.Buying_Center_Analysis__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod_BuyingCentre(mapScoreCalcMaster.get('Buying Centre'),
		scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Buying Centre').Id),objNameRecordsMapTmp,op.id), null, mapScoreCalcMaster.get('Buying Centre'));
		
		objNameRecordsMapTmp.clear();
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Competition Scoring').Id)){
			System.debug('Competition Scoring :::::: ' + methodName);
			objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}
		op.Competition__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod(mapScoreCalcMaster.get('Competition Scoring')
		,scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Competition Scoring').Id),objNameRecordsMapTmp,op.id), null, mapScoreCalcMaster.get('Competition Scoring'));
		
		objNameRecordsMapTmp.clear();
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Summary Position').Id)){
		  objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}
		op.Summary_Position_Today__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod(mapScoreCalcMaster.get('Summary Position')
		,scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Summary Position').Id),objNameRecordsMapTmp,op.id), null, mapScoreCalcMaster.get('Summary Position'));
		
		objNameRecordsMapTmp.clear();
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Solution at a Glance').Id)){
		  objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}
		op.Solution_at_a_Glance__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod(mapScoreCalcMaster.get('Solution at a Glance')
		,scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Solution at a Glance').Id),objNameRecordsMapTmp,op.id), null, mapScoreCalcMaster.get('Solution at a Glance'));
		
		objNameRecordsMapTmp.clear();
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Joint Action Plan').Id)){
		  objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}
		op.Joint_Action_Plan__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod(mapScoreCalcMaster.get('Joint Action Plan')
		,scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Joint Action Plan').Id),objNameRecordsMapTmp,op.id), null, mapScoreCalcMaster.get('Joint Action Plan'));
		
		objNameRecordsMapTmp.clear();
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Value Proposition').Id)){
		  objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}
		op.Value_Propositions__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod(mapScoreCalcMaster.get('Value Proposition')
		,scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Value Proposition').Id),objNameRecordsMapTmp,op.id), null, mapScoreCalcMaster.get('Value Proposition'));
		
		objNameRecordsMapTmp.clear();
		for(String methodName : methodObjectNamesMap.get(mapScoreCalcMaster.get('Action Plan').Id)){
		  objNameRecordsMapTmp.put(methodName,objNameRecordsMap.get(methodName));
		}		
		op.Action_Plan__c = finalizeScore(Opportunity_PlanTriggerHandler.calculateMethod(mapScoreCalcMaster.get('Action Plan')
		,scoreCalculationObjectMap.get(mapScoreCalcMaster.get('Action Plan').Id),objNameRecordsMapTmp,op.id), null, mapScoreCalcMaster.get('Action Plan'));
  		
  		op.Overall_Score__c = (op.Action_Plan__c + op.Value_Propositions__c + op.Opportunity_Historypercent__c +
  								op.Qualification_Profile__c + op.Buying_Center_Analysis__c + op.Competition__c + op.Summary_Position_Today__c +
  								op.Joint_Action_Plan__c + op.Solution_at_a_Glance__c)/ 9;
    }

  }

  /* Helper method for Method wise calculate Score */
  private static Decimal calculateMethod(Opp_Plan_Score_Calc__c objMethod, List<Opp_Plan_Score_Sub_Calc__c> lstScore, Map<String, Map<String, List<SObject>>> objectRecordMaps, Id currentId){
    Decimal score = 0;
    //List<Opp_Plan_Score_Sub_Calc__c> lstScore = getScoreCalculationObject(objMethod.Id);
    
   Map<String, Set<String>> mapFields = new Map<String, Set<String>>();
    for(Opp_Plan_Score_Sub_Calc__c obj :lstScore){
      if(mapFields.containsKey(obj.Object_API_Name__c) == false){
        mapFields.put(obj.Object_API_Name__c, new Set<String>());
      }
      if(obj.Calculation_Field__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Calculation_Field__c);
      }
      if(obj.Controlling_Field__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Controlling_Field__c);
      }
      if(obj.Controlling_Field_2__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Controlling_Field_2__c);
      }
    }
    
    for(String objectName : objectRecordMaps.keySet()) {
    	
      Set<String> setFields = mapFields.get(objectName);
      List<SObject> relatedObjectList = objectRecordMaps.get(objectName).get(currentId);
      //if(relatedObjectList == null) continue;
      // For Action Plan consider 4 records of Task;
      if(objMethod.Name.equalsIgnoreCase('Action Plan') || objMethod.Name.equalsIgnoreCase('Joint Action Plan')){
        if(relatedObjectList != null && relatedObjectList.size() > 0){
          for(SObject obj :relatedObjectList){
            score = score + calculateFieldsScore(lstScore, obj, setFields);
          }
        }
      }
      else{
      	if(relatedObjectList != null && relatedObjectList.size() > 0){
          score = score + calculateFieldsScore(lstScore, relatedObjectList.get(0), setFields);
        }
      }
    }
    
    return score;
  }

  /* Helper method for BuyingCentre */
  private static Decimal calculateMethod_BuyingCentre(Opp_Plan_Score_Calc__c objMethod, List<Opp_Plan_Score_Sub_Calc__c> lstScore, Map<String, Map<String, List<SObject>>> objectRecordMaps, Id currentId){
    Decimal score = 0;
    Map<String, Set<String>> mapFields = new Map<String, Set<String>>();
    for(Opp_Plan_Score_Sub_Calc__c obj :lstScore){
      if(mapFields.containsKey(obj.Object_API_Name__c) == false){
        mapFields.put(obj.Object_API_Name__c, new Set<String>());
      }
      if(obj.Calculation_Field__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Calculation_Field__c);
      }
      if(obj.Controlling_Field__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Controlling_Field__c);
      }
      if(obj.Controlling_Field_2__c != null){
        mapFields.get(obj.Object_API_Name__c).add(obj.Controlling_Field_2__c);
      }
    }
    
    Set<String> setOPContactFields = mapFields.get('Opportunity_Plan_Contact__c');
    List<SObject> relatedObjectList = objectRecordMaps.get('Opportunity_Plan_Contact__c').get(currentId);
    if(relatedObjectList == null) return score;
    
    Opportunity_Plan_Contact__c objContact = (Opportunity_Plan_Contact__c)relatedObjectList.get(0);
    score = score + calculateFieldsScore(lstScore, relatedObjectList.get(0), setOPContactFields);
    
    // Calculate Contact's Fields on Opportunity Plan Contact
    if(objContact.Contact__c != null){
      Set<String> setContactFields = mapFields.get('Contact');
      if(objectRecordMaps.get('Contact') == null || objectRecordMaps.get('Contact').get(objContact.Contact__c) == null) return score;      
      List<SObject> relatedObjectList2 = objectRecordMaps.get('Contact').get(objContact.Contact__c);
      score = score + calculateFieldsScore(lstScore, relatedObjectList2.get(0), setContactFields);
    }
    
    // Calculate Opportunity Plan Contact Self Lookup Check Reports_to__c
    Id selfLookupForOpportunityPlan;
    if(objContact.get('Reports_to__c') != null){
      selfLookupForOpportunityPlan = (Id)relatedObjectList.get(0).get('Reports_to__c');
    }
      
    if(selfLookupForOpportunityPlan != null){
      List<SObject> relatedObjectList3 = objectRecordMaps.get('Opportunity_Plan_Contact__c').get(selfLookupForOpportunityPlan);
      if(relatedObjectList3 == null) return score;
      score = score + calculateFieldsScore(lstScore, relatedObjectList3.get(0), setOPContactFields);
    }
    
    return score;
  }

  /*  Helper method for Calculate Fields Values defined at Opp_Plan_Score_Sub_Calc__c */
  private static decimal calculateFieldsScore(List<Opp_Plan_Score_Sub_Calc__c>lstScore, sObject relatedObject, Set<String> setFields){
    Decimal resultScore = 0;
    for(Opp_Plan_Score_Sub_Calc__c obj : lstScore){
      if(setFields != null && setFields.contains(obj.Calculation_Field__c) == false){
        continue;
      }
      String calculationField = obj.Calculation_Field__c; 
      String controllingField = obj.Controlling_Field__c;
      String controllingField2 = obj.Controlling_Field_2__c;
      Decimal score = obj.Score__c;
      
      if(relatedObject != null){
        if(controllingField == null && controllingField2 == null){
          if(relatedObject.get(calculationField) != null){
            resultScore = resultScore + score;
          }
        }
        else if(controllingField != null && controllingField2 == null){
          if(relatedObject.get(calculationField) != null && relatedObject.get(controllingField) != null){
            resultScore = resultScore + score;
          }
        }
        else if(controllingField != null && controllingField2 != null){
          if(relatedObject.get(calculationField) != null && relatedObject.get(controllingField) != null && relatedObject.get(controllingField2) != null){
          	resultScore = resultScore + score;
          }
        }
      }
    }
    return resultScore;
  }

  /* Helper Method to get all the fields of object */
  private static String getObjectFields(String objectName) {
    if(objectName == 'Opportunity_Plan_Contact__c'){
      return String.join(new List<String>(Schema.SObjectType.Opportunity_Plan_Contact__c.fields.getMap().keySet()), ',');
    }
    else if(objectName == 'Opportunity_Plan_Competitor__c'){
      return String.join(new List<String>(Schema.SObjectType.Opportunity_Plan_Competitor__c.fields.getMap().keySet()), ',');
    }
    else if(objectName == 'Task'){
      return String.join(new List<String>(Schema.SObjectType.Task.fields.getMap().keySet()), ',');
    }
    else if(objectName == 'Contact'){
      return 'Contact_Role__c,Title';//String.join(new List<String>(Schema.SObjectType.Contact.fields.getMap().keySet()), ',');
    } 
    else if(objectName == 'Opportunity_Plan_Joint_Action__c'){
      return String.join(new List<String>(Schema.SObjectType.Opportunity_Plan_Joint_Action__c.fields.getMap().keySet()), ',');
    } 
    else {
      return String.join(new List<String>(Schema.SObjectType.Opportunity_Plan__c.fields.getMap().keySet()), ',');
    }
  }

  /* Helper method to Build Query */
  private static Map<String, List<SObject>> getSObjectRecords(String objectName, Set<Id> filterIds, Boolean matchRecordId){
    String keyName;
    String strQry = 'SELECT ' + getObjectFields(objectName) + ' FROM ' + objectName + ' WHERE ';
    Map<String, List<SObject>> recordsMap = new Map<String, List<SObject>>();
    if(!matchRecordId && objectName.equals('Opportunity_Plan_Contact__c')){
      strQry = strQry + ' (Opportunity_Plan__c =: filterIds Or Id = :filterIds) ORDER BY Opportunity_Plan__c, CreatedDate ASC';
      keyName = 'Opportunity_Plan__c';
      // We are considering only Oldest Opportunity Plan Contact.
    }
    else if(!matchRecordId && objectName.equals('Opportunity_Plan_Joint_Action__c')){
      strQry = strQry + 'Opportunity_Plan__c =: filterIds ORDER BY Opportunity_Plan__c, CreatedDate ASC';
      keyName = 'Opportunity_Plan__c';
      // We are considering only Oldest Opportunity Plan Contact. 
    }
    else if(!matchRecordId && objectName.equals('Opportunity_Plan_Competitor__c')){
      strQry = strQry + 'Opportunity_Plan__c =: filterIds ORDER BY Opportunity_Plan__c, CreatedDate ASC';
      keyName = 'Opportunity_Plan__c';
      // We are considering only Oldest Opportunity Plan Competitor.
    }
    else if(!matchRecordId && objectName.equals('Task')){
      strQry = strQry + 'WhatId =: filterIds ORDER BY WhatId, CreatedDate ASC';
      keyName = 'WhatId';
      // We are considering only Oldest Opportunity Plan Competitor.
    } else if(!matchRecordId && objectName.equals('Contact')) {
      strQry = 'SELECT ' + getObjectFields('Opportunity_Plan_Contact__c') + ' FROM Opportunity_Plan_Contact__c WHERE ';
      strQry = strQry + 'Opportunity_Plan__c =: filterIds ORDER BY Opportunity_Plan__c, CreatedDate ASC';
      List<SObject> lst = Database.query(strQry);
      
      Set<String> contactIds = new Set<String>(); 
      for(SObject obj : lst) {
        if(obj.get('Contact__c') != null) {
          contactIds.add(String.valueOf(obj.get('Contact__c')));
        }
      }

      strQry = 'SELECT ' + getObjectFields(objectName) + ' FROM Contact WHERE Id =: contactIds';
      keyName = 'Id';
    }
    else{
      strQry = strQry + 'Id =: filterIds';
      keyName = 'Id';
    }
    List<SObject> lst = Database.query(strQry);
    if(lst.size() > 0){
      recordsMap = new Map<String, List<SObject>>();
      for(SObject obj : lst) {
        if(!recordsMap.containsKey(String.valueOf(obj.get(keyName)))) {
          recordsMap.put(String.valueOf(obj.get(keyName)), new List<SObject>());
          recordsMap.get(String.valueOf(obj.get(keyName))).add(obj);
        } else {
          if(objectName == 'Task' && recordsMap.get(String.valueOf(obj.get(keyName))).size() <= 4) {
            recordsMap.get(String.valueOf(obj.get(keyName))).add(obj);
          }
           if(objectName == 'Opportunity_Plan_Joint_Action__c' && recordsMap.get(String.valueOf(obj.get(keyName))).size() <= 8) {
            recordsMap.get(String.valueOf(obj.get(keyName))).add(obj);
          }
        }
      }
    }
    return recordsMap;
  }

  /*Finalize the score*/
  private static decimal finalizeScore(decimal score, List<OpportunityTeamMember> opptyTeamLst, Opp_Plan_Score_Calc__c obj) {
    Decimal percent = 0;
    Decimal maxScore = obj.Expected_Score__c;

    if(opptyTeamLst != null) {
      score += opptyTeamLst.size() >= 2 ? 4 : 0;
    }
    
    if(score > maxScore){
      score = maxScore;
    }
    
    if(score > 0 && maxScore > 0){
      percent = (score / maxScore) * 100;
    }

    return percent;
  }

  /* Helper method to Get Score Calculation Master Object */
  private static Map<String, Opp_Plan_Score_Calc__c> mapScoreCalcMaster{
    get{
      if(mapScoreCalcMaster == null){
      	mapScoreCalcMaster = new Map<String, Opp_Plan_Score_Calc__c>();
	    for(Opp_Plan_Score_Calc__c obj :[SELECT Id, Name, Expected_Score__c FROM Opp_Plan_Score_Calc__c]){
	      mapScoreCalcMaster.put(obj.Name, obj);
	    }
      }      
      return mapScoreCalcMaster;
    }
    private set;
  }
  
  //============================================================================
  // I-120989: Method to synch currencies with Opportunity
  //============================================================================
  private static void synchCurrencyISOCodes(List<Opportunity_Plan__c> newList, 
                                            Map<ID, Opportunity_Plan__c> oldMap){
    Set<String> oppIDs = new Set<String>();
    List<Opportunity_Plan__c> lstOppPln = new List<Opportunity_Plan__c>();
    Map<String, Opportunity> mapOppId_Opp = new Map<String, Opportunity>();
    
    //Find acc plan Ids related to Acc Plan Oppty
    for(Opportunity_Plan__c opp : newList){
        if(oldMap == null || (oldMap.get(opp.Id).Opportunity_Name__c   != opp.Opportunity_Name__c  )){
            lstOppPln.add(opp);
            oppIDs.add(opp.Opportunity_Name__c );
        }
    }
    
    if(!oppIDs.isEmpty()){
        for(Opportunity opp : [SELECT Id, CurrencyIsoCode, 
                                    (SELECT Id, CurrencyIsoCode From Opportunity_Plans__r)
                                     From Opportunity 
                                     WHERE ID IN: oppIDs]){
            mapOppId_Opp.put(opp.Id, opp);
        }
        // Update Currency Iso code for Account Plan Opportunity
        for(Opportunity_Plan__c oppPln : lstOppPln){
            oppPln.CurrencyISOCode = mapOppId_Opp.get(oppPln.Opportunity_Name__c).CurrencyISOCode;
        }
    }                                           
    
  }

 }