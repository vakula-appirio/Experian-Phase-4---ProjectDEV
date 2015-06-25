/*========================================================================================================
 * Date Modified      Modified By                  Description of the update
 * Nov 6th, 2014      Arpita Bose(Appirio)         Updated method prepareTestData() and SmxcaseScheduler()
=========================================================================================================*/
@isTest (SeeAllData= true)
global class SMXProcessCaseBatchTest{
   
   public static case prepareTestData()  {    
      Account a = new Account(Name='AAA1',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='TestCountry');    
      Insert a;  
      Contact c = new Contact(FirstName='BBB1',LastName='SMX2SMX',accountId=a.Id, email = 'test123@gmail.com');    
      insert c;    
      /*case cs=new Case(subject='CCC1',accountid=a.id,Status = 'closed');
      insert cs; */
      Case cs = new Case(subject = 'CCC1', AccountId = a.id, Status = 'Closed Resolved', ContactId = c.Id,
                         RecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.CASE_REC_TYPE_EDQ_CASE ));
     // try{           
        insert cs;
     /* } catch(DMLException ex){
         apexLogHandler.createLogAndSave('SMXProcessCaseBatchTest','prepareTestData', ex.getStackTraceString(), ex);
      }*/
      system.debug('Case>>'+cs);  
      return(cs); 
      }
       
    public static void ClearTestData(){    
      List<Feedback__c> lstFbk = [select id from Feedback__c where status__c='Nominated'];    
      delete lstFbk;
      List<Case> lstCs=[select id from Case where subject='CCC1'];
      delete lstCs;
      List<Contact> lstCon = [select id from Contact where FirstName='BBB1'];    
      delete lstCon;
      List<Account> lstAcc = [select id from account where Name='AAA1'];    
      delete lstAcc;  
      }
    
    static testmethod void SmxcaseScheduler(){
    	  User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
        testUser.Global_Business_Line__c = 'Corporate';
        testUser.Business_Line__c = 'Corporate';
        testUser.Business_Unit__c = 'APAC:SE';
        testUser.Region__c = 'North America';
        insert testUser;
        System.runAs(testUser) {       
         test.starttest();
         // case cs=SMXProcessCaseBatchTest.prepareTestData();
         SMXProcessCaseBatch b = new  SMXProcessCaseBatch();
         id batch=database.executebatch(b);
         test.stoptest();
        }
    }
}