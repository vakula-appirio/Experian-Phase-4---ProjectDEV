/**=====================================================================
 * Appirio, Inc
 * Name: CPQQuoteNewAndEditExtension_Test
 * Description: T-313527: Test Class for CPQQuoteNewAndEditExtension.cls
 * Created Date: Aug 20th, 2014
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Oct 18, 2014                 Nathalie Le Guay (Appirio)   T-326984: Add CPQ/EDQ checks
 * Nov 25th, 2014               Naresh Kr Ojha               Added test method for T-336011, enhanced access criteria.
 * Jan 27th, 2015               Nathalie Le Guay             I-146811: adding asserts around opp.Invoice_to_End_User__c
 * Feb 19th, 2015               Noopur                       T-360546 : modified the class to add the new features related to @testSetup
 * Apr 15th, 2015               Nathalie Le Guay             I-155540: Invoice to End user check is for EDQ users only, moving the 
 *                                                           existing check to testCPQQuoteNewEDQUserWithAllowedEDQTypes()
 * Apr 24th, 2015               Suminder Singh               modified test class for assert failures
 =====================================================================*/
@isTest
private class CPQQuoteNewAndEditExtension_Test {
  private static Id currentUserId;
  private static Opportunity opp;
  private static Quote__c quote;
  private static List<Contact> contactList;
  private static User cpqEDQUser;
  private static User nonEDQUser;
  private static User EDQUserWithAllowedEDQTypes;

  //=============================================================================================
  // Method to test VF page CPQQuoteNew
  //=============================================================================================
  //@isTest
  static testMethod void testCPQQuoteNew(){

     opp = [SELECT Id FROM Opportunity];
     nonEDQUser = [SELECT Id FROM User WHERE LastName = 'Non-EDQ'];
     quote = [SELECT Id,Opportunity__c FROM Quote__c];

    PageReference pageRef = Page.CPQQuoteNew;
    Test.setCurrentPage(pageRef);

    Test.startTest();

    System.runAs(nonEDQUser) {
      CPQQuoteNewAndEditExtension cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(true, cont.isError);

      OpportunityTeamMember opTeamMember = Test_Utils.insertOpportunityTeamMember(true, opp.Id, nonEDQUser.Id, 'Account Manager');

      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(false, cont.isError);
    }

    Test.stopTest();

  }


