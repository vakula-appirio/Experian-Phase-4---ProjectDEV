/**========================================================================================
 * Appirio, Inc
 * Name: URLRedirectController_Test
 * Description: This class contains test method to test URLRedirectController
 * Created Date: March 13th, 2014
 * Created By: Nathalie LE GUAY (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jul 28th, 2014				James Weatherall			 Case #2323 Added testOppFromOpportunity() method
 * Feb 26th, 2015				James Weatherall			 Case #9748 Added testPreSalesRequestFromOpportunity() method
 ========================================================================================*/
@isTest(seeAllData = true)
private class URLRedirectController_Test {

  static testMethod void testOppFromContact() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOpportunity');
    pageRef.getParameters().put('Id', cont.Id);

    Test.StartTest();
    Test.setCurrentPage(pageRef);
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }

  static testMethod void testOppFromOpportunity() {
    Account acc = Test_Utils.insertAccount();
    Contact con = Test_Utils.insertContact(acc.Id);
    Opportunity opp = Test_Utils.insertOpportunity(acc.Id);
    Test_Utils.insertOpportunityCR(true, con.Id, opp.Id);
	System.debug('opp.Id = ' + opp.Id);
    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOpportunity');
    pageRef.getParameters().put('Name', opp.Name);
    pageRef.getParameters().put('Id', opp.Id);

    Test.StartTest();
    Test.setCurrentPage(pageRef);
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }
    
  static testMethod void testOppFromEvent() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);
    Event evt = Test_Utils.insertEvent(cont.Id, null);

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOpportunity');
    pageRef.getParameters().put('Id', evt.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }

  static testMethod void testOppFromEventLinkedToLead() {
    Lead lead = Test_Utils.insertLead();
    Event evt = Test_Utils.insertEvent(lead.Id, null);

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOpportunity');
    pageRef.getParameters().put('Id', evt.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    ApexPages.Message[] messages = ApexPages.getMessages();
    System.assertNotEquals(0, messages.size());
    System.assertEquals(Label.URL_Redirect_Missing_Contact, messages.get(0).getSummary());
    Test.StopTest();
  }

  static testMethod void testOppFromTask() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);
    Task task = Test_Utils.insertTask(cont.Id, null);

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOpportunity');
    pageRef.getParameters().put('Id', task.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }

  static testMethod void testOppFromMarketingActivity() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);
    ELQA_Marketing_Activity__c mktgActivity = new ELQA_Marketing_Activity__c(Account__c = acc.Id, Contact__c = cont.Id);
    insert mktgActivity;

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOpportunity');
    pageRef.getParameters().put('Id', mktgActivity.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }

    static testMethod void testOppFromMarketingActivityMissingContact() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);
    ELQA_Marketing_Activity__c mktgActivity = new ELQA_Marketing_Activity__c(Account__c = acc.Id);
    insert mktgActivity;

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOpportunity');
    pageRef.getParameters().put('Id', mktgActivity.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    ApexPages.Message[] messages = ApexPages.getMessages();
    System.assertNotEquals(0, messages.size());
    System.assertEquals(Label.URL_Redirect_Missing_Contact_or_Account, messages.get(0).getSummary());
    Test.StopTest();
  }

  static testMethod void testOrderFromContact() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOrder');
    pageRef.getParameters().put('Id', cont.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }

  static testMethod void testOrderFromEvent() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);
    Event evt = Test_Utils.insertEvent(cont.Id, null);

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOrder');
    pageRef.getParameters().put('Id', evt.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }

  static testMethod void testOrderFromTask() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);
    Task task = Test_Utils.insertTask(cont.Id, null);

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOrder');
    pageRef.getParameters().put('Id', task.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }

  static testMethod void testOrderFromTaskLinkedToLead() {
    Lead lead = Test_Utils.insertLead();
    Task task = Test_Utils.insertTask(lead.Id, null);

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOrder');
    pageRef.getParameters().put('Id', task.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    ApexPages.Message[] messages = ApexPages.getMessages();
    System.assertNotEquals(0, messages.size());
    System.assertEquals(Label.URL_Redirect_Missing_Contact, messages.get(0).getSummary());
    Test.StopTest();
  }

  static testMethod void testOrderFromMarketingActivity() {
    Account acc = Test_Utils.insertAccount();
    Contact cont = Test_Utils.insertContact(acc.Id);
    ELQA_Marketing_Activity__c mktgActivity = new ELQA_Marketing_Activity__c(Account__c = acc.Id, Contact__c = cont.Id);
    insert mktgActivity;

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOrder');
    pageRef.getParameters().put('Id', mktgActivity.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    System.assertEquals(0, ApexPages.getMessages().size());
    Test.StopTest();
  }

  static testMethod void testOrderFromUnsupportedObject() {
    Lead lead = Test_Utils.insertLead();

    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createOpportunity');
    pageRef.getParameters().put('Id', lead.Id);
    Test.setCurrentPage(pageRef);

    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    ApexPages.Message[] messages = ApexPages.getMessages();
    System.assertNotEquals(0, messages.size());
    System.assertEquals(Label.URL_Redirect_Opp_From_Object_Not_Supported, messages.get(0).getSummary());
    Test.StopTest();
  }
    
  static testMethod void testPreSalesRequestFromOpportunity() {
    Account account = Test_Utils.insertAccount();
    Opportunity opportunity = Test_Utils.insertOpportunity(account.Id);
      
    PageReference pageRef = Page.URLRedirect;
    pageRef.getParameters().put('action', 'createPreSalesSupport');
    pageRef.getParameters().put('Id', opportunity.Id);
    Test.setCurrentPage(pageRef);
    
    Test.StartTest();
    URLRedirectController urlRedirect = new URLRedirectController();
    urlRedirect.getURL();
    ApexPages.Message[] messages = ApexPages.getMessages();
    System.assertEquals(0, messages.size());
    Test.StopTest();      
  }
}