/**=====================================================================
 * Appirio, Inc
 * Name: ProjectResource_Utils 
 * Description: Project Resource Utility class
 * Created Date: July 31st, 2014
 * Created By: Nathalie LE GUAY (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jul 31, 2014                 Nathalie Le Guay             T-286011: Create Project Resource records
 * Aug 01st, 2014				Naresh Kr Ojha				 T-309151: Updated method hasProjectResource () for debugging.
 =====================================================================*/
public without sharing class ProjectResource_Utils {

  //========================================================================================
  // Name: createNewProjectResource
  // Will create and return a Project_Resource__c record
  //========================================================================================
  public static Project_Resource__c createNewProjectResourceRecord(String projectId, String userId) {
    return new Project_Resource__c(Project__c = projectId, Resource__c = userId);
  }

  //========================================================================================
  // Name: hasProjectResource
  // Will take a list of Project_Resource__c records and will return true if a match is found
  //========================================================================================
  public static Boolean hasProjectResource(String userId, List<Project_Resource__c> projectResources) {
    for (Project_Resource__c projectResource : projectResources) {
      if (projectResource.Resource__c == userId) {
        return true;
      }
    }
    return false;
  }

  // =========================================================================
  // createProjectResourceRecords will insert Project_Resource__c into the DB
  // =========================================================================
  public static Boolean createProjectResourceRecords(List<Project_Resource__c> prToCreate) {
    try {
      insert prToCreate;
    } catch(DMLException e) {
      apexLogHandler.createLogAndSave('ProjectTriggerHandler','createProjectResources', e.getStackTraceString(), e);
      for (Integer i=0; i < e.getNumDml(); i++) {  
        prToCreate.get(0).addError(e.getDMLMessage(i)); 
      }
      return false;
    }
    return true;
  }

}