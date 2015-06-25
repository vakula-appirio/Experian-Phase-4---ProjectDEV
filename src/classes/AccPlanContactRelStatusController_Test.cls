/**=====================================================================
 * Appirio, Inc
 * Name        : AccPlanContactRelStatusController_Test
 * Description : Handler class for AccPlanContactRelStatusController (for T-289161)
 * Created Date: Jul 8th, 2014
 * Created By  : Sonal Shrivastava (Appirio JDC)
 =====================================================================*/
@isTest
private class AccPlanContactRelStatusController_Test {

	static testMethod void myUnitTest() {
		Account account = Test_Utils.insertAccount();
		 
		Contact con1 = new Contact(AccountId = account.Id,
		                           Email = 'test1@test.com',
		                           FirstName = 'FTest1', LastName = 'LTest1');
		insert con1;
    Contact con2 = new Contact(AccountId = account.Id,
                               Email = 'test2@test.com',
                               ReportsToId = con1.Id,
                               FirstName = 'FTest2', LastName = 'LTest2');
    insert con2;
    
    Contact con3 = new Contact(AccountId = account.Id,
                               Email = 'test3@test.com',
                               ReportsToId = con2.Id,
                               FirstName = 'FTest3', LastName = 'LTest3');
    insert con3;
    
    Account_Plan__c accPlan = Test_Utils.insertAccountPlan(true, account.Id);
    
    
    Account_Plan_Contact__c apc1 = new Account_Plan_Contact__c(Account_Plan__c = accPlan.id, Contact__c = con1.Id, Experian_Relationship__c = 'Positive');
    Account_Plan_Contact__c apc2 = new Account_Plan_Contact__c(Account_Plan__c = accPlan.id, Contact__c = con2.Id, Experian_Relationship__c = 'Negative');
    Account_Plan_Contact__c apc3 = new Account_Plan_Contact__c(Account_Plan__c = accPlan.id, Contact__c = con3.Id, Experian_Relationship__c = 'Neutral');
    
    List<Account_Plan_Contact__c> lstAccPlanContact = new List<Account_Plan_Contact__c>();
    lstAccPlanContact.add(apc1);
    lstAccPlanContact.add(apc2);
    lstAccPlanContact.add(apc3);
    insert lstAccPlanContact;
    
    
    PageReference pageRef = Page.AccPlanContactRelStatusPage;
    pageRef.getParameters().put('id' , accPlan.id);
    Test.setCurrentPage(pageRef);
     
   // ApexPages.Pagereference pg = Page.AccPlanContactRelStatusPage;    
   // pg.getParameters().put('accPlanId', accPlan.id);
  //  Test.setCurrentPage(pg);
    
    Test.startTest();
    AccPlanContactRelStatusController controller = new AccPlanContactRelStatusController();
    System.assertEquals(3, controller.mapConName_NoOfCol.keySet().size());
    System.assertEquals(3, controller.mapLevel_LstContact.keySet().size());
	Test.stopTest();
	}
}