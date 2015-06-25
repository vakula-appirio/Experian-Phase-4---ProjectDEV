/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessItemTriggerHandler
 * Description: T-360797: Action Plans: Code
 * Created Date: Feb 10th, 2015
 * Created By: Naresh kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Mar 16th, 2015               Noopur                       Modified the variable names
 * Mar 17th, 2015               Noopur                       T-370376 : Business Process - Skipped items
                                                             Added code to mark the skipped items.
 * Mar 26th, 2015               Nathalie Le Guay (Appirio)   T-373784: populate BPI.Business_Days_Ready__c
 *                                                           and Business_Hours__c
 * Apr 05th, 2015               Terri Kellough               T-375023 add Adhoc Business Process createAdHocBPI and associated methods
  =====================================================================*/
public class BusinessProcessItemTriggerHandler { 

  //private static final String CLASSNAME = 'Process_Project_Work_Items';
  public static String COMPLETED = 'Completed';
  public static String CLOSED = 'Closed';
  public static String READY = 'Ready';
  public static String CANCELLED = 'Cancelled';
  public static String SKIPPED = 'Skipped';
  public static String NOT_APPLICABLE = 'N/A';
  public static boolean processing = false; 
  public static Set<String> completedStatus = new Set<String>{COMPLETED, CANCELLED, NOT_APPLICABLE};
  private static Map<String, Id> queues = new Map<String, Id>();

  //parent id/sequence map used to sequence ad hoc business items
  private static Map<Id, Decimal> bpParentSequenceMap = new Map<Id, Decimal>(); 
  //parent id/business process map used to apply to ad hoc business items
  private static Map<Id, Id> bpParentBusinessProcessMap = new Map<Id, Id>();
  
  public class FileMoveException extends Exception {
  }
    
  private static void DEBUG(String msg) { System.debug('<<< DEBUG >>> ' + msg); }

  // Given a new Business_Process_Item__c and an old Business_Process_Item__c, determines whether it is moving FROM a 
  // completed state to an incomplete state.
  //TODO: Add check for N/A state too  
  private static boolean isBPICancelledOrCompleted(Business_Process_Item__c newBPI, Business_Process_Item__c oldBPI) {
    system.debug('****newBpi:::::'+newBPI+'  ****oldBPI::::'+oldBPI);  
    return ((oldBPI.status__c != COMPLETED && oldBPI.status__c != CANCELLED) &&
            (newBPI.status__c == COMPLETED || newBPI.status__c == CANCELLED));
  }
   
  private static boolean isBPICompleted(Business_Process_Item__c newBPI, Business_Process_Item__c oldBPI) {
    system.debug('****newBpi:::::'+newBPI+'  ****oldBPI::::'+oldBPI);
    return ((newBPI.Final_State__c) &&
            (oldBPI.status__c != COMPLETED && oldBPI.status__c != CANCELLED && oldBPI.status__c != NOT_APPLICABLE) &&
            (newBPI.status__c == COMPLETED || newBPI.status__c == CANCELLED || newBPI.status__c == NOT_APPLICABLE));
  }
  
  public static void beforeInsert(List<Business_Process_Item__c> newItems) {
    createAdHocBPI(newItems); //TTK Apr 5th, 2015 added
    
    String csdaBusinessHoursId = getDefaultBusinessHours();
    if (csdaBusinessHoursId ==  null) {
      newItems.get(0).addError(Label.BUSINESS_PROCESS_STD_BUSINESSHOUR_MISSING);
    }
    for (Business_Process_Item__c item: newItems) {
      if (item.Business_Hours__c == null) {
        item.Business_Hours__c = csdaBusinessHoursId;
      }
    }
  }

