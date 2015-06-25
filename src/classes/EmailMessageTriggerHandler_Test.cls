/**=====================================================================
 * Appirio, Inc
 * Name: EmailMessageTriggerHandler_Test
 * Description: T-314309: Test class for EmailMessageTriggerHandler.cls
 * Created Date: Aug 25th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Sep 3rd, 2014                Arpita Bose(Appirio)         T-316539: Updated code to populate Sub_Origin__c with ToAddress    
 * Sep 19th, 2014                Mohit Parnami                 T-318433: updated code to populate RecordTypeId, User_Requestor__c, Requestor__c, Requestor_Work_Phone__c                                                                                                                        
 * Oct 10th, 2014               Arpita Bose                  Updated method testPopulateSubOriginOnCase() to fix failure
  =====================================================================*/
@isTest(seeAllData = false)
private class EmailMessageTriggerHandler_Test{
  
  static testmethod void testPopulateSubOriginOnCase(){
    // create test data
    Account testAcc = Test_Utils.insertAccount();
    Contact con = Test_Utils.insertContact(testAcc.Id);
    
    Id EDQGPDId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE, Constants.RECORDTYPE_CASE_EDQ_GPD);

    Case newCase = Test_Utils.insertCase(false, testAcc.Id);
    newCase.SuppliedEmail = 'test@test.com';
    newCase.RecordTypeId = EDQGPDId;
    system.debug('--Rtype---'+newCase.RecordTypeId);
    insert newCase;


    Profile profile = [Select Id From Profile Where Name =: Constants.PROFILE_SYS_ADMIN];
    User usr = Test_Utils.createUser(profile, 'test@test.com', 'LastName');
    usr.Phone = '9799559433';
    insert usr;


    EmailMessage em = new EmailMessage();
    em.FromName = 'Test User';
    em.FromAddress = 'test@example.com';
    em.Incoming = true;
    em.ToAddress = 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com';
    em.Subject = 'Test email';
    em.TextBody = 'Hello';
    em.ParentId = newCase.Id;
    em.CcAddress = 'test@test2.com';

    // start test
    Test.startTest();
    insert em;
    
     List<Case> caseResult = [SELECT Id, Sub_Origin__c, SuppliedEmail, RecordType.Name,
                               RecordTypeId, User_Requestor__c, Requestor__c, Requestor_Email__c, 
                               Requestor_Work_Phone__c
                               FROM Case WHERE Id =:newCase.Id];
     system.debug('case>>' +caseResult);
     List<EmailMessage> emLst = [SELECT Id, ToAddress, Subject, Status, ParentId, FromName, FromAddress
                                 FROM EmailMessage
                                 WHERE Id =:em.Id];
     system.debug('EmailMessage>>' +emLst);                                 
    // stop test
    Test.stopTest();
    // Assert to verify Sub Origin on Case equals to EmailMessage's ToAddress
    system.assertEquals(emLst.get(0).ToAddress+';test@test2.com', caseResult.get(0).Sub_Origin__c);
    system.assertEquals(EDQGPDId, caseResult.get(0).RecordTypeId);
    system.assertEquals(caseResult.get(0).SuppliedEmail, caseResult.get(0).User_Requestor__c);
    system.assertEquals(usr.Id, caseResult.get(0).Requestor__c);
    system.assertEquals(usr.Email, caseResult.get(0).Requestor_Email__c);
    system.assertEquals(usr.Phone, caseResult.get(0).Requestor_Work_Phone__c);
    
  }
  
}