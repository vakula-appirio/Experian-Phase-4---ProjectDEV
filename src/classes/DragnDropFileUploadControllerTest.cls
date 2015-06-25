/**=====================================================================
 * Appirio, Inc
 * Name: DragnDropFileUploadControllerTest
 * Description: T-358314: Test class for DragnDropFileUploader DragnDropFileUploadController.cls
 * Created Date: Feb 03rd, 2015
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Feb 06th, 2015               Arpita Bose                  Added methods testUploadForConInfo(),testUploadForMembership() and
 *                                                           createTestData()
 * Mar 10th, 2015               Noopur Sundriyal             T-368621: Send email on upload error
 * Mar 16th, 2015               Paul Kissick                 Adding more coverage!
 * Apr 23rd, 2015               Paul Kissick                 I-156934: Tests for new Rest Apex calls
 =====================================================================*/
@isTest
private class DragnDropFileUploadControllerTest {
  private static String part1base64;
  private static String part2base64;
  private static Account acct;
  private static Confidential_Information__c conInfo;
  private static Membership__c members;

  static testMethod void testUploadForAccount() {
    createTestData('Account');
    // Start the test
    Test.startTest();
    DragnDropFileUploadController dndCon = new DragnDropFileUploadController();
    String curUrl = dndCon.domainURL;
    system.assert(curUrl != null);
    // Send first part of the file to be uploaded
    String attachmentId = DragnDropFileUploadController.uploadFile(acct.Id, '', 'Test fileName', 'csv', part1base64);

    // Send the second piece of the file to be uploaded
    DragnDropFileUploadController.uploadFile(acct.Id, attachmentId, 'Test fileName', 'csv', part2base64);
    Test.stopTest();

    // Assert one file has been attached to the test account
    List<Attachment> attachments = [SELECT Id, Body FROM Attachment WHERE ParentId = :acct.Id];
    system.assert(attachments.size() == 1);

    // Assert the contents of the split file were recontructed correctly
    system.assert(attachments[0].Body.toString() == 'This text represents a dummy file');
  }

  static testMethod void testUploadForConInfo() {
    createTestData('Confidential_Information__c');
    // Start the test
    Test.startTest();
    // Send first part of the file to be uploaded
    String attachmentId = DragnDropFileUploadController.uploadFile(conInfo.Id, '', 'Test File', 'text', part1base64);

    // Send the second piece of the file to be uploaded
    DragnDropFileUploadController.uploadFile(conInfo.Id, attachmentId, 'Test File', 'text', part2base64);
    Test.stopTest();

    // Assert one file has been attached to the test account
    List<Attachment> attachments = [SELECT Id, Body FROM Attachment WHERE ParentId = :conInfo.Id];
    system.assert(attachments.size() == 1);

    // Assert the contents of the split file were recontructed correctly
    system.assert(attachments[0].Body.toString() == 'This text represents a dummy file');
  }


  static testMethod void testUploadForMembership() {
    createTestData('Membership');
    // Start the test
    Test.startTest();
    // Send first part of the file to be uploaded
    String attachmentId = DragnDropFileUploadController.uploadFile(members.Id, '', 'Test Doc', 'pdf', part1base64);

    // Send the second piece of the file to be uploaded
    DragnDropFileUploadController.uploadFile(members.Id, attachmentId, 'Test Doc', 'pdf', part2base64);
    Test.stopTest();

    // Assert one file has been attached to the test account
    List<Attachment> attachments = [SELECT Id, Body FROM Attachment WHERE ParentId = :members.Id];
    system.assert(attachments.size() == 1);

    // Assert the contents of the split file were recontructed correctly
    system.assert(attachments[0].Body.toString() == 'This text represents a dummy file');
    
    DragnDropFileUploadController.sendMailOnFailure('This is to cover the send email method');
  }

  static testmethod void testIEFallback() {
    acct = Test_Utils.insertAccount();
    Blob part1 = Blob.valueOf('This text re');

    DragnDropFileUploadController c= new DragnDropFileUploadController();
    c.parentId=acct.Id;
    c.attachment.Body = part1;
    c.attachment.Name='Test Doc.txt';
    c.uploadFile();
  }

  //method for test data
  private static void createTestData(String objectName){
    // Split string 'file' in to two chunks, first chunk must be divisible by 3 for base64 encode with no padding
    Blob part1 = Blob.valueOf('This text re'); //length is 12
    Blob part2 = Blob.valueOf('presents a dummy file');

    part1base64 = EncodingUtil.base64Encode(part1);
    part2base64 = EncodingUtil.base64Encode(part2);

    if (objectName.equalsIgnoreCase('Account')) {
      acct = Test_Utils.insertAccount();
    } else {
      acct = Test_Utils.insertAccount();
      Opportunity opp = Test_Utils.insertOpportunity(acct.Id);

      if (objectName.equalsIgnoreCase('Confidential_Information__c')) {
        conInfo = new Confidential_Information__c ();
        conInfo.Name = 'Test ConInfo 001';
        conInfo.Opportunity__c = opp.Id;
        conInfo.Contract_Document__c = true;
        conInfo.Account__c = acct.Id;
        insert conInfo;
      }
      if (objectName.equalsIgnoreCase('Membership')) {
        members = new Membership__c();
        members.Account__c = acct.Id;
        members.Opportunity__c = opp.Id;
        insert members;
      }
    }
  }
  
  static testMethod void testSendMail() {
    
  system.assertEquals(0,Limits.getEmailInvocations());
        
    DragnDropFileUploadController.sendMailOnFailure('This is a failure message.');
        
    system.assertEquals(1,Limits.getEmailInvocations());
    // Trying to send again should fail...
    DragnDropFileUploadController.sendMailOnFailure('This is a failure message.');
    system.assertEquals(1,Limits.getEmailInvocations());
        
  }
    
  static testMethod void testFailureToUpload() {
    DragnDropFileUploadController dndCon = new DragnDropFileUploadController();
    system.assertEquals(null,dndCon.uploadFile());
  }
    
  static testMethod void testFailureToUpload2() {
    String whatHappened = DragnDropFileUploadController.uploadFile(null, '', null, null, null);
    system.assertEquals(null,whatHappened);
  }
    
  static testMethod void testDragAndDropRESTAPI() {
    acct = Test_Utils.insertAccount();
        
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/DragAndDrop/v1/';
    req.addParameter('FileName', 'test.doc');
    req.addParameter('parId',acct.Id);
    req.addParameter('cType','application/msword'); 
    req.httpMethod = 'POST';//HTTP Request Type
    req.requestBody = Blob.valueOf('test doc');
    
    RestContext.request = req;
    RestContext.response= res;

    DragAndDropRESTAPI.attachDoc();
    
    system.assertEquals(1,[SELECT COUNT() FROM Attachment WHERE ParentId = :acct.Id]);
    
  }
    
  static testMethod void testBadDragAndDropRESTAPI() {
    // This test has missing parameters, and should fail!
    acct = Test_Utils.insertAccount();
    
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/DragAndDrop/v1/';

    req.httpMethod = 'POST';//HTTP Request Type
    req.requestBody = Blob.valueOf('test doc');
    
    RestContext.request = req;
    RestContext.response= res;
    
    DragAndDropRESTAPI.attachDoc();
    
    system.assertEquals(0,[SELECT COUNT() FROM Attachment WHERE ParentId = :acct.Id]);
    
  }

}