/******************************************************************************
 * Appirio, Inc
 * Name: ContractsConfidentialInformationExt_Test
 * Description: T-359158: Test class for ContractsConfidentialInformationExt.cls
 * Created Date: Feb 05th, 2015
 * Created By: Arpita Bose(Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * Feb 19th 2015                Peter Martin                 T-363959 delete Evergreen field
 ******************************************************************************/
@isTest
private class ContractsConfidentialInformationExt_Test {

  public static testmethod void testContractsCIExt(){
    //create test data
    Account acc = Test_Utils.insertAccount();
    Opportunity opp = Test_Utils.insertOpportunity(acc.Id);
    Case testCase = Test_Utils.insertCase(false, acc.Id);
    testCase.Opportunity__c = opp.Id;
    testCase.RecordTypeId = DescribeUtility.getRecordTypeIdByName(Constants.SOBJECT_CASE , Constants.CASE_REC_TYPE_CSDA_CONT_REQ );
    insert testCase;

    Account acc1 = Test_Utils.insertAccount();
    Account acc2 = Test_Utils.insertAccount();
    Opportunity opp1 = Test_Utils.insertOpportunity(acc1.Id);
    Opportunity opp2 = Test_Utils.insertOpportunity(acc2.Id);

    Contract__c contract1 = new Contract__c();
    contract1.Account__c = acc1.Id;
    //T-363959
    //contract1.Evergreen__c = 'Yes';
    insert contract1;

    Contract__c contract2 = new Contract__c();
    contract2.Account__c = acc2.Id;
    //T-363959
    //contract2.Evergreen__c = 'Yes';
    insert contract2;

    Membership__c members1 = new Membership__c();
    members1.Account__c = acc1.Id;
    members1.Opportunity__c = opp1.Id;
    insert members1;

    Membership__c members2 = new Membership__c();
    members2.Account__c = acc2.Id;
    members2.Opportunity__c = opp2.Id;
    insert members2;

    Confidential_Information__c conInfo1 = new Confidential_Information__c ();
    conInfo1.Name = 'Test ConInfo 001';
    conInfo1.Opportunity__c = opp.Id;
    conInfo1.Contract_Document__c = true;
    conInfo1.Account__c = acc.Id;
    conInfo1.Membership__c = members1.Id;

    Confidential_Information__c conInfo2 = new Confidential_Information__c ();
    conInfo2.Name = 'Test ConInfo 002';
    conInfo2.Opportunity__c = opp.Id;
    conInfo2.Contract_Document__c = true;
    conInfo2.Account__c = acc.Id;
    conInfo2.Membership__c = members2.Id;

    List<Confidential_Information__c> lstConInfo = new List<Confidential_Information__c>();
    lstConInfo.add(conInfo1);
    lstConInfo.add(conInfo2);
    insert lstConInfo;
    //start test
    Test.startTest();

    ContractsConfidentialInformationExt cls = new ContractsConfidentialInformationExt(new ApexPages.StandardController(testCase));
    //Asserts
    system.assertEquals(cls.confInfoList.size(), 2);
    //stop test
    Test.stopTest();

  }

}