/******************************************************************************
 * Appirio, Inc
 * Name: BusinessProcessTriggerHandler
 * Created Date: Mar 26th, 2015 Created By : Suminder Singh(Appirio)
 *
 * Date Modified        Modified By                  Description of the update
 * Mar 27th, 2015       Terri Kellough               T-373995: added CSDA_Type__c and CSDA_Service_Type__c fields to business process template item
 * Apr 04th, 2015       Naresh kr Ojha(Appirio)      Updated test methods
 * Apr 08th, 2015       Terri Kellough               T-376624: Added test_mappingBPFields
 *******************************************************************************/
@isTest
public class BusinessProcessTriggerHandler_Test {
  static Business_Process__c buProcess;

    static testMethod void handleNewBusinessProcesses_test() {
      Business_Process__c  buProcess1 = [Select Id FROM Business_Process__c];
      list<Business_Process_Item__c> buProcsItems = [SELECT Status__c, Id
                                             FROM Business_Process_Item__c
                                             order by Sequence__c ASC ];
        Business_Process_Item__c buProcsItem1 = buProcsItems[0];
      Business_Process_Item__c buProcsItem2 = buProcsItems[1];
      Business_Process_Item__c buProcsItem3 = buProcsItems[2];
      Test.startTest();
        buProcsItem1.Status__c = Constants.STATUS_SUCCESS;
        update buProcsItem1;
        Test.stopTest();
    }

    static testMethod void test_handleNewBusinessProcesses_OnInsert() {
      Business_Process__c  buProcess1 = [Select Id FROM Business_Process__c];
      list<Business_Process_Item__c> buProcsItems = [SELECT Status__c, Id
                                             FROM Business_Process_Item__c
                                             order by Sequence__c ASC ];
        Business_Process_Item__c buProcsItem1 = buProcsItems[0];
      Business_Process_Item__c buProcsItem2 = buProcsItems[1];
      Business_Process_Item__c buProcsItem3 = buProcsItems[2];
      Test.startTest();
      Business_Process_Item__c buProcList = [select id, Status__c from  Business_Process_Item__c where Id =:buProcsItem2.Id];
      System.assertEquals(buProcList.Status__c, Constants.READY);
      Test.stopTest();
    }

    static testMethod void test_populateMembershipWithBPItems_OnUpdate(){
      Business_Process__c  buProcess1 = [Select Id FROM Business_Process__c];
      list<Business_Process_Item__c> buProcsItems = [SELECT Final_State__c,Status__c, Id
                                             FROM Business_Process_Item__c
                                             order by Sequence__c ASC ];
        Business_Process_Item__c buProcsItem1 = buProcsItems[0];
      Business_Process_Item__c buProcsItem2 = buProcsItems[1];
      Business_Process_Item__c buProcsItem3 = buProcsItems[2];
      Test.startTest();
        buProcsItem1.Status__c = Constants.STATUS_SUCCESS;
        update buProcsItem1;
      Business_Process_Item_Link__c buProcItemLink = [select id, status__c from Business_Process_Item_Link__c where Successor__c = :buProcsItem2.Id];
      System.assertEquals(buProcItemLink.status__c, Constants.STATUS_WAIT);
      Test.stopTest();
    }


    //=====================================================================
    // This method verifies fields from the business process template are
    // mapped to the business process
    //=====================================================================
    static testMethod void test_mappingBPFields() {
      Case cas = [SELECT Id FROM Case LIMIT 1];
      List<Business_Process_Template__c> bptList = [SELECT Id, Business_Unit__c, Sub_Business_Unit__c
                                                    FROM Business_Process_Template__c
                                                    WHERE Name = 'Mapping Test'
                                                    AND Business_Unit__c =: Constants.BU_CSDA
                                                    AND Sub_Business_Unit__c =: Constants.SUB_BU_CIS];

      System.assert(bptList.size() > 0);

      List<Business_Process__c> bpList = new List<Business_Process__c>();
      List<Id> bptIdList = new List<Id>();

      //Apply business process to case
      for (Business_Process_Template__c bpt : bptList) {
        Business_Process__c bp = new Business_Process__c();
        bp.Case__c = cas.Id;
        bp.Business_Process_Template__c = bpt.Id;
        bpList.add(bp);
        bptIdList.add(bpt.Id);
      }

      Test.startTest();
      insert bpList;
      Test.stopTest();

      //Now verify resulting business processes insert has the fields mapped correctly
      List<Business_Process__c> bpInsertedList = [SELECT Id, Case__c, Business_Unit__c, Sub_Business_Unit__c
                                           FROM Business_Process__c
                                           WHERE Business_Process_Template__c In: bptIdList
                                           AND Business_Unit__c =: Constants.BU_CSDA
                                           AND Sub_Business_Unit__c =: Constants.SUB_BU_CIS];
      Integer expected = bptList.size();
      Integer actual = bpInsertedList.size();

      System.assertEquals(expected, actual);

    }

