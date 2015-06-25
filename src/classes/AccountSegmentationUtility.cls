/**=====================================================================
 * Appirio, Inc
 * Name: AccountSegmentationUtility
 * Description: T-372668: Account Segmentation: @Future utility method
 *              that will recalculate the rollup amounts on a specific set
 *              of Segments based on the segment Names. Use of a future
 *              method as this is called by the opp trigger which has a lot
 *              queris already
 *
 * Created Date: March 23th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 * Mar 26th, 2015           Nathalie Le Guay (Appirio)  Break into methods
 * Mar 31st, 2015           Arpita Bose (Appirio)       T-373930: Added method updateOpportunitySegments()
 * Apr 06th, 2015           Noopur (Appirio)            Modified the class to change the calculation for closedwonAmount.
 *                                                      Its based on Order Split now. Added methods populateSegmentOrderMap() and addToSegmentOrderMap()
 * Apr 07th, 2015           Noopur (Appirio)            Added the code to update the Account Segment for which there are no related Opportunities.
 * Apr 09th, 2015           Arpita Bose                 Added method createAccountSegmentRecordforUser() to be called from UserTriggerHandler
 * Apr 14th, 2015           Naresh                      Updated method segmentRecalculation() to fix issues given by apex logger.
 * Apr 15th, 2015           Nathalie Le Guay            Change AccountSegmentMap key to be AccountId + segmentType + segmentValue
 *                                                      I-155503: Populate Parent_Account_Segment__c field (using while loop)
 *                                                      T-376294: Need to create Account Segments for Orders as well
 * Apr 23rd, 2015           Suminder Singh              I-156673 : Added map for ownersegment fields
 ======================================================================*/
public class AccountSegmentationUtility {
  private static map<Id,List<Opportunity>> segmentOpportunityMap = new map<Id,List<Opportunity>>();
  private static map<Id,List<Order__c>> segmentOrderMap = new map<Id,List<Order__c>>();
  // User fields used for segmentation
  public static Map<String, String> userSegmentFieldNames = new Map<String, String>{
                                                  'Global_Business_Line__c'=>'Global Business Line',
                                                  'Business_Line__c'=>'Business Line',
                                                  'Business_Unit__c'=>'Business Unit',
                                                  'Region__c'=>'Region',
                                                  'Country__c'=>'Country'
                                                 };
//owner fields used for segmentation
public static Map<String, String> ownerSegmentFieldNames = new Map<String, String>{
                                                  'Owner_GBL_on_Opp_Close_Date__c'=>'Global Business Line',
                                                  'Owner_BL_on_Opp_Close_Date__c'=>'Business Line',
                                                  'Owner_BU_on_Opp_Close_Date__c'=>'Business Unit',
                                                  'Owner_Region_on_Opp_Close_Date__c'=>'Region',
                                                  'Owner_Country_on_Opp_Close_Date__c'=>'Country'
                                                 };

public static Map<String, String> ordOwnerSegmentFieldNames = new Map<String, String>{
                                                  'Owner_GBL_on_Order_Create_Date__c'=>'Global Business Line',
                                                  'Owner_BL_on_Order_Create_Date__c'=>'Business Line',
                                                  'Owner_BU_on_Order_Create_Date__c'=>'Business Unit',
                                                  'Owner_Region_on_Order_Create_Date__c'=>'Region',
                                                  'Owner_Country_on_Order_Create_Date__c'=>'Country'
                                                 };

  //====================================================================================//
  // The 4 structures below support the Opp/Order trigger when populating the Segment* fields
  public static Map<String, String> userToOppOrderField = new Map<String, String>{
    'Global_Business_Line__c' => 'Segment_Global_Business_Line__c',
    'Business_Line__c' => 'Segment_Business_Line__c',
    'Business_Unit__c' => 'Segment_Business_Unit__c',
    'Region__c' => 'Segment_Region__c',
    'Country__c' => 'Segment_Country__c'
  };
  
  //The 4 structures below support the Opp/Order trigger when populating the Segment* fields
  public static Map<String, String> ownerToOppOrderField = new Map<String, String>{
    'Owner_GBL_on_Opp_Close_Date__c' => 'Segment_Global_Business_Line__c',
    'Owner_BL_on_Opp_Close_Date__c' => 'Segment_Business_Line__c',
    'Owner_BU_on_Opp_Close_Date__c' => 'Segment_Business_Unit__c',
    'Owner_Region_on_Opp_Close_Date__c' => 'Segment_Region__c',
    'Owner_Country_on_Opp_Close_Date__c' => 'Segment_Country__c'
  };
   public static Map<String, String> ordOwnerToOppOrderField = new Map<String, String>{
    'Owner_GBL_on_Order_Create_Date__c' => 'Segment_Global_Business_Line__c',
    'Owner_BL_on_Order_Create_Date__c' => 'Segment_Business_Line__c',
    'Owner_BU_on_Order_Create_Date__c' => 'Segment_Business_Unit__c',
    'Owner_Region_on_Order_Create_Date__c' => 'Segment_Region__c',
    'Owner_Country_on_Order_Create_Date__c' => 'Segment_Country__c'
  };
  public static Set<String> level3Fields = new Set<String>{
                                                   'Global_Business_Line__c',
                                                   'Region__c', 'Country__c'
                                                   };
  public static Set<String> level2Fields = new Set<String>{'Business_Line__c'};
  public static Set<String> level1Fields = new Set<String>{'Business_Unit__c'};
  private static Integer level = 3;
  
