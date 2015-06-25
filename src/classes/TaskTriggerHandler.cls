/**====================================================================================
 * Appirio, Inc
 * Name: TaskTriggerHandler
 * Description: TaskTriggerHandler on Story (S-209627)
 * Created Date: Aug 1st, 2014
 * Created By: Bharti Mehta (Appirio) 
 * 
 * Modified Date        Modified By      Description of the update
 * Jul 31, 2014         Nathalie Le Guay             T-309151: Create a Project Resource record if a Task's Owner is updated to a new User
 *                                                           Task must: 1) Have "Project & Delivery" RT; 2) Assign_Resource__c == true;
 *                                                                      3) WhatId = Delivery_Line__c or Project__c
 * Aug 01, 2014         Naresh Kr Ojha               T-309151: Updated method createProjectResources()
 * Aug 01, 2014         Bharti Mehta (Appirio)       S-209627: Account Planning
 * Aug 04, 2014         Nathalie Le Guay             T-309151: Added Task.Assign_Resource__c check in createProjectResources()
 * Sep 5, 2014          James Weatherall             Case 1949 - Added beforeInsert method which 
 *                                                   calls the new setCampaignWhenConverted method.
 *                                                   This sets the Related To field to the last 
 *                                                   associated Campaign when a Lead is converted.  
 * Oct 13, 2014         Pallavi Sharma               T-325097 (Dispatch Note: Task Trigger Handler): dispatchNote()
 * Dec 2nd, 2014		James Weatherall		     Case 21211 - Modified if statement to prevent error when Email to Case is used 
 * 																  and no Contact exists
 ======================================================================================*/ 

 public class TaskTriggerHandler {

  public static void beforeInsert(List<Task> newTasks){
    setCampaignWhenConverted(newTasks);      
  }
  
  //After Insert Call   
  public static void afterInsert (List<Task> newList) {
    createProjectResources(newList, null);
    refreshOppScoreCalculations();
    dispatchNote(newList);
  }

  //Before Update Call
  public static void afterUpdate (List<Task> newList, Map<Id, Task> oldMap) {
    createProjectResources(newList, oldMap);
  }
  
  public static void afterDelete(){
    refreshOppScoreCalculations();
    
  }
  
  
    //========================================================================================
  // Name: createProjectResources
  // Will take a list of Task records and will create Project_Resource__c records
  // where necessary
  //========================================================================================
  private static void createProjectResources(List<Task> tasks, Map<Id, Task> oldTasks) {
    
    // Retrieve related projects, if owner of Delivery Line was changed
    Set<String> projectIds = new Set<String>();
    Map<String, String> taskIdToProjectId = new Map<String, String>();
    Set<String> dlIds = new Set<String>();
    String whatId;

    String deliveryRTid = DescribeUtility.getRecordTypeIdByName('Task', 'Project and Delivery');
    String deliveryLinePrefix = DescribeUtility.getPrefix('Delivery_Line__c');
    String projectPrefix = DescribeUtility.getPrefix('Project__c');

    for (Task task: tasks) {
      whatId = (String) task.whatId;
      
      if (task.RecordTypeId != deliveryRTid || task.Assign_Resource__c == false
         || (task.WhatId != null && !whatId.startsWith(deliveryLinePrefix) && !whatId.startsWith(projectPrefix))) {
        continue;
      }
      
      if (oldTasks == null || (oldTasks != null && (oldTasks.get(task.Id).OwnerId != task.OwnerId
                                                 || oldTasks.get(task.Id).Assign_Resource__c != task.Assign_Resource__c
                                                 || oldTasks.get(task.Id).RecordTypeId != task.RecordTypeId))) {
        if (task.WhatId != null) {
          if (whatId.startsWith(projectPrefix)) {
            projectIds.add(task.WhatId);
            taskIdToProjectId.put(task.Id, task.WhatId);
          } else if (whatId.startsWith(deliveryLinePrefix)) {
            dlIds.add(task.WhatId);
          }
        }
      }
    }

    if (dlIds.size() > 0) {
      Map<Id, Delivery_Line__c> dls = new Map<Id, Delivery_Line__c>([SELECT Id, Project__c
                                    FROM Delivery_Line__c
                                    WHERE Id in : dlIds AND Project__c != null]);
      for (Delivery_Line__c dl : dls.values()) {
        projectIds.add(dl.Project__c);
      }
      for (Task task: tasks) {
        whatId = (String) task.whatId;
        if (whatId.startsWith(deliveryLinePrefix)) {
          taskIdToProjectId.put(task.Id, dls.get(whatId).Project__c);
        }
      }
     }

    // Query all projects and related Project Resources
    Map<Id, Project__c> projectMap = new Map<Id, Project__c>([SELECT Id, OwnerId,
                                    (SELECT Id, Resource__c FROM Project_Resources__r)
                             FROM Project__c
                             WHERE Id in: projectIds]);

    // Create a Project Resource record if none exists
    List<Project_Resource__c> prToCreate = new List<Project_Resource__c>();
    for (Task task: tasks) {
      system.debug(taskIdToProjectId+'\nTasks project: '+ projectMap + '**taskIdToProjectId.get(task.Id)**'+taskIdToProjectId.get(task.Id));

      if (taskIdToProjectId.containsKey(task.Id) &&
             projectMap.containsKey(taskIdToProjectId.get(task.Id)) && 
             !ProjectResource_Utils.hasProjectResource(task.OwnerId, projectMap.get(taskIdToProjectId.get(task.Id)).Project_Resources__r)) {
        prToCreate.add(ProjectResource_Utils.createNewProjectResourceRecord(taskIdToProjectId.get(task.Id), task.OwnerId));
      }
    }

    if (prToCreate.size() > 0) {
      ProjectResource_Utils.createProjectResourceRecords(prToCreate);
    }
  }
  
  // Case 1949 - Created by James Weatherall   
  public static void setCampaignWhenConverted(List<Task> newTasks) {
    Set<Id> setContactIds = new Set<Id>();
    Set<Id> setConvertedContactIds = new Set<Id>();
    Map<Id, Id> mapCampaigns = new Map<Id, Id>();
    
    for (Task t : newTasks) {
      // Case 21211 - Modified if statement to check whether Contact is null
      if (t.WhatId == null && t.WhoId != null) { 
      	if(t.WhoId.getSobjectType() == Schema.Contact.sObjectType) {
          System.Debug('Working?');
          setContactIds.add(t.WhoId);
      	}
      }
    }
    System.Debug('setContactIds = ' + setContactIds);
    if (setContactIds.size() > 0) {
      
      for (Lead l : [SELECT Id, ConvertedContactId 
                     FROM Lead 
                     WHERE SystemModstamp > :Datetime.now().addMinutes(-1) AND ConvertedContactId in: setContactIds])
      {
        setConvertedContactIds.add(l.ConvertedContactId);          
      }
      System.Debug('setConvertedContactIds = ' + setConvertedContactIds);
      if(setConvertedContactIds.size() > 0) {
        // Should we only select IsActive Campaigns?
        for (CampaignMember cm : [SELECT Id, CampaignId, ContactId 
                                  FROM CampaignMember 
                                  WHERE ContactId in: setConvertedContactIds
                                  ORDER BY Campaign.CreatedDate DESC]) {
          System.Debug('*******cm********' + cm);
          if (!mapCampaigns.containsKey(cm.ContactId)) {
            mapCampaigns.put(cm.ContactId, cm.CampaignId);     
          }
        }      
      }
    }
    
    for (Task t : newTasks) {
      if (setContactIds.contains(t.WhoId)) {
          t.WhatId = mapCampaigns.get(t.WhoId);
      }
    }  
  }

  //==========================================================================//
  // ACCOUNT PLANNING
  //==========================================================================//
  // blank update on all opp plan for score calculation
  public static void refreshOppScoreCalculations() {
    String keyPrefix = Opportunity_Plan__c.SObjectType.getDescribe().getKeyPrefix();
    List<Opportunity_Plan__c> oppPlans = new List<Opportunity_Plan__c>();
    for (sObject obj : Trigger.isInsert ? Trigger.new :  Trigger.old ) {
      Task tsk = (Task)obj;
        if (tsk.whatId != null && String.valueOf(tsk.whatId).StartsWith(keyPrefix)) {
          oppPlans.add(new Opportunity_Plan__c(Id = tsk.whatId));
        }
    }
    if (oppPlans.size() > 0)
       update oppPlans;
  }
  
  //==========================================================================//
  // DispatchNote 
  // Set Order Date Shipped and Order Line Item Shipped on the new task creation
  // If task is Conga generated Task than set Order Date Shipped to today and 
  // Order Line Item Shipped to true
  //==========================================================================//
  private static Set<String> subjectsAllowed;
  private static String keyPrefixOrdedr = Order__c.sObjectType.getDescribe().getKeyPrefix();

  private static void dispatchNote(List<Task> newTasks) {
    set<Id> setOrderIds = new set<Id>();
    for (Task t : newTasks) {
      if (isCongaGeneratedTask(t.Subject)) {
        if (String.valueOf(t.WhatId).startsWith(keyPrefixOrdedr)) {
          setOrderIds.add(t.WhatId);
        }
      }
    }

    if (setOrderIds.isEmpty()) {
      return;
    }

    List<Order__c> lstOrder = new List<Order__c>();
    List<Order_Line_Item__c> lstOrderLineItem = new List<Order_Line_Item__c>();

    set<Id> setOrderWithLineItem = new set<Id>();
    for (Order_Line_Item__c lineItem : [ SELECT Id, Shipped__c , Order__c 
                                        FROM Order_Line_Item__c 
                                        WHERE Delivery_Method__c != :Constants.ORDER_LINE_ITEM_DELIVERY_METHOD_NOT_REQ 
                                        AND Order__c IN : setOrderIds]) {
      lineItem.Shipped__c = true;
      lstOrderLineItem.add(lineItem);
      setOrderWithLineItem.add(lineItem.Order__c);
    }

    for (Task t : newTasks) {
      if (setOrderWithLineItem.contains(t.WhatId)) {
        lstOrder.add(new Order__c(Id=t.WhatId , Date_Shipped__c = system.now()));
      }
    }

    if (!lstOrderLineItem.isEmpty()) {
      try {
        update lstOrder;
        update lstOrderLineItem;
      } catch(Exception e) {
        //log error
        ApexLogHandler.createLogAndSave('TaskTriggerHandler','setDispatchNote', e.getStackTraceString(), e);
      }
    }
  }

  //==========================================================================//
  // DispatchNote 
  // Check whether the task is Conga Generated Task or not
  //==========================================================================//
  private static Boolean isCongaGeneratedTask(String subject) {
    if (subjectsAllowed == null) {
      Map<String, Conga_Quicklinks_Settings__c> congaSettings = Conga_Quicklinks_Settings__c.getAll();
      subjectsAllowed = new Set<String>();
	    for (Conga_Quicklinks_Settings__c congaSetting: congaSettings.values()) {
	      subjectsAllowed.add(congaSetting.Subject__c);
	    }
    }
    if (subjectsAllowed == null || subjectsAllowed.isEmpty()) {
      Exception ex = (Exception) new apexLogHandler.Force_Exception('TaskTriggerHandler:isCongaGeneratedTask');
      //Log Error
      ApexLogHandler.createLogAndSave('TaskTriggerHandler','isCongaGeneratedTask', 'No Record found in Conga Quicklinks Settings' , ex);
      return false;
    }
    
    if (subjectsAllowed.contains(subject)) {
      return true;
    }
    return false; 
  }
}