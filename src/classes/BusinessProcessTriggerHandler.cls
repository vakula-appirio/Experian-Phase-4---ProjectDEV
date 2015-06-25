/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessTriggerHandler
 * Description: T-360797: Action Plans: Code
 * Created Date: Feb 18th, 2015
 * Created By: Naresh kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Feb 24th, 2015               Arpita Bose (Appirio)        Added custom label BP_TEMP_ITEM_UPDATE_STATUS_SERVICE_CREATED
 * Mar 23rd, 2015               Naresh Kr Ojha               T-370674: Added Queue assignment logic as per task, updated buildProjectBusinessProcessFor()
 * Mar 24th, 2015               Naresh Kr Ojha               T-372780: Removed Business_Process__c.Sales_Support_Request__c Custom Field. 
 * Mar 26th, 2015               Naresh Kr Ojha               T-372601: Updated method name for buildProjectBusinessProcessFor() to createBusinessProcessItem() 
 * Mar 26th, 2015               Nathalie Le Guay (Appirio)   T-373784: populate bpi.Business_Hours__c field from template
 * Mar 27th, 2015               Terri Kellough               T-373995: Added CSDA_Type__c and CSDA_Service_Type__c mapping
 * Apr 05th, 2015               Terri Kellough               Added Account__c 
 * Apr 07th, 2015               Terri Kellough               T-376624 Added updateBusinessProcess 
 * Apr 08th, 2015               Terri Kellough               I-154648: revised to without sharing to get past
 *                                                           INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, insufficient access rights on cross-reference id: []: 
 *                                                           Class.BusinessProcessTriggerHandler.handleNewBusinessProcesses: line 136, column 1
 *                                                           The reason why this error is occurring is because some of the item links created are related to items 
 *                                                           either (1) not owned by the user applying the template or (2) user applying the 
 *                                                           template is not a member of the queue
  =====================================================================*/
