/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTrigger_DatesUtility
 * Description: T-264797: Refactoring of OpportunityTriggerHandler and Helper classes.
 *              The following methods were moved from OpportunityTriggerHandler:
 *                - populateStartingStage
 *                - validateServiceDates
 *                - populateServiceDatesOnOLI
 *              FOR HISTORY, REFER TO OpportunityTriggerHandler
 * Created Date: Mar 26th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Apr 01st, 2014               Arpita Bose(Appirio)         T-268401: Removed reference to Opp's Service Start/End dates
 * Apr 02nd, 2014               Arpita Bose(Appirio)         T-268405: Renamed OLI's Service Start/end dates to Start/End dates
 * Apr 04th, 2014               Mohit Parnami(Appirio)       T-268404: Updated validateServiceDates Method to not to display the error msg on the opportunity if
 *                                                           Contract_Start_Date__c <= earliestOLIdate and Contract_End_Date__c >= latestOLIdate
 * Apr 10th, 2014               Nathalie Le Guay (Appirio)   T-270370: Adding logic to populate opp.Number_of_Times_Stage_Moved_Backwards__c
 * May 01, 2014                 Nathalie Le Guay             Switching error messages around in validateServiceDates()
 =====================================================================*/
public without sharing class OpportunityTrigger_DatesUtility {
  private static Map<Id, OpportunityLineItem> opportunityLineItems;
  private static Boolean hasCheckedBackwardStages = false;
  //============================================================================================
  // Populates starting stage on Opportunity
  // If going backwards with the stage (ex: from stage 5 to stage 4), we will set the Starting_Stage__c
  // to the 'new low' stage, as we want the new low stage's criteria to be met
  //============================================================================================  
  public static void populateStartingStage(List<Opportunity> opps, Map<Id, Opportunity> oldOpps) {
     if (oldOpps == null) {
       for (Opportunity opp: opps) {
         if (String.isBlank(opp.Starting_Stage__c)) {
           opp.Starting_Stage__c = Constants.OPPTY_STAGE_3;
         }
       }
     }
     else {
       Integer newStage;
       Integer oldStage;
       Integer startingStage = 7;
       for (Opportunity opp: opps) {
         System.debug('\n[OpportunityTriggerHandler: populateStartingStage] : Starting Stage:' + opp.Starting_Stage__c);
         if (opp.StageName == oldOpps.get(opp.Id).StageName) {
           continue;
         }
         newStage = Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.get(opp.StageName);
         oldStage = Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.get(oldOpps.get(opp.Id).StageName);
         if (String.isNotEmpty(opp.Starting_Stage__c)) {
           startingStage = Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.get(opp.Starting_Stage__c);
         }
         System.debug('\n[OpportunityTriggerHandler: populateStartingStage] : Starting Stage:' + startingStage);
         if (newStage < startingStage && newStage < oldStage) {
           opp.Starting_Stage__c = Opportunity_ExitCriteriaUtility.oppStageNumberToNameMap.get(newStage);
         }
         System.debug('\n[OpportunityTriggerHandler: populateStartingStage] : opp.Number_of_Times_Stage_Moved_Backwards__c:' + opp.Number_of_Times_Stage_Moved_Backwards__c);
         System.debug('\n[OpportunityTriggerHandler: populateStartingStage] : oldStage:' + oldStage + ' new stage: ' + newStage);
         if (newStage < oldStage && !hasCheckedBackwardStages) {
           if (oldOpps != null) {
             opp.Number_of_Times_Stage_Moved_Backwards__c = (opp.Number_of_Times_Stage_Moved_Backwards__c == null) ?
                                                          1 : opp.Number_of_Times_Stage_Moved_Backwards__c + 1;
             System.debug('\nChanging opp.Number_of_Times_Stage_Moved_Backwards__c~~~~~~~~~~' + opp.Number_of_Times_Stage_Moved_Backwards__c);
           }
           hasCheckedBackwardStages = true;
         }
         System.debug('\n[OpportunityTriggerHandler: populateStartingStage] : Opps Starting Stage:' + opp.Starting_Stage__c);
       }
     }
   }

  //============================================================================================
  // T-253868 - validate Opportunity Service Dates
  // If any of the Opportunity's Line Item already has a Start_Date__c or
  // End_Date__c, we will prevent the Opp's respective date from being updated
  //============================================================================================
  public static void validateServiceDates(Map<Id, Opportunity> newOpportunityMap, Map<Id, Opportunity> oldOpportunityMap) {
    Set<Id> startDateChangedOppIds = new Set<Id>();
    Set<Id> endDateChangedOppIds = new Set<Id>();
    opportunityLineItems = new Map<Id,OpportunityLineItem>();
  Map<Id, Opportunity> mapIdToOppMap = new Map<Id, Opportunity>();
  
    for (Opportunity opp : newOpportunityMap.values()) {
      if (!OpportunityTriggerHandler.updateFromOppLI && opp.Contract_Start_Date__c != null && 
            opp.Contract_Start_Date__c != oldOpportunityMap.get(opp.Id).Contract_Start_Date__c) {
        startDateChangedOppIds.add(opp.Id);
        mapIdToOppMap.put(opp.Id, opp);
      }
      
      if (!OpportunityTriggerHandler.updateFromOppLI && opp.Contract_End_Date__c != null && 
                                                    opp.Contract_End_Date__c != oldOpportunityMap.get(opp.Id).Contract_End_Date__c) {
        endDateChangedOppIds.add(opp.Id);
        mapIdToOppMap.put(opp.Id, opp);
      }
    }
    
    Map<Id, List<OpportunityLineItem>> mapOppToListOLI = new Map<Id, List<OpportunityLineItem>>();
    if (!startDateChangedOppIds.isEmpty() || !endDateChangedOppIds.isEmpty()) {
        for (OpportunityLineItem oli : [SELECT Id, OpportunityId, Start_Date__c, End_Date__c, Quantity
                                       FROM  OpportunityLineItem
                                       WHERE (OpportunityId in : startDateChangedOppIds OR OpportunityId in : endDateChangedOppIds)
                                       order by OpportunityId, Start_Date__c NULLS LAST, End_Date__c NULLS LAST]){
           
           /* 
             if (newOpportunityMap.get(oli.OpportunityId).Contract_Start_Date__c != null &&
                         oli.Start_Date__c != null &&
                          startDateChangedOppIds.contains(oli.OpportunityId)) {
                newOpportunityMap.get(oli.OpportunityId).addError(System.Label.Service_Start_Date_Error_Msg);
                continue;
              }
              // check Service End Date
              if (newOpportunityMap.get(oli.OpportunityId).Contract_End_Date__c != null && 
                                 
                                 oli.End_Date__c != null && 
                                 endDateChangedOppIds.contains(oli.OpportunityId)) {
                newOpportunityMap.get(oli.OpportunityId).addError(System.Label.Service_End_Date_Error_Msg);
                continue;
              }
              opportunityLineItems.put(oli.id, oli);
           
           */
           if(!mapOppToListOLI.containsKey(oli.OpportunityId)){
             mapOppToListOLI.put(oli.OpportunityId, new List<OpportunityLineItem>());
           }
      mapOppToListOLI.get(oli.OpportunityId).add(oli);
        }
        
        system.debug('==[OpportunityTrigger_DatesUtility] : [validateServiceDates]=====mapOppToListOLI=======' + mapOppToListOLI);
        if(mapOppToListOLI != null){
          for(Id oppId : mapOppToListOLI.keySet()){
            Date earliestOLIdate = mapOppToListOLI.get(oppId).get(0).Start_Date__c;
        Date latestOLIdate = mapOppToListOLI.get(oppId).get(0).Start_Date__c;
            for(OpportunityLineItem oppLineItem : mapOppToListOLI.get(oppId)){
              if(oppLineItem.Start_Date__c < earliestOLIdate){
                earliestOLIdate = oppLineItem.Start_Date__c;
              }
              if(oppLineItem.End_Date__c > latestOLIdate){
                latestOLIdate = oppLineItem.End_Date__c;
              }
            }
            
            system.debug('==[OpportunityTrigger_DatesUtility] : [validateServiceDates]===' + oppId + '==earliestOLIdate=======' + earliestOLIdate);
            system.debug('==[OpportunityTrigger_DatesUtility] : [validateServiceDates]===' + oppId + '==latestOLIdate=======' + latestOLIdate);
            
            for(OpportunityLineItem opportunityLineItem : mapOppToListOLI.get(oppId)){
              String errorMessage = '';
              Boolean isStartDateError = false;
              Boolean isEndDateError = false;
              // check Service Start Date
              if (mapIdToOppMap.get(oppId).Contract_Start_Date__c != null && startDateChangedOppIds.contains(oppId) && 
                opportunityLineItem.Start_Date__c != null && !(mapIdToOppMap.get(oppId).Contract_Start_Date__c <= earliestOLIdate)){
                  
                system.debug('==[OpportunityTrigger_DatesUtility] : [validateServiceDates]===mapIdToOppMap.get(oppId).Contract_Start_Date__c==' + mapIdToOppMap.get(oppId).Contract_Start_Date__c + '==earliestOLIdate==' + earliestOLIdate);
                isStartDateError = true;
                //mapIdToOppMap.get(oppId).addError(System.Label.Service_Start_Date_Error_Msg);
                system.debug('==[OpportunityTrigger_DatesUtility] : [validateServiceDates]=== Error Added to Start Date');
              }
              // check Service End Date
              if (mapIdToOppMap.get(oppId).Contract_End_Date__c != null && endDateChangedOppIds.contains(oppId) && 
                    opportunityLineItem.End_Date__c != null && !(mapIdToOppMap.get(oppId).Contract_End_Date__c >= latestOLIdate)) {
                    isEndDateError = true;
                    system.debug('==[OpportunityTrigger_DatesUtility] : [validateServiceDates]===mapIdToOppMap.get(oppId).Contract_End_Date__c==' + mapIdToOppMap.get(oppId).Contract_End_Date__c + '==latestOLIdate==' + latestOLIdate);
                    //mapIdToOppMap.get(oppId).addError(System.Label.Service_End_Date_Error_Msg);
                    system.debug('==[OpportunityTrigger_DatesUtility] : [validateServiceDates]=== Error Added to End Date');
              }
              if (isStartDateError || isEndDateError) {
                if (isStartDateError && isEndDateError) {
                  errorMessage = Label.Service_Start_and_End_Date_Error_Msg;
                } else if (isStartDateError) {
                  errorMessage = Label.Service_Start_Date_Error_Msg;
                } else if (isEndDateError) {
                  errorMessage = Label.Service_End_Date_Error_Msg;
                }
                mapIdToOppMap.get(oppId).addError(errorMessage);
              }
                opportunityLineItems.put(opportunityLineItem.id, opportunityLineItem);
            }
          }
          system.debug('==[OpportunityTrigger_DatesUtility] : [validateServiceDates]===' + opportunityLineItems);
        }
    }
  }
  
  //============================================================================================
  // T-253868 - Populate Service Date on Line Items
  // If no error was thrown by now, the Opportunity Line Items Start_Date__c and
  // End_Date__c will be populated with the Opp's dates
  //============================================================================================
  public static void populateServiceDatesOnOLI(Map<Id, Opportunity> newOpportunityMap, Map<Id, Opportunity> oldOpportunityMap) {
      if (opportunityLineItems != null && !opportunityLineItems.isEmpty()) {
        for (OpportunityLineItem oli : opportunityLineItems.values()) {
          // populate Service Start Date
          if (!OpportunityTriggerHandler.updateFromOppLI && newOpportunityMap.containsKey(oli.OpportunityId)
                               && newOpportunityMap.get(oli.OpportunityId).Contract_Start_Date__c
                               != oldOpportunityMap.get(oli.OpportunityId).Contract_Start_Date__c) {
            oli.Start_Date__c = newOpportunityMap.get(oli.OpportunityId).Contract_Start_Date__c;
          }
          // populate Service End Date
          if (!OpportunityTriggerHandler.updateFromOppLI && newOpportunityMap.containsKey(oli.OpportunityId)
                               && newOpportunityMap.get(oli.OpportunityId).Contract_End_Date__c
                               != oldOpportunityMap.get(oli.OpportunityId).Contract_End_Date__c) {
            oli.End_Date__c = newOpportunityMap.get(oli.OpportunityId).Contract_End_Date__c;
          }
        }
      }
    }
}