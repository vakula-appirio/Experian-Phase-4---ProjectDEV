/**
=====================================================================
 * Appirio, Inc
 * Name: HistoryTrackingUtility
 * Description: T-365462 Generic class to track changes in a particular field
 * Created Date: Feb 25th, 2015
 * Created By: Gaurav Kumar Chadha(Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Mar 26th, 2015               Terri Kellough               Making generic to use SObjects T-372880
 * June 3rd, 2015               Noopur                       I-165602: Updated position of the hasRun variable to
 *                                                           allow use of WF rules
  =====================================================================*/

public with sharing class HistoryTrackingUtility {

  // Those Maps get information from User and Queue to store on the new History records
  public static Map<ID, String> ownerIdWithName;
  public static Map<ID, String> ownerIdWithUsersPrimaryQueue;
  public static Map<ID, String> queueIdWithName;
  private static Set<ID> ownerIds = new Set<ID>();

  // These two variables track the object on which we are tracking history and the name of lookup field to it
  private static String objectName;
  private static String historyParentFieldName;

  // This map stores the records on which there were updates to tracked fields
  private static Map<String, SObject> newRecsToCreateHistoryMap = new Map<String, SObject>();

  // This will store the last created History__c log for the field and record we are tracking
  private static Map<String, History__c> mapPriorHistories = new Map<String, History__c>();

  // Utility maps to make this class reusable by multiple triggers on various objects
  private static Map<String,String> mapFieldChangeType = new Map<String,String>();
  private static Map<String, String> prevHisTranslationMap = new Map<String, String>();
  private static Map<String, String> mapObjectTypeToLookupFieldName = new Map<String, String> {
    Constants.SOBJECT_MEMBERSHIP => Constants.SOBJECT_MEMBERSHIP,
    Constants.SOBJECT_CASE => 'Case__c'
  };

  // Prevents code from running twice
  public static Boolean hasRun = false;
  private static List<SObject> triggerRecords;


  //========================================================================
  // MethodName : logHistory
  // Description : It determenes whether the status was changed or not
  // This method passes as parameter the List of records on which we want to
  // track histories.
  //========================================================================
  public static void logHistory(List<SObject> lstNew,
                                            Map<Id , SObject> oldMap) {

    // We only want to run this logic once per context
    if (hasRun == true) {
        return;
    }

    triggerRecords = lstNew;
    getObjectAndFieldNames(lstNew);
    storeFieldsToTrackByObjectName();

    // Find and store in a map the SObject records for which field updates need to be tracked
    newRecsToCreateHistoryMap = checkForFieldChanges(lstNew, oldMap);
    System.debug('===LogHistory==='+newRecsToCreateHistoryMap);
    if (!newRecsToCreateHistoryMap.isEmpty()) {
      if (oldMap != null) {
        // Query and update prior history's end date
        getPriorMostRecentHistories(lstNew);
        updatePreviousHistoryRecEndTime();
      }
      createHistoryRecords();
    }
   
  //  hasRun = true;

  }

  //==========================================================================================
  // MethodName : getObjectTypeName
  // Description : Determines which object the records going through the triggers belong to
  //===========================================================================================
  private static void getObjectAndFieldNames(List<SObject> lstNew) {
    if (lstNew.size() > 0) {
      objectName = DescribeUtility.getSObjectName(lstNew.get(0).Id);
      historyParentFieldName = mapObjectTypeToLookupFieldName.get(objectName);
    }
  }


  //==========================================================================================
  // MethodName : storeFieldsToTrackByObjectName
  // Description : Query the custom settings to determine which set of fields we are tracking
  // History for
  //===========================================================================================
  private static void storeFieldsToTrackByObjectName() {
    List<History_Tracking_Object_Fields__c> lstCSFieldsToTrack  = [SELECT Id, Field_to_Track__c, Change_Type__c
                                                                   FROM History_Tracking_Object_Fields__c
                                                                   WHERE Object_Name__c=:objectName];

    for (History_Tracking_Object_Fields__c cs:lstCSFieldsToTrack) {
      mapFieldChangeType.put(cs.Field_to_Track__c, cs.Change_Type__c);
    }
    return;
  }

  //==========================================================================================
  // MethodName : getNewLstRecordIds
  // Description : Processes the records to extract the list of Ids
  //===========================================================================================
  private static List<String> getNewLstRecordIds(List<Sobject> lstNew) {
    List<String> lstNewRecordIds = new List<String>();
    for (SObject recId : lstNew) {
      if ((String)recId.get('Id') != '') {
        lstNewRecordIds.add((String)recId.get('Id'));
      }
    }
    return lstNewRecordIds;
  }

  //==========================================================================================
  // MethodName : getQualifyingRecords
  // Description : from all the records which are updated check in which only status is updated
  //===========================================================================================
  public static Map<String, SObject> checkForFieldChanges(List<SObject> lstNew, Map<Id, SObject> oldMap) {
    for (SObject obj : lstNew) {
      ownerIds.add((String)obj.get('OwnerId'));
      for (String theTrackedField : mapFieldChangeType.keySet()) {
        String key = obj.get('Id')+'-'+theTrackedField;
        String newTrackedField = (String)obj.get(theTrackedField);
        
        if (oldMap != null) {
          String oldTrackedField =  (String)oldMap.get((String)obj.get('Id')).get(theTrackedField);
          if (newTrackedField != oldTrackedField) {
            newRecsToCreateHistoryMap.put(key, obj);
            // Need to translate between [SObject].[fieldToTrack] and History__c.Change_Type__c
            // in order to identify previous history records to update the end date
            prevHisTranslationMap.put(key, obj.get('Id')+'-'+mapFieldChangeType.get(theTrackedField));
          }
        } else if (oldMap == null) {
          newRecsToCreateHistoryMap.put(key, obj);
        }
      }
    }
    return newRecsToCreateHistoryMap;
  }


  //=================================================================================
  // MethodName  : getPriorMostRecentHistories
  // Description : Will query and store the most recent History__c record without an
  // End Time
  //=================================================================================
  private static void getPriorMostRecentHistories(List<Sobject> lstNew) {
    String query;
    String changeTypes = '';
    String parentRecIds = '';
    List<History__c> lstPreviousHistory = new List<History__c>();
    List<String> lstNewRecordIds = getNewLstRecordIds(lstNew);

    query =  'SELECT Id, Change_Type__c, End_Time__c, ';
    query += historyParentFieldName ;
    query += ' FROM History__c WHERE End_Time__c = NULL AND Change_Type__c In (\'';

    for (String changeType : mapFieldChangeType.values()) {
      changeTypes += (changeTypes == '' ? '' : '\',\'') + changeType;
    }
    query += changeTypes + '\') AND ';

    query += historyParentFieldName + ' In (\'';
    for (String parentAPIName:lstNewRecordIds) {
      parentRecIds += (parentRecIds == '' ? '' : '\',\'') + parentAPIName;
    }
    query += parentRecIds + '\') Order By CreatedDate ASC';

    System.debug('HistoryTrackingUtility:getPriorMostRecentHistories: query = ' + query);

    lstPreviousHistory = Database.query(query);

    for (History__c history : lstPreviousHistory) {
      if (history.Change_Type__c != null) {
       String key = (String)history.get(historyParentFieldName) + '-' + history.Change_Type__c;
       mapPriorHistories.put(key, history);
       System.debug('HistoryTrackingUtility:getPriorMostRecentHistories: key ' + key + ' , mapPriorHistories ' + mapPriorHistories.get(key));
      }
    }

  }

  //=================================================================================
  // MethodName  : updatePreviousHistoryForEndTime
  // Description : updates previuos history record to populate End Time
  //================================= ===============================================
  public static void updatePreviousHistoryRecEndTime() {
    List<History__c> prevHistoryRecUpds = new List<History__c>();

    if (!newRecsToCreateHistoryMap.isEmpty()) {
      for (String key : newRecsToCreateHistoryMap.keySet()){
        String prevHistKey = prevHisTranslationMap.get(key);
        History__c prevHistRec = mapPriorHistories.get(prevHistKey);
        if (prevHistRec != null) {
          prevHistRec.End_time__c = Datetime.now();
          prevHistoryRecUpds.add(prevHistRec);
        }
      }
    }

    if (!prevHistoryRecUpds.isEmpty()) {
      try {
        update prevHistoryRecUpds;
      } catch (DMLException ex) {
          system.debug('[HistoryTrackingUtility: updatePreviousHistoryRecEndTime] Exception: ' + ex.getMessage());
          ApexLogHandler.createLogAndSave('HistoryTrackingUtility','updatePreviousHistoryRecEndTime', ex.getStackTraceString(), ex);
          for (Integer i = 0; i < ex.getNumDml(); i++) {
            triggerRecords.get(0).addError(ex.getDMLMessage(i));
          }
        }
    }
  }


  //===================================================================================
  // MethodName : createHistoryRecords
  // Description : Creates History Records when ever Membership__c status is changed
  //===================================================================================
  private static void createHistoryRecords() {
    List<History__c> listHistoryToInsert = new List<History__c>();

    createUserMaps();
    for (String key : newRecsToCreateHistoryMap.keySet()) {
      SObject sOjRec = newRecsToCreateHistoryMap.get(Key);
      String fieldToTrack = key.substringAfter('-');
      String changeType = mapFieldChangeType.get(fieldToTrack);
      History__c historyRec =  createNewHistoryRec(sOjRec, ownerIdWithName,
                                       ownerIdWithUsersPrimaryQueue, queueIdWithName,
                                       changeType, fieldToTrack);
      listHistoryToInsert.add(historyRec);
    }
    try {
       // Inserting Case History
       if (listHistoryToInsert.size() > 0) {
          insert listHistoryToInsert;
          hasRun = true;
       }
    } catch(DMLException ex) {
      apexLogHandler.createLogAndSave('HistoryTrackingUtility','createHistoryRecords', ex.getStackTraceString(), ex);
      for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
        listHistoryToInsert.get(0).addError(ex.getDMLMessage(indx));
      }
    }
  }

  //=================================================================================
  // MethodName  : getHistoryRecord
  // Description : creates a history record and retuns that record
  //================================================================================
  private static History__c createNewHistoryRec(SObject rec, Map<ID,String> mapOwnerIdWithName,
                                       Map<ID,String> mapOwnerIdWithUsersPrimaryQueue,
                                       Map<ID,String> mapQueueIdWithName, String changeType, String fieldToTrack) {
    ID ownerId = (String)rec.get('OwnerId');
    String userPrefix = DescribeUtility.getPrefix('User');
    History__c historyRec = new History__c();
    historyRec.Change_Type__c = changeType;
    String temp = (String)historyRec.put(historyParentFieldName, rec.Id);
    historyRec.Membership__c = rec.Id;
    historyRec.New_Status__c = (String)rec.get(fieldToTrack); //TODO if 'new value' is a record id, print the name instead of the id; data migration task if this field is changed to New Value, leaving new Status
    historyRec.Start_Time__c = DateTime.now();
    historyRec.Owner_Id__c = OwnerId;
    if ((String.ValueOf(ownerId)).startsWith(userPrefix)) {
      historyRec.Owner_Type__c = constants.HISTORY_OWNER_TYPE_USER ;

      historyRec.Owner_Name__c = mapOwnerIdWithName.get(ownerId);
      historyRec.Users_Primary_Queue__c = mapOwnerIdWithUsersPrimaryQueue.get(ownerId);
    }
    else {
      historyRec.Owner_Type__c = constants.HISTORY_OWNER_TYPE_QUEUE ;
      historyRec.Owner_Name__c = mapQueueIdWithName.get(ownerId);
    }
    return historyRec;
  }

  //=================================================================================
  // MethodName  : createUserMaps
  // Description : create maps for Owner and Queue
  //=================================================================================
  public static void createUserMaps() {
    ownerIdWithName = new Map<ID,String>();
    ownerIdWithUsersPrimaryQueue = new Map<ID,String>();
    queueIdWithName = new Map<ID, String>();
    for (User usr : [SELECT ID, Name ,
                     Primary_queue_name__c
                     FROM User
                     WHERE ID in :ownerIds]) {
      ownerIdWithName.put(usr.ID, usr.Name);
      ownerIdWithUsersPrimaryQueue.put(usr.ID, usr.Primary_queue_name__c);
    }
    for (Group grp : [SELECT ID, Name
                      FROM Group
                      WHERE ID in :ownerIds]) {
      queueIdWithName.put(grp.ID , grp.Name);
    }

  }
}