/******************************************************************************
 * Appirio, Inc
 * Name: RetentionUtility.cls
 * Description: T-335625: Contains methods that will create Retention_Line_Item__c 
 *                        and can be reused from multiple places in the app
 * Created Date: Nov 20th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * Nov 21st, 2014     Arpita Bose(Appirio)         Updated method updateRetentionLineItem(), createRetentionRecord(), getRetentionRecord()
 *                                                 and created reparentRetentionLineItem()method
 * Nov 28th, 2014     Noopur                       Updated the methods to handle bulk data.
 * Dec 01st, 2014     Arpita Bose                  Updated createRetentionLineItem_New() and updateRetentionLineItem_New() method for T-336536 
 * Dec 02nd, 2014     Naresh Ojha                  Updates code to remove functionanlity implemented for T-336536, as task cancelled and
 *                                                 as per discussion by Nathalie Le Guay
 * Dec 03rd, 2014     Arpita Bose                  Added Constants in place of Strings used
 * Dec 03rd, 2014     Naresh Kr Ojha               T-337137: Revenue Retention: Lost scenario implemented when Oppty closed won updated updateRetentionLineItem_New() and processRetentionLineItems ()
 * Dec 03rd, 2014     Naresh Kr Ojha               T-337154: Revenue Retention: Opp Close/won & non-matched RLI updated updateRetentionLineItem_New() and processRetentionLineItems ()
 * Dec 11th, 2014     Nathalie Le Guay             Comment out unused methods
 * Jan 7th, 2015      Nathalie                     Adding default currency on the Retention__c record
 * May 5th, 2015      Noopur                       Modified the removeRetentionLineItems() to use Opportunity in where clause. Also modified updateRetentionLineOpportunityOwner()
 ******************************************************************************/
