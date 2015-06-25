/**=====================================================================
 * Experian
 * Name: CaseMergeUtility
 * Description: Utility class to provide merge functionality across multiple pages
 *              Case #556253
 * Created Date: Mar 23rd, 2015
 * Created By: Paul Kissick
 * 
 * Date Modified                 Modified By                  Description of the update
 * Mar 23rd, 2015                Paul Kissick                 Created 
 * Apr 18th, 2015                Paul Kissick                 Case #921953: Added checks for large text fields.
 =====================================================================*/
public with sharing class CaseMergeUtility {
  
  public class caseMergeException extends Exception{}
  
  /* 
   * MergeCases function to merge multiple child cases into a parent case.
   */
  public static Boolean mergeCases(Id parentCaseId, Set<Id> childCaseIds) {
    Boolean success = false;
    if (parentCaseId == null) return success;
    if (childCaseIds == null) return success;
    if (childCaseIds != null && childCaseIds.isEmpty()) return success;
    if (childCaseIds != null && !childCaseIds.isEmpty()) {
      // Prevents a child being a parent!
      if (childCaseIds.contains(parentCaseId)) return success;
    }
    
    Savepoint sp = Database.setSavepoint();
    try {
      /* Update the original (losing) case... */
      List<Case> loserCases = [
        SELECT Id, Description, Status, ParentId, CaseNumber
        FROM Case
        WHERE Id IN :childCaseIds
      ];
      Case winnerCase = [SELECT Id, Description, Status, CaseNumber, Subject, Owner.Name FROM Case WHERE Id = :parentCaseId LIMIT 1];
      
      List<String> mergedFromCases = new list<String>();
      for(Case lCase : loserCases) {
        mergedFromCases.add('Case #'+lCase.CaseNumber);
      }
      CaseComment addMergeCommentToWinner = new CaseComment(ParentId = parentCaseId, IsPublished = false, CommentBody = 'Merged from '+String.join(mergedFromCases,', '));
      insert addMergeCommentToWinner;
      
      /* Email Messages with Attachments */
      Map<Id,EmailMessage> loserEmls = new Map<Id,EmailMessage>([
        SELECT Id, ParentId, ActivityId, BccAddress, CcAddress, FromAddress, FromName,
          Headers, HtmlBody, Incoming, MessageDate, ReplyToEmailMessageId, Status, Subject,
          TextBody, ToAddress
          ,(SELECT Id, Name, ParentId FROM Attachments)
        FROM EmailMessage 
        WHERE ParentId IN :childCaseIds
      ]);
      if (loserEmls.size() > 0) {
        List<EmailMessage> winnerEmls = new List<EmailMessage>();
        List<Attachment> newEmlAtts = new List<Attachment>();
        List<Id> emlIds = new List<Id>();
        for(Id emlId : loserEmls.keySet()) {
          EmailMessage em = loserEmls.get(emlId);
          EmailMessage newEml = em.clone(false,false,false,false);
          // CASE #921953
          // check the textarea fields aren't too large...
          Map<String,Integer> textCheckMap = new Map<String,Integer>{
            'Headers' => 32000,
            'TextBody' => 32000,
            'HtmlBody' => 32000,
            'BccAddress' => 4000,
            'CcAddress' => 4000,
            'ToAddress' => 4000,
            'Subject' => 3000
          };
          for(String fieldName : textCheckMap.keySet()) {
            newEml.put(fieldName,truncateToLength((String)em.get(fieldName),textCheckMap.get(fieldName))); 
          }

          if (em.Attachments != null && em.Attachments.size() > 0) {
            // move these to the parent case, as this works!
            emlIds.add(emlId);
          }
          newEml.ParentId = parentCaseId; // Reparent to winning case
          winnerEmls.add(newEml);
        }
        if (emlIds.size() > 0) {
          List<Attachment> emlAtts = [
            SELECT Id, Name, Body, ParentId, IsPrivate
            FROM Attachment
            WHERE ParentId IN :emlIds
          ];
          for (Attachment eAtt : emlAtts) {
            Attachment newAtt = eAtt.clone(false,false,false,false);
            newAtt.ParentId = parentCaseId;
            newEmlAtts.add(newAtt);
          }
        }
        
        insert winnerEmls;
        insert newEmlAtts;
      }
      
      /* Find any tasks on the case too and move them... */
      List<Task> loserTasks = [SELECT Id, WhatId FROM Task WHERE WhatId IN :childCaseIds];
      for(Task t : loserTasks) {
        t.WhatId = parentCaseId;
      }
      update loserTasks;
      
      /* Existing Comments */
      List<CaseComment> loserComments = [
        SELECT ParentId, IsPublished, CommentBody 
        FROM CaseComment 
        WHERE ParentId IN :childCaseIds
      ];
      List<CaseComment> winnerComments = new List<CaseComment>();
      for(CaseComment cc : loserComments) {
        CaseComment newCC = cc.clone(false,false,false,false);
        newCC.ParentId = parentCaseId;
        winnerComments.add(newCC);
      }
      insert winnerComments;
      
      /* Existing Attachments */
      List<Attachment> loserAtts = [
        SELECT Id, Name, Body, ParentId, IsPrivate
        FROM Attachment
        WHERE ParentId IN :childCaseIds
      ];
      if (loserAtts.size() > 0) {
        List<Attachment> winnerAtts = new List<Attachment>();
        for(Attachment att : loserAtts) {
          Attachment winAtt = att.clone(false,false,false,false);
          winAtt.parentId = parentCaseId;
          winnerAtts.add(winAtt);
        }
        insert winnerAtts;
      }
      
      /* Save the descriptions as a comment on the winning case */
      List<CaseComment> loserDescriptions = new List<CaseComment>();
      for(Case lCase : loserCases) {
        String lCaseDesc = truncateToLength(lCase.Description, 4000);
        loserDescriptions.add(new CaseComment(ParentId = parentCaseId, IsPublished = false, CommentBody = lCaseDesc));
      }
      insert loserDescriptions;
      
      List<CaseComment> addMergeCommentToLosers = new List<CaseComment>();
      for(Case lCase : loserCases) {
        addMergeCommentToLosers.add(new CaseComment(ParentId = lCase.Id, IsPublished = false, CommentBody = 'Merged into Case #'+winnerCase.CaseNumber));
      }
      insert addMergeCommentToLosers;
      
      /* Finally, reparent the losing cases (don't delete!) */
      for(Case lCase : loserCases) {
        lCase.ParentId = parentCaseId;
        lCase.Status = 'Closed - Duplicate'; // New picklist option
      }
      
      update loserCases;
      
      success = true;
      
    }
    catch (Exception e) {
      Database.rollback(sp);
      throw new caseMergeException(e.getMessage());
    }
    return success;
  } 
  
  public static String truncateToLength(String strIn, Integer len) {
    String strOut = '';
    if (String.isNotBlank(strIn) && len != null && len > 0) {
      strOut = strIn.mid(0,len);
    }
    return strOut;
  }
  
  
}