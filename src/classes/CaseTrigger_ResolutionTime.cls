/**=====================================================================
 * Appirio, Inc
 * Name: CaseTrigger_ResolutionTime
 * Description: T-310733: Helper class for Case Resolution Time Tracking
 * Created Date: Sep 08th, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Sep 12th, 2014               Arpita Bose                  S-252787: Modified class to fix the failure on Case record creation
 * Feb 04th, 2015               Naresh Kumar Ojha            T-358487: Added record type CSDA Contract Request to track case history.
 * Feb 24th, 2015               Naresh Kr Ojha               T-365485: Updated code to adopt History__c object instead Case_History__c as per task. 
 * Jun 18th, 2015               Naresh Kr Ojha               T-411739: Updated method createCaseHistoryRec() as per task.
  =====================================================================*/

public class CaseTrigger_ResolutionTime{

  public static  Set<Id> setOwnerId = new Set<Id>();
  public static Set<Id> setQueueId = new Set<Id>();
  public static Map<Id, User> mapUser = new Map<Id, User>();
  public static Map<Id, Group> mapQueue = new Map<Id, Group>();
  public static Set<Id> setRecordType = new Set<Id>();
  public static List<String> caseRecType = new List<String> {Constants.CASE_REC_TYPE_CCM_NA_CASE, 
                                                             Constants.CASE_REC_TYPE_EDQ_CASE,
                                                             Constants.CASE_REC_TYPE_CSDA_CONT_REQ,
                                                             Constants.RECORDTYPE_CASE_CSDA_BIS_SUPPORT,
                                                             Constants.RECORDTYPE_CASE_CSDA_CIS_BA_REQUEST,
                                                             Constants.RECORDTYPE_CASE_CSDA_CIS_SUPPORT};
  public static History__c caseHistory;
  public static String userPrefix = DescribeUtility.getPrefix('User');
  //public static List<History__c> listCaseHistory = new List<History__c>();

