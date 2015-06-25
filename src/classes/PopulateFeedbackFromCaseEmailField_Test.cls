//
// (c) 2014 Appirio, Inc.
//
// Test class for PopulateFeedbackFromCaseEmailFieldTrigger;
// which is used to populate Email fields on Feedback__c
//
// May 12, 2015      Sidhant Agarwal     Original (Ref. T-375157)
//
@isTest
private class PopulateFeedbackFromCaseEmailField_Test {
    private static String GRP_KEY_PREFIX = '00G';
    private static String emsRecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.RECORDTYPE_CASE_EMS );
    private static Feedback__c feedback;
    private static User testUser1;
    private static User testUser;
    private static Account testAcc1;
    private static Contact newcontact1;
    private static List<Case> lstCase;
    private static Group grp1;
    private static QueuesObject qObj1;
    
    static testMethod void afterInsertTest() {
        createData();
        system.assertEquals(null, feedback.CaseOwnerManagerEmail__c);
    }
    
    static testMethod void afterUpdateTest() {
    	createData();
    	feedback.Name = 'New DUmmy Name';
    	feedback.Case__c = lstCase[1].Id;
    	update feedback;
    	system.assertEquals(null, feedback.CaseOwnerEmail__c);
    	feedback.Case__c = lstCase[2].Id;
    	update feedback;
    	system.assertEquals(testUser1.Managers_Email__c, feedback.CaseOwnerManagerEmail__c);
    }
    
    static void createData() {
    	testUser1 = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
        
	    Profile p = [SELECT id from profile where name =: Constants.PROFILE_SYS_ADMIN ];
	    testUser = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                 emailencodingkey='UTF-8', firstName='test user', lastname='Testing', languagelocalekey='en_US',
                 localesidkey='en_US', profileid = p.Id, timezonesidkey='America/Los_Angeles', Region__c = 'EMEA',
                 username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true,
                 CompanyName = 'test Company', ManagerId = testUser1.ID);
        insert testUser;
        
        testAcc1 = Test_Utils.insertAccount();
    
    	newcontact1  = new Contact (FirstName = 'Larry', LastName = 'Ellison',
                               AccountId = testAcc1.Id, Email = 'sidhant.agarwal@appirio.com');
        insert newcontact1;
    	system.runAs(testUser1) {
    		grp1 = new Group(Name='group name', type='Queue');
	        insert grp1;
	        qObj1 = new QueueSObject(QueueID = grp1.id, SobjectType = 'Case');
	        insert qObj1;
    	}
    	
    	
    	lstCase = new List<Case>();
    	
    	Case newCase = new Case();
    	newCase.Account__c = testAcc1.Id;
    	newCase.Subject = 'Test';
    	newCase.Type = 'Incident';
    	newCase.Reason = 'Data';
    	newCase.Secondary_Case_Reason__c = 'Data Expiry';
    	newCase.Description = 'Dummy Description';
    	newCase.RecordTypeId = emsRecordTypeId;
    	newCase.OwnerId = testUser1.Id;
    	lstCase.add(newcase);
    	
    	Case newCase2 = new Case();
        newCase2.Account__c = testAcc1.Id;
        newCase2.Subject = 'Tester';
        newCase2.Type = 'Incident';
        newCase2.Reason = 'Data';
        newCase2.Secondary_Case_Reason__c = 'Data Expiry';
        newCase2.Description = 'Dummy Descriptioner';
        newCase2.RecordTypeId = emsRecordTypeId;
        newCase2.OwnerId = grp1.Id;
        lstCase.add(newcase2);
        
        Case newCase3 = new Case();
        newCase3.Account__c = testAcc1.Id;
        newCase3.Subject = 'Tester';
        newCase3.Type = 'Incident';
        newCase3.Reason = 'Data';
        newCase3.Secondary_Case_Reason__c = 'Data Expiry';
        newCase3.Description = 'Dummy Descriptioner';
        newCase3.RecordTypeId = emsRecordTypeId;
        newCase3.OwnerId = testUser.Id;
        lstCase.add(newcase3);
    	
    	insert lstCase;
    	
    	feedback = new Feedback__c();
    	feedback.Name = 'DummyFeedback';
    	feedback.Contact__c = newcontact1.Id;
    	feedback.DataCollectionId__c = 'Dummy';
    	feedback.DataCollectionName__c = 'Dumm' ;
    	feedback.Case__c = lstCase[0].Id ;
    	feedback.PrimaryScore__c = 1;
    	feedback.Status__c = 'Dum';
    	insert feedback;
    }
}