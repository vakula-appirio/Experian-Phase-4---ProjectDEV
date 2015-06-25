/**=====================================================================
 * Appirio, Inc
 * Trigger Name: ConfidentialInformationTrigger
 * Handler Class: ConfidentialsInformationTriggerHandler
 * Description: T-266931: Synching OpportunityTeamMembers
 * Created Date: Mar 28th, 2014  
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Feb 10th, 2015               Arpita Bose(Appirio)         T-360092: Added afterDelete and afterUnDelete call
 * Apr 29th, 2015               GCS (added by NLG)           Case # unknown. changed afterDelete signature
 =====================================================================*/
trigger ConfidentialInformationTrigger on Confidential_Information__c(after insert, after update, after delete, after undelete) {

  // Ensure a data admin is not loading the data, so the triggers will not fire
  if (TriggerState.isActive(Constants.CONFINFO_TRIGGER) &&
                      IsDataAdmin__c.getInstance().IsDataAdmin__c == false) {
    // After Insert Call
    if (trigger.isAfter && trigger.isInsert) {
      system.debug('***executed-----'+Trigger.newMap);
      ConfidentialInformationTriggerHandler.afterInsert (Trigger.newMap);
    }
    // After Update Call
    if (trigger.isAfter && trigger.isUpdate) {
      system.debug('***executed-----'+Trigger.newMap);
      ConfidentialInformationTriggerHandler.afterUpdate (Trigger.newMap, Trigger.oldMap);
    }
    // After Delete Call
    if (Trigger.isAfter && Trigger.isDelete) {
      ConfidentialInformationTriggerHandler.afterDelete (Trigger.newMap, Trigger.oldMap);
    }
    // After UnDelete Call
    if (Trigger.isAfter && Trigger.isUnDelete){
        ConfidentialInformationTriggerHandler.afterUnDelete(Trigger.new); 
    }
  }
}