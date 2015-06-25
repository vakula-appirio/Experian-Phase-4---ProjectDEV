/**=====================================================================
 * Appirio, Inc
 * Name: CaseCommentTriggerHandler_Test
 * Description: T-376603: Test class for CaseCommentTriggerHandler
 *
 * Created Date: April 29th, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified            Modified By              Description of the update
 ======================================================================*/
@isTest
public class CaseCommentTriggerHandler_Test {
  
    public static testmethod void testCreateCaseCommentRecord(){
      //create test data
      Account testAcc = Test_Utils.insertAccount();
      
      Contact testCon = Test_Utils.createContact(testAcc.Id);
      insert testCon; 
      
      ID rectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.RECORDTYPE_CASE_EMS).getRecordTypeId();  
      
      Case testCase = Test_Utils.insertCase(false, testAcc.Id);
      testCase.RecordTypeId = rectypeid; 
      testCase.ContactId = testCon.Id;
      testCase.Type = Constants.CASE_TYPE_INCIDENT;
      testCase.Origin = 'Phone';
      testCase.Subject = 'Test Case';
      testCase.RecordTypeId = rectypeid;
      testCase.Description = 'Test data';   
      insert testCase;
      
      List<Case> childCaseLst = new List<Case>();  
      
      for (Integer i=0; i<2; i++) {
        Case childCase = Test_Utils.insertCase(false, testAcc.Id);
        childCase.ParentId = testCase.Id;
        childCase.Type = Constants.CASE_TYPE_INCIDENT;
        childCase.Origin = 'Phone';
        childCase.Subject = 'Test Case-'+i;
        childCase.RecordTypeId = rectypeid;
        childCase.Description = 'Test data';  
        childCaseLst.add(childCase);  
      }
      insert childCaseLst;
      system.debug('==childCaseLst>>>' +childCaseLst);
      //start test
      Test.startTest();
        CaseComment comment = new CaseComment();
        comment.ParentId = testCase.Id;
        comment.CommentBody = 'Test comment';
        comment.IsPublished = true;
        insert comment;
        system.debug('==comment>>>' +comment);
      //stop test
      Test.stopTest();
      
      List<CaseComment> childComment = [SELECT Id, ParentId, CommentBody FROM CaseComment
                                        WHERE ParentId IN :childCaseLst];
      system.debug('==childComment>>' +childComment);  
      //Assert
      System.assertEquals(childComment.size(), childCaseLst.size());    
    }

}