  public static Set<String> level3OwnerFields = new Set<String>{
                                                   'Owner_GBL_on_Opp_Close_Date__c',
                                                   'Owner_Region_on_Opp_Close_Date__c', 'Owner_Country_on_Opp_Close_Date__c'
                                                   };
  public static Set<String> level2OwnerFields = new Set<String>{'Owner_BL_on_Opp_Close_Date__c'};
  public static Set<String> level1OwnerFields = new Set<String>{'Owner_BU_on_Opp_Close_Date__c'};
  private static Integer levelOwner = 3;
  
   public static Set<String> level3OrdOwnerFields = new Set<String>{
                                                   'Owner_GBL_on_Order_Create_Date__c',
                                                   'Owner_Region_on_Order_Create_Date__c', 'Owner_Country_on_Order_Create_Date__c'
                                                   };
  public static Set<String> level2OrdOwnerFields = new Set<String>{'Owner_BL_on_Order_Create_Date__c'};
  public static Set<String> level1OrdOwnerFields = new Set<String>{'Owner_BU_on_Order_Create_Date__c'};
  private static Integer levelOrdOwner = 3;
  //====================================================================================//


  //===========================================================================
  // Method to process the recalculation of 'rollups' on a specific set of
  // Segments
  //===========================================================================
  @future
  public static void segmentationMaintenance(Set<String> segmentNames, Set<String> segmentIds) {
    try {
      map<Id,Account_Segment__c> accountSegmentMap = new map<Id,Account_Segment__c>();
      // create a map of Account Segment Id and record
      if (segmentNames != null || segmentIds != null) {
        if (segmentIds != null) {
          for ( Account_Segment__c accSegment : [SELECT Account__c, Id, Total_Won__c, Total_Open_Pipeline__c
                                               FROM Account_Segment__c
                                               WHERE Id IN :segmentIds] ) {
            accountSegmentMap.put( accSegment.Id, accSegment);
          }
        } else {
          for ( Account_Segment__c accSegment : [SELECT Account__c, Id, Total_Won__c, Total_Open_Pipeline__c
                                               FROM Account_Segment__c
                                               WHERE Value__c IN :segmentNames] ) {
            accountSegmentMap.put( accSegment.Id, accSegment);
          }
        }
        if ( accountSegmentMap.size() > 0 ) {
          List<Account_Segment__c> updatedSegments = segmentRecalculation(accountSegmentMap);
          if ( updatedSegments != null && updatedSegments.size() > 0 ) {
            update updatedSegments;
          }
        }
      }
    }
    catch (Exception e) {
      System.debug('\n[AccountSegmentationUtility: segmentationMaintenance]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountSegmentationUtility','segmentationMaintenance', e.getStackTraceString(), e);
    }
  }