public without sharing class BusinessProcessTriggerHandler {
  
  // New Objects being inserted
  private static Business_Process__c[] allNewBusinessProcesses = null;
  private static Business_Process_Item__c[] allNewBusinessProcessItems = null;
  private static Business_Process_Item_Link__c[] allNewBPILinks = null;
  
  // Indexes
  private static Map<Id, Business_Process__c> idToBusinessProcessMap;
  private static Set<Id> templateIds;
  private static Set<Id> oppIds; // NLG Dec 5th, 2014
  private static Set<Id> bpIDs;
  private static Map<String, Id> queues;  //[CBruzzi 7/2/08]
  private static Map<Id, List<Business_Process_Template_Item__c>> templateID_templateItemsMap;
  private static List<Business_Process_Template_Item_Link__c> templateItemLinks = null;
  private static Map<Id, List<Business_Process_Template_Item_Link__c>> itemToTemplateItemLinks = null;
  //private static Map<String, String> queueAssignments = null; //[BLorenz 10/21/2008]
  
  //==========================================================================
  // Before Insert Method
  //==========================================================================
  public static void beforeInsert (List<Business_Process__c> newList) {
    updateBusinessProcess(newList, null);
  }

  //==========================================================================
  // After Insert Method
  //==========================================================================
  public static void afterInsert (List<Business_Process__c> newList) {
    handleNewBusinessProcesses(newList);
  }

  //==========================================================================
  // Before Update Method
  //==========================================================================
  public static void beforeUpdate(List<Business_Process__c> newList, Map<ID, Business_Process__c> oldMap) {
    updateBusinessProcess(newList, oldMap);
  }
  //==========================================================================
  // After Update Method
  //==========================================================================
  public static void afterUpdate (List<Business_Process__c> newList, Map<ID, Business_Process__c> oldMap) {
    populateMembershipWithBPItems(newList, oldMap);
  }
  
  // reinitialize to allow multiple test method invocations.
  private static void initStaticFields() {
  
     allNewBusinessProcesses = null;
     allNewBusinessProcessItems = new Business_Process_Item__c[]{};
     allNewBPILinks = new Business_Process_Item_Link__c[]{};
  
     idToBusinessProcessMap = new Map<Id,Business_Process__c>();
     templateIds = new Set<Id>();
     oppIds = new Set<Id>(); // NLG Dec 5th, 2014
     bpIDs = new Set<Id>();
     queues = new Map<String, Id>();  //[CBruzzi 7/2/08]
     templateID_templateItemsMap = new Map<Id, List<Business_Process_Template_Item__c>>();
     templateItemLinks = new List<Business_Process_Template_Item_Link__c>();
     itemToTemplateItemLinks = new Map<Id, List<Business_Process_Template_Item_Link__c>>();
  }
  
  //=============================================================================
  // creates Busines Process Item and Item Links for Business Process.
  //=============================================================================
  public static void handleNewBusinessProcesses(List<Business_Process__c> newBusinessProcesses) {

    if (newBusinessProcesses == null || newBusinessProcesses.size() == 0) {
      return;
    }
    
    initStaticFields();    
    allNewBusinessProcesses = newBusinessProcesses;
    
    //Set<Id> projIds = new Set<Id>();
    
    for (Business_Process__c businessProcess : newBusinessProcesses) {
      idToBusinessProcessMap.put(businessProcess.Id, businessProcess);
      templateIds.add(businessProcess.Business_Process_Template__c);
      oppIds.add(businessProcess.Opportunity__c); // NLG Dec 5th, 2014
    }
                                   
    if (templateIds.size() == 0) {
      return;  
    }
    
    fetchTemplateItemsByTemplate(templateIds, templateID_templateItemsMap, bpIDs);
      
    if (templateID_templateItemsMap.keySet().size() == 0) {
      return;  
    }
      
      
    fetchTemplateItemLinks(bpIDs, itemToTemplateItemLinks, templateItemLinks);
    fetchQueuesByName();  //[CBruzzi 7/2/08]
    
    for(Integer i = 0; i < allNewBusinessProcesses.size(); ++i) {
      
      Business_Process__c businessProcess = allNewBusinessProcesses[i];
      if (businessProcess.Business_Process_Template__c == null) {
        continue;
      }
      //Added check for Map to have key: nojha Dec 8th, 2014.
      if (templateID_templateItemsMap.containsKey(businessProcess.Business_Process_Template__c)) { 
        for(Business_Process_Template_Item__c bpTemplateItem : templateID_templateItemsMap.get(businessProcess.Business_Process_Template__c)) {
          allNewBusinessProcessItems.add(createBusinessProcessItem(businessProcess, i, bpTemplateItem));
        } 
      }
    }

    if (allNewBusinessProcessItems.size() > 0) {
      insert allNewBusinessProcessItems;
    }

    for(Business_Process_Item__c bpi : allNewBusinessProcessItems) {    
      List<Business_Process_Template_Item_Link__c> links = itemToTemplateItemLinks.get(bpi.Business_Process_Template_Item__c);
      if (links != null) {
        for(Business_Process_Template_Item_Link__c link : links) {
          allNewBPILinks.add(createBusinessProcessItemLink (bpi, link)); //Creates item links
        }
      } 
    }
    
    if (allNewBPILinks.size() > 0) {
      insert allNewBPILinks;
    }
  }
  
  //==========================================================================
  // Create Business Process Item links
  //==========================================================================
  private static Business_Process_Item_Link__c createBusinessProcessItemLink (Business_Process_Item__c bpi, Business_Process_Template_Item_Link__c link) {
  	Business_Process_Item_Link__c itemLink = new Business_Process_Item_Link__c();
	  itemLink.Predecessor__c = bpi.id;
	  itemLink.Successor__c = findSuccessor(bpi.Business_Process__c, link.successor__c);
	  itemLink.Status__c = link.Status__c;
	  itemLink.Loop_Back_Link__c = link.Loop_Back_Link__c;
  	return itemLink;
  }
  
  //Returns Success ID
  private static Id findSuccessor(Id businessProcessId, Id businessProcessTempItemId) {
    for (Business_Process_Item__c bpItem : allNewBusinessProcessItems) {
      if (bpItem.Business_Process__c == businessProcessId && 
             bpItem.Business_Process_Template_Item__c == businessProcessTempItemId) {
        return bpItem.id;  
      }
    } 
    return null;
  }
  
  //===========================================================================
  // This method adds work items to map and set in second and third parameters
  //===========================================================================
  private static void fetchTemplateItemsByTemplate(Set<Id> bpTemplateIDs, 
                      Map<Id, List<Business_Process_Template_Item__c>> bpTemplateId_templateItemsMap, 
                                                                               Set<Id> wItemSet) {
    
    for (Business_Process_Template_Item__c templateItem :[SELECT  Id, Name, Business_Process_Template__c, Expire__c,
                                                                  Assign_To_Queue_when_Ready__c, Default_Owner__c, 
                                                                  Description__c, Final_State__c, Queue__c, Send_Owner_Email__c, 
                                                                  Sequence__c, Time_Quota__c, Wait_On_All_Preds__c,
                                                                  Update_Status_When__c, Business_Hours__c, CSDA_Type__c, CSDA_Service_Type__c
                                                          FROM  Business_Process_Template_Item__c 
                                                          WHERE Business_Process_Template__c <> null
                                                                AND Business_Process_Template__c in :bpTemplateIDs
                                                          ORDER BY Business_Process_Template__c, Sequence__c]) {
                                
      if (bpTemplateId_templateItemsMap.get(templateItem.Business_Process_Template__c) == null) {
        bpTemplateId_templateItemsMap.put(templateItem.Business_Process_Template__c, new List<Business_Process_Template_Item__c>());
      }
      bpTemplateId_templateItemsMap.get(templateItem.Business_Process_Template__c).add(templateItem);
      wItemSet.add(templateItem.Id); 

      //Collect queues referenced by work items [CBruzzi 7/2/08]
      if (templateItem.Queue__c != null && templateItem.Queue__c != '') {
        queues.put(templateItem.Queue__c, null);
      }
    }
  }
  
  //===========================================================================
  // Fetching template item links for template IDs passed.
  //===========================================================================
  private static void fetchTemplateItemLinks(Set<Id> templateItemIDs, 
                       Map<Id,List<Business_Process_Template_Item_Link__c>> bpMap, 
                              List<Business_Process_Template_Item_Link__c> links) {
    
    for (Business_Process_Template_Item_Link__c templateItemLink : [SELECT  Id, Status__c, Predecessor__c, Successor__c, Loop_Back_Link__c 
                                                                    FROM Business_Process_Template_Item_Link__c 
                                                                    WHERE Predecessor__c in :templateItemIDs 
                                                                    OR Successor__c in :templateItemIDs]) {
      
      if (!bpMap.containsKey(templateItemLink.Predecessor__c)) {
        bpMap.put(templateItemLink.Predecessor__c, new List<Business_Process_Template_Item_Link__c>());
      }
      bpMap.get(templateItemLink.Predecessor__c).add(templateItemLink);
      links.add(templateItemLink);
    }
  }
  
  //Retrieve list of IDs for the queue names referrenced by work items [CBruzzi 7/2/08]
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
  

  
  //===========================================================================
  // Create Business Process Items for Business Process by Business process Template Items.
  //===========================================================================
  private static Business_Process_Item__c createBusinessProcessItem(Business_Process__c businessProcess,
                                                              Integer projServiceIndex, Business_Process_Template_Item__c businessProcessTemplateItem) {

    Business_Process_Item__c newBusinessProcessItem = new Business_Process_Item__c(Business_Process_Template_Item__c = businessProcessTemplateItem.Id);
     
    newBusinessProcessItem.BPI_Name__c = businessProcessTemplateItem.Name;
    
    newBusinessProcessItem.Opportunity__c = businessProcess.Opportunity__c; // NLG Dec 5th, 2014
    newBusinessProcessItem.Case__c = businessProcess.Case__c; // NS Dec 9th, 2014
    newBusinessProcessItem.Account__c = businessProcess.Account__c; //TTK Apr 5th, 2015
    newBusinessProcessItem.Business_Process__c       = businessProcess.Id; 
    newBusinessProcessItem.Membership__c             = businessProcess.Membership__c;
    newBusinessProcessItem.CSDA_Type__c = businessProcessTemplateItem.CSDA_Type__c; //TTK Mar 27th, 2015
    newBusinessProcessItem.CSDA_Service_Type__c = businessProcessTemplateItem.CSDA_Service_Type__c; //TTK Mar 27th, 2015
    
    if (businessProcessTemplateItem.Queue__c != null
        && 
       (!queues.containsKey(businessProcessTemplateItem.Queue__c) || queues.get(businessProcessTemplateItem.Queue__c) == null)) {
      Trigger.new.get(0).addError(Label.BUSINESS_PROCESS_QUEUE_ERR);
    } else if (businessProcessTemplateItem.Queue__c != null &&
        queues.containsKey(businessProcessTemplateItem.Queue__c) &&  
        queues.containsKey(businessProcessTemplateItem.Queue__c) != null) {
      newBusinessProcessItem.OwnerId = queues.get(businessProcessTemplateItem.Queue__c);
    } else if (businessProcessTemplateItem.Default_Owner__c != null) {
      newBusinessProcessItem.OwnerId = businessProcessTemplateItem.Default_Owner__c;
    } else {
      newBusinessProcessItem.OwnerId = UserInfo.getUserId();
    }
    
    newBusinessProcessItem.Assign_To_Queue_when_Ready__c = businessProcessTemplateItem.Assign_To_Queue_when_Ready__c;
    newBusinessProcessItem.Default_Owner__c              = businessProcessTemplateItem.Default_Owner__c;
    newBusinessProcessItem.Description__c                = businessProcessTemplateItem.Description__c;
    newBusinessProcessItem.Update_Status_When__c         = businessProcessTemplateItem.Update_Status_When__c;
    newBusinessProcessItem.Final_State__c                = businessProcessTemplateItem.Final_State__c;
    newBusinessProcessItem.Queue__c                      = businessProcessTemplateItem.Queue__c;
    newBusinessProcessItem.Send_Owner_Email__c           = businessProcessTemplateItem.Send_Owner_Email__c;
    newBusinessProcessItem.Sequence__c                   = businessProcessTemplateItem.Sequence__c;
    newBusinessProcessItem.Time_Quota__c                 = businessProcessTemplateItem.Time_Quota__c;
    newBusinessProcessItem.Wait_On_All_Preds__c          = businessProcessTemplateItem.Wait_On_All_Preds__c;
    newBusinessProcessItem.Expire__c                     = businessProcessTemplateItem.Expire__c;
    newBusinessProcessItem.Business_Hours__c             = businessProcessTemplateItem.Business_Hours__c;
    
    if(businessProcessTemplateItem.Update_Status_When__c == system.Label.BP_TEMP_ITEM_UPDATE_STATUS_SERVICE_CREATED) {
      newBusinessProcessItem.Status__c = Constants.READY;
    }
 
    return newBusinessProcessItem;
   
  }

  //===========================================================================
  // As per task T-365621: on after update
  //===========================================================================
  public static void populateMembershipWithBPItems(List<Business_Process__c> newList, Map<ID, Business_Process__c> oldMap) {
    
    Map<ID, Business_Process__c> businessProcessMap = new Map<ID, Business_Process__c>();
    Map<ID, Business_Process_Item__c> bpItemMap = new Map<ID, Business_Process_Item__c>();
    
    for (Business_Process__c businessProcess : newList) {
      if (businessProcess.Membership__c != null && 
            businessProcess.Membership__c != oldMap.get(businessProcess.ID).Membership__c && 
              !businessProcessMap.containsKey(businessProcess.ID)) {
        businessProcessMap.put(businessProcess.ID, businessProcess);
      }
    }
    
    if (businessProcessMap.size() > 0) {
      for (Business_Process_Item__c bpItem : [SELECT Id, Business_Process__c 
                                              FROM Business_Process_Item__c 
                                              WHERE Business_Process__c IN: businessProcessMap.keySet()]) {
                                                
        if (businessProcessMap.containsKey(bpItem.Business_Process__c) && !bpItemMap.containsKey(bpItem.ID)) {
          bpItem.Membership__c = businessProcessMap.get(bpItem.Business_Process__c).Membership__c;
          bpItemMap.put(bpItem.ID, bpItem);
        }
      }
    }
    
    if (bpItemMap.size() > 0) {
      try{
        update bpItemMap.values();
      } catch(DMLException e) {
        apexLogHandler.createLogAndSave('BusinessProcessTriggerHandler','populateMembershipWithBPItems', e.getStackTraceString(), e);
        for (Integer indx = 0; indx < e.getNumDml(); indx++) {
          newList.get(0).addError(e.getDMLMessage(indx));
        }
      }
    }
  }

  //==========================================================================
  // Updates business process with business unit and sub business unit
  // information from business process template
  //==========================================================================
  private static void updateBusinessProcess (List<Business_Process__c> newList, Map<Id, Business_Process__c> oldMap) {
    List<Id> bpTemplateIdList = new List<Id>();
    Map<Id,Business_Process_Template__c> bpTemplateMap = new Map<Id, Business_Process_Template__c>();

    for (Business_Process__c bp : newList) {
      if (bp.Business_Process_Template__c != null &&
         (oldMap == null || (bp.Business_Process_Template__c != oldMap.get(bp.Id).Business_Process_Template__c))) {
        bpTemplateIdList.add(bp.Business_Process_Template__c);
      }
    }

    if (bpTemplateIdList.size() > 0 ) {
      for (Business_Process_Template__c bpt : [SELECT Id, Business_Unit__c, Sub_Business_Unit__c 
                                                FROM Business_Process_Template__c
                                                WHERE Id In: bpTemplateIdList]) {
        bpTemplateMap.put(bpt.Id, bpt);
      }

      for (Business_Process__c bp : newList) {
        if (bpTemplateMap.get(bp.Business_Process_Template__c) != null) {
          bp.Business_Unit__c = bpTemplateMap.get(bp.Business_Process_Template__c).Business_Unit__c;
          bp.Sub_Business_Unit__c = bpTemplateMap.get(bp.Business_Process_Template__c).Sub_Business_Unit__c;
        }
      }
    }

  }
}