  public static void beforeUpdate(List<Business_Process_Item__c> newItems, Map<Id, Business_Process_Item__c> oldItems) {

    String csdaBusinessHoursId = getDefaultBusinessHours();
    if (csdaBusinessHoursId ==  null) {
      newItems.get(0).addError(Label.BUSINESS_PROCESS_STD_BUSINESSHOUR_MISSING);
    }
    for (Business_Process_Item__c bpi: newItems) {
      if (bpi.Business_Hours__c == null) {
        bpi.Business_Hours__c = csdaBusinessHoursId;
      }
      if (bpi.Business_Hours__c != null && bpi.Ready_Date__c != null && bpi.Completed_Date__c != null) {
        Business_Process_Item__c oldItem = oldItems.get(bpi.Id);
        if (bpi.Ready_Date__c != oldItem.Ready_Date__c || bpi.Completed_Date__c != oldItem.Completed_Date__c) {
          Long timeReady = BusinessHours.diff(bpi.Business_Hours__c,
                                              Datetime.newInstance(bpi.Ready_Date__c, Time.newInstance(0,0,0,0)),
                                              Datetime.newInstance(bpi.Completed_Date__c, Time.newInstance(0,0,0,0)));
          system.debug('\nDAYS READY FOR = ' + BusinessHours.diff(bpi.Business_Hours__c,
                                              Datetime.newInstance(bpi.Ready_Date__c, Time.newInstance(0,0,0,0)),
                                              Datetime.newInstance(bpi.Completed_Date__c, Time.newInstance(0,0,0,0))));
          bpi.Business_Days_Ready__c = timeReady / 86400000;
        }
      }
    }
  }
  
  public static void afterUpdate(Business_Process_Item__c[] new_BPItems, Business_Process_Item__c[] old_BPItems) {

    if (!processing) {
      processing = true;
    } else {
      DEBUG('REFUSING re-entry to trigger!');
      return;
    }

    moveBusinessProcessItemsToReady(new_BPItems, old_BPItems);
  }
  
