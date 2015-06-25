/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTriggerHandler
 * Description:
 * Created Date: Nov 19th, 2013
 * Created By: Mohammed Irfan (Appirio)
 *
 * Date Modified      Modified By                  Description of the update
 * Dec 07th, 2013     MIrfan(Appirio)
 * Jan 30th, 2014     Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 12th, 2014     Nathalie Le Guay (Appirio)   T-249339: Remove Auto_Create_Renewal_on_Close_Win__c
 *                                                 T-249341: add checkOwnerAllowed()
 * Feb 12th, 2014     Sadar Yacob                  Set the Contract Start and End dates for the Renewal Opty
 * Feb 13th, 2014     Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Feb 20th, 2014     Nathalie Le Guay (Appirio)   T-251370: Remove Has_Competitor__c references (deleting field)
 * Feb 21st, 2014     Naresh Kr Ojha (Appirio)     T-251412: Commented checkOwnerAllowed() and implemented checkAccessOnAccountForUser
 *                                                 in OpportunityTriggerHelper class
 * Feb 24th, 2014     Nathalie Le Guay (Appirio)   Removed call to Opportunity_ExitCriteriaUtility.validatePreviousStagesForOppties()
 * Feb 25th, 2014     Nathalie Le Guay             Adding populateStartingStage()
 * Feb 26th, 2014     Nathalie Le Guay (Appirio)   Removing references to Selection_confirmed__c and Signed_Contract__c
 *                                                 and Task_Quote_Delivered__c
 * Feb 28th, 2014     Nathalie Le Guay             Update hasCriteriaMet() to return false as Renewals are on hold
 * Mar 04th, 2014     Arpita Bose (Appirio)        T-243282: Added constants in place of String
 * Mar 5th, 2014      Nathalie Le Guay (Appirio)   Added call to OpportunityTriggerHelper.deleteOrderIfOppIsReopened()
 * Mar 10th, 2014     Nathalie Le Guay             T-257853: createOppContactRoles()
 * Mar 11th, 2014     Naresh Kr Ojha               T-257871 - added call to OppTriggerHelper.multiCurrencyFieldUpdate()
 * Mar 13th, 2014     Nathalie Le Guay             T-257871 - call multiCurrencyFieldUpdate from before insert
 * Mar 18th, 2014     Naresh Kr Ojha               T-260145: Renamed deleteOrderIfOppIsReopened to deleteOrderAndOppIfOppIsReopened
 * Mar 18th, 2014     Megha Agarwal (Appirio JDC)  T-253868: Validate Service Dates and update OLI's Service Dates
                                                   validateServiceDates() , populateServiceDatesOnOLI()
 * Mar 20th, 2014     Naresh Kr Ojha               updated method validateServiceDates() to check Oppty.Service dates not null.
 * Apr 08th, 2014     Arpita Bose                  T-269372: Added addError()in try-catch block
 * Apr 10th, 2014     Naresh Kr Ojha               T-258164: Added checkOpptyDates() which checks for key dates of of alignment w/ ContractStartDate & CloseDate
 * Apr 22nd, 2014     Nathalie Le Guay             Commenting BU Relationship code
 * May 01st, 2014     Arpita Bose                  Updated catch(Exception) to catch(DMLException) to use getDMLException
 * May 01st, 2014     Bharti Mehta(Appirio JDC)    T-273787: Update related  Opp plans records
 * May 14th, 2014     Sadar yacob ( Experian)      Case # 1409 : Make the Opty Contact Role Primary
 * May 16th, 2014     Nathalie Le Guay             I-114865 - Added additional validation around opp.Originating_Contact_Id__c to prevent 'invalid id' errors
 * Jul 18th, 2014     Arpita Bose (Appirio)        I-120989 :  Added a method synchCurrencyISOCodes()
 * Aug 29th, 2014     Arpita Bose                  T-313548: Added methods declared in the interface OpportunityInterface and have change the signature of the methods
                                                   beforeInsert(), afterInsert(), beforeUpdate(), afterUpdate()
 * Sep 04th, 2014     Naresh Kr Ojha               T-317502: create moveTaskToOpptyWhenCreatedFromContact ()
 * Sep 9, 2014        James Weatherall             Case #6875: createOppTeamMembers to add Strat Account Managers to Opp Team
 * Sep 11th,12th 2014 Arpita Bose                  T-318379: Method populateOriginalOppty() and calculateNoOfFollowUpOppty() has been commented as the Task has been blocked
 * Sep 10, 2014       Nathalie Le Guay             I-130073 - Commenting createOppContactRoles() as this is done by the 'conId' parameter
 * Sep 11, 2014       Nathalie Le Guay             T-317502: Cancelled - removing moveTaskToOpptyWhenCreatedFromContact()
 * Sep 15th, 2014     Naresh Kr Ojha               T-319088: On Demand Opportunity Line Item: Opp Trigger added method: onDemandOpportunityLineItem()
 *                                                 Added Label.OPPTY_ERR_ONDEMAND_PRODUCT
 * Sep 17th, 2014     Arpita Bose                  T-319512: added method checkOpptyContactRoleOnClosedWon() in beforeUpdate
 * Sep 17th, 2014     Tyaga Pati                   Case#00004517: Opp Team Owner Change ==> Auto add to account team
 * Sep 18th, 2014     Arpita Bose                  S-254060: Code commented as per the chatter
 * Sep 18th, 2014     Arpita Bose                  T-320132: Added method checkOpptyChannelTypeOnClosedWon()
 * Sep 19th, 2014     Arpita Bose                  T-320157: Added call of OpportunityTriggerHandler_EDQ.populateInvoiceToEndUser_OnClosedWon()
 * Sep 23rd, 2014     Arpita Bose                  T-321347: Added method createOppContactRoles_RenewalOpps()
 * Sep 23rd, 2014     Arpita Bose                  Removed the method moveTaskToOpptyWhenCreatedFromContact()
 * Sep 24th, 2014     Arpita Bose                  Move the method createOppContactRoles_RenewalOpps() to OpportunityTriggerHandler_EDQ.cls
 * Sep 24th, 2014     Noopur                       T-321619: Added the method fetchClosedWonRecords() and used it where we were checking for closed won opportunities
 * Sep 26th, 2014     Arpita Bose                  T-322920: Removed method 'checkOpptyContactRoleOnClosedWon()' and have added a call
 *                                                 to method OpportunityTriggerHandler_EDQ.validateOnePurchaseLedger_OpptyConRole()
 * Sep 26th, 2014     Arpita Bose                  T-322814: Added call to OpportunityTriggerHandler_EDQ.validateOpptyContactRoleOnClosedWon()
 * Sep 29th, 2014     Nathalie Le Guay             Code cleanup: removed BUHierarchy related methods as well as T-318379-specific methods (postponed to Phase 3)
 * Sep 30th, 2014     Noopur                       T-321616 : Code refactoring. Added the method createOppLineItemsForRenewal()
 * Oct 8th, 2014      Nathalie Le Guay             Populating oli.Order_Type__c
 * Oct 08th, 2014     Noopur                       T-323348 : updates for Polymorphism designs. Instantiated the interface and used it instead of caling the static methods of classes.
 * Oct 10, 2014       James Weatherall             Case #8991 Uncommented updateOpportunityPlans() code in order to update Opp Plan fields
 * Oct 13, 2014       Nathalie                     Cleanup/refactoring: Adding hasCheckedExitCriteria
 * Oct 17, 2014       Pallavi                      T-326540: Refactoring: Improve Opp Trigger
 * Oct 20th, 2014     Noopur                       Commented method createOppLineItemsForRenewal() for T-326528
 * Oct 22nd, 2014     Richard Joseph               To Call CPQ service on close of Opty and change the status of Quote associated with the Opty.
 * Nov 07th, 2014     Noopur                       I-138030: Remove logic from checkOpptyChannelTypeOnClosedWon(), as it is EDQ-specific
 * Nov 07th, 2014     Nathalie Le Guay             Adding stamping of Status = 'Cancelled' in reopenPreInvoiceOpp()
 * Nov 14th, 2014     Noopur                       I-138684: Added validateProductsData()
 * Feb 5th, 2015      Paul Kissick                 Case #542894: Modified createOppTeamMembers method, to check for Active Users from Account Team Members
 * Feb 23rd, 2014     Arpita Bose                  T-364931: Added method validateOpptyConAccAddressOnClosedWon_NonFreeTrial()
 * Feb 25th, 2015     Arpita Bose                  T-364941: Added method validateOpptyAccAddressOnClosedWon_NonFreeTrial()
 * Feb 19th, 2015     James Weatherall             Case #562850: Modified reopenPostInvoiceOpp method to update the Opp Record Type to Standard after Clone
 * Mar 03rd, 2015     Arpita Bose                  updated method validateOpptyConAddressOnClosedWon_NonFreeTrial for Registered Address
 *                                                 and removed method validateOpptyAccAddressOnClosedWon_NonFreeTrial()for T-364941
 * Mar 04th, 2015     Arpita Bose                  T-366560: Added method validateOpptyAccWithSaasContact()
 * Mar 13th, 2015     Arpita Bose                  T-368846: Added method getOppConRoleRecord() and updated methods- 1) validateOpptyConAddressOnClosedWon_NonFreeTrial()
                                                             2) validateOpptyContactRoleOnClosedWon()
 * Mar 20th, 2015     Noopur                       T-371756: modified getOppConRoleRecord(), to check for the list size.
 * Mar 26th, 2015     Naresh                       T-373692: added call of method OpportunityTriggerHelper.populateSalesTeamChannelAndRegion()
 * Mar 26th, 2015     Arpita                       T-372609: Opp close date
 * Apr 2nd, 2015      Noopur                       T-374242: Added the method updateRelatedAccountSegments();
 * Apr 02nd, 2015     Naresh                       T-374272: Worked on task to populate segment fields on opportunity
 * Apr 07th, 2015     Noopur                       Moved the method updateOppRelatedAccountSegments() to OpportunityTrigger_AccountSegmentation
 * Apr 13th, 2015     Suminder Singh               T-377400: after delete method afterDelete() for the account segments recalculation on Opp delete
 * Apr 15th, 2015     Tyaga Pati                   Case #00610653 Add Code to Delete Registrations on Asset before Deleting Assets on Reopen of New to New Optys.
 * Apr 27th, 2015     Nathalie Le Guay             I-156880: Add hasRunAccountSegmentation to prevent future method to be added twice (and code to run twice)
 * May 5th, 2015      Noopur                       Modified to pass Opportunity Id to removeRetentionLineItems() for deletion of RetentionLineItems

 * May 20th, 2015     Paul Kissick                 Case #580226: resetCampaignForLeadConversions added for fixing primary campaign source
 * May 27th, 2015     Paul Kissick                 Case #610130: Minor query change to reopening opps, and crediting orders to only to 'Live' orders.
 * Jun 10th, 2015     Naresh Kr Ojha               T-409411: added populateOpportunityPlansForNewOppties() to remove two soql on Opportunity_Plan__c as per task.
 * Jun 06th, 2015     Naresh Kr Ojha               T-409412: Commented queries as it has two soql (nested) on parent. Used inner query instead. Method: onDemandOpportunityLineItem()
 =====================================================================*/
 
