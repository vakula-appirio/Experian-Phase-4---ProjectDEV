/*=====================================================================
 * Date Modified      Modified By                  Description of the update
 * Oct 30th,2014      Pallavi Sharma(Appirio)      Fix Failure
=====================================================================*/
@isTest 
private class SMXAccountProcessorTest {       
    
   public static void setTestResponseValues(Integer testCaseNum ){
      if(testCaseNum == 1){
        SMXAccountProcessor.testHttpStatusCode = 200;
        SMXAccountProcessor.testHttpResponseXML =  '<webserviceresponse><code>0</code><description></description><row value="success"></row></webserviceresponse>';
      }else if(testCaseNum  == 2){
        SMXAccountProcessor.testHttpStatusCode = 200;
        SMXAccountProcessor.testHttpResponseXML = '<webserviceresponse><code>0</code><description></description><row value="No Send Rule is applied for the provider"></row></webserviceresponse>';        
      }else if(testCaseNum  == 3){
        SMXAccountProcessor.testHttpStatusCode = 200;
        SMXAccountProcessor.testHttpResponseXML = '<webserviceresponse><code>-1</code><description></description><row value=""></row></webserviceresponse>';        
      }else if(testCaseNum  == 4){
        SMXAccountProcessor.testHttpStatusCode = 404;
        SMXAccountProcessor.testHttpResponseXML = '<webserviceresponse><code>-1</code><description></description><row value=""></row></webserviceresponse>';        
      }
    }
        
   static testMethod void testFeedbackUpdate(){   
    String strPartyID = prepareTestData();
    for(Integer i = 1; i<=4; i++){
            setTestResponseValues(i);
            SMXAccountProcessor.syncAccount(strPartyID);
        }    
       cleanupTestData(); 
    }
    
  static String prepareTestData()
  {
  	Global_Settings__c custSettings = Global_Settings__c.getValues('Global');
    if (custSettings == null) {
      custSettings = new Global_Settings__c(name= Constants.GLOBAL_SETTING ,Account_Team_Member_Default_Role__c= Constants.TEAM_ROLE_ACCOUNT_MANAGER);
      insert custSettings;
    }
    Account a = new Account(Name='SMX Test Account1');
    insert a;    
    return a.Id;
  }  
  
  static void cleanupTestData(){
   Account a = [SELECT Id FROM ACCOUNT WHERE NAME='SMX Test Account1'];
   delete a;
  }
}