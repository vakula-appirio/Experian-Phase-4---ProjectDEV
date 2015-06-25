/**=====================================================================
 * Appirio, Inc
 * Name: ContactAddressTriggerHandler_Test
 * Description: Test class for ContactAddressTriggerHandler.cls
 * 
 * Created Date: Mar 28th, 2014
 * Created By: Jinesh Goyal (Appirio)
 * 
 * Date Modified        Modified By                 Description of the update
 * Mar 28, 2014         Jinesh Goyal                createNewAccountAddressesTest()
 =====================================================================*/
@isTest (seeAllData=false)
private class ContactAddressTriggerHandler_Test{

    /**
        test method to verify behaviour of ContactAddressTriggerHandler.createNewAccountAddresses method
    */
    static testMethod void createNewAccountAddressesTest() {
       //create 1 account
       Account acc1 = Test_Utils.insertAccount();
       //create 3 addresses
       Address__c address1 = Test_Utils.insertAddress(false);
       address1.Address_id__c = 'testExternalId1';
       Address__c address2 = Test_Utils.insertAddress(false);
       address2.Address_id__c = 'testExternalId2';
       List<Address__c> listAddresses = new List<Address__c>();
       listAddresses.add(address1);
       listAddresses.add(address2);
       insert listAddresses;
       //create 1 account address
       Account_Address__c accAddress1 = Test_Utils.insertAccountAddress(true, address1.Id, acc1.Id);
       //create contact
       Contact contact1 = Test_Utils.insertContact(acc1.Id);
       //create contact address
       Test.startTest();
       Contact_Address__c contactAddress1 = Test_Utils.insertContactAddress(true, address2.Id, contact1.Id);
       //assert
       List<Account_Address__c> listAccountAdd = [SELECT Id, Address__c, Account__c FROM Account_Address__c WHERE Account__c = :acc1.Id];
       Account_Address__c accAddTemp;
       for (Account_Address__c accAdd : listAccountAdd) {
       	 if (accAdd.Id != accAddress1.Id) {
       	   accAddTemp = accAdd;
       	 }
       }
       System.assertEquals(2, listAccountAdd.size());
       System.assertEquals(contactAddress1.Address__c, accAddTemp.Address__c);
       //create second contact
       Contact contact2 = Test_Utils.createContact(acc1.Id);
       contact2.FirstName = 'test contact 2 fn';
       contact2.LastName = 'test contact 2 ln';
       insert contact2;
       Contact_Address__c contactAddress2 = Test_Utils.insertContactAddress(true, address2.Id, contact2.Id);
       listAccountAdd = [SELECT Id, Account__c FROM Account_Address__c WHERE Account__c = :acc1.Id];
       System.assertEquals(2, listAccountAdd.size());
       System.assertEquals(contactAddress1.Address__c, 
                          [SELECT Address__c FROM Contact_Address__c WHERE Id = :contactAddress2.Id].get(0).Address__c);
       Test.stopTest();
    }
}