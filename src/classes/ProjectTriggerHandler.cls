/**=====================================================================
 * Appirio, Inc
 * Name: ProjectTriggerHandler 
 * Description: 
 * Created Date: Jul 30th, 2014
 * Created By: Nathalie LE GUAY (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jul 30th, 2014               Nathalie Le Guay             T-309151: Create a Project Resource record if a Project's Owner is updated to a new User
 * Aug 01st, 2014               Naresh Kr Ojha               T-309484: After delete of project, delete all delievery lines.
 * Aug 07th, 2014               Naresh Kr Ojha               T-310825: Trigger to copy delivery templates to Project delivery lines.
 * Oct 21st, 2014               Arpita Bose(Appirio)         T-326528: Updated method createProjectResources()
 * May 29th, 2015               Paul Kissick                 Case #593374: Adding methods updateLoeFromDeliveryLines(),checkForUpdateLOE() to update 
                                                             estimated LOE on projects
 =====================================================================*/
public without sharing class ProjectTriggerHandler {
  
  
  public static Set<Id> projectsToUpdateLOE = new Set<Id>();
  public static Boolean calledUpdateLoe = false;
  
  public static Boolean enableLoeRollup = false; // PK: Adding this to disable the rollup for now. Awaiting UAT on it. (08-06-15)
  
  //Before Insert Call
  public static void beforeInsert (List<Project__c> newList) {
    //Nothing yet...
  }
  
  //Before Update Call
  public static void beforeUpdate (Map<Id,Project__c> newMap, Map<Id, Project__c> oldMap) {
    checkForUpdateLOE(newMap,oldMap);
  }

  //After Insert Call
  public static void afterInsert (List<Project__c> newList) {
    createProjectResources(newList, null);
    copyDeliveryTemplatesToProjDeliveryLines (newList, null);
    
  }
  //After Update Call
  public static void afterUpdate (List<Project__c> newList, Map<Id, Project__c> oldMap) {
    createProjectResources(newList, oldMap);
    copyDeliveryTemplatesToProjDeliveryLines (newList, oldMap);
    updateLoeFromDeliveryLines(); // Only every called from after update
  }

  //Before Delete Call
  public static void beforeDelete (List<Project__c> oldList) {
    deleteDeliveryLines(oldList);
  }
  
  //========================================================================================
  // Name: createProjectResources
  // Will take a list of Project__c records and will create Project_Resource__c records
  // where necessary
  //========================================================================================
  private static void createProjectResources(List<Project__c> projects, Map<Id, Project__c> oldProjects) {
    Set<String> projectIds = new Set<String>();
    // String userPrefix = DescribeUtility.getPrefix(Constants.SOBJECT_USER); //T-326528

    for (Project__c project: projects) {
      if (oldProjects == null) {
        projectIds.add(project.Id);
      } else {
        if (oldProjects.get(project.Id).OwnerId != project.OwnerId) {
          projectIds.add(project.Id);
        }
      }
    }
    
    List<Project_Resource__c> prToCreate = new List<Project_Resource__c>();

    // Query all projects and related Project Resources
    for (Project__c project: [SELECT Id, OwnerId,
                                    (SELECT Id, Resource__c FROM Project_Resources__r)
                             FROM Project__c
                             WHERE Id in: projectIds]) {
      
      Id projOwnerId  = project.OwnerId;    
        
      if (!ProjectResource_Utils.hasProjectResource(projOwnerId, project.Project_Resources__r)) {
        //T-326528: create Project_Resource__c record when Owner is 'User' and not 'Group'
        if (projOwnerId.getSobjectType() == User.sObjectType ) {
          prToCreate.add(ProjectResource_Utils.createNewProjectResourceRecord(project.Id, projOwnerId));
        } 
      }
    }
    system.debug('prToCreate>>>' +prToCreate);
    if (prToCreate.size() > 0) {
      ProjectResource_Utils.createProjectResourceRecords(prToCreate);
    }
  }
  
  //===========================================================================
  // Name: deleteDeliveryLines
  // will take a list of Project__c records and will delete delivery lines for 
  // those project records.
  //===========================================================================
  private static void deleteDeliveryLines (List<Project__c> deletedProjects) {
    Set<ID> projectIDs = new Set<ID>();
    List<Delivery_Line__c> delLineList = new List<Delivery_Line__c>();
    for (Project__c p : deletedProjects) {
      projectIDs.add(p.ID);
    }
    try {
      //Fetching related records
      if (projectIDs.size() > 0) {
        for (Delivery_Line__c dl : [SELECT ID FROM Delivery_Line__c 
                                              WHERE Project__c IN: projectIDs]) {
          delLineList.add(dl);
        }
      }

      if (delLineList.size() > 0) {
        delete delLineList;
      }
    } catch (DMLException ex) {
       delLineList.get(0).addError('Exception: '+ex.getMessage());
    }
  }
  
  //===========================================================================
  // Name : copyDeliveryTemplatesToProjDeliveryLines
  // On project we need to copy over the delivery lines form a delivery template 
  // (Delivery_Template_Header and Delivery_Template_Lines objects)
  //===========================================================================
  private static void copyDeliveryTemplatesToProjDeliveryLines (List<Project__c> newList, 
                                                              Map<ID, Project__c> oldMap) {
    Set<Id> dthIDs = new Set<Id>();
    // Map<String, Project__c> projectMap = new Map<String, Project__c>();
    Map<Id, Delivery_Template_Header__c> dthID_dthMap = new Map<Id, Delivery_Template_Header__c>();
    List<Delivery_Line__c> deliveryLines = new List<Delivery_Line__c>();
    
    for (Project__c proj : newList) {
      if (proj.Template__c != null && (oldMap == null || proj.Template__c != oldMap.get(proj.ID).Template__c)) {
        dthIDs.add(proj.Template__c);
      }
    }
    // PK: Replaced original for loop with this. Does the same thing.
    dthID_dthMap = new Map<Id,Delivery_Template_Header__c>([
      SELECT Id, Delivery_Line_Record_Type__c,
      (SELECT Id, Name, Sequence__c From Delivery_Template_Lines__r)
      FROM Delivery_Template_Header__c 
      WHERE ID IN : dthIDs
    ]);
    try {
      for (Project__c proj : newList) {
        if (proj.Template__c == null || !dthID_dthMap.containsKey(proj.Template__c)) {
          continue;
        }
        Delivery_Template_Header__c dth = dthID_dthMap.get(proj.Template__c);
        
        Id recTypeId; 
        if (String.isNotBlank(dth.Delivery_Line_Record_Type__c)) {
          try {
            recTypeId = Delivery_Line__c.SObjectType.getDescribe().getRecordTypeInfosByName().get(dth.Delivery_Line_Record_Type__c).getRecordTypeId();
          }
          catch(Exception e) {
            system.debug('Failed to retrieve record type:'+e.getMessage());
          }
        }
        
        for (Delivery_Template_Line__c dtl : dth.Delivery_Template_Lines__r) {
          Delivery_Line__c dl = new Delivery_Line__c();
          dl.Project__c = proj.ID;
          dl.Name = dtl.Name;
          dl.Sequence__c = dtl.Sequence__c;
          if (recTypeId != null) dl.RecordTypeId = recTypeId;
          deliveryLines.add(dl);
        }
      }
    } catch (Exception ex) {
      apexLogHandler.createLogAndSave('ProjectTriggerHandler','copyDeliveryTemplatesToProjDeliveryLines:Exception', ex.getStackTraceString(), ex);
      newList.get(0).addError(ex.getMessage());
    }
    if (deliveryLines.size() > 0) {
      try {
        insert deliveryLines;
      } catch (DMLException ex) {
        apexLogHandler.createLogAndSave('ProjectTriggerHandler','copyDeliveryTemplatesToProjDeliveryLines:DMLException', ex.getStackTraceString(), ex);
        for (Integer indx = 0; indx < ex.getNumDml(); indx++) {
          newList.get(0).addError(ex.getDMLMessage(indx));
        }
      }
    }
  }
  
  //==========================================================================
  // Case #593374: Check for the tick on Update_LOE_From_Delivery_Lines__c and fill a set to use later.
  // 
  //==========================================================================
  public static void checkForUpdateLOE(Map<Id,Project__c> newMap, Map<Id,Project__c> oldMap) {
    for(Id projectId : newMap.keySet()) {
      if (newMap.get(projectId).Update_LOE_From_Delivery_Lines__c == true) {
        projectsToUpdateLOE.add(projectId);
        newMap.get(projectId).Update_LOE_From_Delivery_Lines__c = false;
      }
    }
  }
  
  //==========================================================================
  // Case #593374: Roll up the LOE (Hours and Revenue) from Delivery lines. 
  // 
  //==========================================================================
  public static void updateLoeFromDeliveryLines() {
    if (!enableLoeRollup) {
      return;
    }
    if (calledUpdateLoe == true) {
      // Bail out, only update once!
      return;
    }
    calledUpdateLoe = true;
    // NOTE, not using the Estimated days due to a workflow rule conflict.
    // Using a formula (Revenue_Number__c) for the revenue because Revenue__c currency field always converts to org currency (USD)
    List<AggregateResult> deliveryLineLOEEst = [
      SELECT SUM(Estimated_LOE_Hours__c) LOEHours, SUM(Revenue_Number__c) RevTotal, Project__c 
      FROM Delivery_Line__c 
      WHERE Project__c IN :projectsToUpdateLOE
      AND Service_Type__c IN :DeliveryLineTriggerHandler.deliveryLineServiceTypesLoeSet
      GROUP BY Project__c
    ];
    List<Project__c> projectsToUpdateList = new List<Project__c>();
    for(AggregateResult deliveryLineTotal : deliveryLineLOEEst) {
      Project__c toUpd = new Project__c(
        Id = (Id)deliveryLineTotal.get('Project__c'),
        Estimated_LOE_Hours__c = (Decimal)deliveryLineTotal.get('LOEHours'),
        Revenue__c = (Decimal)deliveryLineTotal.get('RevTotal')
      );
      projectsToUpdateList.add(toUpd);
    }
    try {
      update projectsToUpdateList;
    } 
    catch (DMLException ex) {
      apexLogHandler.createLogAndSave('ProjectTriggerHandler','updateLoeFromDeliveryLines:DMLException', ex.getStackTraceString(), ex);
    }
  }
  
}