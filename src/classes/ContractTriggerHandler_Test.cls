/**=====================================================================
 * Appirio, Inc
 * Name: ContractTriggerHandler_Test
 * Description: Test class for ContractTriggerHandler.cls
 * Created Date: Mar 3rd, 2015
 * Created By: Gaurav Kumar Chadha (Appirio)
 * 
 * Date Modified        Modified By                 Description of the update
 =====================================================================*/
@isTest (seeAllData=false)
private class ContractTriggerHandler_Test{
    static testmethod void testValidatedByAndValidatedDate(){
      User testUser = Test_Utils.createUser(Constants.PROFILE_SYS_ADMIN);
      insert testUser;
      
      System.runAs(testUser) {
          Account acc = Test_Utils.insertAccount();  
    
          Contract__c testContract = Test_Utils.insertContract(true, acc.Id, Constants.AGENCY, Constants.STATUS_ACTIVE);
        
          Contract__c contract = [SELECT Validated_By__c, Validated_Date__c, Validation_Status__c 
                                 FROM Contract__c 
                                 WHERE ID = :testContract.ID ];
                  
          System.assert(contract.Validated_By__c == null && contract.Validated_Date__c == null);        
         
          testContract.Validation_Status__c = Constants.VALIDATION_STATUS_FAIL;
         
          Test.startTest();
          update testContract;
          Test.stopTest();
         
          Contract__c updatedContract = [SELECT Validated_By__c  , Validated_Date__c, Validation_Status__c  
                                        FROM Contract__c 
                                        WHERE ID = :testContract.ID ];

          System.assert(updatedContract.Validated_By__c == testUser.Id);
          System.assert(updatedContract.Validated_Date__c == System.today());       
      }
    }
    
    static testmethod void testValidatedByAndValidatedDate_Insert() {
       Account acc = Test_Utils.insertAccount();  

       Contract__c testContract = Test_Utils.insertContract(false, acc.Id, Constants.AGENCY, Constants.STATUS_ACTIVE);
       testContract.Contract_Effective_Date__c = Date.today();
       testContract.Initial_Term_Period__c = 5;

       Test.startTest();

       insert testContract;
       
       Contract__c contract = [SELECT Initial_Term_Period_End_Date__c  
                             FROM Contract__c 
                             WHERE ID = :testContract.ID ];
     
         System.assert(contract.Initial_Term_Period_End_Date__c != null);        
         
         Test.stopTest();
    }
    
     static testmethod void testValidatedByAndValidatedDate_update() {
       Account acc = Test_Utils.insertAccount();  

       Contract__c testContract = Test_Utils.insertContract(true, acc.Id, Constants.AGENCY, Constants.STATUS_ACTIVE);

       Contract__c contract = [SELECT Initial_Term_Period_End_Date__c  
                             FROM Contract__c 
                             WHERE ID = :testContract.ID ];

       System.assert(contract.Initial_Term_Period_End_Date__c == null);        
       
       Test.startTest();

       testContract.Contract_Effective_Date__c = Date.today();
       testContract.Initial_Term_Period__c = 5;
       update testContract;
       Test.stopTest();
       
       contract = [SELECT Initial_Term_Period_End_Date__c  
                             FROM Contract__c 
                             WHERE ID = :testContract.ID ];
     
       System.assert(contract.Initial_Term_Period_End_Date__c != null);        
       
    }    
}