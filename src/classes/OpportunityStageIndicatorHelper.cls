/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityStageIndicatorHelper
 * Description: 
 * Created Date: January 2014 (reused from topCoder challenge)
 * Created By: Nathalie Le Guay (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 13th, 2014               Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Feb 22th, 2014               Naresh kr Ojha (Appirio)     T-251145: updated to remove ref Has_Completed_Task__c
 * Feb 27th, 2014               Nathalie Le Guay (Appirio)   Class cleanup
 * March 3rd, 2014              Nathalie Le Guay             Updated opp query
 * Apr 15th, 2014               Arpita Bose (Appirio)        T-271695: Removed reference to Below_Review_Thresholds__c field
 * Apr 16th, 2014               Arpita Bose (Appirio)        T-271695: Renamed fields Has_Stage_4_Approval__c to Has_Stage_3_Approval__c 
 *                                                           and Has_Stage_5_Approval__c to Has_Senior_Approval__c
 * Apr 16th, 2014               Nathalie Le Guay             T-272404: Adding Approval Process fields to Opportunity query
 * Jul 28th, 2014               Nathalie Le Guay             S-252919 - Added Outcomes__c to the Opp query (constructor)
 * Nov 13th, 2014               Arpita Bose                  T-333541 - Added method edqUKIUser()
 * Mar 18th, 2015				Paul Kissick				 Case #591965 - Fix for Chinese not rendering properly.
 =====================================================================*/
public without sharing class OpportunityStageIndicatorHelper {
    
    public Opportunity                  opp                 {get;set;}
    public List<wrapperStage>           lstStages           {get;set;}
    public Boolean                      hasContactRole      {get;set;}
    public Boolean                      hasCompletedTask    {get;set;}
    public Integer                      NUM_500000 {get;set;}


  /*
   *   Constructor taking standard controller as a parameter
   */
  public OpportunityStageIndicatorHelper(ApexPages.StandardController controller) {
    NUM_500000 = Integer.valueOf(Label.NUM_500000); 
    if (!String.isBlank(controller.getId())) {
        /* 
         * Removed as this isn't needed. Case #591965
        Set<String> pickListValuesToRemove = new Set<String>{Constants.STR_PROSPECTING,
                                                           Constants.STR_QUALIFICATION,
                                                           Constants.STR_NEEDSANALYSIS,
                                                           Constants.STR_VALUE_PROPOSITION,
                                                           Constants.STR_ID_DECISIO_NMAKERS,
                                                           Constants.STR_PERCEPTION_ANALYSIS,
                                                           Constants.STR_PROPOSAL_PRICEQUOTE,
                                                           Constants.STR_NEGOTIATION_REVIEW,
                                                           Constants.STR_CLOSED_WON,
                                                           Constants.STR_CLOSED_LOST};
		*/
      Set<String> allowedStages = new Set<String>();

      for (Opportunity_Sales_Process__c osp : [SELECT Sales_Process_Name__c, Name
                                               FROM Opportunity_Sales_Process__c
                                               WHERE Sales_Process_Name__c =: Constants.OPPTY_SALES_PROCESS_STANDARD]) {
        allowedStages.add(osp.Name);
      } 
           
      opp = [SELECT Id, Turn_Off_Contact_Role_Criteria_Check__c, toLabel(StageName), Starting_Stage__c, Has_Stage_3_Approval__c,
                    //Below_Review_Thresholds__c,  T-271695: Removed reference to Below_Review_Thresholds__c field
                    Opportunity_Products_Count__c, Has_Senior_Approval__c, Senior_Approver__c,
                    Competitor_Count__c, Amount, Budget__c, isClosed, Owner.Region__c,
                    Is_There_Commercial_Risk__c, Is_There_Delivery_Risk__c,
                    Is_There_Financial_Risk__c, Is_There_Legal_Risk__c,
                    Has_There_Been_Significant_Change__c, Stage_3_Approver__c, OwnerId,
                    (SELECT Id, Role, IsPrimary FROM OpportunityContactRoles WHERE Role =: Constants.DECIDER),
                    (SELECT Id, Type, Status, Outcomes__c
                     FROM Tasks WHERE Status =: Constants.STATUS_COMPLETED)
             FROM Opportunity
             WHERE Id = :controller.getId()];
        
      String sObjectName = controller.getRecord().getSObjectType().getDescribe().getName();
      lstStages = new List<wrapperStage>();
      hasContactRole = opp.OpportunityContactRoles.size() > 0;
      hasCompletedTask = opp.Tasks.size() > 0;
      Schema.DescribeFieldResult f = Schema.sObjectType.Opportunity.fields.StageName;
      // Get the field describe result from the token
      f = f.getSObjectField().getDescribe();
      List <Schema.PicklistEntry> picklistValues = f.getPicklistValues();  
      System.debug('----allowedStages---'+allowedStages);
      for (Integer x = 0; x < picklistValues.size(); x++) {
        //if (!pickListValuesToRemove.contains(picklistValues[x].getLabel().toLowerCase())) {  // PK Case #591965 - Removed as this seems pointless
          System.debug('=======>'+picklistValues[x].getLabel());
          if (allowedStages.contains(picklistValues[x].getValue())) {  // PK Case #591965 - Changed to value.
            lstStages.add(new wrapperstage(picklistValues[x].getLabel()));
          }
        //}
      }

      for (Integer i = 0; i < lstStages.size(); i++) {
        if (opp.StageName == lstStages[i].strStageName) {
          lstStages[i].bolCompleted = true;
          lstStages[i].bolCurrent = true;
          if (i > 1) {
            lstStages[i - 1].bolCurrent = false;
          }
          break;
        } else if (opp.StageName == Constants.OPPTY_CLOSED_LOST) { 
          lstStages[i].bolCompleted = false;
          break;
        } else {
          lstStages[i].bolCompleted = true;
        }
      }
    }
  }

  //=============================================================
  // Booleans used by the VF page for one of the Exit Criteria
  //=============================================================
  public Boolean hasSignedContract {
    get {
     if (hasSignedContract == null && opp != null) {
       hasSignedContract = Opportunity_ExitCriteriaUtility.hasRequiredTask(opp, Constants.ACTIVITY_TYPE_SIGNED_CONTRACT);
     }
     return hasSignedContract;
    }
    set;
  }

  public Boolean hasSelectionConfirmed {
    get {
      if (hasSelectionConfirmed == null & opp != null) {
        hasSelectionConfirmed = Opportunity_ExitCriteriaUtility.hasRequiredTask(opp, Constants.ACTIVITY_TYPE_SELECTION_CONFIRMED);
      }
      return hasSelectionConfirmed;
    }
    set;
  }

  public Boolean hasQuoteDelivered {
    get {
      if (hasQuoteDelivered == null && opp != null) {
        hasQuoteDelivered = Opportunity_ExitCriteriaUtility.hasRequiredTask(opp, Constants.ACTIVITY_TYPE_QUOTE_DELIVERED);
      }
      return hasQuoteDelivered;
    }
    set;
  }

    /*
    *   Wrapper class 
    */
    public class wrapperStage {
        public string strStageName {get;set;}
        public boolean bolCompleted {get;set;}
        public boolean bolCurrent {get;set;} 
        public wrapperStage(string y){
            strStageName = y; 
        }
    }
    
    //=================================================================================
    // T-333541: UK&I Exit Criteria: Approvals exit criteria do not apply to EDQ Users
    //=================================================================================
    
    public Boolean edqUKIUser {
      get {
        edqUKIUser = false;
        User currentUser = [SELECT Id,Region__c 
                            FROM User
                            WHERE Id = : opp.OwnerId];
        String groupName = BusinessUnitUtility.getBusinessUnit(userinfo.getUserId()) ;
        if (String.isNotBlank(groupName) && groupName.equalsIgnoreCase(Constants.EDQ) && 
              currentUser.Region__c == Constants.REGION_UKI) {
          edqUKIUser = true;
        }
        return edqUKIUser;
      }
      set;
    }
}