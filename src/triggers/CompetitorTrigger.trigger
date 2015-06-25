/**=====================================================================
 * Appirio, Inc
 * Trigger Name : CompetitorTrigger
 * Handler Class: CompetitorTriggerHandler  
 * Reference    : T-291592
 * Created Date : Jul 04th, 2014
 * Created By   : Sonal Shrivastava (Appirio JDC)
 * Date Modified                Modified By                  Description of the update
 * Jul 11th, 2014               Arpita Bose(Appirio)         I-120496: Added method in beforeInsert, beforeUpdate to
 *                                                           update Competitor Name with relevant Account Name
 * Jul 11th, 2014               Arpita Bose(Appirio)         I-120496: Commented the code as the requirement is changed as per the chatter
 =====================================================================*/
trigger CompetitorTrigger on Competitor__c (after insert, before delete, before insert, before update) {
  
  if(trigger.isAfter){
	  if(trigger.isInsert){
	    CompetitorTriggerHandler.afterInsert(Trigger.new);
	  }
  }	  
  if(trigger.isBefore){
	  if(trigger.isDelete){
	    CompetitorTriggerHandler.beforeDelete(Trigger.oldMap);
	  }
	  // I-120496: Commented this code as the requirement is changed
	  /*
      if(trigger.isInsert){
        CompetitorTriggerHandler.beforeInsert(Trigger.new);
      }
      if(trigger.isUpdate){
        CompetitorTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
      } */
  }    
}