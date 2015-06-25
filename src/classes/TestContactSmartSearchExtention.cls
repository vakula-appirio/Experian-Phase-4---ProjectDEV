/**=====================================================================
 * Appirio, Inc
 * Name: TestContactSmartSearchExtention
 * Description: 
 * Created Date: Jul 19th, 2011
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014                   Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014                   Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 =====================================================================*/
@isTest
private class TestContactSmartSearchExtention{
  static Contact contact;
  
  static testMethod void myUnitTest() {
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    System.runAs(testUser) {
    Test.startTest();
      ApexPages.StandardController sc;
      createData();
      ContactSmartSearchExtention controller = new ContactSmartSearchExtention();
      controller.contactFirstNameToSearch = 'test';
      controller.contactLastNameToSearch = 'test';
      controller.contactEmailToSearch = 'test@test.com';
      //controller.accountNameToSearch = 'test';
      
      controller.addressline1ToSearch= 'test';
      controller.addressline2ToSearch= 'test';
      controller.addressline3ToSearch= 'test';
      controller.addressCountryToSearch= 'test';
      controller.addressStateToSearch= 'test';
      controller.addressCityToSearch= 'test';
      controller.addressPostalCodeToSearch= 'test';
      
      controller.performSearch(); 
      controller.performSearch(); 
      
      controller.requestedPage = '1';
      controller.requestedAddrPage = '1';
      /*
      System.assert(55<=controller.searchCount);
      System.assertEquals(1,controller.showingFrom);
      System.assertEquals(20,controller.showingTo);
      System.assertEquals(3,controller.totalPage);
      System.assertEquals(true,controller.hasNext);
      System.assertEquals(false,controller.hasPrevious);
      */
      controller.nextContactPage();
      controller.nextAddressPage();
      /*
      System.assertEquals(21,controller.showingFrom);
      System.assertEquals(40,controller.showingTo);
      System.assertEquals(3,controller.totalPage);
      System.assertEquals(true,controller.hasNext);
      System.assertEquals(true,controller.hasPrevious);
      */
      controller.previousContactPage();
      controller.previousAddressPage();
       
      
      controller.requestedPage = '3';
      controller.requestedContactPage();
      controller.requestedAddressPage();
      controller.resetSearchStatus();

      /*
      System.assertEquals(41,controller.showingFrom);
      System.assertEquals(55,controller.showingTo);
      System.assertEquals(3,controller.totalPage);
      System.assertEquals(false,controller.hasNext);
      System.assertEquals(true,controller.hasPrevious);
      */
      
      controller.sortData();
      controller.cancel();
      
      controller.requestedPage = '5';
      controller.requestedContactPage();
      
      //controller.ContactNameToSearch = 'qeeqeq#@@#';
      controller.performSearch();
      Test.stopTest();
    }
  }
  
  static testMethod void myUnitTest2() {
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
    System.runAs(testUser) {
    Test.startTest();
      CreateData();
      ApexPages.StandardController sc = new Apexpages.Standardcontroller(contact);
      ContactSmartSearchExtention controller = new ContactSmartSearchExtention(sc);
      controller.contactFirstNameToSearch = 'firstname';
      controller.contactLastNameToSearch = 'test';
      controller.contactEmailToSearch = 'test@test.com';
      controller.accountNameToSearch = 'test';
      controller.performSearch();
      system.assert(controller.contactResults != null );
    }
  }
  
  static void CreateData() {
    Global_Settings__c custSettings = new Global_Settings__c(name=Constants.GLOBAL_SETTING,Smart_Search_Query_Limit__c=250);
    insert custSettings;
    Account account = Test_Utils.insertAccount();
    contact = Test_Utils.insertContact(account.Id); 
    
    list<Address__c> lstAddrs= new list<Address__c>();

    for(Integer i=0;i<550;i++) {
      lstAddrs.add(new Address__c(Address_1__c='Test Addr ' + String.valueOf(Math.random()) + ' ' + i, 
                                  Address_2__c='Test Addr2 ' + String.valueOf(Math.random()),
                                  Address_3__c='Test Addr3 ' + String.valueOf(Math.random()),
                                  State__c='test state ' + String.valueOf(Math.random()),
                                  City__c='test city ' + String.valueOf(Math.random()),
                                  zip__c='test zip ' + String.valueOf(Math.random()),
                                  Country__c='test country ' + String.valueOf(Math.random()),
                                  EDQ_Integration_Id__c = 'E:' + i,
                                  Prod_Id__c = 'P:' + i));
    }

    insert lstAddrs;

    list<Contact_Address__c> lstContactList = new list<Contact_Address__c>();
    for(Address__c rec:lstAddrs){
      lstContactList.add(Test_Utils.insertContactAddress(false, rec.id, contact.Id));
    }

    insert lstContactList;
  }
}