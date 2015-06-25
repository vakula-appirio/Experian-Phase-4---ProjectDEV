/**=====================================================================
 * Name: AutocompleteV2_Con_Test.cls
 * Description: 
 * Created Date: 12 January 2014
 * Created By: Arpita Bose (Appirio)
 =====================================================================*/
@isTest
private class AutocompleteV2_Con_Test {
    static testMethod void test_AutocompleteV2_Con() {
      User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);

      // The Global_Settings__c is initialized in Test_Utils. We need to call at least one method
      // to have it initialized
      Test_Utils.randomNumber(); 

        System.runAs(testUser) {
        
        List<Account> testAccountList = new List<Account>();
        //create some test account
         IsDataAdmin__c isDateAdmin = Test_Utils.insertIsDataAdmin(false);
        Account ultimateAccount = Test_Utils.insertAccount();
        Account parentAccount = Test_Utils.createAccount();
        parentAccount.Ultimate_Parent_Account__c = ultimateAccount.Id;
        insert parentAccount;
        Test.startTest();
        Account account = Test_Utils.createAccount();
        account.name= 'TestAccountAutoComplete1';
        account.ParentId = parentAccount.Id;
        insert account;
        Account account2 = Test_Utils.createAccount();
        account2.name= 'TestAccountAutoComplete2';
        account2.ParentId = ultimateAccount.Id;
        insert account2;
        
            System.assertEquals(2,AutoCompleteV2_Con.getData('Account','Name','Id','TestAccountAutoComplete').size());
            System.assertEquals(1, AutoCompleteV2_Con.getData('Account','Name','Id','TestAccountAutoComplete1').size());
            System.assertEquals(0, AutoCompleteV2_Con.getData('Account','Name','Id','xxxxxxx').size());
            AutoCompleteV2_Con controller = new AutoCompleteV2_Con ();
            controller.setTargetFieldVar(account.Id);
            System.assertEquals(account.Id,controller.getTargetFieldVar());
            controller.setCacheField(null);
        
        Test.stopTest();
        
      } 
    }
}