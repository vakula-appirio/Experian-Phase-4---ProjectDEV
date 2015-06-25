/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTriggerHelper
 * Description: Class is created to hold related methods and functionality for 
 *                        OpportunityTriggerHandler and OpportunityTrigger
 * Created Date: 02/04/2014 for T-243865
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified        Modified By                  Description of the update
 * Feb 7th, 2014        Naresh kr Ojha (Appirio)     Modified as per suggested by chatter post on T-243865
 * Feb 10th, 2014       Nathalie Le Guay (Appirio)   Commented Asset creation - not for Feb 17th release unless specified otherwise
 *                                                   Adding currency conversion (will need to be added to utility class later on)
 *                                                   Remove population of Order__c.Total__c field (will be calculated by OLItrigger)
 * Feb 17th, 2014       Jinesh Goyal (Appirio)       added null pointer check for T-249048
 * Feb 27th, 2014       Naresh Kr Ojha (Appirio)     T-249341: Updated "checkAccessOnAccountForUser" method to fix issue related to creation of opportunity.
 * Feb 27th, 2014       Nathalie Le Guay             Adding deleteExistingOrders() - I-103403
 * Mar 04th, 2014       Arpita Bose (Appirio)        T-243282: Added constants in place of String
 * Mar 04th, 2014       Nathalie Le Guay             Reordering lines in createOrderAndOrderLineItems to avoid unnecessary processing
 * March 05th, 2014     Nathalie Le Guay             Added deleteOrderIfOppIsReopened()
 * Mar 11th & 13th,2014 Naresh Kr Ojha               T-257871 - added multiCurrencyFieldUpdate()
 * Mar 13th, 2014       Nathalie Le Guay             T-257871 - updated multiCurrencyFieldUpdate signature
 * Mar 17th, 2014       Nathalie Le Guay             Removed checks on StageName value, to instead check on isClosed and isWon fields
 * Mar 18th, 2014       Naresh Kr Ojha               T-260145: Renamed deleteOrderIfOppIsReopened to deleteOrderAndOppIfOppIsReopened and 
 *                                                   deleting related oppties and orders, when oppty reopened.
 * Mar 19th, 2014       Arpita Bose(Appirio)         T-260619: Updated "createOrders" method to populate the Order Service Start/End date from Opportunity
 *                                                   Service Start/End date
 * Mar 20th, 2014       Naresh Kr Ojha               T-260654: Opp Stage Duration: Opportunity Trigger: calculateStageDuration()
 * Mar 21st, 2014       Nathalie Le Guay             Updating createOrder() to trim the Order name length
 * Mar 24th, 2014       Nathalie Le Guay             Updating multiCurrencyFieldUpdate() to use DateConversionRate, bc CurrencyUtility is querying the wrong table
 * Apr 7th,  2014       Mohit Parnami                T-267436: Added New Method updateOppFieldsIfWonOrClosed : updates owners related fields if isWon
 *                                                   or isClosed fields of opportunity are updated from false to true
 * Apr 11th, 2014       Nathalie Le Guay             Remove setOppIdIsWonUpdated use in updateOppFieldsIfWonOrClosed() per Chatter on I-111821
 * Apr 28th, 2014       Arpita Bose                  T-275717: Added LIMIT in multiCurrencyFieldUpdate()method to fix the Force.com Security Scanner Results
 * May 02nd, 2014       Nathalie Le Guay             Adding oppTriggerHasAlreadyRun Boolean to prevent recursive triggers
 * May 06th, 2014               Naresh Kr Ojha                           Moved oppTriggerHasAlreadyRun to Opportunity trigger.
 * Sep 15th, 2014       Naresh Kr Ojha               T-319088: On Demand Opportunity Line Item: Opp Trigger added method: onDemandOpportunityLineItem() 
                                                     Added Label.OPPTY_ERR_ONDEMAND_PRODUCT
 * Sep 16th, 2014       Arpita Bose                  I-130655: Reference of On_Demand_Product__c has been changed to EDQ_On_Demand_Product__c on OpportunityLineItem                                                     
 * Oct 22nd, 2014       Richard Joseph               To set SyncCPQ flag on all closed Opty.
 * Dec 16th, 2014       Naresh Kr Ojha               I-142629: added null pointer checks in updateAccPlanOpptyRecs() 
 * Dec 17th, 2014       James Weatherall             Case #54584: fix Owner Name on Close Date stamping
 * Mar 26th, 2015       Naresh                       T-373692: added method OpportunityTriggerHelper.populateSalesTeamChannelAndRegion()
 * May 20th, 2015       Paul Kissick                 Case #580226: resetCampaignForLeadConversions added for fixing primary campaign source
