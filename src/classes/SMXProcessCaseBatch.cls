global class SMXProcessCaseBatch implements Database.Batchable<Case>, Database.AllowsCallouts{

case [] AssetsToUpdate = [select Id, ContactId from Case where isClosed=true and status IN('Closed Resolved','Closed - Complete') and closedDate >= YESTERDAY and RecordTypeId IN (select id from RecordType where name IN ('EDQ Case', 'EDQ Commercial Case', 'EDQ GPD Case')) and ContactId != null and ContactId != ''];

global Iterable<Case> start(database.batchablecontext BC){
    if(Test.isRunningTest()){
        case cs =SMXProcessCaseBatchTest.prepareTestData();
        AssetsToUpdate = new List<Case>();
        AssetsToUpdate.add(cs);
        return AssetsToUpdate; 
    }
    else{
        return AssetsToUpdate; 
    }
    //return AssetsToUpdate;    
}

global void execute(Database.BatchableContext BC, List<Case> scope){
 
    String strSurveyName = 'EDQ Support Experience';
    String strSurveyId = 'EXPERIAN_106615';
    
    List <Feedback__c> feedbackList = new List<Feedback__c>();
    Long lgSeed = System.currentTimeMillis();
    Set<Id> setContactIds = new Set<Id>();
    Boolean result = false;
    for(Case cs: scope){
        List<Feedback__c> lstSurvey = [select Id from Feedback__c where case__c =: cs.Id ];      
       //system.debug('test case id ' +cs.Id);
       //system.debug('Feedback id '+ lstSurvey.get(0).id);
       Contact con=[select email from Contact where id=: cs.ContactId];
      if(lstSurvey.isEmpty() && (!con.email.endsWith('experian.com'))){
        lgSeed = lgSeed + 1;
        Feedback__c feedback = new Feedback__c();
        feedback.Case__c = cs.Id;
        feedback.Name = 'P_' + lgSeed;
        feedback.Contact__c = cs.ContactId; //ContactName 
        feedback.Status__c = 'Nominated';               
        feedback.DataCollectionName__c = strSurveyName;
        feedback.DataCollectionId__c = strSurveyId;
        feedbackList.add(feedback);        
      }
     
    }
    insert feedbackList;
 }

global void finish(Database.BatchableContext info){
    if(Test.isRunningTest()){
    SMXProcessCaseBatchTest.ClearTestData();
    }
  }//global void finish loop
    
  
}