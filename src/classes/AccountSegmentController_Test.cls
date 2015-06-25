/**=====================================================================
 * Appirio, Inc
 * Name: AccountSegmentController_Test
 * Description: Test class for AccountSegmentController
 * Created Date: Apr 8th, 2015
 * Created By: Nathalie Le Guay (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 =====================================================================*/
@isTest(seeAllData = false)
public with sharing class AccountSegmentController_Test {
  static testMethod void controllerTest() {
    //createTestData();
    Account_Segment__c mySegment = [SELECT Id, Parent_Account_Segment__c, Account__c, Value__c,
                                           Segment__c
                                    FROM Account_Segment__c
                                    WHERE Segment__r.Value__c = 'Child'];
    ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(mySegment);

    Test.startTest();
    AccountSegmentController controller = new AccountSegmentController(sc);

    System.assertNotEquals(null, controller.segment);
    System.assertEquals('Grand Parent > Parent > Child', controller.title);
    System.assertEquals(false, controller.isEdit);

    controller.edit();
    System.assertEquals(true, controller.isEdit);

    controller.cancel();
    System.assertEquals(false, controller.isEdit);

    controller.segment.Total_Won__c = 15;
    controller.save();

    Test.stopTest();
  }

  @testSetup 
  static void createTestData() {
    Account testAcc = Test_Utils.createAccount();
    insert testAcc;

    Hierarchy__c grandParentHierarchy = new Hierarchy__c();
    grandParentHierarchy.Type__c = 'Global Business Line';
    grandParentHierarchy.Value__c = 'Grand Parent';
    grandParentHierarchy.Unique_Key__c = 'My BU';
    insert grandParentHierarchy;

    Hierarchy__c parentHierarchy = new Hierarchy__c();
    parentHierarchy.Type__c = 'Business Line';
    parentHierarchy.Value__c = 'Parent';
    parentHierarchy.Unique_Key__c = 'My BU Blah';
    parentHierarchy.Parent__c = grandParentHierarchy.Id;
    insert parentHierarchy;

    Hierarchy__c childHierarchy = new Hierarchy__c();
    childHierarchy.Type__c = 'Business Unit';
    childHierarchy.Value__c = 'Child';
    childHierarchy.Parent__c = parentHierarchy.Id;
    childHierarchy.Unique_Key__c = 'My BU Blah2';
    insert childHierarchy;

    Account_Segment__c segment = Test_Utils.insertAccountSegment(false, testAcc.Id, grandParentHierarchy.Id, null);
    insert segment;

    Account_Segment__c segment2 = Test_Utils.insertAccountSegment(false, testAcc.Id, parentHierarchy.Id, segment.Id);
    insert segment2;

    Account_Segment__c segment3 = Test_Utils.insertAccountSegment(false, testAcc.Id, childHierarchy.Id, segment2.Id);
    insert segment3;

    Account_Segmentation_Mapping__c mapping = new Account_Segmentation_Mapping__c();
    mapping.Name = 'Child';
    mapping.Global_Business_Line__c = 'Grand Parent';
    mapping.Business_Line__c = 'Parent';
    mapping.Business_Unit__c = 'Child';
    mapping.Common_View_Name__c = 'CSDA';
    mapping.Field_Set_API_Name__c = 'CSDA';
    insert mapping;
  }

}