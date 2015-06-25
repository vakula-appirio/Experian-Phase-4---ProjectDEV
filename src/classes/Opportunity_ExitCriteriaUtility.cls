/**===========================================================================================================
 * Appirio, Inc
 * Name: Opportunity_ExitCriteriaUtility.cls
 * Description: T:235320: Exit criteria for Opportunities
 * Created Date: 02/07/2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * Feb 19th, 2014     Nathalie Le Guay (Appirio)   Created oppStagesAllowedMap & updated all
 *                                                 criteria check methods to simplify logic &
 *                                                 use CurrencyUtility class
 * Feb 22th, 2014     Naresh kr Ojha (Appirio)     T-251145: updated to remove ref Has_Completed_Task__c 
 * Feb 25th, 2014     Nathalie Le Guay (Appirio)  Renamed checkPreviousStageNotMet() to isPassingRequiredExitCriteria()
 *                                                 Rewrote isPassingRequiredExitCriteria() + added oppStageNameToNumberMap
 *                                                 and oppStageNumberToNameMap
 *                                                 Removed duplicate calls to check exit criteria
 *                                                 Created isStage6ExitCriteriaMet()
 * Feb 26th, 2014     Nathalie Le Guay (Appirio)   Removing references to Selection_confirmed__c and Signed_Contract__c
 *                                                 and Task_Quote_Delivered__c
 * Feb 27th, 2014     Naresh Kr Ojha (Appirio)     Updated hasRequiredTask() method to use queried opportunities, as it can have Tasks on oppty 
 *                                                 after querying them.
 * Feb 28th, 2014     Naresh kr Ojha (Appirio)     Fixed issue: I-103440
 * March 3rd, 2014    Nathalie Le Guay             Updated opp query
 * Mar 04th, 2014     Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Mar 27th, 2014     Nathalie Le Guay             Adding debug statements
 * Mar 31st, 2014     Arpita Bose(Appirio)         T-267875: Removed reference to field Total_Annual_Amount__c and the validations for  
 *                                                 Stage_4_to_5_Opportunity_Approval, Stage_4_to_5_AmountOrTAA_Over_Approval
 *                                                 and Stage_5_to_6_Opportunity_Approval
 * April 3rd, 2014    Mohit Parnami(Appirio)       T-266502: updated isMeetingExitCriteria method to use the constructor of currencyUtility 
                                                   having parameter as set of ISO codes 
 * Apr 15th, 2014     Arpita Bose                  T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 15th, 2014     Nathalie Le Guay             T-265496: Removed Stage_4_Exit_Criteria_Met  and Stage_5_Exit_Criteria_Met logic
 * Apr 15th, 2014     Nathalie Le Guay             T-265496: Removed Stage_4_Exit_Criteria_Met in isStage4ExitCriteriaMet() 
 *                                                 and Stage_5_Exit_Criteria_Met in isStage5ExitCriteriaMet()
 * Apr 16th, 2014     Arpita Bose                  T-271695: Renamed fields Has_Stage_4_Approval__c to Has_Stage_3_Approval__c 
 *                                                  and Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * May 21st, 2014     Nathalie Le Guay             Updated getOpportunitiesExitCriteriaNotMet() skipping stage section so that it doesnt apply in testing
 * Jul 28th, 2014     Nathalie Le Guay             S-252919 - Added Outcomes__c to the Opp query (getOpportunitiesExitCriteriaNotMet)
 * Sep 29th, 2014     Naresh Kr Ojha               T-323155: Free trial opportunity wont go through Oppty Exit criteria Validations, added check
 * Nov 11th, 2014     Noopur                       Added the conditions to check of the current user is EDQ and UK&I to bypass some of the criteria.
 ============================================================================================================*/
