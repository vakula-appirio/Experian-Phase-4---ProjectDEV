/**=====================================================================
 * Appirio, Inc
 * Name: ContractTemplateController_Test
 * Description: test class for ContractTemplateController.cls
 * Created Date: Jan 28th, 2015
 * Created By: Noopur (Appirio)
 *
 * Date Modified             Modified By           Description of the update
 * Feb 2nd, 2014             Noopur                Removed the code to create custom
 *                                                 setting Contract_Template__c as it is no longer needed
 * Feb 5th,2015              Gaurav Kumar Chadha   T-359201 Changed the Contract__c.Start_Date__c to Contract__c.Contract_Effective_Date__c
 =====================================================================*/
@isTest
private class ContractTemplateController_Test {

    static Contract__c templateContract;

    static testMethod void baseTest() {
      createData ();
      ContractTemplateController con = new ContractTemplateController();
      con.contract.Contract_Template_Name__c = templateContract.Id;
      con.doSelect();
      system.assert(con.urlString != null);
      system.assert(con.urlString.contains('testId2'));
      con.doCancel();
    }

    static void createData () {
      Contract_Template_Field_IDs__c fieldIds = new Contract_Template_Field_IDs__c();
      fieldIds.Status__c = 'testId1';
      fieldIds.Start_Date__c = 'testId2';
      fieldIds.Contract_Type__c = 'testId3';
      fieldIds.Division__c = 'testId4';
      fieldIds.Contract_Filed_Location__c = 'testId5';
      fieldIds.Initial_Term_Period__c = 'testId6';
      fieldIds.Renewal_Term_Period__c = 'testId7';
      fieldIds.Assignment_Rights__c = 'testId8';
      fieldIds.Audit_Rights__c = 'testId9';
      fieldIds.Auto_Renew__c = 'testId10';
      fieldIds.Next_Auto_Renew_Date__c = 'testId11';
      fieldIds.Notice_Period__c = 'testId12';
      fieldIds.Payment_Terms__c = 'testId13';
      fieldIds.Pricing__c = 'testId14';
      fieldIds.Template_Status__c = 'testId15';
      fieldIds.Tiered_Pricing__c = 'testId16';
      fieldIds.Contract_Name__c = 'testId17';
      fieldIds.Template_Version_Date__c = 'testId18';
      insert fieldIds;

      templateContract = new Contract__c();
      templateContract.Contract_Name__c = 'testConTemplate1';
      templateContract.Template_Status__c = 'Active';
      //templateContract.Affiliate_Rights__c = 'testRights';
      templateContract.Contract_Effective_Date__c = Date.today();
      templateContract.Status__c = 'Pending';
      templateContract.Contract_Type__c = 'testContract';
      templateContract.Contract_Filed_Location__c = 'testLoc';
      //templateContract.Division__c = 'Division';
      templateContract.Initial_Term_Period__c = 2;
      templateContract.Renewal_Term_Period__c = 3;
      templateContract.Auto_Renew__c = 'yes';
      templateContract.Next_Auto_Renewal_Date__c = Date.today().addDays(10);
      templateContract.Notice_Period_Days__c = 5;
      templateContract.Payment_Terms__c = 'testPT';
      templateContract.Audit_Rights__c = 'test';
      templateContract.Assignment_Rights__c = 'test';
      templateContract.Pricing__c = 'test';
      templateContract.Tiered_Pricing__c = 'test';
      templateContract.Template_Status__c = 'Active';
      templateContract.RecordTypeId = DescribeUtility.getRecordTypeIdByName('Contract__c', 'CSDA Contract Header Template');
      insert templateContract;
    }
}