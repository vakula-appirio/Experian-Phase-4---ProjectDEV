/*=====================================================================
 * Date Modified      Modified By                  Description of the update
 * Oct 30th,2014      Pallavi Sharma(Appirio)      Fix Failure
=====================================================================*/
@isTest 
private class CaseRoundRobin_Test {

    static User createUser(string userName){
        Profile testProfile = [select id
          from profile where name like '%System Administrator%' LIMIT 1];
              
        User u = new User(alias = 'xyz-010', email = 'test@testuser.com', 
          emailencodingkey = 'UTF-8', 
          lastname = 'TestLastName', 
          languagelocalekey = 'en_US', 
          localesidkey = 'en_US', 
          profileid = testProfile.id, 
          timezonesidkey = 'America/Los_Angeles', 
          username = userName         
          );
        return u;       
    }
    
    static testMethod void myTest1() {
        
        User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
        
        // This code runs as the system user
        User u1 = CaseRoundRobin_Test.createUser('test@twittertest.com');
        u1.Assignment_Group_Active__c = true;
        insert u1; 
        User u2 = CaseRoundRobin_Test.createUser('test2@twittertest.com');
        u2.Assignment_Group_Active__c = true;
        insert u2; 
        System.debug(u1);
        System.runAs(testUser) {

        Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
        custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
        update custSetting;
        
        CaseTeamRole ctrTest;
        for(CaseTeamRole caseTeam : [SELECT Name , AccessLevel 
                                     From CaseTeamRole 
                                     WHERE Name =: custSetting.Case_Access_Request_TeamRole__c]){
          ctrTest = caseTeam; 
        }
        if(ctrTest == null){
          ctrTest = new CaseTeamRole();
          ctrTest.Name = custSetting.Case_Access_Request_TeamRole__c;
          ctrTest.AccessLevel = 'Edit';
          insert ctrTest;
        }
        
       //*****Create Queue 
       
       Group testGroup = new Group ();
       testGroup.Name = 'TestQueue';
       testGroup.Type = 'Queue';
       insert testGroup;
       
       QueueSObject testQueue = new QueueSObject();
       testQueue.QueueId = testGroup.id;
       testQueue.SObjectType = 'Case';
       insert testQueue;

       // Second Queue       
       Group testGroup2 = new Group ();
       testGroup2.Name = 'TestQueue2';
       testGroup2.Type = 'Queue';
       insert testGroup2;
       
       QueueSObject testQueue2 = new QueueSObject();
       testQueue2.QueueId = testGroup2.id;
       testQueue2.SObjectType = 'Case';
       insert testQueue2;


       //system.runAs(u2){
        
        //Run test
        Test.startTest();
        Database.DMLOptions dmo = new Database.DMLOptions(); 
        dmo.assignmentRuleHeader.useDefaultRule= false;
        List<Case> lstCases = new List<Case>();
        for(Integer x = 0; x<200; x++){
            Case l = new Case(subject='ABC'+x, description='Smith'+x, OwnerId = testGroup.Id); //Set owner ID to Queue
            l.setOptions(dmo); 
            lstCases.add(l);
        }
        insert lstCases;      
        update lstCases;        
        
        
        //Create Assignment Group
        Assignment_Group_Name__c ag1 = new Assignment_Group_Name__c (Name='TestAG', Type__c = 'Case');
        insert ag1;

          
        //Add bad queue name
        Assignment_Group_Queues__c agqBad = new Assignment_Group_Queues__c(name='Bad Queue',Assignment_Group_Name__c = ag1.id );

        try {
            insert agqBad; 
        } catch (DmlException e){
             System.assert(e.getMessage().contains('CUSTOM_VALIDATION_EXCEPTION'), e.getMessage()); 
        
        } //catch

       
        Test.stopTest();
        system.assert([Select Id, OwnerId from Case where Id =: lstCases[0].Id].OwnerId != u1.id);  // assert that no re-assignment took place
       }
    }
    
