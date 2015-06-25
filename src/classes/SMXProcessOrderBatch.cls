global class SMXProcessOrderBatch implements Database.Batchable<Order__c>, Database.AllowsCallouts{



global Iterable<Order__c> start(database.batchablecontext BC){
    List<String> businessUnitStr=new List<String>();
    List<Business_Unit_Group_Mapping__c> businessUnitList=[select User_Business_Unit__c from Business_Unit_Group_Mapping__c where Common_Group_Name__c = 'EDQ'];
    for(Business_Unit_Group_Mapping__c businessUnit : businessUnitList){
        businessUnitStr.add(businessUnit.User_Business_Unit__c);
    }
    
    Order__c [] OrderToUpdate = [select Id, Contact__c from Order__c where Renewal_Survey_Date__c=TODAY and Owner_Business_Unit__c IN : businessUnitStr and Owner_Region__c IN('UK&I','North America')];
    if(Test.isRunningTest()){
        //Opportunity opp=SMXProcessOpportunityBatchTest.prepareTestData();
        return OrderToUpdate; 
    }
    else{
        return OrderToUpdate; 
    }
    //return AssetsToUpdate;    
}

global void execute(Database.BatchableContext BC, List<Order__c> scope){
 
    String strSurveyName = 'EDQ Contract Renewal';
    String strSurveyId = 'EXPERIAN_106614';
    
    List <Feedback__c> feedbackList = new List<Feedback__c>();
    Long lgSeed = System.currentTimeMillis();
    Set<Id> setContactIds = new Set<Id>();
    Boolean result = false;
    for(Order__c cs: scope){
        List<Feedback__c> lstSurvey = [select Id from Feedback__c where Order__c =: cs.Id ];      
       //system.debug('test case id ' +cs.Id);
       //system.debug('Feedback id '+ lstSurvey.get(0).id);
      if(lstSurvey.isEmpty()){
        lgSeed = lgSeed + 1;
        Feedback__c feedback = new Feedback__c();
        feedback.Order__c = cs.Id;
        feedback.Name = 'P_' + lgSeed;
        feedback.Contact__c = cs.Contact__c; //ContactName 
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
    SMXProcessOrderBatchTest.ClearTestData();
    }
  }//global void finish loop
    
  
}