  private static void moveBusinessProcessItemsToReady(Business_Process_Item__c[] new_BPItems, Business_Process_Item__c[] old_BPItems) {

    Set<Id> completedBPI = new Set<Id>();
    Set<Id> completedBusinessProcesses = new Set<Id>();

    for (Integer i = 0; i < new_BPItems.size(); ++i )  {

      Business_Process_Item__c new_item = new_BPItems[i];
      Business_Process_Item__c old_item = old_BPItems[i];
      System.debug('==isBPICancelledOrCompleted(new_item, old_item)=='+isBPICancelledOrCompleted(new_item, old_item));
      if (isBPICancelledOrCompleted(new_item, old_item)) {
          completedBPI.add(new_item.id);
      } 

      //Collect project services that should be closed [CBruzzi 6/30/08]
      if (isBPICompleted(new_item, old_item)) {
        completedBusinessProcesses.add(new_item.Business_Process__c);
      }
    }

    //Update project services that should be closed [CBruzzi 6/30/08]
    for (List<Business_Process__c> nextBPList:[SELECT ID, Status__c 
                                                    FROM Business_Process__c 
                                                    WHERE ID IN :completedBusinessProcesses AND Status__c =: Constants.OPEN]) {
      for (Business_Process__c nextBP : nextBPList ) {
        nextBP.Status__c = CLOSED;
        nextBP.Closed_Date__c = System.now(); //[JCripe 9/30/2008]
      }
      update nextBPList;
    }

    // gather up all successors of completing tasks that are in "Wait" or a closed state.
    Set<String> successorStatusSet = new Set<String>();
    successorStatusSet.add(Constants.STATUS_WAIT);
    successorStatusSet.add(Constants.STATUS_SUCCESS);
    successorStatusSet.add(Constants.STATUS_FAILED);
        
    Business_Process_Item_Link__c[] bpiLinks = [SELECT ID, Status__c, Loop_back_link__c,
                                                    Predecessor__c, Predecessor__r.Status__c, 
                                                    Successor__c, Successor__r.Status__c
                                             FROM Business_Process_Item_Link__c
                                             WHERE Predecessor__c IN :completedBPI
                                             AND Successor__r.Status__c IN: successorStatusSet];
    System.debug('===BPILinks===='+bpiLinks);
    Set<Id> successors = new Set<Id>();
    Map<Id, Id[]> pending2preds = new Map<Id, Id[]>();
      
    String debugStr = '\n\nWAITING SUCCESSORS:\n';
       
    for (Business_Process_Item_Link__c link : bpiLinks) {
        System.debug(link.Successor__c + '===debug if 1.01====' + (link.Successor__c != null));
        System.debug(link.Status__c + '===debug if 1.02===='  + link.Predecessor__r.Status__c + '~~~~' + (link.Status__c == link.Predecessor__r.Status__c));
      if (link.Successor__c != null && link.Status__c == link.Predecessor__r.Status__c) {
        successors.add(link.successor__c);
        pending2preds.put(link.successor__c, new List<Id>());                                       
        debugStr += link.predecessor__c + ' => ' + 
                    link.successor__c + ' ' + 
                    link.successor__r.status__c + ';\n';
      }  
    }
      
    // gather up all waiting predecessors statuses for the waiting tasks.
    system.debug('*******successors:::::::::'+successors);  
    Business_Process_Item_Link__c[] pred_links = [SELECT ID, Status__c, Loop_back_link__c,
                                                       Predecessor__c, Predecessor__r.Status__c, 
                                                       Successor__c, Successor__r.Status__c
                                                  FROM Business_Process_Item_Link__c
                                                  WHERE Successor__c IN :successors 
                                                   and Predecessor__r.Status__c != :COMPLETED];
      
    Set<Id> loopbacks = new Set<Id>();
                                          
    debugStr += '\n\nINCOMPLETE PREDECESSORS:\n';
    System.debug('===pred_links===='+pred_links);  
    for (Business_Process_Item_Link__c  link : pred_links) {
        System.debug('===debug if 1.1===='+(!link.loop_back_link__c && link.status__c != link.predecessor__r.status__c));
      if (!link.loop_back_link__c && link.status__c != link.predecessor__r.status__c) {
        pending2preds.get(link.successor__c).add(link.predecessor__c);                                      
        debugStr += link.successor__c + ' waiting on ' + 
                      link.predecessor__c + ' ' + 
                      link.predecessor__r.status__c + ';\n';
      } else if (link.loop_back_link__c) {
          loopbacks.add(link.predecessor__c);   
      }  
    }
      
    debugStr += '\n\nREADY TO RUN:\n';
      
    Set<Id> bpiToUpdate = new Set<Id>();
      
    for (Id key : pending2preds.keySet()) {
      if (pending2preds.get(key).size() == 0) {
        bpiToUpdate.add(key);
        debugStr += key + ';\n';
      }
    }
      
    DEBUG(debugStr);
      
    // SELECT and update successors that should have status moved FROM 'Wait' to 'Ready';
      
    if (bpiToUpdate.size() > 0 || completedBusinessProcesses.size() > 0) {
        
      List<Business_Process_Item__c> businessProcessItems = new List<Business_Process_Item__c>();
        
      for (Business_Process_Item__c businessProcessItem : [SELECT Id, Status__c,Business_Process__c 
                                                           FROM Business_Process_Item__c 
                                                           WHERE Id IN :bpiToUpdate
                                                           OR Business_Process__c IN :completedBusinessProcesses]) {
        if ( completedBusinessProcesses.contains(businessProcessItem.Business_Process__c) && !completedStatus.contains(businessProcessItem.Status__c) ) {
            businessProcessItem.Status__c = SKIPPED;
            businessProcessItems.add(businessProcessItem);
        }
        else if ( bpiToUpdate.contains(businessProcessItem.Id) ) {
            businessProcessItem.Status__c = READY;
            businessProcessItems.add(businessProcessItem);
        }
      }
      
      if (businessProcessItems.size() > 0) {
        system.debug('*****businessProcessItems:::::::'+businessProcessItems);  
        try {
          update businessProcessItems;
        }  catch (DMLException ex) {
          system.debug('[BusinessProcessItemTriggerHandler: moveBusinessProcessItemsToReady] Exception: ' + ex.getMessage());
          ApexLogHandler.createLogAndSave('BusinessProcessItemTriggerHandler','moveBusinessProcessItemsToReady', ex.getStackTraceString(), ex);
          for (Integer i = 0; i < ex.getNumDml(); i++) {
            new_BPItems.get(0).addError(ex.getDMLMessage(i));
          }
        }
      }
    }
  }
  
   //==========================================================================
  // Will get the default Business Hours set for the company
  //==========================================================================
  private static String getDefaultBusinessHours() {
    try{
      return  [SELECT Id 
               FROM BusinessHours
               WHERE IsDefault = true AND IsActive = true
               LIMIT 1].Id;
    } catch (Exception ex){
      apexLogHandler.createLogAndSave('BusinessProcessItemTriggerHandler','getDefaultBusinessHours', ex.getStackTraceString(), ex);
    }
    return null;
  }

