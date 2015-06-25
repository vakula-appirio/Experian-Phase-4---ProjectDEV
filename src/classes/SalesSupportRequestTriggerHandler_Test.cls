@isTest(seealldata=true)
public class SalesSupportRequestTriggerHandler_Test {

  @isTest
  public static void testCreateSalesSupportClientEcos() {
  	Integer i;
    Integer count = 0;
    List<Competitor__c> lstCompetitors = new List<Competitor__c>();
    List<OpportunityContactRole> lstOppContactRoles = new List<OpportunityContactRole>();
      
	// Create Test Data
	Account testAccount = Test_Utils.insertAccount();
    
    Account testCompetitorAccount = Test_Utils.createAccount();
    testCompetitorAccount.Is_Competitor__c = true;
    insert testCompetitorAccount;
    
    Opportunity testOpportunity = Test_Utils.insertOpportunity(testAccount.Id);      
    Contact testContact = Test_Utils.insertContact(testAccount.Id);
    
    Competitor__c testCompetitor = new Competitor__c();  
    while(count < 5) {
      // Contact Roles
      OpportunityContactRole testOppContactRole = Test_Utils.insertOpportunityContactRole(false, testOpportunity.Id, testContact.Id, Constants.OPPTY_CONTACT_ROLE_PURCHASE_LEDGER, true);
      lstOppContactRoles.add(testOppContactRole);
      // Competitors
      testCompetitor = Test_Utils.createCompetitor(testOpportunity.Id);    
      testCompetitor.Account__c = testCompetitorAccount.Id;
      testCompetitor.Incumbent__c = true;
      lstCompetitors.add(testCompetitor);
      count++;
    }
    insert lstOppContactRoles;
    insert lstCompetitors;
      
    Test.startTest();      
    
    Sales_Support_Request__c testSSR = new Sales_Support_Request__c(Opportunity__c = testOpportunity.Id, Description__c = 'SSR Pre Sales Request');
    insert testSSR;
      
    Test.stopTest();
	// Competitors. Should be 5.
    i = 0;
    for(Sales_Support_Competitor__c SSC : [select Id, Name from Sales_Support_Competitor__c where Sales_Support_Request__c =: testSSR.Id]) {
      i = i+1;      
    }
    System.assertEquals(5, i);
    // Key Contacts. Should only be 1.
    i = 0;
    for(Sales_Support_Key_Contact__c SSC : [select Id, Name from Sales_Support_Key_Contact__c where Sales_Support_Request__c =: testSSR.Id]) {
      i = i+1;      
    }  
    System.assertEquals(1, i);
  } 
  
  @isTest
  public static void testSetOwnerManager() {
      
	// Create Test Data
	Account testAccount = Test_Utils.insertAccount();
        
    Opportunity testOpportunity = Test_Utils.insertOpportunity(testAccount.Id);      
    Contact testContact = Test_Utils.insertContact(testAccount.Id);
    User testUser = Test_Utils.insertUser(Constants.PROFILE_EXP_SALES_EXEC);
    testUser.ManagerId = UserInfo.getUserId();
    update testUser;
      
    Test.startTest();      
    
    Sales_Support_Request__c testSSR = new Sales_Support_Request__c(Opportunity__c = testOpportunity.Id, Description__c = 'SSR Pre Sales Request', OwnerId = testUser.Id);
    insert testSSR;
      
    Test.stopTest();
	
    for(Sales_Support_Request__c ssr : [select Id, Name, Owner_Manager__c from Sales_Support_Request__c where Id =: testSSR.Id])
    {
      System.assertEquals(ssr.Owner_Manager__c, UserInfo.getUserId());
    }
  }
}