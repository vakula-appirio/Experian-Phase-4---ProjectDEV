/**=====================================================================
 * Appirio, Inc
 * Test Class Name: ARIAPlanTriggerHandler_Test
 * Class Name: ARIAPlanTriggerHandler.cls
 * Description: T-280244: To test functionality for related class.
 * Created Date: May 26th, 2014
 * Created By: Naresh Kr Ojha (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest
private class ARIAPlanTriggerHandler_Test {
  private static ARIA_Billing_Account__c ariaBillingAcc;
  private static ARIA_Plan__c ariaPlan;
  static testMethod void ARIAPlanTriggerHandlerTest() {
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);

    System.runAs(testUser) {
    	createTestData();
    	System.assertNotEquals([SELECT ID, SendBillingAccntToAria__c FROM ARIA_Billing_Account__c WHERE ID =:  ariaBillingAcc.ID].SendBillingAccntToAria__c, false);
      Test.startTest();
	      //Updating name, so that trigger will update push to aria.    	
	    	ariaPlan.Plan_Name__c = 'NewTestPlanName';
	    	ariaPlan.Plan_Number__c = '342389732987';
	    	update ariaPlan;
    	Test.stopTest();
    	System.assertEquals([SELECT ID, SendBillingAccntToAria__c FROM ARIA_Billing_Account__c WHERE ID =:  ariaBillingAcc.ID].SendBillingAccntToAria__c, true);
    }
  }
  
  private static void createTestData () {
  	Account testAccount = Test_Utils.insertAccount();
  	Address__c address = Test_Utils.insertAddress(true);
  	Account_Address__c testAccAddress = Test_Utils.insertAccountAddress(true, address.ID, testAccount.ID);

		ariaPlan = new ARIA_Plan__c();
		ariaPlan.Aria_Id__c = '23409349805734';
		ariaPlan.Status__c = 'Active';
		ariaPlan.Plan_Name__c = 'TestAriaPlan';
		insert ariaPlan;

    ariaBillingAcc = new ARIA_Billing_Account__c();
    ariaBillingAcc.Account__c = testAccount.ID;
    ariaBillingAcc.Branch__c = 'Automotive';
    ariaBillingAcc.Billing_Delivery_Method__c = 'PDF Master File';
    ariaBillingAcc.Payment_Method__c = 'Credit Card';
    ariaBillingAcc.Billing_Company_Name__c = 'Test Company';
    ariaBillingAcc.Billing_Address__c = testAccAddress.ID;
    ariaBillingAcc.Billing_Contact_Email__c = 'testemail@ariatest.com';
    ariaBillingAcc.Billing_Contact_Work_Phone__c = '0912942323237';
    ariaBillingAcc.Master_Plan__c = ariaPlan.ID;
    ariaBillingAcc.Push_To_Aria__c = 'Yes';
    insert ariaBillingAcc;
  }
}