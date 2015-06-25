/**=====================================================================
 * Appirio, Inc
 * Name: AddressMerge_Test
 * Description: To test functionality of Webservice to merge addresses.
 * Created Date: Feb 14th, 2014
 * Created By: Naresh Kr Ojha(Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Feb 27th, 2014               Jinesh Goyal (Appirio)       Fixing test class
 * Mar 04th, 2014               Arpita Bose (Appirio)        T-243282: Added Constants in place of string
 * Aug 14th, 2014               Arpita Bose                  T-308907: Added a test method testMergeAddressWebserviceBis() for the webservice
 * Aug 26th, 27th & 28th, 2014        Arpita Bose                  T-308907: Updated the method testMergeAddressWebserviceBis() as per new task description
 =====================================================================*/
@IsTest
public with sharing class AddressMerge_Test {
private static Address_Merge_Request__c addressMergeRequest;
    static testMethod void test_mergeAddress () {
        createTestData ();
        Map<Id, Address__c> mpIdToAddress = new Map<Id, Address__c>();
        List<Address__c> addressList = [SELECT ID, Authenticated_Address__c, Address_id__c,
                                         (Select Id From Contact_Addresses__r), 
                                         (Select Id From Account_Address__r)  
                                        FROM Address__c];
        for (Address__c address : addressList) {
          mpIdToAddress.put (address.Id, address);
        }
        AddressMerge.performManualMerge ( new List<String> {addressMergeRequest.Id} );
        
        AddressMerge.addressMergeRequest ( addressList[0].Id, addressList[2].Id, Constants.BOOMI, mpIdToAddress);
        AddressMerge.mergeAddressWebserviceManual ( addressList[0].Id, new List<String> {addressList[3].Id}, Constants.MANUAL);
       /*addToMerge.masterId = addressList[0].Id;
       addToMerge.slave1 = addressList[1].Id;
       addToMerge.slave2 = addressList[2].Id;
    
        Set<String> addressIDs = new Set<String>();
        addressIDs.add(addressList[0].Id);
        addressIDs.add(addressList[1].Id);
        addressIDs.add(addressList[2].Id);  

        Boolean checkProcessed = AddressMerge.mergeAddress(addToMerge);
        System.assert(checkProcessed == true);*/
        
        addressList = [SELECT ID, Authenticated_Address__c, 
                         (Select Id From Contact_Addresses__r), 
                         (Select Id From Account_Address__r)  
                       FROM Address__c /*WHERE ID IN: addressIDs*/];
        
        //one Victim record deleted
        System.assertEquals(addressList.size(), 3);
        System.assertEquals(addressList.get(0).Authenticated_Address__c, true);
        
        //Verify if a new Address Merge Request created
        System.assertEquals(2, [SELECT count() FROM Address_Merge_Request__c]);
        
        //Child record reparented to survivor
        System.assert(addressList.get(0).Contact_Addresses__r.size() > 0);
        System.assert(addressList.get(0).Account_Address__r.size() > 0);
      //AddressMerge.mergeAddress(addToMerge);
    }

    // testmethod for T-308907
    static testmethod void testMergeAddressWebservice(){
      // create test data
      Account acc = Test_Utils.insertAccount();
      Contact con = Test_Utils.insertContact(acc.Id);
      Address__c testAdd = Test_Utils.insertAddress(true);
      Address__c master = Test_Utils.insertAddress(true);
      Address__c slave1 = Test_Utils.insertAddress(true);
      Address__c slave2 = Test_Utils.insertAddress(true);
      
      Account_Address__c accAdd1 = new Account_Address__c(Account__c = acc.Id, Address__c = slave1.Id);
      Account_Address__c accAdd2 = new Account_Address__c(Account__c = acc.Id, Address__c = slave2.Id);
      
      List<Account_Address__c> accAddressList = new List<Account_Address__c>();
      accAddressList.add(accAdd1);
      accAddressList.add(accAdd2);
      insert accAddressList;
      
      List<Contact_Address__c> conAddressList = new List<Contact_Address__c>();
      Contact_Address__c conAdd1 = new Contact_Address__c(Contact__c = con.Id, Address__c = slave1.Id);
      Contact_Address__c conAdd2 = new Contact_Address__c(Contact__c = con.Id, Address__c = slave2.Id);
      
      conAddressList.add(conAdd1);
      conAddressList.add(conAdd2);
      insert conAddressList;    
      
      List<String> addressList;
      
      // start test
      Test.startTest();
      String response;
      try {
        response = AddressMerge.mergeAddressWebservice(null, null, null);
      } catch(Exception e){
        system.debug('response>>' +response);
        system.assertEquals(response, null);
      }
      response = AddressMerge.mergeAddressWebservice(null, new List<String> {slave1.Id,slave2.Id}, null);
      system.assertNotEquals(response, null);
      
      accAdd1.Address__c = master.Id;
      update accAdd1;
      
      response = AddressMerge.mergeAddressWebservice(master.Id, new List<String> {slave1.Id}, null);
      system.assertNotEquals(response, null);
      
      conAdd1.Address__c = master.Id;
      update conAdd1;
      
      // stop test
      Test.stopTest();

    }
    
    static void createTestData() {
      Global_Settings__c custSettings = new Global_Settings__c(name = Constants.GLOBAL_SETTING, Smart_Search_Query_Limit__c = 250);
      insert custSettings;
      Account acc = new Account(Name = '00TestAccount0',BillingCountry = 'Sweden');
      insert acc;    
      
      Contact newContact = new Contact(); 
      newContact.FirstName = 'TestContact001';
      newContact.LastName = 'TestLastName001';
      newContact.AccountId = acc.ID;
      insert newContact;
    
      List<Address__c> lstAddrs = new List<Address__c>();
      //Survivor address
      lstAddrs.add(new Address__c(Address_1__c = 'Test Addr1 001', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                    Authenticated_Address__c = true));
      //Victime address
      lstAddrs.add(new Address__c(Address_1__c = 'Test Addr1 002', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                    zip__c = 'test zip', Country__c = 'test country',
                                    Authenticated_Address__c = false));
      //Victime address
      lstAddrs.add(new Address__c(Address_1__c = 'Test Addr1 003', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                    State__c = 'test state', City__c = 'test city',
                                    Authenticated_Address__c = false));
                                    
      lstAddrs.add(new Address__c(Address_1__c = 'Test Addr1 004', Address_2__c = 'Test Addr 0022', Address_3__c = 'Test Addr 003',
                                    State__c = 'test state', City__c = 'test city',
                                    Authenticated_Address__c = false));                                    
      insert lstAddrs;   
   
      List<Account_Address__c> accList = new List<Account_Address__c>();
      List<Contact_Address__c> contList = new List<Contact_Address__c>();
    
      for (Address__c rec : lstAddrs) {
        //Adding child records to victims
        if (rec.Authenticated_Address__c == false) {
             accList.add(new Account_Address__c(Account__c = acc.ID, Address__c = rec.ID));
             contList.add(new Contact_Address__c(Contact__c = newContact.ID, Address__c = rec.ID));
         }
      }
    
      insert contList;
      insert accList;
      //create Address Merge Request
      addressMergeRequest = Test_Utils.insertAddressMergeRequest(false, lstAddrs.get(0).id, lstAddrs.get(1).id);
      addressMergeRequest.Perform_Auto_Merge__c = true;
      addressMergeRequest.Merge_Process_Status__c = Constants.MERGE_PROCESS_STATUS_PENDING;
      insert addressMergeRequest;
    }
}