* Jun 10th, 2015       Naresh Kr Ojha               Commenting method as this method is already present in OpportunityTriggerHandler.cls 
                                                     and being used by same name and definition there.
 =====================================================================*/

public without sharing class OpportunityTriggerHelper {
  public static Boolean oppTriggerHasAlreadyRun = false;
  /* Added to OpportunityTrigger_OrderHelper
  public static String orderReadOnlyRT_ID;
  public static String orderLineReadOnlyRT_ID;*/


  //========================================================================================
  // T-249341: Prevent a user creating an opportunity if user dont have access on account.
  //========================================================================================
  public static void checkAccessOnAccountForUser (List<Opportunity> newList) {
    List<String> accountIDList = new List<String>();
    String currentUserId = UserInfo.getUserId();
    Map<String, Boolean> hasAccessMap = new Map<String, Boolean>();

    for (Opportunity opp: newList) {
      if (opp.AccountId != null) {
        accountIDList.add(opp.AccountId);
      }
    }

    Map<Id, Profile> allowedProfiles = new Map<Id, Profile>([SELECT Id
                                         FROM Profile
                                         WHERE Name= :Constants.PROFILE_SYS_ADMIN OR Name= :Constants.PROFILE_EXP_SALES_ADMIN]);

    // Populating hasAccess map to check further access.
    for (UserRecordAccess userAccess  : [SELECT RecordId, HasEditAccess
                                         FROM UserRecordAccess 
                                         WHERE UserId = :currentUserId 
                                          AND RecordId = :accountIDList]) {
      if (!hasAccessMap.containsKey(userAccess.RecordId)) {
        hasAccessMap.put(userAccess.RecordId, userAccess.HasEditAccess);
      }
      if (allowedProfiles.keySet().contains(UserInfo.getProfileId())) {
        hasAccessMap.put(userAccess.RecordId, true);
      }
    }

    // Adding error if user do not have access on the record
    for (Opportunity opp: newList) {
      if (opp.AccountId != null && hasAccessMap.containsKey(opp.AccountId)) {
        System.debug('\n[OpportunityTriggerHelper: checkAccessOnAccountForUser] : has Access? accountId='
                     + opp.AccountId + ' access: '+ hasAccessMap.get(opp.AccountId));
        if (hasAccessMap.get(opp.AccountId) != true) {
          opp.addError (Label.OPP_DONTHAVEACCESS_MSG);
        }
      }
    }
  }

  //========================================================================================
  // T-257871: Multi-Currency Dashboard: Opp Trigger
  //========================================================================================
  public static void multiCurrencyFieldUpdate(List<Opportunity> newList, Map<ID, Opportunity> oldMap) {
    //Map to hold conversion rates for currency. Key of map is ISO code for currency and value is as a list holds all
    //dated conversion rates.
    Map<String, List<DatedConversionRate>> currencyISO_ListDtConvRateMap = new Map<String, List<DatedConversionRate>>();
    Set<String> currencyISOCodes = new Set<String>();

    for (Opportunity oppty : newList) {
      //Skipping if update call do not changing closeDate of opportunity
      if ((oldMap != null && oldMap.get(oppty.ID).CloseDate == oppty.CloseDate
                          && oldMap.get(oppty.Id).CurrencyIsoCode == oppty.CurrencyIsoCode
                          && oldMap.get(oppty.Id).Amount == oppty.Amount)
          || (String.isNotEmpty(oppty.Type) && oppty.Type.equalsIgnoreCase(Constants.OPPTY_TYPE_FREE_TRIAL))) {
        continue;
      }
      currencyISOCodes.add(oppty.CurrencyISOCode);
    }

    // If nothing is to do with currencies
    if (currencyISOCodes.size() < 1) {
      return;
    }
    List<DatedConversionRate> dcrList = new List<DatedConversionRate>();
    //Retrieving all currency values and populating map
    for (DatedConversionRate dcr : [SELECT StartDate, NextStartDate, IsoCode, 
                                           Id, ConversionRate 
                                    FROM DatedConversionRate
                                    limit 10000
                                    ]) {
      if (!currencyISO_ListDtConvRateMap.containsKey(dcr.IsoCode)) {
        currencyISO_ListDtConvRateMap.put(dcr.IsoCode, new List<DatedConversionRate>());
      }
      currencyISO_ListDtConvRateMap.get(dcr.IsoCode).add(dcr);
      dcrList.add(dcr);
    }
    CurrencyUtility.queryAndLoadAllConversionRate();

    Set<String> opptyFields = Schema.SObjectType.Opportunity.fields.getMap().keySet();
    // Updating multi-currency fields
    for (Opportunity oppty : newList) {
      //Skipping if update call do not changing closeDate of opportunity
      if ((oldMap != null && oldMap.get(oppty.ID).CloseDate == oppty.CloseDate
                         && oldMap.get(oppty.Id).CurrencyIsoCode == oppty.CurrencyIsoCode
                         && oldMap.get(oppty.Id).Amount == oppty.Amount)
        || (String.isNotEmpty(oppty.Type) && oppty.Type.equalsIgnoreCase(Constants.OPPTY_TYPE_FREE_TRIAL))) {
        continue;
      }
      
      // if (currencyISO_ListDtConvRateMap.containsKey(oppty.CurrencyIsoCode)) {
      for (DatedConversionRate dcr : dcrList) {
        if (dcr.StartDate <= oppty.CloseDate && dcr.NextStartDate > oppty.CloseDate) {

          if (opptyFields.contains(String.valueOf(dcr.IsoCode+'_Conversion_Rate__c').toLowerCase())) {
            oppty.put(String.valueOf(dcr.IsoCode)+'_Conversion_Rate__c', dcr.ConversionRate);
          }
        }
      }
      if (oppty.Amount <> null) { 
        oppty.Amount_Corp__c = oppty.Amount / Double.valueOf(oppty.get(String.valueOf(oppty.CurrencyISOCode)+'_Conversion_Rate__c'));
      }
    }
  }

  //========================================================================================
  // T-260654: Opp Stage Duration: Opportunity Trigger
  //========================================================================================
  public static void calculateStageDuration(Map<ID, Opportunity> newOpps, Map<ID, Opportunity> oldOpps) {
    if (oppTriggerHasAlreadyRun == true) {
      return;
    }
    oppTriggerHasAlreadyRun = true;
    Set<ID> oppIDs = new Set<ID>();
    // This map helps to populate opptyId_OpptyHistoryMap with the correct OpportunityHistory record
    Set<String> addedToMap = new Set<String>();

    for (Opportunity oppty : newOpps.values()) {
      //As per task : T-323155 Free trial opportunity wont go through Opportunity should not calculate Stage Duration
      if (String.isNotEmpty(oppty.Type) && oppty.Type.equalsIgnoreCase(Constants.OPPTY_TYPE_FREE_TRIAL)) {
        continue;
      }
      if (oppty.StageName != oldOpps.get(oppty.ID).StageName) {
        oppIDs.add(oppty.ID);
      }
    }

    if (oppIds.size() == 0) {
      return;
    }

    // Initialize maps
    Map<String, String> oppStageToDurationFieldMap = new Map<String, String>();
    oppStageToDurationFieldMap.put(Constants.OPPTY_STAGE_3, Constants.STAGE_3_DURATION);
    oppStageToDurationFieldMap.put(Constants.OPPTY_STAGE_4, Constants.STAGE_4_DURATION);
    oppStageToDurationFieldMap.put(Constants.OPPTY_STAGE_5, Constants.STAGE_5_DURATION);
    oppStageToDurationFieldMap.put(Constants.OPPTY_STAGE_6, Constants.STAGE_6_DURATION);
    Map<ID, OpportunityHistory> opptyId_OpptyHistoryMap = new Map<ID, OpportunityHistory>();

    // Getting opportunity history for above opportunities.
    if (oppIDs.size() > 0) {
      for (OpportunityHistory opptyHist : [SELECT StageName, OpportunityId, Id, CreatedDate 
                                           FROM OpportunityHistory
                                           WHERE OpportunityID IN: oppIDs
                                                            order by CreatedDate DESC]) {
        // Find the OpportunityHistory that records the previous most recent change of Stage timestamp
        if (!addedToMap.contains(opptyHist.OpportunityID) && opptyHist.StageName.equalsIgnoreCase(oldOpps.get(opptyHist.OpportunityID).StageName)) {
          opptyId_OpptyHistoryMap.put(opptyHist.OpportunityID, opptyHist);
        } else { // once we no longer are looking at the right stage value in the OppHistory record, it means we need to keep the previous OppHistory
          if (opptyId_OpptyHistoryMap.containsKey(opptyHist.OpportunityID)) {
            addedToMap.add(opptyHist.OpportunityID);
          }
        }
      }

      Datetime dt_old, dt_new;
      String durationFieldName;
      for (ID key : oppIDs) {
        if (opptyId_OpptyHistoryMap.containsKey(key)) {
          dt_old = Datetime.valueOf(opptyId_OpptyHistoryMap.get(key).CreatedDate);
          dt_new = Datetime.now();
          String oldStageName = opptyId_OpptyHistoryMap.get(key).StageName;

          if (oldOpps.get(key).StageName == oldStageName && oppStageToDurationFieldMap.containsKey(oldStageName)) {
            durationFieldName = oppStageToDurationFieldMap.get(oldStageName);
            Decimal duration = (Decimal) newOpps.get(key).get(durationFieldName);
            duration = (duration != null) ? duration : 0.00;
            System.debug('\n[OpportunityTriggerHelper : calculateStageDuration] : existing duration: '+ duration);
            newOpps.get(key).put(durationFieldName, Integer.valueOf((dt_new.getTime() - dt_old.getTime())/1000) + duration);
            System.debug('\n[OpportunityTriggerHelper : calculateStageDuration] : new duration: '+ newOpps.get(key).get(durationFieldName));
          }
        }
      }
    }
  }

  //========================================================================================
  // T-267436: Update the opp fields if opp isWon or isClosed is changed from false to true
  //========================================================================================
  public static void updateOppFieldsIfWonOrClosed(Map<ID, Opportunity> newOpps, Map<ID, Opportunity> oldOpps){
    //Set<Id> setOppIdIsWonUpdated = new Set<Id>();
    Set<Id> setOppIdIsClosedUpdated = new Set<Id>();
    Map<Id, Opportunity> mapOppToUpdate = new Map<Id, Opportunity>();
    
    //T-279757
    Set<String> opttyFields = new Set<String>{'CloseDate', 'StageName', 'Amount'};
    Set<ID> opptyIDsToUpdateAccPlanOpptySet = new Set<ID>();    
    
    for (Opportunity oppty : newOpps.values()) {
      system.debug('\n[OpportunityTriggerHelper : updateOppFieldsIfWonOrClosed] : ====oldOpps.get(oppty.ID).IsWon===' + oldOpps.get(oppty.ID).IsWon
                   + '===oppty.IsWon===' + oppty.IsWon);
      /*if (oldOpps.get(oppty.ID).IsWon == false && oppty.IsWon != oldOpps.get(oppty.ID).IsWon) {
        setOppIdIsWonUpdated.add(oppty.ID);
      }*/
      if (oldOpps.get(oppty.ID).IsClosed == false && oppty.IsClosed != oldOpps.get(oppty.ID).IsClosed) {
        setOppIdIsClosedUpdated.add(oppty.ID);
        //[RJ] - To Set SYNCCPQ flag on Opty close.To update all related Quote status to either Close/Won or Close/Lost.
            oppty.SyncCPQ__c = true;
      }
      //T-279757
      if (isOpptyFieldUpdated(opttyFields, oppty, oldOpps.get(oppty.ID))) {
        opptyIDsToUpdateAccPlanOpptySet.add(oppty.ID);
      }
    }
    System.debug('[OpportunityTriggerHandler: updateOppFieldsIfWonOrClosed][--->]'+setOppIdIsClosedUpdated);
    //system.debug('\n[OpportunityTriggerHelper : updateOppFieldsIfWonOrClosed] : ====setOppIdIsWonUpdated==' + setOppIdIsWonUpdated);
    system.debug('\n[OpportunityTriggerHelper : updateOppFieldsIfWonOrClosed] : ====setOppIdIsClosedUpdated==' + setOppIdIsClosedUpdated);
    
    for (Opportunity opp : [SELECT Id,
                                  Owner_GBL_on_Opp_Close_Date__c,
                                  Owner_BU_on_Opp_Close_Date__c,
                                  Owner_BL_on_Opp_Close_Date__c,
                                  Owner_Sales_Team_on_Opp_Close_Date__c,
                                  Owner_Sales_Sub_Team_on_Opp_Close_Date__c,
                                  Owner_Country_on_Opp_Close_Date__c,
                                  Owner_Region_on_Opp_Close_Date__c,
                                  Owner_Name_on_Opp_Close_Date__c, // 17th Dec, 2014 - JW Case #54584: fix Owner Name stamping
                                  Owner.Sales_Sub_Team__c, 
                                  Owner.Business_Line__c,
                                  Owner.Sales_Team__c,
                                  Owner.Region__c,
                                  Owner.Global_Business_Line__c,
                                  Owner.Country__c,
                                  Owner.Business_Unit__c,
                                  Owner.Name, // 17th Dec, 2014 - JW Case #54584: fix Owner Name stamping
                                  OwnerId
                            FROM Opportunity 
                            WHERE //Id In : setOppIdIsWonUpdated AND
                            Id IN : setOppIdIsClosedUpdated]) {
      mapOppToUpdate.put(opp.Id, opp);
    }
    
    for (Opportunity oppty : newOpps.values()) {
      if (mapOppToUpdate.containsKey(oppty.Id)) {
        Opportunity queriedOpp = mapOppToUpdate.get(oppty.Id);
        System.debug('-----queriedOpp.Owner.Business_Unit__c--->'+queriedOpp.Owner.Business_Unit__c);
        oppty.Owner_GBL_on_Opp_Close_Date__c            = queriedOpp.Owner.Global_Business_Line__c;
        oppty.Owner_BU_on_Opp_Close_Date__c             = queriedOpp.Owner.Business_Unit__c;
        oppty.Owner_BL_on_Opp_Close_Date__c             = queriedOpp.Owner.Business_Line__c;
        oppty.Owner_Sales_Team_on_Opp_Close_Date__c     = queriedOpp.Owner.Sales_Team__c;
        oppty.Owner_Sales_Sub_Team_on_Opp_Close_Date__c = queriedOpp.Owner.Sales_Sub_Team__c;
        oppty.Owner_Country_on_Opp_Close_Date__c        = queriedOpp.Owner.Country__c;
        oppty.Owner_Region_on_Opp_Close_Date__c         = queriedOpp.Owner.Region__c;
        oppty.Owner_Name_on_Opp_Close_Date__c           = queriedOpp.Owner.Name; // 17th Dec, 2014 - JW Case #54584: fix Owner Name stamping
      }
    }

    system.debug('\n[OpportunityTriggerHelper : updateOppFieldsIfWonOrClosed] : ====newOpps==' + newOpps);
    system.debug('\n[OpportunityTriggerHelper : updateOppFieldsIfWonOrClosed] : ====mapOppToUpdate==' + mapOppToUpdate);
    
    //update mapOppToUpdate.values();
    
    //T-279757
    if (opptyIDsToUpdateAccPlanOpptySet.size() > 0) {
        updateAccPlanOpptyRecs(opptyIDsToUpdateAccPlanOpptySet);
    }
  }

  //====================================================================================
  // T-279757: Update Account Plan Opportunity records for oppty updated fieldset given.
  //====================================================================================
  private static void updateAccPlanOpptyRecs (Set<ID> opptyIDsToUpdateAccPlanOpptySet) {
    //Account plan opportunities to be updated
    List<Account_Plan_Opportunity__c> accPlanOppties = new List<Account_Plan_Opportunity__c>();
    
    for (Account_Plan_Opportunity__c apo : [SELECT TCV__c, Sales_Stage__c, Opportunity__c, 
                                                   Current_Year_Revenue__c, Close_Date__c, 
                                                   Annualised_Revenue__c, Opportunity__r.Amount,
                                                   Opportunity__r.StageName, Opportunity__r.CloseDate,
                                                   Opportunity__r.Contract_Start_Date__c, Opportunity__r.Contract_End_Date__c  
                                            FROM Account_Plan_Opportunity__c 
                                            WHERE Opportunity__c IN: opptyIDsToUpdateAccPlanOpptySet]) {
        apo.TCV__c = apo.Opportunity__r.Amount;
        apo.Sales_Stage__c = apo.Opportunity__r.StageName;
        apo.Close_Date__c = apo.Opportunity__r.CloseDate;
        //as per comment from Cheri J on task T-279757
        Integer monthDiff = 1;
        if (apo.Opportunity__r.Contract_Start_Date__c != null && apo.Opportunity__r.Contract_End_Date__c != null) {
          monthDiff = (apo.Opportunity__r.Contract_Start_Date__c.monthsBetween(apo.Opportunity__r.Contract_End_Date__c));
        }
        if (apo.Opportunity__r.Amount != null && monthDiff != null) {
          apo.Annualised_Revenue__c = apo.Opportunity__r.Amount / (monthDiff < 1 ? 1 : monthDiff)*12;
        }
        //apo.Current_Year_Revenue = apo.Opportunity__r;

        accPlanOppties.add(apo);
    }
    
    //Update call
    if (accPlanOppties.size() > 0) {
        update accPlanOppties;
    }
  }
  //============================================================================
  //Returns true if field has updated value in new record.
  //============================================================================
  private static Boolean isOpptyFieldUpdated (Set<String> fieldSet, Opportunity newRec, Opportunity oldRec) {
        for (String fieldName : fieldSet) {
            if(newRec.get(fieldName) != oldRec.get(fieldName)) {
                return true;
            }
        }
    return false;
  }
  
  //============================================================================== 
  //We need to validate data prior to closing an Opportunity. 
  //If an OpportunityLineItem is considered "On Demand" (it comes from another system), 
  //then the related Account should have an "On Demand" contact.
  //==============================================================================
  /* Commented method as this method is already present in OpportunityTriggerHandler.cls and being used by same name and 
     definition there. nojha June 10th, 2015. 
  public static void onDemandOpportunityLineItem(List<Opportunity> closedWonOpportunities, List<Opportunity> newList) {
    Set<ID> closingOpptyIDs = new Set<ID>();
    Set<ID> accountIDs = new Set<ID>();

    Set<ID> onDemandOppIDs = new Set<ID>();
    Set<ID> onDemandAccountIDs = new Set<ID>();

    //Query the Opps along with their OpportunityLineItem WHERE On_Demand_Product__c == TRUE
    for (Opportunity opp : [SELECT ID, StageName, AccountID, (SELECT Id, OpportunityId, EDQ_On_Demand_Product__c 
                                                  FROM OpportunityLineItems
                                                  WHERE EDQ_On_Demand_Product__c = true) 
                            FROM Opportunity 
                            WHERE ID IN: closedWonOpportunities]) {
      //Loop through Opps and if they have an OLI attached, store those OLI's.OpportunityId in a set "onDemandOppsList" 
      if (opp.OpportunityLineItems.size() > 0) {
        onDemandOppIDs.add(opp.ID);
        accountIDs.add(opp.AccountID);
      }
    }

    //Query the subset of (Accounts with Contacts WHERE EDQ_On_Demand__c == TRUE) 
    //to which those Opportunities in onDemandOppsList belong to  ==> those opps have an On Demand OLI.
    for (Account acc : [SELECT Id, (SELECT Id, EDQ_On_Demand__c FROM Contacts WHERE EDQ_On_Demand__c = true) 
                        FROM Account 
                        WHERE ID IN: accountIDs]) {
      //Loop through the Accounts & Contacts, and store the Accounts that have 
      //at least 1 On Demand Contact in a set "onDemandAccountsSet" ==> Those Accounts have an OnDemand Contact
      if (acc.Contacts.size() > 0) {
        onDemandAccountIDs.add(acc.ID);
      }
    }
    
    //Adding error if opportunity is ondemand oppty but do not have onDemand account on it
    for (Opportunity opp : newList) {
      if(onDemandOppIDs.contains(opp.ID) && !onDemandAccountIDs.contains(opp.AccountID)) {
        opp.addError(Label.OPPTY_ERR_ONDEMAND_PRODUCT);
      }
    }
  }*/
  
  //===========================================================================
  // T-373692: Opportunity stamping: Channel and Region
  //===========================================================================
  public static void populateSalesTeamChannelAndRegion (List<Opportunity> newList) {
    
    Map<ID, User> userMap = new Map<ID, User>();
    for (Opportunity opp : newList) {
      userMap.put(opp.OwnerId, null);
    }
    
    for (User usr : [SELECT ID, Sales_Team__c, Sales_Sub_Team__c
                     FROM User 
                     WHERE ID IN: userMap.keySet()]) {
      if (userMap.containsKey(usr.ID)) {
        userMap.put(usr.ID, usr);
      }
    }
    //Populating fields
    for (Opportunity opp: newList) {
      if (userMap.containsKey(opp.OwnerId)) {
        if (!String.isBlank(userMap.get(opp.OwnerId).Sales_Team__c)) {
          opp.Sales_Team_Channel__c = userMap.get(opp.OwnerId).Sales_Team__c;
        }
        if (!String.isBlank(userMap.get(opp.OwnerId).Sales_Sub_Team__c)) {
          opp.Sales_Sub_Team_Region__c = userMap.get(opp.OwnerId).Sales_Sub_Team__c;
        }
      }
    }
  }
  
  //===========================================================================
  // Case #580226: Lead -> Campaign Attribution
  //===========================================================================
  public static void resetCampaignForLeadConversions (List<Opportunity> newList) {
    for(Opportunity opp : newList) {
      if (opp.Lead_Update_Campaign__c) {
        opp.Lead_Converted_with_No_Primary_Campaign__c = (opp.Lead_Assigned_Campaign__c != null) ? false : true; 
        opp.CampaignId = opp.Lead_Assigned_Campaign__c;
        opp.Lead_Assigned_Campaign__c = null;
      }
    }
  }
}