  //===========================================================================
  // Method to recalculate the Amount related fields of the Account Segments sent as argument
  //===========================================================================
  public static List<Account_Segment__c> segmentRecalculation(Map<Id, Account_Segment__c> accountSegmentMap) {
    segmentOpportunityMap = new map<Id,List<Opportunity>>();
    segmentOrderMap = new map<Id,List<Order__c>>();

    try {
      System.debug('~*~*~accountSegmentMap~~~~'+accountSegmentMap);
      if (accountSegmentMap == null) {
        return null;
      }

      Map<Id, Account_Segment__c> updatedSegments = new Map<Id, Account_Segment__c>();
      String orderReadOnlyRT_ID = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);

      // Get the Opp/Order records to perform the recalculation
      populateSegmentOppMap(accountSegmentMap);
      populateSegmentOrderMap(accountSegmentMap);

      Set<Id> segmentIds = new Set<Id>();
      segmentIds.addAll(segmentOpportunityMap.keySet());
      segmentIds.addAll(segmentOrderMap.keySet());

      Boolean isOrderProcessed = false;
      Boolean isOpportunityProcessed = false;
        // iterate the map and do the calculation for each Account Segment
      for ( Id segmentId : segmentIds ) {
        isOpportunityProcessed = isOrderProcessed = false;
        Account_Segment__c accSegment = accountSegmentMap.get(segmentId);
        system.debug('\n[AccountSegmentationUtility: segmentRecalculation] Segment: ' + segmentId + '==>' + accSegment);
        if ( accSegment == null ) {
            continue;
        }
        System.debug('~*~*~accSegment~~~~'+accSegment);
        Double pipelineAmount = 0;
        Double closedWonAmount = 0;
        Double totalAmount = 0;
        if (segmentOpportunityMap != null && segmentOpportunityMap.containsKey(segmentId)) {
          for ( Opportunity opp : segmentOpportunityMap.get(segmentId) ) {
            if ( !opp.IsClosed && opp.Amount_Corp__c != null) {
              pipelineAmount += opp.Amount_Corp__c;
              isOpportunityProcessed = true;
            }
          }
        }
        Boolean isClient = false;
        system.debug('---segmentOrderMap----'+segmentOrderMap+'==segmentId=='+segmentId);
        if( segmentOrderMap != null && segmentOrderMap.containsKey(segmentId) ){
          for ( Order__c ord : segmentOrderMap.get(segmentId) ) {
            if (ord.RecordTypeID == orderReadOnlyRT_ID) {
                closedWonAmount += ord.Amount_Corp__c != null ? ord.Amount_Corp__c:0.0;
                if ( ord.Contract_End_Date__c > Date.today().addYears(-1) ) {
                  isClient = true;
                }
                isOrderProcessed = true;
            }
          }
          System.debug('~~~final amount of won~~~'+closedWonAmount);
        }
        if (isOpportunityProcessed || isOrderProcessed) {
            accSegment.Total_Won__c = closedWonAmount;
            accSegment.Total_Open_Pipeline__c = pipelineAmount;
            if ( isClient) {
              accSegment.Relationship_Type__c = Constants.BU_RELATIONSHIP_TYPE_CLIENT;
            } else if (!isClient && accSegment.Total_Won__c > 0) {
              accSegment.Relationship_Type__c = Constants.BU_RELATIONSHIP_TYPE_FORMER_CLIENT;
            } else if (accSegment.Total_Won__c == 0) {
              accSegment.Relationship_Type__c = Constants.BU_RELATIONSHIP_TYPE_PROSPECT;
            }
            updatedSegments.put(accSegment.Id, accSegment);
        }
      }
      //if no opportunity is related to the Account Segment, populate zero in the amount fields
      for ( String accSegId : accountSegmentMap.keySet() ) {
        if( !segmentOpportunityMap.containsKey(accSegId) ) {
          Account_Segment__c accSegment = accountSegmentMap.get(accSegId);
          accSegment.Total_Open_Pipeline__c = 0.00;
          updatedSegments.put(accSegment.Id, accSegment);
        }
        if( !segmentOrderMap.containsKey(accSegId) ) {
          Account_Segment__c accSegment = accountSegmentMap.get(accSegId);
          accSegment.Total_Won__c = 0.00;
          updatedSegments.put(accSegment.Id, accSegment);
        }
      }
      return updatedSegments.values();
    }
    catch(Exception e){
      System.debug('\n[AccountSegmentationUtility: segmentationMaintenance]: ['+e.getMessage()+']]');
      apexLogHandler.createLogAndSave('AccountSegmentationUtility','segmentationMaintenance', e.getStackTraceString(), e);
      return null;
    }
  }

  //===========================================================================
  // Method to query and populate the map
  //===========================================================================
  private static void populateSegmentOppMap(map<Id,Account_Segment__c> accountSegmentMap) {
    // fetch all the related Opportunities and create a map of Account Segment Id and List of Opportunities
    for ( Opportunity opp : [SELECT Id, AccountId, Segment_Business_Line__c, Segment_Business_Unit__c,
                                  Segment_Global_Business_Line__c, Segment_Region__c, Segment_Country__c,
                                  Amount, isClosed, isWon, Name, Amount_Corp__c
                           FROM Opportunity
                           WHERE isClosed = false AND ((Segment_Business_Line__c IN :accountSegmentMap.keySet())
                              OR (Segment_Business_Unit__c IN :accountSegmentMap.keySet())
                              OR (Segment_Global_Business_Line__c IN :accountSegmentMap.keySet())
                              OR (Segment_Region__c IN :accountSegmentMap.keySet())
                              OR (Segment_Country__c IN :accountSegmentMap.keySet()))]) {
      addToSegmentMap(opp.Segment_Business_Line__c, opp);
      addToSegmentMap(opp.Segment_Business_Unit__c, opp);
      addToSegmentMap(opp.Segment_Global_Business_Line__c, opp);
      addToSegmentMap(opp.Segment_Region__c, opp);
      addToSegmentMap(opp.Segment_Country__c, opp);
    }
    System.debug('\n[AccountSegmentationUtility: populateSegmentOppMap] FINAL MAP \n' + segmentOpportunityMap);
  }

  //===========================================================================
  // Method to add items (Opps) to the segment map, based on the segment name
  //===========================================================================
  private static void addToSegmentMap(Id segmentName, Opportunity opp) {
    if ( segmentName != null) {
      if ( segmentOpportunityMap.containsKey(segmentName) ) {
        segmentOpportunityMap.get(segmentName).add(opp);
      }
      else {
        segmentOpportunityMap.put(segmentName, new List<Opportunity>{opp});
        System.debug('\n[AccountSegmentationUtility: addToSegmentMap] Added entry \n' + segmentName + '==>' + opp.Name);
      }
    }
  }


  //===========================================================================
  // Method to query and populate the map od Segment and Order
  //===========================================================================
  private static void populateSegmentOrderMap(map<Id,Account_Segment__c> accountSegmentMap) {
    // fetch all the related Order and create a map of Account Segment Id and List of Order
    String readOnlyRT = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
    for ( Order__c ord : [SELECT Id, Segment_Country__c, Segment_Region__c, RecordType.DeveloperName, Contract_End_Date__c,
                                            Segment_Global_Business_Line__c, Segment_Business_Line__c, RecordTypeId,
                                            Segment_Business_Unit__c, Amount_Corp__c
                                     FROM Order__c
                                     WHERE RecordTypeId = :readOnlyRT
                                        AND Cancellation_Date__c = null
                                        AND Type__c !=: Constants.ORDER_TYPE_CREDITED
                                        AND Type__c !=: Constants.ORDER_TYPE_CREDIT_NOTE
                                        AND ((Segment_Business_Line__c IN :accountSegmentMap.keySet())
                                        OR (Segment_Business_Unit__c IN :accountSegmentMap.keySet())
                                        OR (Segment_Global_Business_Line__c IN :accountSegmentMap.keySet())
                                        OR (Segment_Region__c IN :accountSegmentMap.keySet())
                                        OR (Segment_Country__c IN :accountSegmentMap.keySet()))]) {
      addToSegmentOrderMap(ord.Segment_Business_Line__c, ord);
      addToSegmentOrderMap(ord.Segment_Business_Unit__c, ord);
      addToSegmentOrderMap(ord.Segment_Global_Business_Line__c, ord);
      addToSegmentOrderMap(ord.Segment_Region__c, ord);
      addToSegmentOrderMap(ord.Segment_Country__c, ord);
      System.debug('~~~ord1.0~~~~'+ord);
    }
  }

  //===========================================================================
  // Method to add items (Order) to the segment Order map, based on the segment name
  //===========================================================================
  private static void addToSegmentOrderMap(Id segmentName, Order__c ord) {
    if ( segmentName != null) {
      if ( segmentOrderMap.containsKey(segmentName) ) {
        segmentOrderMap.get(segmentName).add(ord);
      }
      else {
        segmentOrderMap.put(segmentName, new List<Order__c>{ord});
      }
    }
  }



  //==========================================================================
  // T-373930:
  //==========================================================================
