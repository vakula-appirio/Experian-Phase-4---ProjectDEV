/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityExitCriteriaStatusExtension
 * Description: Extension for VF page added to Opportunity Layout. This update ContactRole checkbox.
 * Created Date: Dec 12th, 2013
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * Jan 30th, 2014     Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 22th, 2014     Naresh kr Ojha (Appirio)     T-251145: updated to remove ref Has_Completed_Task__c 
 * Feb 26th, 2014     Nathalie Le Guay (Appirio)   Removing references to Selection_confirmed__c and Signed_Contract__c
 *                                                 and Task_Quote_Delivered__c
 * Feb 27th, 2014     Nathalie Le Guay             Clean up code - remove queries to OpportunityContactRole and Tasks
 *                                                 created populateStagesMissingCriteriaMap()
 * March 3rd, 2014    Nathalie Le Guay             Updated opp query
 * Apr 15th, 2014     Arpita Bose (Appirio)        T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 16th, 2014     Arpita Bose                  T-271695: Renamed fields Has_Stage_4_Approval__c to Has_Stage_3_Approval__c 
 *                                                  and Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Apr 16th, 2014     Nathalie Le Guay             T-272404: Adding Approval Process fields to Opportunity query
 * Jul 28th, 2014     Nathalie Le Guay             S-252919 - Added Outcomes__c to the Opp query (constructor)
 * Nov 13th, 2014     Noopur                       Added the conditions to check of the current user is EDQ and UK&I to bypass some of the criteria.
 =====================================================================*/
 
public class OpportunityExitCriteriaStatusExtension {
    public Opportunity oppty; 
    public Boolean hasContactRole                       {get;set;}
    public Boolean hasCompletedTask                     {get;set;}
    public Boolean missingAnyPreviousCriteria           {get;set;}
    public Boolean bypassTheCriteria                    {get;set;}
    // This map will be used by the page to determine if specific Exit Criteria
    // need to be displayed as being missed from a previous stage
    public Map<String, Boolean> stagesCriteriaMissing {
      get{
        if (stagesCriteriaMissing == null) {
        stagesCriteriaMissing = new Map<String, Boolean>{'3'=>false,
                                                         '4'=>false, 
                                                         '5'=>false, 
                                                         '6'=>false, 
                                                         '7'=>false};
        return stagesCriteriaMissing;
        }
        return stagesCriteriaMissing;
      }
      set;
    }



  public OpportunityExitCriteriaStatusExtension( ApexPages.StandardController stdController ) {
    oppty = (Opportunity)stdController.getRecord();  
    //DW 2013-12-13 putting the contact role check here and removing all asynchronous processing etc.
    oppty = [SELECT Id, Turn_Off_Contact_Role_Criteria_Check__c, StageName, Starting_Stage__c, Has_Stage_3_Approval__c, Stage_3_Approver__c,
                    //Below_Review_Thresholds__c, T-271695: Removed reference to Below_Review_Thresholds__c
                    CurrencyIsoCode, CloseDate,
                    Opportunity_Products_Count__c, 
                    Has_Senior_Approval__c, Senior_Approver__c,
                    Owner.Region__c,OwnerId,
                    Is_There_Commercial_Risk__c, Is_There_Delivery_Risk__c,
                    Is_There_Financial_Risk__c, Is_There_Legal_Risk__c,
                    Has_There_Been_Significant_Change__c,
                    Competitor_Count__c, Amount, Budget__c,
                    (SELECT Id, Role, IsPrimary FROM OpportunityContactRoles WHERE Role =: Constants.DECIDER),
                    (SELECT Id, Type, Status, Outcomes__c FROM Tasks
                     WHERE Status =: Constants.STATUS_COMPLETED)
             FROM Opportunity
             WHERE Id = :oppty.Id];

    if (!Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.containsKey(oppty.StageName)) {
      return;
    }

    hasContactRole = true;

    //If we don't want to check for contact role (originally loaded opp)
    if(!oppty.Turn_Off_Contact_Role_Criteria_Check__c){
      hasContactRole = oppty.OpportunityContactRoles.size() > 0;
    }
    if (oppty.Tasks != null) {
      hasCompletedTask = oppty.Tasks.size() > 0;
    } else {
      hasCompletedTask = false;
    }

    // In this section, populating the stagesCriteriaMissing map
    if (Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.get(oppty.StageName) == 3) {
      stagesCriteriaMissing.put(String.valueOf(3), true);
      System.debug('\n[OpportunityExitCriteriaStatusExtension: constructor]: Is on stage 3');
      return;
    }
    Integer startingStageNumber = 4;
    Integer stageNumber = Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.get(oppty.StageName);
    Integer lastStage = stageNumber + 1;

    if (String.isNotEmpty(oppty.Starting_Stage__c)) {
      system.debug('\nStart stage: '+oppty.Starting_Stage__c);
      system.debug('\nMap: '+ Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap);
      system.debug('\nMap value: '+Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.get(oppty.Starting_Stage__c));
      startingStageNumber = Opportunity_ExitCriteriaUtility.oppStageNameToNumberMap.get(oppty.Starting_Stage__c) + 1;
      System.debug('\nstartingStageNumber: '+startingStageNumber);
    }

    System.debug('\n[OpportunityExitCriteriaStatusExtension: constructor]: starting logic from stage: '+ startingStageNumber);
    System.debug('\n[OpportunityExitCriteriaStatusExtension: constructor]: last stage will be: '+ lastStage);

    populateStagesMissingCriteriaMap(startingStageNumber, lastStage);
    System.debug('\n[OpportunityExitCriteriaStatusExtension: constructor]: Map: '+ stagesCriteriaMissing);
    
    bypassTheCriteria = false;
    String groupName = BusinessUnitUtility.getBusinessUnit(oppty.OwnerId) ;
    if (String.isNotBlank(groupName) && groupName.equalsIgnoreCase(Constants.EDQ) && 
      oppty.Owner.Region__c == Constants.REGION_UKI) {
      bypassTheCriteria = true;
    }
    system.debug('===bypassTheCriteria==='+bypassTheCriteria);
  }

