/**=====================================================================
 * Appirio, Inc
 * Name: AddDefaultAccountTeam_Controller_Test 
 * Description: Test-class to validate behaviour of AddDefaultAccountTeam_Controller
 * Created Date: 
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Feb 13th, 2014                    Jinesh Goyal(Appirio)         T-232763: Added Exception Logging
 =====================================================================*/
@isTest
private class AddDefaultAccountTeam_Controller_Test {

    static testMethod void testAddDefaultAccountTeam() {
        Account account = Test_Utils.insertAccount();
         
        Test.startTest();
            ApexPages.StandardController std = new ApexPages.StandardController(account);
            AddDefaultAccountTeam_Controller controller = new AddDefaultAccountTeam_Controller(std);
            try{
            controller.addTeamMember();
            List<AccountShare> accShare = [SELECT Id FROM AccountShare WHERE AccountId =: account.id AND UserOrGroupId =: UserInfo.getUserId()];
            system.assertEquals(accShare.size(), 1, 'AccountShare record should be exists.');
            }catch(Exception ex){
            apexLogHandler.createLogAndSave('AddDefaultAccountTeam_Controller_Test','testAddDefaultAccountTeam', ex.getStackTraceString(), ex);
            }
        Test.stopTest();
        
    }
}