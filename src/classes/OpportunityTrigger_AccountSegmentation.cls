/**=====================================================================
 * Appirio, Inc
 * Name: OpportunityTrigger_AccountSegmentation
 * Description:
 *              T-374272: Poopulate segment fields on opportunity: Apr 02nd, 2015 Naresh
 *              T-374272: As per chatter of Nathalie, moved Acc Segment related
 *              Code to this class from OpportunityTriggerHelper.cls
 *
 * Created Date: April 06th, 2015
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified            Modified By               Description of the update
 * Apr 07th, 2015           Noopur                    Added the methods updateOppRelatedAccountSegments(),
 *                                                    isOpptyFieldUpdated() and addSegmentValues()
 * Apr 7th, 2015            Nathalie Le Guay          Rewrote populateSegmentFieldsOnOpp() and functionality
 *                                                    to populate the Opp's Segment__* fields
 * Apr 08th, 2015           Arpita Bose               T-376294: Added the call of SegmentMaintenanceQueue class
 * Apr 08th, 2015           Rohit B                   commented two functions named populateSegmentFieldsOnOppty & createAccountSegmentRecord
 * Apr 15th, 2015           Nathalie Le Guay          Change segment keys to be AccountId + segmentType + segmentValue
 * Apr 24th, 2015           Suminder Singh            I-156673: Modified populateSegmentMap() method to update segment fields with Owner_* fields
                                                                 when opp is closed or won
 ======================================================================*/
 public without sharing class OpportunityTrigger_AccountSegmentation {
  public static Map<String, Account_Segment__c> accSegName_AccountSegmentMap;
  public static Boolean accountSegmentCreated = false;
  public static Integer segmentCreationCalledTimes = 0;
  private static Integer level = 3;
  private static Map<String, Set<String>> segmentValue_accIDsMap;
  public static Set<Id> accountIds;
  private static Map<String, Id> parentMap;
  private static Map<String, Hierarchy__c> hierarchyMap;
  private static Map<ID, Account> accountMap;
  private static Map<String, String> userToOppField = AccountSegmentationUtility.userToOppOrderField;
  private static Map<String, String> ownerToOppField = AccountSegmentationUtility.ownerToOppOrderField;
  private static Set<String> level3Fields = AccountSegmentationUtility.level3Fields;
  private static Set<String> level2Fields = AccountSegmentationUtility.level2Fields;
  private static Set<String> level1Fields = AccountSegmentationUtility.level1Fields;
  private static Set<String> level3OwnerFields = AccountSegmentationUtility.level3OwnerFields;
  private static Set<String> level2OwnerFields = AccountSegmentationUtility.level2OwnerFields;
  private static Set<String> level1OwnerFields = AccountSegmentationUtility.level1OwnerFields;
  private static Map<String, String> userSegmentFieldNames = AccountSegmentationUtility.userSegmentFieldNames;
  private static Map<String, String> ownerSegmentFieldNames = AccountSegmentationUtility.ownerSegmentFieldNames;
  public static Boolean hasRunBatch = false;


  //===========================================================================
  // T-374272: populate segment fields on oppty on before insert
  // This methods determines if the logic should be run and kicks off the
  // process if so
  //===========================================================================
  public static void populateSegmentsOnOppty (List<Opportunity> newList, Map<ID, Opportunity> oldMap) {
    Map<ID, User> userMap = new Map<ID, User>();
    parentMap = new Map<String, Id>();
    Set<String> segmentValueSet = new Set<String>();
    List<Opportunity> oppsToProcess = new List<Opportunity>();
    accountIDs = new Set<ID>();
    accSegName_AccountSegmentMap = new Map<String, Account_Segment__c>();
    Boolean createSegments = false;
    set<String> segmentValueSetForClosed = new set<String>();

    if (hasRunBatch) {
      return;
    }
    for (Opportunity oppty : newList) {
      Opportunity oldOpp = null;
      if (oldMap != null) {
        oldOpp = oldMap.get(oppty.ID);
      }
      if ((oldOpp != null ?
          (oldOpp.OwnerID != oppty.OwnerID || oldOpp.AccountId != oppty.AccountId
                                           || isMissingSegment(userToOppField.values(), oppty)
                                           || oldOpp.IsClosed != oppty.IsClosed) :
          true)) { 
        if (oppty.AccountId != null) {
          accountIDs.add(oppty.AccountID);
        }
        if ( !oppty.IsClosed ) {
          userMap.put(oppty.OwnerId, null);
        }
        else {
        	for ( String fieldName :ownerToOppField.keySet()) {
        		if ( oppty.get(fieldName) != null ) {
        			segmentValueSetForClosed.add(String.valueOf(oppty.get(fieldName)));
        		}
        	}
        } 
        createSegments = true;
        oppsToProcess.add(oppty);
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
      
      system.debug('\n[OpportunityTrigger_AccountSegmentation: populateSegmentsOnOppty]: accountIds entry '+parentMap+ '---'+ accountIDs);
      // populateSegmentFieldsOnOppty(newList, oldMap, userMap);
      populateSegmentFieldsOnOpp(oppsToProcess, oldMap, userMap, segmentNames);
    }
  }


  //===========================================================================
  // Gets the Account Segment created, and then populates the Opp Segment fields
  //===========================================================================
  public static void populateSegmentFieldsOnOpp (List<Opportunity> oppsToProcess, Map<ID, Opportunity> oldMap,
                                                  Map<ID, User> userMap, Set<String> segmentNames) {
 
    hierarchyMap = AccountSegmentationUtility.populateHierarchyMap(segmentNames, false);
    accountMap = AccountSegmentationUtility.populateAccountMap(accountIds);

    // This will create the 3 levels of Account Segment hierarchy
    while (level > 0) {
      processOppsByLevel(oppsToProcess, oldMap, userMap);
      level--;
    }

    // Here we are populating the Opp Segment_* fields, now that all Account Segments have been created
    for (opportunity opp: oppsToProcess) {
      User ownerUser = userMap.get(opp.OwnerId);
      Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
      
      if (!opp.IsClosed) {
        populateOppSegmentFields(opp, oldOpp, ownerUser, userToOppField.keySet());
      }
      if (opp.IsClosed) {
        populateOppSegmentFields(opp, oldOpp, ownerUser, ownerToOppField.keySet());
      }
   }
  }

  //===========================================================================
  // Orchestrate the Level-by-level creation of Account Segments, to allow
  // the hierarchy to be created in the best way
  //===========================================================================
  public static void processOppsByLevel(List<Opportunity> newList, Map<ID, Opportunity> oldMap, Map<ID, User> userMap) {
    segmentValue_accIDsMap = new Map<String, Set<String>>();
    Set<String> userLevelFields;

    for (Opportunity opp: newList) {
      User ownerUser = userMap.get(opp.OwnerId);
      Opportunity oldOpp = oldMap != null ? oldMap.get(opp.Id) : null;
     // if ((oldOpp != null ? oppsToProcess.contains(opp.Id) : true)) {
        //segmentValue_accIDsMap = new Map<String, Set<String>>(); // resetting so we only have the current level
        if (level == 3) {
          if(opp.IsClosed || opp.IsWon) {
            populateSegmentMap(opp, oldOpp, ownerUser, level3OwnerFields);
          }
          else {
          populateSegmentMap(opp, oldOpp, ownerUser, level3Fields);
          }
        }
        if (level == 2) {
          if(opp.IsClosed || opp.IsWon) {
            populateSegmentMap(opp, oldOpp, ownerUser, level2OwnerFields);
          }
          else {
          populateSegmentMap(opp, oldOpp, ownerUser, level2Fields);
          }
        }
        if (level == 1) {
          if(opp.IsClosed || opp.IsWon) {
            populateSegmentMap(opp, oldOpp, ownerUser, level1OwnerFields);
          }
          else {
          populateSegmentMap(opp, oldOpp, ownerUser, level1Fields);
          }
        }
     // }
    }
    // Account Ids contains the account of opps requiring udpates to their Segment* fields
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
      system.debug('\n[OpportunityTrigger_AccountSegmentation: createAccountSegmentRecord]=>segmentName' + segmentTypeAndName);
      for (String accID : segmentValue_accIDsMap.get(segmentTypeAndName)) {
        if (!hierarchyMap.containsKey(segmentTypeAndName)) {
          continue;
        }

        Account_Segment__c newAccountSegment = new Account_Segment__c();
        Hierarchy__c hierarchySegment = hierarchyMap.get(segmentTypeAndName);
        String accountName = accountMap.get(accID).Name;
        String accSegName = accountName.length() > 20? accountName.subString(0,19)+'-'+hierarchySegment.Value__c :accountName+'-'+hierarchySegment.Value__c;

        newAccountSegment.Name = accSegName;
        //newAccountSegment.Name = accountMap.get(accID).Name + '-' + hierarchyMap.get(segmentName).Value__c;
        newAccountSegment.CurrencyIsoCode = Constants.CURRENCY_USD;
        newAccountSegment.Account__c = accID;
        newAccountSegment.Segment__c = hierarchySegment.ID;
        newAccountSegment.Value__c = hierarchySegment.Value__c;
        newAccountSegment.Type__c = hierarchySegment.Type__c;
        newAccountSegment.Relationship_Type__c = Constants.BU_RELATIONSHIP_TYPE_PROSPECT;
        String parentKey = accID + '-' + hierarchySegment.Parent__r.Name;
        system.debug('\n[OpportunityTrigger_AccountSegmentation: createAccountSegmentRecord] for '+ newAccountSegment.Name + ' found: '+ parentMap.get(parentKey));
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
  private static void populateSegmentMap(Opportunity opp, Opportunity oldOpp, User user, Set<String> fieldNames) {
    String segmentValue;
    for (String fieldName: fieldNames) {
      if(opp.IsClosed || opp.IsWon) {
        segmentValue = ownerSegmentFieldNames.get(fieldName) + '-' + (String) opp.get(fieldName);
      }
      else {
        segmentValue = userSegmentFieldNames.get(fieldName) + '-' + (String) user.get(fieldName);
      }
      String segmentMapKey = opp.AccountId+'-'+segmentValue;
      system.debug('\n[OpportunityTrigger_AccountSegmentation: populateSegmentMap] segmentValue:' + segmentValue + '\n and segmentMapKey='+ segmentMapKey);
      if (!String.isBlank(segmentValue)) {
        if (!segmentValue_accIDsMap.containsKey(segmentValue)) {
          segmentValue_accIDsMap.put(segmentValue, new Set<String>());
        }
        // If this entry is not in the map, this means that an Account Segment needs to be created for it
        if (!accSegName_AccountSegmentMap.containsKey(segmentMapKey)) {
          if (opp.AccountId !=  null) {
            segmentValue_accIDsMap.get(segmentValue).add(opp.AccountId);
            accountIds.add(opp.AccountId);
          }
        }
      }
    }
  }

  //===========================================================================
  // Populate the Opp's Segment Fields
  //===========================================================================
  private static void populateOppSegmentFields(Opportunity opp, Opportunity oldOpp, User user, Set<String> fieldNames) {
    for (String fieldName: fieldNames) {
      System.debug('fieldName: ' + fieldName + '---user---'+user);
      String segmentValue = '';
      String oppFieldName = '';
      if ( user != null && !opp.IsClosed) {
        segmentValue = userSegmentFieldNames.get(fieldName) + '-' + (String) user.get(fieldName);
        oppFieldName = userToOppField.get(fieldName);
      }

      if (opp.IsClosed) {
        segmentValue = ownerSegmentFieldNames.get(fieldName) + '-' + (String) opp.get(fieldName);
        oppFieldName = ownerToOppField.get(fieldName);
      }

      if (!String.isEmpty(segmentValue)) {
        String segmentMapKey = opp.AccountId + '-' + segmentValue;
        system.debug('\n[OpportunityTrigger_AccountSegmentation: populateSegmentMap] segmentValue:'+segmentValue + ' and segmentMapKey = ' + segmentMapKey);
        if (!String.isBlank(segmentValue) && parentMap.containsKey(segmentMapKey)) {
          String oldValue = (String) opp.put(oppFieldName, parentMap.get(segmentMapKey));
        } /*else if (!parentMap.containsKey(segmentMapKey)) {
          // If a value is present but should be erased (ex: re-open an opp whose Owner was changed while closed,
          // and owner doesn't have BU)
          String oldValue = (String) opp.put(oppFieldName, null);
        }*/
      }
    }
  }

  //===========================================================================
  // Returns true if any of the field in the param is null
  //===========================================================================
  private static Boolean isMissingSegment(List<String> fieldNames, Opportunity opp) {
    for (String fieldName: fieldNames) {
      if (opp.get(fieldName) == null) {
        return true;
      }
    }
    return false;
  }



  //============================================================================
  // Returns true if field has updated value in new record.
  //============================================================================
  private static Boolean isOpptyFieldUpdated (Set<String> fieldSet, Opportunity newRec, Opportunity oldRec) {
    for (String fieldName : fieldSet) {
      if (newRec.get(fieldName) != oldRec.get(fieldName)) {
        return true;
      }
    }
    return false;
  }

  //============================================================================
  // Returns a set of Account Segment Ids if opp fields not blank
  //============================================================================
  private static Set<Id> addSegmentValues(Set<String> fieldSet, Opportunity newRec, Opportunity oldRec) {
    Set<Id> accSegIds = new Set<Id>();
    for (String fieldName: fieldSet) {
      if (newRec.get(fieldName) != null) {
        accSegIds.add((Id) newRec.get(fieldName));
      }
      if (oldRec != null && oldRec.get(fieldName) != null) {
        accSegIds.add((Id) oldRec.get(fieldName));
      }
    }
    return accSegIds;
  }

  //===========================================================================
  // T-374242 : Method to update the related Account segment on creation/updation of Opp
  //===========================================================================
  public static void updateOppRelatedAccountSegments (map<Id,Opportunity> oldOppMap, map<Id,Opportunity> newOppMap) {
    set<Id> accSegIds = new set<Id>();
    Set<String> segmentFieldsToTrack = new Set<String>{'Segment_Business_Unit__c', 'Segment_Business_Line__c',
                                                       'Segment_Global_Business_Line__c', 'Segment_Region__c',
                                                       'Segment_Country__c'};
    Set<String> fieldsToTrack = new Set<String>{'isWon', 'isClosed'};

    for ( Opportunity opp : newOppMap.values() ) {
      if ((oldOppMap == null
            || (opp.Amount != oldOppMap.get(opp.Id).Amount && !opp.isClosed)
            || isOpptyFieldUpdated(segmentFieldsToTrack, opp, oldOppMap.get(opp.Id)) // those are the segment_* fields
            || isOpptyFieldUpdated(fieldsToTrack, opp, oldOppMap.get(opp.Id)) // those are other, various fields
           )
         ) {
        Opportunity oldOpp = (oldOppMap == null) ? null : oldOppMap.get(opp.Id);
        accSegIds.addAll(addSegmentValues(segmentFieldsToTrack, opp, oldOpp));

      }
    }
    set<String> valuesSet = new set<String>();
   /* for ( Account_Segment__c accSegment : [SELECT Id, Value__c, Segment__r.value__C
                                           FROM Account_Segment__c
                                           WHERE ID IN:accSegIds]) {
      valuesSet.add( accSegment.Id );
    }*/
    System.debug('~~~accSegIds~~~'+accSegIds);
    if ( !accSegIds.isEmpty() ) {
      //AccountSegmentationUtility.segmentationMaintenance(accSegIds, null);
      System.enqueueJob(new SegmentMaintenanceQueue(accSegIds, null)); 
    }
  }

  //===========================================================================
  // Will recalculate the Account Segments
  //===========================================================================
  public static void accountSegmentCalculation(List<Opportunity> oldOpps) {
    Set<Id> segmentIds = new Set<Id>();
    List<String> segmentFieldName = AccountSegmentationUtility.userToOppOrderField.values();
    for (Opportunity opp : oldOpps) {
      for (String fieldName: segmentFieldName) {
        if (opp.get(fieldName) != null) {
          segmentIds.add((Id) opp.get(fieldName));
        }
      }
    }
    if ( !segmentIds.isEmpty() ) {
      System.enqueueJob(new SegmentMaintenanceQueue(segmentIds, null)); 
    }
    //AccountSegmentationUtility.segmentationMaintenance(null, segmentId);
  }
  
}