public  virtual class OpportunityTriggerHandler implements OpportunityInterface {

    public static Boolean isRunningOpportunityTrigger = false;//T-337155
    public static Boolean orignatedOpptyCalculated = false;
    //MIrfan. 07Dec13. TriggerStateVariable to stop creating duplicate Renewl Opps.
    public static boolean hasRenewalOpportunityCheckFinshed = false;
    public static boolean UpdateFromOppLI = false; // T-253868
    public static boolean IsOppPlanSyncInProg = false; // T-253868
    public static OpportunityInterface opportunityClass; // T-323348

    public static Boolean hasRunReopenPostInvoice = false;
    public static Boolean hasCheckedExitCriteria = false;
    public static Boolean hasRunDateValidations = false;
    public static Boolean hasRunCloseWonMethods = false;
    public static Boolean hasRunMultiCurrencyUpdate = false;
    public static Boolean hasRunAccountSegmentation = false;
    public static Boolean isAfterUpdateTriggerExecuted = false;
    public static Boolean isSynchOppDateFutureCalled = false;
    public static List<OpportunityContactRole> lstOppConRole; //T-368846




    public static Map<Id,List<OpportunityLineItem>> oppOLIMapForClosedWon = new Map<Id,List<OpportunityLineItem>>();
    
    public static Boolean isBeforeUpdateTriggerExecuted = false;
    public static Boolean isAfterInsertTriggerExecuted = false;
    public static Boolean isBeforeInsertTriggerExecuted = false;
    
    public static String groupName;

    static {
      if (String.isEmpty(groupName)) {
        groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());
        System.debug('--constructor 1called---');
        opportunityClass = newClassInstance();
        System.debug('--constructor 2called---');
      }
    }

    //Constructor
    public OpportunityTriggerHandler () {

    }


  //===========================================================================
  // BEFORE INSERT 
  //===========================================================================
  public static void beforeInsert (List<Opportunity> newList) {
       
       if(isBeforeInsertTriggerExecuted) {
         return;
       }
         isBeforeInsertTriggerExecuted = true;
       
      //checkOwnerAllowed(newList);
      OpportunityTrigger_AccountSegmentation.populateSegmentsOnOppty(newList, null);
      //AccountSegmentationUtility.populateSegmentsOnOppty(newList);
      OpportunityTriggerHelper.populateSalesTeamChannelAndRegion(newList);//As per T-373692
      OpportunityTriggerHelper.checkAccessOnAccountForUser(newList);
      OpportunityTrigger_DatesUtility.populateStartingStage(newList, null);
      //T-257871: Multi-Currency Dashboard: Opp Trigger
      system.debug('***beforeInsert***newList>>>>' +newList);
      OpportunityTriggerHelper.multiCurrencyFieldUpdate(newList, null);
      OpportunityTriggerHelper.resetCampaignForLeadConversions(newList);
  }

  //===========================================================================
  // AFTER INSERT 
  //===========================================================================
   public static void afterInsert (Map<ID, Opportunity> newMap) {
      
      
      
      if(isAfterInsertTriggerExecuted) {
        return;
      }
      isAfterInsertTriggerExecuted = true;
        
      //addContacttoOpportunity(newMap.keyset()); // Case #583716
       
     // String groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId()); //EDQ specific

      // createOppContactRoles(newMap); NLG Sep 10th, 2014 - Removing method because done by the conId parameter
      //nojha: Sep 04, 2014 for task T-317502
      moveOriginatingTaskToNewOppty(newMap.values());

      // Case 6875 - Added by James Weatherall. 09092014.
      createOppTeamMembers(newMap);

      // T-321347
      opportunityClass.createOppContactRoles_RenewalOpps(newMap);

      // T-321616
      opportunityClass.createOppLineItemsForRenewal(newMap.values());

      // T-335634 - Retention calculations
      List<Opportunity> checkForRetention = new List<Opportunity> ();
      for ( Opportunity opp : newMap.values()) {
        if ( opp.Type == Constants.OPPTY_TYPE_RENEWAL ) {
          checkForRetention.add(opp);
        }
      }
      if ( !checkForRetention.isEmpty() ) {
        RetentionUtility.processOppForRetention( checkForRetention , null);
      }
      if (!hasRunAccountSegmentation) {
        OpportunityTrigger_AccountSegmentation.updateOppRelatedAccountSegments(null, newMap);
        hasRunAccountSegmentation = true;
      }
   }

  //===========================================================================
  // BEFORE UPDATE 
  //===========================================================================
   public static void beforeUpdate (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
     
       if(isBeforeUpdateTriggerExecuted) {
        return;
      }
        isBeforeUpdateTriggerExecuted = true;
      
      //String groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId()); //EDQ specific
      // OpportunityTriggerHelper.checkAccessOnAccountForUser(newMap.values()); NLG - not necessary on update per S-185995
      
      OpportunityTrigger_DatesUtility.populateStartingStage(newMap.values(), oldMap);
      if (!hasCheckedExitCriteria && !Opportunity_ExitCriteriaUtility.getOpportunitiesExitCriteriaNotMet(newMap, oldMap)) {
        return;
      }

      // T-253868 - validate Service Dates
      if (!hasRunDateValidations) {
        OpportunityTrigger_DatesUtility.validateServiceDates(newMap, oldMap);
        hasRunDateValidations = true;
      }

      //gather the closed won opportunities
      List<Opportunity> closedWonOpportunities = new List<Opportunity>();
      closedWonOpportunities = fetchClosedWonRecords(oldMap, newMap.values());
      //T-364931
      opportunityClass.validateOpptyConAddressOnClosedWon_NonFreeTrial(closedWonOpportunities);

      //T-366560
      opportunityClass.validateOpptyAccWithSaasContact(closedWonOpportunities);

      //Noopur : Added this for code refactoring (T-321619)
      // T-320132:
      if (closedWonOpportunities.size() > 0 && !hasRunCloseWonMethods) {
        opportunityClass.checkOpptyChannelTypeOnClosedWon(closedWonOpportunities);
        checkOpptyDates(closedWonOpportunities);

        // Issue I-138684
        List<Opportunity> oppsToBeValidatedFurther = opportunityClass.validateProductsData(closedWonOpportunities, newMap.values());

        //As per T-319088
        opportunityClass.onDemandOpportunityLineItem(closedWonOpportunities, newMap.values());
        //T-320157
        opportunityClass.populateInvoiceToEndUser_OnClosedWon(closedWonOpportunities, newMap.values());
        //T-322814
        opportunityClass.validateOpptyContactRoleOnClosedWon(oppsToBeValidatedFurther, newMap.values());
        //T-322920
        //opportunityClass.validateOnePurchaseLedger_OpptyConRole(closedWonOpportunities, newMap.values()); T-326540

        //opportunityClass.validateOpportunityContactAddressOnClosedWon(oppsToBeValidatedFurther, newMap.values());
        opportunityClass.validateOppRelatedRecordsData(oppsToBeValidatedFurther, newMap.values());

        hasRunCloseWonMethods = true;
      }

      //T-257871: Multi-Currency Dashboard: Opp Trigger
      if (!hasRunMultiCurrencyUpdate) {
        system.debug('***beforeUpdate***newMap.values()>>>>' +newMap.values());
        system.debug('***beforeUpdate***oldMap>>>>' +oldMap);
        OpportunityTriggerHelper.multiCurrencyFieldUpdate(newMap.values(), oldMap);
        hasRunMultiCurrencyUpdate = true;
      }
      OpportunityTriggerHelper.calculateStageDuration(newMap, oldMap);
      System.debug('[OpportunityTriggerHandler: beforeUpdate]: After stage duration:'+ newMap);
      //T-267436: Update the opp fields if opp isWon or isClosed is changed from false to true
      OpportunityTriggerHelper.updateOppFieldsIfWonOrClosed(newMap, oldMap);
      System.debug('[OpportunityTriggerHandler: beforeUpdate]: After updateOppFieldsIfWonOrClosed:'+ newMap);

      OpportunityTrigger_AccountSegmentation.populateSegmentsOnOppty(newMap.values(), oldMap);

    }


  //===========================================================================
  // AFTER UPDATE
  //===========================================================================
   public static void afterUpdate (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
      // NLG Commenting this call - old version of the renewal process
      //OpportunityTrigger_RenewalUtility.createRenewalOpportunties(newMap, oldMap);
     
     System.debug('--trigger call->' + isAfterUpdateTriggerExecuted);
  
     if(!isAfterUpdateTriggerExecuted) {
       isAfterUpdateTriggerExecuted = true;  
     
     //nojha: 02/04/14
     OpportunityTrigger_OrderHelper.createOrderAndOrderLineItems(newMap, oldMap);
      System.debug('[OpportunityTriggerHandler: afterUpdate]: After createOrderAndOrderLineItems:'+ newMap);
     OpportunityTrigger_OrderHelper.deleteOrderAndOppIfOppIsReopened(newMap, oldMap);
      System.debug('[OpportunityTriggerHandler: afterUpdate]: After deleteOrderAndOppIfOppIsReopened:'+ newMap);
     OpportunityTrigger_DatesUtility.populateServiceDatesOnOLI(newMap , oldMap); // T-253868
      System.debug('[OpportunityTriggerHandler: afterUpdate]: After populateServiceDatesOnOLI:'+ newMap);
     updateOpportunityPlans(newMap, oldMap); // Case #8991 - JW 10102014
     //synchCurrencyISOCodes(newMap, oldMap); // I-120989
     
     //
     system.debug('1===isSynchOppDateFutureCalled>>>>' +isSynchOppDateFutureCalled);
     if (!isSynchOppDateFutureCalled) {
       isSynchOppDateFutureCalled = true;
       system.debug('2===isSynchOppDateFutureCalled>>>>' +isSynchOppDateFutureCalled); 
       // NLG Apr 21, 2015 - ON HOLD processOppSynDate(newMap, oldMap);
       System.debug('[OpportunityTriggerHandler: afterUpdate]: After processOppSynDate:'+ newMap);
     }

     //TPati 09-17-2014: Case 00004517- Copy New Opty Owner to Account Team
     updateAcntTeamWithOptOwner(newMap, oldMap);


     opportunityClass.opportunityReopeningProcess(newMap, oldMap);



     //[RJ]- Call optyQuotesStatusChangeprocess
     optyQuotesStatusChangeprocess(newMap, oldMap);

   
   
   
   
   
    
     // T-335634 - Retention calculations
      List<Opportunity> checkForRetention = new List<Opportunity> ();
      for ( Opportunity opp : newMap.values()) {
        if ( opp.Type == Constants.OPPTY_TYPE_RENEWAL ) {
          checkForRetention.add(opp);
        }
      }
      
      if ( !checkForRetention.isEmpty() ) {
        // call the RetentionRelatedMethod for afterUpdate
        RetentionUtility.processOppForRetention( checkForRetention, oldMap );




      }

      checkForRetentionAfterTypeChange ( newMap, oldMap) ;
      
      if (!hasRunAccountSegmentation) {
        OpportunityTrigger_AccountSegmentation.updateOppRelatedAccountSegments(oldMap, newMap);
        hasRunAccountSegmentation = true;
      }
    }
 

 }

  //===========================================================================
  // BEFORE DELETE 
  //===========================================================================
  public static void beforeDelete ( Map<Id,Opportunity> oldMap ) {
    // NS- commented, because we will be using OpportunityId to remove the related Retention Line Items
   /* Map<Id, OpportunityLineItem> oldOLI = new Map<Id,OpportunityLineItem>();
    for ( OpportunityLineItem oli : [SELECT Id, Item_Number__c, Quote_Number__c, Part_Number__c, OpportunityId, Opportunity.Previous_Opportunity__c
                                     FROM OpportunityLineItem
                                     WHERE OpportunityId IN :oldMap.keySet()]) {
      oldOLI.put(oli.Id, oli);
    }*/
    RetentionUtility.removeRetentionLineItems ( oldMap.keySet() ); 
  }


  //===========================================================================
  // AFTER DELETE
  //===========================================================================
  public static void afterDelete (Map<ID, Opportunity> oldMap) {
    OpportunityTrigger_AccountSegmentation.accountSegmentCalculation(oldMap.values()); //T-377400
  }

  //===========================================================================
  // AFTER UNDELETE
  //===========================================================================
  public static void afterUndelete (Map<ID, Opportunity> newMap) {
    OpportunityTrigger_AccountSegmentation.accountSegmentCalculation(newMap.values()); //T-377400
  }





  //===========================================================================
  //===========================TRIGGER FUNCTIONALITY===========================
  //===========================================================================

  // After Update Call DQ Admin Profile
   public static void afterUpdateForDQTeam (Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
     updateAcntTeamWithOptOwner(newMap, oldMap);
  }
  //===========================================================================
  // T-372609
  //===========================================================================
  /* NLG Apr 21, 2015 - ON HOLD
  public static void processOppSynDate(Map<Id, Opportunity>newMap, Map<Id, Opportunity>oldMap) {
    system.debug('=========processOppSynDate>>>>>>>>>');
     // T-372609
     Map<Id, Integer> mapOppIdToDaysShifted = new Map<Id, Integer>();
     for (Opportunity opp : newMap.values()) {
         system.debug('===opp>>>' +opp);
         system.debug('===oldMap>>>' +oldMap);
         system.debug('===opp.CloseDate>>>' +opp.CloseDate);
         system.debug('===old.CloseDate>>>' +oldMap.get(opp.Id).CloseDate);
         if (oldMap <> null  && opp.CloseDate <> oldMap.get(opp.Id).CloseDate && 
               opp.IsClosed == false && opp.All_dates_based_on_Closed_Date__c == true) {  
             mapOppIdToDaysShifted.put(opp.Id, oldMap.get(opp.Id).CloseDate.daysBetween(opp.CloseDate));
         }
     }
     
     system.debug('===mapOppIdToDaysShifted>>>' +mapOppIdToDaysShifted);
     
     if (mapOppIdToDaysShifted.size() > 0) {
       System.debug('~~~~debug calling future~~'+mapOppIdToDaysShifted);
       syncOppDates(mapOppIdToDaysShifted);
     }
   }*/



  //[RJ] Method to process closed Opty and check for count if its more than 1 then call the batch process else call the future process.
  public static void optyQuotesStatusChangeprocess(Map<Id,Opportunity> newMap, Map<ID, Opportunity> oldMap) {

    Integer quoteCount = [SELECT Count() FROM Quote__c WHERE Opportunity__c in : newMap.keySet() LIMIT 110];

    if (newMap.size() > 1 || quoteCount > (Limits.getLimitCallouts() - Limits.getCallouts()) ) {
      Boolean isTriggerBatch = false;
      for (Opportunity optyRec: newMap.values()) {
        if (optyRec.isClosed &&  optyRec.isClosed != oldMap.get(optyRec.Id).isClosed && optyRec.SyncCPQ__c) {
          isTriggerBatch= true;
          break;
        }
      }

      try{

        if (isTriggerBatch && !Test.isRunningtest() ) {
          BatchQuoteStatusUpdate batchQuoteStatusObj = new BatchQuoteStatusUpdate ();
          //database.executeBatch(batchQuoteStatusObj ,1);
          system.scheduleBatch(batchQuoteStatusObj , 'Batch Quote Status Update', 120, 1);
        }

      }
      catch (System.AsyncException ex) {
        System.debug('Batch Quote Status Update is already Scheduled' );
        System.debug('\n OpportunityTriggerHandler - optyQuotesStatusChangeprocess: '+ex.getLineNumber() + ' Stack:' +ex.getStackTraceString() );
      }
      catch (exception ex) {
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','optyQuotesStatusChangeprocess', ex.getStackTraceString(), ex);
        System.debug('OpportunityTriggerHandler - optyQuotesStatusChangeprocess: '+ex.getLineNumber() + ' Stack:' +ex.getStackTraceString() );
      }

    } else {
      for (Opportunity optyRec: newMap.values()) {
        System.debug(optyRec.isClosed +' ' + optyRec.isClosed != oldMap.get(optyRec.Id).isClosed +' '+ optyRec.SyncCPQ__c);
        if (optyRec.isClosed &&  optyRec.isClosed != oldMap.get(optyRec.Id).isClosed && optyRec.SyncCPQ__c) {
          SFDCToCPQChangeStatusServiceClass.callOptyCPQChangeStatusSerivceAsync(optyRec.id);
        }
      }
    }
  }



  // Start Function to add the changed opty owner on the Account Team on Opty Owner Change :Tyaga Pati // TP - Changed from private to public
    private static void updateAcntTeamWithOptOwner(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap) {
        List<Opportunity> oppIDs = new List<Opportunity>();
        //Create a list of Opportunities where the Owner has changed.
        for (Opportunity Opty: newMap.values())
            {
            if(oldMap != null && oldMap.get(Opty.Id).OwnerId == Opty.OwnerId)
                {
                    continue;
                }
            oppIDs.add(Opty);
            }
        //Iterate through the Opportunity set where the
        List<AccountTeamMember> acnttmList = new List<AccountTeamMember>();
        List<AccountShare> AccntShrLst = new List<AccountShare>();
        if (oppIDs.size() > 0)
            {
            for (Opportunity Opty : oppIDs)
                {
                    AccountTeamMember atm = new AccountTeamMember();
                    AccountShare acntshare = new AccountShare();
                    atm.AccountId = Opty.AccountId;
                    atm.UserId = Opty.OwnerId;
                    atm.TeamMemberRole = Constants.TEAM_ROLE_ACCOUNT_MANAGER;
                    acnttmList.add(atm);
                    acntshare.UserOrGroupId = Opty.OwnerId;
                    acntshare.AccountId = Opty.AccountId;
                    acntshare.AccountAccessLevel= Constants.ACCESS_LEVEL_EDIT;
                    acntshare.OpportunityAccessLevel= Constants.ACCESS_LEVEL_READ;
                    AccntShrLst.add(acntshare);
                }//end for Loop
            // PK Case #593979: Fix for inactive users failing on shares
            try {
              insert acnttmList; 
              insert AccntShrLst;  
            }
            catch (DMLException dmle) {
              system.debug('Unable to insert Shares for inactive users.' );
              system.debug('\n OpportunityTriggerHandler - updateAcntTeamWithOptOwner: '+dmle.getLineNumber() + ' Stack:' +dmle.getStackTraceString() );
            }

          }
  }//End OF updateAcntTeamWithOptOwner
  //==========================================================================
  // T-258164: Key Dates out of alignments
  //==========================================================================
  private static void checkOpptyDates(List<Opportunity> closedWonOpportunities) {
    List<String> errList;
    for (Opportunity oppty : closedWonOpportunities) {
      errList = new List<String>();
      errList = OpportunityUtility.checkOpportunityDates(oppty.ID);
      if (errList.size() > 0) {
        String errStr = ' ';
        for (String err : errList) {
          errStr += err +', ';
        }
        oppty.addError(errStr.substring(0, errStr.length()-2));
      }
    }
  }

  ////////// NLG Sep 10th, 2014 - Removing this method because this is done with the contId parameter passed
  //         via URLRedirect.cls
  /*
  public void createOppContactRoles(Map<Id,Opportunity> opps) {
    OpportunityContactRole oppRole;
    List<OpportunityContactRole> oppRoles = new List<OpportunityContactRole>();
    try {
    for (Opportunity opp: opps.values()) {
      if (opp.Originating_Contact_Id__c != null && (opp.Originating_Contact_Id__c.length() == 15 || opp.Originating_Contact_Id__c.length() == 18)) {
        oppRoles.add(new OpportunityContactRole(OpportunityId=opp.Id, ContactId=opp.Originating_Contact_Id__c,IsPrimary=true));
      }
    }

      insert oppRoles;
    } catch (DMLException e) {
      system.debug('[OpportunityTriggerHandler: createOppContactRoles] Exception: ' + e.getMessage());
      ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','createOppContactRoles', e.getStackTraceString(), e);
      for (Integer i=0; i < e.getNumDml(); i++) {
        opps.values().get(0).addError(e.getDMLMessage(i));
      }
    }
  }*/

  // START: Case #6875 (James Weatherall)
  private static void createOppTeamMembers(Map<Id, Opportunity> opps) {
    List<OpportunityTeamMember> oppTeamMembersToInsert = new List<OpportunityTeamMember>();
    Map<Id, Id> mapOppToAccIds = new Map<Id, Id>();
    Map<Id, AccountTeamMember> mapAccToATMs = new Map<Id, AccountTeamMember>();
    Id accountId;
    Id userId;

    try {
      for (Opportunity opp: opps.values()) {
        mapOppToAccIds.put(opp.Id, opp.AccountId);
      }
      // PK: Case 00542894, added User.IsActive = true check
      for(AccountTeamMember atm : [SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMember
                                   WHERE User.IsActive = true AND TeamMemberRole =: Constants.TEAM_ROLE_STRAT_ACCOUNT_MANAGER AND AccountId in: mapOppToAccIds.values()])
      {
        mapAccToATMs.put(atm.AccountId, atm);
      }

      for(Id oppId : mapOppToAccIds.keySet())
      {
        accountId = mapOppToAccIds.get(oppId);
        if(mapAccToATMs.size() > 0) {
          AccountTeamMember atm = mapAccToATMs.get(accountId);
          oppTeamMembersToInsert.add(new OpportunityTeamMember(OpportunityId = oppId, UserId = atm.UserId, TeamMemberRole = atm.TeamMemberRole));
        }
      }

      if(oppTeamMembersToInsert.size() > 0) {
        insert oppTeamMembersToInsert;
      }

    } catch (DMLException e){
      system.debug('[OpportunityTriggerHandler: createOppTeamMembers] Exception: ' + e.getMessage());
      ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','createOppTeamMembers', e.getStackTraceString(), e);
      for (Integer i=0; i < e.getNumDml(); i++) {
        opps.values().get(0).addError(e.getDMLMessage(i));
      }
    }
  }
  // END: Case #6875





  //======================================================
  // This method will perform a check to see if the User set as the Owner
  // is part of the Account Team, which is a requirement in order to
  // save the record. T-249341
  //======================================================
  /*private static void checkOwnerAllowed(List<Opportunity> opps) {
    Set<Id> accountIds = new Set<Id>();
    for (Opportunity opp: opps) {
      if (String.isNotEmpty(opp.AccountId)) {
        accountIds.add(opp.AccountId);
      }
    }
    Map<Id, Profile> specialProfiles = new Map<Id, Profile>([SELECT Id
                        FROM Profile
                        WHERE Name = 'System Administrator' OR Name = 'Experian Sales Administration']);
    Map<Id, Account> accountMap = new Map<Id, Account>(
                            [SELECT Id,
                                    (SELECT Id, UserId
                                     FROM AccountTeamMembers)
                             FROM Account
                             WHERE Id in: accountIds]);
    Account acct;
    Boolean foundTeamMember = false;
    for (Opportunity opp: opps) {
      if (specialProfiles.keySet().contains(UserInfo.getProfileId())) {
        continue;
      }
      if (String.isNotEmpty(opp.AccountId) && accountMap.get(opp.AccountId) != null) {
        acct = accountMap.get(opp.AccountId);
        for (AccountTeamMember teamMember: acct.AccountTeamMembers) {
          if (opp.OwnerId == teamMember.UserId) {
            foundTeamMember = true;
          }
        }
        if (!foundTeamMember) {
          opp.addError('\nThe Owner of this record must be part of the Account Team in order to create this record.');
          return;
        }
      }
    }
  }*/
  
  //As per task T-409411
  public static List<Opportunity_Plan__c> populateOpportunityPlansForNewOppties (Set<ID> newOpptySet) {
             
    List<Opportunity_Plan__c> opportunityPlans = new List<Opportunity_Plan__c>();                                                                       
    for(Opportunity_Plan__c opptyPlan : [SELECT Id, OwnerId, Opportunity_Owner__c, Opportunity_Client_Budget__c, 
                                                Opportunity_Name__c, Opportunity_Expected_Close_Date__c, CurrencyISOCode
                                           FROM Opportunity_Plan__c
                                           WHERE Opportunity_Name__c IN : newOpptySet]) {
      opportunityPlans.add(opptyPlan);
      System.debug('^^^^^^opptyPlan^^^^^'+opptyPlan);
    }
    System.debug('---'+newOpptySet+'**********opportunityPlans***'+opportunityPlans);
    return opportunityPlans;
  }


  //============================================================================
  // This method will find if any Opportunity Plan record exist. If so, update
  // all opportunity plan fields to sync.  T-273787
  //
  // 10102014 James Weatherall - Uncommented code in order to update Opp Plan
  // Opportunity Owner as raised in Case #8991
  //============================================================================
  private static void updateOpportunityPlans(Map<ID, Opportunity> newMap, Map<ID, Opportunity> oldMap){

    List<Account_Plan_Opportunity__c> accPlanOppss ;
    if(IsOppPlanSyncInProg == true) {
     return;
    }
    System.debug('****newMap.keySet()***'+newMap.keySet());
    //Populating opportunity plans
    List<Opportunity_Plan__c> opptyPlansForNewOppties = new List<Opportunity_Plan__c>();
    opptyPlansForNewOppties = populateOpportunityPlansForNewOppties(newMap.keySet());
    
    IsOppPlanSyncInProg = true;

    Set<Id> modifiedOpportunityIds = new Set<Id>();
    List<Opportunity_Plan__c> modifiedOpportunityPlans = new List<Opportunity_Plan__c>();

    //Check if opportunity Budget/OwnerId fields have been changed
    for(Opportunity opp : newMap.values()){
        if((opp.OwnerId <> oldMap.get(opp.Id).OwnerId) ||
           (opp.Budget__c <> oldMap.get(opp.Id).Budget__c ) ||
           (opp.CloseDate <> oldMap.get(opp.Id).CloseDate ) || 
       (oldMap.get(opp.Id).CurrencyIsoCode <> opp.CurrencyIsoCode)){
            modifiedOpportunityIds.add(opp.Id);
        }
    }

  

    System.debug('modifiedOpportunityIds : ' + modifiedOpportunityIds);
    //Find Opportunity Plans related to opportunity
    if (modifiedOpportunityIds.size() > 0) {
      // Added Opportunity_Owner__c field - JW 10102014
      for (Opportunity_Plan__c oppPlan : opptyPlansForNewOppties) {
                                           /*[SELECT Id, OwnerId, Opportunity_Owner__c, Opportunity_Client_Budget__c, Opportunity_Name__c,Opportunity_Expected_Close_Date__c
                                           FROM Opportunity_Plan__c
                                           WHERE Opportunity_Name__c IN :modifiedOpportunityIds]) */
         if (oppPlan.Opportunity_Name__c != null && modifiedOpportunityIds.contains(oppPlan.Opportunity_Name__c)) {                        
        Opportunity currentOpp = newMap.get(oppPlan.Opportunity_Name__c);
            System.debug('currentOpp.OwnerId : ' + currentOpp.OwnerId);
            if (currentOpp != null &&
              (oppPlan.OwnerId != currentOpp.OwnerId ||
               oppPlan.Opportunity_Client_Budget__c != currentOpp.Budget__c ||
               oppPlan.Opportunity_Expected_Close_Date__c != currentOpp.CloseDate)){
                    oppPlan.OwnerId = currentOpp.OwnerId;
                    oppPlan.Opportunity_Owner__c = currentOpp.OwnerId;
                    oppPlan.Opportunity_Client_Budget__c = currentOpp.Budget__c;
                    oppPlan.Opportunity_Expected_Close_Date__c = currentOpp.CloseDate;
                    oppPlan.CurrencyIsoCode = currentOpp.CurrencyIsoCode;
                    modifiedOpportunityPlans.add(oppPlan);
            }
          }
        }

        accPlanOppss = [Select Id , CurrencyISOCode,Opportunity__c From Account_Plan_Opportunity__c Where Opportunity__c = : modifiedOpportunityIds];
        //New Currency ISO Code for opp plan
        for (Account_Plan_Opportunity__c accPlanOpp : accPlanOppss) {
            accPlanOpp.CurrencyISOCode =  newMap.get(accPlanOpp.Opportunity__c).CurrencyIsoCode;
        }
    }
    //Update Opportunity Plan fields
    if (!modifiedOpportunityPlans.isEmpty()) {
        try {
          update modifiedOpportunityPlans;
          if (accPlanOppss != null && accPlanOppss.size() > 0) {
            update accPlanOppss;
        }
        } catch(DMLException ex) {
            apexLogHandler.createLogAndSave('OpportunityTriggerHandler','updateOpportunityPlans', ex.getStackTraceString(), ex);
            for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
                newMap.values().get(0).addError(ex.getDMLMessage(indx));
            }
        }
    }
  }

  //I-120524: Currency should be same between related objects
  /*private static void synchCurrencyISOCodes (Map<Id,Opportunity> newMap, Map<ID, Opportunity> oldMap){
    Set<Id> oppIDs = new Set<ID>();

    for(Opportunity opp : newMap.values()){
      if(oldMap != null && oldMap.get(opp.Id).CurrencyIsoCode == opp.CurrencyIsoCode) {
    continue;
    }
    
    oppIDs.add(opp.ID);
    }


    //Iterating through all opp got updated for currency iso code
    if (oppIDs.size() > 0) {
      List<Opportunity_Plan__c> oppPlans = new List<Opportunity_Plan__c>();//[Select Id , CurrencyISOCode, Opportunity_Name__c From Opportunity_Plan__c Where Opportunity_Name__c = : oppIDs];
      //New Currency ISO Code for opp plan
      for (Opportunity_Plan__c oPlan : opptyPlansForNewOppties) {
        if (oppIDs.size() > 0 && oppIDs.contains(oPlan.Opportunity_Name__c)) {
          oPlan.CurrencyISOCode = newMap.get(oPlan.Opportunity_Name__c).CurrencyIsoCode;
          oppPlans.add(oPlan);
        }
      }


      List<Account_Plan_Opportunity__c> accPlanOppss = [Select Id , CurrencyISOCode,Opportunity__c From Account_Plan_Opportunity__c Where Opportunity__c = : oppIDs];
      //New Currency ISO Code for opp plan
      for (Account_Plan_Opportunity__c accPlanOpp : accPlanOppss) {
          accPlanOpp.CurrencyISOCode =  newMap.get(accPlanOpp.Opportunity__c).CurrencyIsoCode;
      }

      try {
        //Update currency on related objects
        if (oppPlans.size() > 0) {
          update oppPlans;
        }

        if (accPlanOppss.size() > 0) {
          update accPlanOppss;
        }
      } catch (Dmlexception ex) {
        System.debug('[OpportunityTriggerHandler:synchCurrencyISOCodes]'+ex.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','synchCurrencyISOCodes', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          newMap.values().get(0).addError(ex.getDmlMessage(i));
        }
      }
    }

  }*/

  //===============================================================
  // T-317816: Populate Tasks' Opp field when creating opp from Task
  //===============================================================
  private static void moveOriginatingTaskToNewOppty (List<Opportunity> newList) {
    Set<String> orgTasksSet = new Set<String>();
    Map<ID, Task> tasksToUpdateMap = new Map<ID, Task>();

    for (Opportunity opp : newList) {
      if (opp.Originating_Task_Id__c != null) {
        orgTasksSet.add(opp.Originating_Task_Id__c);
        }
    }

    //If no originating task return
    if (orgTasksSet.size() < 1) {
      return;
    }

    //Fetching and populating map for standard tasks for orignating contacts
    for (Task tsk : [SELECT WhatId, WhoId, ID
                          FROM Task
                          WHERE ID IN : orgTasksSet AND WhatId = null]) {
       if (!tasksToUpdateMap.containsKey(tsk.ID)) {
          tasksToUpdateMap.put(tsk.ID, tsk);

       }
    }

    //If no task found return
    if (tasksToUpdateMap.size() < 1) {
      return;
    }

    //Associating standard task with new opportunity
    for (Opportunity opp : newList) {
      if (opp.Originating_Task_Id__c != null) {
        ID taskId = (ID)opp.Originating_Task_Id__c;
        if (tasksToUpdateMap.containsKey(taskId)) {
          tasksToUpdateMap.get(taskId).WhatId = opp.ID;
        }
      }
    }

    try {
      //Updating tasks.
      if (tasksToUpdateMap.values().size() > 0) {
        update tasksToUpdateMap.values();
      }
    }
      catch (DmlException ex) {
        apexLogHandler.createLogAndSave('OpportunityTriggerHandler','moveOriginatingTaskToNewOppty', ex.getStackTraceString(), ex);
        for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          newList.get(0).addError(ex.getDMLMessage(indx));
        }
      }
  }
    //==================================================================
    //T-320132: Method to check channel type and Partner on Opportunity
    //==================================================================
    public virtual void checkOpptyChannelTypeOnClosedWon(List<Opportunity> closedWonOpportunities){

    }



  // T-321619: Method to return the opportunities that have the stagename closed/won
  /*public virtual*/ private static List<Opportunity> fetchClosedWonRecords(Map<Id,Opportunity> oldMap, List<Opportunity> newList) {
    List<Opportunity> closingOppsList = new List<Opportunity>();
    for ( Opportunity opp : newList ) {
      if ( oldMap == null && opp.StageName == Constants.OPPTY_STAGE_7) {
        closingOppsList.add(opp);
      }
      else if ( oldMap != null  && opp.StageName == Constants.OPPTY_STAGE_7
                           && opp.StageName != oldMap.get(opp.ID).StageName )  {
        closingOppsList.add(opp);
      }
    }
    /*if (oppOLIMapForClosedWon.size() == 0) {
      for ( OpportunityLineItem oli : [SELECT Id,EDQ_On_Demand_Product__c,OpportunityId,SaaS__c
                                       FROM OpportunityLineItem
                                       WHERE OpportunityId IN :closingOppsList]) {
        if(oppOLIMapForClosedWon.containsKey(oli.OpportunityId)) {
          oppOLIMapForClosedWon.get(oli.OpportunityId).add(oli);
        }
        else {
          oppOLIMapForClosedWon.put(oli.OpportunityId, new List<OpportunityLineItem> {oli});
        }
      }
    }*/
    return closingOppsList;
 }

  //==============================================================================
  //We need to validate data prior to closing an Opportunity.
  //If an OpportunityLineItem is considered "On Demand" (it comes from another system),
  //then the related Account should have an "On Demand" contact.
  //==============================================================================
  public virtual void onDemandOpportunityLineItem(List<Opportunity> closedWonOpportunities, List<Opportunity> newList) {
    Set<ID> closingOpptyIDs = new Set<ID>();
    Set<ID> accountIDs = new Set<ID>();

    Set<ID> onDemandOppIDs = new Set<ID>();
    Set<ID> onDemandAccountIDs = new Set<ID>();

    //Query the Opps along with their OpportunityLineItem WHERE On_Demand_Product__c == TRUE
    /* T-409412: Commented query as it has two soql (nested) on parent. nojha June 16th, 2015
      for (Opportunity opp : [SELECT ID, StageName, AccountID, (SELECT Id, OpportunityId, EDQ_On_Demand_Product__c
                                                  FROM OpportunityLineItems
                                                  WHERE EDQ_On_Demand_Product__c = true)
                            FROM Opportunity

                            WHERE ID IN: closedWonOpportunities]) {*/
    for (OpportunityLineItem oli : [SELECT Id, Opportunity.AccountId, OpportunityId, EDQ_On_Demand_Product__c
                                                  FROM OpportunityLineItem
                                                  WHERE EDQ_On_Demand_Product__c = true AND
                                                  OpportunityId IN: closedWonOpportunities]) {
                            
      //Loop through Opps and if they have an OLI attached, store those OLI's.OpportunityId in a set "onDemandOppsList"
      onDemandOppIDs.add(oli.OpportunityId);
      accountIDs.add(oli.Opportunity.AccountID);
    }

    //Query the subset of (Accounts with Contacts WHERE EDQ_On_Demand__c == TRUE)
    //to which those Opportunities in onDemandOppsList belong to  ==> those opps have an On Demand OLI.
    /*T-409412: Commented query as it has two soql (nested) on parent. nojha June 16th, 2015
      for (Account acc : [SELECT Id, (SELECT Id, EDQ_On_Demand__c FROM Contacts WHERE EDQ_On_Demand__c = true)
                        FROM Account
                        WHERE ID IN: accountIDs]) { */
    for (Contact cont : [SELECT Id, AccountId, EDQ_On_Demand__c FROM Contact WHERE EDQ_On_Demand__c = true
                        AND AccountID IN: accountIDs]) {                        	
      //Loop through the Accounts & Contacts, and store the Accounts that have
      //at least 1 On Demand Contact in a set "onDemandAccountsSet" ==> Those Accounts have an OnDemand Contact
      onDemandAccountIDs.add(cont.AccountID);
    }

    //Adding error if opportunity is ondemand oppty but do not have onDemand account on it
    if (onDemandOppIDs.size() > 0) {
	    for (Opportunity opp : newList) {
	      if(onDemandOppIDs.contains(opp.ID) && !onDemandAccountIDs.contains(opp.AccountID)) {
	        opp.addError(Label.OPPTY_ERR_ONDEMAND_PRODUCT);
	      }
	    }
    }
  }

 public virtual void updateAccPlanOpptyRecs (Set<ID> opptyIDsToUpdateAccPlanOpptySet) {

 }


  //Pallavi Sharma @ Oct 17th 2014
  //Refactoring Code for improvement
  //Add validation of Primary Contact
  //When Opp gets closed than there must be one Primary Contact associated with it.
  public virtual void validateOpptyContactRoleOnClosedWon(List<Opportunity> closedWonOpportunities, List<Opportunity> newList) {
    set<Id> setOppId = new set<Id>();
    set<Id> setOppOfPrimaryContactRole = new set<Id>();

    for (Opportunity opp : closedWonOpportunities) {
      setOppId.add(opp.Id);
    }
    //Check for one Primary Contact Role
    /*for (AggregateResult contactRole : [ SELECT OpportunityId
                                                FROM OpportunityContactRole
                                                WHERE OpportunityId IN: setOppId
                                                AND IsPrimary = true
                                                AND ContactId != null
                                                Group By OpportunityId]) {
      setOppOfPrimaryContactRole.add( Id.valueOf(contactRole.get('OpportunityId') + ''));
    }*/
    //T-368846
    lstOppConRole = getOppConRoleRecord(setOppId);
    for (OpportunityContactRole ocr : lstOppConRole) {
      if (ocr.IsPrimary ==  true) {
        setOppOfPrimaryContactRole.add(ocr.OpportunityId);
      }
    }
    for (Opportunity opp : closedWonOpportunities) {
      //Adding error of no Primary Contact Role exists
      if (!setOppOfPrimaryContactRole.contains(opp.Id)) {
        opp.addError(Label.Opp_Needs_Primary_Contact);
      }
    }
  }


  //===============================================================
  // Change Opportunity Process Section
  //===============================================================
  public virtual void opportunityReopeningProcess (Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
    // NS- 10-Oct-2014
     Set<Id> stage4Opps = new Set<Id>();
     Set<Id> lostCreditedOpps = new Set<Id>();
     Map<String, Opportunity> lostCreditedOppOldMap = new Map<String, Opportunity>();

     for (Opportunity opp : newMap.values() ) {
       if ( opp.StageName == Constants.OPPTY_STAGE_4 && oldMap.get(opp.Id).StageName == Constants.OPPTY_STAGE_7 ) {
         stage4Opps.add(opp.Id);
       }
       else if ( opp.StageName == Constants.OPPTY_CLOSED_LOST && oldMap.get(opp.Id).StageName == Constants.OPPTY_STAGE_7
        && opp.Type == Constants.OPPTY_TYPE_CREDITED) {
         lostCreditedOpps.add(opp.Id);
         lostCreditedOppOldMap.put(opp.Id, oldMap.get(opp.Id));
       }
     }

     if ( !stage4Opps.isEmpty() ) {
        reopenPreInvoiceOpp(stage4Opps);
     }
     if ( !lostCreditedOpps.isEmpty() ) {
       reopenPostInvoiceOpp(lostCreditedOppOldMap);
     }
  }


  // Method to re-open Opportunity when the Export to Invoicing is false for Opportunity Order.
  private void reopenPreInvoiceOpp (set<Id> stage4Opps) {
    //try {
      List<Asset> assetList = new List<Asset>();
      for ( Asset assetObj : [SELECT Id, Order_Line__r.Opportunity_Line_Item_Id__c,
                                     Order_Line__r.Order__c, Order_Line__c, Cancellation_Date__c ,
                                     Order_Line__r.Order__r.Opportunity__r.Id
                              FROM Asset
                              WHERE Opportunity__c IN :stage4Opps]) {
        assetObj.Cancellation_Date__c = Date.today();
        assetObj.Status = 'Cancelled';
        assetList.add(assetObj);
      }
      if (!assetList.isEmpty()) {
        update assetList;
      }
   // }
    /*catch (DMLException ex) {
      system.debug('[OpportunityTriggerHandler: reopenPreInvoiceOpp] Exception: ' + ex.getMessage());
      ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','reopenPreInvoiceOpp', ex.getStackTraceString(), ex);
    }*/
  }


  // Method to re-open Opportunity when the Export to Invoicing is true for Opportunity Order.
  private void reopenPostInvoiceOpp (Map<String, Opportunity> lostCreditedOppOldMap) {
    //try {
      Set<String> lostCreditedOpps = lostCreditedOppOldMap.keySet();
      if (hasRunReopenPostInvoice) {
        return;
      }
       hasRunReopenPostInvoice = true;
       List<Order__c> ordersToUpdate = new list<Order__c>();
       // PK Case #610130 - Changed the query below to look for live and planned orders only.
       for (Order__c orderObj : [SELECT Id,Credited_Date__c,Opportunity__c
                                 FROM Order__c
                                 WHERE Opportunity__c IN :lostCreditedOpps
                                 /// AND Status__c IN ('Live','Planned') // PK: REVERTED FOR 090615 RELEASE
                                 ]) {
         orderObj.Credited_Date__c = Date.today();
         orderObj.Type__c = Constants.ORDER_TYPE_CREDITED;
         ordersToUpdate.add(orderObj);
       }
       if ( !ordersToUpdate.isEmpty() ) {
         update ordersToUpdate;
       }

       List<Opportunity> renewalOpps = new List<Opportunity>();
       for ( Opportunity opp : [SELECT Id
                                FROM Opportunity
                                WHERE Type= :Constants.OPPTY_TYPE_RENEWAL
                                AND Previous_Opportunity__c IN :lostCreditedOpps]) {
         renewalOpps.add(opp);
       }

      if (!renewalOpps.isEmpty()) {
        delete renewalOpps;
      }

      List<Asset> assetListToUpdate = new List<Asset>();
      List<Asset> assetListToDelete = new List<Asset>();
      List<Asset> assetList = new List<Asset>();
      Set<String> oliIdSet = new Set<String>();
      Set<String> oliSetForDeletion = new Set<String>();
      List<Registration__c> regObjectDel = new List<Registration__C>();//Tyaga Pati: Registration Deletion Code
      // PK Case #610130 - Changed the query below to look for live and scheduled orders only.
      for ( Asset assetObj : [SELECT Id, Order_Line__r.Opportunity_Line_Item_Id__c,
                                     Order_Line__r.Order__c, Order_Line__c, Cancellation_Date__c ,
                                     Order_Line__r.Order__r.Opportunity__r.Id
                              FROM Asset
                              WHERE Opportunity__c IN :lostCreditedOpps
                              // AND Status__c IN ('Live','Scheduled')  // PK: REVERTED FOR 090615 RELEASE
                              ]) {
        oliIdSet.add(assetObj.Order_Line__r.Opportunity_Line_Item_Id__c);
        assetList.add(assetObj);
      }
      for (OpportunityLineItem oli : [SELECT Id, Type__c
                                      FROM OpportunityLineItem
                                      WHERE ID IN :oliIdSet AND Order_Type__c = 'New']) {
        oliSetForDeletion.add(oli.Id);
      }
      for ( Asset assetObj : assetList ) {
        if (oliSetForDeletion.contains(assetObj.Order_Line__r.Opportunity_Line_Item_Id__c)) {
          assetListToDelete.add(assetObj);
        }
        else {
          assetObj.Credited__c = true;
          assetObj.Credited_Date__c = Date.today();
          assetObj.Status = Constants.ASSET_TYPE_CREDITED;
          assetListToUpdate.add(assetObj);
        }
      }
      
      // Tyaga Pati Fetching the Registration records associated with the Assets To be Deleted
      for (Registration__c regObj : [SELECT Id FROM Registration__c 
                                     WHERE Asset__c IN :assetListToDelete]) {
        regObjectDel.add(regObj);
      }
      //try {
        if (!assetListToDelete.isEmpty()) {
          if (!regObjectDel.isEmpty()) {
            // Deleting the Registration records
            delete regObjectDel;
          }
          delete assetListToDelete;
        }
        if (!assetListToUpdate.isEmpty() ) {
          update assetListToUpdate;
        }
      /*} catch (DMLException e) {
        system.debug('[OpportunityTriggerHandler: reopenPostInvoiceOpp] Exception: ' + e.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','reopenPostInvoiceOpp', e.getStackTraceString(), e);
      }*/

      List<Opportunity> oppClonesList = new List<Opportunity>();
      Map<Opportunity,Opportunity> clonedOppMap = new Map<Opportunity,Opportunity>();

      String queryString = 'SELECT ' + fetchObjectFields('Opportunity');
      queryString += ',(SELECT '+ fetchObjectFields('OpportunityContactRole') +' FROM OpportunityContactRoles),';
      queryString += '(SELECT '+ fetchObjectFields('Partner') +' FROM Partners),';
      queryString += '(SELECT '+ fetchObjectFields('OpportunityLineItem') +' FROM OpportunityLineItems),';
      queryString += '(SELECT '+ fetchObjectFields('Competitor__c') +' FROM Competitors__r),';
      queryString += '(SELECT '+ fetchObjectFields('OpportunityTeamMember') +' FROM OpportunityTeamMembers),';
      queryString += '(SELECT '+ fetchObjectFields('OpportunitySplit') +' FROM OpportunitySplits),';
      queryString += '(SELECT '+ fetchObjectFields('Opportunity_Plan__c') +' FROM Opportunity_Plans__r),';
      queryString += '(SELECT '+ fetchObjectFields('Quote__c') +' FROM Quotes__r),';
      queryString += '(SELECT '+ fetchObjectFields('Sales_Support_Request__c') +' FROM Bid_Support_Requests__r),';
      queryString += '(SELECT '+ fetchObjectFields('Task') +' FROM Tasks),';
      queryString += '(SELECT '+ fetchObjectFields('Event') +' FROM Events),';
      queryString += '(SELECT '+ fetchObjectFields('Royalty__c') +' FROM Royalties__r)';

      queryString += ' FROM Opportunity WHERE Id IN :lostCreditedOpps';

      // clone and create new opportunity
      for (Opportunity opp : Database.query(queryString) ) {
        Opportunity newOpp = opp.clone();
        // Start: Case #562850 - 19/2/2015 - JW
        String recTypeId = Record_Type_Ids__c.getOrgDefaults().Opportunity_Standard__c;
        newOpp.RecordTypeId = recTypeId;
        // End
        newOpp.StageName = Constants.OPPTY_STAGE_4;
        newOpp.Forecast_Category__c = Constants.OPPTY_FORECAST_CATEGORY_PIPELINE;
        newOpp.Previous_Opportunity__c = opp.Id;
        newOpp.Prod_Id__c = '';
        newOpp.EDQ_Integration_Id__c = null;
        newOpp.Type = lostCreditedOppOldMap.get(opp.Id).Type;
        oppClonesList.add(newOpp);
        clonedOppMap.put(newOpp,opp);
      }

      if ( !oppClonesList.isEmpty() ) {
        insert oppClonesList;
      }

      insertRelatedListOfClonnedOpp(clonedOppMap);
    /*}
    catch (DMLException ex) {
      system.debug('[OpportunityTriggerHandler: reopenPostInvoiceOpp] Exception: ' + ex.getMessage());
      ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','reopenPostInvoiceOpp', ex.getStackTraceString(), ex);
    }*/
  }

  /*
  Method to insert related list of the opportunities cloned
  */
  private void insertRelatedListOfClonnedOpp ( Map<Opportunity,Opportunity> clonedOppMap) {

      try {

        // insert the related list of new Opportunity created.
        List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
        List<OpportunityContactRole> ocrToInsert = new List<OpportunityContactRole>();
        List<Competitor__c> compToInsert = new List<Competitor__c>();
        List<Sales_Support_Request__c> salesSupportToInsert = new List<Sales_Support_Request__c>();
        List<Quote__c> quoteToInsert = new List<Quote__c>();
        List<Task> tasksToInsert = new List<Task>();
        List<Event> eventsToInsert = new List<Event>();
        List<Partner> partnerToInsert = new List<Partner>();
        List<Opportunity_Plan__c> oppPlansToInsert = new List<Opportunity_Plan__c>();
        List<OpportunitySplit> oppSplitsToInsert = new List<OpportunitySplit>();
        List<OpportunityTeamMember> oppTeamMembersToInsert = new List<OpportunityTeamMember>();
        List<Royalty__c> royaltiesToInsert = new List<Royalty__c>();

        for ( Opportunity newOpp : clonedOppMap.keySet()) {
            if( clonedOppMap.get(newOpp) == null ) {
            continue;
          }
          for (OpportunityLineItem oli : clonedOppMap.get(newOpp).OpportunityLineItems ) {
            OpportunityLineItem oliNew = new OpportunityLineItem();
            oliNew = oli.Clone(false,true);
            oliNew.TotalPrice = null;
            oliNew.OpportunityId = newOpp.Id;
            oliNew.EDQ_Integration_Id__c = null;
            oliToInsert.add(oliNew);
          }
          for (OpportunityContactRole ocr : clonedOppMap.get(newOpp).OpportunityContactRoles ) {
            OpportunityContactRole ocrNew = new OpportunityContactRole();
            ocrNew = ocr.Clone(false,true);
            ocrNew.OpportunityId = newOpp.Id;
            ocrToInsert.add(ocrNew);
          }
          for (Competitor__c comp : clonedOppMap.get(newOpp).Competitors__r ) {
            Competitor__c compNew = new Competitor__c();
            compNew = comp.Clone(false,true);
            compNew.Opportunity__c = newOpp.Id;
            compToInsert.add(compNew);
          }
          for (Sales_Support_Request__c salesSupport : clonedOppMap.get(newOpp).Bid_Support_Requests__r ) {
            Sales_Support_Request__c salesSupportNew = new Sales_Support_Request__c();
            salesSupportNew = salesSupport.Clone(false,true);
            salesSupportNew.Opportunity__c = newOpp.Id;
            salesSupportToInsert.add(salesSupportNew);
          }
          for (Quote__c quoteObj : clonedOppMap.get(newOpp).Quotes__r ) {
            Quote__c quoteNew = new Quote__c();
            quoteNew = quoteObj.Clone(false,true);
            quoteNew.Opportunity__c = newOpp.Id;
            quoteToInsert.add(quoteNew);
          }
          for (Task taskObj : clonedOppMap.get(newOpp).Tasks ) {
            Task taskNew = new Task();
            taskNew = taskObj.Clone(false,true);
            taskNew.WhatId = newOpp.Id;
            tasksToInsert.add(taskNew);
          }
          for (Event eventObj : clonedOppMap.get(newOpp).Events ) {
            Event eventNew = new Event();
            eventNew = eventObj.Clone(false,true);
            eventNew.WhatId = newOpp.Id;
            eventsToInsert.add(eventNew);
          }
          for (Partner partnerObj : clonedOppMap.get(newOpp).Partners ) {
            Partner partnerNew = new Partner();
            partnerNew = partnerObj.Clone(false,true);
            partnerNew.OpportunityId = newOpp.Id;
            partnerNew.AccountFromId = null;
            if ( partnerObj.AccountToId != newOpp.AccountId) {
              partnerToInsert.add(partnerNew);
            }
          }
          for (Opportunity_Plan__c oppPlanObj : clonedOppMap.get(newOpp).Opportunity_Plans__r ) {
            Opportunity_Plan__c oppPlan = new Opportunity_Plan__c();
            oppPlan = oppPlanObj.Clone(false,true);
            oppPlan.Opportunity_Name__c = newOpp.Id;
            oppPlan.Opportunity_ID_Unique__c = null;
            oppPlansToInsert.add(oppPlan);
          }
          for ( OpportunityTeamMember otm : clonedOppMap.get(newOpp).OpportunityTeamMembers) {
            OpportunityTeamMember newOTM = new OpportunityTeamMember();
            newOTM = otm.Clone(false,true);
            newOTM.OpportunityId = newOpp.Id;
            oppTeamMembersToInsert.add(newOTM);
          }
          for (OpportunitySplit oppSplitObj : clonedOppMap.get(newOpp).OpportunitySplits ) {
            OpportunitySplit oppSplit = new OpportunitySplit();
            oppSplit = oppSplitObj.Clone(false,false);
            oppSplit.OpportunityId = newOpp.Id;
            if ( oppSplit.SplitOwnerId != newOpp.OwnerId ) {
             oppSplitsToInsert.add(oppSplit);
            }
          }
          for (Royalty__c royalty : clonedOppMap.get(newOpp).Royalties__r ) {
            Royalty__c newRoyalty = new Royalty__c();
            newRoyalty = royalty.Clone(false,false);
            newRoyalty.Opportunity__c = newOpp.Id;
            royaltiesToInsert.add(newRoyalty);
          }
        }

        if ( !oliToInsert.isEmpty() ) {
          insert oliToInsert;
        }
        if ( !ocrToInsert.isEmpty() ) {
          insert ocrToInsert;
        }
        if ( !compToInsert.isEmpty() ) {
          insert compToInsert;
        }
        if ( !salesSupportToInsert.isEmpty() ) {
          insert salesSupportToInsert;
        }
        if ( !quoteToInsert.isEmpty() ) {
          insert quoteToInsert;
        }
        if ( !tasksToInsert.isEmpty() ) {
          insert tasksToInsert;
        }
        if ( !eventsToInsert.isEmpty() ) {
          insert eventsToInsert;
        }
        if ( !oppPlansToInsert.isEmpty() ) {
          insert oppPlansToInsert;
        }
        if ( !partnerToInsert.isEmpty() ) {
          insert partnerToInsert;
        }
        if ( !oppTeamMembersToInsert.isEmpty() ) {
          insert oppTeamMembersToInsert;
        }
        if ( !oppSplitsToInsert.isEmpty() ) {
          insert oppSplitsToInsert;
        }
        if ( !royaltiesToInsert.isEmpty() ) {
          insert royaltiesToInsert;
        }
      }
      catch (DMLException ex) {
        system.debug('[OpportunityTriggerHandler: insertRelatedListOfClonnedOpp] Exception: ' + ex.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','insertRelatedListOfClonnedOpp', ex.getStackTraceString(), ex);
      }
  }

  // Method to fetch the fields related to an Object to create SQL query.
  String fetchObjectFields ( String objName ) {
    Schema.DescribeSObjectResult objDesc = DescribeUtility.getObjectDescribe(objName);
    Map<String, Schema.Sobjectfield> fieldSetMap = objDesc.fields.getMap();
    String fieldString = '';

    for (String str : fieldSetMap.keySet()) {
      fieldString += str +',';
    }

    fieldString = fieldString.substring(0, fieldString.length()-1);
    return fieldString;
  }


 // Return the appropriate class instance based on className
  public static OpportunityInterface newClassInstance() {
    Type t;
    //String groupName = BusinessUnitUtility.getBusinessUnit(UserInfo.getUserId());

    if (String.isNotBlank(groupName) && groupName.equalsIgnoreCase(Constants.EDQ)) {
      t = Type.forName('OpportunityTriggerHandler_EDQ');
    }
    else {
      t = Type.forName('OpportunityTriggerHandler');
    }
    return (OpportunityInterface) t.newInstance();
  }





  public static void checkForRetentionAfterTypeChange ( map<Id,Opportunity> newMap, map<Id,Opportunity> oldMap  ) {
    List<Opportunity> changedToCredited = new List<Opportunity> ();
    List<Opportunity> changedOwnerOpps = new List<Opportunity> ();
    set<Id> changedToCreditedIds =  new set<Id>();
    for( Opportunity opp : newMap.values() ) {
      if ( oldMap != null  && opp.StageName == Constants.OPPTY_STAGE_7
                           && opp.StageName != oldMap.get(opp.ID).StageName ) {
        continue;
      }
      else if ( oldMap != null && opp.Type == Constants.ORDER_TYPE_CREDITED
                               && opp.Type != oldMap.get(opp.ID).Type ) {
        changedToCredited.add(opp);
        changedToCreditedIds.add(opp.Id);
      }
      // NS 26/Nov/2014  - check if the ownerId of Opp is changed.
      if ( oldMap != null && opp.OwnerId != oldMap.get(opp.ID).OwnerId ) {
        system.debug('*******checkForRetentionAfterTypeChange ::::::::'+newMap);
        changedOwnerOpps.add (opp) ;
      }
    }
    if ( !changedToCredited.isEmpty() ) {
      Set<String> callidusNumberSet = new Set<String>();
      // NS- commented, because we will be using OpportunityId to remove the related Retention Line Items
      /*for ( OpportunityLineItem oli : [SELECT o.Start_Date__c, o.OpportunityId, o.Id,
                                              o.End_Date__c, o.EDQ_Margin__c, o.Order_Type__c,
                                              o.Opportunity.Type,o.Item_Number__c, o.Part_Number__c
                                       FROM OpportunityLineItem o
                                       WHERE OpportunityId IN :changedToCredited]) {
        callidusNumberSet.add(oli.OpportunityId +'~' + oli.Part_Number__c);
      }*/
      Boolean isDeleted = RetentionUtility.removeRetentionLineItems ( changedToCreditedIds);
    }
    if ( !changedOwnerOpps.isEmpty() ) {
      RetentionUtility.updateRetentionLineOpportunityOwner ( changedOwnerOpps );
    }
  }

  //=============================================================================================
  // T-364931 : Method to check Oppty's ContactRole to Have Contact Addresses
  //=============================================================================================
  public virtual void validateOpptyConAddressOnClosedWon_NonFreeTrial(List<Opportunity> closedWonOpportunities) {
    String contactsWithErrors = '';
    Set<Id> oppIds = new Set<Id>();
    Map<String, String> contactIdToName = new Map<String, String>();
    Map<Id, Boolean> oppConIdMapToConAddress = new Map<Id, Boolean>();
    Map<Id, Set<Id>> contactIdToOpp = new Map<Id, Set<Id>>();
    String oppRecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_OPPORTUNITY, Constants.RECORDTYPE_STANDARDS);

    for (Opportunity opp : closedWonOpportunities) {
      //Check for records with RT = "Standard" (make sure that this runs before the RT is changed to "Read Only")
      if (opp.RecordTypeId == oppRecordTypeId && opp.Type <> Constants.OPPTY_TYPE_FREE_TRIAL) {
        oppIds.add(opp.Id);
      }
    }

    lstOppConRole = null;
    lstOppConRole = getOppConRoleRecord(oppIds);

    //T-368846
    for (OpportunityContactRole ocr : lstOppConRole /*[SELECT Id, Role, ContactId, Contact.Name, OpportunityId
                                       FROM OpportunityContactRole
                                       WHERE OpportunityId IN :oppIds
                                       AND ContactId != null ]*/) {
      contactIdToName.put(ocr.ContactId, ocr.Contact.Name);
      if (!contactIdToOpp.containsKey(ocr.OpportunityId)) {
        contactIdToOpp.put(ocr.OpportunityId, new Set<Id>());
      }
      contactIdToOpp.get(ocr.OpportunityId).add(ocr.ContactId);
    }

    //query for all the Contacts attached along with the Number_Of_Addresses__c , Contact_Addresses__r
    for (Contact con : [SELECT Id, Name, Number_of_Registered_Address__c
                        FROM Contact
                        WHERE Id IN :contactIdToName.keySet()]) {
      oppConIdMapToConAddress.put(con.Id, true);
      if (con.Number_of_Registered_Address__c == 0) {
        oppConIdMapToConAddress.put(con.Id, false);
        contactsWithErrors += '\n'+ contactIdToName.get(con.Id);
      }
    }

     for (Opportunity opp : closedWonOpportunities) {
       if (contactIdToOpp.get(opp.Id) != null) {
         Set<Id> contacts = contactIdToOpp.get(opp.Id);
         for (Id contactId: contacts) {
           if (oppConIdMapToConAddress.get(contactId) != null &&
               oppConIdMapToConAddress.get(contactId) == false) {
              opp.addError(label.OPPTY_ERR_MISSING_CONTACT_ADDRESS + ' ' + contactsWithErrors);
            }
         }
      }
    }
  }

  //============================================================================
  //T-368846: Method to get OpportunityContactRole records
  //============================================================================
  private static List<OpportunityContactRole> getOppConRoleRecord(Set<ID> oppIDs) {
    // Noopur : added the check for list size.
    if (lstOppConRole == null || lstOppConRole.size() == 0) {
      lstOppConRole = [SELECT Id, Role, ContactId, Contact.Name, OpportunityId, IsPrimary
                     FROM OpportunityContactRole
                     WHERE OpportunityId IN :oppIDs
                     AND ContactId != null ];             
    }
    return lstOppConRole;
  }

  //=============================================================================================
  // T-366560 : Method to validate Oppty's Account have Saas Contacts
  //=============================================================================================
  public virtual void validateOpptyAccWithSaasContact(List<Opportunity> closedWonOpportunities) {
    Set<Id> accIds = new Set<Id>();
    Set<Id> SaaSAccountsWithSaaSContacts = new Set<Id>();

    for (Opportunity opp : closedWonOpportunities) {
      if (opp.Count_of_SaaS_Line_Items__c > 0) {
        accIds.add(opp.AccountId);
      }
    }

    for (Contact con : [SELECT Id, SaaS__c, AccountId
                        FROM Contact
                        WHERE AccountId IN : accIds
                        AND SaaS__c = :true]) {
      SaaSAccountsWithSaaSContacts.add(con.AccountId);
    }

    for (Opportunity opp : closedWonOpportunities) {
      if (opp.Count_of_SaaS_Line_Items__c > 0 && !SaaSAccountsWithSaaSContacts.contains(opp.AccountId)) {
        opp.addError(Label.SaaS_OPP_NEEDS_SAAS_CONTACTS);
      }
    }


  }
  
  //============================================================================
  // T-372609 : Will sync all OppLineItem, line item schedule, and Opp's
  // Contract Start/End Date when the Close Date is moved, and the opp isn't
  // closed yet
  //============================================================================
  /* NLG Apr 21, 2015: ON HOLD
  @future
  private static void syncOppDates(Map<Id, Integer> mapOppIdToDaysShifted) {
    List<Opportunity> opptyLstToUpdate = new List<Opportunity>();
    List<OpportunityLineItem> olitoUpdate = new List<OpportunityLineItem>();
    Set<ID> oliIDs = new Set<ID>();

    List<Opportunity> lstOppty = new list<Opportunity> (
                                     [SELECT Id, Contract_Start_Date__c, Contract_End_Date__c,
                                            (SELECT Id, Start_Date__c, End_Date__c FROM OpportunityLineItems)
                                      FROM Opportunity 
                                      WHERE Id IN :mapOppIdToDaysShifted.keyset()] );
    
    //================Updating Opportunities================
    for (Opportunity opp : lstOppty) {
      opp = calculateOppDate(opp, mapOppIdToDaysShifted.get(opp.Id), true);
      opptyLstToUpdate.add(opp);
    }

    try {
      if (!opptyLstToUpdate.isEmpty()) {
        update opptyLstToUpdate;
      }
    } catch (Dmlexception ex) {
        System.debug('[OpportunityTriggerHandler:syncOppDates]'+ex.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','syncOppDates', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          opptyLstToUpdate.get(0).addError(ex.getDmlMessage(i));
        }
     } 

    //================Updating Opportunity Line Items================
    for (Opportunity opp : lstOppty) {
      opp = syncOLIDates(opp, mapOppIdToDaysShifted.get(opp.Id));
      olitoUpdate.addAll(opp.OpportunityLineItems);
    }

    try {
      if (!olitoUpdate.isEmpty()) {
        update olitoUpdate;
      }
    }catch (Dmlexception ex) {
        System.debug('[OpportunityTriggerHandler:syncOppDates]'+ex.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','syncOppDates', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          olitoUpdate.get(0).addError(ex.getDmlMessage(i));
        }
    }

    //================Updating Line Item Schedules================
    List<OpportunityLineItemSchedule> olisToUpdate = syncOLISdates(oliToUpdate, mapOppIdToDaysShifted);

    try {
      if (!olisToUpdate.isEmpty()) {
        update olisToUpdate;
      }
    } catch (Dmlexception ex) {
        System.debug('[OpportunityTriggerHandler:syncOppDates]'+ex.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','syncOppDates', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          olisToUpdate.get(0).addError(ex.getDmlMessage(i));
        }
    }
     opptyLstToUpdate = new List<Opportunity>();

    // Updates the second date field of the opportunity
    for (Opportunity opp : lstOppty) {
      opp = calculateOppDate(opp, mapOppIdToDaysShifted.get(opp.Id), false);
      opptyLstToUpdate.add(opp);
    }
    try {
      if (!opptyLstToUpdate.isEmpty()) {
        update opptyLstToUpdate;
      }
    }catch (Dmlexception ex) {
        System.debug('[OpportunityTriggerHandler:syncOppDates]'+ex.getMessage());
        ApexLogHandler.createLogAndSave('OpportunityTriggerHandler','syncOppDates', ex.getStackTraceString(), ex);
        for (Integer i = 0; i < ex.getNumDml(); i++) {
          opptyLstToUpdate.get(0).addError(ex.getDmlMessage(i));
        }
    }
  }*/
  
  
  //============================================================================
  // This method is to recalculate the opp start/end date
  // There is a validation on the OLI.Start/End Date requiring the OLI.Start/End date to be within the opp.Start/End date.
  // As a result, this is a 2-step process, to first 'enlarge' the start/end period, and then to reduce it to the correct date
  //============================================================================
  public static Opportunity calculateOppDate(Opportunity opp, Integer noOfDays, Boolean firstPass) {
    system.debug('\n[OpportunityTriggerHandler: calculateOppDate]===noOfDays>>>' +noOfDays);
    if ((noOfDays < 0 && firstPass) || (noOfDays > 0 && !firstPass)) {
        opp.Contract_Start_Date__c = opp.Contract_Start_Date__c.addDays(noOfDays);
    }
    else if ((noOfDays > 0 && firstPass) || (noOfDays < 0 && !firstPass)) {
        opp.Contract_End_Date__c = opp.Contract_End_Date__c.addDays(noOfDays);
    }
    system.debug('\n[OpportunityTriggerHandler: calculateOppDate]===opp>>>Result:::' +opp);
    return opp;
  }
  
  //============================================================================
  // This will shift the OLI's Start/End date by the number of days specified as
  // a parameter
  //============================================================================
  public static Opportunity syncOLIDates(Opportunity opp, Integer noOfDays) { 
    system.debug('\n[OpportunityTriggerHandler: syncOLIDates]===noOfDays>>>' +noOfDays);  
    for (OpportunityLineItem oli : opp.OpportunityLineItems) {
        oli.Start_Date__c = oli.Start_Date__c.addDays(noOfDays);
        oli.End_Date__c = oli.End_Date__c.addDays(noOfDays);
    }
    system.debug('\n[OpportunityTriggerHandler: syncOLIDates]===OLI>>>Result' +opp.OpportunityLineItems); 
    return opp;
  }

  //============================================================================
  // This will shift the OLI Schedule's date by the number of days specified as
  // a parameter
  //============================================================================
  private static List<OpportunityLineItemSchedule> syncOLISdates(List<OpportunityLineItem> oppLineItems,
                                                                 Map<Id, Integer> mapOppIdToDaysShifted) {
    List<OpportunityLineItemSchedule> olisToUpdate = new List<OpportunityLineItemSchedule>();
    for (OpportunityLineItemSchedule olis: [SELECT Id, ScheduleDate, OpportunityLineItem.OpportunityId
                                            FROM OpportunityLineItemSchedule
                                            WHERE OpportunityLineItemId in: oppLineItems
                                            ORDER BY OpportunityLineItem.OpportunityId]) {
      Integer shiftByDays = mapOppIdToDaysShifted.get(olis.OpportunityLineItem.OpportunityId);
      if (shiftByDays != null && shiftByDays != 0) {
        olis.ScheduleDate = olis.ScheduleDate.addDays(shiftByDays);
        olisToUpdate.add(olis);
      }
    }
    return olisToUpdate;
  }
  
  //****************************************************************
  // Case #00583716 - If renewal contact added, copy to Opp
  //****************************************************************