  //=============================================================================================
  // Method to test VF page CPQQuoteNew
  //=============================================================================================
  @isTest
  static void testCPQQuoteNewEDQUserWithAllowedEDQTypes(){
     opp = [SELECT Id FROM Opportunity];
     contactList = [SELECT Id FROM Contact];
     EDQUserWithAllowedEDQTypes = [SELECT Id FROM User WHERE LastName = 'EDQUserWithAllowedEDQTypes'];
     quote = [SELECT Id,Opportunity__c FROM Quote__c];

    PageReference pageRef = Page.CPQQuoteNew;
    Test.setCurrentPage(pageRef);

    Test.startTest();

    System.runAs(EDQUserWithAllowedEDQTypes) {
      CPQQuoteNewAndEditExtension cont;
     // system.assertEquals('~~~~~~~~~~~~' + [select role from OpportunityContactRole], '+++++');
       List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
      OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, ContactId = contactList.get(0).ID);
      ocrList.add(ocr);
      ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, ContactId = contactList.get(1).ID);
      ocrList.add(ocr);
      ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_SHIPTO, ContactId = contactList.get(2).ID);
      ocrList.add(ocr);
      insert ocrList;
      
      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(false, cont.isError);

      opp.Invoice_to_End_User__c = '';
      update opp;

      quote = [SELECT Id,Opportunity__c FROM Quote__c WHERE Opportunity__c = : opp.ID];

      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      // Invoice to End User is blank, causing error
      system.assertEquals(true, cont.isError);

      opp.Invoice_to_End_User__c = 'Yes';
      update opp;

      quote = [SELECT Id,Opportunity__c FROM Quote__c];
      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(false, cont.isError);
    }

    Test.stopTest();

  }


  //=============================================================================================
  // Method to test VF page CPQQuoteEdit
  //=============================================================================================
  //@isTest
  static testMethod void testCPQQuoteEdit(){

     opp = [SELECT Id FROM Opportunity];
     for( User usr : [SELECT Id,LastName FROM User
                      WHERE LastName = 'cpqEDQUser'
                      OR LastName = 'Non-EDQ']) {
       if(usr.LastName == 'cpqEDQUser') {
         cpqEDQUser = usr;
       }
       else {
         nonEDQUser = usr;
       }
     }
    // cpqEDQUser = [SELECT Id FROM User WHERE LastName = 'cpqEDQUser'];
     quote = [SELECT Id,Opportunity__c FROM Quote__c];
     contactList = [SELECT Id FROM Contact];
    PageReference pageRef = Page.CPQQuoteEdit;
    Test.setCurrentPage(pageRef);

    Test.StartTest();

    System.runAs(cpqEDQUser) {
      CPQQuoteNewAndEditExtension cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      // Missing OppTeam Member
      system.assertEquals(true, cont.isError);
      List<ApexPages.Message> msgList = ApexPages.getMessages();
      //Asserts to get the errors message
      system.debug('msg>>'+msgList);
      System.assert(msgList.size() > 0);

      List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
      OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, ContactId = contactList.get(0).ID);
      ocrList.add(ocr);
      ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, ContactId = contactList.get(1).ID);
      ocrList.add(ocr);
      ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_SHIPTO, ContactId = contactList.get(2).ID);
      ocrList.add(ocr);
      insert ocrList;

      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(true, cont.isError);

      OpportunityTeamMember opTeamMember = Test_Utils.insertOpportunityTeamMember(true, opp.Id, cpqEDQUser.Id, 'Account Manager');

      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(false, cont.isError);

    }

    System.runAs(nonEDQUser) {
      OpportunityTeamMember opTeamMember = Test_Utils.insertOpportunityTeamMember(true, opp.Id, nonEDQUser.Id, 'Account Manager');

      CPQQuoteNewAndEditExtension cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(false, cont.isError);
    }
    Test.StopTest();

  }

  //===========================================================================
  // I-155541: Test for Need Validation rule for Opportunity Term Start/End Dates.
  //===========================================================================
  @isTest
  static void testCPQQuote_ErrorFor_BlankTermDatesOnOppty(){
     opp = [SELECT Id FROM Opportunity];
     EDQUserWithAllowedEDQTypes = [SELECT Id FROM User WHERE LastName = 'EDQUserWithAllowedEDQTypes'];
     quote = [SELECT Id,Opportunity__c FROM Quote__c];
     contactList = [SELECT Id FROM Contact];
    PageReference pageRef = Page.CPQQuoteNew;
    Test.setCurrentPage(pageRef);

    Test.startTest();

    System.runAs(EDQUserWithAllowedEDQTypes) {
      CPQQuoteNewAndEditExtension cont;
       List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
      OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_COMMERCIAL, ContactId = contactList.get(0).ID);
      ocrList.add(ocr);
      ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, ContactId = contactList.get(1).ID);
      ocrList.add(ocr);
      ocr = new OpportunityContactRole(OpportunityId = opp.ID, Role = Constants.OPPTY_CONTACT_ROLE_SHIPTO, ContactId = contactList.get(2).ID);
      ocrList.add(ocr);
      insert ocrList;
      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(false, cont.isError);

      quote = [SELECT Id,Opportunity__c FROM Quote__c WHERE Opportunity__c = : opp.ID];

      try {
	      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
	      
      }
      catch (Exception ex) {
        System.assertEquals('~~~'+ex.getMessage(), '#######');
      } 
      
      opp.Invoice_to_End_User__c = 'Yes';
      update opp;

      quote = [SELECT Id,Opportunity__c FROM Quote__c];
      cont = new CPQQuoteNewAndEditExtension(new ApexPages.StandardController(quote));
      system.assertEquals(false, cont.isError);
    }

    Test.stopTest();

  }

  //=============================================================================================
  // Create Test Data
  //=============================================================================================
  @testSetup
  private static void createTestData() {
    // create data
    Profile p = [select id from profile where name=: Constants.PROFILE_SYS_ADMIN ];
    List<User> users = new List<User>();
    cpqEDQUser = Test_Utils.createCPQUser(p, 't28295jkk@jfdlkk.com', 'CPQ USER');
    cpqEDQUser.LastName = 'cpqEDQUser';
    users.add(cpqEDQUser);
    nonEDQUser = Test_Utils.createCPQUser(p, 't28295jkk@jfdlkk.com', 'CPQ USER');
    nonEDQUser.Business_Unit__c = '';
    nonEDQUser.LastName = 'Non-EDQ';
    users.add(nonEDQUser);
    EDQUserWithAllowedEDQTypes = Test_Utils.createCPQUser(p, 't28295jkk@jfdlkk.com', 'CPQ USER');
    EDQUserWithAllowedEDQTypes.LastName = 'EDQUserWithAllowedEDQTypes';
    EDQUserWithAllowedEDQTypes.CPQ_User_Type__c = Constants.EDQ_USER_TYPE_COMM_TECH_LEGAL;
    users.add(EDQUserWithAllowedEDQTypes);

    insert users;

    //currentUserId = UserInfo.getUserId();
    Account acc = Test_Utils.createAccount();
    acc.Name ='testAcc';
    insert acc;
    opp = Test_Utils.createOpportunity(acc.Id);
    opp.Invoice_to_End_User__c = 'Yes';
    opp.Contract_Start_Date__c = Date.today();
    opp.Contract_End_Date__c = Date.today()+2;
    insert opp;

    contactList = new List<Contact>();

    Contact shipToContact = Test_Utils.createContact(acc.ID);
    contactList.add(shipToContact);
    Contact purchLedContact = Test_Utils.createContact(acc.ID);
    contactList.add(purchLedContact);
    Contact contractContact = Test_Utils.createContact(acc.ID);
    contactList.add(contractContact);

    insert contactList;

    quote = new Quote__c();
    quote.Opportunity__c = opp.Id;
    insert quote;
  }

}