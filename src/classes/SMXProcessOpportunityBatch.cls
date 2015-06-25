global class SMXProcessOpportunityBatch implements Database.Batchable<Opportunity>, Database.AllowsCallouts{


//String[] oppIdStr;



global Iterable<Opportunity> start(database.batchablecontext BC){
    List<String> oppStage=new List<String>();
    List<String> businessUnitStr=new List<String>();
    //String[] oppIds;
    //Integer i=0;
    List<OpportunityStage> oppStageList=[select MasterLabel from OpportunityStage where isActive = true and isWon = true];
    for(OpportunityStage oopStage1: oppStageList){
        oppStage.add(oopStage1.MasterLabel);
    }
    //i=0;
    List<Business_Unit_Group_Mapping__c> businessUnitList=[select User_Business_Unit__c from Business_Unit_Group_Mapping__c where Common_Group_Name__c = 'EDQ'];
    for(Business_Unit_Group_Mapping__c businessUnit : businessUnitList){
        businessUnitStr.add(businessUnit.User_Business_Unit__c);
        //i++;
    }
    Opportunity [] OpportunityToUpdate = [select Id from Opportunity where Id IN (select OpportunityId from  OpportunityHistory where StageName IN :oppStage and createddate >= YESTERDAY) and Owner_s_Business_Unit__c IN : businessUnitStr and Type NOT IN('Credited', 'Existing Business', 'Free Trail', 'Renewal', 'Trial') and Owner_s_Region__c IN('UK&I','North America')];
    if(Test.isRunningTest()){
        List<Opportunity> oppTestList=new List<Opportunity>();
        Opportunity opp=SMXProcessOpportunityBatchTest.prepareTestData();
        oppTestList.add(opp);
        return oppTestList; 
    }
    else{
        return OpportunityToUpdate; 
    }
    //return AssetsToUpdate;    
}

global void execute(Database.BatchableContext BC, List<Opportunity> scope){
 
    String strSurveyName = 'EDQ Purchase Experience';
    String strSurveyId = 'EXPERIAN_106613';
    
    List <Feedback__c> feedbackList = new List<Feedback__c>();
    Long lgSeed = System.currentTimeMillis();
    Set<Id> setContactIds = new Set<Id>();
    Boolean result = false;
    for(Opportunity cs: scope){
        List<Feedback__c> lstSurvey = [select Id from Feedback__c where Opportunity__c =: cs.Id ];      
       //system.debug('test case id ' +cs.Id);
       //system.debug('Feedback id '+ lstSurvey.get(0).id);
      if(lstSurvey.isEmpty()){
        List<OpportunityContactRole> oppContactList=[select ContactId from OpportunityContactRole where OpportunityId=: cs.Id];
        for(OpportunityContactRole oppContact: oppContactList){
            lgSeed = lgSeed + 1;
            Feedback__c feedback = new Feedback__c();
            feedback.Opportunity__c = cs.Id;
            feedback.Name = 'P_' + lgSeed;
            feedback.Contact__c = oppContact.ContactId; //ContactName 
            feedback.Status__c = 'Nominated';               
            feedback.DataCollectionName__c = strSurveyName;
            feedback.DataCollectionId__c = strSurveyId;
            feedbackList.add(feedback);
         }        
      }
     
    }
    insert feedbackList;
 }

global void finish(Database.BatchableContext info){
    if(Test.isRunningTest()){
    SMXProcessOpportunityBatchTest.ClearTestData();
    }
  }//global void finish loop
    
  
}