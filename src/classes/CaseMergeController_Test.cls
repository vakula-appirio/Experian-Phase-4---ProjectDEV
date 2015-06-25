/**=====================================================================
 * Experian
 * Name: CaseMergeController_Test
 * Description: Test class for Case Merge functionality
 *              Case #556253
 * Created Date: Mar 23rd, 2015
 * Created By: Paul Kissick
 * 
 * Date Modified                 Modified By                  Description of the update
 * Mar 23rd, 2015                Paul Kissick                 Created 
 * Apr 18th, 2015                Paul Kissick                 Case #921953: Added testTruncationFunction method to verify truncations.
 =====================================================================*/

@isTest
private class CaseMergeController_Test {
  
  @testSetup static void loadSettings() {
    
    Global_Settings__c gl = new Global_Settings__c(Name = Constants.GLOBAL_SETTING);
    insert gl;
    
  }
  
  private static testMethod void testBadMerge() {
    
    system.assertEquals(false,CaseMergeUtility.mergeCases(null,null));
    
    Case c1 = new Case(
      Subject = 'Test Case 1', Status = 'Open'
    );
    insert c1;

    
    system.assertEquals(false,CaseMergeUtility.mergeCases(c1.Id,null));
    system.assertEquals(false,CaseMergeUtility.mergeCases(c1.Id,new Set<Id>{c1.Id}));

    
  }
  
  private static testMethod void testGoodMerge() {
    
    Case c1 = new Case(
      Subject = 'Test Case 1', Status = 'Open'
    );
    insert c1;
    
    Case c2 = new Case(
      Subject = 'Dup Test Case 1', Status = 'Open'
    );
    insert c2;
    
    system.assertEquals(true,CaseMergeUtility.mergeCases(c1.Id,new Set<Id>{c2.Id}));
    
    system.assertEquals(1,[SELECT COUNT() FROM Case WHERE IsClosed = true]);
    
    
  }
  
  private static testMethod void testGoodMergeWithExtras() {
    
    Case c1 = new Case(
      Subject = 'Test Case 1', Status = 'Open'
    );
    insert c1;
    CaseComment cc1 = new CaseComment(ParentId = c1.Id, CommentBody = 'Test Comment 1');
    insert cc1;
    
    Case c2 = new Case(
      Subject = 'Dup Test Case 1', Status = 'Open'
    );
    insert c2;
    CaseComment cc2 = new CaseComment(ParentId = c2.Id, CommentBody = 'Test Comment 2');
    insert cc2;
    EmailMessage eml1 = new EmailMessage(
      ParentId = c2.Id, 
      FromAddress = 'test.person@email.com', 
      FromName = 'Test Name',
      Incoming = true, 
      MessageDate = Datetime.now(),
      Subject = 'Test Case Email 1',
      TextBody = 'Test information', 
      ToAddress = 'support@experian.com'
    );
    insert eml1;
    Attachment emlAtt1 = new Attachment(ParentId = eml1.Id, Name = 'File.txt', Body = Blob.valueOf('Text Body'));
    Attachment caseAtt1 = new Attachment(ParentId = c2.Id, Name = 'File2.txt', Body = Blob.valueOf('Text Body'));
    insert new List<Attachment>{caseAtt1,emlAtt1};
    
    Task t1 = new Task(Subject = 'Do this',WhatId = c2.Id);
    insert t1;
    Test.startTest();
    system.assertEquals(0,[SELECT COUNT() FROM Attachment WHERE ParentId = :c1.Id]);
    system.assertEquals(0,[SELECT COUNT() FROM Task WHERE WhatId = :c1.Id]);
    system.assertEquals(true,CaseMergeUtility.mergeCases(c1.Id,new Set<Id>{c2.Id}));
    
    system.assertEquals(1,[SELECT COUNT() FROM Case WHERE IsClosed = true]);
    // Should now have 2 attachments on the case.
    system.assertEquals(2,[SELECT COUNT() FROM Attachment WHERE ParentId = :c1.Id]);
    // Should now have the task inserted above.
    system.assertEquals(1,[SELECT COUNT() FROM Task WHERE WhatId = :c1.Id]);
    Test.stopTest();
    
  }
  
  private static testMethod void testCaseMergePage() {
    
    Case c1 = new Case(
      Subject = 'Test Case 1', Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.CASE_REC_TYPE_CRM_REQUEST).getRecordTypeId()
    );
    insert c1;
    CaseComment cc1 = new CaseComment(ParentId = c1.Id, CommentBody = 'Test Comment 1');
    insert cc1;
    
