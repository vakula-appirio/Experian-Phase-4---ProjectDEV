/**
 * @copyright Topcoder INC
 * Developer : Topcoder
 * Version : 0.1
 * Date : 04-MAY-2014
 * This class contains unit tests for validating the behavior of Apex class RaderChartController
 */
@isTest
private class AccountHealthRadarChartControllerTEST {

    static testMethod void DataExistAndCreationTest() {
        Account_Plan__c aplan = new Account_Plan__c();
        insert aplan; // insert account plan
        ApexPages.currentPage().getParameters().put('id', aplan.id);
        Account_Plan_Contact__c accPlanContact = new Account_Plan_Contact__c(Account_Plan__c =aplan.Id,Include_in_Overall_Health_Status__c = TRUE );
        insert accPlanContact; // insert account plan contact
        Test.startTest();
        AccountHealthRadarChartController1 con1 = new AccountHealthRadarChartController1();
        System.assertEquals(con1.accPlanContactList.size(), 1); // one record inserted hence size should be 1 
        con1.changeChartSize();
        Test.stopTest();
        
    }
}