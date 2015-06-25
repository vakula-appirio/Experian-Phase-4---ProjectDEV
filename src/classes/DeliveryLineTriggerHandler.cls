/**=====================================================================
 * Appirio, Inc
 * Name: DeliveryLineTriggerHandler 
 * Description: 
 * Created Date: July 31, 2014
 * Created By: Nathalie LE GUAY (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jul 31, 2014                 Nathalie Le Guay             T-309151: Create a Project Resource record if a DL's Owner is updated to a new User
 * Aug 02, 2014                 Nareseh Kr Ojha               Update method createProjectResources () for null pointer exception, put check for map.
 * Aug 19, 2014                 Arpita Bose(Appirio)         T-313220: Updated method createProjectResources() to create project resource for User only
 * Sep 26, 2014                 Naresh Kr Ojha               T-322781: added method createZeroHourTimecardEntry() method for completed delivery lines.
 * Apr 03, 2015                 Nur Azlini                   Case#555032: Update method createZeroHourTimecardEntry() to make the complete method works for expired status as well.
 * May 29th, 2015               Paul Kissick                 Case #593374: Adding method checkForProjectDeliveryType() to update estimated LOE on projects
 =====================================================================*/
public without sharing class DeliveryLineTriggerHandler {
  //After Insert Call
  public static void afterInsert (List<Delivery_Line__c> newList) {
    createProjectResources(newList, null);
    createZeroHourTimecardEntry(newList, null);//As per: T-322781
    checkForProjectDeliveryType(newList, null); // PK Case #593374
  }
  
  //After Update Call
  public static void afterUpdate (List<Delivery_Line__c> newList, Map<Id, Delivery_Line__c> oldMap) {
    createProjectResources(newList, oldMap);
    createZeroHourTimecardEntry(newList, oldMap);//As per: T-322781
    checkForProjectDeliveryType(newList, oldMap); // PK Case #593374
  }
  
  // After delete call
  public static void afterDelete (Map<Id, Delivery_Line__c> oldMap) {
    checkForProjectDeliveryType(null, oldMap); // PK Case #593374
  }
  
  // Case #593374 - List to filter to update based on service_type__c
  public static Set<String> deliveryLineServiceTypesLoeSet = new Set<String>{'Delivery'};

  //========================================================================================
  // Name: createProjectResources
  // Will take a list of Delivery_Line__c records and will create Project_Resource__c records
  // where necessary
  //========================================================================================
  private static void createProjectResources(List<Delivery_Line__c> deliveryLines, Map<Id, Delivery_Line__c> oldDeliveryLines) {
    
    // Retrieve related projects, if owner of Delivery Line was changed
    Set<String> projectIds = new Set<String>();
    for (Delivery_Line__c dl: deliveryLines) {
      Id ownerId = dl.OwnerId; // PK: Replaced String with Id
      if (oldDeliveryLines == null) {
        if (dl.Project__c != null) {
          projectIds.add(dl.Project__c);
        }
      } else {
        // PK: Replaced the check for prefix with sobject checks
        if (oldDeliveryLines.get(dl.Id).OwnerId != dl.OwnerId && ownerId.getSobjectType() == User.SObjectType) {
          if (dl.Project__c != null) {
            projectIds.add(dl.Project__c);
          }
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
    for (Delivery_Line__c dl: deliveryLines) {
      if (projectMap.containsKey(dl.Project__c) && projectMap.get(dl.Project__c).Project_Resources__r.size() > 0 && 
               !ProjectResource_Utils.hasProjectResource(dl.OwnerId, projectMap.get(dl.Project__c).Project_Resources__r)) {
        prToCreate.add(ProjectResource_Utils.createNewProjectResourceRecord(dl.Project__c, dl.OwnerId));
      }
    }
    if (prToCreate.size() > 0) {
      ProjectResource_Utils.createProjectResourceRecords(prToCreate);
    }
  }
  
  //==========================================================================
  // T-322781: Creating zero hour timecard on completion of delivery line
  // Case#555032
  //==========================================================================
  private static void createZeroHourTimecardEntry (List<Delivery_Line__c> newList, 
                                                   Map<ID, Delivery_Line__c> oldMap) {
    List<Timecard__c> newTimecards = new List<Timecard__c>();
    
    try {
      //For completed and Expired delivery lines, creating timecard entries
      for (Delivery_Line__c delLine : newList) {
        if ((delLine.Status__c == Constants.STATUS_COMPLETED || delLine.Status__c == Constants.STATUS_EXPIRED)&& 
             ((oldMap != null)?(delLine.Status__c != oldMap.get(delLine.ID).Status__c):true)) {
          Timecard__c newTimecard = new Timecard__c();
          newTimecard.Resource__c = delLine.OwnerId;
          newTimecard.Delivery_Line__c = delLine.ID;
          newTimecard.Project__c = delLine.Project__c;
          newTimecard.Description__c = delLine.Description__c;
          newTimecard.Type__c = Constants.TIMECARD_TYPE_DELIVERY;
          newTimecard.Date__c = delLine.Actual_End_Date__c;
          newTimecards.add(newTimecard);
        }
      }
    } catch (Exception ex) {
      ApexLogHandler.createLogAndSave('DeliveryLineTriggerHandler','createZeroHourTimecardEntry', ex.getStackTraceString(), ex);
    }    
    try {
      //Insert timecards
      if (newTimecards.size() > 0) {
        insert newTimecards;
      }
    } catch (DMLException ex) {
      ApexLogHandler.createLogAndSave('DeliveryLineTriggerHandler','createZeroHourTimecardEntry', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        newList.get(0).addError(ex.getDmlMessage(i)); 
      }
    }
  }
  
  //==========================================================================
  // Case #593374: Roll up estimated LOE onto the project. 
  // Sets the Update_LOE_From_Delivery_Lines__c field to kick off the refresh.
  //==========================================================================
  public static void checkForProjectDeliveryType(List<Delivery_Line__c> newList, Map<Id, Delivery_Line__c> oldMap) {
    List<Project__c> projectsToUpdate = new List<Project__c>();
    List<Delivery_Line__c> dlsToCheck = new List<Delivery_Line__c>();
    if (newList == null) dlsToCheck = oldMap.values();
    else dlsToCheck = newList;
    
    Set<Id> projectIds = new Set<Id>();
    for(Delivery_Line__c dl : dlsToCheck) {
      Boolean addProject = false;
      if (Trigger.isUpdate) {
        if (oldMap.get(dl.Id).Service_Type__c != dl.Service_Type__c) {
          addProject = true;
        }
      }
      // Note, only update project to sync Estimated LOE if this is a 'Delivery' project.
      if (deliveryLineServiceTypesLoeSet.contains(dl.Service_Type__c) && !projectIds.contains(dl.Project__c)) {
        addProject = true;
      }
      if (addProject) {
        projectsToUpdate.add(
          new Project__c(
            Id = dl.Project__c, 
            Update_LOE_From_Delivery_Lines__c = true
          )
        );
        projectIds.add(dl.Project__c); // Hold a set of project ids to prevent duplication, thus allowing the update call to work properly.
      }
    }
    try {
      update projectsToUpdate;
    }
    catch (DMLException ex) {
      ApexLogHandler.createLogAndSave('DeliveryLineTriggerHandler','checkForProjectDeliveryType', ex.getStackTraceString(), ex);
      for (Integer i = 0; i < ex.getNumDml(); i++) {
        newList.get(0).addError(ex.getDmlMessage(i)); 
      }
    }
  }
  
}