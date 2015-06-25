/**********************************************************************************
 * Appirio, Inc
 * Name: BatchAccountSubCode_Test
 * Description: S-292550 - Population of CSDA Company Id, T-366637
 * Created Date: Mar 7th, 2015
 * Created By: Terri Kellough (Appirio)
 *
 * Summary:
 * - This is the test class for BatchAccountSubCode
 *
 *
 * Date Modified                Modified By                  Description of the update
 * Mar 9th, 2015        Terri Kellough         fixed test_AccountNoSubCodes() and test_AccountOneSubCode()
 **********************************************************************************/

@isTest
private class BatchAccountSubCode_Test {


    /***************************************************************************
     * (1). test_AccountNoSubCodes():                                          *
     *    Test Accounts with no sub codes will have null CSDA Company Ids      *
     *    will continue to have no CSDA Company Ids after batch update         *
     ***************************************************************************/
    static testMethod void test_AccountNoSubCodes() {
      User testUser = [Select Id From User Limit 1];

      System.runAs(testUser) {

        List<Account> acc = [Select Id, Name, CSDA_Company_Id__c From Account where CSDA_Company_Id__c = null];

        Test.StartTest();
        BatchAccountSubCode accSC = new BatchAccountSubCode();
        ID batchedprocessid = Database.executeBatch(accSC);
        Test.stopTest();

        List<Account> insAcc = [Select Id, Name, CSDA_Company_Id__c From Account Where Id In:acc AND CSDA_Company_Id__c = null];

        System.assertEquals(acc.size(), insAcc.size(), 'It is expected the accounts will have a null CSDA Company Id');


      }
    }

     /***************************************************************************
     * (2). test_AccountAddedOneSubCode():                                           *
     *    Accounts with initially no sub codes have one sub code added          *
     *    after running the batch job, the account's CSDA Company Id            *
     *    should be updated with it's single sub code's company Id              *
     ****************************************************************************/
    static testMethod void test_AccountAddedOneSubCode() {
      User testUser = [Select Id From User Limit 1];
      System.runAs(testUser) {

        String companyId = '4567';
        List<Account> acc = [Select Id, Name, CSDA_Company_Id__c From Account Where CSDA_Company_Id__c = null];

        List<Sub_Code__c> sc = new List<Sub_Code__c>();
        for (Integer i = 0; i < 100; i++) {
          Sub_Code__c s = new Sub_Code__c(Account__c = acc[i].Id, Company_Id__c = companyId, Subscriber_Code__c = i+'');
          sc.add(s);
        }
        insert sc;

        // Company Id should be 4567
        Test.StartTest();
        BatchAccountSubCode accSC = new BatchAccountSubCode();
        ID batchedprocessid = Database.executeBatch(accSC);
        Test.stopTest();

        List<Account> insAcc = [Select Name, CSDA_Company_Id__c From Account Where Id In:acc and CSDA_Company_Id__c =:companyId];
        List<Sub_Code__c> insSc = [Select Name, Company_Id__c From Sub_Code__c Where Id In:sc and Company_Id__c =: companyId];

         System.assertEquals(insSc.size(), insAcc.size(), 'Company Id should be ' + companyId);
      }
    }


