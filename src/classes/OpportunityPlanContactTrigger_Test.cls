/**=====================================================================
 * Appirio, Inc
 * Test Class Name: OpportunityPlanContactTrigger_Test
 * Class Name: OpportunityPlanContactTrigger & OpportunityPlanContactTriggerHandler
 * Created Date: May 23rd, 2014
 * Created By: Naresh kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest
private class OpportunityPlanContactTrigger_Test {

  static testMethod void testMethod1() {
  	Account account = Test_Utils.createAccount();
  	Contact contact = Test_Utils.createContact(account.ID);
    Opportunity opportunity = Test_Utils.insertOpportunity(account.id);
    Opportunity opportunity2 = Test_Utils.insertOpportunity(account.id);        

    Opportunity_Plan__c oppPlan = Test_Utils.insertOpportunityPlan(true, opportunity.id);
    Opportunity_Plan__c oppPlan2 = Test_Utils.insertOpportunityPlan(true, opportunity2.id);
    
    Opportunity_Plan_Contact__c oppPlanCont = new Opportunity_Plan_Contact__c();
    oppPlanCont.Opportunity_Plan__c = oppPlan.ID;
    oppPlanCont.Contact__c = contact.ID;
    insert oppPlanCont;

    Opportunity_Plan_Contact__c oppPlanCont2 = new Opportunity_Plan_Contact__c();
    oppPlanCont2.Opportunity_Plan__c = oppPlan2.ID;
    oppPlanCont2.Contact__c = contact.ID;
    insert oppPlanCont2;
      
    /*      
      Plan_Contact_Relationship__c planContRel = new Plan_Contact_Relationship__c();
        planContRel.Relationship__c = 'Positive';
        planContRel.Contact_1__c = oppPlanCont.ID; 
        planContRel.Contact_2__c = oppPlanCont2.ID;
        insert planContRel;
    */  
    Plan_Contact_Relationship__c planContRel = Test_Utils.createPlanContactRelationship(false,oppPlanCont ,oppPlanCont2,'Positive');
      
        
      //To query deleted plan contact relationships.
      ID oldOppPlanID = oppPlanCont2.ID;
      
      Test.startTest();
        delete oppPlanCont2;
      Test.stopTest();
      //Assert to check deleted associated records. 
      System.assertEquals([SELECT count() FROM Plan_Contact_Relationship__c WHERE Contact_2__c =: oldOppPlanID], 0);
  }
  
  static testMethod void testMethod2() {
  	Account account = Test_Utils.createAccount();
    Contact contact = Test_Utils.createContact(account.ID);
    Opportunity opportunity = Test_Utils.insertOpportunity(account.id);
    Opportunity opportunity2 = Test_Utils.insertOpportunity(account.id);        

    Opportunity_Plan__c oppPlan = Test_Utils.insertOpportunityPlan(true, opportunity.id);
    Opportunity_Plan__c oppPlan2 = Test_Utils.insertOpportunityPlan(true, opportunity2.id);
    
    Opportunity_Plan_Contact__c oppPlanCont = new Opportunity_Plan_Contact__c();
      oppPlanCont.Opportunity_Plan__c = oppPlan.ID;
      oppPlanCont.Contact__c = contact.ID;
      insert oppPlanCont;

      Opportunity_Plan_Contact__c oppPlanCont2 = new Opportunity_Plan_Contact__c();
      oppPlanCont2.Opportunity_Plan__c = oppPlan2.ID;
      oppPlanCont2.Contact__c = contact.ID;
      insert oppPlanCont2;
            
      /*
      Plan_Contact_Relationship__c planContRel = new Plan_Contact_Relationship__c();
      planContRel.Relationship__c = 'Positive';
      planContRel.Contact_1__c = oppPlanCont.ID; 
      planContRel.Contact_2__c = oppPlanCont2.ID;
      insert planContRel;
      */
      
      
     Plan_Contact_Relationship__c planContRel = Test_Utils.createPlanContactRelationship(false,oppPlanCont ,oppPlanCont2,'Positive');
             
     
      
        
      //To query deleted plan contact relationships.
      ID oldOppPlanID = oppPlanCont2.ID;
      
      Test.startTest();
        delete oppPlanCont2;
          //Assert to check deleted associated records. 
          System.assertEquals([SELECT count() FROM Plan_Contact_Relationship__c WHERE Contact_2__c =: oldOppPlanID], 0);
        //undelete Test
        undelete oppPlanCont2;
      Test.stopTest();
      
      //Assert to check deleted associated records. 
      //System.assertNotEquals([SELECT count() FROM Plan_Contact_Relationship__c WHERE Contact_2__c =: oldOppPlanID], 0);
  }
}