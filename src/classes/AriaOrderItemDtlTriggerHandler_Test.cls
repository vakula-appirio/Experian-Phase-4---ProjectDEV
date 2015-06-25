/**=====================================================================
 * Appirio, Inc
 * Name: AriaOrderItemDtlTrigger_Test
 * Description: Test for AriaOrderItemDtlTriggerHandler to prevent a Delete if the Order is not in Draft status
  * Created Date: May 27th, 2015
 * Created By: Sadar Yacob (Experian)
 * 
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/

@isTest
private class AriaOrderItemDtlTriggerHandler_Test
{

    static testMethod void runTest()
    {
      User usr = [select id from User where IsActive=true limit 1];

      Test.StartTest();

      //Create Account
      Account testAcc1 = Test_Utils.insertAccount();
      
     //   Account testAcc1 = new Account();   
       // testAcc1.Name = 'Test Account123'; 
       // insert testAcc1;
    
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
      AriaBillAccnt.Push_To_Aria__c = 'Yes';
      AriaBillAccnt.Billing_System_Ref__c = 'TESTING0001';
             
      insert AriaBillAccnt  ; 
     
     ARIA_Product__c AriaProduct = new ARIA_Product__c(Name= 'Test Aria product',Active_Ind__c ='Y',ARIA_Item_ID__c ='1234',Product_SKU__c ='Test Product',
                                                       Product_Name__c='Test Aria Product',CurrencyIsoCode='USD');
                                                       
      insert AriaProduct;
      
      ARIA_Order__c AriaOrdert = new ARIA_Order__c(ARIA_Order_Ref_Number__c = '123',Billing_Account__c=AriaBillAccnt.id,
      Invoice_Template_Name__c='Dutch Tax Exempt Manual Invoice Template',Status__c='Draft');
      
     insert AriaOrdert;
     
     
     
     Aria_Order_Items_Detail__c AriaOrderline = new Aria_Order_Items_Detail__c(ARIA_Order__c = AriaOrdert.id,Quantity__c = 1,Price_Per_Unit__c =5444,Comments__c ='Test',ARIA_Product__c = AriaProduct.id);
     
     insert AriaOrderline ;
     try
     {
         delete AriaOrderline ;
     }
     catch (DmlException e) 
     {
         System.assert( e.getMessage().contains('Only Order Lines in DRAFT status can be deleted!!'),e.getMessage());
         System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , e.getDmlStatusCode(0) );
     }
     try
     {
         delete AriaOrdert; 
     }
     catch (DmlException e) 
     {
         System.assert( e.getMessage().contains('Only Orders in DRAFT status can be deleted'),e.getMessage());
         System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , e.getDmlStatusCode(0) );
     }



   
       Test.stopTest();
    }
    
}