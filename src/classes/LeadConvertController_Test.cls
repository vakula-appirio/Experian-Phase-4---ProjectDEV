/**=====================================================================
 * Appirio, Inc
 * Name: LeadConvertController_Test
 * Description: : To test the functionality of LeadCovertController class - T-250729
 * Created Date: Feb 18th, 2014
 * Created By: Arpita Bose(Appirio)
 * 
 * Date Modified        Modified By          Description of the update
 * 
 =====================================================================*/
@isTest(SeeAllData=true)
public class LeadConvertController_Test {
  @isTest
  public static void testLeadConvertWithoutLabel(){
    PageReference pageRef = Page.LeadConvertStatus;
    Test.setCurrentPage(pageRef);
    //create lead without Labels
    Lead lead;
    lead = new Lead(FirstName = 'Test Lead-1', City = '', State = '',
                            Street = '', Country = '', PostalCode = '', Status = 'Open',
                      Email = 'test@test.com' , Company = 'TestCompany',
                      CurrencyIsoCode = 'USD' , Phone = '',
                      LeadSource = 'Other' , Industry = 'Automotive',
                      Region__c = 'India', Capability__c = '', Budget__c = '');
    lead.LastName = 'Test_Lead_Convert';
    insert lead;

    //start test
    Test.startTest();
    ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(lead);
    LeadConvertController controller = new LeadConvertController(sc);
    //stop test
    Test.stopTest();
                //Asserts
    System.assertEquals (controller.fieldStatusMap.get(Label.CAPABILITY), false);
    System.assertEquals (controller.fieldStatusMap.get(Label.BUDGET), false);
    System.assertEquals (controller.fieldStatusMap.get(Label.EMAIL), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.PHONE), false);
    System.assertEquals (controller.fieldStatusMap.get(Label.STREET), false);
    System.assertEquals (controller.fieldStatusMap.get(Label.CITY), false);
    System.assertEquals (controller.fieldStatusMap.get(Label.STATE), false);
    System.assertEquals (controller.fieldStatusMap.get(Label.COUNTRY), false);
    System.assertEquals (controller.fieldStatusMap.get(Label.POSTALCODE), false);
  }

  @isTest
  public static void testLeadConvertWithLabel(){
    PageReference pageRef = Page.LeadConvertStatus;
    Test.setCurrentPage(pageRef);
    //create lead with Labels
    Lead lead;
    lead = Test_Utils.createLead();
    lead.LastName = 'Test_Lead_Convert';
    lead.Capability__c = 'Application Processing';
    lead.Budget__c = '1,000';
    insert lead;

    //start test
    Test.startTest();
    ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(lead);
    LeadConvertController controller = new LeadConvertController(sc);
    //stop test
    Test.stopTest();
    //Asserts
    System.assertEquals (controller.fieldStatusMap.get(Label.CAPABILITY), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.BUDGET), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.EMAIL), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.STREET), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.STREET), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.CITY), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.STATE), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.COUNTRY), true);
    System.assertEquals (controller.fieldStatusMap.get(Label.POSTALCODE), true);

  }

}