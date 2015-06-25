/**=====================================================================
 * Appirio, Inc
 * Name: ESDEL_TimecardTriggerHandler
 * Description: Handler class for ESDEL_TimecardTrigger.trigger (for T-270393 and T-270392)
 * Created Date: April 18th, 2014
 * Created By: Rahul Jain (Appirio) 
 * 
 * Date Modified                Modified By                  Description of the update
 * May 01st, 2014               Arpita Bose(Appirio)         Updated catch(Exception) to catch(DMLException) to use getDMLException
  =====================================================================*/
public without sharing class ESDEL_TimecardTriggerHandler {
	public static string SOBJECT_FIELD_ESDEL_CASE = 'ESDEL_Case__c';
	public static string SOBJECT_FIELD_ESDEL_PROJECT = 'ESDEL_Project__c';
	//=========================================================================
  //After Insert Call
  //=========================================================================
  public static void afterInsert(List<ESDEL_Timecard__c> newTimecards){
    Set<Id> caseIds = new Set<Id>();
    // populate the set of caseIds related to inserted timecards
    for(ESDEL_Timecard__c newTimecard : newTimecards){
    	if(newTimecard.ESDEL_Case__c <> null){
    	  caseIds.add(newTimecard.ESDEL_Case__c);
    	}
    }
    if(!caseIds.isEmpty()){    
      if(updateRelatedCasesWithSumMinutesWorked(caseIds, newTimecards)){
        updateRelatedProjectsWithSumMinutesWorked(caseIds);
      }
    }      	  
  }
  
  //=========================================================================
  //After Update Call
  //=========================================================================
  public static void afterUpdate(List<ESDEL_Timecard__c> newTimecards, Map<Id, ESDEL_Timecard__c> oldIdsToTimecardsMap){
  	Set<Id> caseIds = new Set<Id>();
  	// populate the set of caseIds related to inserted timecards where minutes worked is changed or case relation ship is changed.
    for(ESDEL_Timecard__c newTimecard : newTimecards){
    	// check whether timecard minutes worked value is changed on update
      if(newTimecard.ESDEL_Case__c <> null && newTimecard.ESDEL_Minutes_Worked__c <> oldIdsToTimecardsMap.get(newTimecard.id).ESDEL_Minutes_Worked__c){
        caseIds.add(newTimecard.ESDEL_Case__c);
      }
      // check whether timecard related case lookup value is changed on update
      if(newTimecard.ESDEL_Case__c <> oldIdsToTimecardsMap.get(newTimecard.id).ESDEL_Case__c){
      	// add case id if new timecard associated case is not null
      	if(newTimecard.ESDEL_Case__c <> null){
      		caseIds.add(newTimecard.ESDEL_Case__c);
      	}	
      	// add case id if old timecard associated case is not null
      	if(oldIdsToTimecardsMap.get(newTimecard.id).ESDEL_Case__c <> null){
      	  caseIds.add(oldIdsToTimecardsMap.get(newTimecard.id).ESDEL_Case__c);
      	}
      }      
    }
    if(!caseIds.isEmpty()){
      if(updateRelatedCasesWithSumMinutesWorked(caseIds, newTimecards)){
        updateRelatedProjectsWithSumMinutesWorked(caseIds);
      }
    }  
  }
  
  //=========================================================================
  //After Delete Call
  //=========================================================================
  public static void afterDelete(List<ESDEL_Timecard__c> oldTimecards){
  	Set<Id> caseIds = new Set<Id>();
  	// populate the set of caseIds related to deleted timecards
    for(ESDEL_Timecard__c oldTimecard : oldTimecards){    
    	if(oldTimecard.ESDEL_Case__c <> null){  
        caseIds.add(oldTimecard.ESDEL_Case__c);
      }
    }
    if(!caseIds.isEmpty()){
      if(updateRelatedCasesWithSumMinutesWorked(caseIds, oldTimecards)){
        updateRelatedProjectsWithSumMinutesWorked(caseIds);
      }
    }
  }
  
    
  //=========================================================================
  //Generic method to update the related cases with sum of minutes worked
  //=========================================================================
  public static boolean updateRelatedCasesWithSumMinutesWorked(Set<Id> caseIds, List<ESDEL_Timecard__c> listTimeCards){
  	 List<Case> tobeUpdatedCases = new List<Case>();
  	 Map<Id, Case> caseIdsToCaseMap = new Map<Id, Case>();
  	 boolean isUpdateSuccessful = true;  	
  	 try{
	  	 // get the sum of minutes worked on all the timecards assocated to cases
	  	 List<AggregateResult> timecardAggregateResults = [Select SUM(ESDEL_Minutes_Worked__c) sum_min_worked, 
	  	                                                   ESDEL_Case__c 
	  	                                                   FROM ESDEL_Timecard__c  
	  	                                                   WHERE ESDEL_Case__c IN : caseIds
	  	                                                   GROUP BY ESDEL_Case__c];
	  	 // populate the caseIdsToCaseMap with all the existing timecards                                                  
	  	 for(AggregateResult timecardAggregateResult: timecardAggregateResults){
	  	 	 caseIdsToCaseMap.put((Id)timecardAggregateResult.get(SOBJECT_FIELD_ESDEL_CASE),
	  	 	                        new Case(Id = (Id)timecardAggregateResult.get(SOBJECT_FIELD_ESDEL_CASE), 
	                                   ESDEL_Minutes_Worked__c = Integer.valueOf(timecardAggregateResult.get('sum_min_worked'))
	                            ));
	  	 	
	  	 	                            	 	
	  	 }
	  	 
	  	 for(Id caseId : caseIds){
	  	 	 // initiate caseUpdated with mins worked as 0; this is required in the case of delete dml operation
	  	 	 // where no record will be found when only timecard on case is deleted.
	  	   Case caseUpdated = new Case(Id = caseId, ESDEL_Minutes_Worked__c = 0);  
	       if(caseIdsToCaseMap.containsKey(caseId)){
	         caseUpdated = caseIdsToCaseMap.get(caseId);
	       }
	       tobeUpdatedCases.add(caseUpdated);
	  	 }
	  	 
	  	 if(!tobeUpdatedCases.isEmpty()){
	        update tobeUpdatedCases;
	     }
  	 }catch(DMLException ex){
  	 	 isUpdateSuccessful = false;
  	 	 apexLogHandler.createLogAndSave('ESDEL_TimecardTriggerHandler','updateRelatedCasesWithSumMinutesWorked', ex.getStackTraceString(), ex);
  	 	 for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          listTimeCards.get(0).addError(ex.getDMLMessage(indx));
       }
  	 } 
  	 return isUpdateSuccessful;   	 
  }
  
  //==================================================================================
  //Generic method to update related projects with sum minutes worked on related cases
  //==================================================================================
  public static void updateRelatedProjectsWithSumMinutesWorked(Set<Id> caseIds){
    List<ESDEL_Delivery_Project__c> tobeUpdatedProjects = new List<ESDEL_Delivery_Project__c>();  
    Set<Id> projectIds = new Set<Id>();    
    try{
	    // get all updated case record to retreive the associated project ids
	    for(Case caseRecord : [Select ESDEL_Project__c 
	                           From Case 
	                           WHERE id in :caseIds]){
	      if(caseRecord.ESDEL_Project__c <> null){
	        projectIds.add(caseRecord.ESDEL_Project__c);    
	      }   
	    }
	    if(!projectIDs.isEmpty()){ 
		    // get the sum of minutes worked on all the cases assocated to projects
		    List<AggregateResult> caseAggregateResults = [Select SUM(ESDEL_Minutes_Worked__c) sum_min_worked, 
		                                                  ESDEL_Project__c 
			                                                FROM Case  
			                                                WHERE ESDEL_Project__c IN : projectIDs
			                                                GROUP BY ESDEL_Project__c];
			  // populate the list of projects to be updated with sum of minutes worked                                              	                                                       
			  for(AggregateResult caseAggregateResult: caseAggregateResults){
			    tobeUpdatedProjects.add(new ESDEL_Delivery_Project__c(Id = (Id)caseAggregateResult.get(SOBJECT_FIELD_ESDEL_PROJECT), 
			                                                         ESDEL_Minutes_Worked__c = Integer.valueOf(caseAggregateResult.get('sum_min_worked'))
			                              ));
			      
			                                      
			  }
	    }    
	    if(!tobeUpdatedProjects.isEmpty()){
	        update tobeUpdatedProjects;
	    }
    }catch(DMLException ex){    	 
       apexLogHandler.createLogAndSave('ESDEL_TimecardTriggerHandler','updateRelatedProjectsWithSumMinutesWorked', ex.getStackTraceString(), ex);
       for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          tobeUpdatedProjects.get(0).addError(ex.getDMLMessage(indx));
       }
    }    
  }
  
}