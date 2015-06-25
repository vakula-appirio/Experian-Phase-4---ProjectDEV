/**=====================================================================
 * Appirio Inc
 * Name: BusinessUtility_Test.cls
 * Description: T-314193: Test class for BusinessUnitUtility.cls
 * Created Date: Aug 27th, 2014
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified       Modified By                    Description of the update
 * 20th Apr, 2015      Paul Kissick                   Adding more testing
 =====================================================================*/
@isTest
private class BusinessUtility_Test{
  
  public static testmethod void testUtilityMethod(){
    // create test data
    User currentUser = new User();
    currentUser.Id = UserInfo.getUserId();
    currentUser.Global_Business_Line__c = 'Corporate';
    currentUser.Business_Line__c = 'Corporate';
    currentUser.Business_Unit__c = 'APAC:SE';
    update currentUser;
    System.debug('currentUser>>' +currentUser);

    Business_Unit_Group_Mapping__c custSetting1 = new Business_Unit_Group_Mapping__c();
    custSetting1.Name = 'APAC:SE';
    custSetting1.User_Business_Unit__c = 'APAC:SE';
    custSetting1.Common_Group_Name__c = 'APAC Group';
    custSetting1.Alternative_Renewal_Owner__c = UserInfo.getUserId();
    insert custSetting1;

    // start test
    Test.startTest();
    
    Map<String, String> bu_GroupMapTest = BusinessUnitUtility.getGroupNameForBusinessUnits(new Set<String>{'APAC:SE'});
    system.assertEquals(bu_GroupMapTest.get('APAC:SE'), 'APAC Group');
    
    Set<String> buSetTest = BusinessUnitUtility.getBUsFromGroupNames(new Set<String>{'APAC Group'});
    system.assert(buSetTest.contains('APAC:SE'));
    
    String result = BusinessUnitUtility.getBusinessUnit(currentUser.Id);
    String resultRen = BusinessUnitUtility.getAltRenewalOwner('APAC:SE');
    System.assertEquals(result, custSetting1.Common_Group_Name__c);
    System.assertEquals(resultRen, custSetting1.Alternative_Renewal_Owner__c);

    custSetting1.User_Business_Unit__c = 'EMEA MS';
    custSetting1.Common_Group_Name__c = 'EMEA Group';
    custSetting1.Alternative_Renewal_Owner__c = null;
    update custSetting1;

    result = BusinessUnitUtility.getBusinessUnit(currentUser.Id);
    resultRen = BusinessUnitUtility.getAltRenewalOwner('APAC:SE');
    
    // System.assertEquals('APAC Group', result); // PK: Seems a useless check here.
    System.assertEquals(null, resultRen);
    
    // stop test
    Test.stopTest();
  }
	
}