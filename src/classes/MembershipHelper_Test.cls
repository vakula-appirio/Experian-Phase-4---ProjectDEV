/**=====================================================================
 * Appirio, Inc
 * Name: MembershipHelper_Test
 * Description: Test class for MembershipHelper
 * Created Date: Feb 24th, 2015
 * Created By: Noopur (Appirio)
 * 
 * Date Modified            Modified By           Description of the update
 * Feb 25th, 2015           Naresh                Updated class to add method to test funcitonality of submitMembership method of main class.
 * Jun 16th, 2015           Paul Kissick          Contact is now required (by validation rule). Adding this.
  =====================================================================*/
@isTest
private class MembershipHelper_Test {
  
  //=========================================================================
  // Method to verify the functionality of MembershipHelper
  //=========================================================================
  static testMethod void baseTest() {
    // fetch the records 
    Account acc = [SELECT Id,Name FROM Account WHERE Name = 'testAccount'];
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'testOpp'];                          
    Contact con = [SELECT Id,Name FROM Contact WHERE LastName ='testCon'];

    // fetch the record type ids
    String RecordTypeMembershipReq = DescribeUtility.getRecordTypeIdByName('Membership__c','Membership Request');
    String RecordTypeMembershipNonRevenue = DescribeUtility.getRecordTypeIdByName('Membership__c','Membership Non-Revenue');
    String RecordTypeMembershipOppAssesment = DescribeUtility.getRecordTypeIdByName('Membership__c','Membership Opportunity Assessment');

    // call the method for Membership Request RT creation from Account
    String url1 = MembershipHelper.createMembership('Membership Request', acc.Id, acc.Name, null);

    // Verify that the url created has the proper fields are added in the url
    String url1Result ='/'+DescribeUtility.getPrefix('Membership__c')+'/e?RecordType='+RecordTypeMembershipReq+'&retURL=/'+acc.Id+/*'&saveURL=/'+acc.Id+*/'&CFcontactFieldId='+con.Name+'&CFcontactFieldId_lkid='+con.Id+'&CFaccountField=testAccount&CFaccountField_lkid='+acc.Id; 
    system.assertEquals(url1, url1Result);
    system.assert( url1.contains(url1Result));

    // call the method for Non-Revenue Membership from Account
    String url2 = MembershipHelper.createMembership('Membership Non-Revenue', acc.Id, acc.Name, null);

    // Verify that the url created has proper fields are added in the url
    String url2Result ='/'+DescribeUtility.getPrefix('Membership__c')+'/e?RecordType='+RecordTypeMembershipNonRevenue+'&retURL=/'+acc.Id+/*'&saveURL=/'+acc.Id+*/'&CFcontactFieldId='+con.Name+'&CFcontactFieldId_lkid='+con.Id+'&CFaccountField=testAccount&CFaccountField_lkid='+acc.Id;

    system.assert( url2.contains(url2Result));
    system.assertEquals(url2, url2Result);

    // call the method for Opportunity Assessment Membership RT from Opportunity
    String url3 = MembershipHelper.createMembership('Membership Opportunity Assessment', null, '', opp.Id);

    // Verify the result
    String url3Result = '/'+DescribeUtility.getPrefix('Membership__c')+'/e?RecordType='+RecordTypeMembershipOppAssesment+'&retURL=/'+opp.Id+/*'&saveURL=/'+opp.Id+*/'&CFcontactFieldId='+con.Name+'&CFcontactFieldId_lkid='+con.Id+'&CFaccountField=testAccount&CFaccountField_lkid='+acc.Id+'&CFoppField=testOpp&CFoppField_lkid='+opp.Id;

    system.assert( url3.contains(url3Result));

    // call the method for Membership Request creation from Opportunity
    String url4 = MembershipHelper.createMembership('Membership Request', null, '' , opp.Id);

    // Verify the result
    String url4Result = '/'+DescribeUtility.getPrefix('Membership__c')+'/e?RecordType='+RecordTypeMembershipReq+'&retURL=/'+opp.Id+/*'&saveURL=/'+opp.Id+*/'&CFcontactFieldId='+con.Name+'&CFcontactFieldId_lkid='+con.Id+'&CFaccountField=testAccount&CFaccountField_lkid='+acc.Id+'&CFoppField=testOpp&CFoppField_lkid='+opp.Id;

    system.assert( url4.contains(url4Result));
  }

  //=========================================================================
  // Method to verify the functionality of MembershipHelper
  //=========================================================================
  static testMethod void submitMembershipTest() {
    // fetch the records 
    Account testAcc = [SELECT Id, Name FROM Account WHERE Name = 'testAccount'];
    Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'testOpp'];
    Contact con = [SELECT Id,Name FROM Contact WHERE LastName ='testCon'];
    
    String msg = MembershipHelper.submitMembership('');
    system.debug('***msg****::::::::'+msg);
    system.assert(msg.startsWith(Label.MEMBERSHIP_ERR_NORECORD));

    Membership__c members1 = new Membership__c();
    members1.Account__c = testAcc.Id;
    members1.Opportunity__c = testOpp.Id;
    members1.Contact_Name__c = con.Id;
    insert members1;

    //Updating bill code to pass validation
    members1.Bill_Code__c = 'TestCode';
    members1.Service_Area__c = 'TST';
    update members1;

    //Submitting membership record successfully
    msg = MembershipHelper.submitMembership(members1.ID);
    system.assertEquals(msg, System.Label.MEMBERSHIP_MSG_SUCCESS);

    //If already submitted
    msg = MembershipHelper.submitMembership(members1.ID);
    system.assertEquals(msg, System.Label.MEMBERSHIP_ERR_ALREADY_SUBMITTED);

    //If invalid ID passed to method
    msg = MembershipHelper.submitMembership('InvalidID');
    system.assertEquals(msg, System.Label.MEMBERSHIP_ERR_NORECORD);
  }    
    
  @testSetup
  public static void createData () {
    Account acc = Test_Utils.createAccount();
    acc.Name = 'testAccount';
    insert acc;

    Contact con = Test_Utils.createContact(acc.Id);
    con.Contact_Role__c = 'Primary';
    con.LastName = 'testCon';
    insert con;

    Opportunity opp = Test_Utils.createOpportunity(acc.Id);
    opp.Name = 'testOpp';
    insert opp;

    Custom_Object_Prefixes__c cusObjPrefix = new Custom_Object_Prefixes__c();
    cusObjPrefix.Membership__c = 'a0F';
    insert cusObjPrefix;

    Custom_Fields_Ids__c customFields = new Custom_Fields_Ids__c();
    customFields.Membership_Contact__c = 'contactFieldId';
    customFields.Membership_Account__c = 'accountField';
    customFields.Membership_Opportunity__c = 'oppField';
    insert customFields;
  }
  
}