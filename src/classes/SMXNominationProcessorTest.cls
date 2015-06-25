/*=====================================================================
 * Date Modified      Modified By                  Description of the update
 * Oct 30th,2014      Pallavi Sharma(Appirio)      Fix Failure
=====================================================================*/
global class SMXNominationProcessorTest{

    public static void setTestResponseValues(Integer testCaseNum){
      if(testCaseNum == 1){
        SMXNominationProcessor.testHttpStatusCode = 200;
        SMXNominationProcessor.testHttpResponseXML = '<webserviceresponse><code>0</code><description></description><row value="success"></row></webserviceresponse>';
      }else if(testCaseNum  == 2){
        SMXNominationProcessor.testHttpStatusCode = 200;
        SMXNominationProcessor.testHttpResponseXML = '<webserviceresponse><code>0</code><description></description><row value="No Send Rule is applied for the provider"></row></webserviceresponse>';        
      }else if(testCaseNum  == 3){
        SMXNominationProcessor.testHttpStatusCode = 200;
        SMXNominationProcessor.testHttpResponseXML = '<webserviceresponse><code>-1</code><description></description><row value=""></row></webserviceresponse>';        
      }else if(testCaseNum  == 4){
        SMXNominationProcessor.testHttpStatusCode = 404;
        SMXNominationProcessor.testHttpResponseXML = '<webserviceresponse><code>-1</code><description></description><row value=""></row></webserviceresponse>';        
      }      
    }

   @isTest
   static void testFeedbackUpdate(){   
    List<Feedback__c> lstFeedback = prepareTestData();
    for(Feedback__c fbk: lstFeedback){
        for(Integer i = 1; i<=4; i++){
            SMXNominationProcessorTest.setTestResponseValues(i);
            SMXNominationProcessor.processNomination(fbk.Name);
           }
       }
      cleanupTestData(lstFeedback);
   }
   
   /*
   @isTest
   static void testFeedbackUpdateWithScrubbedRecords(){   
    //  test with scrubbing records  
    List<Feedback__c> lstFeedback = prepareTestData1();
    Feedback__c fbk = lstFeedback.get(0);
    
    SMXNominationProcessorTest.setTestResponseValues(1);
    SMXNominationProcessor.processNomination(fbk.Name);
    
    cleanupTestData1(lstFeedback);
       
   }
   
   @isTest
   static void testValidateForScrubRules(){   
    List<Feedback__c> lstFeedback = prepareTestData();
    Feedback__c fbk = lstFeedback.get(0);
    
    Contact c = [select Name,Account.Id, Email,FirstName,LastName,Title,Department,Salutation,Phone,MobilePhone,MailingState,MailingCity,MailingCountry,MailingPostalCode,Satmetrix_Contact_Type__c,HasOptedOutOfEmail,Status__c from Contact where Id =: fbk.Contact__c];
    
    List<Account> lstAccount = [select Id,Name,Industry,ShippingCity,ShippingCountry from Account where Id =: c.Account.Id ];
        
    SMXNominationProcessor.validateForScrubRules(fbk,c,lstAccount);
    
    cleanupTestData(lstFeedback);
       
    lstFeedback = prepareTestData1();
    fbk = lstFeedback.get(0);
    
    c = [select Name,Account.Id, Email,FirstName,LastName,Title,Department,Salutation,Phone,MobilePhone,MailingState,MailingCity,MailingCountry,MailingPostalCode,HasOptedOutOfEmail,Status__c from Contact where Id =: fbk.Contact__c];
    
    lstAccount = [select Id,Name,Industry,ShippingCity,ShippingCountry from Account where Id =: c.Account.Id ];
    
    SMXNominationProcessor.validateForScrubRules(fbk,c,lstAccount);
    
    cleanupTestData1(lstFeedback);
   }
     */
    static List<Feedback__c> prepareTestData()
      {
      	Global_Settings__c custSettings = Global_Settings__c.getValues('Global');
        if (custSettings == null) {
          custSettings = new Global_Settings__c(name= Constants.GLOBAL_SETTING ,Account_Team_Member_Default_Role__c= Constants.TEAM_ROLE_ACCOUNT_MANAGER);
          insert custSettings;
        }
        
        Account a = Test_Utils.createAccount();
        a.NAME='SMX Test Account';
        insert a; 
        
        Contact c = Test_Utils.createContact(a.Id); 
        c.FirstName='SMX TestFName1';
        c.LastName='SMX TestLName1';
        c.Email='this.is.a.smx.test@acmedemo.com';
        c.Phone='9999999';
        insert c;    
        c.HasOptedOutOfEmail = false;                    
        update c;
        
        List <Feedback__c> feedbackList = new List<Feedback__c>();
        Feedback__c feedback = new Feedback__c();
        feedback.Name = 'TESTCRM12345';
        feedback.Contact__c = c.Id; //ContactName
        feedback.DataCollectionId__c = 'SPARTASYSTEMS_126684';
        feedback.DataCollectionName__c = 'Test Survey';
        feedback.Status__c = 'Nominated';                       
        feedback.PrimaryScore__c = 9;
        feedback.PrimaryComment__c = 'Test comment';
        feedback.Status__c = 'Test Status';
        feedback.StatusDescription__c = 'Test Description';
        feedback.SurveyDetailsURL__c = '';
        feedbackList.add(feedback);  
        
        insert feedbackList;    
        
        return feedbackList;
      }  
      
      static void cleanupTestData(List<Feedback__c> lstFeedback){
       delete lstFeedback;
       
       Contact c = [SELECT Id FROM CONTACT WHERE FirstName = 'SMX TestFName1']; 
       delete c;
       
       Account a = [SELECT Id FROM ACCOUNT WHERE NAME='SMX Test Account'];
       delete a;       
      }  
    
      
}