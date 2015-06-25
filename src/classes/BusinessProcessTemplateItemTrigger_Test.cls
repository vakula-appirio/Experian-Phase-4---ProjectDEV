/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessTemplateItemTrigger_Test
 * Description: test class for BusinessProcessTemplateItemTrigger
 * Created Date: Apr 02nd, 2015
 * Created By: Terri Kellough
 * Date Modified                Modified By                  Description of the update
 *
 *=====================================================================*/
@isTest
private class BusinessProcessTemplateItemTrigger_Test {


  //===========================================================================
  // Insert bpti without business hours, trigger should default it
  //===========================================================================
  static testmethod void test_insertBPTIwithoutBusinessHours(){
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);


    System.runAs(testUser) {
      Business_Process_Template__c bpt = [SELECT Id FROM Business_Process_Template__c LIMIT 1];
      List<Business_Process_Template_Item__c> bptisWithoutBusinessHours =
          new List<Business_Process_Template_Item__c>();
      for (Integer b=0; b<201; b++) {
      Business_Process_Template_Item__c bpti =
         new Business_Process_Template_Item__c(Business_Hours__c = null,
                                               Business_Process_Template__c = bpt.Id,
                                               Name = 'WithoutNulls');
        bptisWithoutBusinessHours.add(bpti);
      }

      Test.startTest();
      insert bptisWithoutBusinessHours;
      Test.stopTest();

      Integer results = [SELECT Id
                         FROM Business_Process_Template_Item__c
                         WHERE Business_Hours__c !=null AND Name = 'WithoutNulls'].size();

      // expected should be size of list above (201)
      Integer expected = bptisWithoutBusinessHours.size();

      System.assertEquals(expected, results);
    }
  }

  //===========================================================================
  // Tries to blank the Business_Hours__c, trigger should default it back
  //===========================================================================
  static testmethod void test_updateBPTIwithoutBusinessHours() {
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);

    System.runAs(testUser) {
      List<Business_Process_Template_Item__c> updateBptis = new List<Business_Process_Template_Item__c>();

      for (Business_Process_Template_Item__c bpti : [SELECT Id, Business_Hours__c
                                                     FROM Business_Process_Template_Item__c
                                                     WHERE Business_Hours__c != null]) {
       bpti.Business_Hours__c = null;
       bpti.Name = 'Updated to null';
       updateBptis.add(bpti);
      }

      Test.startTest();
      update updateBptis;
      Test.stopTest();

      Integer results = [SELECT Id
                         FROM Business_Process_Template_Item__c
                         WHERE Business_Hours__c != null
                            AND Name = 'Updated to null'
                            AND Id In:updateBptis].size();

      // expected should be size of list above (201)
      Integer expected = updateBptis.size();

      System.assertEquals(expected, results);
    }
  }

  //===========================================================================
  // Do not default business hours on update
  //===========================================================================
  static testmethod void test_updateBPTIwithBusinessHours() {
    User testUser = Test_Utils.insertUser(Constants.PROFILE_SYS_ADMIN);

    System.runAs(testUser) {
    List<Business_Process_Template_Item__c> updateBptis = new List<Business_Process_Template_Item__c>();

    for (Business_Process_Template_Item__c bpti : [SELECT Id, Business_Hours__c, Name
                                                   FROM Business_Process_Template_Item__c
                                                   WHERE Business_Hours__c != null]) {
       bpti.Name = 'Test 2';
       updateBptis.add(bpti);
    }

    Test.startTest();
    update updateBptis;
    Test.stopTest();

    Integer results = [SELECT Id
                       FROM Business_Process_Template_Item__c
                       WHERE Business_Hours__c !=null and Id In:updateBptis].size();

    // expected should be query size (201)
    Integer expected = updateBptis.size();

    System.assertEquals(expected, results);
   }
  }

  //===========================================================================
  // Creating test data
  //===========================================================================
  @testSetup
  static void setupTestData() {
    BusinessHours theDefaultBusinessHours = [SELECT Id
                                             FROM BusinessHours
                                             WHERE isActive = true AND isDefault = true
                                             LIMIT 1];

    // Create business process templates
    Business_Process_Template__c bpt = new Business_Process_Template__c(Name = 'TEST with Business Hours',
                                                                        Description__c = 'Test with Business Hours',
                                                                        Related_To__c = 'Case');
    insert bpt;

    // Create business process template items
    // Business Process Template Items with Business Hours
    List<Business_Process_Template_Item__c> bptisWithBusinessHours = new List<Business_Process_Template_Item__c>();
    bptisWithBusinessHours.clear();
    for (Integer b=0; b<201; b++) {
    Business_Process_Template_Item__c bpti =
         new Business_Process_Template_Item__c(Business_Hours__c = theDefaultBusinessHours.Id,
                                               Business_Process_Template__c = bpt.Id,
                                               Name = 'Test');
      bptisWithBusinessHours.add(bpti);
    }

    insert bptisWithBusinessHours;
  }
}