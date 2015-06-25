/**=====================================================================
 * Appirio, Inc
 * Name: SMX_EMS_ProcessCaseBatch
 * Description: T-375155
 * Created Date: 7th May, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified            Modified By                  Description of the update
 *
 =====================================================================*/
global class SMX_EMS_ProcessCaseBatch implements Database.Batchable<Case>, Database.AllowsCallouts{

  Case [] assetsToUpdate = [SELECT Id, ContactId FROM Case 
                                WHERE isClosed = true 
                                AND RecordTypeId IN (SELECT Id FROM RecordType WHERE Name IN ('EMS'))
                                AND Status IN('Closed Resolved','Closed Not Resolved') 
                                AND ContactId != null and ContactId != ''
                                AND ClosedDate <= :(system.now() - 0.1666667) ];                               

    // start method
    global Iterable<Case> start(database.batchablecontext BC){
      if(Test.isRunningTest()){
        Case cs = SMX_EMS_ProcessCaseBatchTest.prepareTestData();
        assetsToUpdate = new List<Case>();
        assetsToUpdate.add(cs);
        return assetsToUpdate; 
      }
      else{
        return assetsToUpdate; 
      }
      //return AssetsToUpdate;    
    }

  //execute method
    global void execute(Database.BatchableContext BC, List<Case> scope){
     
      String strSurveyName = 'EMEA MS Customer Service'; 
      String strSurveyId = 'EXPERIAN_107228';
        
      List <Feedback__c> feedbackList = new List<Feedback__c>();
      Long lgSeed = System.currentTimeMillis();
      Set<Id> setContactIds = new Set<Id>();
      Boolean result = false;
      List<Feedback__c> lstSurvey = new List<Feedback__c>();
      
      Map<String, String> mapCaseIdToFeedbackId = new Map<String, String>();
      
      for (Case cs : scope){
        for (Feedback__c feedback : [SELECT Id FROM Feedback__c WHERE Case__c =:cs.Id ]) {
            mapCaseIdToFeedbackId.put(cs.Id, feedback.Id);
            lstSurvey.add(feedback);
        }
        system.debug('isMapped'+(mapCaseIdToFeedbackId.get(cs.Id)));     
        if (lstSurvey.isEmpty() || String.isBlank(mapCaseIdToFeedbackId.get(cs.Id))){ 
          lgSeed = lgSeed + 1;
          Feedback__c feedback = new Feedback__c();
          feedback.Case__c = cs.Id;
          feedback.Name = 'P_' + lgSeed;
          feedback.Contact__c = cs.ContactId; //ContactName 
          feedback.Status__c = 'Nominated';               
          feedback.DataCollectionName__c = strSurveyName;
          feedback.DataCollectionId__c = strSurveyId;
          feedbackList.add(feedback);        
          system.debug('ifLstSurveyEmpty--feedbackList--'+feedbackList);   
        }
      }
      insert feedbackList;
    }
  
  // finish method
    global void finish(Database.BatchableContext info){
      if (Test.isRunningTest()){
        SMX_EMS_ProcessCaseBatchTest.ClearTestData();
      }
    }//global void finish loop
    
  
}