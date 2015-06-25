/*=====================================================================
 * Date Modified      Modified By                  Description of the update
 * Oct 29th,2014      Pallavi Sharma(Appirio)      Fix Failure
=====================================================================*/
@istest(seeAllData=False) 
global class SMXProcessOpportunityBatchTest{
   
   public static Opportunity prepareTestData()  { 
      Global_Settings__c gs = new Global_Settings__c();
      gs.Name = 'Global';
      gs.Batch_Failures_Email__c = '';
      insert gs;

      Account a = Test_Utils.insertAccount();
      Contact c = Test_Utils.insertContact(a.Id);    
      Opportunity newOpp = Test_Utils.createOpportunity(a.Id);
      newOpp.CloseDate = System.today().addDays(90);
      newOpp.Type = 'Credited';
      insert newOpp;
      OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId = newOpp.Id, ContactId = c.Id, IsPrimary = TRUE);
      insert ocr;
      return(newOpp); 
    }
       
    public static void ClearTestData(){    
      List<Feedback__c> lstFbk = [select id from Feedback__c where status__c='Nominated'];    
      delete lstFbk;
      List<Opportunity> lstCs=[select Id from Opportunity where Name='Test Opportunity 001'];
      List<OpportunityContactRole> lstOcr=[select id from OpportunityContactRole where OpportunityId IN : lstCs];
      delete lstOcr;
      delete lstCs;
      List<Contact> lstCon = [select id from Contact where FirstName='BBB1'];    
      delete lstCon;
      List<Account> lstAcc = [select id from account where Name='AAA1'];    
      delete lstAcc;  
      }
    
    static testmethod void SmxOpportunityScheduler(){
      User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      testUser.Global_Business_Line__c = 'Corporate';
      testUser.Business_Line__c = 'Corporate';
      testUser.Business_Unit__c = 'APAC:SE';
      testUser.Region__c = 'North America';
      insert testUser;
      System.runAs(testUser) {
        test.starttest();
        prepareTestData();
        String bu = Test_Utils.edqSetting.User_Business_Unit__c;
        Database.BatchableContext BC;
        SMXProcessOpportunityBatch batch = new  SMXProcessOpportunityBatch();
        Database.executeBatch(batch);
        /*batch.execute(BC, [ Select Id 
                              FROM Opportunity 
                              WHERE Type IN('Credited', 'Existing Business', 'Free Trail', 'Renewal', 'Trial')
                              AND Owner_s_Business_Unit__c = : bu 
                              AND Owner_s_Region__c IN('UK&I','North America')]);
                              
        batch.finish(BC);*/
        test.stoptest();
      }
    }
}