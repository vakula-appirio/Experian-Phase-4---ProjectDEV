/**=====================================================================
 * Appirio, Inc
 * Name: LeadSmartSearchExtension_Test
 * Description: Test class for LeadSmartSearchExtension
 * Created Date: 
 * Created By: 
 * 
 * Date Modified                Modified By                  Description of the update
 * Jan 30th, 2014                   Jinesh Goyal(Appirio)        T-232760: Homogenize the comments
 * Mar 04th, 2014                 Arpita Bose (Appirio)          T-243282: Added Constants in place of String
 * Mar 13th, 2014                 Arpita Bose(Appirio)           T-253906: Modified class name from TestLeadSmartSearchExtension
 *                                                               to LeadSmartSearchExtension_Test
 =====================================================================*/
@isTest
private class LeadSmartSearchExtension_Test {

        static testMethod void myUnitTest() {
        ApexPages.StandardController sc;
        createData();
        LeadSmartSearchExtension controller = new LeadSmartSearchExtension(sc);
        controller.leadFirstNameToSearch = 'Test';
        controller.leadLastNameToSearch = 'TestLast';
        controller.leadCompanyToSearch = 'test';
        controller.addressline1ToSearch = 'test';
        controller.addressCountryToSearch = 'test';
        controller.addressStateToSearch = 'test';
        controller.addressCityToSearch = 'test';
        controller.addressPostalCodeToSearch = 'test';
       
        controller.performSearch();
        /*
        System.assert(55<=controller.searchCount);
        System.assertEquals(1,controller.showingFrom);
        System.assertEquals(20,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(false,controller.hasPrevious);
        */
        controller.nextLeadPage();
        /*
        System.assertEquals(21,controller.showingFrom);
        System.assertEquals(40,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        */
        controller.previousLeadPage();
        /*
        controller.requestedPage = '3';
        controller.requestedLeadPage();
        System.assertEquals(41,controller.showingFrom);
        System.assertEquals(55,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(false,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        */
        controller.sortData();
        controller.cancel();
        
        controller.requestedPage = '5';
        controller.requestedLeadPage();
        
        controller.leadFirstNameToSearch = 'dert';
        controller.leadLastNameToSearch = 'wee';
        controller.performSearch();
        
        controller.leadEmailToSearch='TestLast';
        controller.performsearch();
    }
    
    
    static void CreateData() {
        Global_Settings__c custSettings = new Global_Settings__c(name=Constants.GLOBAL_SETTING,Smart_Search_Query_Limit__c=250);
        insert custSettings;
        
       list<Lead> leadList = new list<Lead>();
       for(Integer i=0;i<55;i++) {
           Lead leadObj = new Lead();
           leadObj.LastName='TestLast'+ i;
           leadObj.FirstName='Test'+  i;
           leadObj.email = 'TestLast@appiro.com';
           leadObj.Company='TestCompany'+ i;
           leadObj.Phone='0123456789';
           leadList.add(leadObj);
       }
       insert leadList;
    }
}