    @testSetup
    static void createData() {
        Account acc = Test_Utils.insertAccount();
        Opportunity opp = Test_Utils.insertOpportunity(acc.Id);
        Business_Process_Template__c bpTemplate = new Business_Process_Template__c();
        bpTemplate.Related_To__c = 'Opportunities';
        bpTemplate.Business_Unit__c = 'CSDA';
        bpTemplate.Sub_Business_Unit__c = 'CIS';
        insert bpTemplate;

        Business_Process_Template_Item__c buProcessItem = new Business_Process_Template_Item__c();
        buProcessItem.Business_Process_Template__c = bpTemplate.Id;
        buProcessItem.Expire__c = false;
        buProcessItem.Assign_To_Queue_when_Ready__c = true;
        buProcessItem.Update_Status_When__c = 'Service is Created';
        buProcessItem.Name = '3-BPTI';
            buProcessItem.CSDA_Service_Type__c = 'Test ST';
            buProcessItem.CSDA_Type__c = 'Test T';
        insert buProcessItem;

        Business_Process_Template_Item__c buProcessItem1 = new Business_Process_Template_Item__c();
        buProcessItem1.Business_Process_Template__c = bpTemplate.Id;
        buProcessItem1.Expire__c = false;
        buProcessItem1.Assign_To_Queue_when_Ready__c = true;
        buProcessItem1.Update_Status_When__c = 'Service is Created';
        buProcessItem1.Name = '4-BPTI';
            buProcessItem.CSDA_Service_Type__c = 'Test ST';
            buProcessItem.CSDA_Type__c = 'Test T';
        insert buProcessItem1;


        Business_Process_Template_Item_Link__c buProcTempItemLink = new Business_Process_Template_Item_Link__c();
        buProcTempItemLink.Predecessor__c = buProcessItem.Id;
        buProcTempItemLink.Successor__c = buProcessItem1.Id;
        insert buProcTempItemLink;

        // create test data
        buProcess = new Business_Process__c();
        buProcess.Status__c = Constants.OPEN;
        buProcess.Opportunity__c = opp.Id;
        buProcess.Business_Process_Template__c = bpTemplate.Id;
        insert buProcess;

        Business_Process_Item__c buProcsItem1 = new Business_Process_Item__c();
        buProcsItem1.Business_Process__c = buProcess.Id;
        buProcsItem1.Status__c = Constants.STATUS_WAIT;
        buProcsItem1.Sequence__c = 1;
        insert buProcsItem1;

        Business_Process_Item__c buProcsItem2 = new Business_Process_Item__c();
        buProcsItem2.Business_Process__c = buProcess.Id;
        buProcsItem2.Status__c = Constants.READY;
        buProcsItem2.Sequence__c = 2;
        insert buProcsItem2;

        Business_Process_Item_Link__c bpiLink1 = new Business_Process_Item_Link__c();
        bpiLink1.Predecessor__c = buProcsItem1.Id;
        bpiLink1.Successor__c = buProcsItem2.Id;
        bpiLink1.Status__c = Constants.STATUS_WAIT;
        bpiLink1.Loop_Back_Link__c = true;
        insert bpiLink1;

        Business_Process_Item_Link__c bpiLink2 = new Business_Process_Item_Link__c();
        bpiLink2.Predecessor__c = buProcsItem1.Id;
        bpiLink2.Successor__c = buProcsItem2.Id;
        bpiLink2.Status__c = Constants.STATUS_SUCCESS;
        bpiLink2.Loop_Back_Link__c = true;
        insert bpiLink2;

        //Apr 8th, 2015 TTK - added
        Case cas = Test_Utils.insertCase (True, null, acc.Id, null);
        List<Business_Process_Template__c> busTemplateList = new List<Business_Process_Template__c>();

        for (Integer bp = 0; bp < 200 ; bp++) {
          Business_Process_Template__c busTemplate2 = Test_Utils.insertBusinessProcessTemplate(false,
            Constants.RELATED_TO_CASES, Constants.BU_CSDA, Constants.SUB_BU_CIS);
          busTemplate2.Name = 'Mapping Test';
          busTemplateList.add(busTemplate2);
        }
        insert busTemplateList;

  }
}