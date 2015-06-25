/**=====================================================================
 * Name: MergeHistoryUtility_Text
 * Description: Test class to verify MergeHistoryUtility methods. Case #29746
 * Created Date: Feb 19th, 2015
 * Created By: Paul Kissick
*/
@isTest
private class MergeHistoryUtility_Test {

  static testMethod void testMergeHistoryGoodAccountTest() {
    
    Account parAcc1 = Test_Utils.insertAccount();
    parAcc1.CSDA_Integration_Id__c = '00000001';
    parAcc1.EDQ_Integration_Id__c = '00000001';
    update parAcc1;
    Account acc1 = Test_Utils.insertAccount();
    acc1.CSDA_Integration_Id__c = '00000002';
    acc1.EDQ_Integration_Id__c = '00000002';
    acc1.Saas__c = true;
    acc1.ParentId = parAcc1.Id;
    update acc1;
    
    Account acc2 = Test_Utils.insertAccount();
    acc2.CSDA_Integration_Id__c = '00000003';
    acc2.EDQ_Integration_Id__c = '00000003';
    update acc2;
    
    
    acc1 = [
      SELECT Id,
        EDQ_Integration_Id__c, 
        CSDA_Integration_Id__c, 
        Global_Unique_ID__c,
        Experian_ID__c,
        Saas__c,
        Ultimate_Parent_Account__c, 
        Ultimate_Parent_Account__r.CSDA_Integration_Id__c
      FROM Account WHERE Id = :acc1.Id 
    ];
    acc2 = [
      SELECT Id,
        EDQ_Integration_Id__c, 
        CSDA_Integration_Id__c, 
        Global_Unique_ID__c,
        Experian_ID__c,
        Saas__c,
        Ultimate_Parent_Account__c, 
        Ultimate_Parent_Account__r.CSDA_Integration_Id__c
      FROM Account WHERE Id = :acc2.Id 
    ];
    // acc2 is loser, acc1 is winner.
    MergeHistory__c mh = MergeHistoryUtility.createMergeHistoryRecord(acc2,acc1);
    system.assert(mh.Winner_Record_ID__c == acc1.Id,'Winner ID is incorrect');
    system.assert(mh.Loser_Record_ID__c == acc2.Id,'Loser ID is incorrect');
    system.assertEquals('Account',mh.Object_Type__c,'Object Type field is incorrect');
    system.assert(mh.Winner_SaaS_Ind__c == true,'Winner Saas is incorrect');
    acc1 = [
      SELECT Id
      FROM Account WHERE Id = :acc1.Id 
    ];
    acc2 = [
      SELECT Id
      FROM Account WHERE Id = :acc2.Id 
    ];
    // acc2 is loser, acc1 is winner.
    MergeHistory__c mh2 = MergeHistoryUtility.createMergeHistoryRecord(acc2,acc1);
    system.assert(mh2.Winner_Record_ID__c == acc1.Id,'Winner ID is incorrect');
    system.assert(mh2.Loser_Record_ID__c == acc2.Id,'Loser ID is incorrect');
    system.assert(mh2.Loser_Top_Parent_ID__c == null,'There is a top parent, there shouldn\'t be.');
 
  }
  
  static testMethod void testMergeHistoryGoodContactTest() {
    
    Account acc1 = Test_Utils.insertAccount();
    Contact cont1 = Test_Utils.insertContact(acc1.Id);
    Contact cont2 = Test_Utils.insertContact(acc1.Id);
    
    cont1 = [
      SELECT Id,
        EDQ_Integration_Id__c, 
        // CSDA_Integration_Id__c, 
        Global_Unique_ID__c,
        Experian_ID__c
      FROM Contact WHERE Id = :cont1.Id 
    ];
    cont2 = [
      SELECT Id,
        EDQ_Integration_Id__c, 
        // CSDA_Integration_Id__c, 
        Global_Unique_ID__c,
        Experian_ID__c
      FROM Contact WHERE Id = :cont2.Id 
    ];
    // acc2 is loser, acc1 is winner.
    MergeHistory__c mh = MergeHistoryUtility.createMergeHistoryRecord(cont2,cont1);
    system.assert(mh.Winner_Record_ID__c == cont1.Id,'Winner ID is incorrect');
    system.assert(mh.Loser_Record_ID__c == cont2.Id,'Loser ID is incorrect');
    system.assertEquals('Contact',mh.Object_Type__c,'Object Type field is incorrect');
    
    cont1 = [
      SELECT Id
      FROM Contact WHERE Id = :cont1.Id 
    ];
    cont2 = [
      SELECT Id
      FROM Contact WHERE Id = :cont2.Id 
    ];
    
    MergeHistory__c mh2 = MergeHistoryUtility.createMergeHistoryRecord(cont2,cont1);
    system.assert(mh2.Winner_Record_ID__c == cont1.Id,'Winner ID is incorrect');
    system.assert(mh2.Loser_Record_ID__c == cont2.Id,'Loser ID is incorrect');
    system.assert(mh2.Loser_Top_Parent_ID__c == null,'There is a top parent, there shouldn\'t be.');
 
  }
  
  static testMethod void testMergeHistoryBadTest() {
  	
  	// User records can not be merged, and won't have any info.
  	List<Profile> twoProfiles = [SELECT Id FROM Profile ORDER BY LastModifiedDate LIMIT 2];
  	
  	MergeHistory__c mh = MergeHistoryUtility.createMergeHistoryRecord(twoProfiles[0],twoProfiles[1]);
  	
  	system.assert(mh.Loser_Global_Unique_ID__c == null,'Somehow, the Global Unique ID field is populated on Profiles!');
  	system.assert(mh.Winner_Global_Unique_ID__c == null,'Somehow, the Global Unique ID field is populated on Profiles!');
  	
  	
  }
  
}