     /***************************************************************************
     * (3). test_AccountAddedTwoSubCode():                                      *
     *    Accounts with initially with one sub codes has another sub code added *
     *    after running the batch job, the account's CSDA Company Id            *
     *    should be updated with it's most recent sub code's company Id         *
     ****************************************************************************/
    static testMethod void test_AccountAddedTwoSubCode() {
      User testUser = [Select Id From User Limit 1];
      System.runAs(testUser) {
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);

        String companyId = '1234';
        List<Account> acc = [Select Id, Name, CSDA_Company_Id__c From Account Where CSDA_Company_Id__c =: companyId];


        List<Sub_Code__c> sc = new List<Sub_Code__c>();
        for (integer i = 0; i < 100; i++) {
          Sub_Code__c s = new Sub_Code__c(Account__c = acc[i].Id, Company_Id__c = companyId, Subscriber_Code__c = i+'');
          sc.add(s);
        }
        insert sc;

        List<Account> insAcc = [Select Name, CSDA_Company_Id__c From Account Where Id In:acc and CSDA_Company_Id__c =:companyId];
        List<Sub_Code__c> insSc = [Select Name, Company_Id__c From Sub_Code__c Where Id In:sc and Company_Id__c =: companyId];

        System.assertEquals(insSc.size(), insAcc.size(), 'Company Id should be ' + companyId);

        //Add 2 subcode where company id = '5678'
        companyId = '5678';

        List<Sub_Code__c> sc2 = new List<Sub_Code__c>();
        for(integer i = 0; i<100; i++){
          Sub_Code__c s = new Sub_Code__c(Account__c = acc[i].Id, Company_Id__c = companyId, Subscriber_Code__c = '0'+i+'0'+i);
          sc2.add(s);
        }
        insert sc2;

        Test.StartTest();
        BatchAccountSubCode accSC2 = new BatchAccountSubCode();
        ID batchedprocessid1 = Database.executeBatch(accSC2);
        Test.stopTest();

        List<Account> insAcc2 = [Select Id, Name, CSDA_Company_Id__c From Account Where Id In:acc and CSDA_Company_Id__c =:companyId];
        List<Sub_Code__c> insSc3 = [Select Id, Name, Company_Id__c From Sub_Code__c Where Id In:sc2 and Company_Id__c =: companyId];

         System.assertEquals(insSc3.size(), insAcc2.size(), 'Company Id matches second subcodes\' company id of ' + companyId);
      }
    }


    /*****************************************************************************
     * (4). test_AccountRemovedSubCode():                                        *
     *    Accounts with initially with one sub codes has sub codes removed       *
     *    after running the batch job, the account's CSDA Company Id             *
     *    should be updated to null                                              *
     ****************************************************************************/
    static testMethod void test_AccountRemovedSubCode() {
      User testUser = [Select Id From User Limit 1];
      System.runAs(testUser) {
        String companyId = '1234';

        List<Account> acc = [Select Id, Name, CSDA_Company_Id__c From Account Where CSDA_Company_Id__c =: companyId];
        List<Sub_Code__c> sc = new List<Sub_Code__c>();
        for (integer i = 0; i < 100; i++) {
          Sub_Code__c s = new Sub_Code__c(Account__c = acc[i].Id, Company_Id__c = companyId, Subscriber_Code__c = i+'');
          System.Debug('Sub_Code__c ' + s);
          sc.add(s);
        }
        insert sc;

        //Acount's company id should initially be 1234
        //Test.StartTest();
        //BatchAccountSubCode accSC = new BatchAccountSubCode();
        //ID batchedprocessid = Database.executeBatch(accSC);

        List<Account> insAcc = [Select Id, Name, CSDA_Company_Id__c From Account Where Id In:acc and CSDA_Company_Id__c =:companyId];
        List<Sub_Code__c> insSc = [Select Id, Name, Company_Id__c From Sub_Code__c Where Id In:sc and Company_Id__c =:companyId];
        //System.Debug('======= insAcc.get(0).CSDA_CompanyId__c ' + insAcc.get(0).CSDA_Company_Id__c);

        System.assertEquals(insSc.size(), insAcc.size(), 'Company Id should be ' + companyId);


         //Account's company id should be null after removing sub code
        delete insSc;

        Test.StartTest();
        BatchAccountSubCode accSC2 = new BatchAccountSubCode();
        ID batchedprocessid2 = Database.executeBatch(accSC2);
        Test.stopTest();

        List<Account> insAcc2 = [Select Id, Name, CSDA_Company_Id__c From Account Where Id In:acc and CSDA_Company_Id__c = null];

        System.assertEquals(acc.size(), insAcc2.size(), 'Company Id should be null');

      }

    }

  @testSetup
  static void setupTestData() {
        User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);
        TriggerSettings__c insertTriggerSettings = Test_Utils.insertTriggerSettings(Constants.ACCOUNT_TRIGGER);
        IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);

        List <Account> accNoSub = new List<Account>();
        for (integer i = 0; i < 100; i++) {
          Account a = Test_Utils.createAccount();
          a.CSDA_Company_Id__c = null;
          accNoSub.add(a);
        }
        insert accNoSub;


        List <Account> accWithSub = new List<Account>();
        for (integer i = 0; i < 100; i++) {
          Account a = Test_Utils.createAccount();
          a.CSDA_Company_Id__c = '1234';
          accWithSub.add(a);
        }
        insert accWithSub;
        //String CompanyId = '1234';

    }
}