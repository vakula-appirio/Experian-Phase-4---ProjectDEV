/**=====================================================================
 * Appirio, Inc
 * Name: LeadTrigger
 * Description: T-194935, On Lead conversion if billing address is not blank 
                then create address record and associate that address with 
                the converted account by creating the AccountAddress record
                and associate converted contact by creating the ContactAddress record.
 * Created Date: Nov 01st, 2013
 * Created By: Manish Soni ( Appirio )
 * 
 * Date Modified                Modified By                  Description of the update
 * Nov 19th, 2013										Pankaj Mehra(Appirio)				 T-213204: Populate Maketing Activity contact lookup on conversion of lead
 * Jan 30th, 2014										Naresh Kr Ojha(Appirio)			 T-232755: Homogenize triggers 
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Mar 04th, 2014                   Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 =====================================================================*/

trigger LeadTrigger on Lead (after update) {

  //Ensure a data admin is not loading the data, so the triggers will not fire
	if (IsDataAdmin__c.getInstance().IsDataAdmin__c == false && 
																				TriggerState.isActive(Constants.LEAD_TRIGGER)) {
    
		if (Trigger.isAfter && Trigger.isUpdate) {
			LeadTriggerHandler.afterUpdate (Trigger.newMap, Trigger.oldMap);
	  }
  }//END:IF DataAdmin bypass
}