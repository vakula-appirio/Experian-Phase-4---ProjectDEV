/**=====================================================================
 * Appirio, Inc
 * Name: OrderTrigger_AccountSegmentation
 * Description:  
 *              T-374276: Poopulate segment fields on order: Apr 02nd, 2015 Naresh                        
 *              T-374272: As per chatter of Nathalie, moved Acc Segment related 
 *              Code to this class from OpportunityTriggerHelper.cls
 *
 * Created Date: April 06th, 2015
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 * Apr 14, 2015             Naresh kr                   T-377401: Added accountSegmentCalculation()
 * Apr 15th, 2015           Nathalie Le Guay            Change segment keys to be AccountId + segmentType + segmentValue
 ======================================================================*/
public with sharing class OrderTrigger_AccountSegmentation {

  public static Map<String, Account_Segment__c> accSegName_AccountSegmentMap;
  public static Boolean accountSegmentCreated = false;
  private static Integer level = 3;
  public static Integer segmentCreationCalledTimes = 0;
  private static Map<String, Set<String>> segmentValue_accIDsMap;
  private static Set<String> segmentFieldNames = new Set<String>{
                                                  'Segment_Global_Business_Line__c',
                                                  'Segment_Business_Line__c',
                                                  'Segment_Business_Unit__c',
                                                  'Segment_Region__c',
                                                  'Segment_Country__c'
                                                 };
  private static Set<Id> accountIds;
  private static Map<String, Id> parentMap;
  private static Map<String, Hierarchy__c> hierarchyMap;
  private static Map<ID, Account> accountMap;
  private static Map<String, String> userToOrderField = AccountSegmentationUtility.userToOppOrderField;
  private static Map<String, String> ordOwnerToOppOrderField = AccountSegmentationUtility.ordOwnerToOppOrderField;
  private static Set<String> level3Fields = AccountSegmentationUtility.level3Fields;
  private static Set<String> level2Fields = AccountSegmentationUtility.level2Fields;
  private static Set<String> level1Fields = AccountSegmentationUtility.level1Fields;
  private static Set<String> level3OrdOwnerFields = AccountSegmentationUtility.level3OrdOwnerFields;
  private static Set<String> level2OrdOwnerFields = AccountSegmentationUtility.level2OrdOwnerFields;
  private static Set<String> level1OrdOwnerFields = AccountSegmentationUtility.level1OrdOwnerFields;
  private static Map<String, String> userSegmentFieldNames = AccountSegmentationUtility.userSegmentFieldNames;
  private static Map<String, String> ordOwnerSegmentFieldNames = AccountSegmentationUtility.ordOwnerSegmentFieldNames;
  public static Boolean hasRunBatch = false;
  public static String readOnlyRT = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);


