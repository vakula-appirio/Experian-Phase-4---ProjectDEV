/**=====================================================================
 * Appirio, Inc
 * Name: ScheduleAutoFollowTest
 * Description: 
 * Created Date:
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Mar 05th, 2014               Arpita Bose (Appirio)            Added Constants in place of String
 * Mar 14th, 2014               Arpita Bose (Appirio)            T-253906: Fixed error 
 =====================================================================*/
@isTest
private class ScheduleAutoFollowTest {

    static testMethod void myUnitTest() {
    Global_Settings__c custSettings = new Global_Settings__c(name= Constants.GLOBAL_SETTING,Account_Team_Member_Default_Role__c= Constants.TEAM_ROLE_ACCOUNT_MANAGER,Smart_Search_Query_Limit__c=250);
        insert custSettings;
        test.startTest();
            Account a = new Account();
            a.Name = 'Test Account';
            insert a;
            
            Account a1 = new Account();
            a1.Name = 'Test Account';
            insert a1;
            
            Opportunity o = new Opportunity();
            o.Name = 'Test Opportunity';
            o.AccountId = a.Id;
            o.StageName = Constants.OPPTY_STAGE_3;
            o.CloseDate = system.today();
            insert o;
            
            ScheduleAutoFollow saf = new ScheduleAutoFollow();
            
            // run the test when no team members are present for Account or Opportunity             
            saf.autoFollowRecord();
            
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = userinfo.getUserId();
            atm.AccountId = a.Id;
            atm.TeamMemberRole = Constants.TEAM_ROLE_ACCOUNT_MANAGER;
            insert atm;
            
            AccountTeamMember atm1 = new AccountTeamMember();
            atm1.UserId = userinfo.getUserId();
            atm1.AccountId = a1.Id;
            atm1.TeamMemberRole = Constants.TEAM_ROLE_ACCOUNT_MANAGER;
            insert atm1;
            
            OpportunityTeamMember otm = new OpportunityTeamMember();
            otm.UserId = userinfo.getUserId();
            otm.opportunityId = o.Id;
            otm.TeamMemberRole = Constants.TEAM_ROLE_SALES_MANAGER;
            insert otm;
            
            EntitySubscription e;
            List<EntitySubscription> lstEntitySubscription = [SELECT Id From EntitySubscription WHERE 
                                                              ParentId =: a.Id AND SubscriberId =: userinfo.getUserId()];
            if(lstEntitySubscription.size() > 0) {
                e = lstEntitySubscription[0];
            } else {
                e = new EntitySubscription();   
                e.ParentId = a.Id;
                e.SubscriberId = userinfo.getUserId();
                insert e;   
            }
            
            // run the test when team members are added for Account and Opportunity & when a record for EntitySubscription is already present i.e. user is already following that record
            saf.autoFollowRecord();
        
        
        // Schedule the test job
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new ScheduleAutoFollow());
        
        // Get the information from the CronTrigger API object  
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime
                            FROM CronTrigger 
                            WHERE id = :jobId];
        
        // Verify the expressions are the same  
        System.assertEquals(CRON_EXP, ct.CronExpression);
    
        // Verify the job has not run  
        System.assertEquals(0, ct.TimesTriggered);
        
        test.stopTest();
        
       
                
    }
}