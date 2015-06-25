/**=====================================================================
 * Appirio, Inc
 * Name: TestRequestAccessExtension
 * Description: 
 * Created Date: Jul 19th, 2011
 * Created By: Mohammed Irfan (Appirio)
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014									  Jinesh Goyal(Appirio)				 T-232760: Homogenize the comments
 * Mar 05th, 2014                   Arpita Bose(Appirio)         T-243282: Added Constants in place of String
 =====================================================================*/
@isTest
private class TestRequestAccessExtension{

    static testMethod void myUnitTest() {
    Global_Settings__c custSettings = new Global_Settings__c(name=Constants.GLOBAL_SETTING, Account_Team_Member_Default_Role__c=Constants.TEAM_ROLE_ACCOUNT_MANAGER, Smart_Search_Query_Limit__c=250);
        insert custSettings;
        Account acc = new Account(name= '00TestContact0');
        insert acc;   
        
        ApexPages.currentPage().getParameters().put('Id',acc.id);
       
       

        RequestAccessExtension cnt = new RequestAccessExtension();
        cnt.name='test';

        Global_Settings__c cust= new Global_Settings__c(Name=Constants.GLOBAL_SETTING,Case_Access_Request_TeamRole__c= Constants.CASE_TEAM_ROLE_REQUESTOR);
        insert cust;
        
        cnt.submitCase();
    }
    
}