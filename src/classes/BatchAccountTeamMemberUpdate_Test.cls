/**=====================================================================
 * Appirio, Inc
 * Name: TestBatchAccountTeamMemberUpdate
 * Description:  Story:     S-123907
 *               Task:      T-194927
 *               The following test class is designed to test the 'BatchAccountTeamMemberUpdate.cls' class.
 * Created Date: 
 * Created By: Shane Khublall (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Feb 13th, 2014               Jinesh Goyal(Appirio)        T-232763: Added Exception Logging
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282: Added Constants in place of String
 * Mar 05th, 2014               Jinesh Goyal (Appirio)       T-253906: test class renaming
 * Mar 14th, 2014               Arpita Bose (Appirio)        T-253906: Error fixed 
 * Oct 29th, 2014               Arpita Bose                  Updated to increase the code coverage 
 =====================================================================*/
@isTest
private class BatchAccountTeamMemberUpdate_Test
{
    static testMethod void testBatch()
    {
        // Create Global Setting for datetime , for the test method.
      
        TestMethodUtilities.createTestGlobalSettings();
        Global_Settings__c lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);
      
        system.debug('BBBBBBBBLast Run : ' + lastRun.Account_Team_Member_Job_Last_Run__c);        
        Datetime testBeforeDateTime = lastRun.Account_Team_Member_Job_Last_Run__c ;
        lastRun.Account_Team_Member_Job_Last_Run__c = lastRun.Account_Team_Member_Job_Last_Run__c.addMinutes(-60);
        update lastRun;
        lastRun = Global_Settings__c.getInstance(Constants.GLOBAL_SETTING);
        system.debug('bbbbbbbb: ' + testBeforeDateTime);
        system.debug('BBBBBBBB: ' + lastRun.Account_Team_Member_Job_Last_Run__c);         
      
        // put the datetime into a format that can be used by the SOQL query below
        String testDateSOQL = lastRun.Account_Team_Member_Job_Last_Run__c.format('yyyy-MM-dd\'T\'hh:mm:ss\'z\''); 

        // generate the new users
        // create a test utils class put some methods to generate the data in, create global utils as well to retrieve global settings across org.
      
        // select profile, role from the org, by name.
      
        TestMethodUtilities testData = new TestMethodUtilities();
        testData.createTestUltimateParentAndChildAccounts();
        Account ultimateParent = testData.getUltimateParent();
                      
        //TestMethodUtilities.createTestUltimateParentAndChildAccounts();
        
        Profile p = [select id from profile where name='System Administrator'];
        /*User testUser1 = new User(lastName ='test1',Email = 'test1@gmail.com', profileId = p.Id, Business_Unit__c = null, Global_Business_Line__c = null,alias = 'test1', emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='test1@testorg.com');
        User testUser2 = new User(lastName ='test2',Email = 'test2@gmail.com', profileId = p.Id, Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT, Global_Business_Line__c = null,alias = 'test2', emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='test2@testorg.com');
        User testUser3 = new User(lastName ='test3',Email = 'test3@gmail.com', profileId = p.Id, Business_Unit__c = null, Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES,alias = 'test3', emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='test3@testorg.com');       
        */
        User testUser1 = Test_Utils.createUser(p, 'test1@gmail.com', 'test1'); //,Email = 'test1@gmail.com', profileId = p.Id, Business_Unit__c = null, Global_Business_Line__c = null,alias = 'test1', emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='test1@testorg.com');
        User testUser2 = Test_Utils.createUser(p, 'test2@gmail.com', 'test2');//,Email = 'test2@gmail.com', profileId = p.Id, Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT, Global_Business_Line__c = null,alias = 'test2', emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='test2@testorg.com');
        testUser2.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT;
        User testUser3 = Test_Utils.createUser(p, 'test3@gmail.com', 'test3'); // profileId = p.Id, Business_Unit__c = null, Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES,alias = 'test3', emailencodingkey='UTF-8', languagelocalekey='en_US', localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='test3@testorg.com');       
        testUser3.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;

        List <User> testUsers = new List<User>();
        testUsers.add(testUser1);
        testUsers.add(testUser2);
        testUsers.add(testUser3);
        insert testUsers;
        // Now create 3 Account Team Members, add them to 3 separate accounts, one to planes, one to boats, one to cars.
        
        AccountTeamMember mem1 = new AccountTeamMember(UserId = testUser1.Id, AccountId = testData.getUltimateParentId(),
        TeamMemberRole=Constants.TEAM_ROLE_ACCOUNT_MANAGER );
        AccountTeamMember mem2 = new AccountTeamMember(UserId = testUser1.Id, AccountId = testData.getchildOneId(),
        TeamMemberRole=Constants.TEAM_ROLE_CHANNEL_MANAGER );
        AccountTeamMember mem3 = new AccountTeamMember(UserId = testUser2.Id, AccountId = testData.getUltimateParentId(),
        TeamMemberRole=Constants.TEAM_ROLE_LEAD_QUALIFIER );
        AccountTeamMember mem4 = new AccountTeamMember(UserId = testUser3.Id, AccountId = testData.getchildTwoId(),
        TeamMemberRole=Constants.TEAM_ROLE_LEAD_QUALIFIER );
      
        List <AccountTeamMember> testMembers = new List<AccountTeamMember>();
        testMembers.add(mem1);
        testMembers.add(mem2);
        testMembers.add(mem3);
        testMembers.add(mem4);
      
        insert testMembers;
        System.debug('testMembers::' + testMembers);
        
        //child account
        Account testChild1 = new Account(Name ='Child1', DQ_Status__c='Pending', Region__c='APAC', Type='Prospect' ,ParentId =  ultimateParent.id,
        																	Industry='Apparel', Ultimate_Parent_Account__c = ultimateParent.id);
        Account testChild2 = new Account(Name ='Child2', DQ_Status__c='Pending', Region__c='APAC', Type='Prospect' , ParentId =  ultimateParent.id,
        																	Industry='Apparel', Ultimate_Parent_Account__c = ultimateParent.id);
        
        List<Account> testChildAcc = new List<Account>();
        testChildAcc.add(testChild1);
        testChildAcc.add(testChild2);
        
        insert testChildAcc;
        System.debug('testChildAcc::' + testChildAcc);
        List<Account> resAccounts = [SELECT ID, Ultimate_Parent_Account__c FROM Account WHERE id in : testChildAcc];
        System.debug(':::resAccounts'+resAccounts);
        
        
        Test.StartTest();
        BatchAccountTeamMemberUpdate batu = new BatchAccountTeamMemberUpdate();        

        //testBeforeDateTime = batu.lastRun.Account_Team_Member_Job_Last_Run__c.addMinutes(-4);
        ID batchprocessid = Database.executeBatch(batu); 
        
        batu.execute((Database.BatchableContext) null, testMembers);
        
        Test.StopTest();
        
        //assert that 2 records were inserted on child accounts, excluding records inserted on the ultimate parent account
        System.assertEquals([SELECT COUNT() FROM AccountTeamMember WHERE AccountID =: testData.getchildOneId()], 2);
        system.debug('cccccccc: ' + testBeforeDateTime);
        system.debug('CCCCCCCC: ' + lastRun.Account_Team_Member_Job_Last_Run__c);
        
        system.assert(testBeforeDateTime != batu.lastRun.Account_Team_Member_Job_Last_Run__c);
    }
}