  // T-310733:After Insert method for creating initial Case history Record
  public static void createCaseHistoryRec(LIST<Case> lstNew) {
    List<History__c> listCaseHistory = new List<History__c>();    
    //Collecting record type ids 
    for (RecordType rt : [SELECT Id, Name FROM RecordType 
                          WHERE RecordType.Name IN :caseRecType]) {
        setRecordType.add(rt.Id);
    }
    //check ownerId contains user or queue
    for (Case caseRec : lstNew) {
      String ownerId = caseRec.OwnerId;
      System.debug('===userPrefix==='+userPrefix);
      System.debug(ownerId+'===ownerId.startsWith(userPrefix)==='+ownerId.startsWith(userPrefix));
      if (ownerId.startsWith(userPrefix)) {
        setOwnerId.add(caseRec.OwnerId);
      }
      else {
        setQueueId.add(caseRec.OwnerId);
      }
    }
    
    //Fetching Owners details
    if (setOwnerId.size() > 0) {
        mapUser = getMapOfUser(setOwnerId);                        
    }
    System.debug('==setQueueId=='+setQueueId);
    if (setQueueId.size() > 0) {
        mapQueue = getMapOfQueue(setQueueId);
    }
        
    //Creating Case History
    for (Case caseRec : lstNew) {
        if (setRecordType.contains(caseRec.RecordTypeId)) {
            User myUser = null;
            System.debug('~~~~myUser~~~'+myUser);
            if (mapUser.containsKey(caseRec.OwnerId)) {
              myUser = mapUser.get(caseRec.OwnerId);
            }
            //if (myUser != null) {
              caseHistory = getCaseHistoryRec(caseRec, myUser ); 
              caseHistory.Change_type__c = Constants.CASE_CHANGE_TYPE_STATUS; 
              listCaseHistory.add(caseHistory);
            //}
        }
    }

    try {    
       //Inserting Case History
       if (listCaseHistory.size() > 0) {
          insert listCaseHistory;
       }
    } catch(DmlException ex){
        apexLogHandler.createLogAndSave('CaseTrigger_ResolutionTime','afterInsert', ex.getStackTraceString(), ex);
        for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          lstNew.get(0).addError(ex.getDMLMessage(indx));
        }
    }   
    
  }

  public static void caseResolutionTimeTrackingProcess(List<Case> lstOld, List<Case> lstNew, Map<Id, Case> newMap, Map<Id,Case> oldMap) {
    Set<Id> setCaseChangeId = new Set<Id>();
    List<Case> listCase = new List<Case>();
    Set<Id> setParentCaseId = new Set<Id>();
    List<History__c> listCaseHistory = new List<History__c>();

    // Collecting record type ids
    for(RecordType rt : [SELECT Id, Name FROM RecordType 
                         WHERE RecordType.Name IN :caseRecType]){
        setRecordType.add(rt.Id);
    }

    // collecting sub case ids
    for (Case caseRec : lstNew) {       
       if (setRecordType.contains(caseRec.RecordTypeId) && 
           (caseRec.OwnerId != oldmap.get(caseRec.Id).OwnerId || caseRec.Status != oldmap.get(caseRec.Id).Status)) {
            setCaseChangeId.add(caseRec.Id);
       }
       String ownerId = caseRec.OwnerId;
       if (ownerId.startsWith(userPrefix)) {
            setOwnerId.add(caseRec.OwnerId);
       }
       else {
            setQueueId.add(caseRec.OwnerId);
       }
    }
    System.debug('~~~~setCaseChangeId~~~'+setCaseChangeId);
    // Fetching Owners details
    if (setOwnerId.size() > 0) {
        mapUser = getMapOfUser(setOwnerId);                           
    } 
        
    if (setQueueId.size() > 0) {
        mapQueue = getMapOfQueue(setQueueId);
    }
        
    // Updating previous Case History for End time      
    if (setCaseChangeId.size() > 0) {
        for (Case caseRec : [SELECT Id, RecordTypeId, IsParent__c, Service_Desk_Parent_Case__c, Status, IsClosed, 
                              (SELECT Id, End_time__c 
                                FROM Case_History__r 
                                ORDER BY CreatedDate desc limit 1) 
                             FROM Case 
                             WHERE Id IN :setCaseChangeId]) {
            System.debug('***caseRec.Case_History__r**'+caseRec.Case_History__r);
            if (caseRec.Case_History__r != null && caseRec.Case_History__r.size() > 0) {
                caseHistory = new History__c(Id = caseRec.Case_History__r.get(0).Id, End_time__c = DateTime.now());
                listCaseHistory.add(caseHistory);
                System.debug('~~~caseRec.Case_History__r~~~'+listCaseHistory.size());

                System.debug('~~~setRecordType.contains(caseRec.RecordTypeId)~~~'+setRecordType.contains(caseRec.RecordTypeId));
                System.debug('~~~caseRec.IsParent__c~~~'+caseRec.IsParent__c);
                System.debug('~~~caseRec.Service_Desk_Parent_Case__c~~~'+caseRec.Service_Desk_Parent_Case__c);
                System.debug('~~~caseRec.Status != oldmap.get(caseRec.Id).Status~~~'+(caseRec.Status != oldmap.get(caseRec.Id).Status));
                  
                // Filter Parent Case for updating child cases
                if (setRecordType.contains(caseRec.RecordTypeId) && caseRec.IsParent__c 
                      && caseRec.Service_Desk_Parent_Case__c == null && caseRec.Status != oldmap.get(caseRec.Id).Status) {
                    setParentCaseId.add(caseRec.Id);
                }
            }
        }
    }
    System.debug('~~~~~~~~lstNew~~~~'+lstNew);  
    //create case history records
    for (Case caseRec : lstNew) {
      String ownerId = caseRec.OwnerId;
      User myUser = mapUser.get(caseRec.OwnerId);

      if (myUser == null) {
          continue;
      }
      
      if (myUser != null) {
          // create case history for change type = 'Owner'
          if (setRecordType.contains(caseRec.RecordTypeId) && caseRec.OwnerId != oldmap.get(caseRec.Id).OwnerId) {
            caseHistory = new History__c();
            caseHistory.Change_type__c = Constants.CASE_CHANGE_TYPE_OWNER; 
            caseHistory = getCaseHistoryRec(caseRec, myUser ); 
            listCaseHistory.add(caseHistory);
          }
          // create case history for change type='Status'
          else if (setRecordType.contains(caseRec.RecordTypeId) && caseRec.Status != oldmap.get(caseRec.Id).Status) {
            caseHistory = getCaseHistoryRec(caseRec, myUser );
            caseHistory.Change_type__c = Constants.CASE_CHANGE_TYPE_STATUS;  
            listCaseHistory.add(caseHistory);
          }
      }
      
      System.debug('===setParentCaseId=='+setParentCaseId);
      // Updating child case status
      if (setParentCaseId.size() > 0){
        for (Case caseRecord : [SELECT Id, status, Case_Owned_by_Queue__c, Service_Desk_Parent_Case__r.status, 
                                    IsClosed, Service_Desk_Parent_Case__c 
                                FROM Case 
                                WHERE Service_Desk_Parent_Case__c IN :setParentCaseId 
                                AND RecordTypeId IN :setRecordType]) {
            System.debug('===caseRecord=='+caseRecord);
            if (!caseRecord.IsClosed && caseRecord.Case_Owned_by_Queue__c && 
                  !newmap.get(caseRecord.Service_Desk_Parent_Case__c).IsClosed) {
              caseRecord.status = newmap.get(caseRecord.Service_Desk_Parent_Case__c).Status;
              listCase.add(caseRecord);
            }

            if (newmap.get(caseRecord.Service_Desk_Parent_Case__c).IsClosed) {
              caseRecord.status = newmap.get(caseRecord.Service_Desk_Parent_Case__c).Status;
              listCase.add(caseRecord);
            }
        } 
        try { 
          // Updating Cases 
          if (listCase.size() > 0) {
            update listCase;
          }
        } catch(DmlException ex){
            apexLogHandler.createLogAndSave('CaseTrigger_ResolutionTime','caseResolutionTimeTrackingProcess', ex.getStackTraceString(), ex);
            for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
              lstNew.get(0).addError(ex.getDMLMessage(indx));
            }
        }
      } 
      
      try {
        // Upserting Case History
        if (listCaseHistory.size() > 0) {
          upsert listCaseHistory;
        }
      } catch(DmlException ex){
          apexLogHandler.createLogAndSave('CaseTrigger_ResolutionTime','CaseTrigger_ResolutionTime', ex.getStackTraceString(), ex);
          for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
            lstNew.get(0).addError(ex.getDMLMessage(indx));
          }
      }
   }
 } 
  // generic method to create Case history
  public static History__c getCaseHistoryRec (Case currentCase, User userRec) {
    String ownerId = currentCase.OwnerId;
    caseHistory = new History__c();
    caseHistory.Case__c = currentCase.Id;
    if (ownerId.startsWith(userPrefix)) {
      caseHistory.Owner_Type__c = Constants.CASE_HISTORY_OWNER_TYPE_USER;
      caseHistory.Owner_name__c = userRec.Name;
      caseHistory.Users_Primary_Queue__c = userRec.Primary_queue_name__c;
    }
    else {
      caseHistory.Owner_Type__c = Constants.CASE_HISTORY_OWNER_TYPE_QUEUE;
      caseHistory.Owner_name__c = mapQueue.get(ownerId).Name;
    }
    caseHistory.Owner_id__c = ownerId;
    caseHistory.Start_time__c = DateTime.now();
    caseHistory.New_status__c = currentCase.Status;
    caseHistory.Case_Severity__c = currentCase.Severity__c; 
    return caseHistory;
  }

  // generic method to get map of User
  public static Map<Id, User> getMapOfUser(Set<Id> ownerIds){
    // retrieve map of User Records
    return new Map<Id, User>([SELECT Id, Primary_queue_name__c, Email, Name 
                              FROM User 
                              WHERE Id IN :ownerIds]);        
  }

  // generic method to get map of Queue
  public static Map<Id, Group> getMapOfQueue(Set<Id> queueIds){
    // retrieve map of Group Records
    return new Map<Id, Group>([SELECT Id, Name 
                               FROM Group 
                               WHERE Id IN :queueIds]);
  }
}