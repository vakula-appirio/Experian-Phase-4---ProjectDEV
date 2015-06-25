/*=====================================================================
 * Date Modified      Modified By                  Description of the update
 * Oct 29th,2014      Pallavi Sharma(Appirio)      Fix Failure
=====================================================================*/
@istest 
global class SMXProcessOrderBatchTest{
   
   
   public static void prepareTestData()  {    
      Account a = Test_Utils.insertAccount();
      Contact c = Test_Utils.insertContact(a.Id);   
      Order__c newOrder = Test_Utils.insertOrder(false, a.Id, c.Id, null);
      newOrder.Transactional_Sale__c = true;
      newOrder.Contract_End_Date__c = system.today().addDays(180);
      insert newOrder;
    }
       
    public static void ClearTestData(){    
      List<Feedback__c> lstFbk = [select id from Feedback__c where status__c='Nominated'];    
      delete lstFbk;
      List<Order__c> lstCs=[select Id from Order__c where Name='Test Order 001'];
      delete lstCs;
      List<Contact> lstCon = [select id from Contact where FirstName='BBB1'];    
      delete lstCon;
      List<Account> lstAcc = [select id from account where Name='AAA1'];    
      delete lstAcc;  
      }
    
    static testmethod void unit_test(){
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
        SMXProcessOrderBatch batch = new  SMXProcessOrderBatch();
        
        batch.execute(null, [ Select Id, Contact__c 
                              FROM Order__c 
                              WHERE Renewal_Survey_Date__c=TODAY 
                              AND Owner_Business_Unit__c = : bu 
                              AND Owner_Region__c IN('UK&I','North America')]);
        batch.finish(null);
        test.stoptest();
      }
    }
}