/*  public static void updateOpportunitySegments(Map<Id, User> newUsers, Map<Id, User> oldUsers){
    Set<ID> accIDs = new Set<ID>();
    Map<String, Account_Segment__c> segmentMap = new Map<String, Account_Segment__c>();
    Map<Id, Opportunity> mapOpptoUpdate = new Map<Id, Opportunity>();
    List<Opportunity> lstOppty = new List<Opportunity>();

    for (Opportunity opp : [SELECT Id, Name, OwnerId, AccountId, Segment_Business_Line__c, Segment_Business_Unit__c,
                                  Segment_Global_Business_Line__c, Segment_Region__c, Segment_Country__c,
                                  Segment_Global_Business_Line__r.Name, Segment_Business_Line__r.Value__c,
                                  Segment_Business_Unit__r.Value__c, Segment_Region__r.Name, Segment_Country__r.Name,
                                  Account.Name, Segment_Business_Unit__r.Name, Segment_Business_Line__r.Name,
                                  Segment_Global_Business_Line__r.Value__c, Segment_Region__r.Value__c,
                                  Segment_Country__r.Value__c, IsClosed
                            FROM Opportunity
                            WHERE OwnerId IN : newUsers.keySet() AND IsClosed = :false
                            /*AND Type <> :Constants.OPPTY_TYPE_FREE_TRIAL - NLG Apr 14th*/ //]) {
  /*    accIDs.add(opp.AccountId);
      lstOppty.add(opp);
    }
    System.debug('lstOppty>>>' +lstOppty);

    String segments = '';
    for (Account_Segment__c accSeg : [SELECT Name, Account__c, Id, Segment__c, Segment_Type__c, Value__c, Segment__r.Name, Segment__r.Type__c
                                      FROM Account_Segment__c
                                      WHERE Account__c IN :accIDs]) {
      segmentMap.put(accSeg.Account__c + '-' + accSeg.Segment__r.Name, accSeg);
      segments += '\n' + accSeg;
    }
    system.debug('segmentMap>>>' +segmentMap);


    String debugString = segments + '===================================== ';
    //loop through Opps
    for (Opportunity opp : lstOppty) {
      User newUser =  newUsers.get(opp.ownerId);
      User oldUser =  oldUsers.get(opp.ownerId);
      System.debug('===oppdebug===='+opp);
      System.debug('===newUser===='+newUser);
      System.debug('===oldUser===='+newUser);

      String keyGBL =  opp.AccountId + '-' + Constants.ACCOUNT_SEGMENT_GBL + '-' + newUser.Global_Business_Line__c;
      System.debug(keyGBL+'~~~~segmentMap~~~~'+segmentMap);

      if (opp.Segment_Global_Business_Line__r.Value__c != newUser.Global_Business_Line__c &&
              newUser.Global_Business_Line__c <> null && segmentMap.containsKey(keyGBL)) {
         opp.Segment_Global_Business_Line__c = segmentMap.get(keyGBL).Id;
         mapOpptoUpdate.put(opp.Id, opp);
      }

      String keyBL =  opp.AccountId + '-' + Constants.ACCOUNT_SEGMENT_BL + '-' + newUser.Business_Line__c;
      System.debug(keyBL+'~~keyBL~~segmentMap~~~~'+segmentMap);
      if (opp.Segment_Business_Line__r.Value__c != newUser.Business_Line__c &&
              newUser.Business_Line__c <> null && segmentMap.containsKey(keyBL)) {
         opp.Segment_Business_Line__c = segmentMap.get(keyBL).Id;
         mapOpptoUpdate.put(opp.Id, opp);
      }

      String keyBU =  opp.AccountId + '-' + Constants.ACCOUNT_SEGMENT_BU + '-' + newUser.Business_Unit__c;
      System.debug(keyBU+'~~keyBU~~segmentMap~~~~'+segmentMap);
      if (opp.Segment_Business_Unit__r.Value__c != newUser.Business_Unit__c &&
              newUser.Business_Unit__c <> null && segmentMap.containsKey(keyBU)) {
         opp.Segment_Business_Unit__c = segmentMap.get(keyBU).Id;
         mapOpptoUpdate.put(opp.Id, opp);
      }

      String keyRegion = opp.AccountId + '-' + Constants.ACCOUNT_SEGMENT_REGION + '-' + newUser.Region__c;

      if (opp.Segment_Region__r.Value__c != newUser.Region__c &&
              newUser.Region__c <> null && segmentMap.containsKey(keyRegion)) {
         opp.Segment_Region__c = segmentMap.get(keyRegion).Id;
         mapOpptoUpdate.put(opp.Id, opp);
      }

      String keyCountry = opp.AccountId + '-' + Constants.ACCOUNT_SEGMENT_COUNTRY + '-' + newUser.Country__c;

      //debugString += '~~~NameOppty:'+opp.Name + ' ====> ' + (opp.Segment_Country__r.Value__c != newUser.Country__c) +'===>'+(newUser.Country__c <> null) + '====>'+segmentMap.containsKey(keyCountry);
      if (opp.Segment_Country__r.Value__c != newUser.Country__c &&
              newUser.Country__c <> null && segmentMap.containsKey(keyCountry)) {

         opp.Segment_Country__c = segmentMap.get(keyCountry).Id;
         mapOpptoUpdate.put(opp.Id, opp);
      }
   }
   //System.assertEquals('~~~~~~'+mapOpptoUpdate, '#####'+debugString);
   // update opps
   try {
     update mapOpptoUpdate.values();
   } catch (DMLException ex) {
          ApexLogHandler.createLogAndSave('AccountSegmentationUtility','updateOpportunitySegments', ex.getStackTraceString(), ex);
          for (Integer i = 0; i < ex.getNumDml(); i++) {
            System.debug('\nError when updating Opportunity #' + i);
            newUsers.values().get(0).addError(ex.getDmlMessage(i));
          }
   }
  }*/


  //==========================================================================
  // T-373930: populate the Order's Segment fields
  //==========================================================================
 /* public static void updateOrderSegments(Map<Id, User> newUsers, Map<Id, User> oldUsers){
    Set<ID> accIDs = new Set<ID>();
    Map<String, Account_Segment__c> segmentMap = new Map<String, Account_Segment__c>();
    Map<Id, Order__c> mapOrdersToUpdate = new Map<Id, Order__c>();
    List<Order__c> orderList = new List<Order__c>();

    for (Order__c ordr : [SELECT Id, OwnerId, Account__c, Segment_Business_Line__c, Segment_Business_Unit__c,
                                  Segment_Global_Business_Line__c, Segment_Region__c, Segment_Country__c,
                                  Segment_Global_Business_Line__r.Name, Segment_Business_Line__r.Value__c,
                                  Segment_Business_Unit__r.Value__c, Segment_Region__r.Name, Segment_Country__r.Name,
                                  Account__r.Name, Segment_Business_Unit__r.Name, Segment_Business_Line__r.Name,
                                  Segment_Global_Business_Line__r.Value__c, Segment_Region__r.Value__c,
                                  Segment_Country__r.Value__c, RecordType.Name
                            FROM Order__c
                            WHERE OwnerId IN : newUsers.keySet() AND RecordType.Name =: Constants.READ_ONLY]) {
      accIDs.add(ordr.Account__c);
      orderList.add(ordr);
    }
    system.debug('orderList>>>' +orderList);

    String segments = '';
    for (Account_Segment__c accSeg : [SELECT Name, Account__c, Id, Segment__c, Segment_Type__c, Value__c, Segment__r.Name
                                      FROM Account_Segment__c
                                      WHERE Account__c IN :accIDs]) {
      segmentMap.put(accSeg.Account__c + '-' + accSeg.Segment__r.Name, accSeg);
      segments += '\n' + accSeg;
    }

    //loop through Orders
    for (Order__c ordr : orderList) {
      User newUser =  newUsers.get(ordr.OwnerId);
      User oldUser =  oldUsers.get(ordr.OwnerId);

      String keyGBL =  ordr.Account__c + '-' + Constants.ACCOUNT_SEGMENT_GBL + '-' + newUser.Global_Business_Line__c;

      if (ordr.Segment_Global_Business_Line__r.Value__c != newUser.Global_Business_Line__c &&
              newUser.Global_Business_Line__c <> null && segmentMap.containsKey(keyGBL)) {
         ordr.Segment_Global_Business_Line__c = segmentMap.get(keyGBL).Id;
         mapOrdersToUpdate.put(ordr.Id, ordr);
      }

      String keyBL =  ordr.Account__c + '-' + Constants.ACCOUNT_SEGMENT_BL + '-' + newUser.Business_Line__c;
      if (ordr.Segment_Business_Line__r.Value__c != newUser.Business_Line__c &&
              newUser.Business_Line__c <> null && segmentMap.containsKey(keyBL)) {
         ordr.Segment_Business_Line__c = segmentMap.get(keyBL).Id;
         mapOrdersToUpdate.put(ordr.Id, ordr);
      }

      String keyBU =  ordr.Account__c + '-' + Constants.ACCOUNT_SEGMENT_BU + '-' + newUser.Business_Unit__c;
      if (ordr.Segment_Business_Unit__r.Value__c != newUser.Business_Unit__c &&
              newUser.Business_Unit__c <> null && segmentMap.containsKey(keyBU)) {
         ordr.Segment_Business_Unit__c = segmentMap.get(keyBU).Id;
         mapOrdersToUpdate.put(ordr.Id, ordr);
      }

      String keyRegion = ordr.Account__c + '-' + Constants.ACCOUNT_SEGMENT_REGION + '-' + newUser.Region__c;
      if (ordr.Segment_Region__r.Value__c != newUser.Region__c &&
              newUser.Region__c <> null && segmentMap.containsKey(keyRegion)) {
         ordr.Segment_Region__c = segmentMap.get(keyRegion).Id;
         mapOrdersToUpdate.put(ordr.Id, ordr);
      }

      String keyCountry = ordr.Account__c + '-' + Constants.ACCOUNT_SEGMENT_COUNTRY + '-' + newUser.Country__c;

      if (ordr.Segment_Country__r.Value__c != newUser.Country__c &&
              newUser.Country__c <> null && segmentMap.containsKey(keyCountry)) {
         ordr.Segment_Country__c = segmentMap.get(keyCountry).Id;
         mapOrdersToUpdate.put(ordr.Id, ordr);
      }
   }

   // update orders
   try {
     update mapOrdersToUpdate.values();
   } catch (DMLException ex) {
          ApexLogHandler.createLogAndSave('AccountSegmentationUtility','updateOpportunitySegments', ex.getStackTraceString(), ex);
          for (Integer i = 0; i < ex.getNumDml(); i++) {
            System.debug('\nError when updating Opportunity #' + i);
            newUsers.values().get(0).addError(ex.getDmlMessage(i));
          }
   }
  }*/


  //===========================================================================
  // populate segment map with AccountID and Segment Value as key and segment object
  //===========================================================================
  public static Set<String> populateSegmentMapAndOwnerMap (Set<ID> accountIDset, Map<ID, User> ownerMap,
                            Map<String, Account_Segment__c> accSegNameTo_AccountSegmentMap, Map<String, Id> parentMap, set<String> segmentValueSetForClosed) {
    Set<String> segmentValueSet = new Set<String>();

    for (User usr : [SELECT ID, Sales_Team__c, Sales_Sub_Team__c, Region__c, Business_Line__c,
                            Global_Business_Line__c, Country__c, Business_Unit__c
                     FROM User
                     WHERE ID IN: ownerMap.keySet()]) {

      segmentValueSet.add(usr.Business_Line__c);
      segmentValueSet.add(usr.Business_Unit__c);
      segmentValueSet.add(usr.Global_Business_Line__c);
      segmentValueSet.add(usr.Country__c);
      segmentValueSet.add(usr.Region__c);
      system.debug('\n[AccountSegmentationUtility: populateSegmentMapAndOwnerMap] User queried is: \n'+ usr);
      if (ownerMap.containsKey(usr.ID)) {
        ownerMap.put(usr.ID, usr);
      }
    }
    if ( segmentValueSetForClosed.size() > 0) {
    	for ( String segmentValue : segmentValueSetForClosed) {
    		segmentValueSet.add(segmentValue);
    	}
    }

    for (Account_Segment__c accSegment : [SELECT ID, Name, Account__c, Value__c, Segment__r.Name, Segment__r.Parent__r.Name,
                                                 Segment__r.Parent__r.Parent__r.Name
                                          FROM Account_Segment__c
                                          WHERE Account__c IN: accountIDset
                                            AND Segment__r.Value__c IN: segmentValueSet
                                             ]) {
      String keyOfMap = accSegment.Account__c + '-' + accSegment.Segment__r.Name;
      if (!accSegNameTo_AccountSegmentMap.containsKey(keyOfMap)) {
        accSegNameTo_AccountSegmentMap.put(keyOfMap, accSegment);
        parentMap.put(keyOfMap, accSegment.Id);
      }
    }
    return segmentValueSet;
  }

  //===========================================================================
  // Populates and returns a hierarchy map for the segment names in param
  //===========================================================================
  public static Map<String, Hierarchy__c> populateHierarchyMap(Set<String> segmentNames, Boolean queryAllHierarchy) {
    Map<String, Hierarchy__c> hierarchyMap = new Map<String, Hierarchy__c>();
    List<Hierarchy__c> hierarchies = new List<Hierarchy__c>();
    Set<String> segmentationLevels = new Set<String>();
    Set<String> parentsSegments = new Set<String>();

    String hierarchyMapString = '';

    // If method is called from code where all the values
    // in the hierarchy are already known (ex: we know the hierarchy values when calling from opp or order
    // trigger, as they are all gathered from the user record at once), then we only want to query those
    if (!queryAllHierarchy) {
      hierarchies =  [SELECT Id, Name, Value__c, Parent__c, Type__c,
                                            Parent__r.Value__c, Parent__r.Parent__c,
                                            Parent__r.Type__c, Parent__r.Name
                 FROM Hierarchy__c WHERE Value__c IN: segmentNames];
    }

    // Called from the user trigger,
    // where the update could be at the BU level, and the BL level might already be in the DB. In
    // that case, we need to query the existing account segment, which we do through the Hierarchy
    else {
      hierarchies =  [SELECT Id, Name, Value__c, Parent__c, Type__c,
                                            Parent__r.Value__c, Parent__r.Parent__c,
                                            Parent__r.Type__c, Parent__r.Name
                      FROM Hierarchy__c];
    }

    for (Hierarchy__c hr : hierarchies) {
      hierarchyMap.put(hr.Name, hr);
      hierarchyMapString += '\n' + hr.Name;
    }

    system.debug('\n[AccountSegmentationUtility: populateHierarchyMap]\n==> hierarchyMapString:'+hierarchyMapString);

    return hierarchyMap;
  }

  //===========================================================================
  // Populates and returns the account map for all account ids
  //===========================================================================
  public static Map<ID, Account> populateAccountMap(Set<Id> accountIds) {
    Map<ID, Account> accountMap = new Map<ID, Account>();
    for (Account acc : [SELECT ID, Name FROM Account WHERE ID IN : accountIds]) {
      accountMap.put(acc.ID, acc);
    }
    return accountMap;
  }




  //===========================================================================
  // Store Account Segments that are either in the db or to be created
  private static map<String, Account_Segment__c> accountSegmentMap;
  private static Map<String,Hierarchy__c> hierarchyMap ;
  private static Map<Id, String> accountMap;

  //===========================================================================
  // Method to create Account Segment record for User mapping with Segment
  //===========================================================================
  public static Map<String, Account_Segment__c> createAccountSegmentRecordforUser(Set<String> segmentValues, Map<Id, User> newUsers, Set<String> userFieldNameSet) {
    hierarchyMap = new Map<String,Hierarchy__c>();
    accountSegmentMap = new Map<String, Account_Segment__c>();
    List<Account_Segment__c> newAccountSegments = new List<Account_Segment__c>();
    List<Opportunity> lstOppty = new List<Opportunity>();
    List<Order__c> orderList = new List<Order__c>();
    accountMap = new Map<Id, String>();


    // Store Opp, Hierarchy and Account Segment in structures
    String accountSegmentMapString = '';
    String hierarchyMapString = '';

    for (Opportunity opp : [SELECT Id, OwnerId, Account.Id, Account.Name, IsClosed,
                                   Owner.Global_Business_Line__c, Owner.Business_Line__c,
                                   Owner.Business_Unit__c, Owner.Region__c, Owner.Country__c
                            FROM Opportunity
                            WHERE OwnerId in : newUsers.keySet()
                            AND isClosed = false]) {
      accountMap.put(opp.AccountId, opp.Account.Name);
      lstOppty.add(opp);
    }

    for (Order__c ordr : [SELECT Id, OwnerId, Account__r.Id, Account__r.Name, Account__c, RecordType.Name
                            FROM Order__c
                            WHERE OwnerId in: newUsers.keySet()]) {
      accountMap.put(ordr.Account__c, ordr.Account__r.Name);
      orderList.add(ordr);
    }
    set<Id> parentHierarchies = new set<Id>();
    hierarchyMap = populateHierarchyMap(segmentValues, true);

    for ( Account_Segment__c accSeg : [SELECT Id, Segment__c, Segment__r.Value__c, Name, Account__c, Account__r.Name, Segment__r.Name, Segment__r.Type__c
                                       FROM Account_Segment__c
                                       WHERE Account__c IN :accountMap.keySet()
                                       AND Segment__r.Name IN :hierarchyMap.keySet()]) {
      System.debug('\n[AccountSegmentationUtility: createAccountSegmentRecordforUser]\n==> accSeg: '+ accSeg);
      String key = accSeg.Account__c + '-' + accSeg.Segment__r.Name;
      //if ( segmentValues.contains(accSeg.Segment__r.Value__c) ) {
      if (!accountSegmentMap.keySet().contains(key)) {
        accountSegmentMap.put(key, accSeg);
        accountSegmentMapString += '\n' + key;
      }
    }

    system.debug('\n[AccountSegmentationUtility: createAccountSegmentRecordforUser]\n==> hierarchyMapString:'+hierarchyMapString);
    system.debug('\n[AccountSegmentationUtility: createAccountSegmentRecordforUser]\n==> accountSegmentMapString: '+ accountSegmentMapString);


    // This will create the 3 levels of Account Segment hierarchy
    while (level > 0) {
      processByLevel(lstOppty, orderList, newUsers);
      level--;
    }

    // Here we are populating the Opp Segment_* fields, now that all Account Segments have been created
    for (Opportunity opp: lstOppty) {
      User ownerUser = newUsers.get(opp.OwnerId);
      populateOppSegmentFields(opp, ownerUser, userToOppOrderField.keySet());
    }
    try {
      update lstOppty;
    } catch (Dmlexception ex) {
      ApexLogHandler.createLogAndSave('AccountSegmentationUtility','createAccountSegmentRecordforUser', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        newUsers.values().get(0).addError(ex.getDmlMessage(i)); 
      }
    }
    
    // Here we are populating the Opp Segment_* fields, now that all Account Segments have been created
    for (Order__c ordr: orderList) {
    	if ( ordr.RecordType.Name == 'Read Only' ) {
    		continue;
    	}
      User ownerUser = newUsers.get(ordr.OwnerId);
      populateOrderSegmentFields(ordr, ownerUser, userToOppOrderField.keySet());
    }
    try {
      update orderList;
    } catch (Dmlexception ex) {
      ApexLogHandler.createLogAndSave('AccountSegmentationUtility','createAccountSegmentRecordforUser', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        newUsers.values().get(0).addError(ex.getDmlMessage(i)); 
      }
    }
    
    return accountSegmentMap;
  }


  //========================================================================
  // Method to create Account Segments level by level
  //========================================================================
  public static void processByLevel(List<Opportunity> opportunities, List<Order__c> orderList, Map<Id, User> users) {
    List<Account_Segment__c> newSegments = new List<Account_Segment__c>();
    if (level == 3) {
      newSegments = processAccSeg(opportunities, level3Fields, null); // GBL/Region/Country first
      newSegments.addAll(processAccSeg(orderList, level3Fields, users)); // GBL/Region/Country first
    }
    if (level == 2) {
      newSegments = processAccSeg(opportunities, level2Fields, null); // BL
     newSegments.addAll(processAccSeg(orderList, level2Fields, users)); // BL
    }
    if (level == 1) {
      newSegments = processAccSeg(opportunities, level1Fields, null); // BU
      newSegments.addAll(processAccSeg(orderList, level1Fields, users)); // BU
    }

    // Insert records and store them in map to reference them as parents for other Account Segments
    insert newSegments;
    System.debug('===segments created==='+newSegments);
    for (Account_Segment__c accSegment: newSegments) {
      accountSegmentMap.put(accSegment.Account__c + '-' + accSegment.Type__c + '-' + accSegment.Value__c, accSegment);
    }
  }



  //========================================================================
  // Method to create - if necessary - and add new Account Segments to a map
  //========================================================================
  private static List<Account_Segment__c> processAccSeg(List<Opportunity> opps, Set<String> segmentNames, Map<Id, User> users) {
    List<Account_Segment__c> newSegments = new List<Account_Segment__c>();
    for(Opportunity opp : opps){
      for (String segmentName: segmentNames) {
        system.debug('\n[AccountSegmentationUtility: createAccountSegmentRecord]======opp.get(segmentName)~~>>>Opp Owner: '+opp.Owner + ' and value: ' + opp.Owner.get(segmentName));
        String key = opp.Account.Id + '-' + userSegmentFieldNames.get(segmentName) + '-' + (String) opp.Owner.get(segmentName);
        String segmentType = userSegmentFieldNames.get(segmentName);

        if (!String.isEmpty((String) opp.Owner.get(segmentName)) && !accountSegmentMap.containsKey(key)) {
          system.debug('---creating acc segments--for--'+ opp);
          Account_Segment__c segment = createAccountSegmentRecord(opp.AccountId, (String) opp.Owner.get(segmentName), segmentType);
          if (segment != null) {
            newSegments.add(segment);
            accountSegmentMap.put(key, segment);
          }
        }
      }
    }
    return newSegments;
  }

  //========================================================================
  // Method to create - if necessary - and add new Account Segments to a map
  //========================================================================
  private static List<Account_Segment__c> processAccSeg(List<Order__c> orders, Set<String> segmentNames, Map<Id, User> users) {
    List<Account_Segment__c> newSegments = new List<Account_Segment__c>();
    for(Order__c ordr : orders) {
      User orderOwner = users.get(ordr.OwnerId);
      for (String segmentName: segmentNames) {
        system.debug('\n[AccountSegmentationUtility: createAccountSegmentRecord]======order.get(segmentName)~~>>>Order Owner: '+orderOwner.Id + ' and value: ' + orderOwner.get(segmentName));
        String key = ordr.Account__c + '-' + userSegmentFieldNames.get(segmentName) + '-' + (String) orderOwner.get(segmentName);
        String segmentType = userSegmentFieldNames.get(segmentName);

        if (!String.isEmpty((String) orderOwner.get(segmentName)) && !accountSegmentMap.containsKey(key)) {
          Account_Segment__c segment = createAccountSegmentRecord(ordr.Account__c, (String) orderOwner.get(segmentName), segmentType);
          if (segment != null) {
            newSegments.add(segment);
            accountSegmentMap.put(key, segment);
          }
        }
      }
    }
    return newSegments;
  }

  //===================================================================
  // Method to create Account Segment if it does not exist already
  //===================================================================
  private static Account_Segment__c createAccountSegmentRecord( Id accountId, String segmentName, String segmentType) {
    Account_Segment__c accSeg;
    String accountName = accountMap.get(accountId);
    String key = accountId + '-' + segmentType + '-' + segmentName;
    String hierarchyKey = segmentType + '-' + segmentName;


    String accSegName = accountName.length() > 20? accountName.subString(0,19)+'-'+segmentName :accountName+'-'+segmentName;
    system.debug('\n[AccountSegmentationUtility: createAccountSegmentRecord]======hierarchyKey>>>' +hierarchyKey + ' and ' + hierarchyMap.get(hierarchyKey));
    if( !accountSegmentMap.containsKey(key) && hierarchyMap != null && hierarchyMap.containsKey(hierarchyKey)) {
      String parentSegKey = (hierarchyMap != null && hierarchyMap.containsKey(hierarchyKey) && hierarchyMap.get(hierarchyKey).Parent__c != null)?
                             accountId+ '-'+ hierarchyMap.get(hierarchyKey).Parent__r.Name : '';
      accSeg = new Account_Segment__c();
      accSeg.Name = accSegName;
      accSeg.CurrencyIsoCode = Constants.CURRENCY_USD;
      accSeg.Account__c = accountId;
      accSeg.Segment__c = hierarchyMap.get(hierarchyKey).Id;
      accSeg.Relationship_Type__c = Constants.BU_RELATIONSHIP_TYPE_PROSPECT;
      accSeg.Type__c = segmentType;

      system.debug('\n[AccountSegmentationUtility: createAccountSegmentRecord]======parentSegKey>>>' +parentSegKey);
      if ( parentSegKey != '' && accountSegmentMap != null && accountSegmentMap.containsKey(parentSegKey) ) {
        accSeg.Parent_Account_Segment__c = accountSegmentMap.get(parentSegKey).Id;
      }
      system.debug('\n[AccountSegmentationUtility: createAccountSegmentRecord]----'+accSegName+'===='+accSeg.Parent_Account_Segment__c);
      accountSegmentMap.put(key, accSeg);
    }
    return accSeg;
  }

  //===========================================================================
  // Populate the Opp's Segment Fields
  //===========================================================================
  private static void populateOppSegmentFields(Opportunity opp, User user, Set<String> fieldNames) {
    for (String fieldName: fieldNames) {
      System.debug('---user---'+user+'===='+fieldname);
      if( user != null ) {
      String segmentValue = userSegmentFieldNames.get(fieldName) + '-' + (String) user.get(fieldName);
      String segmentMapKey = opp.AccountId + '-' + segmentValue;
      system.debug('\n[OpportunityTrigger_AccountSegmentation: populateSegmentMap] segmentValue:'+segmentValue + ' and segmentMapKey = ' + segmentMapKey);
      if (!String.isBlank(segmentValue) && accountSegmentMap.containsKey(segmentMapKey)) {
        String oldValue = (String) opp.put(userToOppOrderField.get(fieldName), accountSegmentMap.get(segmentMapKey).Id);
      }
      }
    }
  }

  //===========================================================================
  // Populate the Opp's Segment Fields
  //===========================================================================
  private static void populateOrderSegmentFields(Order__c ordr, User user, Set<String> fieldNames) {
    for (String fieldName: fieldNames) {
      if ( user != null ) {
      String segmentValue = userSegmentFieldNames.get(fieldName) + '-' + (String) user.get(fieldName);
      String segmentMapKey = ordr.Account__c + '-' + segmentValue;
      system.debug('\n[OpportunityTrigger_AccountSegmentation: populateSegmentMap] segmentValue:'+segmentValue + ' and segmentMapKey = ' + segmentMapKey);
      if (!String.isBlank(segmentValue) && accountSegmentMap.containsKey(segmentMapKey)) {
        String oldValue = (String) ordr.put(userToOppOrderField.get(fieldName), accountSegmentMap.get(segmentMapKey).Id);
      }
      }
    }
  }

}