    Case c2 = new Case(
      Subject = 'RE: Test Case 1', Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.CASE_REC_TYPE_CRM_REQUEST).getRecordTypeId()
    );
    insert c2;
    CaseComment cc2 = new CaseComment(ParentId = c2.Id, CommentBody = 'Test Comment 2');
    insert cc2;
    
    //Different type, shouldn't be found in the search...
    Case c3 = new Case(
      Subject = 'RE: Test Case 1', Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.CASE_REC_TYPE_CPQ_REQUEST).getRecordTypeId()
    );
    insert c3;
    
    String caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :c1.Id].CaseNumber;
    
    ApexPages.StandardController con = new ApexPages.StandardController(c2);
    CaseMergeController cmc = new CaseMergeController(con);
    cmc.prepareSearch();
    system.assertEquals(1,cmc.getFoundParents().size());
    cmc.caseNumber = caseNumber;
    cmc.searchCases();
    system.assertEquals(1,cmc.getFoundParents().size());
    system.assertEquals(true,cmc.showSearchGrid);
    system.assertEquals(null,cmc.selectedCase);
    cmc.selectCase();
    
    // check the setcontroller methods...
    system.assertEquals(false,cmc.getHasNext());
    system.assertEquals(false,cmc.getHasPrevious());
    
    
    cmc.gotoLast();
    cmc.gotoPrevious();
    cmc.gotoNext();
    cmc.gotoStart();
    system.assertEquals(1,cmc.getPageNumber());
    system.assertEquals(1,cmc.getResultSize());
    system.assertEquals(1,cmc.getTotalPages());
    
    cmc.selectedCase = c1.Id;
    cmc.selectCase();
    system.assertEquals(false,cmc.showSearchGrid);
    system.assertEquals(true,cmc.showWinner);
    
    cmc.backToList();
    system.assertEquals(true,cmc.showSearchGrid);
    system.assertEquals(false,cmc.showWinner);
    system.assertEquals(null,cmc.selectedCase);
    
    cmc.selectedCase = c1.Id;
    cmc.selectCase();
    system.assertEquals(false,cmc.showSearchGrid);
    system.assertEquals(true,cmc.showWinner);
    
    system.assertNotEquals(null,cmc.performMerge());
    
    system.assertEquals(1, [SELECT COUNT() FROM Case WHERE IsClosed = true]);
    
  }

  private static testMethod void testCaseMergeListPage() {
    
    Case c1 = new Case(
      Subject = 'Test Case 1', Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.CASE_REC_TYPE_CRM_REQUEST).getRecordTypeId()
    );
    insert c1;
    
    Case c2 = new Case(
      Subject = 'RE: Test Case 1', Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.CASE_REC_TYPE_CRM_REQUEST).getRecordTypeId()
    );
    insert c2;
    
    //Different type, shouldn't be found in the search...
    Case c3 = new Case(
      Subject = 'RE: Test Case 1', Status = 'Open', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.CASE_REC_TYPE_CPQ_REQUEST).getRecordTypeId()
    );
    insert c3;
    
    ApexPages.StandardSetController scon = new ApexPages.StandardSetController([SELECT Id FROM Case WHERE IsClosed = false]);
    scon.setSelected([SELECT Id FROM Case WHERE IsClosed = false]);
    CaseMergeController cmc = new CaseMergeController(scon);
    cmc.mergeFromList();
    
    system.assertEquals(1, [SELECT COUNT() FROM Case WHERE IsClosed = false]);
    system.assertEquals(2, [SELECT COUNT() FROM Case WHERE IsClosed = true]);
  }
  
  private static testMethod void testTruncationFunction() {
   
    // always ensure this works as expected.
    system.assertEquals('',CaseMergeUtility.truncateToLength(null,null));
    
    system.assertEquals('',CaseMergeUtility.truncateToLength('',null));
    
    system.assertEquals('',CaseMergeUtility.truncateToLength('abcde',0));
    
    system.assertEquals('',CaseMergeUtility.truncateToLength('abcde',-1));
    
    system.assertEquals('abcde',CaseMergeUtility.truncateToLength('abcde',5));
    
    system.assertEquals('abcde',CaseMergeUtility.truncateToLength('abcdefghij',5));
    
  }

}