public with sharing class Opportunity_ExitCriteriaUtility {

  private static Boolean isCriteriaMet;
  public static String errorMessage;
  public static User currentUser = [select Id,Region__c 
                                    from User
                                    Where Id = :userinfo.getUserId()];
  
  public static Boolean bypassTheCriteria ;
  //Querried opportunities
  public static Map<String, Opportunity> opportunityMap;

  private static Map<String, Set<String>> oppStagesAllowedMap = new Map<String, Set<String>>{
                                   Constants.OPPTY_STAGE_3 => new Set<String>{Constants.OPPTY_STAGE_4},
                                   Constants.OPPTY_STAGE_4 => new Set<String>{Constants.OPPTY_STAGE_5, Constants.OPPTY_STAGE_3},
                                   Constants.OPPTY_STAGE_5 => new Set<String>{Constants.OPPTY_STAGE_6, Constants.OPPTY_STAGE_4, Constants.OPPTY_STAGE_3},
                                   Constants.OPPTY_STAGE_6 => new Set<String>{Constants.OPPTY_STAGE_7, Constants.OPPTY_STAGE_5, Constants.OPPTY_STAGE_4, Constants.OPPTY_STAGE_3}
  };
  public static Map<String, Integer> oppStageNameToNumberMap = new Map<String, Integer>{
                                   Constants.OPPTY_STAGE_3 => 3,
                                   Constants.OPPTY_STAGE_4 => 4,
                                   Constants.OPPTY_STAGE_5 => 5,
                                   Constants.OPPTY_STAGE_6 => 6,
                                   Constants.OPPTY_STAGE_7 => 7
  };

  public static Map<Integer, String> oppStageNumberToNameMap = new Map<Integer, String>{
                                   3 => Constants.OPPTY_STAGE_3,
                                   4 => Constants.OPPTY_STAGE_4,
                                   5 => Constants.OPPTY_STAGE_5,
                                   6 => Constants.OPPTY_STAGE_6,
                                   7 => Constants.OPPTY_STAGE_7
  };


  //============================================================================================
  // T-251412: Exit Criteria: Display error message if Exit Criteria of previous Stages not met
  //============================================================================================
  private static Boolean isPassingRequiredExitCriteria (Opportunity opp, String stageName, String oldStage) {
    Boolean meetingCriteria = true;

    Integer startApplyingCriteriaStage = 3;
    system.debug('\n[Opportunity_ExitCriteriaUtility : isPassingRequiredExitCritria] : opp.Starting_Stage__c' + opp.Starting_Stage__c + ' oldStage' + oldStage);
    Integer startingStageNumber = oppStageNameToNumberMap.get(opp.Starting_Stage__c);
    Integer stageNumber = oppStageNameToNumberMap.get(stageName);
    Integer oldStageNum = oppStageNameToNumberMap.get(oldStage);
    
    
    system.debug('\n[Opportunity_ExitCriteriaUtility : isPassingRequiredExitCritria] : startingStageNumber: '+ startingStageNumber + ' and opps startingstage: ' + opp.Starting_Stage__c);
    if (String.isNotEmpty(opp.Starting_Stage__c) && startingStageNumber != null) {
      startApplyingCriteriaStage = startingStageNumber;
    }
    
    //system.debug('\n[Opportunity_ExitCriteriaUtility : isPassingRequiredExitCritria] : tempStage: ' + tempStage + ' and startingStageNb: ' + startingStageNumber);
    
    do {
      system.debug('\n[Opportunity_ExitCriteriaUtility : isPassingRequiredExitCriteria] : \nstartApplyingCriteriaStage:' + startApplyingCriteriaStage + ' \nstageNumber:'+ stageNumber);
      system.debug('\n[Opportunity_ExitCriteriaUtility : isPassingRequiredExitCriteria] :startApplyingCriteriaStage <= stageNumber?' + (startApplyingCriteriaStage <= stageNumber) + '\nstageNumber > oldStageNum?'+(stageNumber > oldStageNum));
      if ((startApplyingCriteriaStage <= stageNumber && stageNumber > oldStageNum)/* || (startApplyingCriteriaStage < oldStageNum && stageNumber < oldStageNum)*/) {
        system.debug('\nIs tempStage >= oldStageNum ? tempStage='+startApplyingCriteriaStage + ' and oldStageNum='+oldStageNum);
        meetingCriteria = isMeetingExitCriteria(opp, oppStageNumberToNameMap.get(startApplyingCriteriaStage+1), oppStageNumberToNameMap.get(startApplyingCriteriaStage));

        System.debug(meetingCriteria+'\n[Opportunity_ExitCriteriaUtility: isPassingRequiredExitCritria111] : from: '+ oppStageNumberToNameMap.get(startApplyingCriteriaStage+1)+
                                                                                        ' to: '+ oppStageNumberToNameMap.get(startApplyingCriteriaStage)+ '\n:::'+ meetingCriteria);


        //oldStageNum++;
      } /*else { 
        System.debug('\n[Opportunity_ExitCriteriaUtility: isPassingRequiredExitCritria222] : from: '+ oppStageNumberToNameMap.get(tempStage+1)+
                                                                                        ' to: '+ oppStageNumberToNameMap.get(tempStage));


        meetingCriteria = isMeetingExitCriteria(opp, oppStageNumberToNameMap.get(tempStage+1), oppStageNumberToNameMap.get(tempStage)); 
      }*/
      
      if (!meetingCriteria) {
        errorMessage = 'Opportunity Exit Criteria are not met when moving from stage : '+oldStage + ' to '+stageName + '. '+ errorMessage;
        return false;
      }
      startApplyingCriteriaStage++;
    } while (startApplyingCriteriaStage < stageNumber);
    
    return meetingCriteria;
  }


  //============================================================================================
  // Returns list of opportunities which do not match exit criteria
  //============================================================================================
  public static Boolean getOpportunitiesExitCriteriaNotMet (
                                                Map<Id, Opportunity> newOpps, 
                                                Map<Id, Opportunity> oldOpps) {
    if (!OpportunityTriggerHandler.hasCheckedExitCriteria) {
      OpportunityTriggerHandler.hasCheckedExitCriteria = true;
    }
    
    List<Opportunity> notMetOpportunitiesList = new List<Opportunity>();
    opportunityMap = new Map<String, Opportunity>();
    Global_Settings__c globalSettings = Global_Settings__c.getValues(Constants.GLOBAL_SETTING);    
    
    for (Opportunity oppty : [SELECT ID, Competitor_Count__c, Turn_Off_Contact_Role_Criteria_Check__c, StageName,Starting_Stage__c,
                                      CurrencyIsoCode, Budget__c, Has_Stage_3_Approval__c, Has_Senior_Approval__c,Opportunity_Products_Count__c, 
                                      Owner.Region__c, Stage_3_Approver__c, Senior_Approver__c,
                                      Is_There_Commercial_Risk__c, Is_There_Delivery_Risk__c,
                                      Is_There_Financial_Risk__c, Is_There_Legal_Risk__c,
                                      Has_There_Been_Significant_Change__c, Type, OwnerId,
                                      //Below_Review_Thresholds__c,  T-271695: Removed reference to Below_Review_Thresholds__c
                                      Amount, CloseDate, 
                                     (SELECT Id, Role, IsPrimary FROM OpportunityContactRoles WHERE Role =: Constants.DECIDER),
                                     (SELECT Id, Type, Status, Outcomes__c FROM Tasks
                                       WHERE Status =: Constants.STATUS_COMPLETED /*OR (Type =: Constants.ACTIVITY_TYPE_QUOTE_DELIVERED
                                                                                  OR Type =: Constants.ACTIVITY_TYPE_SELECTION_CONFIRMED
                                                                                  OR Type =: Constants.ACTIVITY_TYPE_SIGNED_CONTRACT)*/)
                              FROM Opportunity WHERE ID IN: newOpps.keySet()]) {
      opportunityMap.put(oppty.ID, oppty);
    }

    for (Opportunity oppty : newOpps.values()) {
      //As per task : T-323155 Free trial opportunity wont go through Opportunity exit criteria validations
      if (String.isNotBlank(oppty.Type) && oppty.Type.equalsIgnoreCase(Constants.OPPTY_TYPE_FREE_TRIAL)) {
        continue;
      }
      errorMessage = '';

      if (oppty.StageName == globalSettings.Opp_Stage_4_Name__c && 
              oldOpps.get(oppty.Id).StageName == globalSettings.Opp_Stage_3_Name__c) {
        //If this was an originally loaded Opportunity then we don't require people to fill in the contact role
        if(opportunityMap.get(oppty.ID).OpportunityContactRoles.size() < 1 && !opportunityMap.get(oppty.ID).Turn_Off_Contact_Role_Criteria_Check__c) {
          oppty.StageName.addError(Label.Opp_Stage_3_Stage_Exit_Failure);
          continue;
        }
      }

      // Check whether opportunity skipping stage
      if (Test.isRunningTest() && Constants.OPPTY_CHECK_SKIPPING && !oppty.isClosed
          && !oppty.StageName.equalsIgnoreCase(Constants.OPPTY_STAGE_NO_DECISION)
          && isSkippingStages(oppty.StageName, oldOpps.get(oppty.ID).StageName)) {
        oppty.addError (Label.OECS_MSG_SKIPSTAGE);
        notMetOpportunitiesList.add(oppty);
        continue;
      }

      System.debug('\nOldStageName: '+oldOpps.get(oppty.ID).StageName + '\nNew StageNAME: '+ oppty.StageName );
      system.debug('\n===isPassingRequiredExitCriteria(opportunityMap.get(oppty.ID), oppty.StageName, oldOpps.get(oppty.ID).StageName)=' + isPassingRequiredExitCriteria(opportunityMap.get(oppty.ID), oppty.StageName, oldOpps.get(oppty.ID).StageName));
      // passing both opp and oppty's StageName because the opp from the opportunityMap is retrieved from DB, not from trigger
      if (oppty.StageName <> oldOpps.get(oppty.ID).StageName && !isPassingRequiredExitCriteria(opportunityMap.get(oppty.ID), oppty.StageName, oldOpps.get(oppty.ID).StageName)) {
        //Moving to new stage  
        oppty.StageName.addError (errorMessage);
      }
    }

    return (notMetOpportunitiesList.size() > 0? false:true);
  }


  //============================================================================================
  // Check two stages weather the stage is skpping
  //============================================================================================
  private static Boolean isSkippingStages (String newStage, String oldStage) {
    Boolean isSkipping = false;

    if (oppStagesAllowedMap.get(oldStage) != null && newStage != oldStage
        && !oppStagesAllowedMap.get(oldStage).contains(newStage)) {
      isSkipping = true;
    }
    
    return isSkipping;
  }

  //============================================================================================
  //check opportunity weather that is meeting exit criteria
  //============================================================================================
  public static Boolean isMeetingExitCriteria (Opportunity opp, String newStage, 
                                                              String oldStage) {
    Boolean isOpptyMeetingExitCriteria = true;
    Decimal adjustedRate = 0.00;
    Decimal currencyRate = 1.00;
    /*********Code Added By Mohit Begins **************************************/
    Set<String> setOppCurrencyISOCode = new Set<String>();
    setOppCurrencyISOCode.add(opp.CurrencyIsoCode);
    CurrencyUtility currencyUtil = new CurrencyUtility(setOppCurrencyISOCode);
    /*********Code Added By Mohit Ends **************************************/
    currencyRate = currencyUtil.convertCurrency(opp.CurrencyIsoCode, 1, Constants.CURRENCY_GBP, opp.CloseDate);
    adjustedRate = 1 - currencyRate;
    String groupName = BusinessUnitUtility.getBusinessUnit(opp.OwnerId) ;
    if (String.isNotBlank(groupName) && groupName.equalsIgnoreCase(Constants.EDQ) && 
      opp.Owner.Region__c == Constants.REGION_UKI) {
      bypassTheCriteria = true;
    }
    else {
    	bypassTheCriteria = false;
    }
    system.debug('\n[Opportunity_ExitCriteriaUtility : isMeetingExitCriteria]' + bypassTheCriteria);

    //When opportunity moving Stage 3 to Stage 4.
    if (newStage == Constants.OPPTY_STAGE_4 && oldStage == Constants.OPPTY_STAGE_3) { 
      isOpptyMeetingExitCriteria = isStage3ExitCriteriaMet(opp, newStage, oldStage, adjustedRate);
    } //When opportunity moving Stage 4 to Stage 5.
    else if (newStage == Constants.OPPTY_STAGE_5 && oldStage == Constants.OPPTY_STAGE_4) {
      isOpptyMeetingExitCriteria = isStage4ExitCriteriaMet(opp, newStage, oldStage, adjustedRate);
    } //When opportunity moving Stage 5 to Stage 6.
    else if (newStage == Constants.OPPTY_STAGE_6 && oldStage == Constants.OPPTY_STAGE_5) {
      isOpptyMeetingExitCriteria = isStage5ExitCriteriaMet(opp, newStage, oldStage, adjustedRate);
    }
    else if (newStage == Constants.OPPTY_STAGE_7 && oldStage == Constants.OPPTY_STAGE_6) {
      System.debug(opp.Has_There_Been_Significant_Change__c+'[**8opp****]'+opp);
      isOpptyMeetingExitCriteria = isStage6ExitCriteriaMet(opp, newStage, oldStage);
    }

    return isOpptyMeetingExitCriteria;
  }

  //============================================================================================
  // Stage 3 exit criteria met ?
  //============================================================================================
  private static Boolean isStage3ExitCriteriaMet(Opportunity opp, String newStage, String oldStage, Decimal adjustedRate) {
    isCriteriaMet = true;
    system.debug('\n[Opportunity_ExitCriteriaUtility: isStage3ExitCriteriaMet] new Stage:' +newStage + ' oldStage: '+oldStage + '; adjustedRate: '+ adjustedRate);
    
    //Validation Rule: stage_3_Exit_Criteria_Met
    // removed: opp.Has_Completed_Task == false as per Task T-251145 (nojha Feb 21st, 14.)
    if (opp != null &&
       ((opp.Tasks != null && opp.Tasks.size() < 1 )
        || opp.Budget__c == ''
        || (opp.Competitor_Count__c == null || Integer.valueOf(opp.Competitor_Count__c) == 0)
        || (opp.OpportunityContactRoles != null && 
              opp.OpportunityContactRoles.size() < 1 && 
              !opp.Turn_Off_Contact_Role_Criteria_Check__c))
        ) {
      isCriteriaMet = false;
      errorMessage = Label.OECS_MSG_STAGE3_EXIT;
    }

        System.debug('[---debug1.0--]'+opp.Stage_3_Approver__c);
        System.debug('[---debug1.1--]'+opp.Has_Stage_3_Approval__c);
        System.debug('[---debug1.2--]'+opp.StageName);
        System.debug('[---debug1.3--]'+opp);
        System.debug('[---debug1.4--]'+bypassTheCriteria);
    if (opp.Owner.Region__c == Constants.REGION_UKI && !bypassTheCriteria && opp.Amount >= 500000 && oppStageNameToNumberMap.get(newStage) == 4) {

        
      if (opp.Stage_3_Approver__c == null) {
        errorMessage += ' ' + Label.OECS_MSG_POPULATE_STAGE_3_APPROVER;
        isCriteriaMet = false;
      }
      else if (opp.Has_Stage_3_Approval__c == false) {
        errorMessage += ' ' + Label.OECS_MSG_STAGE_3_TO_4_AMOUNTORTAA_OVER_APPROVAL;
        isCriteriaMet = false;
      }
    }
    system.debug('\n[Opportunity_ExitCriteriaUtility: isStage3ExitCriteriaMet] stage 3 met:' +isCriteriaMet);
    return isCriteriaMet;
  }

  //============================================================================================
  // Stage 4 exit criteria met ?
  //============================================================================================
  private static Boolean isStage4ExitCriteriaMet(Opportunity opp, String newStage, String oldStage, Decimal adjustedRate) {
    isCriteriaMet = true;
    Boolean hasQuoteDelivered = hasRequiredTask(opp, Constants.ACTIVITY_TYPE_QUOTE_DELIVERED);
    
    if (!hasQuoteDelivered || opp.Opportunity_Products_Count__c == 0) {
      errorMessage += '\n'+Label.OECS_MSG_STAGE_4_EXIT_CRITERIA;
      isCriteriaMet = false;
    }
    system.debug('\nOpp Region: '+ opp.Owner.Region__c + ' bypass: ' + bypassTheCriteria);
    if (opp.Owner.Region__c == Constants.REGION_UKI && !bypassTheCriteria) {
      if (opp.Is_There_Commercial_Risk__c == null || opp.Is_There_Delivery_Risk__c == null
         || opp.Is_There_Financial_Risk__c == null|| opp.Is_There_Legal_Risk__c == null) {
        errorMessage += '\n'+Label.OECS_MSG_POPULATE_RISK_FIELDS;
        isCriteriaMet = false;
      }
      if ((opp.Has_There_Been_Significant_Change__c != null && opp.Has_There_Been_Significant_Change__c.equalsIgnoreCase('Yes'))
       || opp.Amount >= 500000
              /*(opp.Is_There_Commercial_Risk__c != null && opp.Is_There_Commercial_Risk__c.equalsIgnoreCase('Yes'))
           || (opp.Is_There_Delivery_Risk__c != null && opp.Is_There_Delivery_Risk__c.equalsIgnoreCase('Yes'))
           || (opp.Is_There_Financial_Risk__c != null && opp.Is_There_Financial_Risk__c.equalsIgnoreCase('Yes'))
           || (opp.Is_There_Legal_Risk__c != null && opp.Is_There_Legal_Risk__c.equalsIgnoreCase('Yes'))
         */) {
        if (opp.Senior_Approver__c == null) {
          errorMessage = Label.OECS_MSG_POPULATE_SENIOR_APPROVER;
          isCriteriaMet = false;
        } else if (opp.Has_Senior_Approval__c == false) {
          errorMessage += '\n'+Label.OECS_MSG_STAGE_4_TO_5_AMOUNTORTAA_OVER_APPROVAL;
          isCriteriaMet = false;
        }
      }
    }
 /*   // Validation Rule: Stage_4_to_5_Opportunity_Approval
    if (// Can be updated not to have to check the specific currency
       opp.Below_Review_Thresholds__c == 'No' && opp.Has_Stage_3_Approval__c == false &&
       (opp.Amount < (100000 * adjustedRate) + 100000)) {
       //  || opp.Total_Annual_Amount__c < (40000 * adjustedRate) + 40000)) { T-267875: Refactoring OLI fields
        isCriteriaMet = false;
        errorMessage = Label.OECS_MSG_STAGE_4_TO_5_OPPTY_APPROVAL;
        system.debug('\n[Opportunity_ExitCriteriaUtility: isStage4ExitCriteriaMet] stage 4 not met:' +errorMessage);
        return isCriteriaMet;  
    } */  
    
    // Removed Validation Rule: Stage_4_to_5_AmountOrTAA_Over_Approval as per T-267875 
   
/*    // Validation Rule: Stage_4_to_5_AmountOrTAA_Over_Approval
    if (opp.Amount >= ((100000 * adjustedRate) + 100000) && opp.Has_Stage_3_Approval__c == false) {
      isCriteriaMet = false;
      errorMessage = Label.OECS_MSG_STAGE_4_TO_5_AMOUNTORTAA_OVER_APPROVAL;
      system.debug('\n[Opportunity_ExitCriteriaUtility: isStage4ExitCriteriaMet] stage 4 not met:' +errorMessage);
      return isCriteriaMet;
    } */ 
    
    system.debug('\n[Opportunity_ExitCriteriaUtility: isStage4ExitCriteriaMet] stage 4 met:' +isCriteriaMet);
    return isCriteriaMet;
  }

  //============================================================================================
  // Stage 5 exit criteria met ?
  //============================================================================================
  private static Boolean isStage5ExitCriteriaMet(Opportunity opp, String newStage, String oldStage, Decimal adjustedRate) {
    isCriteriaMet = true;
    Boolean hasSelectionConfirmed = hasRequiredTask(opp, Constants.ACTIVITY_TYPE_SELECTION_CONFIRMED);

    if (!hasSelectionConfirmed) {
        errorMessage += '\n'+Label.OECS_MSG_STAGE_5_EXIT_CRITERIA_MET;
        isCriteriaMet = false;
    }

    if (opp.Owner.Region__c == Constants.REGION_UKI && !bypassTheCriteria) {
      if (opp.Is_There_Commercial_Risk__c == null || opp.Is_There_Delivery_Risk__c == null
         || opp.Is_There_Financial_Risk__c == null|| opp.Is_There_Legal_Risk__c == null) {
        errorMessage += Label.OECS_MSG_POPULATE_RISK_FIELDS;
        isCriteriaMet = false;
      }
      if (opp.Has_There_Been_Significant_Change__c == null) {
        isCriteriaMet = false;
      }
      if ((opp.Has_There_Been_Significant_Change__c != null && opp.Has_There_Been_Significant_Change__c.equalsIgnoreCase('Yes'))
        || opp.Amount >= 500000) {
        if (opp.Senior_Approver__c == null) {
          errorMessage += Label.OECS_MSG_POPULATE_SENIOR_APPROVER;
          isCriteriaMet = false;
        } else if (opp.Has_Senior_Approval__c == false) {
          errorMessage += Label.OECS_MSG_STAGE_5_TO_6_OPPTY_APPROVAL;
          isCriteriaMet = false;
        }
      }
    }
/*    // Validation Rule: Stage_5_to_6_Opportunity_Approval
    if (opp.Has_Senior_Approval__c == false &&
        opp.Below_Review_Thresholds__c == 'No' &&
          (opp.Amount < (100000 * adjustedRate) + 100000)) {// || opp.Total_Annual_Amount__c < (40000 * adjustedRate) + 40000 )) { T-267875: Refactoring OLI fields

      isCriteriaMet = false;
      errorMessage = Label.OECS_MSG_STAGE_5_TO_6_OPPTY_APPROVAL; 
      system.debug('\n[Opportunity_ExitCriteriaUtility: isStage5ExitCriteriaMet] stage 5 not met:' +errorMessage);
      return isCriteriaMet;
    } */ 
    system.debug('\n[Opportunity_ExitCriteriaUtility: isStage5ExitCriteriaMet] stage 5 met:' +isCriteriaMet);
    return isCriteriaMet;
  }
  
  //============================================================================================
  // Stage 6 Exit Criteria not met?
  //============================================================================================
  private static Boolean isStage6ExitCriteriaMet(Opportunity opp, String newStage, String oldStage) {
    isCriteriaMet = true;
    Boolean hasSignedContract = hasRequiredTask(opp, Constants.ACTIVITY_TYPE_SIGNED_CONTRACT);
    //Validation Rule: Stage_6_Exit_Criteria_Met
    if (hasSignedContract == false) {
      isCriteriaMet = false;
      errorMessage += Label.OECS_MSG_STAGE_6_EXIT_CRITERIA_MET;
    }
    System.debug('[---opp.Owner.Region__c--->]'+opp.Owner.Region__c);
    if (opp.Owner.Region__c == Constants.REGION_UKI && !bypassTheCriteria) {
      System.debug('[---opp.Has_There_Been_Significant_Change__c--->]'+opp.Has_There_Been_Significant_Change__c);
      if (String.isBlank(opp.Has_There_Been_Significant_Change__c)) {
        System.debug('[---opp.e--->]:'+opp.Has_There_Been_Significant_Change__c);
        errorMessage += Label.OECS_MSG_POPULATE_SIGNIFICANT_CHANGE;
        isCriteriaMet = false;
      } else if (opp.Has_There_Been_Significant_Change__c.equalsIgnoreCase('Yes')) {
        if (opp.Senior_Approver__c == null) {
          errorMessage += Label.OECS_MSG_POPULATE_SENIOR_APPROVER;
          isCriteriaMet = false;
        } else if (opp.Senior_Approver__c != null && opp.Has_Senior_Approval__c == false) {
          errorMessage += Label.OECS_MSG_STAGE_6_TO_7_OPPTY_APPROVAL;
          isCriteriaMet = false;
        }
      }
    }
    return isCriteriaMet;
  }
  
  //============================================================================================
  // Utility method to check wether an Opp has a required task or not by specifying the task Type
  //============================================================================================
  public static Boolean hasRequiredTask(Opportunity opp, String taskType) {
    
    if (opp.Tasks.size() > 0) {
      for (Task t: opp.Tasks) {
        if (String.isNotBlank(t.Outcomes__c) && t.Outcomes__c.containsIgnoreCase(taskType) && 
              String.isNotEmpty(t.Status) && 
                      t.Status.equalsIgnoreCase(Constants.STATUS_COMPLETED)) {
          return true;
        }
      }
    }
    return false;
  }
}