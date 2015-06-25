/**=====================================================================
 * Appirio, Inc
 * Name: EveryHourScheduling
 * Description: Class to schedule the scheduler to calculate the case age on
               hourly basis. (installed from Asset)
 * Created Date: 27 Apr 2015
 * Created By: Noopur (Appirio)
 * Date Modified                Modified By                  Description of the update
 * May, 12th 2015               Arpita Bose(Appirio)         T-375163: Updated for calulating Record_time__c on Case
 *========================================================================*/
public class EveryHourScheduling {
  
  public EveryHourScheduling() {
    //ScheduledApexOnCase skedule = new ScheduledApexOnCase();
    //String timeOfRun = '0 0 * * * ?'; //every hour is scheduling 
    //system.schedule('Schedule Job On Case Age', timeOfRun, skedule);
    
    //T-375163
    System.schedule('Schedule Job On Case Record time 00', '0 0 * * * ?',  new ScheduledApexOnCase());        
    System.schedule('Schedule Job On Case Record time 15', '0 15 * * * ?', new ScheduledApexOnCase());        
    System.schedule('Schedule Job On Case Record time 30', '0 30 * * * ?', new ScheduledApexOnCase());    
    System.schedule('Schedule Job On Case Record time 45', '0 45 * * * ?', new ScheduledApexOnCase());
  }
}