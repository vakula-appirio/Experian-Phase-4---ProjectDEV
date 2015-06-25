/**=====================================================================
 * Appirio, Inc
 * Name: AccountSmartSearchExtension_Test
 * Description: Test class for AccountSmartSearchExtention
 * Created Date: Jul 19th, 2011
 * Created By: Urminder Vohra (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014               Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014               Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 * Mar 13th, 2014               Arpita Bose(Appirio)         T-253906: Modified class name from TestAccountSmartSearchExtention
 *                                                           to AccountSmartSearchExtension_Test
 * Mar 20th, 2014               Arpita Bose(Appirio)         T-253906: Added test method to test the functionality of
 *                                                           SmartSearchRecordVisibility.cls
 * Apr 29th, 2014               Arpita Bose                  T-275717: Added Asserts to fix Force.com Security Scanner Results
 * Feb 19th, 2015               Paul Kissick                 Case #22017 - Fixed test asserts as they were incorrect.                                                
 * Apr 7th, 2015				Suminder Singh(Appirio)		 T-375346: Fixed test class for better unit testing
 =====================================================================*/
@isTest(seeAllData = false)
private class AccountSmartSearchExtension_Test {
    static testMethod void myUnitTest() {
        ApexPages.StandardController sc;
        createData();
        AccountSmartSearchExtention controller = new AccountSmartSearchExtention(sc);
        controller.accountNameToSeaarch = 'test';

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
        //Asserts
        System.assert(55<=controller.searchCount);
        System.assertEquals(1,controller.showingFrom);
        System.assertEquals(20,controller.showingTo);
        // System.assertEquals(25,controller.totalPage); // HOW IS THIS POSSIBLE WHEN THERE ARE 20 PER PAGE AND 250 MAXIMUM RETURNED!!!
        System.assertEquals(13,controller.totalPage); // PK Case #22017 - This number is correct!
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(false,controller.hasPrevious);

        controller.nextAccountPage();
        controller.nextAddressPage();
        //Asserts
        System.assertEquals(21,controller.showingFrom);
        System.assertEquals(40,controller.showingTo);
        //System.assertEquals(25,controller.totalPage);
        System.assertEquals(13,controller.totalPage); // PK Case #22017 - This number is correct!
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);

        controller.previousAccountPage();
        controller.previousAddressPage();


        controller.requestedPage = '3';
        controller.requestedAccountPage();

        controller.requestedAddressPage();
        controller.resetSearchStatus();

        //Asserts
        System.assertEquals(41,controller.showingFrom);
        System.assertEquals(60,controller.showingTo);
        //System.assertEquals(25,controller.totalPage);
        System.assertEquals(13,controller.totalPage); // PK Case #22017 - This number is correct!
        System.assertEquals(false,controller.hasNext);
        System.assertEquals(false,controller.hasPrevious);


        controller.sortData();
        controller.cancel();

        controller.requestedPage = '5';
        controller.requestedAccountPage();


        controller.accountNameToSearch = 'qeeqeq#@@#';
        controller.performSearch();

    }

    static testmethod void testSmartSearchRecordVisibility(){
      Account testAcc1 = Test_Utils.insertAccount();
      Account testAcc2 = Test_Utils.insertAccount();
      Account testAcc3 = Test_Utils.insertAccount();

      Set<Id> testAccs= new Set<Id>();
           testAccs.add(testAcc1.Id);
           testAccs.add(testAcc2.Id);
           testAccs.add(testAcc3.Id);

      Contact testcon1 = Test_Utils.insertContact(testAcc1.Id);
      Contact testcon2 = Test_Utils.insertContact(testAcc2.Id);
      Contact testcon3 = Test_Utils.insertContact(testAcc3.Id);

      Set<Id> conSet = new Set<Id>();
      conSet.add(testcon1.Id);
      conSet.add(testcon2.Id);
      conSet.add(testcon3.Id);

      //SmartSearchRecordVisibility ssrv = new SmartSearchRecordVisibility();
      String ssAccount = SmartSearchRecordVisibility.getUserAccessibleAccounts(testAccs);
      String ssContact = SmartSearchRecordVisibility.getUserAccessibleContacts(conSet);
      List<Account> acc =[select id from Account where id IN :testAccs];
      List<Contact> con =[select id from Contact where id IN :conSet];
      //Asserts
      system.assert(acc.size() > 0);
      system.assert(con.size() > 0);
      system.assertEquals(ssAccount!= null, true);
      system.assertEquals(ssContact!= null, true);


    }

    static void CreateData() {
        Global_Settings__c custSettings = new Global_Settings__c(name= Constants.GLOBAL_SETTING, Smart_Search_Query_Limit__c = 250);
        insert custSettings;

       Account acc = new Account(Name = '00TestAccount0',BillingCountry = 'Sweden');
       insert acc;

       list<Address__c> lstAddrs= new list<Address__c>();

       for(Integer i=0; i < 550; i++) {
         lstAddrs.add(new Address__c(Address_1__c='Test Addr1'+i, Address_2__c='Test Addr2',Address_3__c='Test Addr3',
                                        State__c='test state',City__c='test city',zip__c='test zip',Country__c='test country',
                                        EDQ_Integration_Id__c = String.valueOf(Math.random())));
       }
       insert lstAddrs;

       list<Account_Address__c> accList = new list<Account_Address__c>();
       for(Address__c rec : lstAddrs){
           accList.add(new Account_Address__c(Account__c = acc.id, Address__c = rec.id));
       }
       insert accList;
    }
}