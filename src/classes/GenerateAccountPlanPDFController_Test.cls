/**=====================================================================
 * Appirio, Inc
 * Test Class Name: GenerateAccountPlanPDFController_Test
 * Class Name: GenerateAccountPlanPDFController
 * Description: T-286029: To test functionality of GenerateAccountPlanPDFController
 * Created Date: Aug 07th, 2014
 * Created By: Arpita Bose (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Sep 15th, 2014               Arpita Bose                  T-315815: Modified methods testGenerateAccount1() and testGenerateAccount2()
 *                                                           to increase the code coverage
 =====================================================================*/
@isTest
private class GenerateAccountPlanPDFController_Test {
  private static Account_Plan__c aPlan;
  private static User testUser;
  private static Account_Plan_SWOT__c aSOWT;
  
  // testmethod with all records and for 'Experian SWOT'
  static testmethod void testGenerateAccount1(){
    //create test data
    createTestData(); 
    
    // start test     
    Test.startTest();
        PageReference pageRef = Page.GenerateAccountPlanPDF;
        pageRef.getParameters().put('mode','pdf');
        Test.setCurrentPage(pageRef);
        
        Attachment attachTest = new Attachment(Name='Account Plan.pdf');
        attachTest.body = Blob.valueOf('');
        attachTest.ParentID = aPlan.Id;
        attachTest.OwnerID = testUser.Id;
        insert attachTest;
        
        ApexPages.StandardController sc = new ApexPages.standardController(aPlan);
        GenerateAccountPlanPDFController gapc = new GenerateAccountPlanPDFController(sc);
        
        gapc.fetchRadarChartImageId();
        
        gapc.saveAttachment();
        
        aSOWT.Type__c = 'Strength';
        update aSOWT;
        
        sc = new ApexPages.standardController(aPlan);
        gapc = new GenerateAccountPlanPDFController(sc);
        //Asserts for strength Acc Plan SWOT
        system.assert(gapc.strengthAccPlanSWOTs <> null);
        
        aSOWT.Type__c = 'Opportunity';
        update aSOWT;
        sc = new ApexPages.standardController(aPlan);
        gapc = new GenerateAccountPlanPDFController(sc);
        //Asserts for opportunity Acc Plan SWOT
        system.assert(gapc.opportunityAccPlanSWOTs <> null);
        
        aSOWT.Type__c = 'Threat';
        update aSOWT;
        sc = new ApexPages.standardController(aPlan);
        gapc = new GenerateAccountPlanPDFController(sc);
        //Asserts for threat Acc Plan SWOT
        system.assert(gapc.threatAccPlanSWOTs <> null);
               
        // stop test
        Test.stopTest();
        
  }
  
  // testmethod for 'Client SWOT'
  static testmethod void testGenerateAccount2(){
        //create test data
        createTestData();   
        
        // start test       
        Test.startTest();
        PageReference pageRef = Page.GenerateAccountPlanPDF;
        pageRef.getParameters().put('mode','pdf');
        Test.setCurrentPage(pageRef);
        
        Attachment attachTest = new Attachment(Name='Account Plan.pdf');
        attachTest.body = Blob.valueOf('');
        attachTest.ParentID = aPlan.Id;  
        attachTest.OwnerID = testUser.Id;
        insert attachTest;
        
        ApexPages.StandardController sc = new ApexPages.standardController(aPlan);
        GenerateAccountPlanPDFController gapc = new GenerateAccountPlanPDFController(sc);
        
        gapc.fetchRadarChartImageId();
        
        gapc.saveAttachment();
         
        aSOWT.Who__c = 'Client';
        aSOWT.Type__c = 'Strength';
        update aSOWT;
        
        sc = new ApexPages.standardController(aPlan);
        gapc = new GenerateAccountPlanPDFController(sc);
        //Asserts for client strength Acc Plan SWOT
        system.assert(gapc.clientstrengthAccPlanSWOTs <> null);
        
        aSOWT.Type__c = 'Weakness';
        update aSOWT;
        sc = new ApexPages.standardController(aPlan);
        gapc = new GenerateAccountPlanPDFController(sc);
        //Asserts for client weakness Acc Plan SWOT
        system.assert(gapc.clientweaknessAccPlanSWOTs <> null);
        
        aSOWT.Type__c = 'Opportunity';
        update aSOWT;
        sc = new ApexPages.standardController(aPlan);
        gapc = new GenerateAccountPlanPDFController(sc);
        //Asserts for client Opportunity Acc Plan SWOT
        system.assert(gapc.clientopportunityAccPlanSWOTs <> null);
        
        aSOWT.Type__c = 'Threat';
        update aSOWT;
        sc = new ApexPages.standardController(aPlan);
        gapc = new GenerateAccountPlanPDFController(sc); 
        //Asserts for client threat Acc Plan SWOT
        system.assert(gapc.clientthreatAccPlanSWOTs <> null);
        
        
        // stop test
        Test.stopTest();
        
    }
  
  // method to create test data
  public static void createTestData(){
    testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);

    Account account = Test_Utils.insertAccount();
    aPlan = Test_Utils.insertAccountPlan(false, Account.id);
    insert aPlan;
        
    Opportunity testOpp = Test_Utils.insertOpportunity(account.Id);
        
    Account_Plan_Opportunity__c aPlanOpp = Test_Utils.insertAccountPlanOpp(true, aPlan.Id, testOpp.Id);
        
    AccountTeamMember accTeam = Test_Utils.createAccountTeamMembers(account.Id, testUser.Id, true);
        
    Account_Plan_Team__c aPlanTeam = Test_Utils.insertAccountPlanTeam(true, aPlan.Id, testUser.Id);
    
    aSOWT = Test_Utils.insertAccountPlanSwot(false, aPlan.Id);
    aSOWT.Who__c = 'Experian';
    aSOWT.Type__c = 'Weakness';
    insert aSOWT;

    Task task = test_Utils.createTask(account.Id, Constants.ACTIVITY_TYPE_SELECTION_CONFIRMED, Constants.STATUS_COMPLETED);
    insert task; 
    
  }

}