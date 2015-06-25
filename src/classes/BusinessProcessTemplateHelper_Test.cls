/**=====================================================================
 * Appirio, Inc
 * Name: BusinessProcessTemplateHelper_Test
 * Description: T-360800: Test class for BusinessProcessTemplateHelper
 * Created Date: Feb 16th, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified                Modified By                  Description of the update

  =====================================================================*/
@isTest
private class BusinessProcessTemplateHelper_Test {

    public static testmethod void testDeepCopy() {
      //create test data
      Profile p = [SELECT Id FROM Profile WHERE name=: Constants.PROFILE_SYS_ADMIN ];
      User defaultOwner1 = Test_Utils.createUser(p, 'test1234@gmail.com', 'test1');
      insert defaultOwner1;

      User defaultOwner2 = Test_Utils.createUser(p, 'test1234_2@gmail.com', 'test1_2');
      insert defaultOwner2;

      //business process template
      Business_Process_Template__c bpTemplt = new Business_Process_Template__c();
      bpTemplt.Name = 'Test BP Template-1';
      bpTemplt.Related_To__c = 'Cases';
      bpTemplt.Description__c = 'Test data';
      insert bpTemplt;
      //business process template item
      Business_Process_Template_Item__c bpTempltItem = new Business_Process_Template_Item__c();
      bpTempltItem.Business_Process_Template__c = bpTemplt.Id;
      bpTempltItem.Name = 'Test BP_Template Item-1';
      bpTempltItem.Description__c = 'Test data';
      bpTempltItem.Default_Owner__c = defaultOwner1.Id;
      bpTempltItem.Update_Status_When__c = Label.BP_TEMP_ITEM_UPDATE_STATUS_SERVICE_CREATED;
      bpTempltItem.Sequence__c = 1;
      insert bpTempltItem;

      Business_Process_Template_Item__c bpTempltItem1 = new Business_Process_Template_Item__c();
      bpTempltItem1.Business_Process_Template__c = bpTemplt.Id;
      bpTempltItem1.Name = 'Test BP_Template Item-2';
      bpTempltItem1.Description__c = 'Test data';
      bpTempltItem1.Default_Owner__c = defaultOwner2.Id;
      bpTempltItem1.Sequence__c = 2;
      insert bpTempltItem1;

      Business_Process_Template_Item__c bpTempltItem2 = new Business_Process_Template_Item__c();
      bpTempltItem2.Business_Process_Template__c = bpTemplt.Id;
      bpTempltItem2.Name = 'Test BP_Template Item-2';
      bpTempltItem2.Description__c = 'Test data';
      bpTempltItem2.Default_Owner__c = defaultOwner2.Id;
      bpTempltItem2.Sequence__c = 3;
      insert bpTempltItem2;
      //predecessor and successor for above Business_Process_Template_Item__c
      Business_Process_Template_Item_Link__c succesors1 = new Business_Process_Template_Item_Link__c();
      succesors1.Successor__c = bpTempltItem1.Id; //2nd BP tempItem
      succesors1.Status__c = Constants.STATUS_WAIT;
      succesors1.Loop_Back_Link__c = false;
      succesors1.Predecessor__c = bpTempltItem.Id; //1st BP temp Item
      insert succesors1;

      Business_Process_Template_Item_Link__c predecessor2 = new Business_Process_Template_Item_Link__c();
      predecessor2.Predecessor__c = bpTempltItem.Id; //1st
      predecessor2.Status__c = Constants.STATUS_WAIT;
      predecessor2.Loop_Back_Link__c = true;
      predecessor2.Successor__c = bpTempltItem1.Id; //2nd
      insert predecessor2;

      Business_Process_Template_Item_Link__c succesors2 = new Business_Process_Template_Item_Link__c();
      succesors2.Predecessor__c = bpTempltItem1.Id; //2nd
      succesors2.Status__c = Constants.STATUS_WAIT;
      succesors2.Loop_Back_Link__c = false;
      succesors2.Successor__c = bpTempltItem2.Id;
      insert succesors2;

      List<Business_Process_Template_Item__c> oldBPTempItemLst = [SELECT Id FROM Business_Process_Template_Item__c
                                                                  WHERE Business_Process_Template__c = :bpTemplt.Id];
      system.assertEquals(oldBPTempItemLst.size(), 3);

      List<String> oldBPTItemRecList = new List<String>();

      for (Business_Process_Template_Item__c oldBPTI : oldBPTempItemLst) {
         oldBPTItemRecList.add(oldBPTI.id);
      }
      List<String> newBPTItemRecList = new List<String>();

      // start test
      Test.startTest();
      //call the webservice by clicking the button
      BusinessProcessTemplateHelper.deepCopy(bpTemplt.Id);

      List<Business_Process_Template__c> newBPTemplt = [SELECT Id, Name FROM Business_Process_Template__c
                                                         WHERE Name =:bpTemplt.Name];
      //Asserts to check new copy of Business_Process_Template__c is created
      system.assertEquals(newBPTemplt.size(), 2);

      List<Business_Process_Template_Item__c> newBPTempItemLst = [SELECT Id FROM Business_Process_Template_Item__c
                                                                  WHERE Business_Process_Template__c = :newBPTemplt.get(1).Id
                                                                  AND Business_Process_Template__c <> :bpTemplt.Id];
      //Asserts to check new copy of Business_Process_Template_Item__c is created
      system.assertEquals(newBPTempItemLst.size(), 3);

      for (Business_Process_Template_Item__c newBPTI : newBPTempItemLst) {
         newBPTItemRecList.add(newBPTI.id);
      }

      List<Business_Process_Template_Item_Link__c> bpILink = [SELECT Id, Loop_Back_Link__c, Name,
                                                               Predecessor__c, Status__c, Successor__c
                                                              FROM Business_Process_Template_Item_Link__c
                                                              WHERE Predecessor__c IN :oldBPTItemRecList
                                                              OR Successor__c IN :oldBPTItemRecList];

      for (Business_Process_Template_Item_Link__c newBPILink : bpILink) {
        if (newBPILink.Predecessor__c != null) {
          BusinessProcessTemplateHelper.getNewId(oldBPTItemRecList, newBPTItemRecList, newBPILink.Predecessor__c);
        }
        if (newBPILink.Successor__c != null) {
          BusinessProcessTemplateHelper.getNewId(oldBPTItemRecList, newBPTItemRecList, newBPILink.Successor__c);
        }
      }

      List<Business_Process_Template_Item_Link__c> newBPILink = [SELECT Id FROM Business_Process_Template_Item_Link__c
                                                                 WHERE Predecessor__c IN :newBPTItemRecList
                                                                 OR Successor__c IN :newBPTItemRecList ];
      //Asserts to check new copy of Business Process Template Item Link (Predecessor and Successor)
      //is created for Business Process Item
      system.assertEquals(newBPILink.size(), 3);
      // stop test
      Test.stopTest();


    }


}