  //=============================================================
  // This method will populate the stagesCriteriaMissing Map that 
  // will help the VF page render the appropriate data
  //=============================================================
  private void populateStagesMissingCriteriaMap(Integer startStage, Integer stopStage) {
    Integer tempStage = startStage;
    Boolean meetingCriteria = true;
    missingAnyPreviousCriteria = false;

    while (tempStage <= stopStage) {
      // We want to see the next exit criteria for the current stage regardless of whether they are met or not
      if (tempStage == stopStage) {
        System.debug('\n[OpportunityExitCriteriaStatusExtension: constructor]: Reaching last stage: '+ tempStage);
        stagesCriteriaMissing.put(String.valueOf(tempStage), true);
        tempStage++;
        continue;
      }

      meetingCriteria = Opportunity_ExitCriteriaUtility.isMeetingExitCriteria(oppty,
                                                                              Opportunity_ExitCriteriaUtility.oppStageNumberToNameMap.get(tempStage),
                                                                              Opportunity_ExitCriteriaUtility.oppStageNumberToNameMap.get(tempStage-1));
      System.debug('\n[OpportunityExitCriteriaStatusExtension: constructor]: Met Exit Criteria for Stage '+ tempStage + '? ' + meetingCriteria);
      if (!meetingCriteria) {
        stagesCriteriaMissing.put(String.valueOf(tempStage-1), true);
        missingAnyPreviousCriteria = true;
      }
      tempStage++;
    }
  }

  //=============================================================
  // Booleans used by the VF page for one of the Exit Criteria
  //=============================================================
  public Boolean hasSignedContract {
    get {
      if (hasSignedContract == null) {
        hasSignedContract = Opportunity_ExitCriteriaUtility.hasRequiredTask(oppty, Constants.ACTIVITY_TYPE_SIGNED_CONTRACT);
      }
      return hasSignedContract;
    }
    set;
  }

   public Boolean hasSelectionConfirmed {
     get {
       if (hasSelectionConfirmed == null) {
         hasSelectionConfirmed = Opportunity_ExitCriteriaUtility.hasRequiredTask(oppty, Constants.ACTIVITY_TYPE_SELECTION_CONFIRMED);
       }
       return hasSelectionConfirmed;
     }
     set;
   }
 
   public Boolean hasQuoteDelivered {
     get {
       if (hasQuoteDelivered == null) {
         hasQuoteDelivered = Opportunity_ExitCriteriaUtility.hasRequiredTask(oppty, Constants.ACTIVITY_TYPE_QUOTE_DELIVERED);
       }
       return hasQuoteDelivered;
     }
     set;
   }
  
}