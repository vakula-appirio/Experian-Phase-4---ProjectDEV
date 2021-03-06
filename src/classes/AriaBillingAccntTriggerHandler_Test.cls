/**=====================================================================
 * Appirio, Inc
 * Name: AriaBillingAccntTriggerHandler_Test
 * Description: Test for Billing Account Trigger to update a flag on the Address object when an Account Address is used on a ARIA Billing Account
 * Created Date: March 28th, 2014
 * Created By: Sadar Yacob (Experian)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/

@isTest
private class AriaBillingAccntTriggerHandler_Test{

    static testMethod void runTest()
    {
      User usr = [select id from User where IsActive=true limit 1];

      //Create Account
      Account testAcc1 = Test_Utils.insertAccount();
    
    //Create address
     Address__c addr1 = new Address__c(Address_1__c = 'Test Addr1 001', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                                Country__c = 'Australia',Authenticated_Address__c = true);
      insert addr1;   

      //Create AccountAddress
      Account_Address__c accntAddr1 = new Account_Address__c(Account__c = testAcc1.ID, Address__c = addr1.ID);

      insert accntAddr1;

      //create the ARIA Billing Account
      ARIA_Billing_Account__c AriaBillAccnt  = new ARIA_Billing_Account__c(Account__c = testAcc1.Id, Billing_Account_Name__c = testAcc1.Name + '123',
                                      Billing_Company_Name__c = testAcc1.Name,Owner__c= usr.id,Billing_Delivery_Method__c ='PDF Master File',
                                      Billing_Contact_Last_Name__c ='Test',Billing_Contact_First_Name__c='Contact',Billing_Contact_Email__c='test@email.com',
                                      Billing_Contact_Work_Phone__c='1234 5678 1234',Payment_Method__c='',Billing_Enquiries_Contact__c='Arjan vd Akker, 0704404459'
                                    , Billing_Address__c =accntAddr1.Id );
                                      
      AriaBillAccnt.Billing_Account_Country__c  = 'USA';
      AriaBillAccnt.Business_ID_Number__c = '1232313213';
      AriaBillAccnt.Business_ID_Type__c = 'ABN';
      
      insert AriaBillAccnt  ;
    }
}