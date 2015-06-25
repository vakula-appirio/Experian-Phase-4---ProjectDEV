/**=====================================================================
 * Name: BatchQuoteStatusUpdate_Test
 * Description: Test Class to cover SFDCToCPQChangeStatusServiceClass ,BatchQuoteStatusUpdate.
 * Created Date: Oct 23th 2014
 * Created By: Richard Joseph
 *
 * Date Modified         Modified By          Description of the update
 =====================================================================*/
@isTest(seealldata=false)
public class BatchQuoteStatusUpdate_Test {

  //=============================================================================================
  // Reopening Opp
  //=============================================================================================
  private static testmethod void CPQChangeStatusServiceTest() {
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    User oldUser = [SELECT Id FROM User limit 1];
    Opportunity oppr = [SELECT Id FROM Opportunity LIMIT 1];
    Address__c address = [SELECT Id FROM Address__c LIMIT 1];

    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
    insert newcontact;
    Test_Utils.insertContactAddress(true, address.Id, newContact.Id);

    Test_Utils.createOpptyTasks(oppr.Id, true);
    Test_Utils.insertEDQOpportunityContactRoles(oppr.Id, newContact.Id);

    Quote__c newQuote = new Quote__c();
    newQuote.Opportunity__c = oppr.id;
    insert newQuote;

    Test.startTest();
    oppr.StageName = Constants.OPPTY_STAGE_7;
    oppr.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    update oppr;

    Test.stopTest();
    /*Opportunity updatedOpp = [SELECT Id, Owner_GBL_on_Opp_Close_Date__c, Owner_BU_on_Opp_Close_Date__c, Owner_BL_on_Opp_Close_Date__c,
                                     Owner_Sales_Team_on_Opp_Close_Date__c, Owner_Sales_Sub_Team_on_Opp_Close_Date__c,
                                     Owner_Country_on_Opp_Close_Date__c, Owner_Region_on_Opp_Close_Date__c,IsWon,IsClosed
                              FROM Opportunity
                            WHERE Id =: oppr.Id];
    system.debug('@@IsWon' + updatedOpp.IsWon);
    system.debug('@@IsWon' + updatedOpp.IsClosed);

    system.assertEquals(updatedOpp.Owner_BU_on_Opp_Close_Date__c , Constants.BUSINESS_UNIT_MS_CIT);
    system.assertEquals(updatedOpp.Owner_GBL_on_Opp_Close_Date__c , Constants.GLOBAL_BUSINESS_MARKETING_SERVICES);*/

  }

  //=============================================================================================
  // Reopening 2 Opps
  //=============================================================================================
  private static testmethod void BulkQuoteStatusUpdateTest() {

    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    User oldUser = [SELECT Id FROM User LIMIT 1];
    Opportunity oppr = [SELECT Id,StageName,Name,CloseDate,Amount,Has_Senior_Approval__c,
                               Starting_Stage__c,Channel_Type__c,OwnerId
                        FROM Opportunity LIMIT 1];
    Address__c address = [SELECT Id FROM Address__c LIMIT 1];

    Contact newcontact  = new Contact (FirstName = 'Larry', LastName = 'Ellison', AccountId = testAccount.Id, Email = 'larrye@email.com');
    insert newcontact;
    Test_Utils.insertContactAddress(true, address.Id, newContact.Id);

    Test_Utils.createOpptyTasks(oppr.Id, true);

    Test_Utils.insertEDQOpportunityContactRoles(oppr.Id, newContact.Id);
    Opportunity opprClone = oppr.Clone();
    insert opprClone ;

    Test_Utils.createOpptyTasks(opprClone .Id, true);
    Test_Utils.insertEDQOpportunityContactRoles(opprClone.Id, newContact.Id);

    Quote__c newQuote = new Quote__c();
    newQuote.Opportunity__c = oppr.id;
    insert newQuote;

    Quote__c newNextQuote = new Quote__c();
    newNextQuote .Opportunity__c = opprClone .id;
    insert newNextQuote ;


    Test.startTest();
    oppr.StageName = Constants.OPPTY_STAGE_7;
    oppr.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    //update oppr;

    opprClone.StageName = Constants.OPPTY_STAGE_7;
    opprClone.Starting_Stage__c = Constants.OPPTY_STAGE_6;

    list<Opportunity> optyListUpdate1 = new  list<Opportunity>();
    list<Opportunity> optyListUpdate2 = new  list<Opportunity>();
    optyListUpdate1 .add(oppr);
    optyListUpdate2 .add(opprClone);
    update optyListUpdate1 ;
    update optyListUpdate2 ;
    Test.stopTest();

  }

