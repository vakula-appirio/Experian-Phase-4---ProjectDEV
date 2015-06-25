/**=====================================================================
 * Appirio, Inc
 * Name: ChatterAutoFollowController
 * Description: 
 * Created Date: 
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014								Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Apr 24th, 2014               Arpita Bose (Appirio)        Updated Nightly() and testRunNow() to increase the code coverage
 =====================================================================*/
public class ChatterAutoFollowController{


    public PageReference Nightly(){
    	  ScheduleAutoFollowScheduler saf = new ScheduleAutoFollowScheduler();
        ScheduleAutoFollowScheduler.Start();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Job Has Been Scheduled'));
        return null;
    }
    public PageReference RunNow(){
        ScheduleAutoFollow s = new ScheduleAutoFollow();
        s.autoFollowRecord();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Chatter Following Has Been Started'));
        return null;
    }
    
    @isTest
    public static void testRunNow(){
        ChatterAutoFollowController c = new ChatterAutoFollowController();
        c.RunNow();
        //Assert to check for message "Chatter Following Has Been Started"
        System.assert(String.valueOf(ApexPages.getMessages()).contains('Chatter Following Has Been Started'));
        c.Nightly();
        //Assert to check for message "Job Has Been Scheduled"
        System.assert(String.valueOf(ApexPages.getMessages()).contains('Job Has Been Scheduled'));
    }
}