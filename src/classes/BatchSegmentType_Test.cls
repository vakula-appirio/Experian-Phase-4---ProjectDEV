/**=====================================================================
 * Appirio, Inc
 * Name: BatchSegmentType
 * Description: T-371862
 * Created Date: Mar 19th, 2015
 * Created By: Arpita Bose (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * 17th Apr, 2015               Suminder Singh               Fixed Test class for failures
 =====================================================================*/
@isTest(SeeAllData=false)
private class BatchSegmentType_Test {

    public static testmethod void testBatch() {
      // Actual test begins
        Test.StartTest();

        // Executing the batch job
        BatchSegmentType batch = new BatchSegmentType(false);
        ID batchprocessid = Database.executeBatch(batch,200);

          Test.StopTest();
          system.assertEquals(200, [SELECT ID FROM Account_Segment__c].size());
          system.assertEquals(100, [SELECT ID FROM Account_Segment__c WHERE Relationship_Type__c = 'Client'].size());
          system.assertEquals(100, [SELECT ID FROM Account_Segment__c WHERE Relationship_Type__c = 'Former Client'].size());
    }

    @testSetup
    private static void createTestData() {
      Integer runTimes = 200;
      List<Account> accList = new List<Account>();
      List<Contact> contactList = new List<Contact>();
      List<Opportunity> opptyList = new List<Opportunity>();
        Map<String, Hierarchy__c> hierarchyMap = new Map<String, Hierarchy__c>();
        Map<String, Account_Segment__c> accSegmentMap = new Map<String, Account_Segment__c>();
        for (Integer i = 0; i<runTimes; i++) {
        accList.add(Test_Utils.createAccount());
      }
      insert accList;

      for (Integer i = 0; i<runTimes; i++) {
        contactList.add(Test_Utils.createContact(accList.get(i).Id));
      }
      insert contactList;

      for (Integer i = 0; i<runTimes; i++) {
        opptyList.add(Test_Utils.createOpportunity(accList.get(i).Id));
      }
      insert opptyList;

      //for (Integer i = 0; i<runTimes; i++) {
        Hierarchy__c gbl = Test_Utils.insertHierarchy(false, null, 'Level 1 - Test-GBL', 'Global Business Line');
        hierarchyMap.put('gbl-', gbl);
        Hierarchy__c bl = Test_Utils.insertHierarchy(false, null, 'Level 2 - Test-BL', 'Business Line');
        hierarchyMap.put('bl-', bl);
        Hierarchy__c bu = Test_Utils.insertHierarchy(false, null, 'Level 3 - Test-BU', 'Business Unit');
        hierarchyMap.put('bu-', bu);
        Hierarchy__c region = Test_Utils.insertHierarchy(false, null, 'Test-Region', 'Region');
        hierarchyMap.put('region-', region);
        Hierarchy__c country = Test_Utils.insertHierarchy(false, null, 'Test-Country', 'Country');
        hierarchyMap.put('country-', country);
    //  }

      insert hierarchyMap.values();

      string debugStr = '';
      for (Integer i = 0; i<runTimes; i++) {
            Account_Segment__c accSeg1 = Test_Utils.insertAccountSegment(false, accList.get(i).Id, hierarchyMap.get('gbl-').Id, null);
            accSegmentMap.put(accList.get(i).Name+'-'+hierarchyMap.get('gbl-').Name, accSeg1);
            debugStr += '\n~~GBL='+i+'~~~~~~' + hierarchyMap.get('gbl-');
            Account_Segment__c accSeg2 = Test_Utils.insertAccountSegment(false, accList.get(i).Id, hierarchyMap.get('bl-').Id, null);
            accSegmentMap.put(accList.get(i).Name+'-'+hierarchyMap.get('bl-').Name, accSeg2);
            debugStr += '\n~~BL='+i+'~~~~~~' + hierarchyMap.get('bl-');
            Account_Segment__c accSeg3 = Test_Utils.insertAccountSegment(false, accList.get(i).Id, hierarchyMap.get('bu-').Id, null);
            accSegmentMap.put(accList.get(i).Name+'-'+hierarchyMap.get('bu-').Name, accSeg3);
            debugStr += '\n~~BU='+i+'~~~~~~' + hierarchyMap.get('bu-');
            Account_Segment__c accSeg4 = Test_Utils.insertAccountSegment(false, accList.get(i).Id, hierarchyMap.get('region-').Id, null);
            accSegmentMap.put(accList.get(i).Name+'-'+hierarchyMap.get('region-').Name, accSeg4);
            debugStr += '\n~~Region='+i+'~~~~~~' + hierarchyMap.get('region-');
            Account_Segment__c accSeg5 = Test_Utils.insertAccountSegment(false, accList.get(i).Id, hierarchyMap.get('country-').Id, null);
            accSegmentMap.put(accList.get(i).Name+'-'+hierarchyMap.get('country-').Name, accSeg5);
            debugStr += '\n~~Country='+i+'~~~~~~' + hierarchyMap.get('country-');
      }

      insert accSegmentMap.values();

      Date startDate = system.today().addDays(-6);
      Date endDate = system.today().addDays(-1);

      List<Order__c> lstOrder = new List<Order__c>();

      for (Integer i = 0; i < runTimes; i++) {
        if (i < runTimes/2) {
          Order__c ordr1 = Test_Utils.insertOrder (false, accList.get(i).Id, contactList.get(i).Id, opptyList.get(i).Id);
          ordr1.Contract_Start_Date__c = startDate;
          ordr1.Contract_End_Date__c = endDate;
          ordr1.Segment_Global_Business_Line__c = accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('gbl-').Name).Id;
          ordr1.Segment_Business_Line__c = accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('bl-').Name).Id;
          ordr1.Segment_Business_Unit__c = accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('bu-').Name).Id;
          ordr1.Segment_Region__c = accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('region-').Name).Id;
          ordr1.Segment_Country__c =  accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('country-').Name).Id;
          lstOrder.add(ordr1);
          continue;
        }

          Order__c ordr4 = Test_Utils.insertOrder (false, accList.get(i).Id, contactList.get(i).Id, opptyList.get(i).Id );
          ordr4.Contract_Start_Date__c = startDate.addYears(-1);
          ordr4.Contract_End_Date__c = endDate.addYears(-1);
          ordr4.Segment_Global_Business_Line__c = accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('gbl-').Name).Id;
          ordr4.Segment_Business_Line__c = accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('bl-').Name).Id;
          ordr4.Segment_Business_Unit__c = accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('bu-').Name).Id;
          ordr4.Segment_Region__c = accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('region-').Name).Id;
          ordr4.Segment_Country__c =  accSegmentMap.get(accList.get(i).Name+'-'+hierarchyMap.get('country-').Name).Id;
          
          /*if( i <= 5) {
            ordr1.Contract_End_Date__c = ordr1.Contract_End_Date__c.addDays(-30);
            ordr4.Contract_End_Date__c = ordr4.Contract_End_Date__c.addDays(-30);
          }*/

          lstOrder.add(ordr4);
      }
      
      insert lstOrder;
    }
}