public with sharing class RetentionUtility {

  public static Map<String, Retention__c> retentionMap = new Map<String, Retention__c>();
  public static Map<String, Retention_Line_Item__c> retentionLineItemByCallidusRefMap = new Map<String, Retention_Line_Item__c>();
  public static Retention__c retention;
  

  //===========================================================================
  //Creates Retention__c record 
  //===========================================================================
  public static Retention__c createRetentionRecord (OpportunityLineItem oli, String accountId) {
    Retention__c newRetention = new Retention__c();

    newRetention.Account__c = accountId;
    
    // NS- changed End date to start date
    newRetention.Month__c = oli.Start_Date__c.addDays(-1).Month();
    newRetention.Year__c = oli.Start_Date__c.addDays(-1).Year();
    newRetention.Lock__c = false;
    newRetention.CurrencyIsoCode = Constants.CURRENCY_USD;

    retentionMap.put(newRetention.Month__c + '~' + newRetention.Year__c + '~' + newRetention.Account__c, newRetention);

    return newRetention;
  }
  

  //===========================================================================
  //Loading retentions for EndDates and accountIDs with key of month+year+accountId
  //===========================================================================
  public static void queryRetentionRecords(Integer earliestYear, Integer latestYear,
                                           Set<String> accounts) {
    retentionMap = new Map<String, Retention__c>();

    for (Retention__c ret : [SELECT Year__c, Month__c, Id, Account__c, Lock__c,
                                    (SELECT Id, Callidus_Reference__c, Account__c, Available_Margin__c, Duration_in_Month__c, Status__c,Opportunity__c,
                                            Month__c, Year__c, Opportunity_Owner__c, Original_Asset_Id__c, Partner_Account__c, Retention__c
                                     FROM Retention_Line_Items__r)
                             FROM Retention__c 
                             WHERE Year__c >= : earliestYear AND Year__c <= : latestYear 
                             AND Account__c IN: accounts]) {
      if (!retentionMap.containsKey(ret.Month__c + '~' + ret.Year__c + '~' + ret.Account__c)) {
        retentionMap.put(ret.Month__c + '~' + ret.Year__c + '~' + ret.Account__c, ret);
      }
      for (Retention_Line_Item__c rli: ret.Retention_Line_Items__r) {
        if (!retentionLineItemByCallidusRefMap.containsKey(rli.Callidus_Reference__c)) {
          retentionLineItemByCallidusRefMap.put(rli.Callidus_Reference__c, rli);
        }
      }
    }
  }
  
  //===========================================================================
  // Fetch/load Retention record
  //===========================================================================
  public static Retention__c getRetentionRecord (Date endDate, String accountId) {
    retention = new Retention__c();
    if (retentionMap.size() > 0 && retentionMap.containsKey(endDate.Month() + '~' + endDate.Year() + '~' + accountId)) {
      return retentionMap.get(endDate.Month() + '~' + endDate.Year() + '~' + accountId);
    } else {
      return null;
    }

    return retention;
  }

  //===========================================================================
  // Fetch / load Retention Line Item records
  //===========================================================================
  public static Retention_Line_Item__c getRetentionLineItemRecord(OpportunityLineItem oli) {

    if (retentionLineItemByCallidusRefMap.size() == 0 
           || !retentionLineItemByCallidusRefMap.containsKey(oli.OpportunityId + '~' + oli.Part_Number__c)) {
      return null;
    }

    return retentionLineItemByCallidusRefMap.get(oli.OpportunityId + '~' + oli.Part_Number__c);
  }


  //===============================================================================
  // Delete all the RLIs with given Calidus numbers - should not be called in loop
  //===============================================================================
  public static boolean removeRetentionLineItems (Set<Id> oppIds) {

    if (oppIds.size() > 0) {
      try {
        delete [SELECT ID FROM Retention_Line_Item__c WHERE Opportunity__c IN : oppIds];
        for( Id oppIdForDeletion : oppIds) {
        	for (String key: retentionLineItemByCallidusRefMap.keySet()) {
	          if( key.contains(oppIdForDeletion)) {
	            retentionLineItemByCallidusRefMap.remove(key);
	          }
	        }
        }
        
        return true;
      } catch (DMLException ex) {
        apexLogHandler.createLogAndSave('RetentionUtility','removeRetentionLineItems', ex.getStackTraceString(), ex);
        System.debug('\n[RetentionUtility: removeRetentionLineItems]: ['+ex.getMessage()+']]');
        return false;
      }
    }
    return false;
  }


  //===========================================================================
  // Calls removeRetentionLineItems() once the keys are built
  // Keys are OpportunityLineItem.Item_Number__c + '~' + OpportunityLineItem.Quote_Number__c
  // Calls method which will perform the DML Delete operation - should not be called in loop
  //===========================================================================
  /*public static void deleteRetentionLineItems(Map<Id, OpportunityLineItem> oldOLI) {
    Set<String> callidusReferencesIds = new Set<String>();
    for (OpportunityLineItem oli: oldOLI.values()) {
      if (oli.Part_Number__c != null ) {
        callidusReferencesIds.add(oli.OpportunityId + '~' + oli.Part_Number__c);
      }
    }
    if (callidusReferencesIds.size() > 0) {
      removeRetentionLineItems(callidusReferencesIds);
    }
  }*/

  
  //===========================================================================
  // Functionality called by the OpportunityLineItemTriggerHandler
  // T-335658: Automate the creation/Update of RLIs records with OLI updates
  //===========================================================================
  public static void processRetentionLineItems (List<OpportunityLineItem> newList, Map<ID, OpportunityLineItem> oldMap) {

    //List<OpportunityLineItem> oliListToBeUsedForReparenting = new List<OpportunityLineItem>();
    List<OpportunityLineItem> oliListForCreationOfRetention = new List <OpportunityLineItem> ();
    Map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();
    List<Retention_Line_Item__c> retentionLineItemsToCreate = new List<Retention_Line_Item__c>();
    //Map<String, Retention_Line_Item__c> retentionLineItemsToUpdate = new Map<String, Retention_Line_Item__c>(); NLG Dec 11th - not used!
    Set<String> callidusNosToRLIdel = new Set<String>();
    Set<Id> oppIdsForRLIDel = new Set<Id>();
    Integer latestYear;
    Integer earliestYear = latestYear = null;
    Set<String> accountIDs = new Set<String>();
    Set<String> orderTypesForRetention = new Set<String>{Constants.OLI_ORDER_TYPE_PDT,
                                                         Constants.OLI_ORDER_TYPE_UPSELL,
                                                         Constants.OLI_ORDER_TYPE_REPLACEMENT};
    
    for (OpportunityLineItem oli : newList) {
      // Gathering the period of time for which to query the Retention records
      if (oli.Start_Date__c == null) {
        continue;
      }
      if (oli.OpportunityId != null) {
        opportunityMap.put(oli.OpportunityId, null);
      }
      Integer currentYear = oli.Start_Date__c.Year();
      Integer oldCurrentYear = oldMap != null ? oldMap.get(oli.Id).Start_Date__c.Year() : null;

      if (earliestYear == null || currentYear < earliestYear) {
        earliestYear = currentYear;
      }
      if (oldCurrentYear != null && oldCurrentYear < earliestYear) {
        earliestYear = oldCurrentYear;
      }

      if (latestYear == null || currentYear > latestYear) {
        latestYear = currentYear;
      }
      if (oldCurrentYear != null && oldCurrentYear > latestYear) {
        latestYear = oldCurrentYear;
      }
    }
    system.debug('\n[RetentionUtility : processRetentionLineItems] : years to query: ' + earliestYear + '-' + latestYear);
    for (Opportunity oppty : [SELECT ID, OwnerId, AccountId, Type,isClosed,isWon,
                                     (SELECT Id, OpportunityId, AccountToId, IsPrimary From OpportunityPartnersFrom) 
                             FROM Opportunity 
                             WHERE ID IN: opportunityMap.keySet()]) {
      opportunityMap.put(oppty.ID, oppty);
      accountIDs.add(oppty.AccountId);
    }

    //Loading retention/RLI records - will be stored in retentionMap and retentionLineItemByCallidusRefMap
    RetentionUtility.queryRetentionRecords(earliestYear, latestYear, accountIDs);
    
    for (OpportunityLineItem oli : newList) {
      if (oli.Part_Number__c == null || opportunityMap.get(oli.OpportunityId).Type != Constants.OPPTY_TYPE_RENEWAL) {
        continue;
      }

      system.debug('\n[RetentionUtility : processRetentionLineItems] : Looping through: '+ oli.Id + ' key=' +oli.Item_Number__c+'~'+oli.Quote_Number__c);

      // if the oli.Order Type matches select subset, or is updated to be included in the subset
      if (oli.Part_Number__c != null  && ((oldMap == null && !orderTypesForRetention.contains(oli.Order_Type__c)) || 
                                          (oli.Order_Type__c != oldMap.get(oli.ID).Order_Type__c && 
                                            (orderTypesForRetention.contains(oldMap.get(oli.ID).Order_Type__c)) && 
                                            (!orderTypesForRetention.contains(oli.Order_Type__c))))) {
        // Adding opp line item to list of RLI to create
        oliListForCreationOfRetention.add(oli);
        system.debug('\n[RetentionUtility : processRetentionLineItems] : Adding oli.Id to set to create: '+ oli.Id + ' key=' +oli.Item_Number__c+'~'+oli.Quote_Number__c);
      } 
      // OLI's Order Type is changed to a value for which we don't want to track with Retention Line Items
      else if (oldMap != null && oli.Order_Type__c != oldMap.get(oli.ID).Order_Type__c && 
                 (!orderTypesForRetention.contains(oldMap.get(oli.ID).Order_Type__c)) && 
                 (orderTypesForRetention.contains(oli.Order_Type__c))) {
         if (!String.isBlank(oli.Part_Number__c)) {
           callidusNosToRLIdel.add(oli.OpportunityId + '~' + oli.Part_Number__c);
           oppIdsForRLIDel.add(oli.OpportunityId);
         }
      } 
    }
    system.debug('\n[RetentionUtility : processRetentionLineItems] : oliListForCreationOfRetention : ' + oliListForCreationOfRetention);
    retentionLineItemsToCreate.addAll(RetentionUtility.createRetentionLineItem_New(oliListForCreationOfRetention, opportunityMap ));
      
    
    try {
      //Remove RLIs with given set of calidus numbers from OLIs, it calls delete DML
      if (oppIdsForRLIDel.size() > 0) {
        RetentionUtility.removeRetentionLineItems(oppIdsForRLIDel);
      }
    
      //Inserts new RLIs
      if (retentionLineItemsToCreate.size() > 0) {
        insert retentionLineItemsToCreate;
      }
    } catch (DMLException e) {
      System.debug('\n[OpportunityLineItemTriggerHandler: processRetentionLineItems: DMLException]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('OpportunityLineItemTriggerHandler','processRetentionLineItems: DMLException', e.getStackTraceString(), e); 

      for (Integer i = 0; i < e.getNumDml(); i++) {
        newList.get(0).addError(e.getDmlMessage(i));
      }
    }
    
  }
  

  //===========================================================================
  // Functionality called by the OpportunityTriggerHandler
  //===========================================================================
  public static void processOppForRetention ( List<Opportunity> newOppList, map<Id,Opportunity> oldMap ) {
    Map<String, Opportunity> newOpps = new Map<String, Opportunity>();
    for ( Opportunity opp : [SELECT Id, AccountId, Contract_End_Date__c, OwnerId, 
                                    StageName, Type,isClosed,isWon,Contract_Start_Date__c,
                                    (SELECT Id, isPrimary, AccountToId FROM OpportunityPartnersFrom),
                                    (SELECT Id, Available_Margin__c, Callidus_Reference__c, Actual_Margin__c, 
                                            Opportunity__c, Lost_Margin__c 
                                     FROM Retention_Line_Items__r)
                             FROM Opportunity
                             WHERE Id IN: newOppList]) {
      newOpps.put( opp.Id , opp );
    }
    Set<String> accounts = new Set<String>();
    Date earliestContractYear ;
    Date latestContractYear;
    Map<Id, Boolean> oppClosedWonMap = new Map<Id, Boolean>();
    Map<Id, Boolean> oppClosedLostMap = new Map<Id, Boolean>();
    set<Id> changedFromCredited = new set<Id>();
    List<OpportunityLineItem> oliListForCreation = new List<OpportunityLineItem>();
    List<OpportunityLineItem> oliListForUpdate = new List<OpportunityLineItem>();
    
    try {

      for ( Opportunity opp : newOpps.values() ) {
        if ( opp.Contract_Start_Date__c != null && (opp.Contract_Start_Date__c > latestContractYear || latestContractYear == null )) {
          latestContractYear = opp.Contract_Start_Date__c; 
        }
        else if ( opp.Contract_Start_Date__c != null && (opp.Contract_Start_Date__c < earliestContractYear || earliestContractYear == null ) ){
          earliestContractYear = opp.Contract_Start_Date__c; 
        }
        
        accounts.add(opp.AccountId) ;
        
        if ( oldMap != null &&
             opp.Type != Constants.ORDER_TYPE_CREDITED && oldMap.get(opp.ID).Type == Constants.ORDER_TYPE_CREDITED ) {
          system.debug('\n[RetentionUtility : processOppForRetention] : Change from credited to other: ' + opp.Id);
          changedFromCredited.add(opp.Id);
        }
        else if ( oldMap != null && oldMap.get(opp.ID).IsClosed != opp.IsClosed && opp.IsClosed == true && opp.IsWon == true) {
          oppClosedWonMap.put(opp.Id, true);
        }
        else {
          oppClosedWonMap.put(opp.Id, false);
        }
        //For closed lost
        if (oldMap != null && oldMap.get(opp.ID).IsClosed != opp.IsClosed && opp.IsClosed == true && opp.IsWon != true) {
            oppClosedLostMap.put(opp.ID, true);
        }
      }
      Integer earliestYear = earliestContractYear != null ? earliestContractYear.year(): null;
      Integer latestYear = latestContractYear != null ? latestContractYear.year() : null;
      RetentionUtility.queryRetentionRecords(earliestYear, latestYear, accounts);

      // Set of Order Type for which we should not create Retention Line Items
      set<String> orderTypeThatDoNotApply = new set<String>{Constants.OLI_ORDER_TYPE_PDT,
                                                            Constants.OLI_ORDER_TYPE_UPSELL,
                                                            Constants.OLI_ORDER_TYPE_REPLACEMENT};
      Map<String, OpportunityLineItem> oliItemNumbersMap = new Map<String, OpportunityLineItem> ();
      set<String> callidusRefSet = new set<String>(); // Set to gather the Callidus references
      List<Retention_Line_Item__c> rliToUpsert = new List<Retention_Line_Item__c>();

      List<OpportunityLineItem> oliList = [Select o.Start_Date__c, o.OpportunityId, o.Id,o.Part_Number__c,
                                                  o.End_Date__c, o.EDQ_Margin__c, o.Order_Type__c,o.Quote_Number__c,
                                                  o.Opportunity.Type, o.Item_Number__c, o.Original_Asset_ID__c, CurrencyISOCode
                                           From OpportunityLineItem o
                                           Where OpportunityId IN :newOpps.values()];
      
      // Populating maps
      for ( OpportunityLineItem oli : oliList) {
        if ( orderTypeThatDoNotApply.contains(oli.Order_Type__c) || oli.Opportunity.Type == Constants.OPPTY_TYPE_CREDITED ) {
          continue;
        }
        oliItemNumbersMap.put(oli.OpportunityId + '~' + oli.Part_Number__c, oli);
      }

      // Populating maps
      system.debug('\n[RetentionUtility : processOppForRetention] : MAP: '+ oliItemNumbersMap.keySet());
      // NS - modified the query to remove the non-selective query error.
      for ( Retention_Line_Item__c rli : [Select Id, Callidus_Reference__c 
                                          From Retention_Line_Item__c 
                                          Where Opportunity__c IN: newOpps.values()
                                          AND Callidus_Reference__c  IN :oliItemNumbersMap.keyset()]) {
        callidusRefSet.add(rli.Callidus_Reference__c);
      }
      
      for ( OpportunityLineItem oli : oliItemNumbersMap.values()) {
        Retention_Line_Item__c rli ;
        system.debug('\n[RetentionUtility : processOppForRetention] : oli.Id = ' + oli.Id + ' key = ' + oli.Item_Number__c+'~'+oli.Quote_Number__c + '\nSet: '+ callidusRefSet);
        if ( callidusRefSet.contains(oli.OpportunityId + '~' + oli.Part_Number__c) && !changedFromCredited.contains(oli.OpportunityId) ) {
          
          oliListForUpdate.add(oli);
        } else if (oppClosedLostMap.containsKey(oli.OpportunityId) && oppClosedLostMap.get(oli.OpportunityId) == true) {
            //Added oli to processed for closed opportunity
            oliListForUpdate.add(oli);
        }
        else {
          oliListForCreation.add(oli);
          system.debug('\n[RetentionUtility : processOppForRetention] : Adding OLI: ' + oli.Id);
        }
      }
      if (oliListForCreation.size() > 0) {
        rliToUpsert.addAll(RetentionUtility.createRetentionLineItem_New(oliListForCreation, newOpps));
      }
      
      if (oliListForUpdate.size() > 0) {
        rliToUpsert.addAll(RetentionUtility.updateRetentionLineItem_New(oliListForUpdate, newOpps , oldMap, oppClosedWonMap));
      }

      if ( !rliToUpsert.isEmpty() ) {
        upsert rliToUpsert;
      }
    }
    catch ( Exception e ) {
      system.debug('[RetentionUtility: processOppForRetention] Exception: ' + e.getMessage());
      ApexLogHandler.createLogAndSave('RetentionUtility','processOppForRetention', e.getStackTraceString(), e);
    }
  }
  
  
  //=========================================================================
  // Method to Create Retention Line Item
  //=========================================================================
  public static List<Retention_Line_Item__c> createRetentionLineItem_New ( List<OpportunityLineItem> oliList, Map<String,Opportunity> OpportunityMap) {
    
    List<Retention__c> retentionListToInsert = new List<Retention__c>();
    List<Retention__c> retentionList = new List<Retention__c>();
    List<Retention_Line_Item__c> rliList = new List<Retention_Line_Item__c>();
    Map<String, Retention__c> oliRetentionMap = new Map<String, Retention__c>();
    
    for ( OpportunityLineItem oli : oliList) {
      Opportunity oppty = OpportunityMap.get(oli.OpportunityId);
      system.debug('\n[RetentionUtility : createRetentionLineItem_New] : ~~ OLI ~~: ' + oli.Id);
      if ( oli.Part_Number__c == null || oppty.Type != Constants.OPPTY_TYPE_RENEWAL  ) { 
        continue;
      }
      else {
        retention = getRetentionRecord(oli.Start_Date__c, opportunityMap.get(oli.OpportunityId).AccountId);
        system.debug('\n[RetentionUtility : createRetentionLineItem_New] : ~~ found Retention ~~: ' + retention);
      
        if (retention == null) {
          retention = createRetentionRecord(oli, opportunityMap.get(oli.OpportunityId).AccountId);
          retentionListToInsert.add(retention);
          system.debug('\n[RetentionUtility : createRetentionLineItem_New] : ~~ created Retention ~~: ' + retention);
        }
        retentionList.add(retention);
        oliRetentionMap.put(oli.OpportunityId,retention);
      }
    }
    if ( !retentionListToInsert.isEmpty() ) {
      insert retentionListToInsert;
    }
    //for (  Retention__c retObj : retentionList  ) {
    for ( OpportunityLineItem oli : oliList) {
        
     // OpportunityLineItem oli = oliRetentionMap.get(retObj.Month__c + '~' + retObj.Year__c + '~' + retObj.Account__c);
      Opportunity oppty = OpportunityMap.get(oli.OpportunityId);
      retention = oliRetentionMap.get(oli.OpportunityId);
      
      if ( retention == null ) {
        continue;
      }
      
      Retention_Line_Item__c newRetentionLine   = new Retention_Line_Item__c();
      
      //create RLI for for renewal opp 
      newRetentionLine.Type__c                  = Constants.RLI_TYPE_STANDARD;
      newRetentionLine.Duration_in_Month__c     = oli.Start_Date__c.daysBetween(oli.End_Date__c)/30;
      newRetentionLine.Available_Margin__c      = oli.EDQ_Margin__c;
      newRetentionLine.CurrencyIsoCode          = oli.CurrencyIsoCode;//As per I-142616 
      newRetentionLine.Account__c               = oppty.AccountId;
      //NS- Added to populate Opportunity 
      newRetentionLine.Opportunity__c           = oppty.Id;
      newRetentionLine.Callidus_Reference__c    = oli.OpportunityId + '~' + oli.Part_Number__c;
      
      newRetentionLine.Month__c                 = oli.Start_Date__c.addDays(-1).month();
      newRetentionLine.Opportunity_Owner__c     = oppty.OwnerId;
      newRetentionLine.Original_Asset_Id__c     = oli.Original_Asset_ID__c;
      for (Partner p : oppty.Partners) {
        if (p.isPrimary) {
          newRetentionLine.Partner_Account__c = p.AccountToId;
        }
      }

      system.debug('---retention--->>>'+retention);

      newRetentionLine.Exclude_from_Retention_Calculations__c = retention!=null?retention.Lock__c:false;
      newRetentionLine.Retention__c = retention.ID;
      newRetentionLine.Status__c = Constants.RLI_STATUS_UNPAID;
      newRetentionLine.Year__c = oli.Start_Date__c.addDays(-1).year();

      if ( newRetentionLine.Actual_Margin__c == null ) {
        newRetentionLine.Lost_Margin__c = 0;
      }

      if (oppty.isClosed && !oppty.IsWon && (newRetentionLine.Actual_Margin__c == null || newRetentionLine.Actual_Margin__c == 0)){
         newRetentionLine.Status__c = Constants.RLI_STATUS_LOST;
         newRetentionLine.Lost_Margin__c = newRetentionLine.Available_Margin__c ;
      }
      else if ( oppty.isClosed && oppty.isWon && newRetentionLine.Available_Margin__c != null && 
                     newRetentionLine.Actual_Margin__c != null && 
                     newRetentionLine.Available_Margin__c - newRetentionLine.Actual_Margin__c > 0) {
         newRetentionLine.Lost_Margin__c = newRetentionLine.Available_Margin__c - newRetentionLine.Actual_Margin__c;
      }

      retentionLineItemByCallidusRefMap.put(newRetentionLine.Callidus_Reference__c, newRetentionLine);
      system.debug('\n[RetentionUtility : createRetentionLineItem_New] : adding entry: '+ newRetentionLine.Callidus_Reference__c);
      system.debug('\n[RetentionUtility : createRetentionLineItem_New] : RLI Created: '+ newRetentionLine);
      rliList.add(newRetentionLine);
    }
    return rliList;
  }

  //===========================================================================
  // Update Retention Line Item record
  //===========================================================================
  public static List<Retention_Line_Item__c> updateRetentionLineItem_New (List<OpportunityLineItem> oliList, Map<String, Opportunity> opportunityMap, 
                                                                  Map<Id, Opportunity> oldMap,  Map<Id, Boolean> isCloseWonMap) {
                                                                     
      List<Retention_Line_Item__c> rliList = new List<Retention_Line_Item__c>();
      List<Retention__c> retentionListToInsert = new List<Retention__c>();
      List<Retention__c> retentionList = new List<Retention__c>();
      List<OpportunityLineItem> oliForCreationOfRetentionLineItem = new List<OpportunityLineItem>();

      Map<ID, List<OpportunityLineItem>> opptyID_OliListMap = new Map<ID, List<OpportunityLineItem>>();
      Map<String, OpportunityLineItem> oliRetentionMap = new Map<String, OpportunityLineItem>();

      
      for ( OpportunityLineItem oli : oliList) {
        Opportunity oppty = OpportunityMap.get(oli.OpportunityId);

        if ( oli.Part_Number__c == null || oppty.Type != Constants.OPPTY_TYPE_RENEWAL  ) {
          continue;
        }
        else {
          Retention_Line_Item__c rliToUpdate = getRetentionLineItemRecord(oli);
          if (rliToUpdate == null) {
            oliForCreationOfRetentionLineItem.add(oli);// = createRetentionLineItem(oli, oppty);
          }
          else {
            rliList.add(rliToUpdate);
          }
          oliRetentionMap.put(oli.OpportunityId+'~'+oli.Part_Number__c,oli);
        }

        if (!opptyID_OliListMap.containsKey(oli.OpportunityId)) {
          opptyID_OliListMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
        }
        opptyID_OliListMap.get(oli.OpportunityId).add(oli);
      }
      if ( !oliForCreationOfRetentionLineItem.isEmpty() ) {
        rliList.addAll(createRetentionLineItem_New ( oliForCreationOfRetentionLineItem,  OpportunityMap));
      }

      for ( Retention_Line_Item__c rliToUpdate : rliList) {
        Opportunity oppty = OpportunityMap.get(rliToUpdate.Opportunity__c);
        OpportunityLineItem oli = oliRetentionMap.get(rliToUpdate.Callidus_Reference__c);

        if (isCloseWonMap.get(oppty.Id)) {
              rliToUpdate.Actual_Margin__c = oli.EDQ_Margin__c;
              rliToUpdate.Status__c = Constants.RLI_STATUS_PAID;

            } else {
              //rliToUpdate.Available_Margin__c = oli.EDQ_Margin__c;
              rliToUpdate.Status__c = Constants.RLI_STATUS_UNPAID;
              rliToUpdate.Duration_in_Month__c = oli.Start_Date__c.daysBetween(oli.End_Date__c)/30;
            }

            rliToUpdate.Month__c = oli.Start_Date__c.addDays(-1).month();
            rliToUpdate.Opportunity_Owner__c = oppty.OwnerId;
            rliToUpdate.Opportunity__c = oppty.Id;
            for (Partner p : oppty.Partners) {
              if (p.isPrimary) {
                rliToUpdate.Partner_Account__c = p.AccountToId;
              }
            }
            rliToUpdate.Year__c = oli.Start_Date__c.addDays(-1).year();
            if ( rliToUpdate.Actual_Margin__c == null ) {
              rliToUpdate.Lost_Margin__c = 0;
            }
            if (oppty.isClosed && !oppty.IsWon && (rliToUpdate.Actual_Margin__c == null || rliToUpdate.Actual_Margin__c == 0)) {
               rliToUpdate.Status__c = Constants.RLI_STATUS_LOST;
               rliToUpdate.Lost_Margin__c = rliToUpdate.Available_Margin__c ;
               rliToUpdate.Actual_Margin__c = 0;
            }
            else if ( oppty.isClosed && oppty.isWon && rliToUpdate.Available_Margin__c - rliToUpdate.Actual_Margin__c > 0) {
               rliToUpdate.Lost_Margin__c = rliToUpdate.Available_Margin__c - rliToUpdate.Actual_Margin__c;
            }
      }

      //As per Task T-337154 : If RLI has blank Callidus number or do not match with OLI, should be lost
      for (ID opptyID : opportunityMap.keySet()) {
        
        //When oppty get closed won
        if (opportunityMap.get(opptyID).IsClosed != oldMap.get(opptyID).IsClosed && 
               opportunityMap.get(opptyID).IsClosed == true && opportunityMap.get(opptyID).IsWon == true) {
          for (Retention_Line_Item__c rliToUpdate : opportunityMap.get(opptyID).Retention_Line_Items__r) {
            if (rliToUpdate.Opportunity__c == opptyID) {
              Boolean isMatched = false;
              for (OpportunityLineItem oli : opptyID_OliListMap.get(opptyID)) {
                if (!String.isBlank(oli.Part_Number__c) && rliToUpdate.Callidus_Reference__c == opptyID+'~'+oli.Part_Number__c) {
                  isMatched = true;
                }
              }
              //If no oli is matched with callidus number with its part number, make it lost.
              if (!isMatched) {
                rliToUpdate.Status__c = Constants.RLI_STATUS_LOST;
                rliToUpdate.Actual_Margin__c = 0;
                rliToUpdate.Lost_Margin__c = rliToUpdate.Available_Margin__c;
                rliList.add(rliToUpdate);
              }
            }
          }
        }
      }
      return rliList;
   }

  //===========================================================================
  // Method to update the Opportunity_Owner__c field on RLI when Opp Owner is changed.
  //===========================================================================
  public static void updateRetentionLineOpportunityOwner ( List<Opportunity> updatedOpps) {
    
    Map<Id,Id> retentionOwnerMap = new Map<Id,Id>();
    for ( Opportunity opp : updatedOpps ) {
    	retentionOwnerMap.put(opp.Id, opp.OwnerId);
    }
    List<Retention_Line_Item__c> RLIToUpdate = new List<Retention_Line_Item__c>();
  /*  for ( OpportunityLineItem oli : [Select o.Start_Date__c, o.OpportunityId, o.Id,Opportunity.OwnerId,
                                            o.End_Date__c, o.EDQ_Margin__c, o.Order_Type__c,o.Quote_Number__c,
                                            o.Opportunity.Type, o.Item_Number__c, o.Original_Asset_ID__c,
                                            o.Part_Number__c
                                     From OpportunityLineItem o
                                     Where OpportunityId IN :updatedOpps]) {
      String callidusRef = oli.OpportunityId + '~' + oli.Part_Number__c;
      retentionOwnerMap.put(callidusRef, oli.Opportunity.OwnerId);
    }*/

    for ( Retention_Line_Item__c rli : [Select Id,Opportunity_Owner__c,Callidus_Reference__c, Opportunity__c
                                        From Retention_Line_Item__c
                                        Where Opportunity__c IN :retentionOwnerMap.keySet()]) {
      //if ( retentionOwnerMap != null && retentionOwnerMap.containsKey(rli.Callidus_Reference__c) && 
      // rli.Opportunity_Owner__c != retentionOwnerMap.get(rli.Callidus_Reference__c) ) {
        rli.Opportunity_Owner__c = retentionOwnerMap.get(rli.Opportunity__c);
        RLIToUpdate.add(rli);
     // }
    }

    if ( !RLIToUpdate.isEmpty() ) {
      update RLIToUpdate;    
    } 
  }

}