  //=========================================================================
  //Allows creating an adhoc bpi from the parent (an Account, Case, Membership, 
  //or Opportunity ) by
  // (1) optionally applying a business process template item 
  // (2) parent's business process with the add hoc bpi
  //=========================================================================
  private static void createAdHocBPI(List<Business_Process_Item__c> newItems) {
    // bpti id/bpti object map
    Map<Id, Business_Process_Template_Item__c> bptiMap = new Map<Id, Business_Process_Template_Item__c>();
    
    // Id Sets
    Set<Id> bptiIdSet = new Set<Id>();
    Set<Id> accIdSet = new Set<Id>();
    Set<Id> oppIdSet = new Set<Id>();
    Set<Id> memIdSet = new Set<Id>();
    Set<Id> caseIdSet = new Set<Id>();

    //Get the bpi's parent ids and bpi's bpti ids
    for(Business_Process_Item__c bpi : newItems) {
      if (bpi.Business_Process_Template_Item__c != null) {
        bptiIdSet.add(bpi.Business_Process_Template_Item__c);
      }
      if (bpi.Case__c != null) {
        caseIdSet.add(bpi.Case__c);
      }
      if (bpi.Membership__c != null) {
        memIdSet.add(bpi.Membership__c);
      }
      if (bpi.Opportunity__c != null) {
        oppIdSet.add(bpi.Opportunity__c);
      }
      if (bpi.Account__c != null) {
        accIdSet.add(bpi.Account__c);
      }
    }

    //Get business processes' items max sequence related to the parent, and choose 1 
    getAdHocParentBP(memIdSet, caseIdSet, oppIdSet, accIdSet);

    //Get relevant bpti fields 
    bptiMap = getAdHocBPTI(bptiIdSet);  

    fetchQueuesByName();

    //Update the bpi with the business process template item and one of the parent's business processes
    for (Business_Process_Item__c bpi : newItems) {
      boolean applyTemplate = false;

      Business_Process_Template_Item__c bpti = bptiMap.get(bpi.Business_Process_Template_Item__c);

      //conditions to apply bpti template and bp to template item
      if (bpi.Business_Process__c == null && bpi.Business_Process_Template_Item__c != null) {
        //apply business process fields
        bpi = setAdHocBpiBp(bpi);
        //apply business process template item fields
        bpi = setAdHocBpiBpti(bpi, bptiMap);
      }
    }
  }

  //==============================================================
  // get business process template item fields for add hoc BPTI
  //==============================================================
  private static Map<Id, Business_Process_Template_Item__c> getAdHocBPTI(Set<Id> bptiIdSet) {
    Map<Id, Business_Process_Template_Item__c> bptiMap = new Map<Id, Business_Process_Template_Item__c>();

    //Get relevant bpti fields 
    for (Business_Process_Template_Item__c bpti : [SELECT Id, Name, Description__c, Business_Hours__c,
                                                          Assign_To_Queue_when_Ready__c, Default_Owner__c,
                                                          Update_Status_When__c, Queue__c, Send_Owner_Email__c,
                                                          Time_Quota__c, Expire__c, 
                                                          CSDA_Type__c, CSDA_Service_Type__c 
                                                   FROM Business_Process_Template_Item__c 
                                                   WHERE Id In: bptiIdSet]) {
      // Collect template's queue names
      if (String.isNotEmpty(bpti.Queue__c)) {
        queues.put(bpti.Queue__c, null);
      }

      bptiMap.put(bpti.Id, bpti);
    }

    return bptiMap;
  }

  //==============================================================
  // Get ad hoc bpi's parent's business process info
  //==============================================================
  private static void getAdHocParentBP (Set<Id> memIdSet, Set<Id> caseIdSet,
                                        Set<Id> oppIdSet, Set<Id> accIdSet) {
    Id parentId;
    Boolean getSequence = false;

    // Get business processes related to the parent, and choose 1 
    for (Business_Process__c bp : [SELECT Id, Membership__c, Case__c, Account__c, Opportunity__c,
                                          (SELECT Id, Sequence__c 
                                           FROM Business_Process_Items__r
                                           ORDER BY Sequence__c DESC 
                                           LIMIT 1) 
                                   FROM Business_Process__c 
                                   WHERE Membership__c In: memIdSet
                                      OR Case__c In: caseIdSet
                                      OR Account__c In: accIdSet
                                      OR Opportunity__c In: oppIdSet]) {
      parentId = null;
      getSequence = false;
      if (bp.Membership__c != null) {
        parentId = bp.Membership__c;
        getSequence = true;
      }
      else if (bp.Case__c != null) {
        parentId = bp.Case__c;
        getSequence = true;
      } else if (bp.Account__c != null) {
        parentId = bp.Account__c;
        getSequence = true;
      } else if (bp.Opportunity__c != null) {
        parentId = bp.Opportunity__c;
        getSequence = true;
      }

      if (getSequence == true) {
        bpParentBusinessProcessMap.put(parentId, bp.Id);
        if (bp.Business_Process_Items__r.size() > 0) {
          bpParentSequenceMap.put(parentId, bp.Business_Process_Items__r[0].Sequence__c);
        }
      }
    }

    //return bpParentSequenceMap;
  }
  