/////////////////// NATHALIE/////////////////////////

  //===========================================================================
  // T-374272: populate segment fields on order on before insert
  // This methods determines if the logic should be run and kicks off the
  // process if so
  //===========================================================================
  public static void populateSegmentsOnOrders (List<Order__c> newList, Map<ID, Order__c> oldMap) {
    Map<ID, User> userMap = new Map<ID, User>();
    parentMap = new Map<String, Id>();
    Set<String> segmentValueSet = new Set<String>();
    Set<Id> ordersToProcess = new Set<Id>();
    accountIDs = new Set<ID>();
    set<String> segmentValueSetForClosed = new set<String>();
    accSegName_AccountSegmentMap = new Map<String, Account_Segment__c>();
    Boolean createSegments = false;
    if (hasRunBatch) {
      return;
    }

    for (Order__c ord : newList) {
      Order__c oldOrder = null;
      if (oldMap != null) {
        oldOrder = oldMap.get(ord.ID);
      }
      if ((oldOrder != null ?
          (oldOrder.OwnerID != ord.OwnerID || oldOrder.Account__c != ord.Account__c 
                                           || isMissingSegment(userToOrderField.values(), ord)
                                           || ord.RecordTypeId == readOnlyRT) :
          true)) { 
        if (ord.Account__c !=  null) {
          accountIDs.add(ord.Account__c);
        }
        if ( ord.RecordTypeId != readOnlyRT) {
          userMap.put(ord.OwnerId, null);
        }
        else {
        	for ( String fieldName :ordOwnerToOppOrderField.keySet()) {
            if ( ord.get(fieldName) != null ) {
              segmentValueSetForClosed.add(String.valueOf(ord.get(fieldName)));
            }
          }
        }
        createSegments = true;
        ordersToProcess.add(ord.Id);
      }

    }
    if (createSegments) {
      // Populates userMap and AccountSegment Map
      Set<String> segmentNames = AccountSegmentationUtility.populateSegmentMapAndOwnerMap(
                                                            accountIDs,
                                                            userMap,
                                                            accSegName_AccountSegmentMap,
                                                            parentMap,
                                                            segmentValueSetForClosed);
      system.debug('\n[OrderTrigger_AccountSegmentation: populateSegmentsOnOrders]: userMap entry ');
      for (Id userId: userMap.keySet()) {
        system.debug('\n'+ userMap.get(userId));
      }
      populateSegmentFieldsOnOrder(newList, oldMap, userMap, segmentNames, ordersToProcess);
    }
  }


  //===========================================================================
  // Gets the Account Segment created, and then populates the Order Segment fields
  //===========================================================================
  public static void populateSegmentFieldsOnOrder (List<Order__c> newList, Map<ID, Order__c> oldMap,
                                                  Map<ID, User> userMap, Set<String> segmentNames,
                                                  Set<Id> ordersToProcess) {

    hierarchyMap = AccountSegmentationUtility.populateHierarchyMap(segmentNames, false);
    accountMap = AccountSegmentationUtility.populateAccountMap(accountIds);
    //String readOnlyRT = '';
    //readOnlyRT = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
    // This will create the 3 levels of Account Segment hierarchy
    while (level > 0) {
      processOrdersByLevel(newList, oldMap, userMap, ordersToProcess);
      level--;
    }

    // Here we are populating the Order Segment_* fields, now that all Account Segments have been created
    for (Order__c ord: newList) {
      if (!ordersToProcess.contains(ord.Id)) {
        continue;
      }
      User ownerUser = userMap.get(ord.OwnerId);
      Order__c oldOrder = oldMap != null ? oldMap.get(ord.Id) : null;
      if (ord.RecordTypeId == readOnlyRT) {
        populateOrderSegmentFields(ord, oldOrder, ownerUser, ordOwnerToOppOrderField.keySet()); //I
      }
      else {
        populateOrderSegmentFields(ord, oldOrder, ownerUser, userToOrderField.keySet());
      }
      
   }
  }

  //===========================================================================
  // Orchestrate the Level-by-level creation of Account Segments, to allow
  // the hierarchy to be created in the best way
  //===========================================================================
  private static void processOrdersByLevel(List<Order__c> newList, Map<ID, Order__c> oldMap,
                                         Map<ID, User> userMap, Set<Id> ordersToProcess) {
    segmentValue_accIDsMap = new Map<String, Set<String>>();
    Set<String> userLevelFields;
    //String readOnlyRT = '';
    //readOnlyRT = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
    for (Order__c ord: newList) {
      User ownerUser = userMap.get(ord.OwnerId);
      Order__c oldOrder = oldMap != null ? oldMap.get(ord.Id) : null;
      if ((oldOrder != null ? ordersToProcess.contains(ord.Id) : true)) {
        //segmentValue_accIDsMap = new Map<String, Set<String>>(); // resetting so we only have the current level
        if (level == 3) {
          if(ord.RecordTypeId == readOnlyRT) {
          populateSegmentMap(ord, oldOrder, ownerUser, level3OrdOwnerFields);
          }
          else {
          	populateSegmentMap(ord, oldOrder, ownerUser, level3Fields);
          }
        }
        if (level == 2) {
        	if(ord.RecordTypeId == readOnlyRT) {
          populateSegmentMap(ord, oldOrder, ownerUser, level2OrdOwnerFields);
          }
          else {
            populateSegmentMap(ord, oldOrder, ownerUser, level2Fields);
          }
        }
        if (level == 1) {
          if(ord.RecordTypeId == readOnlyRT) {
          populateSegmentMap(ord, oldOrder, ownerUser, level1OrdOwnerFields);
          }
          else {
            populateSegmentMap(ord, oldOrder, ownerUser, level1Fields);
          }
        }
      }
    }
    // Account Ids contains the account of ords requiring udpates to their Segment* fields
    if (accountIDs.size() > 0) {
      createAccountSegmentRecord(); // Will create account segments for entries in segmentValue_accIDsMap
    }
  }

  //===========================================================================
  // Creates the account segments for data in the segmentValue_accIDsMap
  //===========================================================================
  private static void createAccountSegmentRecord () {
    Map<String, Account_Segment__c> parentAccountSegmentMap = new Map<String, Account_Segment__c>();
    List<Account_Segment__c> accountSegmentsTobeCreated = new List<Account_Segment__c>();

    for (String segmentTypeAndName : segmentValue_accIDsMap.keySet()) {
      for (String accID : segmentValue_accIDsMap.get(segmentTypeAndName)) {
        if (!hierarchyMap.containsKey(segmentTypeAndName)) {
          continue;
        }
        system.debug('hierarchyMap>>>' +hierarchyMap);
        Account_Segment__c newAccountSegment = new Account_Segment__c();
        Hierarchy__c hierarchySegment = hierarchyMap.get(segmentTypeAndName);
        String accountName = accountMap.get(accID).Name;
        String accSegName = accountName.length() > 20? accountName.subString(0,19)+'-'+hierarchySegment.Value__c :accountName+'-'+hierarchySegment.Value__c;
        newAccountSegment.Name = accSegName;
        newAccountSegment.CurrencyIsoCode = Constants.CURRENCY_USD;
        newAccountSegment.Account__c = accID;
        newAccountSegment.Segment__c = hierarchySegment.ID;
        newAccountSegment.Value__c = hierarchySegment.Value__c;
        newAccountSegment.Type__c = hierarchySegment.Type__c;
        newAccountSegment.Relationship_Type__c = Constants.BU_RELATIONSHIP_TYPE_PROSPECT;
        String parentKey = accID + '-' + hierarchySegment.Parent__r.Name;
        system.debug('\n[OrderTrigger_AccountSegmentation: createAccountSegmentRecord] for '+ newAccountSegment.Name + ' found: '+ parentMap.get(parentKey));
        if (parentMap.containsKey(parentKey)) {
          newAccountSegment.Parent_Account_Segment__c = parentMap.get(parentKey);
        }
        accountSegmentsTobeCreated.add(newAccountSegment);
        accSegName_AccountSegmentMap.put(accID + '-' + segmentTypeAndName, newAccountSegment);
      }
    }

    if (accountSegmentsTobeCreated.size() > 0) {
      insert accountSegmentsTobeCreated;
      for (Account_Segment__c segment: accountSegmentsTobeCreated) {
        parentMap.put(segment.Account__c + '-' + segment.Type__c + '-' + segment.Value__c, segment.Id);
      }
    }
     
  }

  //===========================================================================
  // Populates the various structures
  //===========================================================================
  private static void populateSegmentMap(Order__c ord, Order__c oldOrder, User user, Set<String> fieldNames) {
    //String readOnlyRT = '';
    //readOnlyRT = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_ORDER, Constants.READ_ONLY);
    String segmentValue = '';
    for (String fieldName: fieldNames) {
    	if(ord.RecordTypeId == readOnlyRT) {
    		segmentValue = ordOwnerSegmentFieldNames.get(fieldName) + '-' + (String) ord.get(fieldName);
    	}
    	else {
        segmentValue = userSegmentFieldNames.get(fieldName) + '-' + (String) user.get(fieldName);
    	}
      String segmentMapKey = ord.Account__c+'-'+segmentValue;
      system.debug('\n[OrderTrigger_AccountSegmentation: populateSegmentMap] segmentValue:' + segmentValue + '\n and segmentMapKey='+ segmentMapKey);
      if (!String.isBlank(segmentValue)) {
        if (!segmentValue_accIDsMap.containsKey(segmentValue)) {
          segmentValue_accIDsMap.put(segmentValue, new Set<String>());
        }
        // If this entry is not in the map, this means that an Account Segment needs to be created for it
        if (!accSegName_AccountSegmentMap.containsKey(segmentMapKey)) {
          if (ord.Account__c !=  null) {
            segmentValue_accIDsMap.get(segmentValue).add(ord.Account__c);
            accountIds.add(ord.Account__c);
          }
        }
      }
    }
  }

  //===========================================================================
  // Populate the Order's Segment Fields
  //===========================================================================
  private static void populateOrderSegmentFields(Order__c ord, Order__c oldOrder, User user, Set<String> fieldNames) {
    for (String fieldName: fieldNames) {
      System.debug('---user---'+user+'===='+fieldname);
      String segmentValue = '';
      String ordFieldName = '';
      if (ord.RecordTypeId == readOnlyRT) {
        segmentValue = ordOwnerSegmentFieldNames.get(fieldName) + '-' + (String) ord.get(fieldName);
        ordFieldName = ordOwnerToOppOrderField.get(fieldName);
      }
      else {
     	  segmentValue = userSegmentFieldNames.get(fieldName) + '-' + (String) user.get(fieldName);
      	ordFieldName = userToOrderField.get(fieldName);
      }	
      
      if (!String.isEmpty(segmentValue)) {
	      String segmentMapKey = ord.Account__c + '-' + segmentValue;
	      
	      system.debug('\n[OrderTrigger_AccountSegmentation: populateSegmentMap] segmentValue:'+segmentValue + ' and segmentMapKey = ' + segmentMapKey);
	      system.debug('parentMap>>>'+parentMap);
	      if (!String.isBlank(segmentValue) && parentMap.containsKey(segmentMapKey)) {
	        String oldValue = (String) ord.put(ordFieldName, /*accSegName_AccountSegmentMap*/
	                                           parentMap.get(segmentMapKey));        
	      }
      }
    }
  }

  //===========================================================================
  // Returns true if any of the field in the param is null
  //===========================================================================
  private static Boolean isMissingSegment(List<String> fieldNames, Order__c ord) {
    for (String fieldName: fieldNames) {
      if (ord.get(fieldName) == null) {
        return true;
      }
    }
    return false;
  }

/////////////////// END NATHALIE ////////////////////////
  

  //===========================================================================
  // Will recalculate the Account Segments ( T-377401)
  //===========================================================================
  public static void accountSegmentCalculation(List<Order__c> oldOrders) {
    Set<Id> segmentIds = new Set<Id>();
    List<String> segmentFieldName = AccountSegmentationUtility.userToOppOrderField.values();
    for (Order__c ord : oldOrders) {
      for (String fieldName: segmentFieldName) {
        if (ord.get(fieldName) != null) {
          segmentIds.add((Id) ord.get(fieldName));
        }
      }
    }
    if ( !segmentIds.isEmpty() ) {
      System.enqueueJob(new SegmentMaintenanceQueue(segmentIds, null)); 
    }
  }
 
}