/*=======================================================================================================================
 * Appirio, Inc
 * Name: AddressTriggerHandler_Test
 * Description: Test class for Address Trigger
                
 * Created Date: Apr 22nd, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Oct 15, 2014                 Pallavi Sharma               T-325153 : Unit test coverage for updation in Handler
 * Oct 22, 2014                 Nathalie Le Guay (Appirio)   I-135920: remove references to Account_Address__c.EDQ_Integration_Id__c
 * Oct 30th, 2014               Pallavi Sharma               Fix Failures 
 * Dec 19th, 2014               Arpita Bose                  Updated test_syncContactOnDemand() to populate contact.Phone for OnDemand Decider contact                
 =========================================================================================================================*/
 @isTest(seeAllData=false) 
 private class AddressTriggerHandler_Test {
    
    static testmethod void testSendBillingAccntToAria() 
    {
        User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
      System.runAs(testUser) {
          Account testAcc = Test_Utils.insertAccount();
          
          Map<ID, ARIA_Billing_Account__c> ARIABillingAccountMap = new Map<ID, ARIA_Billing_Account__c>();
          Map<ID, Account_Address__c> AccountAddressMap = new Map<ID, Account_Address__c>();
          List<Address__c> addrsLst = new List<Address__c>();
           Address__c addrs1 = new Address__c(Address_1__c = 'Test Addr1 001', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                        Authenticated_Address__c = true);
           Address__c addrs2 = new Address__c(Address_1__c = 'Test Addr1 002', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                        zip__c = 'test zip', Country__c = 'test country',
                                        Authenticated_Address__c = false);
           Address__c addrs3 = new Address__c(Address_1__c = 'Test Addr1 002', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                        zip__c = 'test zip', Country__c = 'test country',
                                        Authenticated_Address__c = false);
           Address__c addrs4 = new Address__c(Address_1__c = 'Test Addr1 002', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                        zip__c = 'test zip', Country__c = 'test country',
                                        Authenticated_Address__c = false);
           addrsLst.add(addrs1);  
           addrsLst.add(addrs2);
           addrsLst.add(addrs3);
           addrsLst.add(addrs4);                                 
         insert addrsLst; 
         
        List<Account_Address__c> accList = new List<Account_Address__c>();
           
        for (Address__c rec : addrsLst) {
            if (rec.Authenticated_Address__c == false) {
                accList.add(new Account_Address__c(Account__c = testAcc.ID, Address__c = rec.ID, Address_Type__c ='Registered',Boomi__c =rec.ID));
            }
        }
        insert accList;
        
        ARIA_Billing_Account__c aria = new ARIA_Billing_Account__c();
        aria.Account__c = testAcc.Id;
        aria.Push_To_Aria__c = Constants.PICKLISTVAL_YES;
        aria.SendBillingAccntToAria__c = false;
        aria.Billing_Address__c =accList.get(0).Id; //added 06/10/14 
        insert aria;
        
        Test.startTest();
        addrsLst.get(0).City__c = 'TestCity'; 
        addrsLst.get(1).Country__c = 'Test_Country';
        update addrsLst; 
        
        List<Account_Address__c> accAddrsList = [SELECT Address__c, Id, Boomi__c,
                                                 (SELECT Id, Push_To_Aria__c, SendBillingAccntToAria__c 
                                                  FROM ARIA_Billing_Accounts__r 
                                                  WHERE Push_To_Aria__c =: Constants.PICKLISTVAL_YES) 
                                                  FROM Account_Address__c
                                                  WHERE Address__c IN :addrsLst];                                               
        
        system.assert(accAddrsList.get(0).Boomi__c != null);
                                                             
        List<ARIA_Billing_Account__c> ariaRslt = [SELECT ID, Push_To_Aria__c, SendBillingAccntToAria__c FROM ARIA_Billing_Account__c
                                           WHERE Id = :aria.Id AND Push_To_Aria__c =: Constants.PICKLISTVAL_YES ];    
                                           
                                                                                                       
        Test.stopTest();                   
        System.debug('DBG:Aria Billing Accnt Id:' + ariaRslt.get(0).Id +' Send Flag:' + ariaRslt.get(0).SendBillingAccntToAria__c );
                                                       
        system.assert(ariaRslt.get(0).SendBillingAccntToAria__c, true);  
    }                                        
  }
    
  //Test Method for unit test coverage of Method syncContactOnDemand
  static testmethod void test_syncContactOnDemand() {
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    System.runAs(testUser) {
      //Create Bulk Account
      Account account ;
      List<Account> lstAccountToInsert = new List<Account>(); 
      for (Integer i = 1; i <= 120; i++) {
        account = Test_Utils.insertEDQAccount(false);
        account.EDQ_Integration_Id__c = i + '';
        lstAccountToInsert.add(account);
      }
      insert lstAccountToInsert;
      
      //Create Bulk Contact
      Contact contact; 
      List<Contact> lstContactToInsert = new List<Contact>(); 
      for (Integer i = 0; i < 120; i++) {
        contact = Test_Utils.createContact(lstAccountToInsert.get(i).Id);
        contact.Title = 'test title';
        contact.EDQ_On_Demand__c = true;
        contact.EDQ_Integration_Id__c = 'abcdefghij' + i;
        contact.Experian_ID__c = '' + i;
        contact.Phone = '9799559433';
        //Commented as per issue: I:139165 to delete field Prod_Id__c. nojha on Nov 18th, 2014.
        //contact.Prod_Id__c = '' + i;
        lstContactToInsert.add(contact);
      }
      insert lstContactToInsert;
      
      //Creating bulk address
      Address__c address;
      List<Address__c> lstAddressToInsert = new List<Address__c>(); 
      for (Integer i = 1; i <= 120; i++) {
        address = Test_Utils.insertAddress(false);
        address.EDQ_Integration_Id__c = '' + i;
        lstAddressToInsert.add(address);
      }
      insert lstAddressToInsert;
      
      //Creating bulk Account Address
      Account_Address__c accountAddress;
      List<Account_Address__c> lstAccountAddressToInsert = new List<Account_Address__c>(); 
      for (Integer i = 0; i < 120; i++) {
        accountAddress = Test_Utils.insertAccountAddress(false, lstAddressToInsert.get(i).Id, lstAccountToInsert.get(i).Id);
        // accountAddress.EDQ_Integration_Id__c = '' + i; I-135920
        lstAccountAddressToInsert.add(accountAddress);
      }
      insert lstAccountAddressToInsert;
      
      //Set EDQ_Send_to_On_Demand__c to false
      for (Contact con : lstContactToInsert) {
        con.EDQ_Send_to_On_Demand__c = false;
      }
      update lstContactToInsert; 
      
      Test.startTest();
      //Update Address
      for (Address__c addr : lstAddressToInsert) {
        addr.County__c = 'London';
      }
      update lstAddressToInsert;
      Test.stopTest();
      
      //Asserting Contact for EDQ_Send_to_On_Demand__c change
      system.assertEquals(120, [SELECT Id FROM Contact WHERE EDQ_Send_to_On_Demand__c = true AND EDQ_Integration_Id__c like 'abcdefghij%'].size());
      
    }
  }
 

}