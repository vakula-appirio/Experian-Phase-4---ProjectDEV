/**=====================================================================
 * Appirio, Inc
 * Name: PlanContactRelationshipHandler_Test
 * Description: Test class for PlanContactRelationshipHandler.cls (for T-356453)
 * Created Date: Feb 2nd, 2015
 * Created By: Naresh Kr Ojha (Appirio)
 *
 * Date Modified          Modified By                    Description of the update
  =====================================================================*/
@isTest
public with sharing class PlanContactRelationshipHandler_Test {
  
  //Tests to validate Plan Contact should be created once only for two contacts
  static testMethod void testValidatePlanContactRelationship() {
    //test data start
    Account account = Test_Utils.insertAccount();

    Opportunity opp = Test_Utils.insertOpportunity(account.id);        

    // creates Opportunity_Plan__c records
    Opportunity_Plan__c oPlan = Test_Utils.insertOpportunityPlan(true, opp.id);
      
    List<Contact> contacts = new List<Contact>();
    contacts.add(Test_Utils.createContact(account.id));
    contacts.add(Test_Utils.createContact(account.id));
    insert contacts;

    List<Opportunity_Plan_Contact__c> opptyPlanContacts = new List<Opportunity_Plan_Contact__c>();
    opptyPlanContacts.add(Test_Utils.createOpportunityPlanContact(oPlan, contacts.get(0)));
    opptyPlanContacts.add(Test_Utils.createOpportunityPlanContact(oPlan, contacts.get(1)));
    insert opptyPlanContacts;
    
    Test.startTest();
    try {
      Plan_Contact_Relationship__c planContactRel = new Plan_Contact_Relationship__c();
      planContactRel.Contact_1__c = opptyPlanContacts.get(0).ID;
      planContactRel.Contact_2__c = opptyPlanContacts.get(1).ID;
      planContactRel.Relationship__c = Constants.STR_POSITIVE;
      insert planContactRel;
      
      //Assert to check Plan Contact Relationship created.
      System.assert([SELECT Id FROM Plan_Contact_Relationship__c WHERE Contact_1__c =: opptyPlanContacts.get(0).ID].size() == 1);
  
      Plan_Contact_Relationship__c anotherPlanContactRel = new Plan_Contact_Relationship__c();
      anotherPlanContactRel.Contact_1__c = opptyPlanContacts.get(0).ID;
      anotherPlanContactRel.Contact_2__c = opptyPlanContacts.get(1).ID;
      anotherPlanContactRel.Relationship__c = Constants.STR_POSITIVE;
      insert anotherPlanContactRel;
    } catch (Exception ex) {
      //Assert to check we can not create Plan Contact Relationship if that is already created for same accounts either negative/positive.
      System.assert(ex.getMessage().contains(System.Label.A_contact_can_be_related_to_another_contact_only_once));
    }
    Test.stopTest();
  }
}