    static testMethod void myTest3() {
 
        // This code runs as the system user
        User u1;
        User u2 ;
        User testUser;
        Group testGroup;
        QueueSObject testQueue;
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs(thisUser){
            u1 = CaseRoundRobin_Test.createUser('test@twittertest.com');
            u1.Assignment_Group_Active__c = true;
            insert u1; 
            u2 = CaseRoundRobin_Test.createUser('test2@twittertest.com');
            u2.Assignment_Group_Active__c = true;
            insert u2; 
            testUser = CaseRoundRobin_Test.createUser('testUser@twittertest.com');
            insert testUser;
            System.debug(u1);
    
           //*****Create Queue 
           
           testGroup = new Group ();
           testGroup.Name = 'TestQueue';
           testGroup.Type = 'Queue';
           insert testGroup;
           
           testQueue = new QueueSObject();
           testQueue.QueueId = testGroup.id;
           testQueue.SObjectType = 'Case';
           insert testQueue;
        }
        List<Case> lstCases;
        system.runAs(testUser){
            Global_Settings__c custSetting = Test_Utils.insertGlobalSettings();
            custSetting.Case_Access_Request_TeamRole__c = Constants.CASE_TEAM_ROLE_REQUESTOR;
            update custSetting;
            //Run test        
            
            CaseTeamRole ctrTest;
            for(CaseTeamRole caseTeam : [SELECT Name , AccessLevel 
                                         From CaseTeamRole 
                                         WHERE Name =: custSetting.Case_Access_Request_TeamRole__c]){
              ctrTest = caseTeam;	
            }
            if(ctrTest == null){
	            ctrTest = new CaseTeamRole();
			        ctrTest.Name = custSetting.Case_Access_Request_TeamRole__c;
			        ctrTest.AccessLevel = 'Edit';
			        insert ctrTest;
            }
        
            //Create Assignment Group
            Assignment_Group_Name__c ag1 = new Assignment_Group_Name__c (Name='TestAG', Type__c = 'Case');
            insert ag1;        
    
            //Add Good Queue to Assignment Group
            Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(name=testGroup.Name ,Assignment_Group_Name__c = ag1.id );
            insert agq1;
            
            
            //Add User to Assignment Groups Users
            Assignment_Groups__c agu1 = new Assignment_Groups__c (User__c = u1.id, Active__c='True', Group_Name__c = ag1.id, Last_Assignment__c = datetime.valueOf('2009-01-01 21:13:24') );
            insert agu1;      
            Assignment_Groups__c agu2 = new Assignment_Groups__c (User__c = u2.id, Active__c='True', Group_Name__c = ag1.id, Last_Assignment__c = datetime.valueOf('2009-01-01 21:13:25') );
            insert agu2;  
             // DON'T ALLOW ASSIGNMENT RULES TO RUN AS THEY CHANGE. Manually set QueueId 
            //Database.DMLOptions dmo = new Database.DMLOptions(); 
            //dmo.assignmentRuleHeader.useDefaultRule= false;
            lstCases = new List<Case>();
            for(Integer x = 0; x<200; x++){
                Case l = new Case(subject='ABC'+x, description='Smith'+x); // don't set owner yet. simulate owner change via lead assignment rules (web-to-lead)
                //l.setOptions(dmo); 
                lstCases.add(l);
            }
            insert lstCases; 
            Map<Integer,Id> customQueueIds = new Map<Integer,Id>(); 
            Set<Id> setUpdatedCaseIds = new Set<Id>();   
            for(Integer x = 0; x<200; x++){
                lstCases[x].OwnerId = testGroup.Id; //Set owner ID to Queue
                //l.setOptions(dmo); 
                customQueueIds.put(x, lstCases[x].OwnerId);
                setUpdatedCaseIds.add(lstCases[x].Id);
            }        
            update lstCases;  
            
            CaseTriggerHandler.addExceptionError(lstCases, customQueueIds, 'Custom Error Exception');
            CaseTriggerHandler.OnAfterUpdateAsync(setUpdatedCaseIds);
         }
        system.debug([Select Id, OwnerId from Case where Id =: lstCases[0].Id]);
       
        system.debug([Select Id, OwnerId from Case where Id =: lstCases[0].Id]);
        //system.assert([Select Id, OwnerId from Case where Id =: lstCases[0].Id].OwnerId == u1.id);
        //system.assert([Select Id, OwnerId from Case where Id =: lstCases[1].Id].OwnerId == u2.id);
       
    }

    static testMethod void myTest4() {

        // This code runs as the system user
        User u1 = CaseRoundRobin_Test.createUser('test@twittertest.com');
        u1.Assignment_Group_Active__c = true;
        insert u1; 
        User u2 = CaseRoundRobin_Test.createUser('test2@twittertest.com');
        u2.Assignment_Group_Active__c = true;
        insert u2; 
        System.debug(u1);

       //*****Create Queue 
       
       Group testGroup = new Group ();
       testGroup.Name = 'TestQueue';
       testGroup.Type = 'Queue';
       insert testGroup;
       
       QueueSObject testQueue = new QueueSObject();
       testQueue.QueueId = testGroup.id;
       testQueue.SObjectType = 'Case';
       insert testQueue;
      

       system.runAs(u2){
        
        //Run test

        //Create Assignment Group
        Assignment_Group_Name__c ag1 = new Assignment_Group_Name__c (Name='TestAG', Type__c = 'Case');
        insert ag1;        

        //Add Good Queue to Assignment Group
        Assignment_Group_Queues__c agq1 = new Assignment_Group_Queues__c(name=testGroup.Name ,Assignment_Group_Name__c = ag1.id );
        insert agq1;
        
          //Test for AG-Queues already assigned to another Assignment Group
        Assignment_Group_Queues__c agq2 = new Assignment_Group_Queues__c(name=testGroup.Name,Assignment_Group_Name__c = ag1.id );
        try {
            insert agq2;
        } catch (DmlException e){
             System.assert(e.getMessage().contains('CUSTOM_VALIDATION_EXCEPTION'), e.getMessage()); 
        } //catch

       }
        
    }
    
    static testmethod void test5 (){
        CaseTriggerHandler caseTrigger = new CaseTriggerHandler(true, 10);
        boolean isTrigger = caseTrigger.IsTriggerContext;
        boolean isVF = caseTrigger.IsVisualforcePageContext;
        boolean isWebservice = caseTrigger.IsWebServiceContext;
        boolean isExecuteAnonymous = caseTrigger.IsExecuteAnonymousContext;
    }
}