//  @future
  /*public static void addContacttoOpportunity(set<id> oppids){
    //isRecursive = true;
    List<Opportunity> updateOppList = new List<opportunity>();
    system.debug('code start');
    for(Opportunity opp:[select id, Renewal_Contact__c,(select id,role,contactid from opportunitycontactroles where Role='Renewals') from opportunity where id in :oppids]) {
      if(opp.opportunitycontactroles<>null &&
         opp.opportunitycontactroles.size()==1 &&
         opp.opportunitycontactroles[0].contactid<>opp.Renewal_Contact__c) {
        updateOppList.add(new Opportunity(id=opp.id,Renewal_Contact__c=opp.opportunitycontactroles[0].contactid));
      }
    }
    update updateOppList;
  }*/

 
  //============================================================================
  // T-313548 : methods implemented from OpportunityInterface
  //============================================================================

  public virtual void populateInvoiceToEndUser_OnClosedWon(List<Opportunity> closedWonOpportunities ,List<Opportunity> newList) {
  }

  //public virtual  void validateOnePurchaseLedger_OpptyConRole(List<Opportunity> closedWonOpportunities, List<Opportunity> newList){} T-326540

  public virtual void createOppContactRoles_RenewalOpps(Map<Id, Opportunity> newMap) {}

  public virtual void validateOpportunityContactAddressOnClosedWon(List<Opportunity> closedWonOpportunities ,List<Opportunity> newList) {}
  public virtual void validateOppRelatedRecordsData (List<Opportunity> closedWonOpportunies, List<Opportunity> newList) {}

  // I-138684
  public virtual List<Opportunity> validateProductsData(List<Opportunity> closedWonOpportunities, List<Opportunity> newList){
    return closedWonOpportunities;
  }

 // T-321616 : Method to check if the opportunity type is "Renewal" and then create line items for it
 public virtual void createOppLineItemsForRenewal ( List<Opportunity> newList ) {
 }

}