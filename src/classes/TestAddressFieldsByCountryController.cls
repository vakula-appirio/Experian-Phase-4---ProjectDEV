/*******************************************************************
Name  : TestAddressFieldsByCountryController
Author: Mohammed Irfan
Date  : Nov 11, 2013
 
*************************************************************************/
@isTest
private class TestAddressFieldsByCountryController {

    static testMethod void myUnitTest() {
       
       Address__c addr = new Address__c(Address_1__c='Test Addr1', Address_2__c='Test Addr2',Address_3__c='Test Addr3',
                                        State__c='test state',City__c='test city',zip__c='test zip',Country__c='USA');
       insert addr;

       AddressFieldsByCountryController cnt = new AddressFieldsByCountryController();
        cnt.addressId=addr.id;
        cnt.getAddress(); 
    }

}