  //=============================================================================================
  // Executing BatchQuoteStatusUpdate() Batch
  //=============================================================================================
  private static testmethod void BatchQuoteStatusUpdateTest() {
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    User oldUser = [SELECT Id FROM User limit 1];
    Opportunity oppr = [SELECT Id FROM Opportunity LIMIT 1];

    Quote__c newQuote = new Quote__c();
    newQuote.Opportunity__c = oppr.id;
    newQuote.Status_Change_Error_Message__c='Error';
    insert newQuote;

    Test.startTest();
    BatchQuoteStatusUpdate objTest = new BatchQuoteStatusUpdate ();
    //objTest .query = 'Select id,Quote_Id__c,Primary__c,Opportunity__r.StageName,Name from Quote__c where Opportunity__r.id=\''+oppr.id+'\'';
    objTest .query = 'Select id,Quote_Id__c,Primary__c,opportunity__c from Quote__c where Opportunity__r.id=\''+oppr.id+'\'';
    objTest .updateOpportunityMap = new Map<id,Opportunity>();
    objTest .updateOpportunityMap.put(oppr.id,oppr);
    database.executeBatch(objTest ,1);
    Test.stopTest();
  }

  //=============================================================================================
  // Code coverage
  //=============================================================================================
  private static testmethod void CPQChangeStatusServiceAsyncTest() {
    Quote__c newQuote = new Quote__c();
    insert newQuote;

    Test.startTest();
    SFDCToCPQChangeStatusServiceClass.callCPQChangeStatusSerivceAsync(newQuote.ID);
    Test.stopTest();
  }

  //=============================================================================================
  // Code coverage
  //=============================================================================================
  private static testmethod void callCPQUserAdminSerivceTest() {
    Quote__c newQuote = new Quote__c();
    insert newQuote;

    Test.startTest();
    HttpResponse resTest = new HttpResponse();
    resTest .setStatus('OK');
    resTest .setStatusCode(200);
    resTest .setBody('<Result><Result>OK</Result></Result>');
    SFDCToCPQChangeStatusServiceClass.responseCPQ=resTest ;
    SFDCToCPQChangeStatusServiceClass.callCPQUserAdminSerivce(newQuote);
    Test.stopTest();
  }

  //=============================================================================================
  // Create test data
  // 1 Account
  // 1 User
  // 2 CPQ Settings
  // 1 Opportunity
  //=============================================================================================
  @testSetup
  private static void createTestData () {
    Account testAccount = Test_Utils.insertAccount();
    Address__c addr = Test_Utils.insertAddress(true);
    Test_Utils.insertAccountAddress(true, addr.Id, testAccount.Id);

    User oldUser = Test_Utils.createUser(Constants.PROFILE_EXP_SALES_EXEC);
    oldUser.Business_Unit__c = Constants.BUSINESS_UNIT_MS_CIT;
    oldUser.Global_Business_Line__c = Constants.GLOBAL_BUSINESS_MARKETING_SERVICES;
    oldUser.CPQ_User__c=true;
    oldUser.CPQ_User_Type__c= 'EDQ Sales';
    oldUser.country__c='USA';
    insert oldUser;

    CPQ_Settings__c testCPQSetting= new CPQ_Settings__c ();
    testCPQSetting.Name = 'CPQ';
    testCPQSetting.Company_Code__c= 'Experian';
    testCPQSetting.CPQ_API_Access_Word__c = 'Accessword';
    testCPQSetting.CPQ_API_Endpoint__c= 'https://test.webcomcpq.com/';
    testCPQSetting.CPQ_API_UserName__c= 'TestUser#Experian';

    CPQ_Settings__c testCPQSetting2= new CPQ_Settings__c ();
    testCPQSetting2.Name = 'CPQAlt';
    testCPQSetting2.Company_Code__c= 'Experian';
    testCPQSetting2.CPQ_API_Access_Word__c = 'Accessword';
    testCPQSetting2.CPQ_API_Endpoint__c= 'https://test.webcomcpq.com/';
    testCPQSetting2.CPQ_API_UserName__c= 'TestUser#Experian';
     insert new List<CPQ_Settings__c> { testCPQSetting,testCPQSetting2};

    Opportunity oppr = Test_Utils.createOpportunity(testAccount.Id);
    oppr.Has_Senior_Approval__c = true;
    oppr.StageName = Constants.OPPTY_STAGE_3;

    oppr.Amount = 500;
    oppr.Starting_Stage__c = Constants.OPPTY_STAGE_6;
    oppr.OwnerId = oldUser.Id;
    oppr.Channel_Type__c = Constants.OPPTY_CHANNEL_TYPE_DIRECT;
    insert oppr;
  }
}