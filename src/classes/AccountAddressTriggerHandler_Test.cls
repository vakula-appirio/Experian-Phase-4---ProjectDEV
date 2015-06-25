/**=====================================================================
 * Appirio, Inc
 * Name: AccountAddressTriggerHandler_Test
 * Description: T-324658: Test Class for AccountAddressTriggerHandler.cls
 * Created Date: Oct 08th, 2014
 * Created By    : Arpita Bose (Appirio)
 * 
 * Date Modified      Modified By                  Description of the update
 * Dec 30th, 2014     Arpita Bose                  Updated methods testSyncContactRec_OnDemand1() and testSyncContactRec_OnDemand2()to fix failure
 ======================================================================**/
 @isTest
 public class AccountAddressTriggerHandler_Test {
    
    // Scenario 1: for insert of Account Address with Address_Type__c = 'Registered'
    @isTest
    public static void testSyncContactRec_OnDemand1(){
      // create test data
      Account acc = Test_Utils.insertAccount();
      Contact con = new Contact (FirstName = 'Larry', LastName = 'Ellison', Title = 'Mr', //Inactive__c = false,
                                 AccountId = acc.Id, Email = 'larrye@email.com', EDQ_On_Demand__c = true,
                                 Phone = '9799559433', EDQ_Integration_Id__c = 'TestIds123');
      insert con;

      Address__c addrs1 = Test_Utils.insertAddress(true);
      
      Test.startTest();
      //insert account address
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(true, addrs1.Id, acc.Id);
      
      Test.stopTest();
      Contact testCon = [SELECT Id, EDQ_Send_to_On_Demand__c FROM Contact WHERE Id =: con.Id AND AccountId = :acc.Id];
      //Assert to verify EDQ_Send_to_On_Demand__c = true
      System.assertEquals(testCon.EDQ_Send_to_On_Demand__c, true);
    }

    // Scenario 2: for update of Account Address with Address_Type__c = 'Registered'
    @isTest
    public static void testSyncContactRec_OnDemand2(){
      // create test data
      Account acc = Test_Utils.insertAccount();
      Contact con = new Contact (FirstName = 'Larry', LastName = 'Ellison', Title = 'Mr', //Inactive__c = false,
                                 AccountId = acc.Id, Email = 'larrye@email.com', EDQ_On_Demand__c = true,
                                 Phone = '9799559433', EDQ_Integration_Id__c = 'TestIds123');
      insert con;

      Address__c addrs1 = Test_Utils.insertAddress(true);
      
      // start test
      Test.startTest();
      //insert account address with Address_Type__c = 'Secondary'
      Account_Address__c accAddrs = Test_Utils.insertAccountAddress(false, addrs1.Id, acc.Id);
      accAddrs.Address_Type__c = Constants.ADDRESS_TYPE_SECONDARY;
      insert accAddrs;
      
      //Assert to verify EDQ_Send_to_On_Demand__c = false
      Contact testCon = [SELECT Id, EDQ_Send_to_On_Demand__c FROM Contact WHERE Id =: con.Id AND AccountId = :acc.Id];
      System.assertEquals(con.EDQ_Send_to_On_Demand__c, false);
      
      // update Address_Type__c = 'Registered' 
      accAddrs.Address_Type__c = Constants.ADDRESS_TYPE_REGISTERED;
      update accAddrs;      
      
      testCon = [SELECT Id, EDQ_Send_to_On_Demand__c FROM Contact WHERE Id =: con.Id AND AccountId = :acc.Id];
      
      //Assert to verify EDQ_Send_to_On_Demand__c = true
      System.assertEquals(testCon.EDQ_Send_to_On_Demand__c, true);
      
      // update Address_Type__c = 'Secondary' 
      accAddrs.Address_Type__c = Constants.ADDRESS_TYPE_SECONDARY;
      update accAddrs;
      
      Contact testCon1 = [SELECT Id, EDQ_Send_to_On_Demand__c FROM Contact WHERE Id =: con.Id AND AccountId = :acc.Id];
      //Assert to verify EDQ_Send_to_On_Demand__c = true
      System.assertEquals(testCon1.EDQ_Send_to_On_Demand__c, true);

      Test.stopTest();
      
    }

}