/**=====================================================================
 * Appirio, Inc
 * Name: CaseCommentTriggerHandler
 * Description: T-376602: Trigger to update case comments on child records
 *
 * Created Date: April 24th, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified            Modified By              Description of the update
 ======================================================================*/
public class CaseCommentTriggerHandler {
  
  //after insert call
  public static void afterInsert(List<CaseComment> newList) {
    createCaseCommentRecord(newList, null);    
  }
  
  public static void createCaseCommentRecord(List<CaseComment>newList, Map<Id,CaseComment> oldMap) {
        Map<Id,CaseComment> caseMap = new Map<Id,CaseComment>();
        Set<Id> caseIds = new set<Id>();
        
        for (CaseComment csComm: newList){
          caseMap.put(csComm.ParentId, csComm);
          caseIds.add(csComm.ParentId);   
        }
         
        ID rectypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.RECORDTYPE_CASE_EMS).getRecordTypeId();
        
        List<Case> allCases = [SELECT Id, ParentId, Type, RecordTypeId FROM Case 
                               WHERE RecordTypeId = : rectypeid
                               AND Type = :Constants.CASE_TYPE_INCIDENT
                               AND ParentId IN :caseIds];
        
        List<CaseComment> childComment = new List<CaseComment>();
        
        for (integer i=0; i<allCases.size(); i++){
         
            CaseComment newCommment = new CaseComment();
            newCommment.CommentBody = caseMap.get(allCases[i].ParentId).CommentBody;
            newCommment.IsPublished = TRUE;
            newCommment.ParentId = allCases[i].id;
            childComment.add(newCommment);
        }
         
        if(!childComment.isEmpty()){
          insert childComment;
        }
    }  

}