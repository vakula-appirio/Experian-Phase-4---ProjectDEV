/**=====================================================================
 * Appirio, Inc
 * Name: TriggerState
 * Description: 
 * Created Date:
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Feb 13th, 2014                    Jinesh Goyal(Appirio)         T-232763: Added Exception Logging
 =====================================================================*/
public abstract class TriggerState { 
	static Map<String, TriggerSettings__c> triggerSetting = TriggerSettings__c.getAll(); 

	public static boolean isActive(String triggerName) { 
		boolean isActive = true; 
		try { 
			if(triggerSetting.containsKey(triggerName)) { 
				isActive = (Boolean)triggerSetting.get(triggerName).get('isActive__c'); 
			} 
		} catch (Exception e) { 
		  apexLogHandler.createLogAndSave('TriggerState','isActive', e.getStackTraceString(), e);
		}
		 
		return isActive; 
	} 
}