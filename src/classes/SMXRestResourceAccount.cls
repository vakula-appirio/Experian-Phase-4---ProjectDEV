/*
 WS class
 SMXRestResourceAccount exposes methods to update account level NPS scores. 
*/
@RestResource(urlMapping='/Account/*')
global with sharing class SMXRestResourceAccount {

/*
 Calls updateAccount method with account id and NPS score
*/
@HttpPost
global static String doPost(Decimal decAvgNPS) {    
    RestRequest req = RestContext.request;
    String strCompanyId= req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
    strCompanyId = EncodingUtil.urlDecode(strCompanyId,'UTF-8');
    return updateAccount(strCompanyId,decAvgNPS);
   }
   
  /*
    updates the account level NPS scores
    strCompanyId - account id of the account to be updated
    decAvgNPS - NPS score
  */  
 static String updateAccount(String strCompanyId, Decimal decAvgNPS){
    // fetch account and update the NPS score
    if(strCompanyId == null || strCompanyId == '')
     return 'Failure';
    else{ 
        Account account;
        List<Account> lstAccount= [SELECT NPSScore__c FROM Account where ID =: strCompanyId];
        if(lstAccount == null || lstAccount.isEmpty())
            return 'Failure';
        else{   
            account = lstAccount[0];
            account.NPSScore__c = decAvgNPS;
            update account;
            return 'Success';
          }
       }
  }   
  
  
  /****** Test Methods *******/
  
  // test the WS interface
  @isTest(SeeAllData=true)
  static void testDoPost(){
     String strAccountId = prepareTestData();
     System.RestContext.request = new RestRequest();
     RestContext.request.requestURI = '/Account/' + strAccountId;
     SMXRestResourceAccount.doPost(9);     
     clearTestData();
  }
  
  // create test data
  static String prepareTestData(){  
    Account a = new Account(Name='SMX Test Account2',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='TestCountry');
    insert a;
    return a.Id;
  }
  
  // rupture test data
  static void clearTestData(){
    Account a = [SELECT Id from ACCOUNT WHERE Name = 'SMX Test Account2'];
    delete a;
  }
}