  //==============================================================
  // set the business process related fields on the Ad Hoc Bpi
  //==============================================================
  private static Business_Process_Item__c setAdHocBpiBp(Business_Process_Item__c bpi) {
    String parentId;

    if (bpi.Case__c != null) {
      parentId = bpi.Case__c;
    } else if (bpi.Membership__c != null) {
      parentId = bpi.Membership__c; 
    } else if (bpi.Account__c != null) {
      parentId = bpi.Account__c;
    } else if (bpi.Opportunity__c != null) {
      parentId = bpi.Opportunity__c;
    } else {
      parentId = null;
    }

    if (bpParentSequenceMap.get(parentId) != null ) {
      //apply business process
      bpi.Business_Process__c = bpParentBusinessProcessMap.get(parentId);
      System.debug('BusinessProcessItemTriggerHandler:createAdHocBPIFromTemplate: bpi.Business_Process__c ' + bpi.Business_Process__c);

      //apply sequence #
      if (bpParentSequenceMap.get(parentId) != null) {
          //increment sequence
          Decimal newSequence = bpParentSequenceMap.get(parentId) + 1;
          bpParentSequenceMap.put(parentId, newSequence);
          bpi.Sequence__c = newSequence;
      } 
    }
    return bpi;
  }

  //==============================================================
  // set the business process template item related fields on the Ad Hoc Bpi
  //==============================================================
  private static Business_Process_Item__c setAdHocBpiBpti(Business_Process_Item__c bpi, 
    Map<Id, Business_Process_Template_Item__c> bptiMap) {
    Business_Process_Template_Item__c templateItem = bptiMap.get(bpi.Business_Process_Template_Item__c);
    bpi.BPI_Name__c                   = templateItem.Name;
    bpi.Description__c                = templateItem.Description__c;
    bpi.Business_Hours__c             = templateItem.Business_Hours__c;
    bpi.Assign_To_Queue_when_Ready__c = templateItem.Assign_To_Queue_when_Ready__c;
    bpi.Default_Owner__c              = templateItem.Default_Owner__c;
    bpi.Update_Status_When__c         = templateItem.Update_Status_When__c;
    bpi.Queue__c                      = templateItem.Queue__c;
    bpi.Send_Owner_Email__c           = templateItem.Send_Owner_Email__c;
    bpi.Time_Quota__c                 = templateItem.Time_Quota__c; 
    bpi.Expire__c                     = templateItem.Expire__c;
    bpi.CSDA_Type__c                  = templateItem.CSDA_Type__c;
    bpi.CSDA_Service_Type__c          = templateItem.CSDA_Service_Type__c;

    if (bpi.Queue__c != null
        && 
       (!queues.containsKey(bpi.Queue__c) || queues.get(bpi.Queue__c) == null)) {
      bpi.addError(Label.BUSINESS_PROCESS_QUEUE_ERR);
    } else if (bpi.Queue__c != null &&
        queues.containsKey(bpi.Queue__c) &&  
        queues.containsKey(bpi.Queue__c) != null) {
      bpi.OwnerId = queues.get(bpi.Queue__c);
    } else if (bpi.Default_Owner__c != null) {
      bpi.OwnerId = bpi.Default_Owner__c;
    } else {
      bpi.OwnerId = UserInfo.getUserId();
    }
    
    return bpi;
  }

  //==============================================================
  // fetch queue ids for the queues associated with the bpti queue names
  //==============================================================
  private static void fetchQueuesByName() {
    
    if (queues.isEmpty()) {
      return;
    }
      
    for (Group queueGroups : [SELECT Id, Name 
                              FROM Group 
                              WHERE Name in :queues.keySet() AND Type =: Constants.STR_QUEUE]) {
      queues.put(queueGroups.Name, queueGroups.id);
    }
  }
}