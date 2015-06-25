/**=====================================================================
 * Appirio, Inc
 * Name: BatchAccountType_Test
 * Description: T-286028: Test class to verify the behaviour of BatchAccountType.cls
 * Created Date: Aug 01st, 2014
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified         Modified By          Description of the update
 * Feb 16th, 2015        Noopur               T-360546 : modified the class to add the new features related to @testSetup
 =====================================================================*/
 @isTest(seeAllData=false)
private class BatchAccountType_Test {

 // Scenario1: if there any Opportunity,  set the Account's Type to "Prospect"
 static testMethod void testAccType_Prospect() {

    // Actual test begins
    Test.StartTest();


    // Executing the batch job
    BatchAccountType accType = new BatchAccountType();
    ID batchprocessid = Database.executeBatch(accType);

    Test.StopTest();
    List<Account> result = [SELECT ID, Account_Type__c FROM Account
                            WHERE Name = 'forProspect1'
                            OR Name = 'forProspect2'];

    // Asserts to verify Account type set to prospect
    system.assertEquals(result.get(0).Account_Type__c, 'Prospect');
    system.assertEquals(result.get(1).Account_Type__c, 'Prospect');

  }

  // Scenario2: if there is any Order which has an End Date within a year from today,
  // set the Account's Type to "Client"
  static testMethod void testAccType_Client() {

    // Actual test begins
    Test.StartTest();

    // Executing the batch job
    BatchAccountType accType = new BatchAccountType();
    ID batchprocessid = Database.executeBatch(accType);

    Test.StopTest();
    List<Account> result = [SELECT ID, Account_Type__c FROM Account
                            WHERE Name = 'forCLient1'
                            OR Name = 'forCLient2'];

    // Asserts to verify Account type set to client
    System.assertEquals(result.get(0).Account_Type__c, 'Client');
    System.assertEquals(result.get(1).Account_Type__c, 'Client');

  }

  // Scenario3: if there are Orders, but NONE which has an End Date prior to a year from today
  // set the Account's Type to "Former Client"
  static testmethod void testAccType_FormerClient() {

    Test.StartTest();

    // Executing the batch job
    BatchAccountType accType = new BatchAccountType();
    ID batchprocessid = Database.executeBatch(accType);

    Test.StopTest();
    List<Account> result = [SELECT ID, Account_Type__c
                            FROM Account
                            WHERE Name = 'forFormerClient1'
                            OR Name = 'forFormerClient2'];
    // Asserts to verify Account type set to former client
    system.assertEquals(result.get(0).Account_Type__c, 'Former Client');
    system.assertEquals(result.get(1).Account_Type__c, 'Former Client');

  }

  //=============================================================================================
  // Settting up the data
  // 6 Accounts
  // 4 Contacts
  // 6 Opportunities - one per Account
  // 4 Orders - one on each of 4 Accounts
  // 4 Order Line Items - one for each Order
  //=============================================================================================
  @testSetup
  private static void createTestData() {
    List<Opportunity> lstOpps = new List<Opportunity>();
    List<Contact> lstCons = new List<Contact>();

    List<Account> lstAccount1 = new List<Account>();
    Account acc1 = Test_Utils.createAccount();
    acc1.Name = 'forFormerClient1';
    Account acc2 = Test_Utils.createAccount();
    acc2.Name = 'forFormerClient2';
    Account acc3 = Test_Utils.createAccount();
    acc3.Account_Type__c = null;
    acc3.Name = 'forProspect1';

    Account acc4 = Test_Utils.createAccount();
    acc4.No_Longer_In_Business__c = false;
    acc4.Name = 'forProspect2';

    Account acc5 = Test_Utils.createAccount();
    acc5.Name = 'forCLient1';
    Account acc6 = Test_Utils.createAccount();
    acc6.Name = 'forCLient2';
    acc6.No_Longer_In_Business__c = false;

    lstAccount1.add(acc1);
    lstAccount1.add(acc2);
    lstAccount1.add(acc3);
    lstAccount1.add(acc4);
    lstAccount1.add(acc5);
    lstAccount1.add(acc6);
    if (lstAccount1.size() > 0) {
      insert lstAccount1;
    }
    Contact con = Test_Utils.createContact(acc1.Id);
    Opportunity opp1 = Test_Utils.createOpportunity(acc1.Id);

    Contact con1 = Test_Utils.createContact(acc1.Id);
    Opportunity opp2 = Test_Utils.createOpportunity(acc1.Id);

    Opportunity opp3 = Test_Utils.createOpportunity(acc3.Id);

    Opportunity opp4 = Test_Utils.createOpportunity(acc4.Id);

    Contact con3 = Test_Utils.createContact(acc5.Id);
    Opportunity opp5 = Test_Utils.createOpportunity(acc5.Id);

    Contact con4 = Test_Utils.createContact(acc6.Id);
    Opportunity opp6 = Test_Utils.createOpportunity(acc6.Id);



    lstOpps.add(opp1);
    lstOpps.add(opp2);
    lstOpps.add(opp3);
    lstOpps.add(opp4);
    lstOpps.add(opp5);
    lstOpps.add(opp6);
    if (lstOpps.size() > 0) {
      insert lstOpps;
    }

    lstCons.add(con);
    lstCons.add(con1);
    lstCons.add(con3);
    lstCons.add(con4);
    if (lstCons.size() > 0) {
      insert lstCons;
    }

    List<Order__c> orders = new List<Order__c>();
    List<Order_Line_Item__c> olis = new List<Order_Line_Item__c>();
    Order__c ordr1 = Test_Utils.insertOrder(false, acc5.Id, con3.Id, opp5.Id);
    ordr1.Contract_End_Date__c = System.today().addDays(-30);
    orders.add(ordr1);

    Order__c ordr2 = Test_Utils.insertOrder(false, acc6.Id, con4.Id, opp6.Id);
    ordr2.Contract_End_Date__c = System.today().addYears(-1).addDays(+2);
    orders.add(ordr2);

    Date startDate = date.newinstance(2011, 2, 10);
    Date endDate = date.newinstance(2011, 2, 17);
    Date closeDate = date.newinstance(2011, 2, 27);

    Order__c ordr3 = Test_Utils.insertOrder(false, acc1.Id, con.Id, opp1.Id);
    ordr3.Contract_Start_Date__c = startDate;
    ordr3.Contract_End_Date__c = endDate;
    ordr3.Close_Date__c = closeDate;
    orders.add(ordr3);

    Order__c ordr4 = Test_Utils.insertOrder(false, acc2.Id, con1.Id, opp2.Id);
    ordr4.Contract_Start_Date__c = startDate;
    ordr4.Contract_End_Date__c = endDate;
    ordr4.Close_Date__c = closeDate;
    orders.add(ordr4);

    insert orders;

    Order_Line_Item__c oli1 = Test_Utils.insertOrderLineItems(false, ordr1.Id, null);
    olis.add(oli1);

    Order_Line_Item__c oli2 = Test_Utils.insertOrderLineItems(false, ordr2.Id, null);
    olis.add(oli2);

    Order_Line_Item__c oli3 = Test_Utils.insertOrderLineItems(false, ordr3.Id, null);
    oli3.Start_Date__c = startDate;
    oli3.End_Date__c = endDate;
    olis.add(oli3);

    Order_Line_Item__c oli4 = Test_Utils.insertOrderLineItems(false, ordr4.Id, null);
    oli4.Start_Date__c = startDate;
    oli4.End_Date__c = endDate;
    olis.add(oli4);

    insert olis;
  }

}